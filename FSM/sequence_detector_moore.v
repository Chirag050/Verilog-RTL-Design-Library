module sequence_detector_moore (
    input  wire clk,
    input  wire rst,      // Asynchronous active-high reset
    input  wire sequence_in,
    output reg  detector_out
);

    // State Encoding (5 states require 3 bits)
    localparam S_RESET = 3'b000,
               S_1     = 3'b001,
               S_10    = 3'b010,
               S_101   = 3'b011,
               S_1011  = 3'b100; 

    reg [2:0] current_state, next_state;

    // 1. Sequential Block: State Transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S_RESET;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Combinational Block: Next State Logic
    always @* begin
        next_state = current_state; // Default hold state

        case (current_state)
            S_RESET: begin
                if (sequence_in) next_state = S_1;
                else             next_state = S_RESET;
            end
            
            S_1: begin
                if (~sequence_in) next_state = S_10;
                else              next_state = S_1;
            end
            
            S_10: begin
                if (sequence_in) next_state = S_101;
                else             next_state = S_RESET;
            end
            
            S_101: begin
                if (sequence_in) next_state = S_1011; // Sequence complete!
                else             next_state = S_10;
            end
            
            S_1011: begin
                // Non-overlapping behavior: decide where to go from the final '1'
                if (sequence_in) next_state = S_1;
                else             next_state = S_10;
            end
            
            default: next_state = S_RESET;
        endcase
    end

    // 3. Moore Output Logic: Depends ONLY on the current state
    always @* begin
        if (current_state == S_1011) begin
            detector_out = 1'b1;
        end else begin
            detector_out = 1'b0;
        end
    end

endmodule
