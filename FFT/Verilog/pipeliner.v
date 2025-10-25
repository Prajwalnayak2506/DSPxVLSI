module stage_reg_bank (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] R_in [0:15],
    input wire signed [15:0] I_in [0:15],
    output wire signed [15:0] R_out [0:15],
    output wire signed [15:0] I_out [0:15]
);

    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : register_bank_gen
            complex_reg reg_i (
                .clk    (clk),
                .rst_n  (rst_n),
                .R_in   (R_in[i]),
                .I_in   (I_in[i]),
                .R_out  (R_out[i]),
                .I_out  (I_out[i])
            );            
        end
    endgenerate
endmodule