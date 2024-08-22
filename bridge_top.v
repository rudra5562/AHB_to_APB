module ahb_slave_interface(hclk, hresetn, hwrite, hreadyin, htrans, haddr, hwdata, prdata, hrdata, valid, haddr1, haddr2, hwdata1, hwdata2, hwritereg, hwritereg1, tempselx);

input hclk, hresetn, hwrite, hreadyin;
input [1:0]htrans;
input [31:0] haddr, hwdata, prdata;
output reg valid;
output reg hwritereg, hwritereg1;
output reg [2:0]tempselx; 
output reg [31:0] haddr1, haddr2, hwdata1, hwdata2;
output [31:0]hrdata;

//pipelining of haddress
always@(posedge hclk)
    begin
	    if(!hresetn)
		    begin
			haddr1<=0;
			haddr2<=0;
			end
		else
		    begin
			haddr1<=haddr;
			haddr2<=haddr1;
			end
	end
	
//pipelining of hdata
always@(posedge hclk)
    begin
	    if(!hresetn)
		    begin
			hwdata1<=0;
			hwdata2<=0;
			end
		else
		    begin
			hwdata1<=hwdata;
			hwdata2<=hwdata1;
			end
	end
	
//pipelining of hwrite
always@(posedge hclk)
    begin
	    if(!hresetn)
		    begin
			hwritereg<=0;
			hwritereg1<=0;
			end
		else
		    begin
			hwritereg<=hwrite;
			hwritereg1<=hwritereg;
			end
	end
	
always@(*)
    begin
	    if( hreadyin && haddr>=32'h8000_0000 && haddr<32'h8c00_0000 && (htrans==2'b10 || htrans==2'b11))
        valid <= 1;
        else	
        valid <= 0;
	end

always@(*)
    begin
	    if(haddr>=32'h8000_0000 && haddr<32'h8400_0000)
		tempselx <= 3'b001;
		else if (haddr>=32'h8400_0000 && haddr<32'h8800_0000)
		tempselx <= 3'b010;
		else if (haddr>=32'h8800_0000 && haddr<32'h8c00_0000)
		tempselx <= 3'b100;
		else
		tempselx <= 3'b000;
	end
	
assign hrdata = prdata;

endmodule



module apb_controller(hclk, hresetn, valid, haddr, haddr1, haddr2, hwdata, hwdata1, hwdata2, hwrite, hwritereg, hwritereg1, tempselx, hreadyout, pwrite, penable, pselx, pwdata, paddr);

input hclk, hresetn, valid, hwrite, hwritereg, hwritereg1;
input [31:0] haddr, haddr1, haddr2, hwdata, hwdata1, hwdata2;
input [2:0]tempselx;
output reg pwrite, penable, hreadyout;
output reg [31:0] pwdata, paddr; 
output reg [2:0]pselx;

reg [2:0]present_state, next_state;

parameter ST_IDLE = 3'b000, ST_WWAIT = 3'b001, ST_READ = 3'b010, ST_RENABLE = 3'b011, ST_WRITE = 3'b100, ST_WRITEP = 3'b101, ST_WENABLE = 3'b110, ST_WENABLEP = 3'b111;

reg penable_temp, pwrite_temp, hreadyout_temp;
reg [2:0]pselx_temp;
reg [31:0]paddr_temp,pwdata_temp;

//present state logic
always@(posedge hclk)
    begin
	if(!hresetn)
	    present_state<=ST_IDLE;
	else
	    present_state<=next_state;
	end
	
