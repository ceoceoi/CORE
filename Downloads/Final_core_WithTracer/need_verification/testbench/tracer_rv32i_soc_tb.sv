    // =================================================================== //
    //   This is the example tb for connecting tracer to the riscv core
    // ================================================================== //
//uhiuhg
module tracer_rv32i_soc_tb;
    logic clk;
    logic reset_n;
    logic o_flash_sclk;
    logic o_flash_cs_n;
    logic o_flash_mosi;
    logic i_flash_miso;
    logic o_uart_tx;
    logic i_uart_rx;
    // more signals can be here 
//`define  TRACER_ENABLE=1;
    logic [31:0] rvfi_insn;
    logic [4:0]  rvfi_rs1_addr;
    logic [4:0]  rvfi_rs2_addr;
    logic [31:0] rvfi_rs1_rdata;
    logic [31:0] rvfi_rs2_rdata;
    logic [4:0]  rvfi_rd_addr  ;
    logic [31:0] rvfi_rd_wdata ;
    logic [31:0] rvfi_pc_rdata ;
    logic [31:0] rvfi_pc_wdata ;
    logic [31:0] rvfi_mem_addr ;
    logic [31:0] rvfi_mem_wdata;
    logic [31:0] rvfi_mem_rdata;
    logic        rvfi_valid;
    
    // Clock generator 
    initial clk = 0;
    always #10 clk = ~clk;

    // signal geneartion here
    initial begin 
        reset_n = 0;
        repeat(2) @(negedge clk);
        reset_n = 1; // dropping reset after two clk cycles
    end

    // =================================================== //
    //             Instantiation of the SoC
    // =================================================== //
    // Dut instantiation
    rv32i_soc #(
        .IMEM_DEPTH(10000),
        .DMEM_DEPTH(10000)
       // .NO_OF_GPIO_PINS(NO_OF_GPIO_PINS)
    )DUT(
        //.*
        .clk(clk),
        .reset_n(reset_n),
                //TRACER
//          `ifdef TRACER_ENABLE
.rvfi_insn(rvfi_insn),      
.rvfi_rs1_addr(rvfi_rs1_addr),  
.rvfi_rs2_addr(rvfi_rs2_addr),  
.rvfi_rs1_rdata(rvfi_rs1_rdata), 
.rvfi_rs2_rdata(rvfi_rs2_rdata), 
.rvfi_rd_addr(rvfi_rd_addr),   
.rvfi_rd_wdata(rvfi_rd_wdata),  
.rvfi_pc_rdata(rvfi_pc_rdata),  
.rvfi_pc_wdata(rvfi_pc_wdata),  
.rvfi_mem_addr(rvfi_mem_addr),  
.rvfi_mem_wdata(rvfi_mem_wdata), 
.rvfi_mem_rdata(rvfi_mem_rdata), 
.rvfi_valid(rvfi_valid),      
//        `endif
        
.srx_pad_i(), 
.stx_pad_o(), 
.rts_pad_o(),
.cts_pad_i(), 

.current_pc_out(),  
.inst_out()        
        
    );


    // ============================================================================ //
    //     Example connection of tracer with WB stage signals in the data path
    // ============================================================================ //
//    `ifdef tracer 
        tracer tracer_inst (
        .clk_i(clk),
        .rst_ni(reset_n),
        .hart_id_i(1),
        .rvfi_insn_t(DUT.rv32i_core_inst.data_path_inst.rvfi_insn),
        .rvfi_rs1_addr_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs1_addr),
        .rvfi_rs2_addr_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs2_addr),
        .rvfi_rs3_addr_t(),
        .rvfi_rs3_rdata_t(),
        .rvfi_mem_rmask(),
        .rvfi_mem_wmask(),
        .rvfi_rs1_rdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs1_rdata),
        .rvfi_rs2_rdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs2_rdata),
        .rvfi_rd_addr_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rd_addr),
        .rvfi_rd_wdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rd_wdata),
        .rvfi_pc_rdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_pc_rdata),
        .rvfi_pc_wdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_pc_wdata),
        .rvfi_mem_addr(DUT.rv32i_core_inst.data_path_inst.rvfi_mem_addr),
        .rvfi_mem_wdata(DUT.rv32i_core_inst.data_path_inst.rvfi_mem_wdata),
        .rvfi_mem_rdata(DUT.rv32i_core_inst.data_path_inst.rvfi_mem_rdata),
        .rvfi_valid(DUT.rv32i_core_inst.data_path_inst.rvfi_valid)
        );
//    `endif


    // ============================================================================ //
    //  Logic to Initialize the instruction Memory and Data Memory with .hex files
    // ============================================================================ //


    // ============================================================================ //
    //                        Your Own testbench logic ....
    // ============================================================================ //

// initializing the instruction memory after every reset
logic [31:0] initial_imem [10000]  ;
logic [31:0] initial_dmem [10000]  ;


  initial begin
            
            $readmemh("/home/Reda_Alhashem/git/uart_wb_uvcs/core-verification/need_verification/testbench/inst_formatted.hex", initial_imem);
            $readmemh("/home/Reda_Alhashem/git/uart_wb_uvcs/core-verification/need_verification/testbench/data_formatted.hex", initial_dmem);

		force DUT.inst_mem_inst.dmem = initial_imem;
                force DUT.data_mem_inst.dmem = initial_dmem;
		#1; 
		release DUT.inst_mem_inst.dmem;
		release DUT.data_mem_inst.dmem;
    // $readmemh("/home/it/Documents/RVSOC-FreeRTOS-Kernel-DEMO/instr_formatted.hex",DUT.inst_mem_inst.dmem); // VIVADO
    // $readmemh("/home/it/Documents/RVSOC-FreeRTOS-Kernel-DEMO/data_formatted.hex",DUT.data_mem_inst.dmem); // VIVADO

    repeat(10000) begin 
        @(posedge clk);
    end

    
    $finish;
 
  end  // wait


  // enable waveform dump
  initial begin 
    $dumpfile("waveform.vcd");
    $dumpvars(0);
  end


endmodule

