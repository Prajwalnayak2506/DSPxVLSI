module complex_reg(
    input wire signed [15:0] R_in,
    input wire signed [15:0] I_in,
    input wire clk,
    input wire rst_n,
    output reg signed [15:0] R_out,
    output reg signed [15:0] I_out
);
always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        R_out <= 16'b0;
        I_out <= 16'b0;
    end
    else begin
        R_out <= R_in;
        I_out <= I_in;
    end
end
endmodule