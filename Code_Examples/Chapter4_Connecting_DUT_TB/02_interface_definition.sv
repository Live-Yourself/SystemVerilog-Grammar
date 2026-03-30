//============================================================
// 文件名: 02_interface_definition.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 4.2 接口的定义
// 说明: 演示SystemVerilog接口的基本定义和使用方法
//============================================================

// ==================== 接口定义 ====================
// 基本接口：封装一组相关信号
interface simple_bus;
  // 信号声明
  logic        clk;
  logic        rst_n;
  logic [7:0]  addr;
  logic [7:0]  wdata;
  logic [7:0]  rdata;
  logic        write;    // 1=写, 0=读
  logic        valid;
  logic        ready;
endinterface


// ==================== 使用接口的DUT ====================
module interface_dut(simple_bus bus);
  // 内部存储器
  logic [7:0] mem [0:255];
  
  // 使用接口中的信号
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.rdata  <= 8'h00;
      bus.ready  <= 1'b0;
    end
    else if (bus.valid) begin
      if (bus.write) begin
        // 写操作
        mem[bus.addr] <= bus.wdata;
        bus.ready <= 1'b1;
      end
      else begin
        // 读操作
        bus.rdata <= mem[bus.addr];
        bus.ready <= 1'b1;
      end
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule


// ==================== 使用接口的测试平台 ====================
module interface_tb(simple_bus bus);
  
  // 测试激励
  initial begin
    $display("===== 接口使用示例 =====");
    
    // 初始化
    bus.rst_n = 0;
    bus.valid = 0;
    bus.write = 0;
    bus.addr  = 8'h00;
    bus.wdata = 8'h00;
    
    // 复位
    @(posedge bus.clk);
    bus.rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 写操作测试
    repeat(3) begin
      @(posedge bus.clk);
      bus.addr  = $urandom_range(0, 255);
      bus.wdata = $urandom_range(0, 255);
      bus.write = 1;
      bus.valid = 1;
      $display("[%0t] 写操作: addr=0x%02h, data=0x%02h", 
               $time, bus.addr, bus.wdata);
      
      @(posedge bus.clk);
      bus.valid = 0;
      
      wait(bus.ready);
      @(posedge bus.clk);
    end
    
    // 读操作测试
    bus.write = 0;
    repeat(3) begin
      @(posedge bus.clk);
      bus.addr  = $urandom_range(0, 255);
      bus.valid = 1;
      $display("[%0t] 读操作: addr=0x%02h", $time, bus.addr);
      
      wait(bus.ready);
      $display("[%0t] 读结果: data=0x%02h", $time, bus.rdata);
      
      @(posedge bus.clk);
      bus.valid = 0;
    end
    
    $display("===== 测试完成 =====\n");
    $finish;
  end
endmodule


// ==================== 顶层模块 ====================
module top_example1;
  // 实例化接口
  simple_bus bus();
  
  // 时钟生成（在接口外部）
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  // 实例化DUT和TB，共享接口
  interface_dut dut(bus);
  interface_tb  tb(bus);
endmodule


// ==================== 包含方法的高级接口 ====================
// 接口可以包含task和function
interface advanced_bus #(parameter DATA_WIDTH = 8);
  logic                      clk;
  logic                      rst_n;
  logic [DATA_WIDTH-1:0]     addr;
  logic [DATA_WIDTH-1:0]     wdata;
  logic [DATA_WIDTH-1:0]     rdata;
  logic                      write;
  logic                      valid;
  logic                      ready;
  
  // 接口中的任务：写操作
  task write_data(input [DATA_WIDTH-1:0] addr_val, 
                  input [DATA_WIDTH-1:0] data_val);
    @(posedge clk);
    addr  = addr_val;
    wdata = data_val;
    write = 1;
    valid = 1;
    @(posedge clk);
    valid = 0;
    wait(ready);
    @(posedge clk);
  endtask
  
  // 接口中的任务：读操作
  task read_data(input [DATA_WIDTH-1:0] addr_val, 
                 output [DATA_WIDTH-1:0] data_val);
    @(posedge clk);
    addr = addr_val;
    write = 0;
    valid = 1;
    wait(ready);
    data_val = rdata;
    @(posedge clk);
    valid = 0;
  endtask
  
  // 接口中的函数：检查复位状态
  function bit is_reset();
    return !rst_n;
  endfunction
  
endinterface


// ==================== 使用高级接口的DUT ====================
module advanced_dut(advanced_bus bus);
  logic [7:0] mem [0:255];
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.rdata <= 8'h00;
      bus.ready <= 1'b0;
    end
    else if (bus.valid) begin
      if (bus.write)
        mem[bus.addr] <= bus.wdata;
      else
        bus.rdata <= mem[bus.addr];
      bus.ready <= 1'b1;
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule


