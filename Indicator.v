module Indicator(clk, pos_H, pos_V, possibleItems, SW1pointer, SW2pointer, shade, indicate1, indicate2);

input clk;
input[9:0] pos_H, pos_V;
input[11:0] possibleItems;
input[3:0] SW1pointer, SW2pointer;
output wire shade, indicate1, indicate2;

wire AlwaysHigh;
wire[11:0] item;
wire[2:0] column;
wire[3:0] row;
wire xline1, yline1, xline2, yline2;

reg[7:0] SW1xcoord, SW1ycoord, SW2xcoord, SW2ycoord;

initial begin
	SW1xcoord = 0;
	SW1ycoord = 17;
	SW2xcoord = 168;
	SW2ycoord = 66;
end


//Selected items will be highlighted according to their codes,
//others will be shaded 
assign AlwaysHigh = (pos_V < 34+17*2 || pos_H > 144+167*2);

assign column[0] = ((pos_H >= 144) && (pos_H < 144+55*2)); 
assign column[1] = ((pos_H >= 144+56*2) && (pos_H < 144+111*2));
assign column[2] = ((pos_H >= 144+112*2) && (pos_H < 144+167*2));

assign row[0] = ((pos_V >= 35+17*2) && (pos_V < 35+72*2));
assign row[1] = ((pos_V >= 35+73*2) && (pos_V < 35+128*2));
assign row[2] = ((pos_V >= 35+129*2) && (pos_V < 35+184*2));
assign row[3] = ((pos_V >= 35+185*2) && (pos_V < 35+240*2));

assign item[0] = ((column[0] && row[0]) && possibleItems[0]);
assign item[1] = ((column[1] && row[0]) && possibleItems[1]);
assign item[2] = ((column[2] && row[0]) && possibleItems[2]);
assign item[3] = ((column[0] && row[1]) && possibleItems[3]);
assign item[4] = ((column[1] && row[1]) && possibleItems[4]);
assign item[5] = ((column[2] && row[1]) && possibleItems[5]);
assign item[6] = ((column[0] && row[2]) && possibleItems[6]);
assign item[7] = ((column[1] && row[2]) && possibleItems[7]);
assign item[8] = ((column[2] && row[2]) && possibleItems[8]);
assign item[9] = ((column[0] && row[3]) && possibleItems[9]);
assign item[10] = ((column[1] && row[3]) && possibleItems[10]);
assign item[11] = ((column[2] && row[3]) && possibleItems[11]);

assign shade = !(AlwaysHigh || item[0] || item[1] || item[2] || item[3] || item[4] || item[5] || item[6] || item[7] || item[8] || item[9] || item[10] || item[11]);


always @(posedge clk) begin
	case(SW1pointer)
	4'd0: begin
				SW1xcoord <= 0;
				SW1ycoord <= 17;
			end
	4'd1: begin
				SW1xcoord <= 56;
				SW1ycoord <= 17;
			end
	4'd2: begin
				SW1xcoord <= 112;
				SW1ycoord <= 17;
			end
	4'd3: begin
				SW1xcoord <= 0;
				SW1ycoord <= 73;
			end
	4'd4: begin
				SW1xcoord <= 56;
				SW1ycoord <= 73;
			end
	4'd5: begin
				SW1xcoord <= 112;
				SW1ycoord <= 73;
			end
	4'd6: begin
				SW1xcoord <= 0;
				SW1ycoord <= 129;
			end
	4'd7: begin
				SW1xcoord <= 56;
				SW1ycoord <= 129;
			end
	4'd8: begin
				SW1xcoord <= 112;
				SW1ycoord <= 129;
			end
	4'd9: begin
				SW1xcoord <= 0;
				SW1ycoord <= 185;
			end
	4'd10: begin
				SW1xcoord <= 56;
				SW1ycoord <= 185;
			 end
	4'd11: begin
				SW1xcoord <= 112;
				SW1ycoord <= 185;
		    end
	endcase
	
	case(SW2pointer)
	4'd0: begin
				SW2ycoord <= 66;
			end
	4'd1: begin
				SW2ycoord <= 91;
			end
	4'd2: begin 
				SW2ycoord <= 116;
			end
	4'd3: begin 
				SW2ycoord <= 141;
			end
	4'd4: begin
				SW2ycoord <= 166;
			end
	4'd5: begin
				SW2ycoord <= 191;
			end
	endcase
end


//Producing a red square that enclosures the selected items
assign xline1 = (((pos_V >= 34+SW1ycoord*2) && (pos_V < 34+(55+SW1ycoord)*2)) && ((pos_H == 144+SW1xcoord*2+1) || (pos_H == 144+SW1xcoord*2+2) || (pos_H == 144+(55+SW1xcoord)*2) || (pos_H == 144+(55+SW1xcoord)*2-1)));
assign yline1 = (((pos_H > 144+SW1xcoord*2) && (pos_H < 144+(55+SW1xcoord)*2)) && ((pos_V == 34+SW1ycoord*2) || (pos_V == 34+SW1ycoord*2+1) || (pos_V == 34+(54+SW1ycoord)*2) || (pos_V == 34+(54+SW1ycoord)*2+1)));

assign indicate1 = (xline1 || yline1);


//Producing a red rectangle that enclosures the selected item names
assign xline2 = (((pos_V >= 34+SW2ycoord*2) && (pos_V < 34+(24+SW2ycoord)*2)) && ((pos_H == 144+SW2xcoord*2+1) || (pos_H == 144+SW2xcoord*2+2) || (pos_H == 144+(120+SW2xcoord)*2+1) || (pos_H == 144+(120+SW2xcoord)*2+2)));
assign yline2 = (((pos_H > 144+SW2xcoord*2) && (pos_H < 144+(121+SW2xcoord)*2)) && ((pos_V == 34+SW2ycoord*2) || (pos_V == 34+SW2ycoord*2+1) || (pos_V == 34+(23+SW2ycoord)*2) || (pos_V == 34+(23+SW2ycoord)*2+1)));

assign indicate2 = (xline2 || yline2);

endmodule