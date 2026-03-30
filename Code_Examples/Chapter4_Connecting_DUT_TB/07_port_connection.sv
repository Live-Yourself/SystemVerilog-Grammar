//=============================================================================
// 文件名: 07_port_connection.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 7. 模块连接与端口匹配
// 说明: 演示各种端口连接方式和端口匹配规则
//=============================================================================

//-----------------------------------------------------------------------------
// 示例1: 按名称连接（推荐方式）
//-----------------------------------------------------------------------------
module example1_named_connection;
  logic       clk;
  logic       rst_n;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic       valid_in;
  logic       valid_out;
  
  // 定义简单的DUT模块
  simple_dut #(
    .WIDTH(8)
  ) u_dut (
    // 按名称连接：清晰、易维护、顺序无关
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (data_in),
    .valid_in  (valid_in),
    .data_out  (data_out),
    .valid_out (valid_out)
  );
  
  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 测试激励
  initial begin
    rst_n    = 0;
    data_in  = 0;
    valid_in = 0;
    
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    repeat(3) begin
      @(posedge clk);
      data_in  = $random;
      valid_in = 1;
      
      @(posedge clk);
      valid_in = 0;
      
      wait(valid_out);
      $display("[按名称连接] data_in=0x%02h, data_out=0x%02h", 
               data_in, data_out);
    end
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 示例2: 按位置连接（传统方式，不推荐）
//-----------------------------------------------------------------------------
module example2_positional_connection;
  logic       clk;
  logic       rst_n;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic       valid_in;
  logic       valid_out;
  
  // 按位置连接：顺序必须严格匹配端口列表
  // 容易出错，不推荐使用
  simple_dut #(
    .WIDTH(8)
  ) u_dut (clk, rst_n, data_in, valid_in, data_out, valid_out);
  //           ↑ 顺序必须与模块端口定义完全一致
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    @(posedge clk);
    data_in  = 8'hBC;
    valid_in = 1;
    
    @(posedge clk);
    valid_in = 0;
    
    wait(valid_out);
    $display("[按位置连接] data_out=0x%02h", data_out);
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 示例3: 隐式端口连接 .*
//-----------------------------------------------------------------------------
module example3_implicit_connection;
  logic       clk;
  logic       rst_n;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic       valid_in;
  logic       valid_out;
  
  // 隐式连接：自动连接同名的端口和信号
  // 要求：端口名必须与信号名完全相同
  simple_dut #(
    .WIDTH(8)
  ) u_dut (.*);
  // .* 自动展开为：
  // .clk       (clk),
  // .rst_n     (rst_n),
  // .data_in   (data_in),
  // .valid_in  (valid_in),
  // .data_out  (data_out),
  // .valid_out (valid_out)
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    @(posedge clk);
    data_in  = 8'hDE;
    valid_in = 1;
    
    @(posedge clk);
    valid_in = 0;
    
    wait(valid_out);
    $display("[隐式连接] data_out=0x%02h", data_out);
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 示例4: 混合连接方式
//-----------------------------------------------------------------------------
module example4_mixed_connection;
  logic       clk;
  logic       rst_n;
  logic [7:0] my_data;        // 注意：名称与端口名不同
  logic [7:0] data_out;
  logic       valid_in;
  logic       valid_out;
  
  // 混合使用：部分隐式，部分显式
  simple_dut #(
    .WIDTH(8)
  ) u_dut (
    .*,                      // 隐式连接同名信号
    .data_in (my_data)       // 显式连接不同名信号
  );
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 0;
    my_data = 0;
    valid_in = 0;
    
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    @(posedge clk);
    my_data  = 8'hAD;
    valid_in = 1;
    
    @(posedge clk);
    valid_in = 0;
    
    wait(valid_out);
    $display("[混合连接] my_data=0x%02h, data_out=0x%02h", 
             my_data, data_out);
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 示例5: 接口连接方式
//-----------------------------------------------------------------------------
// 定义接口
interface dut_if;
  logic        clk;
  logic        rst_n;
  logic [7:0]  data_in;
  logic [7:0]  data_out;
  logic        valid_in;
  logic        valid_out;
  
  // DUT视角
  modport DUT (
    input  clk, rst_n, data_in, valid_in,
    output data_out, valid_out
  );
  
  // 测试平台视角
  modport TB (
    output clk, rst_n, data_in, valid_in,
    input  data_out, valid_out
  );
endinterface

