`timescale 1ns / 1ps

module tb_first_posedge_detector;

    // Inputs to the Unit Under Test (UUT)
    reg clk;
    reg rst_n;
    reg sig_in;

    // Outputs from the UUT
    wire pulse_out;

    // Instantiate the First Posedge Detector
    first_posedge_detector uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .sig_in(sig_in), 
        .pulse_out(pulse_out)
    );

    // Clock Generator: Creates a 20ns clock period (50MHz)
    always #10 clk = ~clk;

    // Main Simulation Process
    initial begin
        // --- 1. System Initialization ---
        clk = 0;
        rst_n = 0;      // Activate reset
        sig_in = 0;
        #30;            // Hold reset for a bit

        rst_n = 1;      // Release reset
        #10;
        
        $display("--- Starting First Posedge Detector Simulation ---");

        // --- 2. First Rising Edge (Should fire) ---
        @(posedge clk);
        #1;             // Shift input 1ns after the clock edge to avoid simulation races
        sig_in = 1;
        $display("[Time %0t ns] Applied FIRST rising edge.", $time);
        
        #40;            // Let sig_in stay high for 2 clock cycles
        
        @(posedge clk);
        #1;
        sig_in = 0;     // Bring signal low again
        $display("[Time %0t ns] Brought signal back to LOW.", $time);
        
        #40;            // Let sig_in stay low for 2 clock cycles

        // --- 3. Second Rising Edge (Should be BLOCKED) ---
        @(posedge clk);
        #1;
        sig_in = 1;     // Apply second rising edge
        $display("[Time %0t ns] Applied SECOND rising edge (Expect lockout).", $time);
        
        #40;            // Let sig_in stay high for 2 clock cycles
        
        @(posedge clk);
        #1;
        sig_in = 0;     // Bring signal low again
        
        #20;

        // --- 4. Third Rising Edge (Should also be BLOCKED) ---
        @(posedge clk);
        #1;
        sig_in = 1;     // Apply third rising edge
        $display("[Time %0t ns] Applied THIRD rising edge (Expect lockout).", $time);
        
        #40;
        
        $display("--- Simulation Complete ---");
        $finish;
    end

    // Monitor Block: Automatically prints anytime pulse_out changes state
    always @(pulse_out) begin
        $display("[TIME %0t ns] >>> pulse_out changed state to: %b <<<", $time, pulse_out);
    end
      
endmodule