//next state logic
always@(*)
    begin
	next_state=ST_IDLE;
	case(present_state)
	ST_IDLE: if(valid==1 && hwrite==1)
	             next_state=ST_WWAIT;
			 else if (valid==1 && hwrite==0)
			     next_state=ST_READ;
			 else
			     next_state=ST_IDLE;
				 
    ST_READ: next_state=ST_RENABLE;

    ST_WWAIT: if(valid==1)
                 next_state=ST_WRITEP;
              else 
                 next_state=ST_WRITE;
    
    ST_WRITEP: next_state=ST_WENABLEP;

    ST_WRITE: if(valid==1)
                 next_state=ST_WENABLEP;
              else 
                 next_state=ST_WENABLE;

    ST_WENABLEP: if(valid==1 && hwritereg==1)
	                 next_state=ST_WRITEP;
			     else if (valid==0 && hwritereg==1)
			         next_state=ST_WRITE;
			     else
			         next_state=ST_READ;
					 
    ST_WENABLE: if(valid==1 && hwrite==1)
	                 next_state=ST_WWAIT;
			     else if (valid==1 && hwrite==0)
			         next_state=ST_READ;
			     else
			         next_state=ST_IDLE;
					 
	ST_RENABLE: if(valid==1 && hwrite==1)
	                 next_state=ST_WWAIT;
			     else if (valid==1 && hwrite==0)
			         next_state=ST_READ;
			     else
			         next_state=ST_IDLE;
	endcase
	end
	
//temporary output logic
always@(*)
    begin
	case(present_state)
	ST_IDLE: if(valid==1 && hwrite==0)
	             begin
				 paddr_temp=haddr;
				 pwrite_temp=hwrite;
				 pselx_temp=tempselx;
				 penable_temp=0;
				 hreadyout_temp=0;
				 end
			 else if(valid==1 && hwrite==1)
			     begin
				 pselx_temp=0;
				 penable_temp=0;
				 hreadyout_temp=1;
				 end
			 else
			     begin
			     pselx_temp=0;
				 penable_temp=0;
				 hreadyout_temp=1;
				 end
				 
	ST_READ: begin
	         penable_temp=1;
			 hreadyout_temp=1;
			 end
			 
	ST_RENABLE: if(valid==1 && hwrite==0)
	                begin
				    paddr_temp=haddr;
				    pwrite_temp=hwrite;
				    pselx_temp=tempselx;
				    penable_temp=0;
				    hreadyout_temp=0;
				    end
				else if(valid==1 && hwrite==1)
			        begin
				    pselx_temp=0;
				    penable_temp=0;
				    hreadyout_temp=1;
				    end
			    else
			        begin
			        pselx_temp=0;
				    penable_temp=0;
				    hreadyout_temp=1;
				    end
					
	ST_WWAIT: begin
	          paddr_temp=haddr1;
			  pwdata_temp=hwdata;
			  pwrite_temp=hwrite;
			  pselx_temp=tempselx;
			  penable_temp=0;
			  hreadyout_temp=0;
			  end
			  
	ST_WRITE: begin 
	          penable_temp=1;
			  hreadyout_temp=1;
			  end
			  
	ST_WRITEP: begin 
	           penable_temp=1;
			   hreadyout_temp=1;
			   end
				 
	ST_WENABLEP: begin
	             paddr_temp=haddr2;
			     pwdata_temp=hwdata1;
			     pwrite_temp=hwritereg;
			     pselx_temp=tempselx;
			     penable_temp=0;
			     hreadyout_temp=0;
			     end
				 
	ST_WENABLE: if(valid==1 && hwrite==0)
	                begin
				    paddr_temp=haddr2;
				    pwrite_temp=hwrite;
				    pselx_temp=tempselx;
				    penable_temp=0;
				    hreadyout_temp=0;
				    end
				else if(valid==1 && hwrite==1)
			        begin
				    pselx_temp=0;
				    penable_temp=0;
				    hreadyout_temp=1;
				    end
				else
			        begin
			        pselx_temp=0;
				    penable_temp=0;
				    hreadyout_temp=1;
				    end
	endcase
	end

//actual output logic
always@(posedge hclk)
    begin
	if(!hresetn)
	    begin
		paddr<=0;
		pwdata<=0;
		pwrite<=0;
		pselx<=0;
		penable<=0;
		hreadyout<=1;
		end
	else
	    begin
		paddr<=paddr_temp;
		pwdata<=pwdata_temp;
		pwrite<=pwrite_temp;
		pselx<=pselx_temp;
		penable<=penable_temp;
		hreadyout<=hreadyout_temp;
		end
	end
	
