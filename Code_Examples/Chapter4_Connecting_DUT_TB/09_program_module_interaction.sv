//=============================================================================
// 文件名: 09_program_module_interaction.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 9. 程序与模块的交互
// 说明: 演示程序块与设计模块之间的交互方式
//=============================================================================

//-----------------------------------------------------------------------------
// 示例1: 直接信号连接方式
//-----------------------------------------------------------------------------
// 设计模块(DUT)
module simple_counter (
  input  logic       clk,
  input  logic       rst_n,
  output logic [7:0] count
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      count <= 8'h00;
    else
      count <= count + 1;
  end
endmodule

// 程序块(测试平台) - 直接端口连接
program simple_counter_tb (
  input  logic       clk,
  output logic       rst_n,
  input  logic [7:0] count
);
  initial begin
    $display("\n=== 示例1: 直接信号连接 ===");
    
    // 驱动复位信号
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    // 采样并显示计数器值
    repeat(5) begin
      @(posedge clk);
      // 此时count已经是DUT更新后的稳定值
      $display("[%0t] count = %0d", $time, count);
    end
    
    $display("示例1完成\n");
    $finish;
  end
endprogram

// 顶层模块
module example1_top;
  logic       clk;
  logic       rst_n;
  logic [7:0] count;
  
  // 时钟生成（必须在module中）
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 实例化DUT和测试平台
  simple_counter     dut (clk, rst_n, count);
  simple_counter_tb  tb  (clk, rst_n, count);
endmodule

//-----------------------------------------------------------------------------
// 示例2: 通过接口连接（推荐方式）
//-----------------------------------------------------------------------------
// 接口定义
interface counter_if;
  logic        clk;
  logic        rst_n;
  logic [7:0]  count;
  
  // 时钟块 - 同步接口
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  count;       // 采样DUT输出
    output rst_n;       // 驱动DUT输入
  endclocking
  
  // modport定义
  modport DUT (input clk, rst_n, output count);
  modport TB  (clocking cb);         // 测试平台使用时钟块
  modport TB_ASYNC (output rst_n, input count);  // 异步方式
endinterface

// 设计模块
module counter_with_if (counter_if.DUT bus);
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n)
      bus.count <= 8'h00;
    else
      bus.count <= bus.count + 1;
  end
endmodule

// 程序块 - 使用接口和时钟块
program counter_if_tb (counter_if.TB bus);
  initial begin
    $display("\n=== 示例2: 通过接口连接 ===");
    
    // 使用时钟块驱动和采样
    bus.cb.rst_n <= 0;
    repeat(2) @(bus.cb);
    bus.cb.rst_n <= 1;
    
    // 监控计数器
    repeat(5) begin
      @(bus.cb);
      $display("[%0t] count = %0d", $time, bus.cb.count);
    end
    
    $display("示例2完成\n");
    $finish;
  end
endprogram

// 顶层模块
module example2_top;
  counter_if bus();
  
  // 时钟生成
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  // 实例化
  counter_with_if  dut (bus);
  counter_if_tb    tb  (bus);
endmodule

//-----------------------------------------------------------------------------
// 示例3: 程序块的执行顺序演示
//-----------------------------------------------------------------------------
// 设计模块 - 带输出更新的DUT
module order_test_dut (
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  output logic [7:0] data_out
);
  logic [7:0] internal_data;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      internal_data <= 8'h00;
      data_out      <= 8'h00;
    end
    else if (enable) begin
      internal_data <= internal_data + 1;
      data_out      <= internal_data;  // 注意：使用旧值
    end
  end
endmodule

// 程序块 - 观察执行顺序
program order_test_tb (
  input  logic       clk,
  output logic       rst_n,
  output logic       enable,
  input  logic [7:0] data_out
);
  initial begin
    $display("\n=== 示例3: 执行顺序演示 ===");
    $display("说明：程序块在Reactive区域执行，DUT在Active区域执行");
    $display("因此程序块采样时，DUT已经更新完毕\n");
    
    rst_n  = 0;
    enable = 0;
    
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    enable = 1;
    
    repeat(5) begin
      @(posedge clk);
      $display("[%0t] data_out = %0d (DUT已更新，采样稳定值)", 
               $time, data_out);
    end
    
    $display("\n示例3完成\n");
    $finish;
  end
endprogram

