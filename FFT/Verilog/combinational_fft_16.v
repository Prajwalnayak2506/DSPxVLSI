module fft(
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] Xin_r [15:0],
    input wire signed [15:0] Xin_i [15:0],
    output wire signed [15:0] Xout_r [15:0],
    output wire signed [15:0] Xout_i [15:0]
);
wire signed [15:0] Y_S1_R [0:15]; 
wire signed [15:0] Y_S1_I [0:15];
wire signed [15:0] X_S1_R [0:15]; 
wire signed [15:0] X_S1_I [0:15];
// --- STAGE 1: 8 Butterflies (i=0 to 7) ---
generate
    genvar i;
    for (i = 0; i < 8; i = i + 1) begin : stage1_trivial_gen
        bfu_trivial BFU_S1_i (
            .Xar(Xin_r[i]),     .Xai(Xin_i[i]), 
            .Xbr(Xin_r[i + 8]), .Xbi(Xin_i[i + 8]),
            .Yar(Y_S1_R[i]),    .Yai(Y_S1_I[i]), 
            .Ybr(Y_S1_R[i + 8]), .Ybi(Y_S1_I[i + 8])
        );
    end
endgenerate
stage_reg_bank Reg_Bank_S1 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in(Y_S1_R),
    .I_in(Y_S1_I),
    .R_out(X_S1_R), 
    .I_out(X_S1_I)
);
//STage 2
wire signed [15:0] Y_S2_R [0:15]; 
wire signed [15:0] Y_S2_I [0:15]; 
wire signed [15:0] X_S2_R [0:15]; 
wire signed [15:0] X_S2_I [0:15];
wire signed [15:0] inter_stage2_real [0:15];
wire signed [15:0] inter_stage2_img [0:15];
// Wires to hold the 8 unique complex twiddle factors (W^0 to W^7)
wire signed [15:0] W_R [0:7];
wire signed [15:0] W_I [0:7];
generate
    genvar j;
    // Instantiate ROM 8 times to get all 8 constants simultaneously (k=0 through k=7)
    for (j = 0; j < 8; j = j + 1) begin : rom_instance_gen
        
        // The ROM module only needs the constant index 'j' as input
        twiddle_rom W_const_j (
            .k(j),                          // Address input is hardcoded (0, 1, 2, ..., 7)
            .twiddle_real(W_R[j]),          // Output W_R[j]
            .twiddle_img(W_I[j])            // Output W_I[j]
        );
    end
endgenerate
generate
    genvar i;
    for (i = 0; i < 16; i = i + 1) begin : stage2_mult
      if (i<12) begin
        inter_stage2_img[i] = X_S1_I[i];
        inter_stage2_real[i] = X_S1_R[i];
      end
      else begin
        //multiple twiddle factor (W_16^4) with each of thesese
        z_multiplier CMUL_s2(
            .Ar(X_S1_R[i]),        .Ai(X_S1_I[i]),  
            .Br(W_R[4]),  .Bi(W_I[4]),
            .Rout(inter_stage2_real[i]), 
            .Iout(inter_stage2_img[i])  
        );
      end
    end
endgenerate
generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin : stage2_gen_1
        bfu_trivial BFU_S1_1 (
            .Xar(inter_stage2_real[i]),     .Xai(inter_stage2_img[i]), 
            .Xbr(inter_stage2_real[i + 4]), .Xbi(inter_stage2_img[i + 4]),
            .Yar(Y_S2_R[i]),    .Yai(Y_S2_I[i]), 
            .Ybr(Y_S2_R[i + 4]), .Ybi(Y_S2_I[i + 4])
        );
        bfu_trivial BFU_S1_2 (
            .Xar(inter_stage2_real[i+8]),     .Xai(inter_stage2_img[i+8]), 
            .Xbr(inter_stage2_real[i + 4+8]), .Xbi(inter_stage2_img[i + 4+8]),
            .Yar(Y_S2_R[i+8]),    .Yai(Y_S2_I[i+8]), 
            .Ybr(Y_S2_R[i + 4+ 8]), .Ybi(Y_S2_I[i + 4+ 8])
        );
    end
endgenerate
stage_reg_bank Reg_Bank_S2 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in(Y_S2_R),
    .I_in(Y_S2_I),
    .R_out(X_S2_R), 
    .I_out(X_S2_I)
);

//stage 3
wire signed [15:0] Y_S3_R [0:15]; 
wire signed [15:0] Y_S3_I [0:15]; 
wire signed [15:0] X_S3_R [0:15]; 
wire signed [15:0] X_S3_I [0:15];
wire signed [15:0] inter_stage3_real [0:15];
wire signed [15:0] inter_stage3_img [0:15];
generate
    genvar i;
    for (i = 0; i < 16; i = i + 1) begin : stage2_mult
      if (i == 10 || i ==11) begin
        z_multiplier CMUL_s3(
            .Ar(X_S2_R[i]),  .Ai(X_S2_I[i]),  
            .Br(W_R[2]),  .Bi(W_I[2]),
            .Rout(inter_stage3_real[i]), 
            .Iout(inter_stage3_img[i])  
        );
      end
      else if(i == 6 || i == 7) begin
        z_multiplier CMUL_s4(
            .Ar(X_S2_R[i]),  .Ai(X_S2_I[i]),  
            .Br(W_R[4]),  .Bi(W_I[4]),
            .Rout(inter_stage3_real[i]), 
            .Iout(inter_stage3_img[i])  
        );
      end
      else if(i == 14 || i == 15) begin
        z_multiplier CMUL_s5(
            .Ar(X_S2_R[i]),  .Ai(X_S2_I[i]),  
            .Br(W_R[6]),  .Bi(W_I[6]),
            .Rout(inter_stage3_real[i]), 
            .Iout(inter_stage3_img[i])  
        );
      end
      else begin
        //multiple twiddle factor (W_16^4) with each of thesese
        inter_stage3_img[i] = X_S2_I[i];
        inter_stage3_real[i] = X_S2_R[i];        
      end
    end
