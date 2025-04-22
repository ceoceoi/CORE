// TODO: use new int_mul module that Nehal created
`timescale 1ns / 1ps
import riscv_types::*;

module wallace_tree_multiplier (
    input wire [31:0] A,     // Multiplicand
    input wire [31:0] B,     // Multiplier
    input  alu_t  alu_ctrl,  // Operation selector (MUL, MULH, MULHU, MULHSU)
    output reg [31:0] result // Product of multiplication
);

    wire [31:0][31:0] partial_products; // Array to hold partial products
    wire [31:0] multiplicand, multiplier;
    wire sign_result;
    
    assign multiplicand = (alu_ctrl == MULH || alu_ctrl == MULHSU) && A[31] ?  (~A + 1) :  A;
    assign multiplier = (alu_ctrl == MULH) && B[31] ?  (~B + 1) :  B;
    assign sign_result = (alu_ctrl == MULH && A[31] ^ B[31]) || (alu_ctrl == MULHSU && A[31]);

    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_partial_products
            for (j = 0; j < 32; j = j + 1) begin : gen_bits
                assign partial_products[i][j] = multiplicand[j] & multiplier[i];
            end
        end
    endgenerate

    // Reduce partial products using Wallace tree
    wire [63:0] sum_stage1 [9:0];


generate
    for (i = 0; i < 10; i = i + 1) begin : stage1
            assign  sum_stage1[i] = {partial_products[3*i+2],2'b0} + {partial_products[3*i+1],1'b0} + {32'b0,partial_products[3*i]};
    end
endgenerate

    wire [63:0] sum_stage2 [3:0];
    wire [31:0] carry_stage2 [3:0];

    generate
        for (i = 0; i < 4; i = i + 1) begin : stage2
            if (i < 3) begin            
                assign sum_stage2[i] = { sum_stage1[3*i+2],6'b0} + { sum_stage1[3*i+1],3'b0} + { sum_stage1[3*i]};        
            end else begin            
                assign  sum_stage2[i] = {sum_stage1[3*i]} + {partial_products[31],4'b0} + {partial_products[30],3'b0};        
            end
        end
    endgenerate

    wire [63:0] sum_stage3 [1:0];
    wire [31:0] carry_stage3 [1:0];

    generate
        for (i = 0; i < 2; i = i + 1) begin : stage3
            assign  sum_stage3[i] ={ sum_stage2[2*i+1],9'b0} + { sum_stage2[2*i]};
        end
    endgenerate


    // Final stage to obtain the product
    wire [63:0] product = {sum_stage3[1],18'b0} + {sum_stage3[0]};
    // Handle different operations 
    always @(*) begin
        case (alu_ctrl)
            MUL: result <= product[31:0]; // MUL
            MULH: result <= sign_result ? (~product[63:32] + 1) : product[63:32]; // MULH
            MULHU: result <= product[63:32]; // MULHU
            MULHSU: result <= sign_result ? (~product[63:32] + 1) : product[63:32]; // MULHSU
//                        MULHSU: result <= A[31] ? (~product[63:32]) : product[63:32]; // FIXED
//                        MULHSU: result <= product[63:32]; // FIXED
            default: result <= 32'b0;
        endcase
    end

endmodule
