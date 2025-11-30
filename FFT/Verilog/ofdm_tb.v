`timescale 1ns/1ps

module ofdm_system_tb;

    reg clk;
    reg rst_n;
    reg [23:0] data_in;
    wire signed [255:0] tx_out_r;
    wire signed [255:0] tx_out_i;

    // Instantiate Top Module
    ofdm_tx_pipeline dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .tx_out_r(tx_out_r),
        .tx_out_i(tx_out_i)
    );

    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Helper to print 16-bit signed values from flat bus
    task print_outputs;
        integer k;
        reg signed [15:0] val_r, val_i;
        begin
            $display("--- IFFT Output (OFDM Time Domain Symbol) ---");
            for (k=0; k<16; k=k+1) begin
                // Extract 16-bit slices
                val_r = tx_out_r[16*k +: 16];
                val_i = tx_out_i[16*k +: 16];
                
                // Display Index and Values
                $display("Sample %02d: Real = %6d, Imag = %6d", k, val_r, val_i);
            end
        end
    endtask

    initial begin
        $dumpfile("ofdm_tx.vcd");
        $dumpvars(0, ofdm_system_tb);

        // 1. Reset
        rst_n = 0;
        data_in = 0;
        #20;
        rst_n = 1;

        // 2. Apply Maximum Energy Input
        // 24'hFFFFFF maps to the corner points of the 16-QAM constellation (+3/-3)
        // This is the "Stress Test" for Overflow.
        @(posedge clk);
        data_in = 24'hFFFFFF; 
        
        // 3. Wait for Pipeline + IFFT Latency
        // Pipeline Depth = 2 cycles
        // FFT Latency = approx 4-5 cycles
        // Wait 15 cycles to be safe and see stable output
        repeat(15) @(posedge clk);

        // 4. Print Results
        print_outputs();

        // 5. Finish
        $finish;
    end

endmodule