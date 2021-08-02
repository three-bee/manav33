module Interface(vga_CLK, ready, pos_H, pos_V, RGB, price, amount, products);			
  
input vga_CLK, ready;								//In order to reduce both the compilation time and the
input[9:0] pos_H, pos_V;							//memory usage, we multiply all pixels by two so that
input[23:0] products;								//we can display 320x240 image with 640x480 resolution
input[19:0] price;
input[17:0] amount;
output reg[11:0] RGB;

parameter width = 320;								//Width of the interface image

reg[11:0] ImageData[76799:0];		            //320x240 = 76800 pixels, each has 12 bits (RGB444)
reg[11:0] ProductNames[14399:0];					//120x120 = 12400 pixels
reg[11:0] Numbers[699:0];							//7x10 = 700 pixels

reg loop_H, loop_V, white;
reg[16:0] count_data, count_start, data1;		//Counters for double scaling of the	interface image
reg[13:0] data2;
reg[8:0] x, y;
reg[4:0] check;

initial begin																		
	count_data = 0;								   
	count_start = 0;
	loop_H = 0;
	loop_V = 0;
	x = 0;
	y = 0;
	data1 = 0;
	data2 = 0;
	white = 0;
	check = 0;
end

initial begin
	$readmemb("ImageData.txt", ImageData);								//RGB444 binary data of the interface image
	$readmemb("ProductNames.txt", ProductNames);						//Read 'interface', 'products names' and 'numbers's
	$readmemb("Numbers.txt", Numbers); 									//image data sets from the text file
end


always @(posedge vga_CLK) begin

	RGB <= ImageData[count_data];											//Send the current data to the top level design file

	if(!pos_V) begin															//At start of each frame, zero the counters
		count_data <= 0;
		count_start <= 0;
		loop_H <= 0;
		loop_V <= 0;
	end
	
	if(!pos_H) count_data <= count_start;
	
	if(ready) begin                   									//Due to double scaling, image displaying will end
		if(!loop_V) begin  													//at the position that is twice of the width                    
			loop_H <= ~loop_H;												//At each clock pulse, toggle the horizontal counter
			
			if(loop_H) count_data <= count_data + 1;					//When a pixel displayed twice, increment the data counter
			
			if(pos_H == (144 + 2*width - 1)) loop_V <= 1;			//At the end of each row of the image, toggle the 
		end																		//vertical counter so that each row will be 
		else begin																//displayed twice
			loop_H <= ~loop_H;
			
			if(loop_H) count_data <= count_data + 1;
			
			if(pos_H == (144 + 2*width - 1)) begin
				loop_V <= 0;													
				count_start <= count_start + width;						//When a row displayed twice, increment the start count			
			end																	//by the width of the product list image so that
		end																		//the next row's data will start to be displayed 
	end
end


