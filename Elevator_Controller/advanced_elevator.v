module elevator_fsm (
    input clk,                  // System clock
    input reset,                // Reset button (forces return to Ground)
    input emergency_stop,       // Emergency stop switch
    input [1:0] target_floor,   // 2-bit input: 00=G, 01=1st, 10=2nd, 11=3rd
    input sensor_G,             // High when at Ground floor
    input sensor_1,             // High when at 1st floor
    input sensor_2,             // High when at 2nd floor
    input sensor_3,             // High when at 3rd floor
    
    output reg motor_up,        // Signals motor to drive up
    output reg motor_down,      // Signals motor to drive down
    output reg motor_stop,      // Signals brakes/stop
    output reg [1:0] current_floor_out // Displays current state floor
);

    // State Encoding using Parameters
    parameter STATE_G         = 3'b000;
    parameter STATE_1         = 3'b001;
    parameter STATE_2         = 3'b010;
    parameter STATE_3         = 3'b011;
    parameter STATE_EMERGENCY = 3'b100;

    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [2:0] saved_state;     // To remember state prior to Emergency

    // 1. Sequential Logic: State Transitions
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= STATE_G;
            saved_state   <= STATE_G;
        end else if (emergency_stop) begin
            if (current_state != STATE_EMERGENCY) begin
                saved_state   <= current_state; // Save state before halting
                current_state <= STATE_EMERGENCY;
            end
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Combinational Logic: Next State Logic
    always @(*) begin
        // Default assignment to avoid latches
        next_state = current_state; 
        
        case (current_state)
            STATE_G: begin
                if (target_floor > 2'b00) begin
                    if (sensor_1)      next_state = STATE_1;
                    else if (sensor_2) next_state = STATE_2;
                    else if (sensor_3) next_state = STATE_3;
                end
            end

            STATE_1: begin
                if (target_floor > 2'b01) begin
                    if (sensor_2)      next_state = STATE_2;
                    else if (sensor_3) next_state = STATE_3;
                end else if (target_floor < 2'b01) begin
                    if (sensor_G)      next_state = STATE_G;
                end
            end

            STATE_2: begin
                if (target_floor > 2'b10) begin
                    if (sensor_3)      next_state = STATE_3;
                end else if (target_floor < 2'b10) begin
                    if (sensor_1)      next_state = STATE_1;
                    else if (sensor_G) next_state = STATE_G;
                end
            end

            STATE_3: begin
                if (target_floor < 2'b11) begin
                    if (sensor_2)      next_state = STATE_2;
                    else if (sensor_1) next_state = STATE_1;
                    else if (sensor_G) next_state = STATE_G;
                end
            end

            STATE_EMERGENCY: begin
                if (!emergency_stop) begin
                    next_state = saved_state; // Resume from where we left off
                end
            end
            
            default: next_state = STATE_G;
        endcase
    end

    // 3. Combinational Logic: Output Logic (Motor Control)
    always @(*) begin
        // Default states
        motor_up   = 1'b0;
        motor_down = 1'b0;
        motor_stop = 1'b0;
        current_floor_out = 2'b00;

        case (current_state)
            STATE_G: begin
                current_floor_out = 2'b00;
                if (target_floor > 2'b00) motor_up = 1'b1;
                else                      motor_stop = 1'b1;
            end

            STATE_1: begin
                current_floor_out = 2'b01;
                if (target_floor > 2'b01)      motor_up = 1'b1;
                else if (target_floor < 2'b01) motor_down = 1'b1;
                else                           motor_stop = 1'b1;
            end

            STATE_2: begin
                current_floor_out = 2'b10;
                if (target_floor > 2'b10)      motor_up = 1'b1;
                else if (target_floor < 2'b10) motor_down = 1'b1;
                else                           motor_stop = 1'b1;
            end

            STATE_3: begin
                current_floor_out = 2'b11;
                if (target_floor < 2'b11) motor_down = 1'b1;
                else                      motor_stop = 1'b1;
            end

            STATE_EMERGENCY: begin
                motor_stop = 1'b1; // Cut motor power instantly
                // Keep the output floor indicator locked to the last known state
                current_floor_out = saved_state[1:0]; 
            end
        endcase
    end

endmodule
