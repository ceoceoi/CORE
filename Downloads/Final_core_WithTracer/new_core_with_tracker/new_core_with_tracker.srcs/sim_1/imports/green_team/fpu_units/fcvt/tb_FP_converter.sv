import riscv_types::*;


module tb_FP_converter;
    logic [31:0] rs1, rs2;
    logic [2:0] rm;
    logic [31:0] result;
    alu_t alu_ctrl;

    // Instantiate the DUT (Device Under Test)
    fpu uut (
        .alu_ctrl(alu_ctrl),
        .rs1(rs1),
        .rs2(rs2),
        .rm(rm),
        .result(result)
    );

    initial begin
        $display("Test Start");

        // Test Case 1: Floating-Point Min
        alu_ctrl = FMIN; rs1 = 32'h3F800000; rs2 = 32'h40000000; #10; // 1.0 vs 2.0
        $display("FMIN: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 2: Floating-Point Max
        alu_ctrl = FMAX; rs1 = 32'h40400000; rs2 = 32'h3F800000; #10; // 3.0 vs 1.0
        $display("FMAX: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 3: Floating-Point Equal
        alu_ctrl = FEQ; rs1 = 32'h3F800000; rs2 = 32'h3F800000; #10; // 1.0 == 1.0
        $display("FEQ: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 4: Floating-Point Less Than
        alu_ctrl = FLT; rs1 = 32'h3F800000; rs2 = 32'h40000000; #10; // 1.0 < 2.0
        $display("FLT: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 5: Floating-Point Less Than or Equal
        alu_ctrl = FLE; rs1 = 32'h3F800000; rs2 = 32'h3F800000; #10; // 1.0 <= 1.0
        $display("FLE: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 6: Floating-Point Sign Copy
        alu_ctrl = FSGNJ; rs1 = 32'h3F800000; rs2 = 32'hBF800000; #10; // Copy sign of -1.0 to 1.0
        $display("FSGNJ: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 7: Floating-Point Sign Negation
        alu_ctrl = FSGNJN; rs1 = 32'h3F800000; #10; // Negate 1.0
        $display("FSGNJN: rs1 = %h -> result = %h", rs1, result);

        // Test Case 8: Floating-Point Sign XOR
        alu_ctrl = FSGNJX; rs1 = 32'h3F800000; rs2 = 32'hBF800000; #10; // 1.0 XOR -1.0 sign
        $display("FSGNJX: rs1 = %h, rs2 = %h -> result = %h", rs1, rs2, result);

        // Test Case 9: Floating-Point Classification
        alu_ctrl = FCLASS; rs1 = 32'h7FC00000; #10; // Quiet NaN
        $display("FCLASS: rs1 = %h -> result = %h", rs1, result);

        // Test Case 10: Convert Float to Int
        alu_ctrl = FCVTW; rs1 = 32'h41200000; rm = 3'b000; #10; // Convert 10.0 to int
        $display("FCVTW: rs1 = %h, rm = %b -> result = %h", rs1, rm, result);

        // Test Case 11: Convert Float to Unsigned Int
        alu_ctrl = FCVTWU; rs1 = 32'h41200000; rm = 3'b000; #10; // Convert 10.0 to unsigned int
        $display("FCVTWU: rs1 = %h, rm = %b -> result = %h", rs1, rm, result);

        // Test Case 12: Move Float to Integer
        alu_ctrl = FMVXW; rs1 = 32'h41200000; #10; // Move 10.0 directly
        $display("FMVXW: rs1 = %h -> result = %h", rs1, result);

        // Test Case 13: Convert Int to Float
        alu_ctrl = FCVTSW; rs1 = 32'd10; rm = 3'b000; #10; // Convert int 10 to float
        $display("FCVTSW: rs1 = %d, rm = %b -> result = %h", rs1, rm, result);

        // Test Case 14: Convert Unsigned Int to Float
        alu_ctrl = FCVTSWU; rs1 = 32'd10; rm = 3'b000; #10; // Convert unsigned int 10 to float
        $display("FCVTSWU: rs1 = %d, rm = %b -> result = %h", rs1, rm, result);

        // Test Case 15: Move Integer to Float Register
        alu_ctrl = FMVWX; rs1 = 32'd10; #10; // Move int 10
        $display("FMVWX: rs1 = %d -> result = %h", rs1, result);

        $display("Test End");
        $finish;
    end
endmodule

