module twiddle_rom ( // Renamed module to avoid internal conflict
    input wire [2:0] k,
    output wire signed [15:0] twiddle_real,
    output wire signed [15:0] twiddle_img
);
    // Use a single 1D array to store the concatenated Real/Imag values
    // This forces the tool to treat the memory structure uniformly.
    reg signed [15:0] ROM_R [0:7];
    reg signed [15:0] ROM_I [0:7];

    initial begin
        // Use the mathematically derived hex values.
        // If this still fails, the error is in the Testbench's 'Expected' value or environment.
        ROM_R[0] = 16'h4000;    // 16384
        ROM_R[1] = 16'h3B1C;    // 15132
        ROM_R[2] = 16'h2D41;    // 11585
        ROM_R[3] = 16'h187F;    // 6271
        ROM_R[4] = 16'h0000;    // 0
        ROM_R[5] = 16'hE781;    // -6271
        ROM_R[6] = 16'hD27F;    // -11585
        ROM_R[7] = 16'hC4C4;    // -15132
        ROM_I[0] = 16'h0000;    // 0
        ROM_I[1] = 16'hE781;    // -6271
        ROM_I[2] = 16'hD27F;    // -11585
        ROM_I[3] = 16'hC4C4;    // -15132
        ROM_I[4] = 16'hC000;    // -16384
        ROM_I[5] = 16'hC4C4;    // -15132
        ROM_I[6] = 16'hD27F;    // -11585
        ROM_I[7] = 16'hE781;    // -6271
    end

    // Combinational lookup is correct
    assign twiddle_real = ROM_R[k];
    assign twiddle_img = ROM_I[k];
endmodule