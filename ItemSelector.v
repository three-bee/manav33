module ItemSelector(CLK, KEY, SW, possibleItems, productList_Pointer, currentPointer, totalPrice_BCD, shop_final_amounts, shop_final_products);

input CLK; //Built-in FPGA CLK
input [3:0] KEY; //Keys, active low
input [1:0] SW; //Switches, active high

//Shopping Data
reg [11:0] priceList[11:0]; //12 products, each having 12 bit prices
									 //Max price: DEC 999 = BIN 0011 1110 0111
reg [7:0] productList[11:0]; //12 products, 8-bit 4-digit ID
output reg [11:0] possibleItems; //For autocompletion of ID
reg [35:0] shoppingList; //12 products with 3-bit amount
output reg [23:0] shop_final_products;
output reg [17:0] shop_final_amounts;

reg [15:0] totalPrice; //Binary
output reg [19:0] totalPrice_BCD;

//Counters
integer keyCount; //Keycount for enterID state
integer pressedKEY1, pressedKEY2, pressedKEY3, pressedKEY4;
reg [2:0] itemKindCount; //Cart can include at most 6 different items

//Iterators & pointers & temporary registers
reg [7:0] i;  
integer x, j, temp, temp_new, shop_final_counter;
output reg [3:0] currentPointer;
output reg [3:0] productList_Pointer;
integer itemToBeBought; //Index of the item to be bought in possibleItems
reg [2:0] previousAmount; //If the same item is tried to added to the cart, save old amount temporarily

//Flags
reg alreadyBoughtFlag; 


//Possible states
reg [3:0] posState;
parameter posState_reset = 'd0;
parameter posState_SW2 = 'd1;
parameter posState_SW1 = 'd2;
parameter posState_enterID = 'd3;
parameter posState_enterAmount ='d4;
parameter posState_updateTotalPrice = 'd5;
parameter posState_endShopping = 'd6;


initial begin
	possibleItems = 12'b111111111111;
	shoppingList = 35'd0;
	itemToBeBought = 'd0;

	keyCount = 'd0;
	itemKindCount = 'd0;
	x = 'd0;
	alreadyBoughtFlag = 0;
	previousAmount = 3'b000;
		
	totalPrice = 16'b0000000000000000;
	totalPrice_BCD = 20'b00000000000000000000;
	
	currentPointer = 4'b0010;
	productList_Pointer = 4'b0010;
	shop_final_products= 24'b000000000000000000000000;
	shop_final_amounts =18'b000000000000000000;

	pressedKEY1 = 'd0;
	pressedKEY2 = 'd0;
	pressedKEY3 = 'd0;
	pressedKEY4 = 'd0;

	//1: 00,
	//2: 01,
	//3: 10,
	//4: 11
	productList[0] = 8'b10000111; //Banana:3124
	productList[1] = 8'b11001001; //Potato:4132
	productList[2] = 8'b11001010; //Tomato:4133
	productList[3] = 8'b10000100; //Peach:3121
	productList[4] = 8'b10001010; //Apple:3133
	productList[5] = 8'b10010011; //Pineapple:3214
	productList[6] = 8'b01001110; //Cucumber:2143
	productList[7] = 8'b00011011; //Pear:1234
	productList[8] = 8'b11011101; //Melon:4242 //42 is the license plate city code of the KONYA :D. My hometown Çumra/Konya is famous for its melon btw. 
	productList[9] = 8'b00000101; //Cherry:1122
	productList[10] = 8'b00111100; //Strawberry:1441
	productList[11] = 8'b01011111; //Orange:2244
	
	priceList[0] = 'd250; //Banana: 2.50
	priceList[1] = 'd50;  //Potato: 0.50
	priceList[2] = 'd75;  //Tomato: 0.75
	priceList[3] = 'd200; //Peach: 2.00
	priceList[4] = 'd100; //Apple: 1.00
	priceList[5] = 'd995; //Pineapple: 9.95
	priceList[6] = 'd50; //Cucumber: 0.50
	priceList[7] = 'd425; //Pear: 4.25
	priceList[8] = 'd999; //Melon: 9.99 // It is Çumra melon afterall
	priceList[9] = 'd500; //Cherry: 5.00
	priceList[10] = 'd550; //Strawberry: 5.50
	priceList[11] = 'd200; //Orange: 2.00
	
	posState = posState_enterID;
