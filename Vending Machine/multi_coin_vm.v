module multi_coin_vending_machine (
    input wire clk,
    input wire reset,
    
    // Coin inputs
    input wire coin_5,
    input wire coin_10,
    input wire coin_20,
    
    // User Actions
    input wire cancel_return, // Dedicated Coin Return / Cancel Button
    
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

    // State Encoded Definitions representing accumulated credit
    localparam ST_0       = 3'b000,
               ST_5       = 3'b001,
               ST_10      = 3'b010,
               ST_15      = 3'b011,
               ST_20      = 3'b100,
               ST_25      = 3'b101,
               ST_30      = 3'b110, 
               ST_INVALID = 3'b111;

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
                if (coin_5)       next_state = ST_5;
                else if (coin_10) next_state = ST_10;
                else if (coin_20) next_state = ST_20;
                else if (sel_choc || sel_tea || sel_bun) next_state = ST_INVALID;
            end
            
            ST_5: begin
                if (cancel_return) next_state = ST_0; // Cancel & return 5c
                else if (coin_5)   next_state = ST_10; 
                else if (coin_10)  next_state = ST_15; 
                else if (coin_20)  next_state = ST_25; 
                else if (sel_choc) next_state = ST_0;  // Purchase: 5 - 5 = 0
                else if (sel_tea || sel_bun) next_state = ST_INVALID; 
            end
            
            ST_10: begin
                if (cancel_return) next_state = ST_0; // Cancel & return 10c
                else if (coin_5)   next_state = ST_15; 
                else if (coin_10)  next_state = ST_20; 
                else if (coin_20)  next_state = ST_30; 
                else if (sel_choc || sel_tea) next_state = ST_0; // Drops to 0, outputs handle change
                else if (sel_bun)  next_state = ST_INVALID; 
            end
            
            ST_15: begin
                if (cancel_return) next_state = ST_0; // Cancel & return 15c
                else if (coin_5)   next_state = ST_20;
                else if (coin_10)  next_state = ST_25;
                else if (coin_20)  next_state = ST_30; 
                else if (sel_choc || sel_tea) next_state = ST_0; 
                else if (sel_bun)  next_state = ST_INVALID; 
            end
            
            ST_20: begin
                if (cancel_return) next_state = ST_0; // Cancel & return 20c
                else if (coin_5)   next_state = ST_25;
                else if (coin_10)  next_state = ST_30;
                else if (coin_20)  next_state = ST_30; 
                else if (sel_choc || sel_tea || sel_bun) next_state = ST_0; 
            end

            ST_25: begin
                if (cancel_return) next_state = ST_0; // Cancel & return 25c
                else if (coin_5 || coin_10 || coin_20) next_state = ST_30; 
                else if (sel_choc || sel_tea || sel_bun) next_state = ST_0; 
            end

            ST_30: begin
                if (cancel_return) next_state = ST_0; // Cancel & return 30c
                else if (sel_choc || sel_tea || sel_bun) next_state = ST_0; 
            end
            
            ST_INVALID: begin
                next_state = ST_0; 
            end
            
            default: next_state = ST_0;
        endcase
    end

    // 3. Combinational Output Logic
    always @(*) begin
        // Prevent latches by defaulting all outputs to 0
        dispense_choc = 1'b0;
        dispense_tea  = 1'b0;
        dispense_bun  = 1'b0;
        change_out    = 5'd0;
        error_invalid = 1'b0;
        
        case (current_state)
            ST_5: begin
                if (cancel_return) change_out = 5'd5;
                else if (sel_choc) dispense_choc = 1'b1; // 5 - 5 = 0 change
            end
            
            ST_10: begin
                if (cancel_return) change_out = 5'd10;
                else if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out    = 5'd5;  // 10 - 5 = 5c change
                end else if (sel_tea) begin
                    dispense_tea  = 1'b1;  // 10 - 10 = 0 change
                end
            end
            
            ST_15: begin
                if (cancel_return) change_out = 5'd15;
                else if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out    = 5'd10; // 15 - 5 = 10c change
                end else if (sel_tea) begin
                    dispense_tea  = 1'b1;
                    change_out    = 5'd5;  // 15 - 10 = 5c change
                end
            end
            
            ST_20: begin
                if (cancel_return) change_out = 5'd20;
                else if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out    = 5'd15; // 20 - 5 = 15c change
                end else if (sel_tea) begin
                    dispense_tea  = 1'b1;
                    change_out    = 5'd10; // 20 - 10 = 10c change
                end else if (sel_bun) begin
                    dispense_bun  = 1'b1;  // 20 - 20 = 0 change
                end
            end

            ST_25: begin
                if (cancel_return) change_out = 5'd25;
                else if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out    = 5'd20; // 25 - 5 = 20c change
                end else if (sel_tea) begin
                    dispense_tea  = 1'b1;
                    change_out    = 5'd15; // 25 - 10 = 15c change
                end else if (sel_bun) begin
                    dispense_bun  = 1'b1;
                    change_out    = 5'd5;  // 25 - 20 = 5c change
                end
            end

            ST_30: begin
                if (cancel_return) change_out = 5'd30;
                else if (sel_choc) begin
                    dispense_choc = 1'b1;
                    change_out    = 5'd25; // 30 - 5 = 25c change
                end else if (sel_tea) begin
                    dispense_tea  = 1'b1;
                    change_out    = 5'd20; // 30 - 10 = 20c change
                end else if (sel_bun) begin
                    dispense_bun  = 1'b1;
                    change_out    = 5'd10; // 30 - 20 = 10c change
                end
            end
            
            ST_INVALID: begin
                error_invalid = 1'b1;
            end
            
            default: ;
        endcase
    end

endmodule