// ==================== 使用高级接口的测试平台 ====================
module advanced_tb(advanced_bus bus);
  
  initial begin
    $display("===== 高级接口示例（包含方法） =====");
    
    bus.rst_n = 0;
    #20 bus.rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 使用接口中的任务进行写操作
    bus.write_data(8'h10, 8'hAA);
    $display("[%0t] 通过接口任务写入: addr=0x10, data=0xAA", $time);
    
    bus.write_data(8'h20, 8'hBB);
    $display("[%0t] 通过接口任务写入: addr=0x20, data=0xBB", $time);
    
    // 使用接口中的任务进行读操作
    begin
      logic [7:0] rd_data;
      bus.read_data(8'h10, rd_data);
      $display("[%0t] 通过接口任务读取: addr=0x10, data=0x%02h", $time, rd_data);
    end
    
    // 使用接口中的函数
    if (!bus.is_reset())
      $display("[%0t] 系统正常运行中", $time);
    
    $display("===== 测试完成 =====\n");
    $finish;
  end
endmodule


// ==================== 高级接口顶层模块 ====================
module top_example2;
  advanced_bus #(.DATA_WIDTH(8)) bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  advanced_dut dut(bus);
  advanced_tb  tb(bus);
endmodule


// ==================== 包含时钟生成的接口 ====================
// 接口可以包含initial块生成时钟
interface self_clocked_bus;
  logic        clk;
  logic        rst_n;
  logic [7:0]  data;
  logic        valid;
  logic        ready;
  
  // 接口内部生成时钟
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 接口内部的复位任务
  task reset();
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
  endtask
endinterface


// ==================== 传统连接方式对比 ====================
// 传统方式：每个信号单独连接
module traditional_dut(
  input  logic       clk,
  input  logic       rst_n,
  input  logic [7:0] data_in,
  input  logic       valid_in,
  output logic [7:0] data_out,
  output logic       ready_out
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out  <= 8'h00;
      ready_out <= 1'b0;
    end
    else if (valid_in) begin
      data_out  <= data_in;
      ready_out <= 1'b1;
    end
    else begin
      ready_out <= 1'b0;
    end
  end
endmodule

// 传统方式的顶层连接 - 繁琐
module top_traditional;
  logic       clk;
  logic       rst_n;
  logic [7:0] data_in;
  logic       valid_in;
  logic [7:0] data_out;
  logic       ready_out;
  
  // 每个信号都要单独连接！
  traditional_dut dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .ready_out(ready_out)
  );
  
  initial begin
    clk = 0; forever #5 clk = ~clk; end
  initial begin
    $display("传统连接方式需要逐个连接信号");
    $finish;
  end
endmodule

// 接口方式 - 简洁
interface compact_if;
  logic clk, rst_n;
  logic [7:0] data;
  logic valid, ready;
endinterface

module compact_dut(compact_if bus);
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.data  <= 8'h00;
      bus.ready <= 1'b0;
    end
    else if (bus.valid) begin
      bus.ready <= 1'b1;
    end
  end
endmodule

module top_interface;
  compact_if bus();  // 一个接口替代多个信号！
  
  initial begin bus.clk = 0; forever #5 bus.clk = ~bus.clk; end
  compact_dut dut(bus);  // 只需连接一个接口
  
  initial begin
    $display("接口连接方式只需连接一个接口实例");
    $finish;
  end
endmodule


// ==================== 参数化接口 ====================
// 接口可以使用参数
interface param_bus #(parameter WIDTH = 8, DEPTH = 16);
  logic                      clk;
  logic                      rst_n;
  logic [WIDTH-1:0]          data;
  logic [$clog2(DEPTH)-1:0]  addr;
  logic                      valid;
  logic                      ready;
endinterface

module top_parameterized;
  // 不同参数的接口实例
  param_bus #(.WIDTH(8),  .DEPTH(16)) bus8();   // 8位数据宽度
  param_bus #(.WIDTH(16), .DEPTH(32)) bus16();  // 16位数据宽度
  param_bus #(.WIDTH(32), .DEPTH(64)) bus32();  // 32位数据宽度
  
  initial begin
    $display("参数化接口可以创建不同配置的总线");
    $display("  bus8:  WIDTH=8,  DEPTH=16");
    $display("  bus16: WIDTH=16, DEPTH=32");
    $display("  bus32: WIDTH=32, DEPTH=64");
    $finish;
  end
endmodule


// ==================== 仿真配置 ====================
/*
仿真说明:

1. 运行 top_example1:
   - 演示基本接口的使用
   - 接口封装信号并简化连接

2. 运行 top_example2:
   - 演示包含方法的高级接口
   - 接口中的task和function使用

3. 对比传统方式与接口方式:
   - 传统方式需要逐个连接信号
   - 接口方式只需连接一个接口实例

推荐运行顺序:
  top_example1 → top_example2 → top_parameterized
*/
