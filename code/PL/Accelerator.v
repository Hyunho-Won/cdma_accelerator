module Accelerator #
(
	// Users to add parameters here
	//AXI4-lite
	parameter DATA_WIDTH_AXI = 32,
	//BRAM
	parameter integer DATA_WIDTH = 64,
	parameter integer ADDR_WIDTH = 32,
	// User parameters ends
	// Do not modify the parameters beyond this line


	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 6
)
(
	// Users to add ports here
	//BRAM0
	output wire		[ADDR_WIDTH-1:0] 	addr_0,
	output wire		 					ce_0,
	output wire		 					we_0,
	input wire		[DATA_WIDTH-1:0]  	dout_0,
	output wire		[DATA_WIDTH-1:0] 	din_0,
	//BRAM1
	output wire		[ADDR_WIDTH-1:0] 	addr_1,
	output wire		 					ce_1,
	output wire		 					we_1,
	input wire		[DATA_WIDTH-1:0] 	 dout_1,
	output wire		[DATA_WIDTH-1:0] 	din_1,
	// User ports ends
	// Do not modify the ports beyond this line


	// Ports of Axi Slave Bus Interface S00_AXI
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready
);

	wire  				w_run;
	wire [DATA_WIDTH_AXI-1:0]	w_num_cnt;
	wire   				w_idle;
	wire   				w_read;
	wire   				w_write;
	wire    			w_done;
	// Ctrl Side
	wire		[DATA_WIDTH_AXI-1:0]  	result_0	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_1	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_2	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_3	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_4	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_5	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_6	;
	wire		[DATA_WIDTH_AXI-1:0]  	result_7	;

// Instantiation of Axi Bus Interface S00_AXI
	AXI4_lite # ( 
		.DATA_WIDTH_AXI(DATA_WIDTH_AXI),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)

	) u_AXI4_lite (

		.o_run		(w_run),
		.o_num_cnt	(w_num_cnt),
		.i_idle		(w_idle),
		.i_read		(w_read),
		.i_write	(w_write),
		.i_done		(w_done),
		
		.result_0	(result_0		),
		.result_1	(result_1		),
		.result_2	(result_2		),
		.result_3	(result_3		),
		.result_4	(result_4		),
		.result_5	(result_5		),
		.result_6	(result_6		),
		.result_7	(result_7		),

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	bram_to_fc # (
		.DATA_WIDTH_AXI(DATA_WIDTH_AXI),
	// BRAM
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
	// Delay cycle
		.IN_DATA_WITDH (8)
	) u_bram_to_fc(
	    .clk		(s00_axi_aclk	),
	    .reset_n	(s00_axi_aresetn),
		.i_run		(w_run			),
		.i_num_cnt	(w_num_cnt		),
		.o_idle		(w_idle			),
		.o_read		(w_read			),
		.o_write	(w_write		),
		.o_done		(w_done			),
	
		.addr_0		(addr_0			),
		.ce_0		(ce_0			),
		.we_0		(we_0			),
		.dout_0		(dout_0			),
		.din_0		(din_0			),
	
		.addr_1		(addr_1			),
		.ce_1		(ce_1			),
		.we_1		(we_1			),
		.dout_1		(dout_1			),
		.din_1		(din_1			),

		.result_0	(result_0		),
		.result_1	(result_1		),
		.result_2	(result_2		),
		.result_3	(result_3		),
		.result_4	(result_4		),
		.result_5	(result_5		),
		.result_6	(result_6		),
		.result_7	(result_7		)
	);

endmodule
