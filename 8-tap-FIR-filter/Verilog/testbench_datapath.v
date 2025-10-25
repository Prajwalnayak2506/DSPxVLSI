// ====================================================================
// FILE: tb_datapath.v
// Testbench for the fir_datapath module.
// FINAL FIX: Moves local variable declarations to module scope to resolve
// strict compiler errors on procedural assignment.
// ====================================================================

`timescale 1ns / 1ps

module tb_datapath;

    // --- Parameters ---
    localparam CLK_PERIOD = 10; // Clock period = 10ns
    integer cycle_count;
    integer i;

    // --- Testbench Signals ---
    reg clk;
    reg rst_n;
    reg i_shift_enable;
    reg i_coeff_write_en;
    reg [2:0] i_coeff_addr;
    reg signed [7:0] i_coeff_data;
    reg signed [7:0] i_data;
    wire signed [31:0] o_data;
    
    // Wire for the debug output from the datapath (if implemented)
    wire [127:0] dummy_debug_products; 

    // --- NEW: Local Test Arrays moved to module scope for strict compilers ---
    reg [7:0] input_sequence [0:7];
    reg [63:0] input_packed;


    // --- Instantiate the DATAPATH (DUT) ---
    fir_datapath dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_shift_enable(i_shift_enable),
        .i_coeff_write_en(i_coeff_write_en),
        .i_coeff_addr(i_coeff_addr),
        .i_coeff_data(i_coeff_data),
        .i_data(i_data),
        .o_data(o_data) 
        // .o_debug_products_visible(dummy_debug_products)
    );


    // --- Clock Generation ---
    always # (CLK_PERIOD / 2) clk = ~clk;


    // --- Main Test Sequence ---
    initial begin
        cycle_count = 0;
        // --- Setup Waveform Dumping ---
        $dumpfile("datapath_dump.vcd");
        // Dumps ALL signals inside the 'dut' instance
        $dumpvars(0, dut); 

        // --- 1. Initialization and Reset ---
        clk = 0;
        rst_n = 1;
        i_shift_enable = 0;
        i_coeff_write_en = 0;
        i_data = 0;
        
        #5;
        rst_n = 0; // Assert reset
        #(CLK_PERIOD * 2);
        rst_n = 1; // De-assert reset
        #(CLK_PERIOD);

        // --- 2. Load Coefficients: h = [8, 4, 2, 1, 0, 0, 0, 0] (Initial Test) ---
        $display("\n=============================================");
        $display("--- TEST 1: Initial Impulse Load (h=8,4,2,1) ---");
        $display("=============================================");

        i_coeff_write_en = 1;
        i_shift_enable = 0;

        // Load h[0] = 8 
        i_coeff_addr = 0; i_coeff_data = 8; 
        #(CLK_PERIOD);
        $display("LOAD: h[0] = %0d. Time: %0t", 8, $time);

        // Load h[1] = 4
        i_coeff_addr = 1; i_coeff_data = 4; 
        #(CLK_PERIOD);
        $display("LOAD: h[1] = %0d. Time: %0t", 4, $time);

        // Load h[2] = 2
        i_coeff_addr = 2; i_coeff_data = 2; 
        #(CLK_PERIOD);
        $display("LOAD: h[2] = %0d. Time: %0t", 2, $time);

        // Load h[3] = 1
        i_coeff_addr = 3; i_coeff_data = 1; 
        #(CLK_PERIOD);
        $display("LOAD: h[3] = %0d. Time: %0t", 1, $time);
        
        // Exit Load Mode
        i_coeff_write_en = 0; 
        i_coeff_data = 0;
        @(posedge clk); 

        // --- 3. Run Impulse Test (Input: 1, 0, 0, ...) ---
        $display("\n--- Running Impulse Test ---");
        i_shift_enable = 1; 
        cycle_count = 0;

        // Cycle 1: Input 1.
        i_data = 1;     
        @(posedge clk); 
        cycle_count = cycle_count + 1;
        $display("Cycle %0d | Input: 1 | Output: %0d", cycle_count, o_data);

        // Cycles 2-5: Input 0. 
        for (i = 2; i <= 5; i = i + 1) begin
            i_data = 0;     
            @(posedge clk); 
            cycle_count = cycle_count + 1;
            $display("Cycle %0d | Input: 0 | Output: %0d", cycle_count, o_data);
        end

        // Run to shift the rest of the '1' out
        #(CLK_PERIOD * 3);


        // =========================================================
        // --- NEW TEST 2: Complex Load and Data Sequence ---
        // =========================================================

        $display("\n=============================================");
        $display("--- TEST 2: Full Load (h=1..8) & Data Test ---");
        $display("=============================================");
        
        // --- 4. Reset Everything ---
        $display("--- Resetting Datapath ---");
        i_shift_enable = 0;
        i_data = 0;
        i_coeff_write_en = 0;
        #5;
        rst_n = 0; // Assert reset
        #(CLK_PERIOD * 2);
        rst_n = 1; // De-assert reset
        @(posedge clk); 

        // --- 5. Load New Coefficients: h = [1, 2, 3, 4, 5, 6, 7, 8] ---
        $display("--- Loading New Coefficients (1 through 8) ---");
        i_coeff_write_en = 1;
        
        for (i = 0; i <= 7; i = i + 1) begin
            i_coeff_addr = i;
            i_coeff_data = i + 1; // Load 1, 2, 3, ... 8
            #(CLK_PERIOD);
            $display("LOAD: h[%0d] = %0d. Time: %0t", i, i + 1, $time);
        end
        
        i_coeff_write_en = 0;
        @(posedge clk); 

        // --- 6. Run Complex Data Sequence ---
        // x[n] = [10, 20, 30, 40, 50, 60, 10, 20, 0, 0, ...]
        $display("\n--- Running Complex Data Sequence ---");
        i_shift_enable = 1;
        cycle_count = 0;
        
        // Assignment uses blocking '=' now, which is necessary after moving the declaration.
        input_packed = {8'd20, 8'd10, 8'd60, 8'd50, 8'd40, 8'd30, 8'd20, 8'd10}; 

        // Initialize the unpacked array from the packed vector using a loop
        for (i = 0; i <= 7; i = i + 1) begin
            // input_packed[0:7] is 10, input_packed[8:15] is 20, etc.
            // Note: The logic here is reversed to match the provided sequence [10, 20, 30, 40, 50, 60, 10, 20]
            // The assignment needs to be done manually since the packed vector is reversed for easy concatenation.
            input_sequence[i] = input_packed[ ( (7 - i) * 8 ) +: 8 ]; 
        end
        
        // Apply the 8 main inputs
        for (i = 0; i <= 7; i = i + 1) begin
            i_data = input_sequence[i]; 
            @(posedge clk); 
            cycle_count = cycle_count + 1;
            $display("Cycle %0d | Input: %0d | Output: %0d", cycle_count, input_sequence[i], o_data);
        end
        
        // Apply 5 more zeros to flush the pipeline
        for (i = 0; i < 5; i = i + 1) begin
            i_data = 0;     
            @(posedge clk); 
            cycle_count = cycle_count + 1;
            $display("Cycle %0d | Input: 0 | Output: %0d", cycle_count, o_data);
        end
        
        // --- 7. End Simulation ---
        $display("\n--- Test Complete ---");
        $finish;
    end

endmodule
