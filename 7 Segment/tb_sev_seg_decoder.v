`timescale 1ns / 1ps

module tb_sev_seg_decoder();

    // Inputs to the Design Under Test (DUT) are registers
    reg [3:0] tb_bin_in;
    
    // Outputs from the DUT are wires
    wire [6:0] tb_seg_out;
    
    // Instantiate the Design Under Test (DUT)
    // Replace "sev_seg_decoder" with whatever you named your main module
    sev_seg_decoder uut (
        .bin_in(tb_bin_in),
        .physical_seg_out(tb_seg_out)
    );

    // Stimulus block
    initial begin
        // Initialize Input
        tb_bin_in = 4'h0;
        #10; // Wait 10 ns
        
        // Loop through all hex values from 1 to 15 (F)
        repeat (15) begin
            tb_bin_in = tb_bin_in + 1;
            #10;
        end

        $finish; 
    end
    //Monitor values in the Vivado Tcl Console
    initial begin
        $monitor("Time = %0t | Input (Hex) = %h | Output (gfedcba) = %b", $time, tb_bin_in, tb_seg_out);
    end

endmodule
