//============================================================
// 文件名: 01_separation_design_tb.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 4.1 将测试平台和设计分开
// 说明: 演示设计与测试平台的基本分离方法
//       - logic类型用于单驱动信号
//       - wire类型用于多驱动信号
//============================================================

// ==================== 设计模块(DUT) ====================
// DUT是一个简单的数据通路模块
module simple_dut(
  input  logic       clk,        // 时钟信号
  input  logic       rst_n,      // 异步复位，低有效
  input  logic [7:0] data_in,    // 输入数据
  input  logic       valid_in,   // 输入有效信号
  output logic [7:0] data_out,   // 输出数据
  output logic       valid_out   // 输出有效信号
);

  // DUT内部逻辑：简单的寄存器传递
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out  <= 8'h00;
      valid_out <= 1'b0;
    end
    else if (valid_in) begin
      data_out  <= data_in;   // 传递输入数据
      valid_out <= 1'b1;      // 指示输出有效
    end
    else begin
      valid_out <= 1'b0;
    end
  end

endmodule


// ==================== 传统Verilog风格的测试平台 ====================
// 问题: 端口连接繁琐，容易出错
module traditional_tb;
  // 信号声明 - 使用logic因为只有测试平台驱动
  logic       clk;
  logic       rst_n;
  logic [7:0] data_in;
  logic       valid_in;
  // 使用wire连接DUT输出（虽然只有单驱动，但演示wire用法）
  wire [7:0] data_out;
  wire       valid_out;

  // DUT实例化 - 端口连接繁琐
  simple_dut dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
  );

  // 时钟生成 - 10ns周期
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 测试激励
  initial begin
    $display("===== 传统Verilog风格测试平台 =====");
    
    // 复位序列
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;
    #20 rst_n = 1;
    
    // 测试用例1: 发送数据0xA5
    @(posedge clk);
    data_in = 8'hA5;
    valid_in = 1;
    $display("[%0t] 发送数据: 0x%02h", $time, data_in);
    
    // 测试用例2: 发送数据0x3C
    @(posedge clk);
    data_in = 8'h3C;
    $display("[%0t] 发送数据: 0x%02h", $time, data_in);
    
    // 等待输出
    @(posedge clk);
    valid_in = 0;
    
    repeat(2) @(posedge clk);
    $display("[%0t] 最后输出: data_out=0x%02h, valid_out=%b", 
             $time, data_out, valid_out);
    
    $display("===== 测试完成 =====\n");
    $finish;
  end

endmodule


// ==================== logic与wire的区别演示 ====================
module logic_vs_wire_demo;

  // logic类型 - 只能有一个驱动源
  logic [7:0] single_driver_sig;
  
  // wire类型 - 可以有多个驱动源
  wire [7:0] multi_driver_sig;
  
  // 演示logic的正确用法：单一驱动
  initial begin
    single_driver_sig = 8'hAA;  // OK: logic在过程块中赋值
    $display("[%0t] logic信号赋值: 0x%02h", $time, single_driver_sig);
  end

  // 演示wire的正确用法：连续赋值
  assign multi_driver_sig = single_driver_sig;  // OK: wire使用连续赋值
  
  // 注意: 如果尝试在多个地方驱动logic，会产生X态
  // 以下代码会产生多驱动错误（已注释）:
  // assign single_driver_sig = 8'h55;  // 错误！logic不能有多个驱动

endmodule


