module cordic_algorithm (
    input wire clk,
    input wire reset_n,
    input wire signed [15:0] theta,
    input wire i_valid,
    output wire signed [15:0] sine,
    output wire signed [15:0] cosine
);
reg [1:0] current_state;         
reg signed [15:0] z_reg, x_reg, y_reg; 
wire sin_sign, cos_sign;           
wire [1:0] next_state;            
wire signed [15:0] z_next, x_next, y_next; 
wire signed [15:0] alpha_value;   
wire [3:0] i;                     
wire done;                        
wire signed [15:0] Z_init;
wire signed [15:0] X_init;
wire signed [15:0] Y_init;
wire theta_modified;
wire o_valid;
wire start_counter_en;
wire resetter;
wire sigma;
wire sigma_bar;
wire [15:0] final_y;
wire [15:0] final_x;
assign theta_modified = theta; 
assign o_valid = (current_state == 2'b11); 
assign resetter = reset_n; 
assign start_counter_en = (current_state == 2'b01) & i_valid; 
assign next_state[1] = current_state[0] ^ current_state[1];
assign next_state[0] = ((done) & ~current_state[0] & current_state[1]) | (i_valid & ~current_state[0] & ~current_state[1]);
assign sigma = ~z_reg[15];
assign sigma_bar = z_reg[15]; 
wire signed [15:0] shifted_y = y_reg >>> i;
wire signed [15:0] shifted_x = x_reg >>> i;
wire signed [15:0] not_shifted_x;
wire signed [15:0] not_shifted_y;
wire signed [15:0] alpha_not;
wire signed [15:0] yb;
wire signed [15:0] xb;
wire signed [15:0] alpha_signed;
quadrant_mapper qm1 (
    .angle_in(theta), 
    .Z_init(Z_init), 
    .X_init(X_init), 
    .Y_init(Y_init), 
    .flip_X_out(sin_sign), 
    .flip_Y_out(cos_sign)
);

cordic_counter counter1 (
    .clk(clk),
    .rst_n(resetter),
    .start(start_counter_en), 
    .iteration_count(i),
    .done(done)
);
cordic_constants consts (
    .i(i),
    .alpha_i(alpha_value)
);
assign not_shifted_x = ~shifted_x;
assign not_shifted_y = ~shifted_y;
assign alpha_not = ~alpha_value;
//correct so far
wire signed [15:0] complement_shifted_x = ~shifted_x; 
wire signed [15:0] complement_shifted_y = ~shifted_y; 

assign yb = sigma ? complement_shifted_y : shifted_y; 
assign xb = sigma ? shifted_x : complement_shifted_x;

kogge_stone_16bit ksa_x (.A(x_reg), .B(yb), .CIN(sigma), .Y(x_next), .COUT());
kogge_stone_16bit ksa_y (.A(y_reg), .B(xb), .CIN(sigma_bar), .Y(y_next), .COUT());
assign alpha_signed = sigma? alpha_not : alpha_value;
kogge_stone_16bit ksa_z (.A(z_reg), .B(alpha_signed), .CIN(sigma), .Y(z_next), .COUT());
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        current_state <= 2'b00;
    end else begin
        current_state <= next_state;
    end
end
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        x_reg <= 16'h0000;
        y_reg <= 16'h0000;
        z_reg <= 16'h0000;
    end else begin
        if (start_counter_en) begin
            z_reg <= Z_init;
            x_reg <= X_init;
            y_reg <= Y_init;
        end
        else if (current_state == 2'b10) begin
            z_reg <= z_next;
            x_reg <= x_next;
            y_reg <= y_next;
        end
    end
end
// assign final_y = cos_sign ? (0 - y_reg) : y_reg; 
// assign final_x = sin_sign ? (0 - x_reg) : x_reg; 
assign sine = done? y_reg : 16'h0000;
assign cosine = done? x_reg : 16'h0000;
endmodule