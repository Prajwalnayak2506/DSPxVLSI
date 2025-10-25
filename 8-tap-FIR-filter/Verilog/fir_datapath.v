module fir_datapath( // defining module as a blackbox
    input wire clk, rst_n,
    input wire i_shift_enable,
    input wire i_coeff_write_en,
    input wire [2:0] i_coeff_addr,
    input wire [7:0] i_coeff_data,
    input wire [7:0] i_data,
    output wire [31:0] o_data,
    output wire [127:0] o_debug_products_visible // <-- ADD THIS PORT
);

reg signed [7:0] h_n [7:0];
reg signed [7:0] x_n [7:0];
wire signed [15:0] products [7:0];
wire signed [15:0] stage1_sum [3:0];
wire signed [16:0] stage1_full_sum [3:0];
wire signed [31:0] stage2_full_sum [1:0];
wire signed [31:0] final_sum;
wire sum_cout [3:0];
wire signed [31:0] extended_sum [3:0];
integer i;
wire temp1,temp2,temp3;
//PRODUCT GENERATION
generate
    genvar j;
    for (j=0;j < 8; j=j+1) begin: multiplication
    assign products[j] = x_n[j]*h_n[j];
    assign o_debug_products_visible[(j*16) +: 16] = products[j];
    end
endgenerate

//ADDERS LAYER 1
kogge_stone_16bit instance1(
    .A (products[0]), 
    .B (products[1]), 
    .CIN (1'b0),
    .Y (stage1_sum[0]),
    .COUT (sum_cout[0])
);
kogge_stone_16bit instance2(
    .A (products[2]), 
    .B (products[3]), 
    .CIN (1'b0),
    .Y (stage1_sum[1]),
    .COUT (sum_cout[1])
);
kogge_stone_16bit instance3(
    .A (products[4]), 
    .B (products[5]), 
    .CIN (1'b0),
    .Y (stage1_sum[2]),
    .COUT (sum_cout[2])
);
kogge_stone_16bit instance4(
    .A (products[6]), 
    .B (products[7]), 
    .CIN (1'b0),
    .Y (stage1_sum[3]),
    .COUT (sum_cout[3])
);
assign stage1_full_sum[0] = {sum_cout[0], stage1_sum[0]};
assign stage1_full_sum[1] = {sum_cout[1], stage1_sum[1]};
assign stage1_full_sum[2] = {sum_cout[2], stage1_sum[2]};
assign stage1_full_sum[3] = {sum_cout[3], stage1_sum[3]};
//SIGN EXTENSION
generate
    genvar k;
    for(k = 0; k< 4;k=k+1) begin : loop1
    assign extended_sum[k] = { {15{stage1_full_sum[k][16]}}, stage1_full_sum[k] };
    end
endgenerate

//second stage of adders:
kogge_stone_32bit instance5(
    .A (extended_sum[0]),
    .B (extended_sum[1]),
    .CIN (1'b0),
    .Y (stage2_full_sum[0]),
    .COUT (temp1)
);
kogge_stone_32bit instance6(
    .A (extended_sum[2]),
    .B (extended_sum[3]),
    .CIN (1'b0),
    .Y (stage2_full_sum[1]),
    .COUT (temp2)
);
kogge_stone_32bit instance7(
    .A (stage2_full_sum[0]),
    .B (stage2_full_sum[1]),
    .CIN (1'b0),
    .Y (final_sum),
    .COUT (temp3)
);

assign o_data = final_sum;
//when update or reset
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin //if reset
        for (i = 0; i<=7; i = i+1) begin
            h_n[i] <= 8'b00000000; //set all coefficients to 0
            x_n[i] <= 8'b00000000; //set all x[n] = 0
        end
    end
        else begin
            //LOAD MODE
            if(i_coeff_write_en == 1) begin //if we are enabling writing of h[n], then 
                h_n[i_coeff_addr] <= i_coeff_data; //write value of h[n] in corresponding address
            end
            //RUN MODE
            else if(i_shift_enable == 1) begin //if we are enabling giving input
                // give command to shift registers
                x_n[0] <= i_data; 
                for (i = 1; i<=7; i=i+1) begin
                    x_n[i] <= x_n[i-1];
                end
            end
        end
    end
endmodule