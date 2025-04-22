// NEHAL: DID NOT CLEAN THIS SINCE IT NEEDS MODIFICATION
`timescale 1ns / 1ps
import riscv_types::*;

module fp_sqrt_Multicycle(
    input logic clk,
    input logic rst_n,
    input logic clear,      // TODO: not used yet ...
    input logic [31:0] A_top2,
    input logic p,   
    input exe_p_mux_bus_type bus_i,
    output logic busy,
    output logic p_out,
    output logic [31:0] result_out,
    output exe_p_mux_bus_type bus_o,
    // for clear logic ...
    output logic [4:0] uu_rd,    // means "unit uses this rd"
    output logic uu_reg_write,
    output logic  uu_FP_reg_write,
    input logic en
    );
    
    exe_p_mux_bus_type bus_temp; // as internal signal
    assign uu_rd = bus_temp.rd;    // used for clear logic -> (Abdulshakoor did this)
    assign uu_reg_write = bus_temp.reg_write;    // used for clear logic -> (Abdulshakoor did this)
    assign uu_FP_reg_write = bus_temp.FP_reg_write;    // used for clear logic -> (Abdulshakoor did this)

    // datapath
    logic [31:0] result;
    logic [31:0] A_top;
    logic [31:0] temp1;
    logic [31:0] temp2;
    logic exception;
    logic done_div;
    logic [31:0] A;
    logic [31:0] B;
    logic en_in;
    logic [1:0] S;
    logic [22:0] Mantissa;
    logic [31:0] w1;
    logic [31:0] x0;
    logic [7:0] Exp_2;
    logic [31:0] result_div,result_add,result_mul;
    logic done_add;
    logic en_add;
    logic done_mul;
    logic en_mul;
    logic en_temp; 
    //control
    logic [31:0] mul1_a,mul2_a;
    logic [31:0] sqrt_1by05,sqrt_1by2;
    logic [7:0] Exponent;
    logic pos;
    logic remainder;
    logic Sign;
    logic en_div;
    logic NaN, inf;
    logic on_ctrl;
    logic clrdiv;
            logic exception_ff;
    logic c1;
    //control
    assign x0 = 32'h3f5a827a;
    assign sqrt_1by05 = 32'h3fb504f3;  // 1/sqrt(0.5)
    assign sqrt_1by2 = 32'h3f3504f3;
    assign Exponent = A_top[30:23];
    assign pos = (Exponent>=8'd127) ? 1'b1 : 1'b0;
    assign Exp_2 = pos ? (Exponent-8'd127)/2 : (Exponent-8'd127-1)/2 ;
    assign remainder = (Exponent-8'd127)%2;
//    assign mul2_a = {temp1[31],Exp_2 + temp1[30:23],temp1[22:0]};
    
    //datapath
    assign Sign = A_top[31];
    assign Mantissa = A_top[22:0];
    // assign result = w1;         // Abdulshakoor - try this: "result_out = w1;"
    assign result_out = w1;         // Abdulshakoor - try this: "result_out = w1;"

    //condection
    assign NaN = (Mantissa > 23'h000000 && Exponent == 8'b11111111);
    assign inf = (Mantissa == 23'd0 && Exponent == 8'b11111111);
    assign exception = (Sign || NaN || inf) ? 1 : 0;

    // Define state type
    typedef enum logic [3:0] {
        IDLE,  // State 0
        DIV1,  // State 1
        ADD1,  // State 2
        DIV2,
        ADD2,
        DIV3,
        ADD3,
        MUL1,
        MUL2,
        FINALIZE   // State 3
    } state_t;

    state_t current_state, next_state; // State registers

    // **State Transition Logic (Sequential)**
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;  // Reset to initial state
        else if (clear)
            current_state<=IDLE;    
        else if (en)
            current_state <= next_state;  // Move to next state
    end

    // **Next State Logic (Combinational)**
    always_comb begin
        case (current_state)
            IDLE: next_state = (p) ? DIV1 : IDLE;
            DIV1: next_state = (exception) ? IDLE :(done_div) ? ADD1 : DIV1;
            ADD1: next_state =  (done_add) ? DIV2 : ADD1;
            DIV2: next_state = (done_div) ? ADD2 : DIV2;
            ADD2: next_state =  (done_add) ? DIV3 : ADD2;
            DIV3: next_state = (done_div) ? ADD3 : DIV3;
            ADD3: next_state =  (done_add) ? MUL1 : ADD3;
            MUL1: next_state =  (done_mul) ? MUL2 : MUL1;
            MUL2: next_state =  (done_mul) ? FINALIZE : MUL2 ;
            FINALIZE: next_state = IDLE; // Example transition
            default: next_state = IDLE;
        endcase 
    end

    // **Output Logic (Moore or Mealy)**
    always_comb begin
        case (current_state)
            IDLE: begin     c1=1;   clrdiv = 1;en_div =0; en_add =0; en_mul =0; p_out = (exception_ff)?1:0; S = 2'd0; A = 32'd0; B = 32'd0; busy = 0; en_in = (p)?1:0; mul2_a = 0;  on_ctrl=(p)?1:0;end
            DIV1: begin     c1=0;   clrdiv = 1;en_div =1; en_add =0; en_mul =0; p_out = 0; S = 2'd0; A = {1'b0,8'd126,Mantissa}; B = x0; busy = 1; en_in=0; mul2_a = 0;on_ctrl=(exception)?1:0;end
            ADD1: begin     c1=0;   clrdiv = 0;en_div =0; en_add =1; en_mul =0; p_out = 0; S = 2'd1; A = temp1; B = x0; busy = 1;en_in=0;  mul2_a = 0;on_ctrl=0;end
            DIV2: begin     c1=0;   clrdiv = 1;en_div =1; en_add =0; en_mul =0; p_out = 0; S = 2'd0; A = {1'b0,8'd126,Mantissa}; B = temp1; busy = 1; en_in=0;mul2_a = 0; on_ctrl=0;end
            ADD2: begin     c1=0;   clrdiv = 0;en_div =0; en_add =1; en_mul =0; p_out = 0; S = 2'd1; A = temp1; B = temp2; busy = 1;en_in=0; mul2_a = 0; on_ctrl=0;end
            DIV3: begin     c1=0;   clrdiv = 1;en_div =1; en_add =0; en_mul =0; p_out = 0; S = 2'd0; A = {1'b0,8'd126,Mantissa}; B = temp1; busy = 1;en_in=0;mul2_a = 0;  on_ctrl=0;end
            ADD3: begin     c1=0;   clrdiv = 0;en_div =0; en_add =1; en_mul =(next_state==MUL1)?0:1; p_out = 0; S = 2'd1; A = temp1; B = temp2; busy = 1;en_in=0; mul2_a = 0;on_ctrl=0;end
            MUL1: begin     c1=0;   clrdiv = 1;en_div =0; en_add =0; en_mul =(next_state==MUL2)?0:1; p_out = 0; S = 2'd2; A = temp1; B = sqrt_1by05; busy = 1;en_in=0;mul2_a = 0;  on_ctrl=0;end
            MUL2: begin     c1=0;   clrdiv = 1;en_div =0; en_add =0; en_mul =1; p_out = 0; S = 2'd2; A = {temp1[31],Exp_2 + temp1[30:23],temp1[22:0]}; B = sqrt_1by05; busy = 1; en_in=0;mul2_a = {temp1[31],Exp_2 + temp1[30:23],temp1[22:0]}; on_ctrl=(next_state==FINALIZE);end
            FINALIZE: begin c1=0;   clrdiv = 1;en_div =0; en_add =0; en_mul =0; p_out = 1; S = 2'd3; A = result; B = 32'd0; busy = 0; en_in=0;mul2_a = {temp2[31],Exp_2 + temp2[30:23],temp2[22:0]};  on_ctrl=0;end
            default: begin  c1=0;   clrdiv = 1;en_div =0; en_add =0; en_mul =0; p_out = 0; S = 2'd0; A = 32'd0; B = 32'd0; busy = 0;en_in=0; mul2_a = 0; on_ctrl=0;end
        endcase
    end
    /* Abdulshakoor - NOTE: "FINALIZE: p_out <= en? 'b0 : p_out;"   --> so it supposes to be stored in a register not as comb logic
                en = ~ (collision & p_signal_last)   --> and this is what you will recieve from outside as input port
    */
//-----------------------Data_path--------------------------------



    always_comb begin
        if(exception) begin
            if (inf) begin
                w1 = 32'b01111111100000000000000000000000;
            end
            else if(Sign || NaN) begin
                w1 = 32'b01111111100000000000000000000001;
            end
        end
        else
        case (S) 
            2'b00: w1 = result_div; 
            2'b01: w1 = {result_add[31], result_add[30:23] - 1, result_add[22:0]}; 
            2'b10: w1 = result_mul;
            2'b11: w1 = remainder ?  temp1:mul2_a ;
            default: w1 = 0;
        endcase
        end
    Register R0 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & en_in), .d(A_top2), .q(A_top));
    Register Rx ( .clk(clk), .rst_n(rst_n), .clear(c1), .en(en), .d(exception), .q(exception_ff));
    Register R1 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en&en_temp), .d(w1), .q(temp1));
    Register R2 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en&en_temp), .d(temp1), .q(temp2));
    Register #(.bits($bits(bus_i))) R3 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & on_ctrl), .d(bus_i), .q(bus_temp));              // Abdulshakoor put parameter
    Register #(.bits($bits(bus_temp))) R4 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & on_ctrl), .d(bus_temp), .q(bus_o));              // Abdulshakoor put parameter

//    Register R5 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(p_out), .d(result), .q(result_out));        // Abdulshakoor comment it
//    Register R5 ( .clk(clk), .rst_n(rst_n), .en(on_ctrl), .d(result), .q(result_out));        // Abdulshakoor: i used "on_ctrl" instead of "p_out" to get result with p_out at the same time\

//    Register R8 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(1'b1), .d(p_out & busy), .q(p_out));        // Abdulshakoor comment it -> (new) deleted
    
//    fp_div D1(.A(A),.B(B),.p_in(en_div),.p_out(done_div),.result(result_div));  // old version
    fdiv #(.num_delay(25)) D1(.clk(clk),.en(en),.rst(rst_n & clrdiv),.clear('b0),.a(A),.b(B),.p_start(en_div),.p_result(done_div),.rm(3'b000),.result(result_div));  // Dana - version
//    fp_add A1(.A(A),.B(B),.result(result_add),.rm(3'b000),.add_sub(1'b0));
    
//    fp_mul M1(.A(A),.B(B),.result(result_mul));

    
    FP_add_sub A2(.clk(clk),.rst(rst_n),.en(en),.clear(clear),.add_sub(1'b0),.num1(A),.num2(B),.rm(3'b000),.sum(result_add),.p_start(en_add),.p_result(done_add));

    FP_final_Multiplier M2(.clk(clk),.rst(rst_n),.clear(clear),.en(en),.a(A),.b(B),.rm(3'b000),.P_signal(en_mul),.P_O_signal(done_mul),.result(result_mul));
    assign en_temp   = ( current_state == MUL2 || (!(current_state == next_state )));

endmodule



//// Older version before Apr 17
//`timescale 1ns / 1ps
//import riscv_types::*;
//`include "fp_div.v"   // don't use this module it's single cycle one

