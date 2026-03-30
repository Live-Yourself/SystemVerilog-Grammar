//============================================================
// 文件名: 06_drive_sample.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 4.4 接口的驱动和采样
// 说明: 演示接口信号的驱动和采样方法
//============================================================

// ==================== 基本接口定义 ====================
interface basic_io_if;
  logic        clk;
  logic        rst_n;
  logic [7:0]  data_out;  // DUT输出，TB采样
  logic [7:0]  data_in;   // DUT输入，TB驱动
  logic        valid;     // TB驱动
  logic        ready;     // DUT驱动
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  ready, data_out;   // TB采样
    output data_in, valid;    // TB驱动
  endclocking
  
  modport TB (clocking cb, output rst_n);
  modport DUT (input clk, rst_n, data_in, valid, output data_out, ready);
endinterface


// ==================== 简单DUT ====================
module simple_dut(basic_io_if.DUT bus);
  logic [7:0] data_reg;
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      data_reg    <= 8'h00;
      bus.ready   <= 1'b0;
      bus.data_out <= 8'h00;
    end
    else begin
      if (bus.valid) begin
        data_reg <= bus.data_in;
        bus.ready <= 1'b1;
      end
      else begin
        bus.ready <= 1'b0;
      end
      bus.data_out <= data_reg;
    end
  end
endmodule


// ==================== 同步驱动示例 ====================
module sync_drive_example(basic_io_if.TB bus);
  
  initial begin
    $display("===== 同步驱动示例 =====");
    $display("使用时钟块(cb)进行同步驱动");
    $display("");
    
    // 异步信号直接驱动
    bus.rst_n = 0;
    
    // 同步信号初始化
    bus.cb.data_in <= 8'h00;
    bus.cb.valid   <= 1'b0;
    
    // 等待并释放复位
    repeat(2) @(bus.cb);
    bus.rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 同步驱动数据
    repeat(3) begin
      @(bus.cb);
      bus.cb.data_in <= $urandom_range(0, 255);  // 非阻塞赋值
      bus.cb.valid   <= 1;
      $display("[%0t] 驱动: data_in = 0x%02h", $time, bus.cb.data_in);
      
      // 采样响应
      @(bus.cb);
      bus.cb.valid <= 0;
      
      if (bus.cb.ready) begin
        $display("[%0t] 采样: data_out = 0x%02h", $time, bus.cb.data_out);
      end
    end
    
    $display("\n===== 示例完成 =====");
    #20 $finish;
  end
endmodule


// ==================== 顶层模块 ====================
module top_sync_drive;
  basic_io_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  simple_dut        dut(bus);
  sync_drive_example tb (bus);
endmodule


// ==================== 驱动方式对比示例 ====================
interface drive_compare_if;
  logic       clk;
  logic [7:0] sig_sync;   // 同步驱动
  logic [7:0] sig_async;  // 异步驱动
  logic       rst_n;
  
  clocking cb @ (posedge clk);
    output sig_sync;
  endclocking
  
  modport TB (clocking cb, output sig_async, rst_n);
endinterface

module drive_compare(drive_compare_if.TB bus);
  
  initial begin
    $display("\n===== 驱动方式对比 =====");
    
    bus.rst_n = 0;
    bus.sig_async = 8'h00;
    bus.cb.sig_sync <= 8'h00;
    
    repeat(2) @(bus.cb);
    bus.rst_n = 1;
    
    // 同步驱动 vs 异步驱动
    repeat(5) begin
      logic [7:0] test_val = $urandom_range(0, 255);
      
      // 方式1: 同步驱动（使用时钟块）
      bus.cb.sig_sync <= test_val;
      
      // 方式2: 异步驱动（直接赋值）
      bus.sig_async = test_val;
      
      $display("[%0t] 同步: 0x%02h, 异步: 0x%02h", 
               $time, bus.sig_sync, bus.sig_async);
      
      @(bus.cb);
    end
    
    $display("\n===== 对比完成 =====");
    $finish;
  end
endmodule

module top_drive_compare;
  drive_compare_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  drive_compare demo(bus);
endmodule


