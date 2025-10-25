module z_multiplier(
    input wire signed [15:0] Ar,
    input wire signed [15:0] Ai,
    input wire signed [15:0] Br,
    input wire signed [15:0] Bi,
    output wire signed [15:0] Rout,
    output wire signed [15:0] Iout
);


wire signed [31:0] P_rr;   
wire signed [31:0] P_ii;   
wire signed [31:0] P_ii_not;
wire signed [31:0] P_ri;
wire signed [31:0] P_ir;
wire signed [31:0] R_sum;  
wire signed [31:0] I_sum;  

assign P_rr = Ar * Br; 
assign P_ii = Ai * Bi;
assign P_ri = Ar * Bi;
assign P_ir = Ai * Br;

assign P_ii_not = ~($signed(P_ii)); 

kogge_stone_32bit adder1 (
    .A   (P_rr),
    .B   (P_ii_not), 
    .CIN (1'b1),   
    .Y   (R_sum),
    .COUT()
);

kogge_stone_32bit adder2 (
    .A   (P_ri),
    .B   (P_ir),
    .CIN (1'b0),
    .Y   (I_sum),
    .COUT()
);

assign Rout = R_sum >>> 14;
assign Iout = I_sum >>> 14;
endmodule