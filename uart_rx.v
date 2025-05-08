`timescale 1ns/1ps
module uart_rx (
    input wire clk,  //系統時脈
    input wire rst,  //非同步重置信號
    input wire rx,   // UART 接收腳位
    output reg [7:0] data_out,  //接收到的資料
    output reg done  //接收完成旗標
);
    localparam [2:0]
        IDLE_STATE = 3'd0,
		  START_STATE = 3'd1,
		  DATA_STATE = 3'd2,
		  STOP_STATE = 3'd3,
	     DONE_STATE = 3'd4;

    reg [2:0] state;
	 reg [3:0] bit_cnt;
	 reg [3:0] baud_cnt;
    reg [7:0] rx_shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE_STATE;
				data_out <= 8'd0;
				done <= 0;
            bit_cnt <= 0;
				baud_cnt <= 0;
				rx_shift <= 8'd0;
        end else begin
				case (state)
					IDLE_STATE: begin
						done <= 0;
						if (!rx) begin
							state <= START_STATE;
							baud_cnt <= 0;
						end
					end

                START_STATE: begin
                    if (baud_cnt == 4'd7) begin
                        if (!rx) begin
                            state <= DATA_STATE;
                            bit_cnt <= 0;
									 baud_cnt <= 0;
                        end else begin
                            state <= IDLE_STATE;
								end
                    end  else begin
							    baud_cnt <= baud_cnt + 1;
						  end
                end

                DATA_STATE: begin
                    if (baud_cnt == 4'd15) begin
								baud_cnt <= 0;
								rx_shift[bit_cnt] <= rx;
                        if (bit_cnt == 7)
                            state <= STOP_STATE;
								else
									bit_cnt <= bit_cnt + 1;
							end else begin
								 baud_cnt <= baud_cnt + 1;
							end
					 end


                STOP_STATE: begin
                    if (baud_cnt == 4'd15) begin
                            data_out <= rx_shift;
                            done <= 1;
									 state <= DONE_STATE;
                     end else begin
							    baud_cnt <= baud_cnt + 1;
							end
                end

                DONE_STATE: begin
							done <= 0;
							state <= IDLE_STATE;
					 end
      		    default: state <= IDLE_STATE;
             endcase
	     end
    end
endmodule
