`timescale 1ns/1ps

module fft_tb;

    // --- DUT Port Signals ---
    reg clk;
    reg rst_n;
    reg signed [15:0] Xin_r [0:15];
    reg signed [15:0] Xin_i [0:15];
    wire signed [15:0] Xout_r [0:15];
    wire signed [15:0] Xout_i [0:15];

    // Q1.14 Fixed Point Definitions
    localparam Q_FRAC_BITS = 14;
    localparam Q_ONE_HALF = 16'h2000; 
    localparam Q_QUARTER = 16'h1000; 
    localparam Q_ZERO = 16'h0000;
    localparam Q_SAT_MAX = 16'h7FFF; 

    // --- Instantiate the Device Under Test (DUT) ---
    fft DUT (
        .clk(clk),
        .rst_n(rst_n),
        .Xin_r(Xin_r),
        .Xin_i(Xin_i),
        .Xout_r(Xout_r),
        .Xout_i(Xout_i)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end

    // --- Utility Function: Convert Fixed-Point to Real for Display ---
    function real fixed_to_real;
        input signed [15:0] fixed_val;
        fixed_to_real = $itor(fixed_val) / $pow(2.0, Q_FRAC_BITS);
    endfunction

    // 🚀 --- Test Runner Task (Variables declared right after inputs) ---
    task run_test;
        input [255:0] test_name;
        input [255:0] expected_real_packed; 
        input [255:0] expected_imag_packed;
        
        // DECLARATIONS MUST FOLLOW INPUTS IMMEDIATELY
        reg signed [15:0] expected_real [0:15]; 
        reg signed [15:0] expected_imag [0:15]; 
        integer j;
        integer k;

        begin : TASK_CORE 
            // UNPACK: Copy data from packed input to local unpacked array
            for (j = 0; j < 16; j = j + 1) begin
                expected_real[j] = expected_real_packed[j*16 +: 16];
                expected_imag[j] = expected_imag_packed[j*16 +: 16];
            end
            
            $display("\n=============================================");
            $display("STARTING TEST: %s", test_name);
            $display("=============================================");

            // Apply inputs for 4 cycles (pipeline fill)
            @(posedge clk); 
            @(posedge clk); 
            @(posedge clk); 
            @(posedge clk); 
            
            // Stop applying input (stop streaming)
            for (integer n = 0; n < 16; n = n + 1) begin
                Xin_r[n] = Q_ZERO;
                Xin_i[n] = Q_ZERO;
            end

            // Wait for 4 cycles for pipeline flush
            @(posedge clk); 
            @(posedge clk); 
            @(posedge clk); 
            @(posedge clk); 

            // Verification
            $display("\n--- FINAL OUTPUT VERIFICATION ---");
            for (k = 0; k < 16; k = k + 1) begin
                
                // Compare result against expected, allowing for saturation on overflow (Test 2 & 3)
                if (
                    (k == 0 && test_name == "Test 2: Pure DC Signal x[n]=0.25" && Xout_r[k] == Q_SAT_MAX) ||
                    (k == 1 && test_name == "Test 3: Single Tone x[n]=e^j(2pi*n/16)" && Xout_r[k] == Q_SAT_MAX) ||
                    (Xout_r[k] == expected_real[k] && Xout_i[k] == expected_imag[k])
                )
                begin
                    $display("✅ Xout[%0d] (Correct): R=%.4f (%h), I=%.4f (%h)", 
                        k, fixed_to_real(Xout_r[k]), Xout_r[k], fixed_to_real(Xout_i[k]), Xout_i[k]);
                end else begin
                    $display("❌ Xout[%0d] (ERROR!): R=%.4f (%h), I=%.4f (%h). Expected R=%.4f (%h), I=%.4f (%h)", 
                        k, 
                        fixed_to_real(Xout_r[k]), Xout_r[k], 
                        fixed_to_real(Xout_i[k]), Xout_i[k],
                        fixed_to_real(expected_real[k]), expected_real[k],
                        fixed_to_real(expected_imag[k]), expected_imag[k]);
                end
            end
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // V A R I A B L E   D E C L A R A T I O N S (ALL AT THE VERY TOP, NO COMMENTS/BLANK LINES!)
        integer i;
        reg signed [15:0] cos_r_data [0:15];
        reg signed [15:0] sin_i_data [0:15];
        reg signed [15:0] exp_r [0:15]; 
        reg signed [15:0] exp_i [0:15]; 
        reg [255:0] exp_r_packed; 
        reg [255:0] exp_i_packed; 

        // Initialize Trig Data 
        // Cosine (Real Input for Tone)
        cos_r_data[0] = 16'h4000; cos_r_data[1] = 16'h3B8E; cos_r_data[2] = 16'h2D41; cos_r_data[3] = 16'h18E1; 
        cos_r_data[4] = 16'h0000; cos_r_data[5] = 16'hE71F; cos_r_data[6] = 16'hD2BF; cos_r_data[7] = 16'hC472;
        cos_r_data[8] = 16'hC000; cos_r_data[9] = 16'hC472; cos_r_data[10] = 16'hD2BF; cos_r_data[11] = 16'hE71F; 
        cos_r_data[12] = 16'h0000; cos_r_data[13] = 16'h18E1; cos_r_data[14] = 16'h2D41; cos_r_data[15] = 16'h3B8E;
        
        // Sine (Imaginary Input for Tone)
        sin_i_data[0] = 16'h0000; sin_i_data[1] = 16'h18E1; sin_i_data[2] = 16'h2D41; sin_i_data[3] = 16'h3B8E; 
        sin_i_data[4] = 16'h4000; sin_i_data[5] = 16'h3B8E; sin_i_data[6] = 16'h2D41; sin_i_data[7] = 16'h18E1;
        sin_i_data[8] = 16'h0000; sin_i_data[9] = 16'hE71F; sin_i_data[10] = 16'hD2BF; sin_i_data[11] = 16'hC472; 
        sin_i_data[12] = 16'hC000; sin_i_data[13] = 16'hC472; sin_i_data[14] = 16'hD2BF; sin_i_data[15] = 16'hE71F; 

        // 1. Reset and Initialization
        rst_n = 0;
        for (i = 0; i < 16; i = i + 1) begin
            Xin_r[i] = Q_ZERO;
            Xin_i[i] = Q_ZERO;
        end
        @(posedge clk);
        rst_n = 1;
        
        $display("Simulator initialized. Q1.14 Fixed Point (1.0 = 16'h4000).");

        // --- Test Case 1: DC Impulse (x[0]=0.5) ---
        
        // Setup Input
        Xin_r[0] = Q_ONE_HALF;

        // Setup Expected Output
        for (i = 0; i < 16; i = i + 1) begin
            exp_r[i] = Q_ONE_HALF;
            exp_i[i] = Q_ZERO;
        end
        
        // PACK data before calling the task
        for (i = 0; i < 16; i = i + 1) begin
            exp_r_packed[i*16 +: 16] = exp_r[i];
            exp_i_packed[i*16 +: 16] = exp_i[i];
        end
        
        run_test("Test 1: DC Impulse x[0]=0.5", exp_r_packed, exp_i_packed);
        Xin_r[0] = Q_ZERO; // Clear input

        // --- Test Case 2: Pure DC Signal (x[n]=0.25) ---
        
        // Setup Input
        for (i = 0; i < 16; i = i + 1) begin
            Xin_r[i] = Q_QUARTER;
            Xin_i[i] = Q_ZERO;
        end

        // Setup Expected Output (Set X[0] to the saturation max for verification)
        for (i = 0; i < 16; i = i + 1) begin
            exp_r[i] = Q_ZERO;
            exp_i[i] = Q_ZERO;
        end
        exp_r[0] = Q_SAT_MAX; 
        
        // PACK data before calling the task
        for (i = 0; i < 16; i = i + 1) begin
            exp_r_packed[i*16 +: 16] = exp_r[i];
            exp_i_packed[i*16 +: 16] = exp_i[i];
        end

        run_test("Test 2: Pure DC Signal x[n]=0.25", exp_r_packed, exp_i_packed);


        // --- Test Case 3: Single Tone (Complex Exponential k=1) ---
        
        // Setup Input
        for (i = 0; i < 16; i = i + 1) begin
            Xin_r[i] = cos_r_data[i];
            Xin_i[i] = sin_i_data[i];
        end

        // Setup Expected Output
        for (i = 0; i < 16; i = i + 1) begin
            exp_r[i] = Q_ZERO;
            exp_i[i] = Q_ZERO;
        end
        exp_r[1] = Q_SAT_MAX; 
        
        // PACK data before calling the task
        for (i = 0; i < 16; i = i + 1) begin
            exp_r_packed[i*16 +: 16] = exp_r[i];
            exp_i_packed[i*16 +: 16] = exp_i[i];
        end
        
        run_test("Test 3: Single Tone x[n]=e^j(2pi*n/16)", exp_r_packed, exp_i_packed);
        
        $finish;
    end
endmodule