`timescale 1ns/1ps

module fft(
    input wire clk,
    input wire rst_n,
    // flattened: 16 samples × 16 bits = 256 bits. LSB = sample 0.
    input  wire signed [16*16-1:0] Xin_r_flat,
    input  wire signed [16*16-1:0] Xin_i_flat,
    output wire signed [16*16-1:0] Xout_r_flat,
    output wire signed [16*16-1:0] Xout_i_flat
);

// ----------------- Stage 1 -----------------
wire signed [16*16-1:0] Y_S1_R_flat;
wire signed [16*16-1:0] Y_S1_I_flat;
wire signed [16*16-1:0] X_S1_R_flat;
wire signed [16*16-1:0] X_S1_I_flat;

// Stage 1 BFUs: pairs (0,8),(1,9)...(7,15)
genvar g_s1;
generate
    for (g_s1 = 0; g_s1 < 8; g_s1 = g_s1 + 1) begin : stage1_trivial_gen
        bfu BFU_S1 (
            .Xar( Xin_r_flat[16*(g_s1)   +: 16] ),
            .Xai( Xin_i_flat[16*(g_s1)   +: 16] ),
            .Xbr( Xin_r_flat[16*(g_s1+8) +: 16] ),
            .Xbi( Xin_i_flat[16*(g_s1+8) +: 16] ),
            .Yar( Y_S1_R_flat[16*(g_s1)   +: 16] ),
            .Yai( Y_S1_I_flat[16*(g_s1)   +: 16] ),
            .Ybr( Y_S1_R_flat[16*(g_s1+8) +: 16] ),
            .Ybi( Y_S1_I_flat[16*(g_s1+8) +: 16] )
        );
    end
endgenerate

// Stage register bank 1
stage_reg_bank StageReg1 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in_flat(Y_S1_R_flat),
    .I_in_flat(Y_S1_I_flat),
    .R_out_flat(X_S1_R_flat),
    .I_out_flat(X_S1_I_flat)
);

// ----------------- Twiddle ROMs -----------------
wire signed [16*8-1:0] W_R_flat; // 8 entries × 16 bits
wire signed [16*8-1:0] W_I_flat;

genvar g_rom;
generate
  for (g_rom = 0; g_rom < 8; g_rom = g_rom + 1) begin : rom_instance_gen
    twiddle_rom tw_inst (
      .k(g_rom[2:0]),
      .twiddle_real(W_R_flat[16*g_rom +: 16]),
      .twiddle_img( W_I_flat[16*g_rom +: 16])
    );
  end
endgenerate

// ----------------- Stage 2 -----------------
wire signed [16*16-1:0] Y_S2_R_flat;
wire signed [16*16-1:0] Y_S2_I_flat;
wire signed [16*16-1:0] X_S2_R_flat;
wire signed [16*16-1:0] X_S2_I_flat;

wire signed [16*16-1:0] inter_stage2_real_flat;
wire signed [16*16-1:0] inter_stage2_img_flat;

// --- STAGE 2 MULTIPLIERS (CORRECTED) ---
genvar g_s2;
generate
  for (g_s2 = 0; g_s2 < 16; g_s2 = g_s2 + 1) begin : stage2_mult
    // The bottom 8 samples (8 to 15) need Twiddles W^0 to W^7
    if (g_s2 >= 8) begin
      z_multiplier CMUL_s2 (
        .Ar( X_S1_R_flat[16*g_s2 +: 16] ),
        .Ai( X_S1_I_flat[16*g_s2 +: 16] ),
        // k maps 0..7
        .Br( W_R_flat[16*(g_s2 - 8) +: 16] ),
        .Bi( W_I_flat[16*(g_s2 - 8) +: 16] ),
        .Rout( inter_stage2_real_flat[16*g_s2 +: 16] ),
        .Iout( inter_stage2_img_flat[16*g_s2 +: 16] )
      );
    end else begin
      // Indices 0 to 7 pass through
      assign inter_stage2_real_flat[16*g_s2 +: 16] = X_S1_R_flat[16*g_s2 +: 16];
      assign inter_stage2_img_flat[16*g_s2 +: 16]  = X_S1_I_flat[16*g_s2 +: 16];
    end
  end
endgenerate

// Stage 2 BFUs
genvar g_s2_bf;
generate
  for (g_s2_bf = 0; g_s2_bf < 4; g_s2_bf = g_s2_bf + 1) begin : stage2_gen_1
    // group 0..3 vs 4..7
    bfu BFU_S2_0 (
      .Xar( inter_stage2_real_flat[16*g_s2_bf +: 16] ),
      .Xai( inter_stage2_img_flat[16*g_s2_bf +: 16] ),
      .Xbr( inter_stage2_real_flat[16*(g_s2_bf + 4) +: 16] ),
      .Xbi( inter_stage2_img_flat[16*(g_s2_bf + 4) +: 16] ),
      .Yar( Y_S2_R_flat[16*g_s2_bf +: 16] ),
      .Yai( Y_S2_I_flat[16*g_s2_bf +: 16] ),
      .Ybr( Y_S2_R_flat[16*(g_s2_bf + 4) +: 16] ),
      .Ybi( Y_S2_I_flat[16*(g_s2_bf + 4) +: 16] )
    );

    // group 8..11 vs 12..15
    bfu BFU_S2_1 (
      .Xar( inter_stage2_real_flat[16*(g_s2_bf + 8) +: 16] ),
      .Xai( inter_stage2_img_flat[16*(g_s2_bf + 8) +: 16] ),
      .Xbr( inter_stage2_real_flat[16*(g_s2_bf + 12) +: 16] ),
      .Xbi( inter_stage2_img_flat[16*(g_s2_bf + 12) +: 16] ),
      .Yar( Y_S2_R_flat[16*(g_s2_bf + 8) +: 16] ),
      .Yai( Y_S2_I_flat[16*(g_s2_bf + 8) +: 16] ),
      .Ybr( Y_S2_R_flat[16*(g_s2_bf + 12) +: 16] ),
      .Ybi( Y_S2_I_flat[16*(g_s2_bf + 12) +: 16] )
    );
  end
endgenerate

// Stage register bank 2
stage_reg_bank StageReg2 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in_flat(Y_S2_R_flat),
    .I_in_flat(Y_S2_I_flat),
    .R_out_flat(X_S2_R_flat),
    .I_out_flat(X_S2_I_flat)
);

// ----------------- Stage 3 -----------------
wire signed [16*16-1:0] Y_S3_R_flat;
wire signed [16*16-1:0] Y_S3_I_flat;
wire signed [16*16-1:0] X_S3_R_flat;
wire signed [16*16-1:0] X_S3_I_flat;
wire signed [16*16-1:0] inter_stage3_real_flat;
wire signed [16*16-1:0] inter_stage3_img_flat;

// --- STAGE 3 MULTIPLIERS (CORRECTED) ---
genvar g_s3;
generate
  for (g_s3 = 0; g_s3 < 16; g_s3 = g_s3 + 1) begin : stage3_mult
    // Bottom half of groups of 8: Indices 4-7 and 12-15
    if ( (g_s3 & 4) != 0 ) begin
      // k: 0, 2, 4, 6
      localparam integer _k3 = (g_s3 & 3) * 2;
      
      z_multiplier CMUL_s3 (
        .Ar( X_S2_R_flat[16*g_s3 +: 16] ),
        .Ai( X_S2_I_flat[16*g_s3 +: 16] ),
        .Br( W_R_flat[16*_k3 +: 16] ),
        .Bi( W_I_flat[16*_k3 +: 16] ),
        .Rout( inter_stage3_real_flat[16*g_s3 +: 16] ),
        .Iout( inter_stage3_img_flat[16*g_s3 +: 16] )
      );
    end else begin
      // Pass through
      assign inter_stage3_real_flat[16*g_s3 +: 16] = X_S2_R_flat[16*g_s3 +: 16];
      assign inter_stage3_img_flat[16*g_s3 +: 16]  = X_S2_I_flat[16*g_s3 +: 16];
    end
  end
endgenerate

genvar g_s3_bf;
generate
  for (g_s3_bf = 0; g_s3_bf < 4; g_s3_bf = g_s3_bf + 1) begin : stage3_gen_1
    // pair (0,2), (4,6), (8,10), (12,14)
    bfu BFU_S3_0 (
      .Xar( inter_stage3_real_flat[16*(4*g_s3_bf)     +: 16] ),
      .Xai( inter_stage3_img_flat[16*(4*g_s3_bf)     +: 16] ),
      .Xbr( inter_stage3_real_flat[16*(4*g_s3_bf + 2) +: 16] ),
      .Xbi( inter_stage3_img_flat[16*(4*g_s3_bf + 2) +: 16] ),
      .Yar( Y_S3_R_flat[16*(4*g_s3_bf)     +: 16] ),
      .Yai( Y_S3_I_flat[16*(4*g_s3_bf)     +: 16] ),
      .Ybr( Y_S3_R_flat[16*(4*g_s3_bf + 2) +: 16] ),
      .Ybi( Y_S3_I_flat[16*(4*g_s3_bf + 2) +: 16] )
    );

    // pair (1,3), (5,7), (9,11), (13,15)
    bfu BFU_S3_1 (
      .Xar( inter_stage3_real_flat[16*(4*g_s3_bf + 1) +: 16] ),
      .Xai( inter_stage3_img_flat[16*(4*g_s3_bf + 1) +: 16] ),
      .Xbr( inter_stage3_real_flat[16*(4*g_s3_bf + 3) +: 16] ),
      .Xbi( inter_stage3_img_flat[16*(4*g_s3_bf + 3) +: 16] ),
      .Yar( Y_S3_R_flat[16*(4*g_s3_bf + 1) +: 16] ),
      .Yai( Y_S3_I_flat[16*(4*g_s3_bf + 1) +: 16] ),
      .Ybr( Y_S3_R_flat[16*(4*g_s3_bf + 3) +: 16] ),
      .Ybi( Y_S3_I_flat[16*(4*g_s3_bf + 3) +: 16] )
    );
  end
endgenerate

stage_reg_bank StageReg3 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in_flat(Y_S3_R_flat),
    .I_in_flat(Y_S3_I_flat),
    .R_out_flat(X_S3_R_flat),
    .I_out_flat(X_S3_I_flat)
);

// ----------------- Stage 4 -----------------
wire signed [16*16-1:0] Y_S4_R_flat;
wire signed [16*16-1:0] Y_S4_I_flat;
wire signed [16*16-1:0] X_S4_R_flat;
wire signed [16*16-1:0] X_S4_I_flat;
wire signed [16*16-1:0] inter_stage4_real_flat;
wire signed [16*16-1:0] inter_stage4_img_flat;

// --- STAGE 4 MULTIPLIERS (CORRECTED) ---
genvar g_s4;
generate
  for (g_s4 = 0; g_s4 < 16; g_s4 = g_s4 + 1) begin : stage4_mult
    // Bottom half of groups of 4: Indices 2,3, 6,7, 10,11, 14,15
    if ( (g_s4 & 2) != 0 ) begin
      // k is 0 or 4
      localparam integer _k4 = (g_s4 & 1) * 4;

      z_multiplier CMUL_s4 (
        .Ar( X_S3_R_flat[16*g_s4 +: 16] ),
        .Ai( X_S3_I_flat[16*g_s4 +: 16] ),
        .Br( W_R_flat[16*_k4 +: 16] ),
        .Bi( W_I_flat[16*_k4 +: 16] ),
        .Rout( inter_stage4_real_flat[16*g_s4 +: 16] ),
        .Iout( inter_stage4_img_flat[16*g_s4 +: 16] )
      );
    end else begin
      // Pass through
      assign inter_stage4_real_flat[16*g_s4 +: 16] = X_S3_R_flat[16*g_s4 +: 16];
      assign inter_stage4_img_flat[16*g_s4 +: 16]  = X_S3_I_flat[16*g_s4 +: 16];
    end
  end
endgenerate

genvar g_s4_bf;
generate
  for (g_s4_bf = 0; g_s4_bf < 8; g_s4_bf = g_s4_bf + 1) begin : stage4_gen_1
    bfu BFU_S4 (
      .Xar( inter_stage4_real_flat[16*(2*g_s4_bf)     +: 16] ),
      .Xai( inter_stage4_img_flat[16*(2*g_s4_bf)     +: 16] ),
      .Xbr( inter_stage4_real_flat[16*(2*g_s4_bf + 1) +: 16] ),
      .Xbi( inter_stage4_img_flat[16*(2*g_s4_bf + 1) +: 16] ),
      .Yar( Y_S4_R_flat[16*(2*g_s4_bf)     +: 16] ),
      .Yai( Y_S4_I_flat[16*(2*g_s4_bf)     +: 16] ),
      .Ybr( Y_S4_R_flat[16*(2*g_s4_bf + 1) +: 16] ),
      .Ybi( Y_S4_I_flat[16*(2*g_s4_bf + 1) +: 16] )
    );
  end
endgenerate

// Stage 4 registers
stage_reg_bank StageReg4 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in_flat(Y_S4_R_flat),
    .I_in_flat(Y_S4_I_flat),
    .R_out_flat(X_S4_R_flat),
    .I_out_flat(X_S4_I_flat)
);

// ----------------- Output permutation -----------------
function integer perm;
  input integer idx;
  begin
    case (idx)
      0: perm = 0;
      1: perm = 8;
      2: perm = 4;
      3: perm = 12;
      4: perm = 2;
      5: perm = 10;
      6: perm = 6;
      7: perm = 14;
      8: perm = 1;
      9: perm = 9;
      10: perm = 5;
      11: perm = 13;
      12: perm = 3;
      13: perm = 11;
      14: perm = 7;
      15: perm = 15;
      default: perm = 0;
    endcase
  end
endfunction

genvar g_out;
generate
  for (g_out = 0; g_out < 16; g_out = g_out + 1) begin : out_map
    assign Xout_r_flat[16*g_out +: 16] = X_S4_R_flat[16*perm(g_out) +: 16];
    assign Xout_i_flat[16*g_out +: 16] = X_S4_I_flat[16*perm(g_out) +: 16];
  end
endgenerate

endmodule