`timescale 1ns/1ps

module kogge_stone_16bit_tb;

  // Parameters for easy modification
  localparam DATA_WIDTH = 16;
  localparam RESULT_STRING_WIDTH = 32 * 8; // Width for the string

  // DUT inputs
  reg [DATA_WIDTH-1:0] A_tb, B_tb;
  reg CIN_tb;

  // DUT outputs
  wire [DATA_WIDTH-1:0] Y_tb;
  wire COUT_tb;

  // Expected output calculation (for checking)
  reg [DATA_WIDTH:0] expected_sum;

  // ⭐️ FIX: Intermediate wires for $monitor ⭐️
  wire [DATA_WIDTH-1:0] expected_Y_tb;
  wire expected_COUT_tb;
  wire match;
  reg [RESULT_STRING_WIDTH-1:0] test_result;

  // Instantiate the Device Under Test (DUT)
  kogge_stone_16bit DUT (
    .A(A_tb),
    .B(B_tb),
    .CIN(CIN_tb),
    .Y(Y_tb),
    .COUT(COUT_tb)
  );

  // Expected sum calculation
  always @(A_tb, B_tb, CIN_tb) begin
    // Perform the addition using a wider register to catch the full carry-out
    expected_sum = A_tb + B_tb + CIN_tb;
  end

  // ⭐️ FIX: Continuous assignments for intermediate signals ⭐️
  assign expected_Y_tb = expected_sum[DATA_WIDTH-1:0];
  assign expected_COUT_tb = expected_sum[DATA_WIDTH];
  assign match = (Y_tb == expected_Y_tb) && (COUT_tb == expected_COUT_tb);

  always @(match) begin
    if (match)
      test_result = "PASS";
    else
      test_result = "FAIL";
  end
  // ----------------------------------------------------------------------

  // Test sequence
  initial begin
    $display("----------------------------------------------------------------------------------------------------------------");
    $display("Kogge-Stone 16-bit Adder Testbench Simulation Starts");
    $display("TIME\t\tA\t\tB\t\tCIN\t| EXPECTED(DEC)\tY(DEC)\tY(HEX)\tCOUT | RESULT");
    $display("----------------------------------------------------------------------------------------------------------------");

    // ⭐️ FIX: Use intermediate wires in $monitor ⭐️
    $monitor("%0t\t%h\t%h\t%b\t| %d\t\t%d\t%h\t%b | %s",
             $time, A_tb, B_tb, CIN_tb, expected_sum, Y_tb, Y_tb, COUT_tb,
             test_result); // test_result is a simple signal now!

    // 1. Simple addition test
    A_tb = 16'h0005; B_tb = 16'h000A; CIN_tb = 0; #10;

    // 2. Maximum simple sum (no carry out)
    A_tb = 16'h7FFF; B_tb = 16'h0000; CIN_tb = 0; #10;

    // 3. Test maximum carry-out (full 16-bit carry propagation)
    $display("--- Testing full carry chain propagation (CIN=1 to COUT=1) ---");
    A_tb = 16'hFFFF; B_tb = 16'h0000; CIN_tb = 1; #10; // FFFF + 0 + 1 = 1_0000
    A_tb = 16'hFFFF; B_tb = 16'hFFFF; CIN_tb = 0; #10; // FFFF + FFFF + 0 = 1_FFFE
    A_tb = 16'h8000; B_tb = 16'h8000; CIN_tb = 0; #10; // 8000 + 8000 + 0 = 1_0000

    // 4. Test two's complement (Negative numbers)
    $display("--- Testing two's complement (Negative numbers) ---");
    A_tb = 16'd5;       B_tb = 16'hFFFB; CIN_tb = 0; #10; // 5 + (-5) = 0
    A_tb = 16'd10;      B_tb = 16'hFFFF; CIN_tb = 0; #10; // 10 + (-1) = 9
    A_tb = 16'hFFFF;    B_tb = 16'hFFFF; CIN_tb = 0; #10; // (-1) + (-1) = (-2) i.e. 1_FFFE
    A_tb = 16'h8000;    B_tb = 16'h0001; CIN_tb = 0; #10; // (-32768) + 1 = (-32767)

    // 5. Test with CIN set for a negative sum
    A_tb = 16'hFFFE; B_tb = 16'hFFFF; CIN_tb = 1; #10; // (-2) + (-1) + 1 = -2 i.e. 1_FFFE

    // 6. Test minimum numbers
    A_tb = 16'h0000; B_tb = 16'h0000; CIN_tb = 0; #10;

    $display("----------------------------------------------------------------------------------------------------------------");
    $display("Kogge-Stone 16-bit Adder Testbench Simulation Ends");
    $finish; // Use $finish instead of $stop for cleaner simulator exit
  end

endmodule