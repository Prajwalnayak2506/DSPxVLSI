module cordic_constants (
    input wire [3:0] i, 
    output reg [15:0] alpha_i
);

// Format: Q3.12 (Scale Factor = 4096)
// Values are fixed-point representation of arctan(2^-i) in radians.

always @(*) begin
    case (i)
        4'd0:  alpha_i = 16'h0C91; // 0.785398 rad
        4'd1:  alpha_i = 16'h0773; // 0.463648 rad
        4'd2:  alpha_i = 16'h03EB; // 0.244979 rad
        4'd3:  alpha_i = 16'h01FD; // 0.124355 rad
        4'd4:  alpha_i = 16'h00FF; // 0.062402 rad
        4'd5:  alpha_i = 16'h0080; // 0.031239 rad
        4'd6:  alpha_i = 16'h0040; // 0.015623 rad
        4'd7:  alpha_i = 16'h0020; // 0.007812 rad
        4'd8:  alpha_i = 16'h0010; // 0.003906 rad
        4'd9:  alpha_i = 16'h0008; // 0.001953 rad
        4'd10: alpha_i = 16'h0004; // 0.000977 rad
        4'd11: alpha_i = 16'h0002; // 0.000488 rad
        4'd12: alpha_i = 16'h0001; // 0.000244 rad
        4'd13: alpha_i = 16'h0000;
        4'd14: alpha_i = 16'h0000;
        4'd15: alpha_i = 16'h0000;
        default: alpha_i = 16'd0; 
    endcase
end
endmodule