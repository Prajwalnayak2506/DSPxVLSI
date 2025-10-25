module kogge_stone_32bit(A, B, CIN, Y, COUT);
input [31:0] A, B;
input CIN;
output wire [31:0] Y;
output wire COUT;

wire [63:0] props_and_gens;
wire [31:0] carry;
wire [63:0] layer1;
wire [63:0] layer2;
wire [63:0] layer3;
wire [63:0] layer4;
wire [63:0] layer5;

genvar i;

function [1:0] PG_init_generator;
  input A_i, B_i;
  reg G, P;
  begin
     G = A_i & B_i;
     P = A_i ^ B_i;
     PG_init_generator = {G,P};
  end
endfunction

function [1:0] PG_inter_generator;
  input P_prev, P_pres, G_prev, G_pres;
    reg P, G;
      begin
      P = P_prev & P_pres;
      G = G_pres | (P_pres & G_prev);
      PG_inter_generator = {G,P};
      end
endfunction

generate
  for (i = 0; i < 32; i = i + 1) begin
    assign props_and_gens[2 * i + 1 : 2 * i] = PG_init_generator(A[i], B[i]); 
  end

  for (i = 0; i < 1; i = i + 1) begin
    assign layer1[2 * i + 1 : 2 * i] = props_and_gens[2 * i + 1 : 2 * i]; 
  end
  for (i = 1; i < 32; i = i + 1) begin
  assign layer1[2 * i + 1 : 2 * i] = PG_inter_generator(
    props_and_gens[2 * (i - 1)], props_and_gens[2 * i],
    props_and_gens[2 * (i - 1)+1], props_and_gens[2 * i+1]);
  end

  for (i = 0; i < 2; i = i + 1) begin
    assign layer2[2 * i + 1 : 2 * i] = layer1[2 * i + 1 : 2 * i]; 
  end
  for (i = 2; i < 32; i = i + 1) begin
    assign layer2[2 * i + 1 : 2 * i] = PG_inter_generator(layer1[2 * (i - 2)], layer1[2 * i], layer1[2 * (i - 2)+1], layer1[2 * i+1]); 
  end

  for (i = 0; i < 4; i = i + 1) begin
      assign layer3[2 * i + 1 : 2 * i] = layer2[2 * i + 1 : 2 * i];
  end
  for (i = 4; i < 32; i = i + 1) begin
      assign layer3[2 * i + 1 : 2 * i] = PG_inter_generator(layer2[2 * (i - 4)], layer2[2 * i], layer2[2 * (i - 4)+1], layer2[2 * i+1]);
  end

  for (i = 0; i < 8; i = i + 1) begin
      assign layer4[2 * i + 1 : 2 * i] = layer3[2 * i + 1 : 2 * i];
  end
  for (i = 8; i < 32; i = i + 1) begin
      assign layer4[2 * i + 1 : 2 * i] = PG_inter_generator(layer3[2 * (i - 8)], layer3[2 * i], layer3[2 * (i - 8)+1], layer3[2 * i+1]);
  end

    for (i = 0; i < 16; i = i + 1) begin
      assign layer5[2 * i + 1 : 2 * i] = layer4[2 * i + 1 : 2 * i];
    end
    for (i = 16; i < 32; i = i + 1) begin
      assign layer5[2 * i + 1 : 2 * i] = PG_inter_generator(layer4[2 * (i - 16)], layer4[2 * i], layer4[2 * (i - 16)+1], layer4[2 * i+1]);
    end
  endgenerate

assign carry[0] = CIN;

generate
  for (i = 1; i < 32; i = i + 1) begin
    assign carry[i] = layer5[2*(i-1)+1];
  end
endgenerate

assign COUT = layer5[63];

  generate
    for (i = 0; i < 32; i = i + 1) begin
      assign Y[i] = props_and_gens[2 * i] ^ carry[i];
    end
  endgenerate
endmodule