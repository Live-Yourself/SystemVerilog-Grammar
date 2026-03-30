//============================================================================
// 文件名: 11_ref_port.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: ref端口
// 描述: 演示ref端口的使用方法，包括值传递与引用传递的区别、
//       ref与interface结合、ref在task/function中的应用
//============================================================================

`timescale 1ns/1ps

//============================================================================
// 示例1: 值传递 vs 引用传递 对比
//============================================================================

// 值传递模块
module value_pass_module (
  input  int value_in,      // 值传递（复制）
  output int value_out      // 值传递（复制）
);
  always_comb begin
    value_out = value_in * 2;
    $display("[value_pass] value_in=%0d, value_out=%0d", value_in, value_out);
  end
endmodule

// 引用传递模块
module ref_pass_module (
  ref int shared_var        // 引用传递（不复制）
);
  always @(posedge $root.top1.clk) begin
    shared_var = shared_var + 1;  // 直接修改外部变量
    $display("[ref_pass] shared_var = %0d", shared_var);
  end
endmodule

module top1;
  int original_value = 10;
  int output_value;
  logic clk;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 值传递示例
  value_pass_module u_value (
    .value_in  (original_value),
    .value_out (output_value)
  );
  
  // 引用传递示例
  int counter = 0;
  ref_pass_module u_ref (counter);
  
  initial begin
    $display("\n========== 示例1: 值传递 vs 引用传递 ==========");
    $display("初始值: original_value=%0d, counter=%0d", original_value, counter);
    
    #5;
    original_value = 20;
    $display("修改original_value为20后，output_value=%0d (值传递，已复制)", output_value);
    
    #20;
    $display("经过ref模块处理后，counter=%0d (引用传递，直接修改)", counter);
    
    #20;
    $display("最终counter=%0d", counter);
    $finish;
  end
endmodule


//============================================================================
// 示例2: ref与interface结合使用
//============================================================================

interface shared_bus_if;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  
  // 使用ref的modport
  modport PRODUCER (
    ref    data,      // 引用传递
    output valid,
    input  ready
  );
  
  modport CONSUMER (
    ref    data,      // 引用传递
    input  valid,
    output ready
  );
endinterface

// 生产者模块 - 使用ref
module producer (
  ref shared_bus_if.PRODUCER bus,
  input  logic clk,
  input  logic rst_n
);
  logic [7:0] data_gen;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_gen <= 8'h00;
      bus.valid <= 1'b0;
    end else begin
      if (!bus.ready) begin
        bus.data  <= data_gen;    // 直接修改interface中的变量
        bus.valid <= 1'b1;
        data_gen  <= data_gen + 1;
        $display("[Producer] 发送数据: 0x%02h", bus.data);
      end else begin
        bus.valid <= 1'b0;
      end
    end
  end
endmodule

// 消费者模块 - 使用ref
module consumer (
  ref shared_bus_if.CONSUMER bus,
  input  logic clk,
  input  logic rst_n
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bus.ready <= 1'b0;
    end else begin
      if (bus.valid && !bus.ready) begin
        bus.ready <= 1'b1;
        $display("[Consumer] 接收数据: 0x%02h", bus.data);
      end else begin
        bus.ready <= 1'b0;
      end
    end
  end
endmodule

module top2;
  logic clk, rst_n;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  shared_bus_if bus();
  
  producer u_prod (bus, clk, rst_n);
  consumer u_cons (bus, clk, rst_n);
  
  initial begin
    $display("\n========== 示例2: ref与interface结合 ==========");
    rst_n = 0;
    #20 rst_n = 1;
    #100 $finish;
  end
endmodule


//============================================================================
// 示例3: ref在task和function中的应用
//============================================================================

module ref_task_function;
  
  // 使用ref的task - 交换两个变量
  task automatic swap(ref int a, ref int b);
    int temp;
    temp = a;
    a    = b;
    b    = temp;
    $display("[swap] 交换后: a=%0d, b=%0d", a, b);
  endtask
  
  // 使用const ref的function - 求数组和
  function automatic int sum_array(const ref int arr[]);
    int result = 0;
    foreach (arr[i])
      result += arr[i];
    return result;
  endtask
  
  // 使用ref修改数组元素
  task automatic double_array(ref int arr[]);
    foreach (arr[i])
      arr[i] *= 2;
  endtask
  
  int x, y;
  int data[5];
  
  initial begin
    $display("\n========== 示例3: ref在task/function中的应用 ==========");
    
    // 测试swap
    x = 10;
    y = 20;
    $display("交换前: x=%0d, y=%0d", x, y);
    swap(x, y);
    $display("交换后: x=%0d, y=%0d (直接修改原变量)", x, y);
    
    // 测试const ref
    data = '{1, 2, 3, 4, 5};
    $display("\n数组: %p", data);
    $display("数组和 = %0d (使用const ref，只读)", sum_array(data));
    
    // 测试ref修改数组
    double_array(data);
    $display("double后数组: %p (使用ref，直接修改)", data);
    
    $finish;
  end
endmodule


//============================================================================
// 示例4: 共享变量与多模块通信
//============================================================================

package shared_pkg;
  // 共享的数据结构
  typedef struct packed {
    logic [31:0] addr;
    logic [31:0] data;
    logic        valid;
    logic        ready;
  } transaction_t;
endpackage

import shared_pkg::*;

// 使用ref共享变量
module counter_driver (
  ref int shared_counter,
  input  logic clk,
  input  logic rst_n,
  input  logic enable
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      shared_counter <= 0;
    else if (enable)
      shared_counter <= shared_counter + 1;
  end
endmodule

// 监控模块 - 读取共享变量
module counter_monitor (
  const ref int shared_counter,  // 只读引用
  input  logic clk
);
  always @(posedge clk) begin
    $display("[Monitor] Time=%0t, Counter=%0d", $time, shared_counter);
  end
endmodule

// 检查模块 - 验证共享变量
module counter_checker (
  const ref int shared_counter,
  input  logic clk,
  input  logic rst_n
);
  int last_count;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      last_count <= 0;
    else begin
      if (shared_counter != last_count + 1 && shared_counter != 0)
        $error("[Checker] Counter跳变错误: last=%0d, current=%0d", last_count, shared_counter);
      last_count <= shared_counter;
    end
  end
endmodule

module top4;
  logic clk, rst_n, enable;
  int shared_counter;  // 共享变量
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 三个模块共享同一个变量
  counter_driver   u_driver  (shared_counter, clk, rst_n, enable);
  counter_monitor  u_monitor (shared_counter, clk);
  counter_checker  u_checker (shared_counter, clk, rst_n);
  
  initial begin
    $display("\n========== 示例4: 共享变量与多模块通信 ==========");
    rst_n  = 0;
    enable = 0;
    
    #20 rst_n = 1;
    #10 enable = 1;
    
    #50;
    enable = 0;
    $display("\n停止计数后，共享变量 = %0d", shared_counter);
    
    #20;
    $display("所有模块都访问同一个共享变量");
    $finish;
  end
endmodule


//============================================================================
// 示例5: ref传递大型数据结构
//============================================================================

module large_data_example;
  // 定义大型数据结构
  typedef struct packed {
    logic [63:0] header;
    logic [511:0] payload;  // 512位数据
    logic [31:0] checksum;
    logic        valid;
  } packet_t;
  
  // 使用ref处理大型数据结构
  task automatic process_packet(ref packet_t pkt);
    // 直接操作，不需要复制
    pkt.checksum = calculate_checksum(pkt.payload);
    $display("[process_packet] 处理数据包，生成校验和: 0x%08h", pkt.checksum);
  endtask
  
  // 只读访问大型数据结构
  function automatic bit verify_packet(const ref packet_t pkt);
    logic [31:0] expected;
    expected = calculate_checksum(pkt.payload);
    return (pkt.checksum == expected);
  endfunction
  
  function automatic logic [31:0] calculate_checksum(input logic [511:0] data);
    calculate_checksum = 32'h0;
    for (int i = 0; i < 16; i++)
      calculate_checksum ^= data[i*32 +: 32];
  endfunction
  
  packet_t packet;
  
  initial begin
    $display("\n========== 示例5: ref传递大型数据结构 ==========");
    
    // 初始化数据包
    packet.header   = 64'hDEAD_BEEF_CAFE_BABE;
    packet.payload  = {16{32'h12345678}};
    packet.valid    = 1'b1;
    
    $display("数据包大小: %0d bits", $bits(packet));
    $display("使用ref传递，无需复制整个数据结构");
    
    // 处理数据包
    process_packet(packet);
    
    // 验证数据包
    if (verify_packet(packet))
      $display("校验通过！");
    else
      $display("校验失败！");
    
    $finish;
  end
endmodule


//============================================================================
// 示例6: ref与inout的对比
//============================================================================

module ref_vs_inout;
  
  // 使用inout的模块
  module inout_module (
    inout wire [7:0] bi_data,
    input  logic     oe,      // 输出使能
    input  logic     clk
  );
    reg [7:0] out_data;
    
    assign bi_data = oe ? out_data : 8'bz;  // 三态
    
    always @(posedge clk) begin
      if (oe)
        out_data <= out_data + 1;
    end
  endmodule
  
  // 使用ref的模块
  module ref_module (
    ref logic [7:0] shared_data,
    input  logic    clk,
    input  logic    enable
  );
    always @(posedge clk) begin
      if (enable)
        shared_data <= shared_data + 1;
    end
  endmodule
  
  logic clk;
  wire [7:0] bi_data;
  logic [7:0] ref_data;
  logic oe, enable;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  inout_module u_inout (bi_data, oe, clk);
  ref_module   u_ref   (ref_data, clk, enable);
  
  initial begin
    $display("\n========== 示例6: ref vs inout 对比 ==========");
    
    $display("inout特点:");
    $display("  - 用于双向总线");
    $display("  - 支持多驱动（需要三态）");
    $display("  - 值传递方式");
    
    $display("\nref特点:");
    $display("  - 引用传递，高效");
    $display("  - 不能用于net类型");
    $display("  - 不允许多驱动");
    
    // 测试ref
    ref_data = 0;
    enable = 1;
    #30;
    $display("\n使用ref，3个周期后数据: %0d", ref_data);
    
    $finish;
  end
endmodule


//============================================================================
// 主测试入口
//============================================================================

module main;
  initial begin
    $display("============================================================");
    $display("        SystemVerilog ref端口 示例演示");
    $display("============================================================");
    $display("");
    $display("知识点:");
    $display("  1. 值传递 vs 引用传递");
    $display("  2. ref与interface结合");
    $display("  3. ref在task/function中的应用");
    $display("  4. 共享变量与多模块通信");
    $display("  5. ref传递大型数据结构");
    $display("  6. ref与inout的对比");
    $display("");
    $display("要点:");
    $display("  - ref使用引用传递，不复制数据");
    $display("  - 只能用于变量类型，不能用于net");
    $display("  - const ref提供只读访问");
    $display("  - 适合传递大型数据结构和共享变量");
    $display("============================================================");
    
    // 运行示例1
    run_example1();
  end
  
  task run_example1;
    $display("\n运行示例1: 值传递 vs 引用传递");
    $display("请分别编译运行各个示例模块");
  endtask
endmodule