// ==================== 双向信号示例 ====================
interface bidir_if;
  logic       clk;
  logic       rst_n;
  wire [7:0]  data;     // 双向数据总线
  logic       oe;       // 输出使能
  logic       dir;      // 方向: 1=写, 0=读
  
  clocking cb @ (posedge clk);
    inout data;         // 双向信号
    output oe, dir;
  endclocking
  
  modport TB (clocking cb, output rst_n);
  modport DUT (input clk, rst_n, inout data, input oe, dir);
endinterface


// 双向DUT
module bidir_dut(bidir_if.DUT bus);
  logic [7:0] internal_data = 8'hAA;
  
  // DUT侧驱动逻辑
  assign bus.data = (bus.dir == 0 && bus.oe) ? internal_data : 8'hZZ;
  
  // DUT侧接收逻辑
  always @(posedge bus.clk) begin
    if (bus.dir == 1 && bus.oe) begin
      internal_data <= bus.data;
    end
  end
endmodule


// 双向驱动测试
module bidir_tb(bidir_if.TB bus);
  logic [7:0] read_data;
  
  initial begin
    $display("\n===== 双向信号示例 =====");
    
    bus.rst_n = 0;
    bus.cb.oe <= 0;
    bus.cb.dir <= 0;
    
    repeat(2) @(bus.cb);
    bus.rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 写操作: TB驱动数据
    $display("\n--- 写操作 ---");
    bus.cb.dir <= 1;          // 方向: TB→DUT
    bus.cb.oe  <= 1;
    bus.cb.data <= 8'h55;     // TB驱动数据
    @(bus.cb);
    $display("[%0t] TB写入: 0x55", $time);
    bus.cb.oe <= 0;
    
    // 读操作: DUT驱动数据
    $display("\n--- 读操作 ---");
    bus.cb.dir <= 0;          // 方向: DUT→TB
    bus.cb.oe  <= 1;
    @(bus.cb);
    read_data = bus.cb.data;  // TB采样数据
    $display("[%0t] TB读取: 0x%02h", $time, read_data);
    bus.cb.oe <= 0;
    
    $display("\n===== 双向示例完成 =====");
    #20 $finish;
  end
endmodule

module top_bidir;
  bidir_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  bidir_dut dut(bus);
  bidir_tb  tb (bus);
endmodule


// ==================== 握手机制示例 ====================
interface handshake_if;
  logic       clk;
  logic       rst_n;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  ready;
    output data, valid;
  endclocking
  
  modport TB (clocking cb, output rst_n);
  modport DUT (input clk, rst_n, data, valid, output ready);
endinterface


// 握手DUT
module handshake_dut(handshake_if.DUT bus);
  logic [7:0] received_data;
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.ready <= 1'b0;
      received_data <= 8'h00;
    end
    else if (bus.valid && !bus.ready) begin
      received_data <= bus.data;
      bus.ready <= 1'b1;
      $display("[DUT] 收到数据: 0x%02h", bus.data);
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule


