`timescale 1ns/1ps
module uart_command_top(
	input wire clk,  //系統主時脈
	input wire rst,  //非同步重置信號
	input wire rx,   //UART RX
	output wire tx,  //UART TX
	output wire led  //控制LED,觀察回應
);
	
	//=== UART RX ===
	wire [7:0] rx_data;
	wire rx_done;
	wire rx_done_sync;  //補回CDC sync訊號
	
	
	uart_rx u_rx(
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.data_out(rx_data),
		.done(rx_done)
	);
	
	//=== CDC SYNC ===
	cdc_sync u_cdc(
		.clk_dst(clk),
		.rst(rst),
		.signal_src(rx_done),
		.signal_dst(rx_done_sync)
	);
		
		//=== FIFO ===
		wire fifo_empty, fifo_full;
		wire [7:0] fifo_dout;
		reg fifo_rd_en;
		
		fifo u_fifo (
			.clk(clk),
			.rst(rst),
			.wr_en(rx_done_sync),
			.rd_en(fifo_rd_en),
			.din(rx_data),
			.dout(fifo_dout),
			.full(fifo_full),
			.empty(fifo_empty)
		);
		
		//=== Command Decoder ===
		wire [7:0] tx_data;
		wire tx_start;
		wire led_state;
		wire [2:0] cmd_state;  // FSM狀態輸出
		
		command_decoder u_cmd(
			.clk(clk),
			.rst(rst),
			.valid(!fifo_empty),
			.cmd_in(fifo_dout),
			.tx_data(tx_data),
			.tx_start(tx_start),
			.led_state(led_state),
			.state(cmd_state)
		);
		
		//=== UART TX ===
		wire tx_busy;
		wire [2:0] tx_state;
			
		uart_tx u_tx(
			.clk(clk),
			.rst(rst),
			.tx_start(tx_start),
			.data_in(tx_data),
			.tx(tx),
			.busy(tx_busy),
			.state(tx_state)
		);
		//===控制 FIFO 讀出===
		always @(*) begin
				fifo_rd_en = !fifo_empty && !tx_busy && tx_start;
		end
		
		//=== LED輸出===
		assign led = led_state;
			
endmodule