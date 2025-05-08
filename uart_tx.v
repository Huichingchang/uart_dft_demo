`timescale 1ns/1ps
module uart_tx(
	input wire clk,  //系統時脈
	input wire rst,  //非同步重置信號
	input wire tx_start,  //啟動傳送
	input wire [7:0] data_in,   //要傳送的資料
	output reg tx,   //UART 傳送腳位
	output reg busy,  //傳送中旗標
	output reg [2:0] state,
	
	//DFT scan chain ports
	input wire scan_enable,
	input wire scan_in,
	output wire scan_out
);

	//狀態定義
	localparam [2:0] IDLE_STATE = 3'd0;
   localparam [2:0] START_STATE = 3'd1;
	localparam [2:0] DATA_STATE = 3'd2;
	localparam [2:0] STOP_STATE = 3'd3;
	localparam [2:0] DONE_STATE = 3'd4;
	
	//其他暫存器
	reg [3:0] bit_cnt;  //資料位元計數器
	reg [7:0] shift_reg;  //傳送資料暫存器
	reg [3:0] baud_cnt;  //假設16倍 baudrate(用來控制每個bit傳送時間)
	reg [7:0] scan_chain;
	
	assign scan_out = scan_chain[7];
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			state <= IDLE_STATE;
			tx <= 1'b1;  // UART 閒置狀態為高
			busy <= 1'b0;
			bit_cnt <= 4'd0;
			baud_cnt <= 4'd0;
			shift_reg <= 8'd0;
			scan_chain <= 8'd0;
		end else begin
			 if (scan_enable) begin
			 // Scan mode: shift in
			 scan_chain <= {scan_chain[6:0], scan_in};
		    end else begin
			     case (state)
				       IDLE_STATE: begin
					        tx <= 1'b1;
					        busy <= 1'b0;
					        if (tx_start) begin
						         shift_reg <= data_in;
						         state <= START_STATE;
						         busy <= 1'b1;
						         baud_cnt <= 4'd0;
					        end
				       end
				
				       START_STATE: begin
					         tx <= 1'b0;  // start bit
					         if (baud_cnt == 4'd15) begin
						          baud_cnt <= 0;
						          bit_cnt <= 0;
						          state <= DATA_STATE;
					         end else begin
								    baud_cnt <= baud_cnt + 1;
								end
						 end
						 
                   DATA_STATE: begin
					        tx <= shift_reg[bit_cnt];
					        if (baud_cnt == 4'd15) begin
						         baud_cnt <= 0;
					         	if (bit_cnt == 7) 
							          state <= STOP_STATE;
						         else
							          bit_cnt <= bit_cnt + 1;
                       end else begin
							      baud_cnt <= baud_cnt + 1;
							  end
					    end
						 
				       STOP_STATE: begin
					         tx <= 1'b1; //Stop bit
		         			if (baud_cnt == 4'd15) begin
					           	baud_cnt <= 0;
					         	state <= DONE_STATE;
					         end else begin
								    baud_cnt <= baud_cnt + 1;	
								end 
					    end	
						 
                   DONE_STATE: begin
					       busy <= 1'b0;  //傳送結束,釋放busy
					       state <= IDLE_STATE;
						 end
						 
                   default: state <= IDLE_STATE;
              endcase
		    end
      end
	end
endmodule
					
			