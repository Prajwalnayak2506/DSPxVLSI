`timescale 1ns/1ps

module tb_data_mapper;

    reg  [95:0] DATA_IN_R;
    reg  [95:0] DATA_IN_I;
    wire [255:0] SC_OUT_R;
    wire [255:0] SC_OUT_I;

    // Instantiate DUT
    data_mapper uut (
        .DATA_IN_R(DATA_IN_R),
        .DATA_IN_I(DATA_IN_I),
        .SC_OUT_R(SC_OUT_R),
        .SC_OUT_I(SC_OUT_I)
    );

    integer i;

initial begin
    $dumpfile("tb_data_mapper.vcd");   // name of the VCD file
    $dumpvars(0, tb_data_mapper);      // dump all signals in tb_data_mapper

    $display("Starting testbench...");

    // Initialize inputs
    DATA_IN_R = {16'h6666, 16'h5555, 16'h4444, 16'h3333, 16'h2222, 16'h1111};
    DATA_IN_I = {16'hFFFF, 16'hEEEE, 16'hDDDD, 16'hCCCC, 16'hBBBB, 16'hAAAA};

    #5;

    // Print outputs
    $display("SC_OUT_R:");
    for (i = 0; i < 16; i = i + 1) begin
        $display("SC_OUT_R[%0d] = %h", i, SC_OUT_R[i*16 +: 16]);
    end

    $display("SC_OUT_I:");
    for (i = 0; i < 16; i = i + 1) begin
        $display("SC_OUT_I[%0d] = %h", i, SC_OUT_I[i*16 +: 16]);
    end

    $finish;
end



endmodule

