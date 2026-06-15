module even_parity_fsm (
    input clk,
    input rst_n,        // Active-low asynchronous reset
    input data_in,      // Bit-by-bit input stream
    output reg even_out // High when even number of 1s detected
);

    // State Encoding
    parameter EVEN = 1'b0;
    parameter ODD  = 1'b1;

    reg current_state, next_state;

    // 1. Sequential Logic: State Transitions
    always @(posedge clk or negedge rst_n) begin // asyn
   // always @(posedge clk ) begin // sync
        if (!rst_n) begin
            current_state <= EVEN;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Combinational Logic: Next State Output
    always @(*) begin
        case (current_state)
            EVEN: begin
                if (data_in == 1'b1)
                    next_state = ODD;
                else
                    next_state = EVEN;
            end
            ODD: begin
                if (data_in == 1'b1)
                    next_state = EVEN;
                else
                    next_state = ODD;
            end
            default: next_state = EVEN;
        endcase
    end

    // 3. Output Logic: Output is high only when in EVEN state
    always @(*) begin
        even_out = (current_state == EVEN);
    end

endmodule
