module data_mapper(
    input  [95:0] DATA_IN_R,
    input  [95:0] DATA_IN_I,
    output [255:0] SC_OUT_R,
    output [255:0] SC_OUT_I
);

    // Assign SC_OUT_R according to specifications
    assign SC_OUT_R[15:0]  = 16'b0000000000000000;   // All zeros
    assign SC_OUT_R[31:16]  = DATA_IN_R[15:0];       // First data element
    assign SC_OUT_R[47:32]  = DATA_IN_R[31:16];      // Second data element
    assign SC_OUT_R[63:48]  = DATA_IN_R[47:32];      // Third data element
    assign SC_OUT_R[79:64]  = 16'b0000110000000000;  // Constant: 0000110000000000
    assign SC_OUT_R[95:80]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_R[111:96]  = 16'b0000000000000000; // All zeros
    assign SC_OUT_R[127:112]  = 16'b0000000000000000;// All zeros
    assign SC_OUT_R[143:128]  = 16'b0000000000000000;// All zeros
    assign SC_OUT_R[159:144]  = 16'b0000000000000000;// All zeros
    assign SC_OUT_R[175:160] = 16'b0000000000000000; // All zeros
    assign SC_OUT_R[191:176] = 16'b0000000000000000; // All zeros
    assign SC_OUT_R[207:192] = 16'b0000110000000000; // Constant: 0000110000000000
    assign SC_OUT_R[223:208] = DATA_IN_R[63:48];     // Fourth data element
    assign SC_OUT_R[239:224] = DATA_IN_R[79:64];     // Fifth data element
    assign SC_OUT_R[255:240] = DATA_IN_R[95:80];     // Sixth data element

    // Assign SC_OUT_I according to specifications
    assign SC_OUT_I[15:0]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[31:16]  = DATA_IN_I[15:0];          // First data element
    assign SC_OUT_I[47:32]  = DATA_IN_I[31:16];          // Second data element
    assign SC_OUT_I[63:48]  = DATA_IN_I[47:32];          // Third data element
    assign SC_OUT_I[79:64]  = 16'b0000000000000000;  // Constant: 0000110000000000
    assign SC_OUT_I[95:80]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[111:96]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[127:112]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[143:128]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[159:144]  = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[175:160] = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[191:176] = 16'b0000000000000000;  // All zeros
    assign SC_OUT_I[207:192] = 16'b0000000000000000;  // Constant: 0000110000000000
    assign SC_OUT_I[223:208] = DATA_IN_I[63:48];          // Fourth data element
    assign SC_OUT_I[239:224] = DATA_IN_I[79:64];          // Fifth data element
    assign SC_OUT_I[255:240] = DATA_IN_I[95:80];          // Sixth data element

endmodule
