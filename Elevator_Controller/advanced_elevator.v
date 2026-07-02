module advanced_elevator (
    input clk,                          // System clock
    input reset,                        // Global reset (returns to Ground)
    input emergency_stop,               // Emergency stop switch
    
    // User Inputs
    input [3:0] car_req,                // Inside cabin requests [3=F3, 2=F2, 1=F1, 0=G]
    input [2:0] hall_req_up,            // Outside hall UP requests [2=F2, 1=F1, 0=G]
    input [3:1] hall_req_down,          // Outside hall DOWN requests [3=F3, 2=F2, 1=F1]
    
    // Physical Floor Sensors
    input sensor_G, sensor_1, sensor_2, sensor_3,
    
    // Hardware Outputs
    output reg motor_up,
    output reg motor_down,
    output reg motor_stop,
    output reg door_open,
    output reg [1:0] current_floor_out
);

    // State Encodings
    parameter STATE_G         = 3'b000;
    parameter STATE_1         = 3'b001;
    parameter STATE_2         = 3'b010;
    parameter STATE_3         = 3'b011;
    parameter STATE_EMERGENCY = 3'b100;

    // Direction Encodings
    parameter IDLE = 2'b00;
    parameter UP   = 2'b01;
    parameter DOWN = 2'b10;

    // Internal System Registers
    reg [2:0] current_state, next_state, saved_state;
    reg [1:0] dir_state, next_dir_state;
    reg [3:0] request_floor_reg; // Master Memory Registry for 4 floors

    // -------------------------------------------------------------
    // 1. ASYNCHRONOUS MEMORY REGISTRY BLOCK (Captures & Clears Requests)
    // -------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            request_floor_reg <= 4'b0000;
        end else begin
            // Capture incoming requests into memory (Bitwise OR adds new presses)
            request_floor_reg[0] <= request_floor_reg[0] | car_req[0] | hall_req_up[0];
            request_floor_reg[1] <= request_floor_reg[1] | car_req[1] | hall_req_up[1] | hall_req_down[1];
            request_floor_reg[2] <= request_floor_reg[2] | car_req[2] | hall_req_up[2] | hall_req_down[2];
            request_floor_reg[3] <= request_floor_reg[3] | car_req[3] | hall_req_down[3];

            // Clear servicing requests when doors are open at a floor
            if (door_open) begin
                case (current_state)
                    STATE_G: request_floor_reg[0] <= 1'b0;
                    STATE_1: request_floor_reg[1] <= 1'b0;
                    STATE_2: request_floor_reg[2] <= 1'b0;
                    STATE_3: request_floor_reg[3] <= 1'b0;
                endcase
            end
        end
    end

    // -------------------------------------------------------------
    // 2. SEQUENTIAL BLOCK: State Updates (Clock Driven)
    // -------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= STATE_G;
            dir_state     <= IDLE;
            saved_state   <= STATE_G;
        end else if (emergency_stop) begin
            if (current_state != STATE_EMERGENCY) begin
                saved_state   <= current_state;
                current_state <= STATE_EMERGENCY;
            end
        end else begin
            current_state <= next_state;
            dir_state     <= next_dir_state;
        end
    end

    // -------------------------------------------------------------
    // 3. CASE BLOCK 1: Next-Location Combinational Logic
    // -------------------------------------------------------------
    always @(*) begin
        next_state = current_state; // Default Hold

        case (current_state)
            STATE_G: begin
                if (dir_state == UP && sensor_1)       next_state = STATE_1;
                else if (dir_state == UP && sensor_2)  next_state = STATE_2;
                else if (dir_state == UP && sensor_3)  next_state = STATE_3;
            end

            STATE_1: begin
                if (dir_state == UP && sensor_2)       next_state = STATE_2;
                else if (dir_state == UP && sensor_3)  next_state = STATE_3;
                else if (dir_state == DOWN && sensor_G) next_state = STATE_G;
            end

            STATE_2: begin
                if (dir_state == UP && sensor_3)       next_state = STATE_3;
                else if (dir_state == DOWN && sensor_1) next_state = STATE_1;
                else if (dir_state == DOWN && sensor_G) next_state = STATE_G;
            end

            STATE_3: begin
                if (dir_state == DOWN && sensor_2)     next_state = STATE_2;
                else if (dir_state == DOWN && sensor_1) next_state = STATE_1;
                else if (dir_state == DOWN && sensor_G) next_state = STATE_G;
            end

            STATE_EMERGENCY: begin
                if (!emergency_stop) next_state = saved_state;
            end
            
            default: next_state = STATE_G;
        endcase
    end

    // -------------------------------------------------------------
    // 4. CASE BLOCK 2: Global Direction & Priority Logic
    // -------------------------------------------------------------
    always @(*) begin
        next_dir_state = dir_state;

        case (dir_state)
            IDLE: begin
                // Priority Rule: If any request exists on Ground floor, prioritize going DOWN to clear it first
                if (request_floor_reg[0] && current_state != STATE_G) begin
                    next_dir_state = DOWN;
                end
                // Otherwise, search for any active requests anywhere
                else if (request_floor_reg != 4'b0000) begin
                    if ((request_floor_reg > (1 << current_state)) && current_state != STATE_3)
                        next_dir_state = UP;
                    else if (current_state != STATE_G)
                        next_dir_state = DOWN;
                end
            end

            UP: begin
                // Keep moving up if there are pending requests above us
                if (current_state == STATE_3 || 
                    (current_state == STATE_2 && !request_floor_reg[3]) ||
                    (current_state == STATE_1 && !request_floor_reg[2] && !request_floor_reg[3]) ||
                    (request_floor_reg == 4'b0000)) begin
                    
                    // No more requests above; check if we should go down or idle
                    if (request_floor_reg != 4'b0000) next_dir_state = DOWN;
                    else                              next_dir_state = IDLE;
                end
            end

            DOWN: begin
                // Keep moving down if there are pending requests below us
                if (current_state == STATE_G ||
                    (current_state == STATE_1 && !request_floor_reg[0]) ||
                    (current_state == STATE_2 && !request_floor_reg[0] && !request_floor_reg[1]) ||
                    (request_floor_reg == 4'b0000)) begin
                    
                    // No more requests below; check if we should go up or idle
                    if (request_floor_reg != 4'b0000) next_dir_state = UP;
                    else                              next_dir_state = IDLE;
                end
            end
            
            default: next_dir_state = IDLE;
        endcase
    end

    // -------------------------------------------------------------
    // 5. CASE BLOCK 3: Physical Output Control Logic
    // -------------------------------------------------------------
    always @(*) begin
        // Secure defaults to prevent accidental motor engagements
        motor_up   = 1'b0;
        motor_down = 1'b0;
        motor_stop = 1'b1;
        door_open  = 1'b0;
        current_floor_out = current_state[1:0];

        if (current_state == STATE_EMERGENCY) begin
            motor_stop = 1'b1;
            door_open  = 1'b0; // Safety rule: doors remain shut mid-shaft
            current_floor_out = saved_state[1:0];
        end else begin
            // Check if our current floor has an outstanding request that matches the current travel intent
            if (request_floor_reg[current_state]) begin
                motor_stop = 1'b1;
                door_open  = 1'b1; // Stop and serve the floor
            end else begin
                // Run motors purely based on Direction State
                case (dir_state)
                    IDLE: begin
                        motor_stop = 1'b1;
                    end
                    UP: begin
                        motor_up   = 1'b1;
                        motor_stop = 1'b0;
                    end
                    DOWN: begin
                        motor_down = 1'b1;
                        motor_stop = 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
