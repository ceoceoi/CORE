import riscv_types::*;

module multi_cycle_multiplier #(
    parameter WIDTH = 32  // width of numbers in bits (integer only)
) (
    input wire logic clk,    // clock
    input wire logic rst,    // reset
    input wire logic i_p_signal,  // start calculation
    input  alu_t  alu_ctrl,             // Operation selector (MUL, MULH, MULHU, MULHSU)
    exe_p_mux_bus_type  i_pipeline_control,  // pipeline control input
    input wire logic [WIDTH-1:0] a,   // multiplicand
    input wire logic [WIDTH-1:0] b,   // multiplier
    output logic stall,   // calculation in progress
    output logic o_p_signal,   // calculation is complete (high for one tick)
    output logic [31:0] result,  // result value
    exe_p_mux_bus_type  o_pipeline_control,   // pipeline control output
    
    // signals to solve Write-After-Write (WAW) issue
    output logic [4:0] rd_mul_unit_use,
    input logic clear
);

    // Internal signals
    logic [$clog2(WIDTH):0] i;           // iteration counter
    logic [63:0] multiplicand, multiplier;
    logic [63:0] product;
    logic sign_result;
    exe_p_mux_bus_type  temp_i_pipeline_control;

    // State Encoding
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        INIT = 2'b01,
        CALC = 2'b10,
        FINALIZE = 2'b11
    } state_t;

    state_t state, next_state;

    // State Transition Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else if (clear) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next State Logic
    always_comb begin
        case (state)
            IDLE: begin
                if (i_p_signal)
                    next_state = INIT;
                else
                    next_state = IDLE;
            end
            INIT: begin
                next_state = CALC;
            end
            CALC: begin
                if (i == WIDTH-1)
                    next_state = FINALIZE;
                else
                    next_state = CALC;
            end
            FINALIZE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output and Internal State Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            product <= 64'b0;
            multiplicand <= 64'b0;
            multiplier <= 64'b0;
            i <= 0;
            result <= 32'b0;
            stall <= 0;
            o_p_signal <= 0;
            o_pipeline_control <= 32'b0;
            rd_mul_unit_use = 'b0;    // Green Team did
        end else if (clear) begin
            product <= 64'b0;
            multiplicand <= 64'b0;
            multiplier <= 64'b0;
            i <= 0;
            result <= 32'b0;
            stall <= 0;
            o_p_signal <= 0;
            o_pipeline_control <= 32'b0;
            rd_mul_unit_use = 'b0;    // Green Team did
        end else begin
            case (state)
                IDLE: begin
//                    stall <= 0;
//                    o_p_signal <= 0;
//                    o_pipeline_control <= 32'b0;
                   // multiplicand <= 64'b0;
                    //multiplier <=64'b0;

                    if (i_p_signal) begin // WAW
                        stall <= 1;
                        o_p_signal <= 0;
                        o_pipeline_control <= 32'b0;
                        temp_i_pipeline_control <= i_pipeline_control;
                        rd_mul_unit_use = i_pipeline_control.rd;    // Green Team did
                    end else begin
                        stall <= 0;
                        o_p_signal <= 0;
//                        o_pipeline_control <= 32'b0;
                    end
                end
                INIT: begin
                    multiplicand <= (alu_ctrl == MULH || alu_ctrl == MULHSU) && a[31] ? {32'b0, (~a + 1)} : {32'b0, a};
                    multiplier <= (alu_ctrl == MULH) && b[31] ? {32'b0, (~b + 1)} : {32'b0, b};
                    product <= 64'b0;
                    i <= 0;
                    stall <= 1;
                    sign_result <= (alu_ctrl == MULH && a[31] ^ b[31]) || (alu_ctrl == MULHSU && a[31]);
//                    temp_i_pipeline_control <= i_pipeline_control;
                   o_pipeline_control<=temp_i_pipeline_control;
                end
                CALC: begin
//                   o_pipeline_control<=temp_i_pipeline_control;
                    if (multiplier[0])
                        product <= product + multiplicand;
                    multiplicand <= multiplicand << 1;
                    multiplier <= multiplier >> 1;
                    i <= i + 1;
                end
                FINALIZE: begin
                    case (alu_ctrl)
                        MUL: result <= product[31:0]; // MUL
                        MULH: result <= sign_result ? (~product[63:32] + 1) : product[63:32]; // MULH
                        MULHU: result <= product[63:32]; // MULHU
                        MULHSU: result <= sign_result ? (~product[63:32] + 1) : product[63:32]; // MULHSU
                        default: result <= 32'b0;
                    endcase
                    stall <= 0;
                    o_p_signal <= 1;
                    o_pipeline_control <= temp_i_pipeline_control;
                end
            endcase
        end
    end

endmodule