//module fp_sqrt_Multicycle(
//    input logic clk,
//    input logic rst_n,
//    input logic clear,      // TODO: not used yet ...
//    input logic [31:0] A_top2,
//    input logic p,   
//    input exe_p_mux_bus_type bus_i,
//    output logic busy,
//    output logic p_out,
//    output logic [31:0] result_out,
//    output exe_p_mux_bus_type bus_o,
//    // for clear logic ...
//    output logic [4:0] uu_rd,    // means "unit uses this rd"
//    output logic uu_reg_write,
//    output logic  uu_FP_reg_write,
//    input logic en
//    );

//    exe_p_mux_bus_type bus_temp; // as internal signal
//    assign uu_rd = bus_temp.rd;    // used for clear logic
//    assign uu_reg_write = bus_temp.reg_write;    // used for clear logic -> (Abdulshakoor did this)
//    assign uu_FP_reg_write = bus_temp.FP_reg_write;    // used for clear logic -> (Abdulshakoor did this)
    
//    // datapath
//    logic [31:0] result;
//    logic [31:0] A_top;
//    logic [31:0] temp1;
//    logic [31:0] temp2;
//    logic exception;
//    logic done_div;
//    logic [31:0] A;
//    logic [31:0] B;
//    logic en_in;
//    logic [1:0] S;
//    logic [22:0] Mantissa;
//    logic [31:0] w1;
//    logic [31:0] x0;
//    logic [7:0] Exp_2;
//    logic [31:0] result_div,result_add,result_mul;
  
