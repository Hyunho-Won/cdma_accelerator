`timescale 1ns / 1ps
module fully_connected_core
#(
	parameter IN_DATA_WITDH = 8
)

(
    input 								clk,
    input 								reset_n,
	input								i_run,
	input 								i_valid,
	input 	[IN_DATA_WITDH-1:0]			i_node,
	input 	[IN_DATA_WITDH-1:0]			i_wegt,
	output  							o_valid,
	output  [(4*IN_DATA_WITDH)-1:0]		o_result
);

reg				                r_valid;
reg                             r_valid_delay;
reg 	[(4*IN_DATA_WITDH)-1:0] r_mult;
wire  	[(2*IN_DATA_WITDH)-1:0] w_mult;
reg 	[(4*IN_DATA_WITDH)-1:0] r_result;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid <= 1'b0;  
    end else if (i_run) begin
        r_valid <= 1'b0;  
    end else begin
		r_valid <= i_valid;
	end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid_delay <= 1'b0;  
    end else if (i_run) begin
        r_valid_delay <= 1'b0;  
    end else begin
		r_valid_delay <= r_valid;
	end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_mult <= {(2*IN_DATA_WITDH){1'b0}};  
    end else if (i_run) begin
        r_mult <= {(2*IN_DATA_WITDH){1'b0}};  
    end else if (i_valid) begin
		r_mult <= w_mult;
	end
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_result <= {(4*IN_DATA_WITDH){1'b0}};  
    end else if (i_run) begin
        r_result <= {(4*IN_DATA_WITDH){1'b0}};  
    end else if (r_valid) begin
		r_result <= r_result + r_mult;
	end
end

assign o_valid 	= r_valid_delay;
assign w_mult = i_node * i_wegt;
assign o_result = r_result;

endmodule
