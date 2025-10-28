module cordic_counter (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg [3:0] iteration_count,
    output wire done
);
parameter MAX_COUNT = 4'd15;
reg counting_active;
wire next_count_0, next_count_1, next_count_2, next_count_3;
assign done = (iteration_count == MAX_COUNT) && counting_active;
assign next_count_0 = ~iteration_count[0];
assign next_count_1 = iteration_count[0] ^ iteration_count[1];
assign next_count_2 = ((~iteration_count[3]) & (~iteration_count[2]) & (iteration_count[1]) & iteration_count[0])
                    | (~iteration_count[0] & iteration_count[2])
                    | (~iteration_count[1] & iteration_count[2])
                    | (~iteration_count[1] & iteration_count[0] & iteration_count[3]);
assign next_count_3 = ((~iteration_count[3]) & (iteration_count[2]) & (iteration_count[1]) & iteration_count[0])
                    | (~iteration_count[0] & iteration_count[3])
                    | (~iteration_count[1] & iteration_count[3])
                    | (~iteration_count[2] & iteration_count[3]);
always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        iteration_count <= 4'd0;
        counting_active <= 1'b0;
    end else begin
        if (start) begin
            iteration_count <= 4'd0;
            counting_active <= 1'b1;
        end else if (counting_active) begin
            if (iteration_count < MAX_COUNT) begin
                iteration_count <= {next_count_3, next_count_2, next_count_1, next_count_0};
            end else begin
                counting_active <= 1'b0;
            end
        end
    end
end
endmodule