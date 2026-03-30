//============================================================
// 文件名: 05_program_block.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 4.3 程序块
// 说明: 演示程序块的定义和使用，以及与module的区别
//============================================================

// ==================== 设计模块(DUT) ====================
// 一个简单的计数器
module counter_dut(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       enable,
  output logic [7:0] count,
  output logic       overflow
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= 8'h00;
    end
    else if (enable) begin
      count <= count + 1;
    end
  end

  assign overflow = (count == 8'hFF) && enable;

endmodule


// ==================== 程序块(测试平台) ====================
// 使用program封装测试代码
program automatic counter_tb(
  input  logic       clk,
  output logic       rst_n,
  output logic       enable,
  input  logic [7:0] count,
  input  logic       overflow
);

  // 测试统计
  int pass_count = 0;
  int fail_count = 0;

  // 主测试流程
  initial begin
    $display("===== 程序块测试示例 =====");
    $display("program在Reactive区域执行，避免竞争冒险");
    $display("");

    // 初始化
    rst_n  = 0;
    enable = 0;

    // 复位序列
    repeat(2) @(posedge clk);
    rst_n = 1;
    $display("[%0t] 复位释放", $time);

    // 测试1: 基本计数
    $display("\n--- 测试1: 基本计数 ---");
    enable = 1;
    repeat(5) begin
      @(posedge clk);
      // program在Reactive区域采样，此时count已经稳定
      $display("[%0t] count = %0d", $time, count);
    end
    pass_count++;

    // 测试2: 停止计数
    $display("\n--- 测试2: 停止计数 ---");
    enable = 0;
    repeat(3) begin
      @(posedge clk);
      $display("[%0t] count = %0d (应保持不变)", $time, count);
    end
    pass_count++;

    // 测试3: 溢出检测
    $display("\n--- 测试3: 溢出检测 ---");
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    enable = 1;

    // 等待接近溢出
    repeat(250) @(posedge clk);
    
    // 监控溢出
    fork
      begin
        wait(overflow);
        $display("[%0t] 检测到溢出! count = %0d", $time, count);
        pass_count++;
      end
      begin
        repeat(10) @(posedge clk);
        if (!overflow) begin
          $display("[%0t] 错误: 未检测到溢出", $time);
          fail_count++;
        end
      end
    join

    // 测试结果汇总
    $display("\n===== 测试结果 =====");
    $display("通过: %0d", pass_count);
    $display("失败: %0d", fail_count);

    // 程序块执行完毕后自动$exit
  end

  // final块: 仿真结束前执行
  final begin
    $display("\n[Final块] 仿真结束，执行清理工作");
    $display("Final块在program所有initial执行完毕后运行");
  end

endprogram


// ==================== 顶层模块 ====================
module top_program_example;
  logic       clk;
  logic       rst_n;
  logic       enable;
  logic [7:0] count;
  logic       overflow;

  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 实例化
  counter_dut  dut (clk, rst_n, enable, count, overflow);
  counter_tb   tb  (clk, rst_n, enable, count, overflow);

endmodule


// ==================== module vs program 竞争演示 ====================
// 这个示例展示为什么需要program

// 使用module的测试平台（可能有竞争）
module module_tb(
  input  logic       clk,
  output logic       rst_n,
  input  logic [7:0] count
);

  initial begin
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    repeat(5) @(posedge clk) begin
      // 问题: 在时钟沿同时采样
      // count可能还没更新，也可能已更新
      // 结果不确定！
      $display("[module] [%0t] count = %0d", $time, count);
    end
    
    $finish;
  end

endmodule

// 使用program的测试平台（无竞争）
program program_tb(
  input  logic       clk,
  output logic       rst_n,
  input  logic [7:0] count
);

  initial begin
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    repeat(5) @(posedge clk) begin
      // 程序块在Reactive区域执行
      // DUT已经更新count，结果确定！
      $display("[program] [%0t] count = %0d", $time, count);
    end
    
    $finish;
  end

endprogram


// ==================== program中禁止使用always ====================
program always_example(
  input  logic clk,
  output logic signal
);

  // ❌ 错误: program中不能使用always
  // always @(posedge clk) begin
  //   signal = ~signal;
  // end

  // ✅ 正确: 使用 initial forever
  initial forever begin
    @(posedge clk);
    signal = ~signal;
  end

endprogram


// ==================== 完整的程序块示例 ====================
// 带接口的程序块
interface complete_if;
  logic        clk;
  logic        rst_n;
  logic [7:0]  addr;
  logic [7:0]  wdata;
  logic [7:0]  rdata;
  logic        write;
  logic        valid;
  logic        ready;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    input  rdata, ready;
    output addr, wdata, write, valid;
  endclocking
  
  modport TB (clocking cb, output rst_n);
  modport DUT (input clk, rst_n, addr, wdata, write, valid,
               output rdata, ready);
endinterface


// DUT模块
module memory_dut(complete_if.DUT bus);
  logic [7:0] mem [0:255];
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.rdata <= 8'h00;
      bus.ready <= 1'b0;
    end
    else if (bus.valid) begin
      if (bus.write) begin
        mem[bus.addr] <= bus.wdata;
      end
      else begin
        bus.rdata <= mem[bus.addr];
      end
      bus.ready <= 1'b1;
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule


// 完整的程序块测试平台
program automatic memory_tb(complete_if.TB bus);
  
  // 任务: 写操作
  task write_mem(input logic [7:0] addr, input logic [7:0] data);
    bus.cb.addr  <= addr;
    bus.cb.wdata <= data;
    bus.cb.write <= 1;
    bus.cb.valid <= 1;
    @(bus.cb);
    bus.cb.valid <= 0;
    wait(bus.cb.ready);
    $display("[%0t] 写入: addr=0x%02h, data=0x%02h", $time, addr, data);
  endtask
  
  // 任务: 读操作
  task read_mem(input logic [7:0] addr, output logic [7:0] data);
    bus.cb.addr  <= addr;
    bus.cb.write <= 0;
    bus.cb.valid <= 1;
    @(bus.cb);
    bus.cb.valid <= 0;
    wait(bus.cb.ready);
    data = bus.cb.rdata;
    $display("[%0t] 读取: addr=0x%02h, data=0x%02h", $time, addr, data);
  endtask
  
  // 主测试流程
  initial begin
    logic [7:0] rd_data;
    
    $display("\n===== 完整程序块示例 =====");
    $display("结合接口、时钟块和程序块");
    $display("");
    
    // 复位
    bus.rst_n = 0;
    repeat(3) @(bus.cb);
    bus.rst_n = 1;
    $display("[%0t] 复位完成", $time);
    
    // 初始化信号
    bus.cb.addr  <= 0;
    bus.cb.wdata <= 0;
    bus.cb.write <= 0;
    bus.cb.valid <= 0;
    
    // 写测试
    $display("\n--- 写操作测试 ---");
    write_mem(8'h10, 8'hAA);
    write_mem(8'h20, 8'hBB);
    write_mem(8'h30, 8'hCC);
    
    // 读测试
    $display("\n--- 读操作测试 ---");
    read_mem(8'h10, rd_data);
    read_mem(8'h20, rd_data);
    read_mem(8'h30, rd_data);
    
    $display("\n===== 测试完成 =====");
    #20 $finish;
  end
  
  // 监控进程
  initial forever begin
    @(bus.cb);
    if (bus.cb.ready && bus.cb.valid) begin
      // 可以添加额外的监控逻辑
    end
  end

endprogram


// 完整示例顶层
module top_complete_example;
  complete_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  memory_dut  dut (bus);
  memory_tb   tb  (bus);
endmodule


// ==================== program的final块详解 ====================
program final_example;
  
  int test_count = 0;
  int error_count = 0;
  
  initial begin
    $display("执行测试...");
    repeat(5) begin
      #10;
      test_count++;
      $display("[%0t] 测试 %0d 完成", $time, test_count);
    end
    // initial执行完毕，触发final块
  end
  
  // final块: 仿真结束前自动执行
  final begin
    $display("\n===== Final块执行 =====");
    $display("总测试数: %0d", test_count);
    $display("错误数: %0d", error_count);
    $display("Final块用于清理工作，如:");
    $display("  - 关闭文件");
    $display("  - 输出统计信息");
    $display("  - 释放资源");
  end

endprogram

// Final示例顶层
module top_final_example;
  initial begin
    $display("===== Final块示例 =====");
  end
  
  final_example prog();
endmodule


// ==================== 仿真调度区域演示 ====================
module scheduling_demo;
  logic clk = 0;
  logic [7:0] count = 0;
  
  // 时钟生成
  initial forever #5 clk = ~clk;
  
  // Active区域: module的always块
  always @(posedge clk) begin
    count <= count + 1;
    $display("[Active]   [%0t] module always: count更新为 %0d", 
             $time, count);
  end
  
  // 使用program在Reactive区域执行
  program sched_prog(
    input logic clk_ref,
    input logic [7:0] count_ref
  );
    initial forever begin
      @(posedge clk_ref);
      $display("[Reactive] [%0t] program采样: count = %0d", 
               $time, count_ref);
      $display("");
    end
  endprogram
  
  sched_prog prog(clk, count);
  
  initial begin
    repeat(3) @(posedge clk);
    $finish;
  end
  
endmodule


// ==================== 仿真配置 ====================
/*
仿真说明:

1. 运行 top_program_example:
   - 演示程序块的基本用法
   - 展示final块的执行

2. 运行 top_complete_example:
   - 完整示例：接口+时钟块+程序块
   - 展示验证环境的典型结构

3. 运行 top_final_example:
   - 演示final块的用法
   - 程序块自动结束机制

4. 运行 scheduling_demo:
   - 演示Active区域和Reactive区域的执行顺序
   - 展示为什么program能避免竞争

关键要点:
  - program在Reactive区域执行（DUT之后）
  - program中不能使用always块
  - 使用 initial forever 替代 always
  - 推荐使用 program automatic
  - final块用于清理工作
*/
