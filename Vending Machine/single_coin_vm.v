module single_coin_vending_machine (
    input wire clk,
    input wire reset,
    
    // Coin inputs (Only one coin accepted per transaction)
    input wire coin_5,
    input wire coin_10,
    input wire coin_20,
    
    // Product selection inputs
    input wire sel_choc, // Cost: 5
    input wire sel_tea,  // Cost: 10
    input wire sel_bun,  // Cost: 20
    
    // Outputs
    output reg dispense_choc,
    output reg dispense_tea,
    output reg dispense_bun,
    output reg [4:0] change_out, // Amount of change returned in cents
    output reg error_invalid     // High if user tries to buy with insufficient funds
);

    // State Encoded Definitions
    localparam ST_0       = 3'b000,
               ST_5       = 3'b001,
               ST_10      = 3'b010,
               ST_20      = 3'b011,
               ST_INVALID = 3'b100;

    reg [2:0] current_state, next_state;

    // 1. Sequential State Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= ST_0;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Combinational Next-State Logic
    always @(*) begin
        next_state = current_state; // Default hold state
        
        case (current_state)
            ST_0: begin
                // Move to the corresponding coin state in the first go
                if (coin_5)       next_state = ST_5;
                else if (coin_10) next_state = ST_10;
                else if (coin_20) next_state = ST_20;
                // If a user selects an item with 0 cents deposited
                else if (sel_choc || sel_tea || sel_bun) next_state = ST_INVALID;
            end
            
            ST_5: begin
                if (sel_choc) next_state = ST_0; // Valid: Exact change -> reset
                else if (sel_tea || sel_bun) next_state = ST_INVALID; // Invalid: Insufficient funds
            end
            
            ST_10: begin
                if (sel_choc || sel_tea) next_state = ST_0; // Valid -> reset
                else if (sel_bun) next_state = ST_INVALID; // Invalid: Insufficient funds
            end
            
            ST_20: begin
                if (sel_choc || sel_tea || sel_bun) next_state = ST_0; // Valid: All items affordable -> reset
            end
            
            ST_INVALID: begin
                next_state = ST_0; // Auto-recovery to idle state on next clock cycle
            end
            
            default: next_state = ST_0;
        endcase
    end

    // 3. Combinational Output Logic (Dispense & Change Calculation)
    always @(*) begin
        // Set all defaults to zero to avoid structural latches in Vivado
        dispense_choc = 1'b0;
        dispense_tea  = 1'b0;
        dispense_bun  = 1'b0;
        change_out    = 5'd0;
        error_invalid = 1'b0;
        
        case (current_state)
            ST_5: begin
                if (sel_choc) dispense_choc = 1'b1; // 5c coin - 5c cost = 0 change
            end
            
            ST_10: begin
                if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out = 5'd5;  // 10c coin - 5c cost = 5c change
                end else if (sel_tea) begin
                    dispense_tea = 1'b1; // 10c coin - 10c cost = 0 change
                end
            end
            
            ST_20: begin
                if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out = 5'd15; // 20c coin - 5c cost = 15c change
                end else if (sel_tea) begin
                    dispense_tea = 1'b1;
                    change_out = 5'd10; // 20c coin - 10c cost = 10c change
                end else if (sel_bun) begin
                    dispense_bun = 1'b1; // 20c coin - 20c cost = 0 change
                end
            end
            
            ST_INVALID: begin
                error_invalid = 1'b1; // Raise error flag to return inserted coin
            end
            
            default: ; // Do nothing, default values apply
        endcase
    end

endmodule
