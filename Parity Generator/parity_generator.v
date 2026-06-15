module parity_generator (
    input  wire [7:0] data_in,   // 8-bit input data
    output wire       even_bit,  // Generated even parity bit
    output wire       odd_bit    // Generated odd parity bit
);

    // Reduction XOR operator (^): XORs all bits of data_in together
    // data_in[0] ^ data_in[1] ^ ... ^ data_in[7]
    assign even_bit = ^data_in;
    
    assign odd_bit  = ~even_bit;

endmodule