module example5_interface_connection;
  dut_if bus();  // 接口实例
  
  // 使用接口modport连接
  simple_dut #(
    .WIDTH(8)
  ) u_dut (bus.DUT);
  //         ↑ 使用DUT modport
  
  // 时钟生成
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  // 测试激励
  initial begin
    bus.rst_n    = 0;
    bus.data_in  = 0;
    bus.valid_in = 0;
    
    repeat(2) @(posedge bus.clk);
    bus.rst_n = 1;
    
    repeat(3) begin
      @(posedge bus.clk);
      bus.data_in  = $random;
      bus.valid_in = 1;
      
      @(posedge bus.clk);
      bus.valid_in = 0;
      
      wait(bus.valid_out);
      $display("[接口连接] data_in=0x%02h, data_out=0x%02h", 
               bus.data_in, bus.data_out);
    end
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 示例6: 端口位宽匹配
//-----------------------------------------------------------------------------
module example6_width_matching;
  logic       clk;
  logic       rst_n;
  logic [7:0] data_8bit;    // 8位信号
  logic [3:0] data_4bit;    // 4位信号（演示位宽不匹配）
  logic [7:0] data_out;
  logic       valid_in;
  logic       valid_out;
  
  // 位宽匹配：8位对8位
  simple_dut #(
    .WIDTH(8)
  ) u_dut_match (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (data_8bit),   // ✓ 匹配
    .valid_in  (valid_in),
    .data_out  (data_out),
    .valid_out (valid_out)
  );
  
  // 位宽不匹配示例（会产生警告）
  // simple_dut #(.WIDTH(8)) u_dut_mismatch (
  //   .clk       (clk),
  //   .rst_n     (rst_n),
  //   .data_in   (data_4bit),   // ⚠ 警告：4位连8位，高4位为X
  //   .valid_in  (valid_in),
  //   .data_out  (data_out),
  //   .valid_out (valid_out)
  // );
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $display("=== 端口位宽匹配示例 ===");
    $display("8位信号连接8位端口：匹配");
    $display("4位信号连接8位端口：不匹配（高位为X）");
    
    rst_n = 0;
    data_8bit = 0;
    valid_in = 0;
    
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    @(posedge clk);
    data_8bit = 8'hFF;
    valid_in = 1;
    
    @(posedge clk);
    valid_in = 0;
    
    wait(valid_out);
    $display("[位宽匹配] data_8bit=0x%02h, data_out=0x%02h", 
             data_8bit, data_out);
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 示例7: 未连接端口处理
//-----------------------------------------------------------------------------
module example7_unconnected_ports;
  logic       clk;
  logic       rst_n;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic       valid_in;
  // valid_out 未连接
  
  // 部分端口未连接
  simple_dut #(
    .WIDTH(8)
  ) u_dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (data_in),
    .valid_in  (valid_in),
    .data_out  (data_out)
    // .valid_out 未连接 - 输出端口值被忽略
  );
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $display("=== 未连接端口示例 ===");
    $display("输出端口 valid_out 未连接，值被忽略");
    
    rst_n = 0;
    data_in = 0;
    valid_in = 0;
    
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    @(posedge clk);
    data_in = 8'h12;
    valid_in = 1;
    
    @(posedge clk);
    valid_in = 0;
    
    // 由于valid_out未连接，无法使用wait(valid_out)
    repeat(3) @(posedge clk);
    $display("[未连接端口] data_in=0x%02h, data_out=0x%02h", 
             data_in, data_out);
    
    #20 $finish;
  end
endmodule

//-----------------------------------------------------------------------------
// 被测模块定义
//-----------------------------------------------------------------------------
module simple_dut #(
  parameter WIDTH = 8
)(
  input  logic             clk,
  input  logic             rst_n,
  input  logic [WIDTH-1:0] data_in,
  input  logic             valid_in,
  output logic [WIDTH-1:0] data_out,
  output logic             valid_out
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out  <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end
    else if (valid_in) begin
      data_out  <= data_in;
      valid_out <= 1'b1;
    end
    else begin
      valid_out <= 1'b0;
    end
  end

endmodule

//-----------------------------------------------------------------------------
// 端口连接方式总结
//-----------------------------------------------------------------------------
/*
┌─────────────────────────────────────────────────────────────────────────┐
│                        端口连接方式对比                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  方式          │  语法                  │  优点        │  推荐度       │
│  ─────────────────────────────────────────────────────────────────────  │
│  按名称        │  .port(sig)           │  清晰、安全  │  ★★★★★      │
│  按位置        │  (sig1, sig2, ...)    │  简洁        │  ★★☆☆☆      │
│  隐式 .*       │  (.*)                 │  最简洁      │  ★★★★☆      │
│  混合          │  (.*, .port(sig))     │  灵活        │  ★★★★☆      │
│  接口          │  (interface.modport)  │  可重用      │  ★★★★★      │
│                                                                         │
│  最佳实践:                                                              │
│  1. 推荐使用按名称连接或隐式连接                                        │
│  2. 复杂设计推荐使用接口                                                │
│  3. 避免使用按位置连接（易出错）                                        │
│  4. 确保端口位宽匹配                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
*/
