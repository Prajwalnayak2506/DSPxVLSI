`timescale 1ns / 1ps

module cordic_tb; 

    // --- 1. Constants and Parameters ---
    parameter CLK_PERIOD = 10;
    parameter Q_SCALE = 4096; 
    parameter MAX_ERROR_LSB = 6; 
    parameter TEST_THETA = 16'h0861; // 30 degrees (pi/6 scaled by pi=8000h)
    parameter REF_SIN = 16'h0800; // sin(30) * 4096 = 2048
    parameter REF_COS = 16'h0DDB; // cos(30) * 4096 = 3547
    
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
    reg [15:0] sin_err_mag;
    reg [15:0] cos_err_mag;
    integer errors;
    
    // --- 4. Instantiate the Device Under Test (DUT) ---
    cordic_algorithm DUT (
        .clk(clk),
        .reset_n(reset_n),
        .theta(theta),
        .i_valid(i_valid),
        .sine(sine_out),
        .cosine(cosine_out)
    );

    // --- 5. Clock Generation & Waveform Setup ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $dumpfile("cordic_debug_essential.vcd");
        $dumpvars(0, DUT); 
    end

    // --- 6. Debugging Test Sequence ---
    initial begin
        errors = 0;
        expected_sin = REF_SIN;
        expected_cos = REF_COS;

        $display("------------------------------------------------------------------------------------------------------");
        $display("--- CORE CORDIC TRACE (Angle: 30 deg, FP: 0861) ---");
        $display("------------------------------------------------------------------------------------------------------");
        $display("Cyc| i | X_reg | Y_reg | Z_reg | Sigma | Alpha | shifted_x | shifted_y | Xb | Yb");
        $display("------------------------------------------------------------------------------------------------------");

        // Initialization
        reset_n = 0; i_valid = 0; theta = 16'h0000;
        #10;
        
        // Apply inputs and start CORDIC
        reset_n = 1; theta = TEST_THETA; i_valid = 1;
        
        // Wait 2 clock cycles to load registers (Cycles 1, 2)
        @(posedge clk); 
        @(posedge clk); 
        // i_valid remains high during calculation as requested.

        // Run and Display 20 Iterations (Cycles 3 through 22)
        repeat (20) begin
            $display("%3d| %1h | %5h | %5h | %5h | %3b | %5h | %7h | %7h |%7h|%7h", 
                     $time/CLK_PERIOD, DUT.i, DUT.x_reg, DUT.y_reg, DUT.z_reg,
                     DUT.sigma, DUT.alpha_not, DUT.shifted_x,DUT.shifted_y,DUT.xb, DUT.yb);
            
            @(posedge clk); // Registers update on this edge
        end
        
        // De-assert i_valid before final check
        i_valid = 0;

        // --- Final Verification Check ---
        sin_err_mag = (sine_out > expected_sin) ? (sine_out - expected_sin) : (expected_sin - sine_out);
        cos_err_mag = (cosine_out > expected_cos) ? (cosine_out - expected_cos) : (expected_cos - cosine_out);
        
        $display("\n-------------------------------------------------------");
        $display("Final CORDIC Output (FP): SIN=%h, COS=%h", sine_out, cosine_out);
        $display("Expected Output (FP): SIN=%h, COS=%h", expected_sin, expected_cos);

        if (sin_err_mag <= MAX_ERROR_LSB && cos_err_mag <= MAX_ERROR_LSB) begin
            $display("** PASS: Error <= %0d LSBs. **", MAX_ERROR_LSB);
        end else begin
            $display("!! FAIL: Max Error: SIN=%0d, COS=%0d LSBs. !!", sin_err_mag, cos_err_mag);
            errors = errors + 1;
        end
        $display("-------------------------------------------------------");
        
        $finish;
    end
    
endmodule
