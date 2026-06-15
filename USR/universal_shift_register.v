// 4-to-1 Multiplexer Sub-module
module mux4to1(
    input [1:0] S,
    input in0, in1, in2, in3,
    output out
);
    assign out = (S == 2'b00) ? in0 :
                 (S == 2'b01) ? in1 :
                 (S == 2'b10) ? in2 :
                                in3;
endmodule

// D Flip-Flop Sub-module
module d_ff(
    input clk, rst,
    input d,
    output reg q
);
    always @(posedge clk or posedge rst) begin
        if (rst) q <= 1'b0;
        else     q <= d;
    end
endmodule

// Top-Level Module
module universal_shift_register (
    input clk, rst,
    input [1:0] S,
    input [3:0] I, //parallel in
    input SRSI, SLSI, //serial shift right and shift left input
    output [3:0] Q
);

    wire [3:0] D; // Interconnecting wires from MUX out to DFF in

    // Stage 3 (MSB)
    mux4to1 mux3 (.S(S), .in0(Q[3]), .in1(SRSI), .in2(Q[2]), .in3(I[3]), .out(D[3]));
    d_ff    dff3 (.clk(clk), .rst(rst), .d(D[3]), .q(Q[3]));

    // Stage 2
    mux4to1 mux2 (.S(S), .in0(Q[2]), .in1(Q[3]), .in2(Q[1]), .in3(I[2]), .out(D[2]));
    d_ff    dff2 (.clk(clk), .rst(rst), .d(D[2]), .q(Q[2]));

    // Stage 1
    mux4to1 mux1 (.S(S), .in0(Q[1]), .in1(Q[2]), .in2(Q[0]), .in3(I[1]), .out(D[1]));
    d_ff    dff1 (.clk(clk), .rst(rst), .d(D[1]), .q(Q[1]));

    // Stage 0 (LSB)
    mux4to1 mux0 (.S(S), .in0(Q[0]), .in1(Q[1]), .in2(SLSI), .in3(I[0]), .out(D[0]));
    d_ff    dff0 (.clk(clk), .rst(rst), .d(D[0]), .q(Q[0]));

endmodule
