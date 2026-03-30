//============================================================
// 文件名: 04_clocking_block.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 4.3 时钟块
// 说明: 演示时钟块定义同步信号时序、消除竞争冒险
//============================================================

// ==================== 时钟块基本定义 ====================
interface basic_clocking_if;
  logic        clk;
  logic        rst_n;
  logic [7:0]  data_out;    // DUT输出，TB输入
  logic [7:0]  data_in;     // DUT输入，TB输出
  logic        valid;       // TB驱动
  logic        ready;       // DUT驱动
  
  // ========== 时钟块定义 ==========
  clocking cb @ (posedge clk);
    // 默认时序：输入在时钟沿前采样，输出在时钟沿后驱动
    default input #1step output #1ns;
    
    // 输入信号（从DUT角度是输出，TB采样）
    input  ready, data_out;
    
    // 输出信号（TB驱动，DUT采样）
    output valid, data_in;
    
    // 注意：rst_n不放在时钟块中，是异步信号
  endclocking
  
  // Modport使用时钟块
  modport TEST (clocking cb, output rst_n, clk);
  modport DUT  (input clk, rst_n, data_in, valid, output data_out, ready);
  
endinterface


// ==================== 简单DUT ====================
module simple_dut(basic_clocking_if.DUT bus);
  logic [7:0] data_reg;
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      data_reg    <= 8'h00;
      bus.ready   <= 1'b0;
      bus.data_out <= 8'h00;
    end
    else begin
      if (bus.valid) begin
        data_reg <= bus.data_in;   // 接收数据
        bus.ready <= 1'b1;         // 响应
        $display("[%0t] DUT接收: data=0x%02h", $time, bus.data_in);
      end
      else begin
        bus.ready <= 1'b0;
      end
      bus.data_out <= data_reg;    // 输出最后接收的数据
    end
  end
endmodule


// ==================== 使用时钟块的测试平台 ====================
module clocking_tb(basic_clocking_if.TEST bus);
  
  initial begin
    $display("===== 时钟块基本使用示例 =====");
    $display("时钟块特点:");
    $display("  - 输入信号: 在时钟沿前 #1step 采样");
    $display("  - 输出信号: 在时钟沿后 #1ns 驱动");
    $display("");
    
    // 异步复位（不在时钟块中）
    bus.rst_n = 0;
    
    // 初始化时钟块中的信号
    bus.cb.data_in = 8'h00;
    bus.cb.valid   = 1'b0;
    
    // 等待几个时钟周期
    repeat(3) @(bus.cb);
    
    // 释放复位
    bus.rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 使用时钟块同步发送数据
    repeat(3) begin
      @(bus.cb);  // 等待时钟块同步
      bus.cb.data_in <= $urandom_range(0, 255);  // 非阻塞赋值
      bus.cb.valid   <= 1'b1;
      $display("[%0t] TB发送: data_in=0x%02h", $time, bus.cb.data_in);
      
      // 等待响应（使用时钟块采样）
      @(bus.cb);
      bus.cb.valid <= 1'b0;
      
      // 检查响应（ready是通过时钟块采样的）
      if (bus.cb.ready) begin
        $display("[%0t] TB收到响应: data_out=0x%02h", $time, bus.cb.data_out);
      end
    end
    
    $display("\n===== 测试完成 =====");
    #50 $finish;
  end
endmodule


// ==================== 顶层模块 ====================
module top_clocking_basic;
  basic_clocking_if bus();
  
  // 时钟生成
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;  // 10ns周期
  end
  
  simple_dut   dut(bus);
  clocking_tb  tb (bus);
endmodule


// ==================== 时钟块消除竞争冒险演示 ====================
/*
问题演示：没有时钟块时的竞争冒险

时间线:
      │
  5ns ├── 时钟上升沿
      │
      ├── DUT在此时采样data_in
      │   TB也在此时驱动data_in
      │   → 谁先谁后？不确定！
      │
      └── 竞争冒险！

解决方案：时钟块

时间线:
      │
  4ns ├── TB采样data_out (时钟沿前#1step)
      │
  5ns ├── 时钟上升沿
      │
  6ns ├── TB驱动data_in (时钟沿后#1ns)
      │   DUT在时钟沿采样
      │   → 没有竞争！
      │
      └── 时序确定
*/


