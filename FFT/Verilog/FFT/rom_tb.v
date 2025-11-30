`timescale 1ns / 1ps

module rom_tb;

    // --- 1. DUT Signals (Matching ROM Ports) ---
    reg  [2:0] k_tb;
    wire signed [15:0] twiddle_real_tb;
    wire signed [15:0] twiddle_img_tb;

    // --- Twiddle Factor Constants (Expected Values) ---
    // Q1.14 values from your ROM
    localparam W0_R  = 16384;  // W^0 Real: 1.0
    localparam W0_I  = 0;      // W^0 Imag: 0.0
    localparam W4_R  = 0;      // W^4 Real: 0.0
    localparam W4_I  = -16384; // W^4 Imag: -1.0
    localparam W1_R  = 15132;  // W^1 Real: 0.9239
    localparam W1_I  = -6271;  // W^1 Imag: -0.3827
    localparam W7_R  = -15164; // W^7 Real: -0.9239
    localparam W7_I  = -6271;  // W^7 Imag: -0.3827

    // --- 2. Instantiate the DUT ---
    // NOTE: Your ROM code used 'address' internally, but the port is 'k'. 
    // Assuming the ROM module was corrected to use 'k' for indexing.
    twiddle_rom DUT (
        .k(k_tb),
        .twiddle_real(twiddle_real_tb),
        .twiddle_img(twiddle_img_tb)
    );

    // --- 3. Test Stimulus ---
    initial begin
        k_tb = 0; // Initialize address

        $display("--- Starting Twiddle ROM Testbench (Q1.14) ---");
        #10; 

        // -------------------------------------------------------------------
        // TEST 1: Trivial W^0 (k=0) - Checks 1.0 + j0
        // -------------------------------------------------------------------
        $display("\n--- TEST 1: k=0 (W^0) ---");
        k_tb = 3'd0;
        #10;
        $display("Actual: R=%d, I=%d. Expected: R=%d, I=%d", 
                  twiddle_real_tb, twiddle_img_tb, W0_R, W0_I);
        if (twiddle_real_tb == W0_R && twiddle_img_tb == W0_I)
            $display("PASS: W^0 (1 + j0) correct.");
        else
            $display("FAIL: W^0 incorrect.");

        // -------------------------------------------------------------------
        // TEST 2: Trivial W^4 (k=4) - Checks 0 - j1.0
        // -------------------------------------------------------------------
        $display("\n--- TEST 2: k=4 (W^4) ---");
        k_tb = 3'd4;
        #10;
        $display("Actual: R=%d, I=%d. Expected: R=%d, I=%d", 
                  twiddle_real_tb, twiddle_img_tb, W4_R, W4_I);
        if (twiddle_real_tb == W4_R && twiddle_img_tb == W4_I)
            $display("PASS: W^4 (0 - j1.0) correct.");
        else
            $display("FAIL: W^4 incorrect.");

        // -------------------------------------------------------------------
        // TEST 3: Non-Trivial W^1 (k=1) - Checks complex fractional values
        // -------------------------------------------------------------------
        $display("\n--- TEST 3: k=1 (W^1) ---");
        k_tb = 3'd1;
        #10;
        $display("Actual: R=%d, I=%d. Expected: R=%d, I=%d", 
                  twiddle_real_tb, twiddle_img_tb, W1_R, W1_I);
        if (twiddle_real_tb == W1_R && twiddle_img_tb == W1_I)
            $display("PASS: W^1 correct.");
        else
            $display("FAIL: W^1 incorrect.");

        // -------------------------------------------------------------------
        // TEST 4: Boundary Negative W^7 (k=7) - Checks maximum negative real part
        // -------------------------------------------------------------------
        $display("\n--- TEST 4: k=7 (W^7) ---");
        k_tb = 3'd7;
        #10;
        $display("Actual: R=%d, I=%d. Expected: R=%d, I=%d", 
                  twiddle_real_tb, twiddle_img_tb, W7_R, W7_I);
        if (twiddle_real_tb == W7_R && twiddle_img_tb == W7_I)
            $display("PASS: W^7 correct.");
        else
            $display("FAIL: W^7 incorrect.");

        $finish;
    end
endmodule