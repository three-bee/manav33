module TopModule(CLOCK_50, VGA_VS, VGA_HS, VGA_CLK, VGA_R, VGA_G, VGA_B, SW, KEY);

input CLOCK_50;
input[1:0] SW;
input[3:0] KEY;
output VGA_HS, VGA_VS; 
output reg VGA_CLK;
output reg[7:0] VGA_R, VGA_G, VGA_B;

//VGA related wires
wire READY;
wire[9:0] POS_H, POS_V;
wire[11:0] RGB;

//ItemSelector related wires
wire HIGHLIGHT, SHADE, INDICATE_1, INDICATE_2;
wire[23:0] PRODUCTS;
wire[19:0] PRICE;
wire[17:0] AMOUNT;
wire[11:0] POSSIBLEITEMS;
wire[3:0] SW1POINTER, SW2POINTER;

initial begin
	VGA_CLK = 1'b0;
	VGA_R = 8'h00;
	VGA_G = 8'h00;
	VGA_B = 8'h00;
end

always @(posedge CLOCK_50) begin 
	VGA_CLK = ~VGA_CLK;
end

VGA_Sync SYNC(.vga_CLK(VGA_CLK), .vga_VS(VGA_VS), .vga_HS(VGA_HS), .vga_Ready(READY), .pos_H(POS_H), .pos_V(POS_V));
Interface IMAGE(.vga_CLK(VGA_CLK), .ready(READY), .pos_H(POS_H), .pos_V(POS_V), .RGB(RGB), .price(PRICE), .amount(AMOUNT), .products(PRODUCTS));
ItemSelector SELECT(.CLK(CLOCK_50), .KEY(KEY), .SW(SW), .possibleItems(POSSIBLEITEMS), .productList_Pointer(SW1POINTER), .currentPointer(SW2POINTER), .totalPrice_BCD(PRICE), .shop_final_amounts(AMOUNT), .shop_final_products(PRODUCTS));
Indicator INDICATE(.clk(CLOCK_50), .pos_H(POS_H), .pos_V(POS_V), .possibleItems(POSSIBLEITEMS), .SW1pointer(SW1POINTER), .SW2pointer(SW2POINTER), .shade(SHADE), .indicate1(INDICATE_1), .indicate2(INDICATE_2));

always @(posedge VGA_CLK) begin
	if(READY) begin
		VGA_R[3:0] <= 4'hF;  
		VGA_G[3:0] <= 4'hF;
		VGA_B[3:0] <= 4'hF;
			
		if((SW[0] && INDICATE_1) || (SW[1] && INDICATE_2)) begin
			VGA_R <= 8'hFF;
			VGA_G <= 8'h00;
			VGA_B <= 8'h00;
		end
		else if(SHADE) begin
			VGA_R[7:4] <= RGB[11:8]>>1;  
			VGA_G[7:4] <= RGB[7:4]>>1;
			VGA_B[7:4] <= RGB[3:0]>>1;
		end
		else begin
			VGA_R[7:4] <= RGB[11:8];  
			VGA_G[7:4] <= RGB[7:4];
			VGA_B[7:4] <= RGB[3:0];
		end
	end
	else begin
		VGA_R <= 8'h00;
		VGA_G <= 8'h00;
		VGA_B <= 8'h00;	
	end
end
endmodule