// ==================== 详细时序演示 ====================
interface timing_if;
  logic       clk;
  logic [7:0] data;
  logic       valid;
  
  // 带有明确时序的时钟块
  clocking cb @ (posedge clk);
    default input #2ns output #3ns;  // 明确的偏移值
    input  data;    // 时钟沿前2ns采样
    output valid;   // 时钟沿后3ns驱动
  endclocking
  
  modport TB (clocking cb, output clk);
endinterface

module timing_demo(timing_if.TB bus);
  
  initial begin
    $display("\n===== 详细时序演示 =====");
    $display("时钟周期: 10ns (半周期5ns)");
    $display("输入偏移: #2ns (时钟沿前采样)");
    $display("输出偏移: #3ns (时钟沿后驱动)");
    $display("");
    
    // 初始化
    bus.cb.valid = 0;
    
    // 记录详细时序
    repeat(2) begin
      bus.cb.valid <= 1;
      $display("[时间=%0t] 设置valid=1", $time);
      
      @(bus.cb);  // 等待时钟同步
      $display("[时间=%0t] 时钟沿到达", $time);
      $display("[时间=%0t] 采样到data=0x%02h", $time, bus.cb.data);
      
      bus.cb.valid <= 0;
    end
    
    $display("\n===== 演示完成 =====");
    $finish;
  end
endmodule

module top_timing;
  timing_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  // 简单的数据源
  always @(posedge bus.clk) begin
    bus.data <= $urandom_range(0, 255);
  end
  
  timing_demo demo(bus);
endmodule


// ==================== 多时钟域时钟块 ====================
interface multi_clock_if;
  logic clk_a;      // 时钟域A
  logic clk_b;      // 时钟域B
  logic [7:0] data_a;
  logic [7:0] data_b;
  logic       valid_a;
  logic       valid_b;
  
  // 时钟域A的时钟块
  clocking cb_a @ (posedge clk_a);
    default input #1ns output #1ns;
    input  data_b, valid_b;   // 从B域接收
    output data_a, valid_a;   // 发送到B域
  endclocking
  
  // 时钟域B的时钟块
  clocking cb_b @ (posedge clk_b);
    default input #1ns output #1ns;
    input  data_a, valid_a;   // 从A域接收
    output data_b, valid_b;   // 发送到A域
  endclocking
  
  modport DOMAIN_A (clocking cb_a);
  modport DOMAIN_B (clocking cb_b);
endinterface


// ==================== 时钟块与事件 ====================
interface event_clocking_if;
  logic clk;
  logic [7:0] data;
  logic       valid;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  data;
    output valid;
  endclocking
  
  modport TB (clocking cb, output clk);
endinterface

module event_demo(event_clocking_if.TB bus);
  
  initial begin
    $display("\n===== 时钟块事件使用 =====");
    
    bus.cb.valid = 0;
    
    // 方式1: 使用 @(clocking_block)
    $display("方式1: @(bus.cb) - 等待一个时钟周期");
    repeat(3) begin
      @(bus.cb);
      $display("[时间=%0t] 时钟沿到达, data=0x%02h", $time, bus.cb.data);
    end
    
    // 方式2: 使用循环
    $display("\n方式2: 循环中使用");
    bus.cb.valid <= 1;
    repeat(5) @(bus.cb) begin
      $display("[时间=%0t] 循环中, data=0x%02h", $time, bus.cb.data);
    end
    
    $display("\n===== 演示完成 =====");
    $finish;
  end
endmodule

module top_event;
  event_clocking_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  always @(posedge bus.clk) begin
    bus.data <= $urandom_range(0, 255);
  end
  
  event_demo demo(bus);
endmodule