end

//Check if any key is pressed (LOW)
always @(posedge CLK) begin
	//If so, increment the pressedKEY counter up to its MAX value
	//This step is designed considering debouncing of the keys
	if (KEY[0]==0 & pressedKEY1 < 'd3)	pressedKEY1 <= pressedKEY1 + 'd1;
		else if (KEY[0]==1)	pressedKEY1 <= 0;
		
	if (KEY[1]==0 & pressedKEY2 < 'd3)	pressedKEY2 <= pressedKEY2 + 'd1;
		else if (KEY[1]==1)	pressedKEY2 <= 0;
		
	if (KEY[2]==0 & pressedKEY3 < 'd3)	pressedKEY3 <= pressedKEY3 + 'd1;
		else if (KEY[2]==1)	pressedKEY3 <= 0;
		
	if (KEY[3]==0 & pressedKEY4 < 'd3)	pressedKEY4 <= pressedKEY4 + 'd1;
		else if (KEY[3]==1)	pressedKEY4 <= 0;

end

//Key counter
always @(posedge CLK) begin
	//if (posState == posState_SW2) keyCount <= 0;
	if (pressedKEY1 == 'd2 | pressedKEY2 == 'd2 | pressedKEY3 == 'd2 | pressedKEY4 == 'd2) begin
		//While passing to enterAmount, reset keyCount
		if	(posState == posState_enterAmount & keyCount == 'd4)	keyCount <= 0;
		//Do not count keys in SW, reset end end shopping states
		else if (posState == posState_SW2 | posState == posState_reset | posState == posState_SW1 | posState == posState_endShopping) keyCount <= 0;
		else keyCount <= keyCount + 'd1;
	end
end

//State machine
always @(posedge CLK) begin

	//Before performing case statement, force state changes when in those three states: SW1, SW2 and enterID.
	//Other states will eventually come back to those three.
	if (posState == posState_SW1 | posState == posState_SW2 | posState == posState_enterID) begin
		if (pressedKEY1 == 'd3 && pressedKEY4 == 'd2) posState <= posState_endShopping;
		else if (SW[1]==1) posState <= posState_SW2;
		else if (SW[0]==1) posState <= posState_SW1;
		else posState <= posState_enterID;
	end
	
	case (posState)

	posState_endShopping : begin
		//Convert Total price to totalPrice_BCD
		totalPrice_BCD = 0; //initialize total to zero.
		for (i = 0; i < 16; i = i+1) begin
			totalPrice_BCD = {totalPrice_BCD[18:0],totalPrice[15-i]}; //concatenation
					  
			//if a hex digit of 'bcd' is more than 4, add 3 to it.  
			if(i < 15 && totalPrice_BCD[3:0] > 4) 
			  totalPrice_BCD[3:0] = totalPrice_BCD[3:0] + 3;
					  
			if(i < 15 && totalPrice_BCD[7:4] > 4)
			  totalPrice_BCD[7:4] = totalPrice_BCD[7:4] + 3;
			  
			if(i < 15 && totalPrice_BCD[11:8] > 4)
			  totalPrice_BCD[11:8] = totalPrice_BCD[11:8] + 3; 
					  
			if(i < 15 && totalPrice_BCD[15:12] > 4)
			  totalPrice_BCD[15:12] = totalPrice_BCD[15:12] + 3;
					  
			if(i < 15 && totalPrice_BCD[19:16] > 4)
			  totalPrice_BCD[19:16] = totalPrice_BCD[19:16] + 3;    
		end
		
		if (pressedKEY1 == 'd3 && pressedKEY4 == 'd2)	
			posState <= posState_reset;
		
	end
	
	//Reset for a new customer
	posState_reset : begin
		possibleItems <= 12'b111111111111;
		shoppingList <= 35'd0;
		itemToBeBought <= 'd0;
		totalPrice <= 16'b0000000000000000;
		totalPrice_BCD <= 'd0;
		currentPointer <= 4'b0000;
		productList_Pointer <= 4'b0000;
		itemKindCount <= 'd0;
		alreadyBoughtFlag <= 0;
		previousAmount <= 3'b000;
		
		shop_final_products <= 'd0;
		shop_final_amounts <= 'd0;
		
		posState <= posState_enterID;
	end
	
	posState_SW2 : begin
			
		for(x=0; x<12; x=x+1) begin
			if (shop_final_counter<6)begin
				if (shoppingList[3*x+:3] != 3'b000) begin
					shop_final_products[4*shop_final_counter+:4] <= x+1;
					shop_final_amounts[3*shop_final_counter+:3] <= shoppingList[3*x+:3];
					shop_final_counter = shop_final_counter+1;
				end
			end
		end
		shop_final_counter = 0;
	
		//KEY1 : UP
		//KEY2 : DOWN
		//KEY3 : DELETE PRODUCT
		
		//Note that UP and DOWN directions means travel through the shopping List via increasing and decreasing the index, respectively.
		
		// The logic behind this part is that we try to assign
		//currentPointer to a product existing in the shopping list 
		//and avoid to assign it to an empty part of the list.
		
		//In each step(going UP or DOWN), We iterate through the list and 
		//find the fisrt occupied place which can be assigned to currentPointer by 
		//skipping the empty parts of the shopping list.
		
		// Check if the zero index is empty. If so find the first occupied place and assign currentPointer to there.
		
		//KEY1 UP operation
		if (pressedKEY1 == 'd2) begin 
			temp = currentPointer;
			temp_new = currentPointer;	
			
			currentPointer <= currentPointer +1;
			temp = temp+1;
			
			// If currentPointer is at the end of the list, go back to beginning
			// I use two temporary variables(temp and temp_new) to check this
			if(temp==6 || shop_final_products[4*(currentPointer+1)+:4] == 4'b0000) begin
				currentPointer <=0;
				temp=0;				
			end
		end
		
		//KEY2 DOWN operation
		if (pressedKEY2 == 'd2) begin //DOWN
			temp = currentPointer;
			temp_new = currentPointer;
			
			currentPointer <= currentPointer -1;
			temp = temp-1;
			
			if(temp==-1) begin
				for (x=5; x>-1; x=x-1) begin
					if(j==0)begin
						if (shop_final_products[4*x+:4] != 4'b0000) begin
						currentPointer<=x;
						j=1;
						end
					end
				end
				j=0;
			end
		end
		//KEY3 DELETE operation
		if (pressedKEY3 == 'd2) begin
			temp_new = currentPointer - 1;
					
			itemKindCount<= itemKindCount -1;
			temp = shop_final_products[4*currentPointer+:4] - 1;
			
			previousAmount <= shoppingList[3*temp+:3];
			shoppingList[3*temp+:3] <= 3'b000;
			itemToBeBought <= temp;
			alreadyBoughtFlag <= 1;
			
			if(currentPointer != 0) currentPointer <= currentPointer-1;
			shop_final_counter = 0;
			
			shop_final_products <= 24'b000000000000000000000000;
			shop_final_amounts <= 18'b000000000000000000;
			/*
			// -1 -> to the end of the list
			if(temp_new==-1) begin
				for (x=5; x>-1; x=x-1) begin
					if(j==0)begin
						if (shop_final_products[4*x+:4] != 4'b0000)
						currentPointer<=x;
						j=1;
					end
				end
				j=0;
			end
			*/
			posState <= posState_updateTotalPrice;
		end	
	end
	
	posState_SW1 : begin
	
		//KEY1 : RIGHT
		//KEY2 : UP
		//KEY3 : DOWN
		//KEY4 : LEFT
		//KEY2&KEY3: Select item to be bought
		
		// Select combination
		if (pressedKEY2 == 'd3 && pressedKEY3 == 'd2) begin
			//Compensate unintentional UP by DOWN
			if((productList_Pointer/3) == 3) begin
				productList_Pointer <= productList_Pointer-9;
				itemToBeBought <= productList_Pointer-9;
			end
			else begin
				productList_Pointer <= productList_Pointer+3;
				itemToBeBought <= productList_Pointer+3;
			end
			posState <= posState_enterAmount;
		end
		
		//KEY1 RIGHT 
		else if (pressedKEY1 == 'd2) begin
			productList_Pointer <= (productList_Pointer/3)*3 + ((productList_Pointer+1)%3);  
		end
		
		//KEY2 UP 
		else if (pressedKEY2 == 'd2) begin
			if((productList_Pointer/3) == 0) begin
				productList_Pointer <= productList_Pointer+9;
			end
			else begin
				productList_Pointer <= productList_Pointer-3;
			end
		end
		
		//KEY3 DOWN 
		else if (pressedKEY3 == 'd2) begin
			if((productList_Pointer/3) == 3) begin
				productList_Pointer <= productList_Pointer-9;
			end
			else begin
				productList_Pointer <= productList_Pointer+3;
			end
		end
		
		//KEY4 LEFT 
		else if (pressedKEY4 == 'd2) begin
			if((productList_Pointer%3)==0) begin
				productList_Pointer <= productList_Pointer+2;
			end
			else begin
				productList_Pointer <= productList_Pointer-1;
			end
		end	
	end
	
	posState_enterID : begin

		//Init
		if (keyCount == 'd0) possibleItems <= 12'b111111111111;
		
		//5th key press will enter amount
		if (keyCount == 'd4) posState <= posState_enterAmount;
		
		//Iteratively update possibleItems to autocomplete ID:
		//Initially possibleItems = 12'b111111111111 so that all possible items are iterated
		//Impossible ones are switched to 0 to truncate search space in the next run
		//Only remaining 1 in possibleItems is the itemToBeBought
		for(x=0; x<12; x=x+1) begin
			if (possibleItems[x]==1) begin
				if (pressedKEY1 == 'd2) begin
					//keyCount+1 instead of keyCount due to evaluating Q(n-1) instead of Q(n)
					if (2'b00 == productList[x][(9-2*(keyCount+1))-:2]) begin	
						possibleItems[x] <= 1;
						//4th key press will certainly determine the bought item
						if (keyCount+1==4)	begin
							itemToBeBought <= x;
						end
					end
					else possibleItems[x] <= 0;
				end
				if (pressedKEY2 == 'd2) begin
					if (2'b01 == productList[x][(9-2*(keyCount+1))-:2]) begin
						possibleItems[x] <= 1;
						if (keyCount+1==4)	begin
							itemToBeBought <= x;
						end
					end
					else possibleItems[x] <= 0;
				end
				if (pressedKEY3 == 'd2) begin
					if (2'b10 == productList[x][(9-2*(keyCount+1))-:2]) begin
						possibleItems[x] <= 1;
						if (keyCount+1==4)	begin
							itemToBeBought <= x;
						end
					end
					else possibleItems[x] <= 0;
				end
				if (pressedKEY4 == 'd2) begin
					if (2'b11 == productList[x][(9-2*(keyCount+1))-:2]) begin
						possibleItems[x] <= 1;
						if (keyCount+1==4)	begin
							itemToBeBought <= x;
						end
					end
					else possibleItems[x] <= 0;
				end
			end
		end	
	end	
	
	//Enter amount of product to be bought, then pass to updating total price
	posState_enterAmount : begin
		if (pressedKEY1 == 'd2) begin
			//If the product with entered ID already exists in the shopping cart, update flag and save old amount
			if (shoppingList[3*itemToBeBought+:3] != 3'b000) begin
				alreadyBoughtFlag = 1;
				previousAmount <= shoppingList[3*itemToBeBought+:3];
			end
			//If item count is more than 5, and a different item is tried to bought, ignore 
			if (alreadyBoughtFlag == 0 & itemKindCount > 'd5) begin
				posState <= posState_enterID;
			end
			//If possibleItems is empty, ignore
			else if (!possibleItems)	posState <= posState_enterID;
			//If item count is more than 5, and the same item is tried to bought, accept
			else if (alreadyBoughtFlag == 1 & itemKindCount > 'd5) begin
				posState <= posState_updateTotalPrice;
			end
			//If item count is less than 5, pass to updating total price and update shopping list
			else begin
				shoppingList[3*itemToBeBought+:3] <= 3'b001;
				posState <= posState_updateTotalPrice;
			end
		end
		
		if (pressedKEY2 == 'd2) begin
			if (shoppingList[3*itemToBeBought+:3] != 3'b000) begin
				alreadyBoughtFlag = 1;
				previousAmount <= shoppingList[3*itemToBeBought+:3];
			end
			if (alreadyBoughtFlag == 0 & itemKindCount > 'd5) begin
				posState <= posState_enterID;
			end
			else if (!possibleItems)	posState <= posState_enterID;
			else if (alreadyBoughtFlag == 1 & itemKindCount > 'd5) begin
				posState <= posState_updateTotalPrice;
			end
			else begin
				shoppingList[3*itemToBeBought+:3] <= 3'b010;
				posState <= posState_updateTotalPrice;
			end
		end
		
		if (pressedKEY3 == 'd2) begin
			if (shoppingList[3*itemToBeBought+:3] != 3'b000) begin
				alreadyBoughtFlag = 1;
				previousAmount <= shoppingList[3*itemToBeBought+:3];
			end
			if (alreadyBoughtFlag == 0 & itemKindCount > 'd5) begin
				posState <= posState_enterID;
			end
			else if (!possibleItems)	posState <= posState_enterID;
			else if (alreadyBoughtFlag == 1 & itemKindCount > 'd5) begin
				posState <= posState_updateTotalPrice;
			end
			else begin
				shoppingList[3*itemToBeBought+:3] <= 3'b011;
				posState <= posState_updateTotalPrice;
			end
		end
		
		if (pressedKEY4 == 'd2) begin
			if (shoppingList[3*itemToBeBought+:3] != 3'b000) begin
				alreadyBoughtFlag = 1;
				previousAmount <= shoppingList[3*itemToBeBought+:3];
			end
			if (alreadyBoughtFlag == 0 & itemKindCount > 'd5) begin
				posState <= posState_enterID;
			end
			else if (!possibleItems)	posState <= posState_enterID;
			else if (alreadyBoughtFlag == 1 & itemKindCount > 'd5) begin
				posState <= posState_updateTotalPrice;
			end
			else begin
				shoppingList[3*itemToBeBought+:3] <= 3'b100;
				posState <= posState_updateTotalPrice;
			end
		end
		
	end
	
	//Update total price, increase item kind count, then pass to entering ID again
	posState_updateTotalPrice : begin 
		//Do not increase itemKindCount if the item is already in the cart.
		if (alreadyBoughtFlag==1) begin
			if (previousAmount > shoppingList[3*itemToBeBought+:3]) //Previous is larger, subtract
				totalPrice <= totalPrice - (previousAmount - shoppingList[3*itemToBeBought+:3]) * priceList[itemToBeBought];
			else if (previousAmount < shoppingList[3*itemToBeBought+:3]) //Previous is smaller, add
				totalPrice <= totalPrice + (shoppingList[3*itemToBeBought+:3] - previousAmount) * priceList[itemToBeBought];
			else begin //Equal, continue
				itemToBeBought <= 'd0;
				alreadyBoughtFlag <= 'd0;
				posState <= posState_enterID;
			end
		end
		//If the item is of a new kind, update normally
		else begin
			totalPrice <= totalPrice + shoppingList[3*itemToBeBought+:3] * priceList[itemToBeBought];
			itemKindCount <= itemKindCount + 1;
		end

		itemToBeBought <= 'd0;
		alreadyBoughtFlag <= 'd0;
		posState <= posState_enterID;
		
		// Construct updated shopping list
		for(x=0; x<12; x=x+1) begin
			if (shop_final_counter<6)begin
				if (shoppingList[3*x+:3] != 3'b000) begin
					shop_final_products[4*shop_final_counter+:4] <= x+1;
					shop_final_amounts[3*shop_final_counter+:3] <= shoppingList[3*x+:3];
					shop_final_counter = shop_final_counter+1;
				end
			end
		end
		shop_final_counter = 0;
		
	end
	
	endcase
end

endmodule