endmodule




module bridge_top(input hclk, hresetn, hwrite, hreadyin, input [1:0]htrans, input [31:0] haddr, hwdata, prdata, output pwrite, penable, hreadyout, output [31:0] pwdata, paddr, hrdata, output [2:0]pselx, output [1:0]hresp);

wire [31:0] haddr1, haddr2, hwdata1, hwdata2;
wire [2:0]tempselx;
wire hwritereg, hwritereg1;
wire valid;

ahb_slave_interface A1(hclk, hresetn, hwrite, hreadyin, htrans, haddr, hwdata, prdata, hrdata, valid, haddr1, haddr2, hwdata1, hwdata2, hwritereg, hwritereg1, tempselx);

apb_controller A2(hclk, hresetn, valid, haddr, haddr1, haddr2, hwdata, hwdata1, hwdata2, hwrite, hwritereg, hwritereg1, tempselx, hreadyout, pwrite, penable, pselx, pwdata, paddr);

endmodule

module ahb_master(input hclk, hresetn, hreadyout, input [31:0]hrdata, output reg [31:0] haddr, hwdata, output reg hwrite, hreadyin, output reg [1:0] htrans);

reg [2:0]hburst; //single,4,8,16,.....
reg [2:0]hsize; //size,8,16,32bit,....
integer i=0;

task single_write();
    begin
    @(posedge hclk)
    #1;
        begin
        hwrite=1;
        htrans=2'b10;
        hsize=0;
        hburst=0;
        hreadyin=1;
        haddr=32'h8000_0000;
        end
    @(posedge hclk)
    #1;
        begin
        hwdata=32'h24;
        htrans=2'b00;
        end
    end
endtask	

task single_read();
    begin
	@(posedge hclk)
    #1;
        begin
        hwrite=0;
        htrans=2'b10;
        hsize=0;
        hburst=0;
        hreadyin=1;
        haddr=32'h8000_0000;
        end
    @(posedge hclk)
    #1;
        begin
        htrans=2'b00;
        end
    end
endtask

task burst_4incr_write();
    begin
	@(posedge hclk)
    #1;
        begin
        hwrite=1;
        htrans=2'b10;
        hsize=0;
        hburst=3'b001;
        hreadyin=1;
        haddr=32'h8000_0000;
        end
    @(posedge hclk)
    #1;
        begin
		haddr=haddr+1;
		hwdata={$random}%256;
        htrans=2'b11;
        end
	for(i=0;i<2;i=i+1)
	    begin
		@(posedge hclk)
		#1;
		    begin
			haddr=haddr+1;
			hwdata={$random}%256;
			htrans=2'b11;
			end
		@(posedge hclk)
		#1;
	    end
    @(posedge hclk)
	#1;
	    begin
		hwdata={$random}%256;
		htrans=2'b00;
		end
    end
endtask   

task burst_4incr_read();
    begin
	@(posedge hclk)
    #1;
        begin
        hwrite=0;
        htrans=2'b10;
        hsize=0;
        hburst=3'b001;
        hreadyin=1;
        haddr=32'h8000_0000;
        end
	for(i=0;i<3;i=i+1)
	    begin
		@(posedge hclk)
		#1;
		    begin
			haddr=haddr+1;
			htrans=2'b11;
			end
		@(posedge hclk)
		#1;
		end
    @(posedge hclk)
	#1;
		htrans=2'b00;
    end
endtask

endmodule

  

module apb_interface(input pwrite, penable, input [2:0] pselx, input [31:0] paddr, pwdata, output pwrite_out, penable_out, output [2:0] pselx_out, output [31:0] paddr_out, pwdata_out, output reg [31:0] prdata);

 assign pwrite_out=pwrite;
 assign paddr_out=paddr;
 assign pselx_out=pselx;
 assign pwdata_out=pwdata;
 assign penable_out=penable;
 
 always@(*)
     begin
	     if(!pwrite && penable)
	     prdata={$random}%256;
	     else
		  prdata=32'h0;
	  end

endmodule


