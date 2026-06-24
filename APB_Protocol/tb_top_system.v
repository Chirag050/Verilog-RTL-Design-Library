module tb_top_system();

    // Inputs to top system
    reg clk;
    reg reset_n;
    reg start_tx;
    reg write_or_read;
    reg [31:0] target_address;
    reg [31:0] data_to_send;
    
    // Output from top system
    wire [31:0] read_result;

    // Instantiate Top System (UUT)
    top3_system uut (
        .clk(clk),
        .reset_n(reset_n),
        .start_tx(start_tx),
        .write_or_read(write_or_read),
        .target_address(target_address),
        .data_to_send(data_to_send),
        .read_result(read_result)
    );

    // 50MHz Clock Generation
    always begin
        #10 clk = ~clk;
    end

    // --- REUSABLE TRANSACTION TASK ---
    // This automates driving the inputs to initiate a master sequence
    task apb_transaction(
        input        is_write,  // 1 for write, 0 for read
        input [31:0] addr,      // Target register address
        input [31:0] data       // Data payload (ignored during reads)
    );
    begin
        @(posedge clk);
        target_address = addr;
        data_to_send   = data;
        write_or_read  = is_write;
        start_tx       = 1'b1;       // Pulse start
        
        @(posedge clk);
        start_tx       = 1'b0;       // Turn off start pulse
        
        #60;                         // Wait 3 cycles for transfer to fully finish
    end
    endtask


    // --- MAIN TEST PROCEDURAL BLOCK ---
    initial begin
        // Initialize all input signals
        clk            = 0;
        reset_n        = 0; // Hold system in reset
        start_tx       = 0;
        write_or_read  = 0;
        target_address = 32'h0;
        data_to_send   = 32'h0;

        #40;
        reset_n = 1;        // Release reset
        #20;

        $display("--------------------------------------------------");
        $display("[TESTBENCH] STARTING MULTI-REGISTER WRITE BURST");
        $display("--------------------------------------------------");
        
        // Write Unique Data to Register 0 (Address 0x0)
        $display("[WRITE] Writing 0xAAAA_AAAA to Reg0 (Addr: 0x0)");
        apb_transaction(1'b1, 32'h0, 32'hAAAA_AAAA);

        // Write Unique Data to Register 1 (Address 0x4)
        $display("[WRITE] Writing 0xBBBB_BBBB to Reg1 (Addr: 0x4)");
        apb_transaction(1'b1, 32'h4, 32'hBBBB_BBBB);

        // Write Unique Data to Register 2 (Address 0x8)
        $display("[WRITE] Writing 0xCCCC_CCCC to Reg2 (Addr: 0x8)");
        apb_transaction(1'b1, 32'h8, 32'hCCCC_CCCC);

        // Write Unique Data to Register 3 (Address 0xC)
        $display("[WRITE] Writing 0xDDDD_DDDD to Reg3 (Addr: 0xC)");
        apb_transaction(1'b1, 32'hC, 32'hDDDD_DDDD);


        $display("\n--------------------------------------------------");
        $display("[TESTBENCH] STARTING MULTI-REGISTER READBACK VERIFICATION");
        $display("--------------------------------------------------");

        // Read back and verify Register 0
        apb_transaction(1'b0, 32'h0, 32'h0);
        $display("[READ] Reg0 (Addr 0x0) read out: %h (Expected: aaaaaaaa)", read_result);

        // Read back and verify Register 1
        apb_transaction(1'b0, 32'h4, 32'h0);
        $display("[READ] Reg1 (Addr 0x4) read out: %h (Expected: bbbbbbbb)", read_result);

        // Read back and verify Register 2
        apb_transaction(1'b0, 32'h8, 32'h0);
        $display("[READ] Reg2 (Addr 0x8) read out: %h (Expected: cccccccc)", read_result);

        // Read back and verify Register 3
        apb_transaction(1'b0, 32'hC, 32'h0);
        $display("[READ] Reg3 (Addr 0xC) read out: %h (Expected: dddddddd)", read_result);
        
        // Bonus Test: Read from an invalid address to test error code decoding
        apb_transaction(1'b0, 32'h14, 32'h0);
        $display("[READ] Invalid Addr (0x14) read out: %h (Expected: deadbeef)", read_result);

        $display("\n--------------------------------------------------");
        $display("[TESTBENCH] All multi-register tests completed successfully!");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
