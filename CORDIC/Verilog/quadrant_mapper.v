// Uses 16-bit Q2.14 fixed-point arithmetic.
module quadrant_mapper (
    input wire [15:0] angle_in,     
    output wire [15:0] Z_init,      
    output wire [15:0] X_init,      
    output wire [15:0] Y_init,      
    output reg flip_X_out,          // 1 if final Cosine (X) needs negation
    output reg flip_Y_out           // 1 if final Sine (Y) needs negation
);

parameter PI_HALF   = 16'd25735;   // pi/2 * 2^14
parameter PI_CONST  = 16'd51470;   // pi * 2^14
parameter PI_3_HALF = 16'd77205;   // 3*pi/2 * 2^14
parameter PI_X2     = 16'd102940;  // 2*pi * 2^14
// Inverse Scale Factor K_inv (1/K for N=16)
parameter K_INV     = 16'd26971;
reg [15:0] Z_init_reg; 
// X_init and Y_init are constants based on CORDIC requirements.
assign X_init = K_INV;
assign Y_init = 16'd0; 
assign Z_init = Z_init_reg; 
always @(*) begin
    Z_init_reg = angle_in;
    flip_X_out = 1'b0;
    flip_Y_out = 1'b0;

    if (angle_in < PI_HALF) begin
        // Quadrant 1: [0, PI/2) -> Z_init = angle_in
        Z_init_reg = angle_in;
        flip_X_out = 1'b0;
        flip_Y_out = 1'b0;
        
    end else if (angle_in < PI_CONST) begin
        // Quadrant 2: [PI/2, PI) -> Z_init = PI - angle_in
        // Cosine (-), Sine (+) -> Flip X
        Z_init_reg = PI_CONST - angle_in;
        flip_X_out = 1'b1;
        flip_Y_out = 1'b0;
        
    end else if (angle_in < PI_3_HALF) begin
        // Quadrant 3: [PI, 3PI/2) -> Z_init = angle_in - PI
        // Cosine (-), Sine (-) -> Flip X and Y
        Z_init_reg = angle_in - PI_CONST;
        flip_X_out = 1'b1;
        flip_Y_out = 1'b1;
        
    end else begin // angle_in >= PI_3_HALF
        // Quadrant 4: [3PI/2, 2PI) -> Z_init = angle_in - 2PI (Negative angle)
        // Cosine (+), Sine (-) -> Flip Y
        Z_init_reg = angle_in - PI_X2;
        flip_X_out = 1'b0;
        flip_Y_out = 1'b1;
    end
end

endmodule