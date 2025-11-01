`timescale 1ns / 1ps

module cordic_tb; // Renamed module to cordic_tb for standard practice

    // --- 1. Constants and Parameters ---
    parameter CLK_PERIOD = 10;
    
    // Test Case 1: 30 degrees (pi/6)
    parameter TEST_THETA = 16'h1555;
    
    // --- 2. Testbench Signals (Inputs/Outputs) ---
    reg clk;
    reg reset_n;
    reg [15:0] theta;
    reg i_valid;
    wire [15:0] sine_out;
    wire [15:0] cosine_out;

    // --- 3. Verification & Debugging Variables ---
    integer errors;
    
    // NOTE: These wires are now linked hierarchically, NOT through ports.
    wire [1:0] current_state_h = DUT.current_state; // FSM State (from DUT instance)
    wire [3:0] i_h = DUT.i;                         // Iteration Count (from DUT instance)
    wire signed [15:0] x_reg_h = DUT.x_reg;         // X Register (from DUT instance)
    wire signed [15:0] y_reg_h = DUT.y_reg;         // Y Register (from DUT instance)
    wire signed [15:0] z_reg_h = DUT.z_reg;         // Z Register (from DUT instance)

    // --- 4. Instantiate the Device Under Test (DUT) ---
    // The port list here is ONLY the original, un-modified one.
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
        $dumpfile("cordic_debug_flow.vcd");
        // Dump the entire DUT hierarchy
        $dumpvars(0, DUT); 
    end

    // --- 6. Debugging Test Sequence ---
    initial begin
        $display("-------------------------------------------------------");
        $display("--- CORDIC DEBUG TRACE: 30 Degrees (16'h1555) ---");
        $display("-------------------------------------------------------");
        $display("Cycle | State | i | X_reg | Y_reg | Z_reg (Angle)");
        $display("-------------------------------------------------------");

        // Initialization
        reset_n = 0;
        i_valid = 0;
        theta = 16'h0000;
        
        #10;
        
        // Release Reset and Load Input
        reset_n = 1;
        theta = TEST_THETA;
        i_valid = 1;
        
        // Wait 1 clock cycle for FSM transition and initial load
        @(posedge clk);
        i_valid = 1;
        
        // Run and Display First 5 Iterations
        // The display statement uses the hierarchically linked signals (_h suffix)
        repeat (25) begin
            $display("%5d | %5b | %1h | %4h | %4h | %4h", 
                     $time/CLK_PERIOD, current_state_h, i_h, x_reg_h, y_reg_h, z_reg_h);
            @(posedge clk);
        end
        
        $finish;
    end
    
endmodule