//    //control
//    logic [31:0] mul1_a,mul2_a;
//    logic [31:0] sqrt_1by05,sqrt_1by2;
//    logic [7:0] Exponent;
//    logic pos;
//    logic remainder;
//    logic Sign;
//    logic en_div;
//    logic NaN, inf;
//    logic on_ctrl;
//    //control
//    assign x0 = 32'h3f5a827a;
//    assign sqrt_1by05 = 32'h3fb504f3;  // 1/sqrt(0.5)
//    assign sqrt_1by2 = 32'h3f3504f3;
//    assign Exponent = A_top[30:23];
//    assign pos = (Exponent>=8'd127) ? 1'b1 : 1'b0;
//    assign Exp_2 = pos ? (Exponent-8'd127)/2 : (Exponent-8'd127-1)/2 ;
//    assign remainder = (Exponent-8'd127)%2;
////    assign mul2_a = {temp1[31],Exp_2 + temp1[30:23],temp1[22:0]};
    
//    //datapath
//    assign Sign = A_top[31];
//    assign Mantissa = A_top[22:0];
////    assign result = w1;         // Abdulshakoor - try this: "result_out = w1;"
//    assign result_out = w1;         // Abdulshakoor - try this: "result_out = w1;"

//    //condection
//    assign NaN = (Mantissa > 23'h000000 && Exponent == 8'b11111111);
//    assign inf = (Mantissa == 23'd0 && Exponent == 8'b11111111);
//    assign exception = (Sign || NaN || inf) ? 1 : 0;

