`timescale 1ns/1ps

module ofdm_tx_pipeline (
    input wire clk,
    input wire rst_n,
    input wire [23:0] data_in,      // 24-bit input stream
    output wire signed [255:0] tx_out_r, // Time-domain OFDM Symbol (Real)
    output wire signed [255:0] tx_out_i  // Time-domain OFDM Symbol (Imag)
);

    // ============================================================
    // STAGE 1: QAM MAPPING
    // ============================================================
    wire [95:0] qam_r_wire;
    wire [95:0] qam_i_wire;

    qam u_qam (
        .A(data_in),
        .R(qam_r_wire),
        .I(qam_i_wire)
    );

    // --- PIPELINE REGISTER 1 (QAM -> MAPPER) ---
    reg [95:0] reg_qam_r;
    reg [95:0] reg_qam_i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_qam_r <= 96'd0;
            reg_qam_i <= 96'd0;
        end else begin
            reg_qam_r <= qam_r_wire;
            reg_qam_i <= qam_i_wire;
        end
    end

    // ============================================================
    // STAGE 2: SUBCARRIER MAPPING
    // ============================================================
    wire [255:0] map_r_wire;
    wire [255:0] map_i_wire;

    data_mapper u_mapper (
        .DATA_IN_R(reg_qam_r),
        .DATA_IN_I(reg_qam_i),
        .SC_OUT_R(map_r_wire),
        .SC_OUT_I(map_i_wire)
    );

    // --- PIPELINE REGISTER 2 (MAPPER -> IFFT) ---
    reg signed [255:0] reg_map_r;
    reg signed [255:0] reg_map_i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_map_r <= 256'd0;
            reg_map_i <= 256'd0;
        end else begin
            reg_map_r <= map_r_wire;
            reg_map_i <= map_i_wire;
        end
    end

    // ============================================================
    // STAGE 3: IFFT PROCESSOR (Using FFT Core)
    // Trick: Swap Real/Imag inputs AND Swap Real/Imag outputs
    // to perform Inverse FFT with standard FFT weights.
    // ============================================================
    
    wire signed [255:0] fft_out_r_internal;
    wire signed [255:0] fft_out_i_internal;

    fft u_fft_core (
        .clk(clk),
        .rst_n(rst_n),
        // SWAP INPUTS: Real port gets Imag data, Imag port gets Real data
        .Xin_r_flat(reg_map_i), 
        .Xin_i_flat(reg_map_r),
        // Internal outputs (still bit-reversed if perm wasn't there, but it is)
        .Xout_r_flat(fft_out_r_internal),
        .Xout_i_flat(fft_out_i_internal)
    );

    // SWAP OUTPUTS: Real output comes from Imag port, Imag from Real port
    assign tx_out_r = fft_out_i_internal;
    assign tx_out_i = fft_out_r_internal;

endmodule