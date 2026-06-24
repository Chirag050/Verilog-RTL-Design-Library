module apb3_master (
    input  wire        PCLK,           
    input  wire        PRESETn,        
    
    // User Command Interface
    input  wire        req_start,      
    input  wire        req_write,      
    input  wire [31:0] req_addr,       
    input  wire [31:0] req_wdata,      
    output reg  [31:0] rx_data,        
    output reg         transfer_err,   
    
    // APB Bus Outputs
    output reg  [31:0] PADDR,          
    output reg         PSEL,           
    output reg         PENABLE,        
    output reg         PWRITE,         
    output reg  [31:0] PWDATA,         
    
    // APB Bus Inputs
    input  wire [31:0] PRDATA,         
    input  wire        PREADY,         
    input  wire        PSLVERR         
);

    // Optimized State Encoding: One-hot encoding removes decode logic
    localparam IDLE   = 3'b001,
               SETUP  = 3'b010,
               ACCESS = 3'b100;

    reg [2:0] state;

    // Single Sequential Block FSM (Reduces multiplexer overhead & improves timing)
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state        <= IDLE;
            PADDR        <= 32'h0;
            PSEL         <= 1'b0;
            PENABLE      <= 1'b0;
            PWRITE       <= 1'b0;
            PWDATA       <= 32'h0;
            rx_data      <= 32'h0;
            transfer_err <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                    if (req_start) begin
                        state  <= SETUP;
                        PSEL   <= 1'b1;         // Register lookahead: assert immediately
                        PADDR  <= req_addr;
                        PWRITE <= req_write;
                        PWDATA <= req_wdata;    // Safe to write unconditionally (ignores if read)
                    end
                end

                SETUP: begin
                    state   <= ACCESS;
                    PENABLE <= 1'b1;            // Assert PENABLE on the next cycle
                end

                ACCESS: begin
                    if (PREADY) begin
                        state        <= IDLE;
                        PSEL         <= 1'b0;
                        PENABLE      <= 1'b0;
                        transfer_err <= PSLVERR;
                        if (!PWRITE) begin
                            rx_data  <= PRDATA;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