// 顶层
module example3_top;
  logic       clk;
  logic       rst_n;
  logic       enable;
  logic [7:0] data_out;
  
  initial begin clk = 0; forever #5 clk = ~clk; end
  
  order_test_dut dut (clk, rst_n, enable, data_out);
  order_test_tb  tb  (clk, rst_n, enable, data_out);
endmodule

//-----------------------------------------------------------------------------
// 示例4: 程序块的限制演示
//-----------------------------------------------------------------------------
// 设计模块
module limit_test_dut (
  input  logic clk,
  input  logic in,
  output logic out
);
  always_ff @(posedge clk)
    out <= in;
endmodule

// 程序块 - 演示限制
program limit_test_tb (
  input  logic clk,
  output logic in,
  input  logic out
);
  // ❌ 错误示例（编译会失败）：
  // always @(posedge clk) begin
  //   // 程序块中不能使用always！
  // end
  
  // ✓ 正确：使用 initial forever
  initial forever begin
    @(posedge clk);
    // 周期性监控任务
    if (out !== 1'bx)
      $display("[%0t] monitoring: out = %b", $time, out);
  end
  
  initial begin
    $display("\n=== 示例4: 程序块限制演示 ===");
    $display("程序块中不能使用always块");
    $display("替代方案：使用 initial forever\n");
    
    in = 0;
    repeat(2) @(posedge clk);
    
    in = 1;
    repeat(3) @(posedge clk);
    
    in = 0;
    repeat(2) @(posedge clk);
    
    $display("\n示例4完成\n");
    $finish;
  end
endprogram

// 顶层
module example4_top;
  logic clk, in, out;
  
  initial begin clk = 0; forever #5 clk = ~clk; end
  
  limit_test_dut dut (clk, in, out);
  limit_test_tb  tb  (clk, in, out);
endmodule

//-----------------------------------------------------------------------------
// 示例5: 程序块的自动结束机制
//-----------------------------------------------------------------------------
module auto_end_dut (
  input  logic clk,
  output logic [3:0] state
);
  always_ff @(posedge clk) begin
    state <= state + 1;
  end
endmodule

program auto_end_tb (
  input  logic       clk,
  input  logic [3:0] state
);
  // 第一个initial块
  initial begin
    $display("\n=== 示例5: 自动结束机制 ===");
    $display("程序块在所有initial块执行完毕后自动结束\n");
    
    repeat(3) @(posedge clk);
    $display("第一个initial块完成");
  end
  
  // 第二个initial块
  initial begin
    repeat(5) @(posedge clk);
    $display("第二个initial块完成");
    $display("所有initial块完成，程序块将自动结束");
  end
  
  // final块 - 在程序块结束时执行
  final begin
    $display("\n[final] 程序块结束，执行清理工作");
    $display("[final] 最终 state = %0d", state);
    $display("示例5完成\n");
  end
endprogram

module example5_top;
  logic       clk;
  logic [3:0] state;
  
  initial begin clk = 0; forever #5 clk = ~clk; end
  
  auto_end_dut dut (clk, state);
  auto_end_tb  tb  (clk, state);
endmodule

//-----------------------------------------------------------------------------
// 示例6: 完整的交互示例 - FIFO验证
//-----------------------------------------------------------------------------
// FIFO接口
interface fifo_if #(parameter DATA_WIDTH = 8);
  logic                   clk;
  logic                   rst_n;
  logic [DATA_WIDTH-1:0]  wr_data;
  logic                   wr_en;
  logic                   rd_en;
  logic [DATA_WIDTH-1:0]  rd_data;
  logic                   full;
  logic                   empty;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  rd_data, full, empty;
    output wr_data, wr_en, rd_en, rst_n;
  endclocking
  
  modport DUT (input clk, rst_n, wr_data, wr_en, rd_en,
               output rd_data, full, empty);
  modport TB (clocking cb);
endinterface

// FIFO设计模块
module simple_fifo #(parameter DATA_WIDTH = 8, DEPTH = 4) (
  fifo_if.DUT bus
);
  localparam PTR_WIDTH = $clog2(DEPTH);
  
  logic [PTR_WIDTH:0]   wr_ptr, rd_ptr;
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  
  assign bus.full  = (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]) && 
                     (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);
  assign bus.empty = (wr_ptr == rd_ptr);
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      if (bus.wr_en && !bus.full) begin
        mem[wr_ptr[PTR_WIDTH-1:0]] <= bus.wr_data;
        wr_ptr <= wr_ptr + 1;
      end
      if (bus.rd_en && !bus.empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end
  
  assign bus.rd_data = mem[rd_ptr[PTR_WIDTH-1:0]];
endmodule

// FIFO测试程序块
program fifo_test_tb #(parameter DATA_WIDTH = 8) (
  fifo_if.TB bus
);
  int write_count = 0;
  int read_count = 0;
  int error_count = 0;
  
  initial begin
    $display("\n=== 示例6: FIFO验证 ===");
    
    // 复位
    bus.cb.rst_n <= 0;
    bus.cb.wr_en <= 0;
    bus.cb.rd_en <= 0;
    repeat(2) @(bus.cb);
    bus.cb.rst_n <= 1;
    
    $display("复位完成，开始测试...\n");
    
    // 写入测试
    $display("--- 写入测试 ---");
    for (int i = 0; i < 4; i++) begin
      @(bus.cb);
      if (!bus.cb.full) begin
        bus.cb.wr_data <= i * 16;
        bus.cb.wr_en   <= 1;
        write_count++;
        $display("[write] data=%0d, full=%b", i*16, bus.cb.full);
      end
    end
    @(bus.cb);
    bus.cb.wr_en <= 0;
    
    // 读取测试
    $display("\n--- 读取测试 ---");
    for (int i = 0; i < 4; i++) begin
      @(bus.cb);
      if (!bus.cb.empty) begin
        bus.cb.rd_en <= 1;
        read_count++;
        $display("[read] data=%0d, empty=%b", bus.cb.rd_data, bus.cb.empty);
      end
    end
    @(bus.cb);
    bus.cb.rd_en <= 0;
    
    // 满标志测试
    $display("\n--- 满标志测试 ---");
    bus.cb.wr_en <= 1;
    while (!bus.cb.full) begin
      @(bus.cb);
      bus.cb.wr_data <= $random;
    end
    $display("FIFO已满: full=%b", bus.cb.full);
    bus.cb.wr_en <= 0;
    
    // 清空FIFO
    $display("\n--- 清空FIFO ---");
    bus.cb.rd_en <= 1;
    while (!bus.cb.empty) begin
      @(bus.cb);
    end
    bus.cb.rd_en <= 0;
    $display("FIFO已空: empty=%b", bus.cb.empty);
    
    // 测试报告
    $display("\n========== 测试报告 ==========");
    $display("写入次数: %0d", write_count);
    $display("读取次数: %0d", read_count);
    $display("错误数:   %0d", error_count);
    $display("==============================\n");
    
    $display("示例6完成\n");
  end
  
  final begin
    $display("[final] FIFO测试结束");
  end
