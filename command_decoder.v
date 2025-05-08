`timescale 1ns/1ps
module command_decoder(
	input wire clk,
	input wire rst,
	input wire valid,  //指令有效(ex: rx_done_sync)
	input wire [7:0] cmd_in, //UART 傳入的指令
	output reg [7:0] tx_data,  //要回傳的UART資料
	output reg tx_start,       //啟動UART TX
	output reg led_state,
   output reg [2:0] state	//簡單狀態示範: LED開/關
);

	//狀態編碼
	localparam CMD_IDLE_STATE = 3'd0;
   localparam CMD_DECODE_STATE = 3'd1;
   localparam CMD_DONE_STATE = 3'd2;
	
   //指令定義
   localparam CMD_LED_ON = 8'hA1;
	localparam CMD_LED_OFF= 8'hA2;
	localparam CMD_READ_STATUS = 8'hB1;
	localparam CMD_RESET = 8'hC1;
	
   //回應定義
	localparam RESP_ACK = 8'h55;
	localparam RESP_NACK = 8'hEE;
	localparam RESP_RESET = 8'hAA;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			tx_start <= 0;
			tx_data <= 8'd0;
			led_state <= 0;
			state <= CMD_IDLE_STATE;
		end else begin
			tx_start <= 0;  //預設為0,傳送單一脈波
			state <= CMD_IDLE_STATE;
			
			if(valid) begin
				state <= CMD_DECODE_STATE;
				case (cmd_in)
					CMD_LED_ON: begin
						led_state <= 1;
						tx_data <= RESP_ACK;
						tx_start <= 1;
					end
					
					CMD_LED_OFF: begin
						led_state <= 0;
						tx_data <= RESP_NACK;
						tx_start <= 1;
					end
					
					CMD_READ_STATUS: begin
						tx_data <= {7'd0, led_state}; //回傳0或1
						tx_start <= 1;
					end
					
					CMD_RESET: begin
						led_state <= 0;
						tx_data <= RESP_RESET;
						tx_start <= 1;
					end
					
					default: begin
						tx_data <= RESP_NACK;
						tx_start <= 1;
					end
				endcase
				state <= CMD_DONE_STATE;
			end
		end
	end
endmodule
	