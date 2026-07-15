module sev_seg_decoder (
    input  wire [3:0] bin_in,           // 4-bit binary input (0 to 15)
    output wire [6:0] physical_seg_out  
);

    // common anode values
    reg [6:0] seg_out; 

    always @(*) begin
        case (bin_in)
            //common anode (VCC const) 1 means led off    gfedcba
            4'h0: seg_out = 7'b1000000; // Displays 0
            4'h1: seg_out = 7'b1111001; // Displays 1
            4'h2: seg_out = 7'b0100100; // Displays 2
            4'h3: seg_out = 7'b0110000; // Displays 3
            4'h4: seg_out = 7'b0011001; // Displays 4
            4'h5: seg_out = 7'b0010010; // Displays 5
            4'h6: seg_out = 7'b0000010; // Displays 6
            4'h7: seg_out = 7'b1111000; // Displays 7
            4'h8: seg_out = 7'b0000000; // Displays 8
            4'h9: seg_out = 7'b0010000; // Displays 9
            4'hA: seg_out = 7'b0001000; // Displays A
            4'hB: seg_out = 7'b0000011; // Displays b
            4'hC: seg_out = 7'b1000110; // Displays C
            4'hD: seg_out = 7'b0100001; // Displays d
            4'hE: seg_out = 7'b0000110; // Displays E
            4'hF: seg_out = 7'b0011110; // Displays F
            default: seg_out = 7'b1111111; // All segments OFF
        endcase
    end

    // FOr common cathode (GND const) 0 means led off.
    assign physical_seg_out = ~seg_out;

endmodule
