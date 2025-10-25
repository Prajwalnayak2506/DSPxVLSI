`timescale 1ns / 1ps

module z_multiplier_tb;

    // --- Fixed-Point Parameters (Q1.14) ---
    localparam SCALE_FACTOR = 14;
    localparam DATA_WIDTH = 16;
    localparam Q_EXPONENT = 2**SCALE_FACTOR; // 16384

    // Positive Values (Q1.14 representation)
    localparam Q_ONE     = 16'h4000;  // 1.0 (16384 decimal)
    localparam Q_HALF    = 16'h2000; // 0.5 (8192 decimal)
    localparam Q_QUARTER = 16'h1000; // 0.25 (4096 decimal)
    localparam Q_NEAR_ONE = 16'h399A;    // ~0.9 in Q1.14 (14746)

    // Negative Values (Using signed arithmetic for clarity)
    localparam signed Q_NEG_HALF  = -8192;// -0.5 
    localparam signed Q_NEG_ONE   = -16384;// -1.0 
    localparam signed Q_NEG_QUARTER = -4096; // -0.25

    // Calculated Expected Values for complex tests
    localparam signed Q_EXP_IOUT_T8 = 26543; // ~1.62 in Q1.14

    // --- 1. DUT Signals (Matching Module Ports) ---
    reg signed [DATA_WIDTH-1:0] Ar_tb, Ai_tb, Br_tb, Bi_tb;
    wire signed [DATA_WIDTH-1:0] Rout_tb, Iout_tb;

    // --- 2. Instantiate the DUT (Device Under Test) ---
    z_multiplier DUT (
        .Ar(Ar_tb),
        .Ai(Ai_tb),
        .Br(Br_tb),
        .Bi(Bi_tb),
        .Rout(Rout_tb),
        .Iout(Iout_tb)
    );

    // --- 3. Test Stimulus (Applying Inputs) ---
    initial begin
        // Initialize inputs
        Ar_tb = 0; Ai_tb = 0; Br_tb = 0; Bi_tb = 0;

        $display("--- Starting z_multiplier Testbench (Q1.14 Fixed-Point) ---");
        $display("Q1.14 Scale Factor (1.0) = %d", Q_ONE);
        #10; 
        $display("------------------------------------------------------------------------------------------------");
        
        // ===================================================================
        // TEST 1: Simple Multiplication (1.0 + j0) * (1.0 + j0) = 1.0 + j0
        // Expected Rout: Q_ONE (16384). Expected Iout: 0.
        // ===================================================================
        $display("\n--- TEST 1: 1.0 * 1.0 = 1.0 ---");
        Ar_tb = Q_ONE; // 1.0
        Ai_tb = 0; // 0.0
        Br_tb = Q_ONE; // 1.0
        Bi_tb = 0; // 0.0
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected R_out = %d", Rout_tb, Iout_tb, Q_ONE);
        if (Rout_tb == Q_ONE && Iout_tb == 0) $display("PASS: Simple multiplication."); else $display("FAIL: Simple multiplication.");


        // ===================================================================
        // TEST 2: Fractional Multiplication (0.5 + j0) * (0.5 + j0) = 0.25 + j0
        // Expected Rout: Q_QUARTER (4096).
        // ===================================================================
        $display("\n--- TEST 2: 0.5 * 0.5 = 0.25 (Validating Scaling) ---");
        Ar_tb = Q_HALF; // 0.5
        Ai_tb = 0; // 0.0
        Br_tb = Q_HALF; // 0.5
        Bi_tb = 0; // 0.0
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected R_out = %d", Rout_tb, Iout_tb, Q_QUARTER);
        if (Rout_tb == Q_QUARTER) $display("PASS: Scaling is correct."); else $display("FAIL: Scaling is incorrect.");


        // ===================================================================
        // TEST 3: Complex Multiplication (0.5 + j0) * (0 - j1.0) = 0 - j0.5
        // Expected Rout: 0. Expected Iout: Q_NEG_HALF (-8192)
        // ===================================================================
        $display("\n--- TEST 3: (0.5 + j0) * (0 - j1.0) = 0 - j0.5 ---");
        Ar_tb = Q_HALF; // 0.5
        Ai_tb = 0;         // 0.0
        Br_tb = 0;         // 0.0
        Bi_tb = Q_NEG_ONE; // -1.0
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected I_out = %d", Rout_tb, Iout_tb, Q_NEG_HALF);
        if (Iout_tb == Q_NEG_HALF && Rout_tb == 0) $display("PASS: Complex multiplication."); else $display("FAIL: Complex multiplication.");


        // ===================================================================
        // TEST 4: Signed Multiplication (-1.0 + j0) * (0.5 + j0) = -0.5 + j0
        // Expected Rout: Q_NEG_HALF (-8192)
        // ===================================================================
        $display("\n--- TEST 4: (-1.0) * (0.5) = -0.5 (Signed Arithmetic) ---");
        Ar_tb = Q_NEG_ONE; // -1.0
        Ai_tb = 0;
        Br_tb = Q_HALF;    // 0.5
        Bi_tb = 0;
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected R_out = %d", Rout_tb, Iout_tb, Q_NEG_HALF);
        if (Rout_tb == Q_NEG_HALF) $display("PASS: Signed arithmetic."); else $display("FAIL: Signed arithmetic.");


        // ===================================================================
        // TEST 5: Maximum Negative Real Result (-1.0 + j0) * (1.0 + j0) = -1.0 + j0
        // Checks signed multiplication and scaling for the largest negative output.
        // Expected Rout: Q_NEG_ONE (-16384).
        // ===================================================================
        $display("\n--- TEST 5: (-1.0) * (1.0) = -1.0 (Max Negative Output) ---");
        Ar_tb = Q_NEG_ONE; // -1.0
        Ai_tb = 0;
        Br_tb = Q_ONE;     // 1.0
        Bi_tb = 0;
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected R_out = %d", Rout_tb, Iout_tb, Q_NEG_ONE);
        if (Rout_tb == Q_NEG_ONE && Iout_tb == 0) $display("PASS: Max negative result."); else $display("FAIL: Max negative result.");


        // ===================================================================
        // TEST 6: Imaginary Subtraction Corner Case (1.0 + j1.0) * (0.5 + j0.5) = 0 + j1.0
        // Rout = (0.5 - 0.5) = 0. Iout = (0.5 + 0.5) = 1.0
        // Checks that R_out two's complement subtraction handles zero correctly.
        // Expected Rout: 0. Expected Iout: Q_ONE (16384).
        // ===================================================================
        $display("\n--- TEST 6: (1.0 + j1.0) * (0.5 + j0.5) = 0 + j1.0 (Rout=0 check) ---");
        Ar_tb = Q_ONE; // 1.0
        Ai_tb = Q_ONE; // 1.0
        Br_tb = Q_HALF; // 0.5
        Bi_tb = Q_HALF; // 0.5
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected R_out=0, I_out=%d", Rout_tb, Iout_tb, Q_ONE);
        if (Rout_tb == 0 && Iout_tb == Q_ONE) $display("PASS: Zero real result after subtraction."); else $display("FAIL: Zero real result after subtraction.");


        // ===================================================================
        // TEST 7: Complex Conjugate (0.5 + j0.5) * (0.5 - j0.5) = 0.5 + j0
        // Rout = 0.25 - (-0.25) = 0.5. Iout = -0.25 + 0.25 = 0
        // Checks if subtraction of a negative product works.
        // Expected Rout: Q_HALF (8192). Expected Iout: 0.
        // ===================================================================
        $display("\n--- TEST 7: Conjugate (0.5+j0.5)*(0.5-j0.5) = 0.5 + j0 ---");
        Ar_tb = Q_HALF;  // 0.5
        Ai_tb = Q_HALF;  // 0.5
        Br_tb = Q_HALF;  // 0.5
        Bi_tb = Q_NEG_HALF; // -0.5
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected R_out = %d", Rout_tb, Iout_tb, Q_HALF);
        if (Rout_tb == Q_HALF && Iout_tb == 0) $display("PASS: Conjugate multiplication."); else $display("FAIL: Conjugate multiplication.");


        // ===================================================================
        // TEST 8: Near Max Value Check (0.9 + j0.9) * (0.9 + j0.9) = 0 + j1.62
        // Checks that the Iout adder correctly handles large positive values, 
        // relying on the 32-bit internal width before scaling.
        // Expected Rout: 0. Expected Iout: ~1.62 (26542).
        // ===================================================================
        $display("\n--- TEST 8: Near Max Value (0.9 + j0.9)^2 = 0 + j1.62 ---");
        Ar_tb = Q_NEAR_ONE; // ~0.9
        Ai_tb = Q_NEAR_ONE; // ~0.9
        Br_tb = Q_NEAR_ONE; // ~0.9
        Bi_tb = Q_NEAR_ONE; // ~0.9
        #10;
        $display("Result (Q1.14): R_out = %d, I_out = %d. Expected I_out = %d", Rout_tb, Iout_tb, Q_EXP_IOUT_T8);
        if (Rout_tb == 0 && Iout_tb == Q_EXP_IOUT_T8) $display("PASS: Near max value calculation."); 
        else $display("FAIL: Near max value or scaling is incorrect. (Expected Iout %d)", Q_EXP_IOUT_T8);
        $display("------------------------------------------------------------------------------------------------");


        $display("--- Testbench Execution Complete ---");
        $finish;
    end
endmodule