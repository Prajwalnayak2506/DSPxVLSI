`timescale 1ns / 1ps

module ksa_32bit_tb_improved;

    // Parameters for easy adjustment
    localparam DATA_WIDTH = 32;
    localparam TEST_PASS = "PASS";
    localparam TEST_FAIL = "FAIL";

    // --- 1. DUT Signals ---
    reg [DATA_WIDTH-1:0] A_tb, B_tb;
    reg CIN_tb;
    wire [DATA_WIDTH-1:0] Y_tb;
    wire COUT_tb;

    // --- 2. Instantiate the KSA DUT ---
    kogge_stone_32bit DUT (
        .A(A_tb), 
        .B(B_tb), 
        .CIN(CIN_tb), 
        .Y(Y_tb), 
        .COUT(COUT_tb)
    );

    // --- 3. Helper Function and Task ---
    // Function to calculate the expected (32+1)-bit result for comparison
    function [DATA_WIDTH:0] expected_sum;
        input [DATA_WIDTH-1:0] op1;
        input [DATA_WIDTH-1:0] op2;
        input carry_in;
        expected_sum = op1 + op2 + carry_in;
    endfunction

    // Task to run and check a single test case
    task run_test;
        input [DATA_WIDTH-1:0] A_val;
        input [DATA_WIDTH-1:0] B_val;
        input CIN_val;
        input [31:0] Description; // Test Tag
        
        reg [DATA_WIDTH:0] Expected_Full;
        reg [DATA_WIDTH-1:0] Expected_Y;
        reg Expected_COUT;
        reg [3:0] test_delay; // Use a small delay for combinational logic

        begin
            test_delay = 10;
            A_tb = A_val;
            B_tb = B_val;
            CIN_tb = CIN_val;
            #(test_delay);
            
            // Calculate the expected full sum
            Expected_Full = expected_sum(A_val, B_val, CIN_val);
            Expected_Y = Expected_Full[DATA_WIDTH-1:0];
            Expected_COUT = Expected_Full[DATA_WIDTH];

            $display("--- Test: %s (C_in=%b) ---", Description, CIN_val);
            $display("Input: A=%h, B=%h", A_val, B_val);
            $display("Expected: Y=%h, COUT=%b", Expected_Y, Expected_COUT);
            $display("Actual: Y=%h, COUT=%b", Y_tb, COUT_tb);

            if (Y_tb === Expected_Y && COUT_tb === Expected_COUT) begin
                $display("  Result: %s", TEST_PASS);
            end else begin
                $display("  Result: %s !!! Expected Y/COUT mismatch. Check KSA logic.", TEST_FAIL);
                // $finish; // Optional: Stop on first failure
            end
            $display("--------------------------------------------------------------------------------");
        end
    endtask


    // --- 4. Test Stimulus (Enhanced Cases) ---
    initial begin
        // Initialize for stability
        A_tb = 0; B_tb = 0; CIN_tb = 0;
        #20;
        $display("--- Starting Kogge-Stone 32-bit Adder Testbench (Enhanced) ---");
        $display("--------------------------------------------------------------------------------");

        // 1. BOUNDARY CASES (Zeros, Ones, Max Positive)
        // ----------------------------------------------------------------
        run_test('h0000_0000, 'h0000_0000, 1'b0, "Zero_Zero"); // 0 + 0 + 0 = 0, C_out=0
        run_test('hFFFF_FFFF, 'h0000_0000, 1'b0, "Max_A_Zero"); // Max + 0 + 0 = Max, C_out=0
        run_test('hFFFF_FFFF, 'h0000_0000, 1'b1, "Max_A_CIN");  // Max + 0 + 1 = 0, C_out=1
        run_test('h7FFF_FFFF, 'h0000_0001, 1'b0, "Max_Pos_Plus_1"); // Max Positive + 1 = MSB set, C_out=0 (Signed overflow)

        // 2. FULL CARRY PROPAGATION TESTS (Testing all 5 KSA layers)
        // ----------------------------------------------------------------
        // Full Carry: (2^32 - 1) + (2^32 - 1) + 1 = (2^33 - 1)
        run_test('hFFFF_FFFF, 'hFFFF_FFFF, 1'b1, "Full_Carry_All_Ones"); // FFFF_FFFF + FFFF_FFFF + 1 = 1_FFFF_FFFF, Y=FFFF_FFFF, COUT=1
        
        // Single Carry Propagating through all 32 bits (1 + FFFFFFFF + 0)
        run_test('h0000_0001, 'hFFFF_FFFF, 1'b0, "Single_Carry_Prop_1"); // 1 + FFFFFFFF + 0 = 1_00000000, Y=00000000, COUT=1

        // Single Carry Propagating through all 32 bits (0 + FFFFFFFF + 1)
        run_test('h0000_0000, 'hFFFF_FFFF, 1'b1, "Single_Carry_Prop_2"); // 0 + FFFFFFFF + 1 = 1_00000000, Y=00000000, COUT=1

        // 3. MID-RANGE CHECKERS (Hitting intermediate layers)
        // ----------------------------------------------------------------
        // Carry should stop at bit 16, testing layer 5 boundary
        run_test('h0000_FFFF, 'h0000_0001, 1'b0, "Mid_Range_Low"); // FFFF + 1 = 1_0000, C_out=0

        // Carry should propagate past layer 4 (bit 7) but not reach layer 5 (bit 15)
        run_test('h0001_FFFF, 'h0001_0001, 1'b0, "Mid_Range_High"); // 1FFFF + 10001 = 3_0000, C_out=0

        // Propagate across MSB (bit 31) from bit 30
        run_test('h4000_0000, 'h4000_0000, 1'b0, "MSB_No_CIN"); // 4... + 4... = 8..., C_out=0

        // 4. TWOS COMPLEMENT / SIGNED CHECKS (MSB tests)
        // ----------------------------------------------------------------
        // Subtraction: 5 - 3 = 2 (Signed: 5 + (-3) + 0)
        run_test('h0000_0005, 'hFFFF_FFFD, 1'b0, "Signed_Sub_Pos"); // 5 + FFFD + 0 = 1_0002, Y=00000002, COUT=1
        
        // Subtraction: -5 - 3 = -8 (Signed: FFFB + FFFD + 0)
        run_test('hFFFF_FFFB, 'hFFFF_FFFD, 1'b0, "Signed_Sub_Neg"); // FFFB + FFFD + 0 = 1_FFF8, Y=FFFFFFF8, COUT=1

        // Zero Result: 1 + (-1) + 0
        run_test('h0000_0001, 'hFFFF_FFFF, 1'b0, "Zero_Result"); // 1 + FFFF_FFFF + 0 = 1_00000000, Y=00000000, COUT=1
        run_test('h0CF9_8D40, 'h0CF9_8D40, 1'b0, "Z_MULT_DIAG");
        $display("--- Testbench Execution Complete ---");
        $finish;
    end
endmodule