module kogge_stone_16bit(A, B, CIN, Y, COUT);
  // Defining inputs and ouputs
  input [15:0] A, B;
  input CIN;
  output wire [15:0] Y;
  output wire COUT;

  // Defining internal wires and registers
  wire [31:0] props_and_gens; //layer 0
  wire [15:0] carry;
  wire [31:0] layer1;
  wire [31:0] layer2;
  wire [31:0] layer3;
  wire [31:0] layer4;

  genvar i; // Declaration required for loop variable in generate blocks

  // Function for initial generation of propagate and generatoe signals
  function [1:0] PG_init_generator;
    input A_i, B_i;
    reg G, P;
    begin
      G = A_i & B_i;
      P = A_i ^ B_i;
      PG_init_generator = {G,P};
    end
  endfunction

  // Function for internmediate P and G generation (black box in the notes)
  function [1:0] PG_inter_generator;
    input P_prev, P_pres, G_prev, G_pres;
    reg P, G;
    begin
      P = P_prev & P_pres;
      G = G_pres | (P_pres & G_prev);
      PG_inter_generator = {G,P};
    end
  endfunction


  

  generate // Generate block start

    // inital P and G generation
    for (i = 0; i < 16; i = i + 1) begin
      assign props_and_gens[2 * i + 1 : 2 * i] = PG_init_generator(A[i], B[i]); 
    end

    // layer1 
    for (i = 0; i < 1; i = i + 1) begin // passing the first element directly
      assign layer1[2 * i + 1 : 2 * i] = props_and_gens[2 * i + 1 : 2 * i]; 
    end
    for (i = 1; i < 16; i = i + 1) begin // calculating the rest
      assign layer1[2 * i + 1 : 2 * i] = PG_inter_generator(
        props_and_gens[2 * (i - 1)], props_and_gens[2 * i],
        props_and_gens[2 * (i - 1)+1], props_and_gens[2 * i+1]);
    end

    // layer2
    for (i = 0; i < 2; i = i + 1) begin // passing the first two elements directly
      assign layer2[2 * i + 1 : 2 * i] = layer1[2 * i + 1 : 2 * i]; 
    end
    for (i = 2; i < 16; i = i + 1) begin // calculating the rest
      assign layer2[2 * i + 1 : 2 * i] = PG_inter_generator(layer1[2 * (i - 2)], layer1[2 * i], layer1[2 * (i - 2)+1], layer1[2 * i+1]); 
    end

    // layer3
    for (i = 0; i < 4; i = i + 1) begin // passing the first four elements directly
      assign layer3[2 * i + 1 : 2 * i] = layer2[2 * i + 1 : 2 * i]; // Added assign
    end
    for (i = 4; i < 16; i = i + 1) begin // calculating the rest
      assign layer3[2 * i + 1 : 2 * i] = PG_inter_generator(layer2[2 * (i - 4)], layer2[2 * i], layer2[2 * (i - 4)+1], layer2[2 * i+1]); // Corrected index, added assign
    end

    // layer4
    for (i = 0; i < 8; i = i + 1) begin // passing the first eight elements directly
      assign layer4[2 * i + 1 : 2 * i] = layer3[2 * i + 1 : 2 * i]; // Added assign
    end
    for (i = 8; i < 16; i = i + 1) begin // calculating the rest
      assign layer4[2 * i + 1 : 2 * i] = PG_inter_generator(layer3[2 * (i - 8)], layer3[2 * i], layer3[2 * (i - 8)+1], layer3[2 * i+1]); // Added assign
    end

  endgenerate // Generate block end


// Carry generation
assign carry[0] = CIN;

generate
  for (i = 1; i < 16; i = i + 1) begin
    assign carry[i] = layer4[2*(i-1)+1] | (layer4[2*(i-1)] & CIN); // G_final from last layer
  end
endgenerate

assign COUT = layer4[31] | (layer4[30] & CIN); // G_final for MSB

  // Final sum generation (must be in generate block with assign)
  generate
    for (i = 0; i < 16; i = i + 1) begin
      assign Y[i] = props_and_gens[2 * i] ^ carry[i]; // Added assign
    end
  endgenerate
endmodule