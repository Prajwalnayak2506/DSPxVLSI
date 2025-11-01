`timescale 1ns / 1ps

module cordic_tb;

    // --- 1. Constants and Parameters ---
    parameter CLK_PERIOD = 10;
    // Q_SCALE is 2^12 = 4096 for Q3.12
    parameter Q_SCALE = 4096; 
    // Set error tolerance appropriately for the working Q3.12 system
    parameter MAX_ERROR_LSB = 6; 

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

    // --- 5. Clock Generation & Waveform Dumping ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("cordic_waveform.vcd");
        $dumpvars(0, cordic_tb);
    end

    // --- 7. Test Sequence (First Quadrant Only) ---
    initial begin
        // Initialize
        errors = 0;
        test_count = 0;
        reset_n = 0;
        i_valid = 0;
        theta = 16'h0000;
        
        $display("-------------------------------------------------------");
        $display("Starting CORDIC Testbench (First Quadrant Only)");
        $display("-------------------------------------------------------");

        // Apply Reset
        #10;
        reset_n = 1;
        
        // ** TEST CASES (Q1: 0 to pi/2, or 0000 to 4000) **
        
        // 1. 0 degrees (Boundary): THETA(0000), SIN(0000), COS(1000)
        run_test(16'h0000, 16'h0000, 16'h1000); 

        // 2. 5 degrees: THETA(0161), SIN(0161), COS(0FFF)
        run_test(16'h0161, 16'h0161, 16'h0FFF); 

        // 3. 30 degrees: THETA(0861), SIN(0800), COS(0DDB)
        run_test(16'h0861, 16'h0800, 16'h0DDB); 

        // 4. 45 degrees: THETA(2000), SIN(0B5F), COS(0B5F)
        // 45 deg = pi/4. sin(45) = cos(45) approx 0.707 * 4096 = 2896 (0B5F)
        run_test(16'h2000, 16'h0B5F, 16'h0B5F); 

        // 5. 60 degrees: THETA(2F9F), SIN(0DDB), COS(0800)
        // 60 deg = pi/3. sin(60) approx 0.866 * 4096 = 3547 (0DDB)
        run_test(16'h2F9F, 16'h0DDB, 16'h0800); 

        // 6. 90 degrees (Boundary): THETA(4000), SIN(1000), COS(0000)
        run_test(16'h4000, 16'h1000, 16'h0000); 

        // --- Summary ---
        $display("\n-------------------------------------------------------");
        $display("Test Summary: %0d Tests Run, %0d Errors Found", test_count, errors);
        $display("-------------------------------------------------------");
        
        if (errors == 0) begin
            $display("** PASS: All CORDIC values tested successfully in Q1. **");
            $finish;
        end else begin
            $display("** FAIL: Found errors in core CORDIC calculation. **");
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
            
            // Explicitly de-assert i_valid before new test setup
            i_valid = 0; 
            
            // Wait for system to settle
            @(posedge clk);
            
            // 1. Apply inputs and start CORDIC
            theta = input_theta;
            expected_sin = ref_sin;
            expected_cos = ref_cos;
            i_valid = 1; // Assert i_valid to signal the input is valid
            
            $display("\n[T%0d] Input Angle (FP): %h", test_count, input_theta);
            $display(" REF SIN/COS (FP): %h / %h", expected_sin, expected_cos);
            
            // Wait for 1 clock cycle to let the FSM load initial values.
            @(posedge clk); 
            // i_valid remains high during the calculation as requested.

            // 2. Wait for CORDIC calculation to complete (16 iterations + overhead)
            // Wait 19 more cycles since we already waited 1 cycle above.
            repeat (19) @(posedge clk); 
            
            // De-assert i_valid before checking results
            i_valid = 0;
            
            // 3. Verification Check
            
            // Calculate absolute error magnitude 
            sin_err_mag = (sine_out > expected_sin) ? (sine_out - expected_sin) : (expected_sin - sine_out);
            cos_err_mag = (cosine_out > expected_cos) ? (cosine_out - expected_cos) : (expected_cos - cosine_out);
            
            // Compare error against the MAX_ERROR_LSB parameter
            if (sin_err_mag <= MAX_ERROR_LSB && cos_err_mag <= MAX_ERROR_LSB) begin
                $display(" PASS: SIN/COS = %h / %h. Error <= %0d LSBs.", 
                    sine_out, cosine_out, MAX_ERROR_LSB);
            end else begin
                $display(" FAIL: SIN/COS = %h / %h. Max Error: SIN=%0d, COS=%0d LSBs.", 
                    sine_out, cosine_out, sin_err_mag, cos_err_mag);
                errors = errors + 1;
            end
        end
    endtask
    
endmodule
