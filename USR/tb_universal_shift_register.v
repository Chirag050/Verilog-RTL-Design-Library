`timescale 1ns / 1ps

module tb_universal_shift_register;

    // Inputs to the Unit Under Test (UUT)
    reg clk;
    reg rst;
    reg [1:0] S;
    reg [3:0] I;
    reg SRSI;
    reg SLSI;

    // Outputs from the Unit Under Test (UUT)
    wire [3:0] Q;

    // Instantiate the Unit Under Test (UUT)
    universal_shift_register uut (
        .clk(clk), 
        .rst(rst), 
        .S(S), 
        .I(I), 
        .SRSI(SRSI), 
        .SLSI(SLSI), 
        .Q(Q)
    );

    // Clock generation: 50 MHz clock frequency (20ns period)
    // The clock toggles every 10ns
    always #10 clk = ~clk;

    initial begin
        // --- Step 1: Initialize Inputs ---
        clk = 0;
        rst = 1;      // Assert active-high reset initially
        S = 2'b00;    // Set mode to Hold
        I = 4'b0000;
        SRSI = 0;
        SLSI = 0;

        // Hold reset condition for 20 ns, then release it
        #20;
        rst = 0;
        
        // --- Step 2: Test Parallel Load (S = 11) ---
        // Expected outcome: On the next positive clock edge, Q should immediately become 4'b1101
        #20;
        I = 4'b1101;
        S = 2'b11; 
        
        // --- Step 3: Test Hold Mode (S = 00) ---
        // Expected outcome: Output Q should retain '1101' regardless of clock ticks
        #20;
        S = 2'b00;
        I = 4'b0000; // Change parallel input to make sure it doesn't leak into Q
        
        // --- Step 4: Test Shift Right Mode (S = 01) ---
        // Setting Serial Right Input (SRSI) to 0.
        // Clock 1: 0 enters MSB (Q[3]) -> Q becomes 0110
        // Clock 2: 0 enters MSB (Q[3]) -> Q becomes 0011
        #20;
        SRSI = 1'b0;
        S = 2'b01; 
        #40; // Allow 2 clock cycles to process shifts
        
        // Now feed a 1 into the Shift Right Serial Input
        // Clock 3: 1 enters MSB -> Q becomes 1001
        #20;
        SRSI = 1'b1;
        #20;

        // --- Step 5: Test Shift Left Mode (S = 10) ---
        // Setup a distinct starting state first via Parallel Load
        #20;
        I = 4'b0011;
        S = 2'b11;
        #20;
        
        // Change mode to Shift Left (S = 10) and provide a '1' to Serial Left Input (SLSI)
        // Clock 1: 1 enters LSB (Q[0]) -> Q becomes 0111
        // Clock 2: 1 enters LSB (Q[0]) -> Q becomes 1111
        S = 2'b10;
        SLSI = 1'b1;
        #40; // Allow 2 clock cycles to process shifts

        // --- Step 6: Test Asynchronous Reset Mid-Operation ---
        // Expected outcome: Q should clear to 0000 instantly without waiting for a clock edge
        #10; // offset slightly from the clock edge to test asynchronous nature
        rst = 1;
        #20;
        rst = 0;

        // End simulation run
        #40;
        $finish;
    end
      
endmodule