endprogram

// 顶层模块
module example6_top;
  parameter DATA_WIDTH = 8;
  
  fifo_if #(DATA_WIDTH) bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  simple_fifo #(DATA_WIDTH, 4) dut (bus);
  fifo_test_tb #(DATA_WIDTH)   tb  (bus);
endmodule

//-----------------------------------------------------------------------------
// 程序块与模块交互总结
//-----------------------------------------------------------------------------
/*
┌─────────────────────────────────────────────────────────────────────────┐
│                    程序块与模块交互总结                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  执行顺序:                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  时钟沿 → Active(module) → NBA → Reactive(program) → Postponed │   │
│  │                     │                        │                  │   │
│  │               DUT先执行                  测试平台后执行          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  通信方式:                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  方式1: 直接端口连接                                             │   │
│  │         简单，但不推荐大型设计                                    │   │
│  │                                                                  │   │
│  │  方式2: 接口连接 (推荐)                                          │   │
│  │         使用clocking块同步，可重用性好                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  程序块限制:                                                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ✗ 不能使用 always 块      → 用 initial forever 替代            │   │
│  │  ✗ 不能实例化 module        → 在顶层module中实例化               │   │
│  │  ✗ 不能实例化 program       → 在顶层module中实例化               │   │
│  │  ✓ 可以包含 initial/function/task/class/assert                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  最佳实践:                                                              │
│  1. 使用接口和时钟块连接DUT和测试平台                                  │
│  2. 程序块中驱动信号使用非阻塞赋值(<=)                                 │
│  3. 利用Reactive区域特性，确保采样稳定值                               │
│  4. 使用final块执行清理工作                                            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
*/
