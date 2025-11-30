module bfu(
    input wire signed [15:0] Xar,
    input wire signed [15:0] Xai,
    input wire signed [15:0] Xbr,
    input wire signed [15:0] Xbi,
    output wire signed [15:0] Yar,
    output wire signed [15:0] Ybr,
    output wire signed [15:0] Yai,
    output wire signed [15:0] Ybi
);
wire signed [15:0] Xbr_not;
wire signed [15:0] Xbi_not;
assign Xbr_not = ~($signed(Xbr)); 
assign Xbi_not = ~($signed(Xbi)); 
kogge_stone_16bit adder1 (
    .A   (Xar),
    .B   (Xbr), 
    .CIN (1'b0),   
    .Y   (Yar),
    .COUT()
);
kogge_stone_16bit adder2 (
    .A   (Xai),
    .B   (Xbi), 
    .CIN (1'b0),   
    .Y   (Yai),
    .COUT()
);
kogge_stone_16bit adder3 (
    .A   (Xar),
    .B   (Xbr_not), 
    .CIN (1'b1),   
    .Y   (Ybr),
    .COUT()
);
kogge_stone_16bit adder4 (
    .A   (Xai),
    .B   (Xbi_not), 
    .CIN (1'b1),   
    .Y   (Ybi),
    .COUT()
);

endmodule