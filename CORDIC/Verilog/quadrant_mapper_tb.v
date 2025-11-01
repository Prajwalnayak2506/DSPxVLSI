`timescale 1ns / 1ps

module quadrant_mapper_tb;

    // --- Fixed-Point Q4.12 Test Constants ---
    localparam FIXED_0_DEG_RAD  = 16'd0;      // 0 degrees
    localparam FIXED_45_DEG_RAD = 16'd3217;   // 45 degrees
    localparam FIXED_90_DEG_RAD = 16'd6434;   // 90 degrees (PI_HALF)
    localparam PI_CONST         = 16'd12868;  // 180 degrees (PI)
    localparam FIXED_270_DEG_RAD= 16'd19302;  // 270 degrees (3PI/2)
    localparam FIXED_360_DEG_RAD= 16'd25736;  // 360 degrees (2PI)
    
    // Two's complement expected negative values
    localparam NEG_45_DEG_FP    = 16'hF37F;   // -3217 in Q4.12
    localparam NEG_90_DEG_FP    = 16'hE6DE;   // -6434 in Q4.12 (for 270 deg test)

    // --- DUT Signals ---
    reg [15:0] angle_in;
    wire [15:0] Z_init;
    wire [15:0] X_init;
    wire [15:0] Y_init;
    wire flip_X_out;
    wire flip_Y_out;
    
    // --- Instantiate DUT (Device Under Test) ---
    quadrant_mapper DUT (
        .angle_in(angle_in),
        .Z_init(Z_init),
        .X_init(X_init),
        .Y_init(Y_init),
        .flip_X_out(flip_X_out),
        .flip_Y_out(flip_Y_out)
    );

    // --- Utility Task for Display and Verification ---
    task check_result;
        input [15:0] expected_Z;
        input flip_X_exp;
        input flip_Y_exp;
        begin
            $display("Z_init: %d (0x%H) | FlipX: %b | FlipY: %b", Z_init, Z_init, flip_X_out, flip_Y_out);
            $display("Expected Z: %d (0x%H) | Expected Flips: %b%b", expected_Z, expected_Z, flip_X_exp, flip_Y_exp);
            if (Z_init !== expected_Z || flip_X_out !== flip_X_exp || flip_Y_out !== flip_Y_exp) begin
                $display("!!! TEST FAILED !!!");
            end else begin
                $display("--- TEST PASSED ---");
            end
        end
    endtask

    // --- Test Sequence ---
    initial begin
        $display("--- Starting Quadrant Mapper Test (Q4.12) ---");
        $display("Expected 1/K: %d (0x%H) | Expected Y_init: 0", X_init, X_init);
        
        // 1. Test Q1: 0 degrees (Boundary)
        angle_in = FIXED_0_DEG_RAD;
        #10; $display("\n--- Test 1 (Q1: 0 deg) ---");
        check_result(FIXED_0_DEG_RAD, 1'b0, 1'b0);

        // 2. Test Q1: 45 degrees (Typical)
        angle_in = FIXED_45_DEG_RAD;
        #10; $display("\n--- Test 2 (Q1: 45 deg) ---");
        check_result(FIXED_45_DEG_RAD, 1'b0, 1'b0);

        // 3. Test Q1: 89.99 degrees (Near Boundary)
        angle_in = FIXED_90_DEG_RAD - 1; // 6433
        #10; $display("\n--- Test 3 (Q1: ~90 deg) ---");
        check_result(FIXED_90_DEG_RAD - 1, 1'b0, 1'b0);

        // 4. Test Q2: 90 degrees (Boundary)
        angle_in = FIXED_90_DEG_RAD;
        #10; $display("\n--- Test 4 (Q2: 90 deg) ---");
        // Z_init = PI - 90 deg = 90 deg
        check_result(FIXED_90_DEG_RAD, 1'b1, 1'b0); 

        // 5. Test Q2: 135 degrees (Typical)
        angle_in = PI_CONST - FIXED_45_DEG_RAD; // 9651
        #10; $display("\n--- Test 5 (Q2: 135 deg) ---");
        // Z_init = 180 - 135 = 45 deg
        check_result(FIXED_45_DEG_RAD, 1'b1, 1'b0);

        // 6. Test Q2: 179.99 degrees (Near Boundary)
        angle_in = PI_CONST - 1; // 12867
        #10; $display("\n--- Test 6 (Q2: ~180 deg) ---");
        // Z_init = PI - (PI - 1) = 1 (small positive angle)
        check_result(16'd1, 1'b1, 1'b0); 
        
        // 7. Test Q3: 180 degrees (Boundary)
        angle_in = PI_CONST;
        #10; $display("\n--- Test 7 (Q3: 180 deg) ---");
        // Z_init = 180 - 180 = 0
        check_result(FIXED_0_DEG_RAD, 1'b1, 1'b1);

        // 8. Test Q3: 225 degrees (Typical)
        angle_in = PI_CONST + FIXED_45_DEG_RAD; // 16085
        #10; $display("\n--- Test 8 (Q3: 225 deg) ---");
        // Z_init = 225 - 180 = 45 deg
        check_result(FIXED_45_DEG_RAD, 1'b1, 1'b1);

        // 9. Test Q4: 270 degrees (Boundary)
        angle_in = FIXED_270_DEG_RAD;
        #10; $display("\n--- Test 9 (Q4: 270 deg) ---");
        // Z_init = 270 - 360 = -90 deg
        check_result(NEG_90_DEG_FP, 1'b0, 1'b1); 

        // 10. Test Q4: 315 degrees (Typical)
        angle_in = FIXED_360_DEG_RAD - FIXED_45_DEG_RAD; // 22519
        #10; $display("\n--- Test 10 (Q4: 315 deg) ---");
        // Z_init = 315 - 360 = -45 deg
        check_result(NEG_45_DEG_FP, 1'b0, 1'b1);

        $display("\n--- All Quadrant Mapper Tests finished. ---");
        $finish;
    end

endmodule
