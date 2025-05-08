`timescale 1ns/1ps
module uart_dft_top(
	input wire clk,  //系統時脈
	input wire rst,  //非同步重置信號
	input wire rx,   // UART 接收腳位
	output wire tx,  //UART 傳送腳位
	output wire led,  //顯示簡易狀態

	//DFT Scan Ports
	input wire scan_enable,
	input wire scan_in,
	output wire scan_out
);	
	
	// UART RX 介面
	wire [7:0] rx_data;
	wire rx_done;
	
	uart_rx u_rx (
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.data_out(rx_data),
		.done(rx_done)
	);
	
	//LED狀態翻轉邏輯(每收到資料就切換LED)
	reg led_reg;
	assign led = led_reg;
	
	always @(posedge clk or posedge rst) begin
		if (rst)
			led_reg <= 0;
		else if (rx_done)
			led_reg <= ~led_reg;  
	end
	
   // UART TX + Scan DFT
   wire tx_busy;
   wire [2:0] tx_state;	
	
	uart_tx u_tx(
		.clk(clk),
		.rst(rst),
		.tx_start(rx_done),
		.data_in(rx_data),
		.tx(tx),
		.busy(tx_busy),
		.state(tx_state),
		.scan_enable(scan_enable),
		.scan_in(scan_in),
		.scan_out(scan_out)
	);
		
endmodule