//    // Define state type
//    typedef enum logic [3:0] {
//        IDLE,  // State 0
//        DIV1,  // State 1
//        ADD1,  // State 2
//        DIV2,
//        ADD2,
//        DIV3,
//        ADD3,
//        MUL1,
//        MUL2,
//        FINALIZE   // State 3
//    } state_t;

//    state_t current_state, next_state; // State registers

//    // **State Transition Logic (Sequential)**
//    always_ff @(posedge clk or negedge rst_n) begin
//        if (!rst_n)
//            current_state <= IDLE;  // Reset to initial state
//        else if (clear)
//            current_state <= IDLE;
//        else
//            current_state <= next_state;  // Move to next state
//    end

//    // **Next State Logic (Combinational)**
//    always_comb begin
//        case (current_state)
//            IDLE: next_state = (p) ? DIV1 : IDLE;
//            DIV1: next_state = (exception) ? IDLE :(done_div) ? ADD1 : DIV1;
//            ADD1: next_state =  DIV2;
//            DIV2: next_state = (done_div) ? ADD2 : DIV2;
//            ADD2: next_state = DIV3;
//            DIV3: next_state = (done_div) ? ADD3 : DIV3;
//            ADD3: next_state = MUL1;
//            MUL1: next_state = MUL2;
//            MUL2: next_state = FINALIZE;
//            FINALIZE: next_state = IDLE; // Example transition
//            default: next_state = IDLE;
//        endcase
//    end