endgenerate
generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin : stage3_gen_1
        bfu_trivial BFU_S1_6 (
            .Xar(inter_stage3_real[4*i]),     .Xai(inter_stage3_img[4*i]), 
            .Xbr(inter_stage3_real[4*i + 2]), .Xbi(inter_stage3_img[4*i + 2]),
            .Yar(Y_S3_R[4*i]),    .Yai(Y_S3_I[4*i]), 
            .Ybr(Y_S3_R[4*i + 2]), .Ybi(Y_S3_I[4*i + 2])
        );
        bfu_trivial BFU_S1_7 (
            .Xar(inter_stage3_real[4*i+1]),     .Xai(inter_stage3_img[4*i+1]), 
            .Xbr(inter_stage3_real[4*i +1+ 2]), .Xbi(inter_stage3_img[4*i + 2+1]),
            .Yar(Y_S3_R[4*i+1]),    .Yai(Y_S3_I[4*i+1]), 
            .Ybr(Y_S3_R[4*i + 3]), .Ybi(Y_S3_I[4*i + 3])
        );
         
    end
endgenerate
stage_reg_bank Reg_Bank_S3 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in(Y_S3_R),
    .I_in(Y_S3_I),
    .R_out(X_S3_R), 
    .I_out(X_S3_I)
);


//stage 4
wire signed [15:0] Y_S4_R [0:15]; 
wire signed [15:0] Y_S4_I [0:15]; 
wire signed [15:0] X_S4_R [0:15]; 
wire signed [15:0] X_S4_I [0:15];
wire signed [15:0] inter_stage4_real [0:15];
wire signed [15:0] inter_stage4_img [0:15];
generate
    genvar i;
    for (i = 0; i < 16; i = i + 1) begin : stage2_mult
      if (i == 9) begin
        z_multiplier CMUL_s8(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[1]),  .Bi(W_I[1]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else if(i == 5) begin
                z_multiplier CMUL_s9(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[2]),  .Bi(W_I[2]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else if(i == 13) begin
                z_multiplier CMUL_s10(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[3]),  .Bi(W_I[3]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else if(i == 3) begin
                z_multiplier CMUL_s11(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[4]),  .Bi(W_I[4]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else if(i == 11) begin
                z_multiplier CMUL_s12(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[5]),  .Bi(W_I[5]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else if(i == 7) begin
                z_multiplier CMUL_s13(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[6]),  .Bi(W_I[6]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else if(i == 13) begin
                z_multiplier CMUL_s14(
            .Ar(X_S3_R[i]),  .Ai(X_S3_I[i]),  
            .Br(W_R[7]),  .Bi(W_I[7]),
            .Rout(inter_stage4_real[i]), 
            .Iout(inter_stage4_img[i])  
        );
      end
      else begin
        inter_stage4_img[i] = X_S3_I[i];
        inter_stage4_real[i] = X_S3_R[i];        
      end
    end
endgenerate
generate
    genvar i;
    for (i = 0; i < 8; i = i + 1) begin : stage3_gen_1
        bfu_trivial BFU_S1_15 (
            .Xar(inter_stage4_real[2*i]),     .Xai(inter_stage4_img[2*i]), 
            .Xbr(inter_stage4_real[2*i + 1]), .Xbi(inter_stage4_img[2*i + 1]),
            .Yar(Y_S4_R[2*i]),    .Yai(Y_S4_I[2*i]), 
            .Ybr(Y_S4_R[2*i + 1]), .Ybi(Y_S4_I[2*i + 1])
        );
    end
endgenerate
stage_reg_bank Reg_Bank_S4 (
    .clk(clk),
    .rst_n(rst_n),
    .R_in(Y_S4_R),
    .I_in(Y_S4_I),
    .R_out(X_S4_R), 
    .I_out(X_S4_I)
);
assign Xout_r[0] = X_S4_R[0];
assign Xout_i[0] = X_S4_I[0];
assign Xout_r[1] = X_S4_R[8];
assign Xout_i[1] = X_S4_I[8];
assign Xout_r[2] = X_S4_R[4];
assign Xout_i[2] = X_S4_I[4];
assign Xout_r[3] = X_S4_R[12];
assign Xout_i[3] = X_S4_I[12];
assign Xout_r[4] = X_S4_R[2];
assign Xout_i[4] = X_S4_I[2];
assign Xout_r[5] = X_S4_R[10];
assign Xout_i[5] = X_S4_I[10];
assign Xout_r[6] = X_S4_R[6];
assign Xout_i[6] = X_S4_I[6];
assign Xout_r[7] = X_S4_R[14];
assign Xout_i[7] = X_S4_I[14];
assign Xout_r[8] = X_S4_R[1];
assign Xout_i[8] = X_S4_I[1];
assign Xout_r[9] = X_S4_R[9];
assign Xout_i[9] = X_S4_I[9];
assign Xout_r[10] = X_S4_R[5];
assign Xout_i[10] = X_S4_I[5];
assign Xout_r[11] = X_S4_R[13];
assign Xout_i[11] = X_S4_I[13];
assign Xout_r[12] = X_S4_R[3];
assign Xout_i[12] = X_S4_I[3];
assign Xout_r[13] = X_S4_R[11];
assign Xout_i[13] = X_S4_I[11];
assign Xout_r[14] = X_S4_R[7];
assign Xout_i[14] = X_S4_I[7];
assign Xout_r[15] = X_S4_R[15];
assign Xout_i[15] = X_S4_I[15];

endmodule