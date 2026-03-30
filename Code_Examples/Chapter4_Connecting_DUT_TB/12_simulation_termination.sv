//============================================================================
// 文件名: 12_simulation_termination.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 仿真的结束
// 描述: 演示$finish、$stop、program自动结束、final块的使用方法
//============================================================================

`timescale 1ns/1ps

//============================================================================
// 示例1: $finish 与 $stop 的区别
//============================================================================

module finish_vs_stop;
  logic clk;
  int counter = 0;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $display("\n========== 示例1: \$finish vs \$stop ==========");
    $display("\$finish - 结束仿真，返回操作系统");
    $display("\$stop   - 暂停仿真，进入交互模式（调试用）");
    $display("");
    
    repeat(5) begin
      @(posedge clk);
      counter++;
      $display("[%0t] counter = %0d", $time, counter);
    end
    
    $display("\n测试完成，使用 \$finish 结束仿真");
    $finish;
    
    // $stop;  // 如果用 $stop，仿真会暂停，可以继续
  end
endmodule


//============================================================================
// 示例2: program块的自动结束机制
//============================================================================

program auto_terminate_program (
  input  logic clk,
  output logic rst_n,
  output logic [7:0] data_out
);
  int test_count = 0;
  
  initial begin
    $display("\n========== 示例2: program自动结束 ==========");
    $display("program块中所有initial执行完后自动结束");
    $display("");
    
    // 初始化
    rst_n = 0;
    data_out = 8'h00;
    
    repeat(2) @(posedge clk);
    rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 发送测试数据
    repeat(5) begin
      @(posedge clk);
      data_out <= $random;
      test_count++;
      $display("[%0t] 发送数据: 0x%02h (测试 #%0d)", $time, data_out, test_count);
    end
    
    $display("\n所有initial块执行完毕，program将自动结束");
    // 注意：这里没有显式调用 $finish
    // program会自动结束
  end
  
  // final块在仿真结束前执行
  final begin
    $display("\n--- final块执行 ---");
    $display("仿真即将结束");
    $display("总测试数: %0d", test_count);
  end
endprogram

module top_program_auto;
  logic clk;
  logic rst_n;
  logic [7:0] data_out;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  auto_terminate_program tb (clk, rst_n, data_out);
  
  // 监控
  initial begin
    @tb.test_count;  // 等待测试开始
    forever begin
      @(posedge clk);
      $display("[Monitor] rst_n=%b, data=0x%02h", rst_n, data_out);
    end
  end
endmodule


//============================================================================
// 示例3: final块的使用
//============================================================================

module final_block_example;
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;
  int fd;
  
  task run_single_test(input int test_id, input logic pass);
    test_count++;
    if (pass) begin
      pass_count++;
      $display("[Test %0d] PASS", test_id);
    end else begin
      fail_count++;
      $display("[Test %0d] FAIL", test_id);
    end
  endtask
  
  initial begin
    $display("\n========== 示例3: final块的使用 ==========");
    
    // 打开报告文件
    fd = $fopen("test_report.txt", "w");
    if (!fd) begin
      $error("无法打开报告文件");
      $finish;
    end
    
    $fwrite(fd, "========== 测试报告 ==========\n");
    $fwrite(fd, "开始时间: %0t\n\n", $time);
    
    // 执行测试
    repeat(10) begin
      #1;
      run_single_test(test_count, ($urandom % 10) > 2);  // 80%通过率
    end
    
    // 测试完成
    $display("\n测试执行完毕");
    $finish;
  end
  
  // final块：仿真结束前自动执行
  final begin
    real pass_rate;
    pass_rate = real'(pass_count) / test_count * 100;
    
    $display("\n========== final块执行 ==========");
    $display("仿真即将结束，生成测试报告...");
    $display("");
    $display("========== 测试统计 ==========");
    $display("总测试数: %0d", test_count);
    $display("通过数:   %0d", pass_count);
    $display("失败数:   %0d", fail_count);
    $display("通过率:   %.2f%%", pass_rate);
    $display("==============================");
    
    // 写入文件
    $fwrite(fd, "\n========== 测试统计 ==========\n");
    $fwrite(fd, "总测试数: %0d\n", test_count);
    $fwrite(fd, "通过数:   %0d\n", pass_count);
    $fwrite(fd, "失败数:   %0d\n", fail_count);
    $fwrite(fd, "通过率:   %.2f%%\n", pass_rate);
    $fwrite(fd, "==============================\n");
    $fwrite(fd, "结束时间: %0t\n", $time);
    
    $fclose(fd);
    $display("\n报告已写入 test_report.txt");
  end
endmodule


//============================================================================
// 示例4: 超时保护机制
//============================================================================

module timeout_protection;
  parameter TIMEOUT = 100;  // 100ns超时
  
  logic clk;
  int counter = 0;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 正常测试任务
  task run_test();
    $display("\n========== 示例4: 超时保护机制 ==========");
    $display("超时设置: %0t", TIMEOUT);
    $display("");
    
    repeat(10) begin
      @(posedge clk);
      counter++;
      $display("[%0t] 执行测试步骤 %0d", $time, counter);
      #10;  // 每步延迟10ns
    end
    
    $display("\n测试正常完成");
  endtask
  
  initial begin
    fork
      // 正常测试流程
      run_test();
      
      // 超时保护
      begin
        #TIMEOUT;
        $error("\n仿真超时！超过 %0t 未结束", TIMEOUT);
        $display("当前计数器值: %0d", counter);
      end
    join_any
    
    disable fork;  // 取消未完成的分支
    $finish;
  end
endmodule


//============================================================================
// 示例5: 基于事件结束
//============================================================================

module event_based_finish;
  logic clk;
  event test_started;
  event test_done;
  int result;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 测试任务
  task automatic run_calculation();
    $display("\n========== 示例5: 基于事件结束 ==========");
    $display("使用事件同步测试结束");
    $display("");
    
    -> test_started;  // 触发开始事件
    
    // 执行计算
    result = 0;
    repeat(5) begin
      @(posedge clk);
      result += 10;
      $display("[%0t] 计算中... result = %0d", $time, result);
    end
    
    -> test_done;  // 触发完成事件
  endtask
  
  // 测试执行者
  initial begin
    run_calculation();
  end
  
  // 测试监控者
  initial begin
    @test_started;
    $display("[Monitor] 测试已开始");
    
    @test_done;
    #20;  // 等待最后的处理
    $display("\n[Monitor] 测试已完成，结果 = %0d", result);
    $finish;
  end
endmodule


//============================================================================
// 示例6: $finish参数详解
//============================================================================

module finish_parameters;
  initial begin
    $display("\n========== 示例6: \$finish参数详解 ==========");
    $display("");
    $display("\$finish(0) 或 \$finish - 正常结束，无额外输出");
    $display("\$finish(1)           - 打印仿真时间和位置");
    $display("\$finish(2)           - 详细诊断信息");
    $display("");
    
    // 执行一些操作
    #10;
    $display("仿真时间: %0t", $time);
    
    // 使用 $finish(1) 带诊断信息结束
    $display("\n使用 \$finish(1) 结束仿真:");
    $finish(1);
  end
endmodule


//============================================================================
// 示例7: 常见问题 - 仿真不结束
//============================================================================

module simulation_hangs;
  logic clk;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $display("\n========== 示例7: 仿真不结束问题 ==========");
    $display("");
    
    #20;
    $display("测试完成");
    
    // 问题：忘记 $finish
    // module中有always块，仿真会一直运行
    
    $finish;  // 解决方案：显式结束
  end
  
  // 这个 always 块会持续运行
  // 如果没有 $finish，仿真永远不会结束
  always @(posedge clk) begin
    // 某些周期性操作
  end
endmodule


//============================================================================
// 示例8: program vs module 结束行为对比
//============================================================================

// module版本 - 需要显式结束
module module_testbench;
  logic clk;
  initial begin clk = 0; forever #5 clk = ~clk; end
  
  initial begin
    $display("\n========== 示例8: module vs program ==========");
    $display("");
    $display("module中的initial:");
    
    #20;
    $display("module测试完成");
    $display("module需要显式 \$finish，否则有always块不会结束");
    
    $finish;
  end
endmodule

// program版本 - 自动结束
program program_testbench;
  initial begin
    $display("program中的initial:");
    
    #20;
    $display("program测试完成");
    $display("program会自动结束，无需显式 \$finish");
    // 不需要 $finish
  end
  
  final begin
    $display("program的final块执行");
  end
endprogram


//============================================================================
// 示例9: 完整的测试平台结束模式
//============================================================================

interface tb_if;
  logic clk;
  logic rst_n;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic       valid;
  logic       ready;
  
  clocking cb @ (posedge clk);
    default input #1step output #1ns;
    output rst_n, data_in, valid;
    input  data_out, ready;
  endclocking
endinterface

// DUT
module simple_dut (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [7:0] data_in,
  input  logic       valid,
  output logic [7:0] data_out,
  output logic       ready
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 8'h00;
      ready    <= 1'b0;
    end else begin
      if (valid) begin
        data_out <= data_in + 1;
        ready    <= 1'b1;
      end else begin
        ready <= 1'b0;
      end
    end
  end
endmodule

// 测试平台 - 完整的结束模式
program complete_testbench (tb_if.TB bus);
  int test_count = 0;
  int pass_count = 0;
  
  // 初始化
  initial begin
    bus.rst_n   <= 0;
    bus.data_in <= 0;
    bus.valid   <= 0;
    
    repeat(2) @(bus.cb);
    bus.rst_n <= 1;
    $display("复位完成");
  end
  
  // 主测试流程
  initial begin
    $display("\n========== 示例9: 完整测试平台结束模式 ==========");
    $display("");
    
    wait(bus.rst_n);  // 等待复位完成
    
    // 运行测试
    repeat(5) begin
      test_count++;
      @(bus.cb);
      bus.data_in <= $random;
      bus.valid   <= 1;
      
      @(bus.cb);
      bus.valid <= 0;
      
      // 等待响应
      while (!bus.ready) @(bus.cb);
      
      // 检查结果
      if (bus.data_out == (bus.data_in + 1)) begin
        pass_count++;
        $display("[Test %0d] PASS: in=0x%02h, out=0x%02h", 
                 test_count, bus.data_in, bus.data_out);
      end else begin
        $display("[Test %0d] FAIL: in=0x%02h, out=0x%02h, expected=0x%02h", 
                 test_count, bus.data_in, bus.data_out, bus.data_in + 1);
      end
    end
    
    $display("\n测试完成");
    // program会自动结束，但也可以显式结束
    $finish;
  end
  
  // final块：生成报告
  final begin
    real pass_rate;
    pass_rate = real'(pass_count) / test_count * 100;
    
    $display("\n========== 测试报告 ==========");
    $display("总测试数: %0d", test_count);
    $display("通过数:   %0d", pass_count);
    $display("通过率:   %.2f%%", pass_rate);
    $display("==============================");
  end
endprogram

// 顶层模块
module top_complete;
  tb_if bus();
  
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  simple_dut u_dut (
    .clk      (bus.clk),
    .rst_n    (bus.rst_n),
    .data_in  (bus.data_in),
    .valid    (bus.valid),
    .data_out (bus.data_out),
    .ready    (bus.ready)
  );
  
  complete_testbench u_tb (bus);
endmodule


//============================================================================
// 主测试入口
//============================================================================

module main;
  initial begin
    $display("============================================================");
    $display("        SystemVerilog 仿真结束机制 示例演示");
    $display("============================================================");
    $display("");
    $display("知识点:");
    $display("  1. \$finish vs \$stop");
    $display("  2. program自动结束");
    $display("  3. final块");
    $display("  4. 超时保护");
    $display("  5. 基于事件结束");
    $display("  6. \$finish参数");
    $display("  7. 常见问题解决");
    $display("  8. module vs program");
    $display("  9. 完整测试平台模式");
    $display("");
    $display("要点:");
    $display("  - 使用program封装测试平台，自动结束");
    $display("  - \$finish结束仿真，\$stop暂停（调试用）");
    $display("  - final块用于清理和报告生成");
    $display("  - 添加超时保护防止死循环");
    $display("============================================================");
    
    $finish;
  end
endmodule