always @(posedge vga_CLK) begin
	if(pos_V > 450) begin
		if(y < 222 || y > 231 || x < 257 || x > 297) begin
			y <= 222;
			x <= 257;
		end
		
		if(y >= 222 && y <= 231) begin
			if((x == 263) || (x == 271) || (x == 279) || (x == 289) ||(x == 297)) begin
				if(y == 231) begin
					y <= 222;
					if(x == 297) x <= 257;
					else if(x == 279) x <= x + 4;
					else x <= x + 2;
				end	
				else begin
					y <= y + 1;
					x <= x - 6;
				end
			end
			else x <= x + 1;
		
		
		case(x)
		'd257: check <= 12;
		'd265: check <= 8;
		'd273: check <= 4;
		'd283: check <= 0;
		'd291: check <= 16;
		endcase
		
		if(((x == 257) || (x == 265) || (x == 273) || (x == 283) || (x == 291)) && (y == 222)) begin
			case(price[check +: 4])
			4'b0000: data2 <= 0;
			4'b0001: data2 <= 70;
			4'b0010: data2 <= 140;
			4'b0011: data2 <= 210;
			4'b0100: data2 <= 280;
			4'b0101: data2 <= 350;
			4'b0110: data2 <= 420;
			4'b0111: data2 <= 490;
			4'b1000: data2 <= 560;
			4'b1001: data2 <= 630;
			endcase
		end
		else data2 <= data2 + 1;
		
		data1 <= 320*y + x;
		ImageData[data1] <= Numbers[data2];
		
		end
	end
	
	else if(pos_V > 200) begin
		if(y < 73 || y > 207 || x < 169 || x > 288) begin
			y <= 73;
			x <= 169;
		end
		
		if((y >= 73 && y <= 207) && (x >= 169 && x <= 288)) begin
			if((x == 288)) begin
				x <= x - 119;
				if((y == 82) || (y == 107) || (y == 132) || (y == 157) || (y == 182) || (y == 207)) begin
					if(y == 207) y <= 73; 
					else y <= y + 16;
				end
				else y <= y + 1;
			end
			else x <= x + 1;
		
		case(y)
		73: check <= 4;
		98: check <= 8;
		123: check <= 12;
		148: check <= 16;
		173: check <= 20;
		198: check <= 0;
		endcase
		
		if(((y == 73) || (y == 98)  || (y == 123) || (y == 148) || (y == 173) || (y == 198)) && (x == 169)) begin
			case(products[check +: 4])
			default: white <= 1; 
			4'b0001: begin data2 <= 0;
								white <= 0; end
			4'b0010: begin data2 <= 1200;
								white <= 0; end
			4'b0011: begin data2 <= 2400;
								white <= 0; end
			4'b0100: begin data2 <= 3600;
								white <= 0; end
			4'b0101: begin data2 <= 4800;
								white <= 0; end
			4'b0110: begin data2 <= 6000;
								white <= 0; end
			4'b0111: begin data2 <= 7200;
								white <= 0; end
			4'b1000: begin data2 <= 8400;
								white <= 0; end
			4'b1001: begin data2 <= 9600;
								white <= 0; end
			4'b1010: begin data2 <= 10800;
								white <= 0; end
			4'b1011: begin data2 <= 12000;
								white <= 0; end
			4'b1100: begin data2 <= 13200;
								white <= 0; end
			endcase
		end
		else data2 <= data2 + 1;
		
		data1 <= 320*y + x;
		ImageData[data1] <= (white) ? 12'hFFF : ProductNames[data2];
		
		end
	end
	
	else begin
		if(y < 73 || y > 207 || x < 301 || x > 307) begin
			y <= 73;
			x <= 301;
		end
		
		if((y >= 73 && y <= 207) && (x >= 301 && x <= 307)) begin
			if((x == 307)) begin
				x <= x - 6;
				if((y == 82) || (y == 107) || (y == 132) || (y == 157) || (y == 182) || (y == 207)) begin
					if(y == 207) y <= 73; 
					else y <= y + 16;
				end
				else y <= y + 1;
			end
			else x <= x + 1;
		
		case(y)
		73: check <= 3;
		98: check <= 6;
		123: check <= 9;
		148: check <= 12;
		173: check <= 15;
		198: check <= 0;
		endcase
		
		if(((y == 73) || (y == 98)  || (y == 123) || (y == 148) || (y == 173) || (y == 198)) && (x == 301)) begin
			case(amount[check +: 3])
			default: white <= 1; 
			3'b001: begin data2 <= 70;
							  white <= 0; end
			3'b010: begin data2 <= 140;
							  white <= 0; end
			3'b011: begin data2 <= 210;
							  white <= 0; end
			3'b100: begin data2 <= 280;
							  white <= 0; end
			3'b101: begin data2 <= 350;
							  white <= 0; end
			3'b110: begin data2 <= 420;
							  white <= 0; end
			endcase
		end
		else data2 <= data2 + 1;
		
		data1 <= 320*y + x;
		ImageData[data1] <= (white) ? 12'hFFF : Numbers[data2];
		
		end
	end
end
endmodule