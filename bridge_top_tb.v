module bridge_top_tb();
reg hclk;
reg hresetn;

wire [31:0] hrdata, haddr, hwdata, prdata, paddr, pwdata, paddr_out, pwdata_out;
wire hwrite, hreadyin;
wire [1:0] htrans;
wire [1:0] hresp = 0;
wire penable, pwrite, hreadyout, pwrite_out, penable_out;
wire [2:0] pselx, pselx_out;

ahb_master AHB(hclk, hresetn, hreadyout, hrdata, haddr, hwdata, hwrite, hreadyin, htrans);

bridge_top BRIDGE(hclk, hresetn, hwrite, hreadyin, htrans, haddr, hwdata, prdata, pwrite, penable, hreadyout, pwdata, paddr, hrdata, pselx, hresp);

apb_interface APB(pwrite, penable, pselx, paddr, pwdata, pwrite_out, penable_out, pselx_out, paddr_out, pwdata_out, prdata);

initial
    begin
	hclk=1'b0;
	forever #10 hclk=~hclk;
	end
	
task reset;
    begin
	@(negedge hclk)
	hresetn=1'b0;
	@(negedge hclk)
	hresetn=1'b1;
	end
endtask

initial
    begin
	reset;
	//AHB.single_read();
	//AHB.single_write();
	//AHB.burst_4incr_read();
	AHB.burst_4incr_write();
	end
	
endmodule