// ==================== 多驱动场景演示 ====================
// 展示何时需要使用wire
module multi_driver_example;
  logic clk;
  wire [7:0] shared_bus;  // 共享总线，需要wire
  logic [7:0] master1_data;
  logic [7:0] master2_data;
  logic master1_en;
  logic master2_en;

  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 主设备1驱动总线
  assign shared_bus = master1_en ? master1_data : 8'hZZ;
  
  // 主设备2驱动总线
  assign shared_bus = master2_en ? master2_data : 8'hZZ;

  initial begin
    $display("===== 多驱动场景演示 =====");
    
    master1_data = 8'hAA;
    master2_data = 8'hBB;
    
    // 情况1: 只有主设备1使能
    master1_en = 1;
    master2_en = 0;
    #1;
    $display("[%0t] 主设备1驱动: shared_bus = 0x%02h", $time, shared_bus);
    
    // 情况2: 只有主设备2使能
    master1_en = 0;
    master2_en = 1;
    #1;
    $display("[%0t] 主设备2驱动: shared_bus = 0x%02h", $time, shared_bus);
    
    // 情况3: 两个主设备同时使能（会产生X态，表示冲突）
    master1_en = 1;
    master2_en = 1;
    #1;
    $display("[%0t] 冲突状态: shared_bus = 0x%02h (X表示冲突)", $time, shared_bus);
    
    // 情况4: 无主设备使能
    master1_en = 0;
    master2_en = 0;
    #1;
    $display("[%0t] 无驱动: shared_bus = 0x%02h (高阻态)", $time, shared_bus);
    
    $display("===== 演示完成 =====\n");
    $finish;
  end

endmodule


// ==================== 分离原则的完整示例 ====================
// 展示良好的设计与测试平台分离结构
module top_separation_example;
  
  // ============ 测试平台信号 ============
  logic       tb_clk;
  logic       tb_rst_n;
  logic [7:0] tb_data_in;
  logic       tb_valid_in;
  wire [7:0]  tb_data_out;    // DUT输出，使用wire
  wire        tb_valid_out;
  
  // ============ 设计实例 ============
  simple_dut u_dut (
    .clk(tb_clk),
    .rst_n(tb_rst_n),
    .data_in(tb_data_in),
    .valid_in(tb_valid_in),
    .data_out(tb_data_out),
    .valid_out(tb_valid_out)
  );
  
  // ============ 时钟生成 ============
  initial begin
    tb_clk = 0;
    forever #5 tb_clk = ~tb_clk;
  end
  
  // ============ 测试激励 ============
  initial begin
    $display("===== 分离原则完整示例 =====");
    $display("设计(DUT)与测试平台(TB)通过端口连接");
    $display("信号类型选择:");
    $display("  - logic: 单驱动信号(RTL内部、TB激励)");
    $display("  - wire:  多驱动信号(共享总线)、DUT输出连接");
    $display("");
    
    // 初始化
    tb_rst_n = 0;
    tb_data_in = 8'h00;
    tb_valid_in = 0;
    
    // 复位
    #20 tb_rst_n = 1;
    $display("[%0t] 复位释放", $time);
    
    // 发送测试数据
    repeat(3) begin
      @(posedge tb_clk);
      tb_data_in = $urandom_range(0, 255);
      tb_valid_in = 1;
      $display("[%0t] TB发送: data=0x%02h", $time, tb_data_in);
      
      @(posedge tb_clk);
      tb_valid_in = 0;
      
      // 检查输出
      @(posedge tb_clk);
      $display("[%0t] DUT输出: data=0x%02h, valid=%b", 
               $time, tb_data_out, tb_valid_out);
    end
    
    $display("\n===== 测试完成 =====");
    $display("要点总结:");
    $display("  1. 设计和测试平台放在不同模块");
    $display("  2. 使用logic处理单驱动信号");
    $display("  3. 使用wire处理多驱动信号");
    $display("  4. 后续将用接口(interface)简化连接");
    $finish;
  end

endmodule


// ==================== 仿真配置 ====================
// 可以选择运行哪个测试模块
// 在仿真器中选择相应的顶层模块

/*
仿真说明:

1. 运行 traditional_tb:
   - 演示传统Verilog风格的测试平台
   - 展示端口连接的繁琐性

2. 运行 multi_driver_example:
   - 演示多驱动场景
   - 展示wire类型的必要性

3. 运行 top_separation_example:
   - 演示完整的分离原则
   - 展示logic和wire的正确使用

推荐: 运行 top_separation_example 查看完整演示
*/
