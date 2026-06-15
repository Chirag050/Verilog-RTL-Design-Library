`timescale 1ns / 1ps

module tb_multi_coin_vending_machine;

    // Inputs to the UUT (Unit Under Test)
    reg clk;
    reg reset;
    reg coin_5;
    reg coin_10;
    reg coin_20;
    reg cancel_return;
    reg sel_choc;
    reg sel_tea;
    reg sel_bun;

    // Outputs from the UUT
    wire dispense_choc;
    wire dispense_tea;
    wire dispense_bun;
    wire [4:0] change_out;
    wire error_invalid;

    // Instantiate the Unit Under Test (UUT)
    multi_coin_vending_machine uut (
        .clk(clk),
        .reset(reset),
        .coin_5(coin_5),
        .coin_10(coin_10),
        .coin_20(coin_20),
        .cancel_return(cancel_return),
        .sel_choc(sel_choc),
        .sel_tea(sel_tea),
        .sel_bun(sel_bun),
        .dispense_choc(dispense_choc),
        .dispense_tea(dispense_tea),
        .dispense_bun(dispense_bun),
        .change_out(change_out),
        .error_invalid(error_invalid)
    );

    // Clock generation (50MHz clock cycle = 20ns period)
    always begin
        #10 clk = ~clk;
    end

    // Stimulus process using explicit time delays
    initial begin
        // Initialize all inputs to zero
        clk = 1'b0;
        reset = 1'b0;
        coin_5 = 1'b0;
        coin_10 = 1'b0;
        coin_20 = 1'b0;
        cancel_return = 1'b0;
        sel_choc = 1'b0;
        sel_tea = 1'b0;
        sel_bun = 1'b0;

        // --- System Reset Sequence ---
        #20;
        reset = 1'b1;
        #20;
        reset = 1'b0;
        #20; // Wait for the machine to settle in ST_0

        // =================================================================
        // TEST CASE 1: Exact Change Purchase
        // Insert 5c -> Select Chocolate (Cost 5c) -> Expect Dispense, 0 Change
        // =================================================================
        $display("[TC1] Starting Exact Change Test (Chocolate)");
        
        coin_5 = 1'b1;    // Pulse coin_5 high for 1 clock cycle (20ns)
        #20;
        coin_5 = 1'b0;
        #20;              // Small gap between operations
        
        sel_choc = 1'b1;  // Pulse select chocolate high for 1 clock cycle (20ns)
        #20;
        sel_choc = 1'b0;
        #40;              // Wait to observe state change back to ST_0


        // =================================================================
        // TEST CASE 2: Multi-Coin Accumulation & Change Calculation
        // Insert 10c + 5c (Total 15c) -> Buy Tea (Cost 10c) -> Expect Tea + 5c Change
        // =================================================================
        $display("[TC2] Starting Multi-Coin Accumulation Test (Tea)");
        
        coin_10 = 1'b1;   // Pulse 10c
        #20;
        coin_10 = 1'b0;
        #20;
        
        coin_5 = 1'b1;    // Pulse 5c (Total is now 15c)
        #20;
        coin_5 = 1'b0;
        #20;
        
        sel_tea = 1'b1;   // Select Tea
        #20;
        sel_tea = 1'b0;
        #40;


        // =================================================================
        // TEST CASE 3: Coin Return / Transaction Cancellation
        // Insert 20c + 10c (Total 30c) -> Hit Cancel -> Expect 30c Change, No Dispense
        // =================================================================
        $display("[TC3] Starting Coin Return/Cancel Test");
        
        coin_20 = 1'b1;   // Pulse 20c
        #20;
        coin_20 = 1'b0;
        #20;
        
        coin_10 = 1'b1;   // Pulse 10c (Total is now 30c)
        #20;
        coin_10 = 1'b0;
        #20;
        
        cancel_return = 1'b1; // Press Coin Return
        #20;
        cancel_return = 1'b0;
        #40;


        // =================================================================
        // TEST CASE 4: Error State (Insufficient Funds)
        // Insert 5c -> Select Bun (Cost 20c) -> Expect Error Flag, Return to 0
        // =================================================================
        $display("[TC4] Starting Insufficient Funds Test");
        
        coin_5 = 1'b1;    // Pulse 5c
        #20;
        coin_5 = 1'b0;
        #20;
        
        sel_bun = 1'b1;   // Select Bun (Costs 20c, but we only have 5c)
        #20;
        sel_bun = 1'b0;
        #60;

        // End Simulation
        $display("Simulation Completed Successfully.");
        $finish;
    end
      
endmodule
