// ==============================================================================
// Quadrant Mapper Module (Phase 2) - FIXED TO Q4.12 FORMAT
// Converts input angle [0, 2*PI] to the CORDIC range [-PI/2, PI/2].
// Uses 16-bit Q4.12 fixed-point arithmetic (Scale Factor = 2^12).
// ==============================================================================
module quadrant_mapper (
    input wire [15:0] angle_in,     // Input angle (0 to 2*PI, Q4.12 fixed-point)

    // Output for CORDIC Core Initialization
    output wire [15:0] Z_init,      // Effective angle in [-PI/2, PI/2] (Q4.12)
    output wire [15:0] X_init,      // Initial X (1/K)
    output wire [15:0] Y_init,      // Initial Y (0)
    
    // Output for CORDIC Core Post-Processing
    output reg flip_X_out,          // 1 if final Cosine (X) needs negation
    output reg flip_Y_out           // 1 if final Sine (Y) needs negation
);

// --- Q3.12 FIXED-POINT CONSTANTS (Scale Factor = 4096) ---
// Note: These values have 1 Sign Bit, 3 Integer Bits, 12 Fractional Bits.
// Max Positive Value: 7.999... (16'h7FFF)

// Real Value * 4096 = Decimal Value
parameter PI_HALF  = 16'd6434; // pi/2 (1.570796 * 4096 = 6433.98)
parameter PI_CONST = 16'd12868;  // pi (3.141593 * 4096 = 12867.96)
parameter PI_3_HALF = 16'd19302;  // 3*pi/2 (4.712389 * 4096 = 19301.95)
parameter PI_X2  = 16'd25736;  // 2*pi (6.283185 * 4096 = 25735.94)

// Inverse Scale Factor K_inv (1/K for N=16, Q3.12)
// Required Real Value: 1/K = 0.60725...
// Calculation: 0.60725 * 4096 = 2487.35
parameter K_INV = 16'd2487;
// Note: The value 16'd6746 (1.647) is the CORDIC Gain (K), not the Inverse Gain (1/K).

reg [15:0] Z_init_reg;

// X_init and Y_init are constants
assign X_init = K_INV;
assign Y_init = 16'd0; 
assign Z_init = Z_init_reg; 

// --- Combinational Quadrant Mapping Logic ---
always @(*) begin
    // Always assign a default to prevent latches
    Z_init_reg = 16'd0;
    flip_X_out = 1'b0;
    flip_Y_out = 1'b0;

    if (angle_in < PI_HALF) begin
        // Quadrant 1: [0, PI/2)
        Z_init_reg = angle_in;
        flip_X_out = 1'b0;
        flip_Y_out = 1'b0;
        
    end else if (angle_in < PI_CONST) begin
        // Quadrant 2: [PI/2, PI)
        Z_init_reg = PI_CONST - angle_in;
        flip_X_out = 1'b1;
        flip_Y_out = 1'b0;
        
    end else if (angle_in < PI_3_HALF) begin
        // Quadrant 3: [PI, 3PI/2)
        Z_init_reg = angle_in - PI_CONST;
        flip_X_out = 1'b1;
        flip_Y_out = 1'b1;
        
    end else begin 
        // Quadrant 4: [3PI/2, 2PI)
        Z_init_reg = angle_in - PI_X2; // Negative two's complement angle
        flip_X_out = 1'b0;
        flip_Y_out = 1'b1;
    end
end

endmodule
