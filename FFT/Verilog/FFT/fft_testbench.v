`timescale 1ns/1ps

module fft_testbench;

    reg clk;
    reg rst_n;
    integer i; // Loop variable

    reg  signed [255:0] Xin_r_flat;
    reg  signed [255:0] Xin_i_flat;
    wire signed [255:0] Xout_r_flat;
    wire signed [255:0] Xout_i_flat;

    // -------------------------
    // Instantiate FFT DUT
    // -------------------------
    fft dut (
        .clk(clk),
        .rst_n(rst_n),
        .Xin_r_flat(Xin_r_flat),
        .Xin_i_flat(Xin_i_flat),
        .Xout_r_flat(Xout_r_flat),
        .Xout_i_flat(Xout_i_flat)
    );

    // -------------------------
    // Clock Generation
    // -------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz (10ns period)
    end

    // -------------------------
    // Stimulus
    // -------------------------
    initial begin
        $dumpfile("fft.vcd");
        $dumpvars(0, fft_testbench);

        // --- Initialize ---
        rst_n = 0;
        Xin_r_flat = 0;
        Xin_i_flat = 0;

        #20;
        rst_n = 1;
        
        // ============================================================
        // CASE 1: DC CONSTANT INPUT
        // Input: 1.0 (Q5.10 = 1024) for ALL samples
        // ============================================================
        $display("Applying DC Constant Input (All 1.0)...");
        
        // Use a loop to set all 16 samples to 1024 (16'h0400)
        for (i = 0; i < 16; i = i + 1) begin
            Xin_r_flat[16*i +: 16] = 16'sd1024; 
        end
        Xin_i_flat = 0;

        // Wait for FFT processing (approx 20-30 cycles for data to flush out)
        #300; 

        // ============================================================
        // CASE 2: IMPULSE INPUT
        // Input: Sample 0 = 1.0, Others = 0
        // Triggered after previous test + delay
        // ============================================================
        $display("Applying Impulse Input (Sample[0]=1.0)...");

        // Clear all inputs first
        Xin_r_flat = 0;
        
        // Set only the LSB sample (Sample 0) to 1.0
        Xin_r_flat[15:0] = 16'sd1024;
        
        // Wait for FFT processing
        #300;

        $display("Simulation finished.");
        $finish;
    end

endmodule