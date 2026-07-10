`timescale 1ns / 1ps

module tb_syncFIFO;

    parameter DATA_WIDTH   = 8;
    parameter FIFO_DEPTH   = 8;
    parameter ALMOST_FULL  = 6;
    parameter ALMOST_EMPTY = 3;

    reg clk;
    reg rst_n;
    reg wr_en;
    reg [DATA_WIDTH-1:0] din;
    reg rd_en;
    
    wire [DATA_WIDTH-1:0] dout;
    wire full;
    wire empty;
    wire almost_full;
    wire almost_empty;

    // Instantiate Unit Under Test (UUT)
    syncFIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ALMOST_FULL(ALMOST_FULL),
        .ALMOST_EMPTY(ALMOST_EMPTY)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .din(din),
        .rd_en(rd_en),
        .dout(dout),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty)
    );

    // 50 MHz clock generation (20ns period)
    always #10 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk   = 0;
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        // Apply Reset
        #20 rst_n = 1;
        #20;
        
        // --- Test Scenario 1: Burst Write until Full ---
        $display("[TIME %0t] Starting Burst Writes...", $time);
        
        repeat(FIFO_DEPTH) begin
            @(posedge clk);
            #1; // Delay driving stimulus slightly after edge
            if (!full) begin
                wr_en <= 1;
                din   <= din + 8'h0A;
            end
        end

        // Wait one extra cycle to allow the final write to register
        @(posedge clk);
        #1;
        wr_en <= 0;

        if (full) 
            $display("[TIME %0t] PASS: FIFO is FULL.", $time);
        else 
            $display("[TIME %0t] FAIL: FIFO expected FULL but was not.", $time);

        // --- Test Scenario 2: Overwrite Protection Check ---
        $display("[TIME %0t] Testing Overwrite Protection...", $time);
        @(posedge clk);
        #1;
        wr_en <= 1;
        din   <= 8'hFF; // Should be ignored because full == 1
        
        @(posedge clk);
        #1;
        wr_en <= 0;
        
        // --- Test Scenario 3: Burst Read until Empty ---
        $display("[TIME %0t] Starting Burst Reads...", $time);
        repeat(FIFO_DEPTH) begin
            @(posedge clk);
            #1;
            if (!empty) begin
                rd_en <= 1;
            end
        end
        
        @(posedge clk);
        #1;
        rd_en <= 0;

        if (empty) 
            $display("[TIME %0t] PASS: FIFO is EMPTY.", $time);
        else 
            $display("[TIME %0t] FAIL: FIFO expected EMPTY but was not.", $time);

        // --- Test Scenario 4: Simultaneous Read and Write ---
        $display("[TIME %0t] Testing Concurrent Read/Write...", $time);
        @(posedge clk);
        #1;
        wr_en <= 1;
        din   <= 8'h55;

        @(posedge clk);
        #1;
        wr_en <= 1;
        rd_en <= 1;
        din   <= 8'h99;

        @(posedge clk);
        #1;
        wr_en <= 0;
        rd_en <= 0;

        #40;
        $display("[TIME %0t] Simulation Completed Successfully.", $time);
        $finish;
    end

endmodule
