module first_posedge_detector (
    input  wire clk,         // System clock
    input  wire rst_n,       // Active-low synchronous reset
    input  wire sig_in,      // Input signal to monitor
    output reg  pulse_out    // Register output to avoid combinational race conditions
);

    reg sig_in_delayed;
    reg has_fired;

    always @(posedge clk) begin
        if (!rst_n) begin
            sig_in_delayed <= 1'b0;
            has_fired      <= 1'b0;
            pulse_out      <= 1'b0; // Explicitly reset the pulse output
        end else begin
            sig_in_delayed <= sig_in; // Track delay register

            // Check if a rising edge is happening right now
            if (sig_in && !sig_in_delayed) begin
                if (!has_fired) begin
                    pulse_out <= 1'b1;      // Fired safely on the first time!
                    has_fired <= 1'b1;      // Set the permanent lockout lock
                end else begin
                    pulse_out <= 1'b0;      // Blocked! We already fired before.
                end
            end else begin
                pulse_out <= 1'b0;          // No rising edge, keep pulse low
            end
        end
    end

endmodule