// 握手测试
module handshake_tb(handshake_if.TB bus);
  
  // 握手发送任务
  task send_with_handshake(input logic [7:0] data);
    $display("[TB] 发送数据: 0x%02h", data);
    
    // 驱动数据和valid
    bus.cb.data  <= data;
    bus.cb.valid <= 1;
    
    // 等待ready响应
    while (!bus.cb.ready) begin
      @(bus.cb);
    end
    
    $display("[TB] 收到ready响应");
    
    // 撤销valid
    bus.cb.valid <= 0;
    @(bus.cb);
  endtask
  
  initial begin
    $display("\n===== 握手机制示例 =====");
    
    bus.rst_n = 0;
    bus.cb.valid <= 0;
    bus.cb.data <= 0;
    
    repeat(2) @(bus.cb);
    bus.rst_n = 1;
    
    // 发送多个数据
    send_with_handshake(8'hAA);
    send_with_handshake(8'hBB);
    send_with_handshake(8'hCC);
    
    $display("\n===== 握手示例完成 =====");
    #20 $finish;
  end
endmodule

module top_handshake;
  handshake_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  handshake_dut dut(bus);
  handshake_tb  tb (bus);
endmodule


// ==================== 超时处理示例 ====================
interface timeout_if;
  logic       clk;
  logic       rst_n;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  ready;
    output data, valid;
  endclocking
  
  modport TB (clocking cb, output rst_n);
  modport DUT (input clk, rst_n, data, valid, output ready);
endinterface

module timeout_dut(timeout_if.DUT bus);
  int response_delay;
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.ready <= 1'b0;
    end
    else if (bus.valid) begin
      // 随机响应延迟
      response_delay = $urandom_range(1, 20);
      repeat(response_delay) @(posedge bus.clk);
      bus.ready <= 1'b1;
      @(posedge bus.clk);
      bus.ready <= 1'b0;
    end
  end
endmodule

module timeout_tb(timeout_if.TB bus);
  
  // 带超时的发送任务
  task send_with_timeout(input logic [7:0] data, input int timeout_cycles);
    bit success;
    
    $display("[TB] 发送数据: 0x%02h, 超时=%0d周期", data, timeout_cycles);
    
    bus.cb.data  <= data;
    bus.cb.valid <= 1;
    
    success = 0;
    fork
      begin
        // 等待ready
        while (!bus.cb.ready) @(bus.cb);
        success = 1;
        $display("[TB] 收到响应");
      end
      begin
        // 超时计数
        repeat(timeout_cycles) @(bus.cb);
        if (!success) begin
          $display("[TB] 超时! 未收到响应");
        end
      end
    join_any
    
    disable fork;
    bus.cb.valid <= 0;
    @(bus.cb);
  endtask
  
  initial begin
    $display("\n===== 超时处理示例 =====");
    
    bus.rst_n = 0;
    bus.cb.valid <= 0;
    
    repeat(2) @(bus.cb);
    bus.rst_n = 1;
    
    // 测试超时场景
    send_with_timeout(8'h11, 5);   // 可能超时
    send_with_timeout(8'h22, 25);  // 应该成功
    
    $display("\n===== 超时示例完成 =====");
    #20 $finish;
  end
endmodule

module top_timeout;
  timeout_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  timeout_dut dut(bus);
  timeout_tb  tb (bus);
endmodule


// ==================== 突发传输示例 ====================
interface burst_if;
  logic       clk;
  logic       rst_n;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  ready;
    output data, valid;
  endclocking
  
  modport TB (clocking cb, output rst_n);
  modport DUT (input clk, rst_n, data, valid, output ready);
endinterface

module burst_dut(burst_if.DUT bus);
  int count = 0;
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.ready <= 1'b0;
      count <= 0;
    end
    else if (bus.valid) begin
      count++;
      $display("[DUT] 收到第%0d个数据: 0x%02h", count, bus.data);
      bus.ready <= 1'b1;
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule

module burst_tb(burst_if.TB bus);
  
  // 突发写任务
  task burst_write(input logic [7:0] data_array[], input int count);
    $display("[TB] 开始突发传输，共%0d个数据", count);
    
    foreach (data_array[i]) begin
      bus.cb.data  <= data_array[i];
      bus.cb.valid <= 1;
      @(bus.cb);
    end
    
    bus.cb.valid <= 0;
    $display("[TB] 突发传输完成");
  endtask
  
  initial begin
    logic [7:0] test_data [8];
    
    $display("\n===== 突发传输示例 =====");
    
    bus.rst_n = 0;
    bus.cb.valid <= 0;
    
    repeat(2) @(bus.cb);
    bus.rst_n = 1;
    
    // 准备测试数据
    foreach (test_data[i])
      test_data[i] = $urandom_range(0, 255);
    
    // 执行突发传输
    burst_write(test_data, 8);
    
    $display("\n===== 突发示例完成 =====");
    #20 $finish;
  end
endmodule

module top_burst;
  burst_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  burst_dut dut(bus);
  burst_tb  tb (bus);
endmodule


// ==================== 仿真配置 ====================
/*
仿真说明:

1. 运行 top_sync_drive:
   - 演示基本的同步驱动和采样
   - 时钟块的使用

2. 运行 top_drive_compare:
   - 对比同步驱动和异步驱动
   - 观察时序差异

3. 运行 top_bidir:
   - 双向信号处理
   - inout类型信号的使用

4. 运行 top_handshake:
   - 握手机制实现
   - valid/ready协议

5. 运行 top_timeout:
   - 超时处理机制
   - fork...join_any应用

6. 运行 top_burst:
   - 突发传输模式
   - 连续数据传输

关键要点:
  - 同步驱动使用时钟块(cb)和非阻塞赋值(<=)
  - 异步信号直接赋值
  - 双向信号使用wire和inout
  - 握手协议保证可靠传输
  - 超时处理提高健壮性
*/
