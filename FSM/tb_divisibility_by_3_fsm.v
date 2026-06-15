`timescale 1ns / 1ps

module tb_divisibility_by_3_fsm;

    // Inputs to UUT
    reg clk;
    reg rst;
    reg din;

    // Output from UUT
    wire divisible;

    // Instantiate the Unit Under Test (UUT)
    divisibility_by_3_fsm uut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .divisible(divisible)
    );

    // Clock Generation: 50MHz (20ns period)
    always #10 clk = ~clk;

    // Tracking variables
    integer i;
    integer expected_value;
    reg [19:0] test_stream; // A stream of 20 bits to process continuously

    initial begin
        // --- Step 1: Initialize & Single Reset ---
        clk = 0;
        rst = 1;
        din = 0;
        expected_value = 0;
        #20;
        
        rst = 0; // Release reset once at the beginning
        @(negedge clk); // Move safely away from clock edges to avoid simulation race conditions

        // --- Step 2: Define a continuous stream of random bits ---
        // Binary stream: 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1
        test_stream = 20'b11010001110101001101;

        $display("------------------------------------------------------------------");
        $display("STARTING CONTINUOUS STREAMING TEST (NO INTERMEDIATE RESETS)");
        $display("------------------------------------------------------------------");

        // --- Step 3: Stream the bits sequentially ---
        for (i = 19; i >= 0; i = i - 1) begin
            
            din = test_stream[i]; // Apply the bit
            
            // Calculate what the true accumulated value is mathematically
            expected_value = (expected_value * 2) + din;
            
            @(posedge clk); // Wait for the FSM to capture the bit on the rising edge
            #1; // Give combinatorial logic a 1ns moment to update output flags

            // Verify if FSM matches the real math modulo 3
            if (divisible == (expected_value % 3 == 0)) begin
                $display("PASS | Bit fed: %b | Total Value: %5d | FSM: %b | Expected: %b", 
                         din, expected_value, divisible, (expected_value % 3 == 0));
            end else begin
                $display("FAIL | Bit fed: %b | Total Value: %5d | FSM: %b | Expected: %b", 
                         din, expected_value, divisible, (expected_value % 3 == 0));
            end
            
            @(negedge clk); // Setup step for the next iteration loop
        end

        $display("------------------------------------------------------------------");
        $display("STREAMING SIMULATION COMPLETE");
        $display("------------------------------------------------------------------");
        $finish;
    end

endmodule
