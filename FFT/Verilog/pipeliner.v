// stage_reg_bank.v - flattened stage register bank (pure Verilog)
// Instantiates 16 complex_reg registers that latch 16-bit complex pairs.

`timescale 1ns/1ps

module stage_reg_bank(
    input wire clk,
    input wire rst_n,
    input wire signed [16*16-1:0] R_in_flat,
    input wire signed [16*16-1:0] I_in_flat,
    output wire signed [16*16-1:0] R_out_flat,
    output wire signed [16*16-1:0] I_out_flat
);

genvar gi;
generate
  for (gi = 0; gi < 16; gi = gi + 1) begin : regbank_gen
    complex_reg creg (
      .clk   (clk),
      .rst_n (rst_n),
      .R_in  (R_in_flat[16*gi +: 16]),
      .I_in  (I_in_flat[16*gi +: 16]),
      .R_out (R_out_flat[16*gi +: 16]),
      .I_out (I_out_flat[16*gi +: 16])
    );
  end
endgenerate

endmodule
