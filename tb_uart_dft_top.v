`timescale 1ns/1ps
module tb_uart_dft_top;

	reg clk, rst, rx;
	reg scan_enable, scan_in;
	wire tx, led, scan_out;
	
	// Instantiation of top module
	uart_dft_top uut(
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.tx(tx),
		.led(led),
		.scan_enable(scan_enable),
		.scan_in(scan_in),
		.scan_out(scan_out)
	);
	
	// Clock beneration: 50MHz clock = 20ns period
	always #10 clk = ~clk;
	
   // UART byte transmit task (8-N-1)
	task send_uart_byte(input [7:0] data);
		integer i;
		begin	 
			rx = 0; #160; // start bit
			for (i = 0; i < 8; i = i + 1) begin
			rx = data[i];
			#160;
		   end
			rx = 1; #160; // stop bit
		end
	endtask 
	

	initial begin
		// ===Init===
		clk = 0;
		rst = 1;
		rx = 1;  //idle
		scan_enable = 0;
		scan_in = 0;
		
		
		#100;
		rst = 0;
		#100;
		
	   //===傳送指令 0xA1: LED ON ===
		send_uart_byte(8'hA1);
		$display("[%t] Sent UART data 0xA1", $time);
		#3000;
	
      //===啟動 Scan Enable模式測試===
		scan_enable = 1;
		scan_in = 1; #160;
		scan_in = 0; #160;
		scan_in = 1; #160;
		scan_in = 1; #160;
		scan_in = 0;
		#1000;
		
		//===模擬完成===
		$display("[%t] Simulation complete", $time);
		$finish;
	end
	


endmodule
