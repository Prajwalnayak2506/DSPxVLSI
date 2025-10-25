`timescale 1ns / 1ps

module bfu_adder_tb;

    // --- 1. DUT Signals (Q1.14 Format) ---
    // XA (Input 1)
    reg signed  [15:0] Xar_tb, Xai_tb; 
    // P (Input 2: The product from the z_multiplier)
    reg signed  [15:0] Pr_tb, Pi_tb;    
    // Y (Outputs)
    wire signed [15:0] Yar_tb, Yai_tb;
    wire signed [15:0] Ybr_tb, Ybi_tb;


    // --- Fixed-Point Parameters (Q1.14) ---
    localparam Q_ONE = 16'h4000;       // 1.0 (16384 decimal)
    localparam Q_HALF = 16'h2000;      // 0.5 (8192 decimal)
    localparam Q_ZERO = 16'h0000;      // 0.0
    
    // Negative Values
    localparam Q_NEG_HALF = -8192;     // -0.5
    localparam Q_NEG_ONE = -16384;     // -1.0


    // --- 2. Instantiate the BFU Adder DUT ---
    // NOTE: Replace 'bfu' with your actual module name if different
    bfu DUT (
        .Xar(Xar_tb), .Xai(Xai_tb), 
        .Xbr(Pr_tb),  .Xbi(Pi_tb),  // Xbr/Xbi are P according to your intent
        .Yar(Yar_tb), .Yai(Yai_tb),
        .Ybr(Ybr_tb), .Ybi(Ybi_tb)
    );


    // --- 3. Test Stimulus ---
    initial begin
        // Initialize inputs
        Xar_tb = 0; Xai_tb = 0; Pr_tb = 0; Pi_tb = 0;

        $display("--- Starting BFU Adder Testbench (Q1.14) ---");
        #10; 

        // -------------------------------------------------------------------
        // TEST 1: Complex Addition (1.0 + j0) + (0.5 + j0) = 1.5 + j0
        // Expected YA: 1.0 + 0.5 = 1.5 (24576). Expected YB: 1.0 - 0.5 = 0.5 (8192)
        // -------------------------------------------------------------------
        $display("\n--- TEST 1: (1.0+j0) + (0.5+j0) = 1.5; (1.0+j0) - (0.5+j0) = 0.5 ---");
        Xar_tb = Q_ONE;  // XA_r = 1.0
        Xai_tb = Q_ZERO; // XA_i = 0.0
        Pr_tb = Q_HALF;  // P_r = 0.5
        Pi_tb = Q_ZERO;  // P_i = 0.0
        #10;
        
        $display("YA_r: Actual=%d, Expected=%d", Yar_tb, Q_ONE + Q_HALF);
        $display("YB_r: Actual=%d, Expected=%d", Ybr_tb, Q_HALF);

        if (Yar_tb == (Q_ONE + Q_HALF) && Ybr_tb == Q_HALF)
            $display("PASS: Real parts addition/subtraction correct.");
        else
            $display("FAIL: Real parts arithmetic error.");


        // -------------------------------------------------------------------
        // TEST 2: Complex Subtraction (0.5 + j0) - (-0.5 + j1.0)
        // YA_r: 0.5 + (-0.5) = 0.0
        // YB_i: 0.0 - 1.0 = -1.0 (Q_NEG_ONE)
        // -------------------------------------------------------------------
        $display("\n--- TEST 2: (0.5 + j0) + (-0.5 + j1.0) = 0 + j1.0 ---");
        $display("          (0.5 + j0) - (-0.5 + j1.0) = 1.0 - j1.0 ---");
        Xar_tb = Q_HALF;  // XA_r = 0.5
        Xai_tb = Q_ZERO;  // XA_i = 0.0
        Pr_tb = Q_NEG_HALF; // P_r = -0.5
        Pi_tb = Q_ONE;    // P_i = 1.0
        #10;
        
        $display("YA_r: Actual=%d, Expected=%d", Yar_tb, Q_ZERO);
        $display("YB_i: Actual=%d, Expected=%d", Ybi_tb, Q_NEG_ONE);

        if (Yar_tb == Q_ZERO && Ybi_tb == Q_NEG_ONE)
            $display("PASS: Complex interaction correct.");
        else
            $display("FAIL: Complex interaction error. Check ~ operator use.");


        // -------------------------------------------------------------------
        // TEST 3: Max Negative Subtraction (0.5 + j0) - (1.0 + j0)
        // YA_r: 0.5 + 1.0 = 1.5
        // YB_r: 0.5 - 1.0 = -0.5 (Q_NEG_HALF)
        // -------------------------------------------------------------------
        $display("\n--- TEST 3: Signed Subtraction (0.5 - 1.0) = -0.5 ---");
        Xar_tb = Q_HALF; // XA_r = 0.5
        Xai_tb = Q_ZERO;
        Pr_tb = Q_ONE;   // P_r = 1.0
        Pi_tb = Q_ZERO;
        #10;
        
        $display("YA_r: Actual=%d, Expected=%d", Yar_tb, Q_ONE + Q_HALF);
        $display("YB_r: Actual=%d, Expected=%d", Ybr_tb, Q_NEG_HALF);

        if (Ybr_tb == Q_NEG_HALF)
            $display("PASS: Subtraction with negative result verified.");
        else
            $display("FAIL: Subtraction result error. Check adder CIN logic.");


        $finish;
    end
endmodule