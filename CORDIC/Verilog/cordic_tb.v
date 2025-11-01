`timescale 1ns / 1ps

module cordic_tb;

    // --- 1. Constants and Parameters ---
    parameter CLK_PERIOD = 10;
    parameter Q_SCALE = 16384; 
    parameter MAX_ERROR_LSB = 2; // Tolerance for verification

    // --- 2. Testbench Signals (Inputs/Outputs) ---
    reg clk;
    reg reset_n;
    reg [15:0] theta;
    reg i_valid;
    wire [15:0] sine_out;
    wire [15:0] cosine_out;

    // --- 3. Verification Variables ---
    reg [15:0] expected_sin;
    reg [15:0] expected_cos;
    integer errors;
    integer test_count;

    // --- 4. Instantiate the Device Under Test (DUT) ---
    cordic_algorithm DUT (
        .clk(clk),
        .reset_n(reset_n),
        .theta(theta),
        .i_valid(i_valid),
        .sine(sine_out),
        .cosine(cosine_out)
    );

    // --- 5. Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 6. Waveform Dumping Setup ---
    initial begin
        $dumpfile("cordic_waveform.vcd");
        $dumpvars(0, cordic_tb); // Dump all variables in the testbench
    end

    // --- 7. Test Sequence (Using Corrected Fixed-Point Vectors) ---
    initial begin
        // Initialize
        errors = 0;
        test_count = 0;
        reset_n = 0;
        i_valid = 0;
        theta = 16'h0000;
        
        $display("-------------------------------------------------------");
        $display("Starting CORDIC Testbench (Verilog-2001)");
        $display("-------------------------------------------------------");

        // Apply Reset
        #10;
        reset_n = 1;
        
        // ** Corrected Test Cases (Q1.14 Fixed-Point Values) **
        // 1. 30 degrees: THETA(1555), SIN(2000), COS(376B)
        run_test(16'h1555, 16'h2000, 16'h376B); 

        // 2. 90 degrees: THETA(4000), SIN(3FFF), COS(0000)
        run_test(16'h4000, 16'h3FFF, 16'h0000); 

        // 3. 135 degrees: THETA(6000), SIN(2D80), COS(D280)
        run_test(16'h6000, 16'h2D80, 16'hD280); 

        // 4. 270 degrees: THETA(C000), SIN(C000), COS(0000)
        run_test(16'hC000, 16'hC000, 16'h0000); 

        // 5. 5 degrees: THETA(02AC), SIN(0598), COS(3FBF)
        run_test(16'h02AC, 16'h0598, 16'h3FBF); 

        // 6. -45 degrees: THETA(E000), SIN(D280), COS(2D80)
        run_test(16'hE000, 16'hD280, 16'h2D80); 

        // --- Summary ---
        $display("\n-------------------------------------------------------");
        $display("Test Summary: %0d Tests Run, %0d Errors Found", test_count, errors);
        $display("-------------------------------------------------------");
        
        if (errors == 0) begin
            $display("** PASS: All CORDIC values tested successfully. **");
            $finish;
        end else begin
            $display("** FAIL: Found errors in CORDIC calculation. **");
            $finish;
        end
    end

    // --- 8. Task to Run Individual Test Cases ---
    task run_test;
        // Declare inputs inside the task body (Verilog-2001 syntax)
        input [15:0] input_theta;
        input [15:0] ref_sin;
        input [15:0] ref_cos;
        
        reg [15:0] sin_err_mag;
        reg [15:0] cos_err_mag;
        
        begin
            test_count = test_count + 1;
            
            // Wait for system to settle
            @(posedge clk);
            
            // 1. Apply inputs and start CORDIC
            theta = input_theta;
            expected_sin = ref_sin;
            expected_cos = ref_cos;
            i_valid = 1;
            
            $display("\n[T%0d] Input Angle (FP): %h", test_count, input_theta);
            $display("      REF SIN/COS (FP): %h / %h", expected_sin, expected_cos);
            
            // Wait for 1 clock cycle to let the FSM load initial values
            @(posedge clk);
            i_valid = 0; 

            // 2. Wait for CORDIC calculation to complete (16 iterations + overhead)
            repeat (20) @(posedge clk); 
            
            // 3. Verification Check
            
            // Calculate absolute error magnitude 
            sin_err_mag = (sine_out > expected_sin) ? (sine_out - expected_sin) : (expected_sin - sine_out);
            cos_err_mag = (cosine_out > expected_cos) ? (cosine_out - expected_cos) : (expected_cos - cosine_out);
            
            if (sin_err_mag <= MAX_ERROR_LSB && cos_err_mag <= MAX_ERROR_LSB) begin
                $display("      PASS: SIN/COS = %h / %h. Error <= %0d LSBs.", 
                    sine_out, cosine_out, MAX_ERROR_LSB);
            end else begin
                $display("      FAIL: SIN/COS = %h / %h. Max Error: SIN=%0d, COS=%0d LSBs.", 
                    sine_out, cosine_out, sin_err_mag, cos_err_mag);
                errors = errors + 1;
            end
        end
    endtask
    
endmodule