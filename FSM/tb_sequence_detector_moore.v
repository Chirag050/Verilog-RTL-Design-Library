`timescale 1ns / 1ps

module tb_sequence_detector_moore;

    reg clk;
    reg rst;
    reg sequence_in;
    wire detector_out;

    // Instantiate Moore UUT
    sequence_detector_moore uut (
        .clk(clk),
        .rst(rst),
        .sequence_in(sequence_in),
        .detector_out(detector_out)
    );

    // Clock generation (50MHz)
    always begin
        clk = 1'b0; #10;
        clk = 1'b1; #10;
    end

    // Clock-aligned bit feeding task
    task send_bit(input bit_to_send);
        begin
            @(posedge clk);
            #1; // Delay slightly past the edge to mimic hardware setup/hold times cleanly
            sequence_in = bit_to_send;
        end
    endtask

    initial begin
        rst = 1;
        sequence_in = 0;
        
        repeat(2) @(posedge clk);
        #1 rst = 0;
        
        // Iteration 1: Send valid 1 -> 0 -> 1 -> 1
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1); 
        
        // Iteration 2: Break pattern, then send a clean 1 -> 0 -> 1 -> 1 again
        send_bit(0); 
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1); 

        // Let it cycle one more time to view the final state transition out of S_1011
        repeat(2) @(posedge clk);
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t | Rst=%b | In=%b | Out=%b | State_Encoding=%b", 
                 $time, rst, sequence_in, detector_out, uut.current_state);
    end

endmodule
