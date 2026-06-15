`timescale 1ns / 1ps

module tb_single_coin_vending_machine();

    reg clk;
    reg reset;
    reg coin_5;
    reg coin_10;
    reg coin_20;
    reg sel_choc;
    reg sel_tea;
    reg sel_bun;

    wire dispense_choc;
    wire dispense_tea;
    wire dispense_bun;
    wire [4:0] change_out;
    wire error_invalid;

    // Instantiate UUT
    single_coin_vending_machine uut (
        .clk(clk), .reset(reset),
        .coin_5(coin_5), .coin_10(coin_10), .coin_20(coin_20),
        .sel_choc(sel_choc), .sel_tea(sel_tea), .sel_bun(sel_bun),
        .dispense_choc(dispense_choc), .dispense_tea(dispense_tea), .dispense_bun(dispense_bun),
        .change_out(change_out), .error_invalid(error_invalid)
    );

    // Clock Setup (10ns Cycle)
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0; reset = 1;
        coin_5 = 0; coin_10 = 0; coin_20 = 0;
        sel_choc = 0; sel_tea = 0; sel_bun = 0;
        #20 reset = 0; #10;

        // --- TEST 1: Buy Chocolate (5c) with a 20c Coin (Valid + Change) ---
        $display("[TIME %0t] Test 1: Inserting 20c for Chocolate...", $time);
        coin_20 = 1; #10; coin_20 = 0; #10; // First go: insert coin
        sel_choc = 1; #10; sel_choc = 0;    // Select item
        #20;

        // --- TEST 2: Buy Bun (20c) with a 10c Coin (Invalid State) ---
        $display("[TIME %0t] Test 2: Inserting 10c for Bun (Should Fail)...", $time);
        coin_10 = 1; #10; coin_10 = 0; #10; // First go: insert coin
        sel_bun = 1; #10; sel_bun = 0;      // Select item
        #20;

        // --- TEST 3: Select Item with no coin (Immediate Invalid State) ---
        $display("[TIME %0t] Test 3: Pressing Tea with no coins...", $time);
        sel_tea = 1; #10; sel_tea = 0;
        #20;

        $finish;
    end

    initial begin
        $monitor("Time=%0t | State=%b | Disp_Choc=%b | Disp_Bun=%b | Change=%d | Error=%b", 
                 $time, uut.current_state, dispense_choc, dispense_bun, change_out, error_invalid);
    end

endmodule
