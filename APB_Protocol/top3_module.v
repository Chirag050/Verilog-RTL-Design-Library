module top3_system(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        start_tx,       
    input  wire        write_or_read,  
    input  wire [31:0] target_address, 
    input  wire [31:0] data_to_send,   
    output wire [31:0] read_result,    
    output wire        bad_tx_error    
);

    wire [31:0] apb_addr;
    wire        apb_sel;
    wire        apb_enable;
    wire        apb_write;
    wire [31:0] apb_wdata;
    wire [31:0] apb_rdata;
    wire        apb_ready;
    wire        apb_slverr;

    apb3_master master_inst (
        .PCLK(clk), .PRESETn(reset_n),
        .req_start(start_tx), .req_write(write_or_read), .req_addr(target_address), .req_wdata(data_to_send),
        .rx_data(read_result), .transfer_err(bad_tx_error),
        .PADDR(apb_addr), .PSEL(apb_sel), .PENABLE(apb_enable), .PWRITE(apb_write), .PWDATA(apb_wdata),
        .PRDATA(apb_rdata), .PREADY(apb_ready), .PSLVERR(apb_slverr)
    );

    apb3_slave slave_inst (
        .PCLK(clk), .PRESETn(reset_n),
        .PADDR(apb_addr), .PSEL(apb_sel), .PENABLE(apb_enable), .PWRITE(apb_write), .PWDATA(apb_wdata),
        .PRDATA(apb_rdata), .PREADY(apb_ready), .PSLVERR(apb_slverr)
    );

endmodule
