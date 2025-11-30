module twiddle_rom (
    input wire [2:0] k,
    output wire signed [15:0] twiddle_real,
    output wire signed [15:0] twiddle_img
);
    // Q5.10 / 10 fractional bits / Scaling Factor = 1024 (16384 / 16)
    reg signed [15:0] ROM_R [0:7];
    reg signed [15:0] ROM_I [0:7];

    initial begin
        // Real Part (W^k_R)
        ROM_R[0] = 16'h0400;    // 1.0000 (1024)
        ROM_R[1] = 16'h03B2;    // 0.9239 (946)
        ROM_R[2] = 16'h02D4;    // 0.7071 (724)
        ROM_R[3] = 16'h0188;    // 0.3827 (392)
        ROM_R[4] = 16'h0000;    // 0.0000 (0)
        ROM_R[5] = 16'hFE78;    // -0.3827 (-392)
        ROM_R[6] = 16'hFD2C;    // -0.7071 (-724)
        ROM_R[7] = 16'hFC4E;    // -0.9239 (-946)
        
        // Imaginary Part (W^k_I)
        ROM_I[0] = 16'h0000;    // 0.0000 (0)
        ROM_I[1] = 16'hFE78;    // -0.3827 (-392)
        ROM_I[2] = 16'hFD2C;    // -0.7071 (-724)
        ROM_I[3] = 16'hFC4E;    // -0.9239 (-946)
        ROM_I[4] = 16'hFC00;    // -1.0000 (-1024)
        ROM_I[5] = 16'hFC4E;    // -0.9239 (-946)
        ROM_I[6] = 16'hFD2C;    // -0.7071 (-724)
        ROM_I[7] = 16'hFE78;    // -0.3827 (-392)
    end

    assign twiddle_real = ROM_R[k];
    assign twiddle_img = ROM_I[k];
endmodule