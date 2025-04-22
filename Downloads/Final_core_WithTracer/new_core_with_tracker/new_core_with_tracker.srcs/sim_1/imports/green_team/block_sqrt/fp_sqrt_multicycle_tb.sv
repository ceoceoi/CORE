`timescale 1ns / 1ps
import riscv_types::*;

module Fp_Sqrt_Multicycle_tb;
    // Inputs
    logic clk;
    logic rst_n;
    logic clear;
    logic [31:0] A_top;
    exe_p_mux_bus_type bus_i;
    logic p;
    exe_p_mux_bus_type bus_o;
    // Outputs
    logic busy;
    logic p_out;
    logic [31:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    fp_sqrt_Multicycle uut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .A_top2(A_top),
        .bus_i(bus_i),
        .p(p),
        .bus_o(bus_o),
        .busy(busy),
        .p_out(p_out),
        .result_out(result)
    );
    
    // Clock Generation
    always #5 clk = ~clk;
    
    // Test Procedure
    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        clear = 0;
        A_top = 32'h41800000; // Example input (3.0 in IEEE-754 single-precision)
        bus_i = 2;
        p = 0;
        
        // Reset Sequence
        #10 rst_n = 1;
        #10 clear = 1;
        #10 clear = 0;
        
        // Test Case 1: Start operation
        #10 p = 1;
        #50 p = 0;
        
        // Wait for the operation to complete
        wait (p_out == 1);
        
        // Display Result
        $display("Test Case 1: A_top = %h, Result = %h", A_top, result);
        
        // Additional test cases can be added here
        
        #50;
        $stop;
    end
    
endmodule