// ==================== 完整的总线接口示例 ====================
// 包含时钟块的完整接口定义
interface complete_bus_if #(parameter DATA_WIDTH = 8);
  logic                       clk;
  logic                       rst_n;
  logic [DATA_WIDTH-1:0]      addr;
  logic [DATA_WIDTH-1:0]      wdata;
  logic [DATA_WIDTH-1:0]      rdata;
  logic                       write;
  logic                       valid;
  logic                       ready;
  
  // 测试平台时钟块
  clocking tb_cb @ (posedge clk);
    default input #1step output #1ns;
    
    // 输入：从DUT采样
    input  rdata, ready;
    
    // 输出：驱动到DUT
    output addr, wdata, write, valid;
  endclocking
  
  // Modport定义
  modport TEST (
    clocking tb_cb,    // 包含时钟块
    output   rst_n     // 异步复位
  );
  
  modport DUT (
    input  clk, rst_n, addr, wdata, write, valid,
    output rdata, ready
  );
  
  modport MONITOR (
    input clk, rst_n, addr, wdata, rdata, write, valid, ready
  );
  
endinterface


// 完整示例的DUT
module complete_dut(complete_bus_if.DUT bus);
  logic [7:0] mem [0:255];
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.rdata <= 8'h00;
      bus.ready <= 1'b0;
    end
    else if (bus.valid) begin
      if (bus.write) begin
        mem[bus.addr] <= bus.wdata;
        $display("[%0t] DUT写入: addr=0x%02h, data=0x%02h", 
                 $time, bus.addr, bus.wdata);
      end
      else begin
        bus.rdata <= mem[bus.addr];
        $display("[%0t] DUT读取: addr=0x%02h, data=0x%02h", 
                 $time, bus.addr, bus.rdata);
      end
      bus.ready <= 1'b1;
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule


// 完整示例的测试平台
module complete_tb(complete_bus_if.TEST bus);
  
  initial begin
    $display("\n===== 完整总线接口示例 =====");
    $display("时钟块同步所有信号传输");
    $display("");
    
    // 异步复位
    bus.rst_n = 0;
    bus.tb_cb.addr  = 8'h00;
    bus.tb_cb.wdata = 8'h00;
    bus.tb_cb.write = 0;
    bus.tb_cb.valid = 0;
    
    // 等待复位
    repeat(3) @(bus.tb_cb);
    bus.rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 写操作序列
    repeat(3) begin
      @(bus.tb_cb);
      bus.tb_cb.addr  <= $urandom_range(0, 15);
      bus.tb_cb.wdata <= $urandom_range(0, 255);
      bus.tb_cb.write <= 1;
      bus.tb_cb.valid <= 1;
      $display("[%0t] TB发起写操作", $time);
      
      // 等待响应
      @(bus.tb_cb);
      bus.tb_cb.valid <= 0;
      
      // 使用时钟块采样的ready信号
      if (bus.tb_cb.ready)
        $display("[%0t] TB确认写完成", $time);
    end
    
    // 读操作序列
    bus.tb_cb.write <= 0;
    repeat(3) begin
      @(bus.tb_cb);
      bus.tb_cb.addr  <= $urandom_range(0, 15);
      bus.tb_cb.valid <= 1;
      $display("[%0t] TB发起读操作", $time);
      
      // 等待响应
      @(bus.tb_cb);
      bus.tb_cb.valid <= 0;
      
      if (bus.tb_cb.ready)
        $display("[%0t] TB收到数据: 0x%02h", $time, bus.tb_cb.rdata);
    end
    
    $display("\n===== 测试完成 =====");
    #20 $finish;
  end
endmodule

// 完整示例顶层
module top_complete;
  complete_bus_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  complete_dut dut(bus);
  complete_tb  tb (bus);
endmodule


// ==================== 仿真配置 ====================
/*
仿真说明:

1. 运行 top_clocking_basic:
   - 演示时钟块基本用法
   - 输入采样和输出驱动的时序

2. 运行 top_timing:
   - 详细演示时序偏移
   - 观察采样和驱动的具体时间点

3. 运行 top_event:
   - 演示时钟块事件的使用
   - @(clocking_block)的用法

4. 运行 top_complete:
   - 完整的总线接口示例
   - 时钟块与modport结合使用

关键要点:
  - 时钟块消除竞争冒险
  - 输入信号在时钟沿前采样
  - 输出信号在时钟沿后驱动
  - 使用 @(clocking_block) 同步
  - 非阻塞赋值驱动输出信号
*/
