module cordic_constants (
    input wire [3:0] i, 
    output reg [15:0] alpha_i
);

// Q2.14 Format: 1 sign bit, 2 integer bits, 13 fractional bits.
// Values are in radians * 2^14.

always @(*) begin
    case (i)
        4'd0:  alpha_i = 16'h3244; // arctan(2^-0) = 0.785398 rad (45.000 deg)
        4'd1:  alpha_i = 16'h1DAC; // arctan(2^-1) = 0.463648 rad (26.565 deg)
        4'd2:  alpha_i = 16'h0FAE; // arctan(2^-2) = 0.244979 rad (14.036 deg)
        4'd3:  alpha_i = 16'h07F5; // arctan(2^-3) = 0.124355 rad ( 7.125 deg)
        4'd4:  alpha_i = 16'h03FF; // arctan(2^-4) = 0.062402 rad ( 3.576 deg)
        4'd5:  alpha_i = 16'h0200; // arctan(2^-5) = 0.031239 rad ( 1.789 deg)
        4'd6:  alpha_i = 16'h0100; // arctan(2^-6) = 0.015623 rad ( 0.895 deg)
        4'd7:  alpha_i = 16'h0080; // arctan(2^-7) = 0.007812 rad ( 0.447 deg)
        4'd8:  alpha_i = 16'h0040; // arctan(2^-8) = 0.003906 rad ( 0.224 deg)
        4'd9:  alpha_i = 16'h0020; // arctan(2^-9) = 0.001953 rad ( 0.112 deg)
        4'd10: alpha_i = 16'h0010; // arctan(2^-10) = 0.000977 rad ( 0.056 deg)
        4'd11: alpha_i = 16'h0008; // arctan(2^-11) = 0.000488 rad ( 0.028 deg)
        4'd12: alpha_i = 16'h0004; // arctan(2^-12) = 0.000244 rad ( 0.014 deg)
        4'd13: alpha_i = 16'h0002; // arctan(2^-13) = 0.000122 rad ( 0.007 deg)
        4'd14: alpha_i = 16'h0001; // arctan(2^-14) = 0.000061 rad ( 0.003 deg)
        4'd15: alpha_i = 16'h0000; // arctan(2^-15) approx 0
        default: alpha_i = 16'd0; // Safety default
    endcase
end
endmodule