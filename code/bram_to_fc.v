`timescale 1ns / 1ps
module bram_to_fc
// Param
#(
	//AXI4-lite
	parameter DATA_WIDTH_AXI = 32,
	//BRAM0
	parameter integer DATA_WIDTH = 64,
	parameter integer ADDR_WIDTH = 32,
	
	parameter IN_DATA_WITDH = 8
)
(
    input 						clk,
    input 						reset_n,
	input 						i_run,
	input  [DATA_WIDTH_AXI-2:0]	i_num_cnt,
	output   					o_idle,
	output   					o_read,
	output   					o_write,
	output  					o_done,

	//BRAM0
	output[ADDR_WIDTH-1:0]  addr_0,
	output 					ce_0,
	output 					we_0,
	input [DATA_WIDTH-1:0]  dout_0,
	output[DATA_WIDTH-1:0]  din_0,

	//BRAM1	
	output[ADDR_WIDTH-1:0]  addr_1,
	output 					ce_1,
	output 					we_1,
	input [DATA_WIDTH-1:0]  dout_1,
	output[DATA_WIDTH-1:0]  din_1,

	output[DATA_WIDTH_AXI-1:0]  result_0,
	output[DATA_WIDTH_AXI-1:0]  result_1,
	output[DATA_WIDTH_AXI-1:0]  result_2,
	output[DATA_WIDTH_AXI-1:0]  result_3,
	output[DATA_WIDTH_AXI-1:0]  result_4,
	output[DATA_WIDTH_AXI-1:0]  result_5,
	output[DATA_WIDTH_AXI-1:0]  result_6,
	output[DATA_WIDTH_AXI-1:0]  result_7
    );
localparam IDLE	 = 2'b00;
localparam READ	 = 2'b01;
localparam WRITE = 2'b10;
localparam DONE  = 2'b11;

reg [1:0] current_state;
reg [1:0] next_state;
wire	  is_write_done;
wire	  is_read_done;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
		current_state <= IDLE;
    end else begin
		current_state <= next_state;
    end
end

always @(*)
begin
	case(current_state)
	IDLE	: if(i_run)
				next_state = READ;
			  else
				next_state = IDLE;
	READ    : if(is_read_done)
				next_state = WRITE;
			  else 
				next_state = READ;
	WRITE	: if(is_write_done)
				next_state = DONE;
			  else
				next_state = WRITE;
	DONE	:	next_state = IDLE;
	endcase
end 

assign o_idle 		= (current_state == IDLE);
assign o_read 		= (current_state == READ);
assign o_write 		= (current_state == WRITE);
assign o_done 		= (current_state == DONE);

reg [DATA_WIDTH_AXI-2:0] num_cnt;  
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        num_cnt <= 0;  
    end else if (i_run) begin
        num_cnt <= i_num_cnt;
	end else if (o_done) begin
		num_cnt <= 0;
	end
end

reg [DATA_WIDTH_AXI-1:0] addr_cnt; 
 
assign is_read_done  = o_read  && (addr_cnt >= num_cnt-1);
assign is_write_done = o_write && (addr_cnt >= num_cnt-1);
wire result_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        addr_cnt <= 0;
    end else if (is_read_done || is_write_done) begin
        addr_cnt <= 0;
    end else if (o_read || (o_write && result_valid)) begin
        addr_cnt <= addr_cnt + 8;
	end
end

// 1 cycle latency to sync mem output
reg 				r_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid <= {DATA_WIDTH{1'b0}};  
    end else begin
		r_valid <= o_read; // read data
	end
end

assign addr_0 	= addr_cnt;
assign ce_0 	= o_read;
assign we_0 	= 1'b0;
assign din_0	= {DATA_WIDTH{1'b0}};

wire [DATA_WIDTH-1:0] 	mem_data_0;
assign mem_data_0 = dout_0;  

assign addr_1 	= addr_cnt;
assign ce_1 	= o_read;
assign we_1 	= 1'b0;
assign din_1	= {DATA_WIDTH{1'b0}};

wire [DATA_WIDTH-1:0] 	mem_data_1;
assign mem_data_1 = dout_1;   

wire	[IN_DATA_WITDH-1:0]	    w_a_0	 	= mem_data_0[(8*IN_DATA_WITDH)-1:(7*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_0	 	= mem_data_1[(8*IN_DATA_WITDH)-1:(7*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_0	;
wire 							w_valid_0 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_1	 	= mem_data_0[(7*IN_DATA_WITDH)-1:(6*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_1	 	= mem_data_1[(7*IN_DATA_WITDH)-1:(6*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_1	;
wire 							w_valid_1 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_2	 	= mem_data_0[(6*IN_DATA_WITDH)-1:(5*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_2	 	= mem_data_1[(6*IN_DATA_WITDH)-1:(5*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_2	;
wire 							w_valid_2 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_3	 	= mem_data_0[(5*IN_DATA_WITDH)-1:(4*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_3	 	= mem_data_1[(5*IN_DATA_WITDH)-1:(4*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_3	;
wire 							w_valid_3 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_4	 	= mem_data_0[(4*IN_DATA_WITDH)-1:(3*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_4	 	= mem_data_1[(4*IN_DATA_WITDH)-1:(3*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_4	;
wire 							w_valid_4 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_5	 	= mem_data_0[(3*IN_DATA_WITDH)-1:(2*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_5	 	= mem_data_1[(3*IN_DATA_WITDH)-1:(2*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_5	;
wire 							w_valid_5 	;

wire	[IN_DATA_WITDH-1:0]	    w_a_6	 	= mem_data_0[(2*IN_DATA_WITDH)-1:(1*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_6	 	= mem_data_1[(2*IN_DATA_WITDH)-1:(1*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_6	;
wire 							w_valid_6	;

wire	[IN_DATA_WITDH-1:0]	    w_a_7	 	= mem_data_0[(1*IN_DATA_WITDH)-1:(0*IN_DATA_WITDH)];
wire	[IN_DATA_WITDH-1:0]	    w_b_7	 	= mem_data_1[(1*IN_DATA_WITDH)-1:(0*IN_DATA_WITDH)];
wire	[(8*IN_DATA_WITDH)-1:0] w_result_7	;
wire 							w_valid_7 	;

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_0(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_0	 	),
	.i_wegt		(w_b_0	 	),
	.o_result	(w_result_0	),
	.o_valid	(w_valid_0	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_1(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_1	 	),
	.i_wegt		(w_b_1	 	),
	.o_result	(w_result_1	),
	.o_valid	(w_valid_1	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_2(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_2	 	),
	.i_wegt		(w_b_2	 	),
	.o_result	(w_result_2	),
	.o_valid	(w_valid_2	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_3(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_3	 	),
	.i_wegt		(w_b_3	 	),
	.o_result	(w_result_3	),
	.o_valid	(w_valid_3	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_4(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_4	 	),
	.i_wegt		(w_b_4	 	),
	.o_result	(w_result_4	),
	.o_valid	(w_valid_4	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_5(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_5	 	),
	.i_wegt		(w_b_5	 	),
	.o_result	(w_result_5	),
	.o_valid	(w_valid_5	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_6(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_6	 	),
	.i_wegt		(w_b_6	 	),
	.o_result	(w_result_6	),
	.o_valid	(w_valid_6	)
);

fully_connected_core
// Param
#(
	.IN_DATA_WITDH (IN_DATA_WITDH)
)
u_fully_connected_core_8b_7(
    .clk		(clk	 	),
    .reset_n	(reset_n 	),
	.i_run		(i_run		),
	.i_valid	(r_valid 	),
	.i_node		(w_a_7	 	),
	.i_wegt		(w_b_7	 	),
	.o_result	(w_result_7	),
	.o_valid	(w_valid_7	)
);


assign result_valid = w_valid_0 & w_valid_1 & w_valid_2 & w_valid_3 & w_valid_4 & w_valid_5 & w_valid_6 & w_valid_7;
assign result_0 	= w_result_0;
assign result_1 	= w_result_1;
assign result_2 	= w_result_2;
assign result_3 	= w_result_3;
assign result_4 	= w_result_4;
assign result_5 	= w_result_5;
assign result_6 	= w_result_6;
assign result_7 	= w_result_7;
endmodule
