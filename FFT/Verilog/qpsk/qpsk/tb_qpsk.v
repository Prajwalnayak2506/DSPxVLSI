`timescale 1ns/1ps

module tb_qpsk;

    reg  [23:0] A;
    wire [95:0] R;
    wire [95:0] I;

    // Instantiate DUT
    qpsk dut (
        .A(A),
        .R(R),
        .I(I)
    );

    initial begin
        // Dumpfile for GTKWave
        $dumpfile("qpsk.vcd");
        $dumpvars(0, tb_qpsk);

        // Apply different inputs
        A = 24'h000000;    #10;
        A = 24'hFFFFFF;    #10;
        A = 24'hA5A5A5;    #10;
        A = 24'h123456;    #10;
        A = 24'hFEDCBA;    #10;

        $finish;
    end

endmodule

