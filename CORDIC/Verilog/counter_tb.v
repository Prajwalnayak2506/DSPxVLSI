// ==============================================================================
// Testbench for cordic_counter module
// Verifies sequential counting from 0 to 15 and the stop condition.
// ==============================================================================

`timescale 1ns / 1ps

module counter_tb;

    // --- Signals for DUT (Device Under Test) ---
    reg clk;
    reg rst_n;
    reg start;
    wire [3:0] iteration_count;
    wire done;

    // --- Clock Generation ---
    parameter CLK_PERIOD = 10; // 10ns period (100 MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --- Instantiate the DUT (Assuming module name is 'cordic_counter' from previous step) ---
    cordic_counter DUT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .iteration_count(iteration_count),
        .done(done)
    );

    // --- Test Sequence Stimulus ---
    initial begin
        $dumpfile("counter.vcd");
        $dumpvars(0, counter_tb);
        
        // 1. Initial State and Reset
        rst_n = 0;   // Assert Reset
        start = 0;   // Hold Start low
        #5;
        rst_n = 1;   // De-assert Reset (Module is now IDLE)
        $display("Time=%0t: System out of reset. Waiting for start signal.", $time);
        
        // 2. Wait in IDLE state
        #(CLK_PERIOD * 2);

        // 3. Start the Count (Pulse 'start' for one clock cycle)
        $display("Time=%0t: Pulsing START to initiate counting.", $time);
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // 4. Run the 16 Iterations (0 to 15)
        // CORDIC takes 16 cycles to run, plus 1 cycle for post-processing/done flag
        // We will wait 20 cycles to confirm it stops correctly.
        $display("Time=%0t: Count started. Expected 16 cycles (0-15).", $time);
        
        #(CLK_PERIOD * 20); 
        
        // 5. Verification Checks
        if (iteration_count == 4'd15) begin
            $display("Time=%0t: SUCCESS! Counter stopped at 15.", $time);
        end else begin
            $display("Time=%0t: ERROR! Counter is at %d, expected 15.", $time, iteration_count);
        end

        if (done == 1'b0) begin
            $display("Time=%0t: SUCCESS! Done signal is correctly low after count completion.", $time);
        end else begin
            $display("Time=%0t: ERROR! Done signal is still high.", $time);
        end

        // 6. Test a second run
        $display("\nTime=%0t: Starting second run.", $time);
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        #(CLK_PERIOD * 20);
        
        $display("Time=%0t: Simulation finished.", $time);
        $finish;
    end

endmodule
