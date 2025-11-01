module cordic_algorithm (
    input wire clk,
    input wire reset_n,
    input wire [15:0] theta,
    input wire i_valid,
    output wire [15:0] sine,
    output wire [15:0] cosine
);

// --- Register Declarations ---
reg [1:0] current_state;          // FSM state register (corrected name)
reg signed [15:0] z_reg, x_reg, y_reg; // CORDIC Iteration registers
wire sin_sign, cos_sign;           // Sign flip for quadrant correction

// --- Wire Declarations ---
wire [1:0] next_state;            // FSM next state
wire signed [15:0] z_next, x_next, y_next; // Combinational next values
wire signed [15:0] alpha_value;   // Output from constants ROM
wire [3:0] i;                     // Iteration count (e.g., 4 bits for 16 iterations)
wire done;                        // Completion signal from counter

// Signals from Quadrant Mapper (qm1) - these are the *initial* values
wire signed [15:0] Z_init;
wire signed [15:0] X_init;
wire signed [15:0] Y_init;

// FSM Control Signals
wire theta_modified;
wire o_valid;
wire start_counter_en;
wire resetter;

// CORDIC MUX/Direction Logic
wire sigma;
wire sigma_bar;

// Final Output Correction
wire [15:0] final_y;
wire [15:0] final_x;

// NOTE: Fix FSM transitions here if necessary based on your intended state machine
// For simplicity, I've kept your original state assignment logic structure.
assign theta_modified = theta; // Simplified assignment, assuming qm1 handles range reduction
assign o_valid = (current_state == 2'b11); // Assuming 2'b10 is the Done/Valid state
assign resetter = reset_n; // Corrected: use active-low reset directly
assign start_counter_en = (current_state == 2'b01) & i_valid; // Start when ready and valid input arrives

// FSM State Transition Logic (You will need to re-verify the logic below!)
assign next_state[1] = current_state[0] ^ current_state[1];
assign next_state[0] = ((done) & ~current_state[0] & current_state[1]) | (i_valid & ~current_state[0] & ~current_state[1]);

// --- Core CORDIC Assignments ---

// CORDIC Direction Decision (Sigma)
// Corrected logic: If Z is positive (MSB=0), sigma is 1 (Subtract alpha_i)
assign sigma = ~z_reg[15];
assign sigma_bar = z_reg[15]; // NOT sigma

// Shifted Values
wire signed [15:0] shifted_y = y_reg >>> i;
wire signed [15:0] shifted_x = x_reg >>> i;

// --- Module Instantiations (Your existing blocks) ---

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
    .start(start_counter_en), // Use the start signal to enable
    .iteration_count(i),
    .done(done)
);
cordic_constants consts (
    .i(i),
    .alpha_i(alpha_value)
);

// --- Kogge-Stone Adder Instantiations (Your logic) ---
// X-UPDATE (x_reg +/- shifted_y)
wire [15:0] x_add_sum;
kogge_stone_16bit ksa_x_add (.A(x_reg), .B(shifted_y), .CIN(1'b0), .Y(x_add_sum), .COUT());
wire [15:0] x_sub_sum;
kogge_stone_16bit ksa_x_sub (.A(x_reg), .B(~shifted_y), .CIN(1'b1), .Y(x_sub_sum), .COUT());
assign x_next = (sigma & x_sub_sum) | (sigma_bar & x_add_sum);

// Y-UPDATE (y_reg -/+ shifted_x)
wire [15:0] y_add_sum;
kogge_stone_16bit ksa_y_add (.A(y_reg), .B(shifted_x), .CIN(1'b0), .Y(y_add_sum), .COUT());
wire [15:0] y_sub_sum;
kogge_stone_16bit ksa_y_sub (.A(y_reg), .B(~shifted_x), .CIN(1'b1), .Y(y_sub_sum), .COUT());
assign y_next = (sigma & y_add_sum) | (sigma_bar & y_sub_sum);

// Z-UPDATE (z_reg +/- alpha_value)
wire [15:0] z_sub_sum;
kogge_stone_16bit ksa_z_sub (.A(z_reg), .B(~alpha_value), .CIN(1'b1), .Y(z_sub_sum), .COUT());
wire [15:0] z_add_sum;
kogge_stone_16bit ksa_z_add (.A(z_reg), .B(alpha_value), .CIN(1'b0), .Y(z_add_sum), .COUT());
assign z_next = (sigma & z_sub_sum) | (sigma_bar & z_add_sum);

// --- Sequential Logic Blocks ---
// FSM Sequential Logic
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        current_state <= 2'b00;
    end else begin
        current_state <= next_state;
    end
end

// CORDIC Register Sequential Logic (Updated Every Clock Cycle in the Iteration Phase)
always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        x_reg <= 16'h0;
        y_reg <= 16'h0;
        z_reg <= 16'h0;
    end else begin
        // Load initial values from the quadrant mapper when starting
        if (start_counter_en) begin
            z_reg <= Z_init;
            x_reg <= X_init;
            y_reg <= Y_init;
        end
        // Update registers only during the iteration state (2'b01)
        else if (current_state == 2'b10) begin
            z_reg <= z_next;
            x_reg <= x_next;
            y_reg <= y_next;
        end
    end
end
assign final_y = cos_sign ? (0 - y_reg) : y_reg; // sine is Y
assign final_x = sin_sign ? (0 - x_reg) : x_reg; // cosine is X

// Assign final results to output ports when the calculation is valid (done)
// You may want to register the final output for proper synchronization if this is pipelined.
assign sine = final_y;
assign cosine = final_x; 

endmodule