//    // **Output Logic (Moore or Mealy)**
//    always_comb begin
//        case (current_state)
//            IDLE: begin// en = 0; 
//            en_div =0; p_out = 0; S = 2'd0; A = 32'd0; B = 32'd0; busy = 0; en_in = (p)?1:0; mul2_a = 0;  on_ctrl=(p)?1:0;end
//            DIV1: begin// en = 1;
//             en_div =1; p_out = (exception)?1:0; S = 2'd0; A = {1'b0,8'd126,Mantissa}; B = x0; busy = 1; en_in=0; mul2_a = 0;on_ctrl=(exception)?1:0;end
//            ADD1: begin// en = 1;
//             en_div =0; p_out = 0; S = 2'd1; A = temp1; B = x0; busy = 1;en_in=0;  mul2_a = 0;on_ctrl=0;end
//            DIV2: begin// en = 1;
//             en_div =1; p_out = 0; S = 2'd0; A = {1'b0,8'd126,Mantissa}; B = temp1; busy = 1; en_in=0;mul2_a = 0; on_ctrl=0;end
//            ADD2: begin //en = 1;
//             en_div =0; p_out = 0; S = 2'd1; A = temp1; B = temp2; busy = 1;en_in=0; mul2_a = 0; on_ctrl=0;end
//            DIV3: begin //en = 1;
//             en_div =1; p_out = 0; S = 2'd0; A = {1'b0,8'd126,Mantissa}; B = temp1; busy = 1;en_in=0;mul2_a = 0;  on_ctrl=0;end
//            ADD3: begin// en = 1;
//             en_div =0; p_out = 0; S = 2'd1; A = temp1; B = temp2; busy = 1;en_in=0; mul2_a = 0;on_ctrl=0;end
//            MUL1: begin// en = 1;
//             en_div =0; p_out = 0; S = 2'd2; A = temp1; B = sqrt_1by05; busy = 1;en_in=0;mul2_a = 0;  on_ctrl=0;end
//            MUL2: begin// en = 1;
//             en_div =0; p_out = 0; S = 2'd2; A = mul2_a; B = sqrt_1by05; busy = 1; en_in=0;mul2_a = {temp1[31],Exp_2 + temp1[30:23],temp1[22:0]};  on_ctrl=1;end
//            FINALIZE: begin //en = 0;
//             en_div =0; p_out = 1; S = 2'd3; A = result; B = 32'd0; busy = 0; en_in=0;mul2_a = {temp2[31],Exp_2 + temp2[30:23],temp2[22:0]};  on_ctrl=0;end
//            default: begin// en = 0;
//              en_div =0; p_out = 0; S = 2'd0; A = 32'd0; B = 32'd0; busy = 0;en_in=0; mul2_a = 0; on_ctrl=0;end
//        endcase
//    end
//    /* Abdulshakoor - NOTE: "FINALIZE: p_out <= en? 'b0 : p_out;"   --> so it supposes to be stored in a register not as comb logic
//                en = ~ (collision & p_signal_last)   --> and this is what you will recieve from outside as input port
//    */
////-----------------------Data_path--------------------------------



    
//    always_comb begin
//        if(exception) begin
//            if (inf) begin
//                w1 = 32'b01111111100000000000000000000000;
//            end
//            else if(Sign || NaN) begin
//                w1 = 32'b01111111100000000000000000000001;
//            end
//        end
//        else
//        case (S) 
//            2'b00: w1 = result_div; 
//            2'b01: w1 = {result_add[31], result_add[30:23] - 1, result_add[22:0]}; 
//            2'b10: w1 = result_mul;
//            2'b11: w1 = remainder ?  temp1:mul2_a ;
//            default: w1 = 0;
//        endcase
//        end
        
//    Register R0 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & en_in), .d(A_top2), .q(A_top));
//    Register R1 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .d(w1), .q(temp1));
//    Register R2 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en), .d(temp1), .q(temp2));
//    Register #(.bits($bits(bus_i))) R3 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & on_ctrl), .d(bus_i), .q(bus_temp));
//    Register #(.bits($bits(bus_temp))) R4 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & on_ctrl), .d(bus_temp), .q(bus_o));
////    Register R5 ( .clk(clk), .rst_n(rst_n), .clear(clear), .en(en & p_out), .d(result), .q(result_out));        // Abdulshakoor comment it
////    Register R5 ( .clk(clk), .rst_n(rst_n), .en(on_ctrl), .d(result), .q(result_out));        // Abdulshakoor: i used "on_ctrl" instead of "p_out" to get result with p_out at the same time\
    
//    // Abdulshakoor - NOTE: these modules are single cycle units (have comb logic), it's not our modules -> "fp_div.v", "fp_add.sv", and "fp_mul.v" files
//    fp_div D1(.A(A),.B(B),.p_in(en_div),.p_out(done_div),.result(result_div));
//    fp_add A1(.A(A),.B(B),.result(result_add),.rm(3'b000),.add_sub(1'b0));
//    fp_mul M1(.A(A),.B(B),.result(result_mul));
    
////    // TODO: use pipelined ones which compatable with the top-level design ("fdiv.sv", "FP_add_sub_top.sv", and "FP_final_multiplier.sv")
////    fdiv D1 ();
////    FP_add_sub A1 ();
////    FP_final_Multiplier M1 ();
    
    
//endmodule