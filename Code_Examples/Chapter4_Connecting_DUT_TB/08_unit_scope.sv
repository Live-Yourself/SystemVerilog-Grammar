//=============================================================================
// 文件名: 08_unit_scope.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 8. 顶层作用域$unit
// 说明: 演示$unit编译单元作用域的定义和使用
//=============================================================================

//-----------------------------------------------------------------------------
// $unit 作用域定义（在所有模块之外）
//-----------------------------------------------------------------------------

// $unit中的参数定义
parameter UNIT_DATA_WIDTH = 8;
parameter UNIT_ADDR_WIDTH = 16;

// $unit中的类型定义
typedef logic [UNIT_DATA_WIDTH-1:0] unit_data_t;
typedef logic [UNIT_ADDR_WIDTH-1:0] unit_addr_t;

// $unit中的枚举类型定义
typedef enum bit [1:0] {
  UNIT_IDLE   = 2'b00,
  UNIT_ACTIVE = 2'b01,
  UNIT_HOLD   = 2'b10,
  UNIT_DONE   = 2'b11
} unit_state_t;

// $unit中的结构体类型定义
typedef struct packed {
  unit_addr_t addr;
  unit_data_t data;
  logic       valid;
  logic       ready;
} unit_transaction_t;

// $unit中的常量定义
const int UNIT_MAX_COUNT = 256;
const string UNIT_DESIGN_NAME = "UnitScopeDemo";

// $unit中的函数定义
function void unit_print_banner(string module_name);
  $display("========================================");
  $display("  Module: %s", module_name);
  $display("  Design: %s", UNIT_DESIGN_NAME);
  $display("========================================");
endfunction

function void unit_print_time(string msg);
  $display("[%0t] %s", $time, msg);
endfunction

// $unit中计数函数
function int unit_count_bits(input unit_data_t data);
  int count = 0;
  foreach (data[i])
    if (data[i]) count++;
  return count;
endfunction

//-----------------------------------------------------------------------------
// 示例1: 在模块中使用$unit定义的类型和参数
//-----------------------------------------------------------------------------
module example1_using_unit_types (
  input  logic        clk,
  input  logic        rst_n,
  input  unit_data_t  data_in,
  output unit_data_t  data_out
);
  // 使用$unit中的常量
  localparam int DEPTH = UNIT_MAX_COUNT;
  
  // 内部寄存器
  unit_data_t internal_reg;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      internal_reg <= '0;
      data_out     <= '0;
    end
    else begin
      internal_reg <= data_in;
      data_out     <= internal_reg;
    end
  end
  
  // 调用$unit中的函数
  initial unit_print_banner("example1_using_unit_types");
  
endmodule

//-----------------------------------------------------------------------------
// 示例2: 使用$unit中的枚举类型
//-----------------------------------------------------------------------------
module example2_using_unit_enum (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  output unit_state_t current_state
);
  unit_state_t next_state;
  
  // 状态转移逻辑
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      current_state <= UNIT_IDLE;
    else
      current_state <= next_state;
  end
  
  // 下一状态逻辑
  always_comb begin
    case (current_state)
      UNIT_IDLE:   next_state = start ? UNIT_ACTIVE : UNIT_IDLE;
      UNIT_ACTIVE: next_state = UNIT_HOLD;
      UNIT_HOLD:   next_state = UNIT_DONE;
      UNIT_DONE:   next_state = UNIT_IDLE;
      default:     next_state = UNIT_IDLE;
    endcase
  end
  
  initial unit_print_banner("example2_using_unit_enum");
  
endmodule

//-----------------------------------------------------------------------------
// 示例3: 使用$unit中的结构体类型
//-----------------------------------------------------------------------------
module example3_using_unit_struct (
  input  logic              clk,
  input  logic              rst_n,
  input  unit_transaction_t trans_in,
  output unit_transaction_t trans_out
);
  // 内部事务缓冲
  unit_transaction_t trans_buffer;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      trans_buffer <= '0;
      trans_out    <= '0;
    end
    else if (trans_in.valid) begin
      trans_buffer      <= trans_in;
      trans_buffer.ready <= 1'b1;
      trans_out         <= trans_buffer;
    end
    else begin
      trans_buffer.ready <= 1'b0;
    end
  end
  
  initial unit_print_banner("example3_using_unit_struct");
  
endmodule

//-----------------------------------------------------------------------------
// 示例4: 使用$unit::显式引用解决命名冲突
//-----------------------------------------------------------------------------
module example4_explicit_reference;
  // 模块内部的同名参数（覆盖$unit中的定义）
  parameter UNIT_DATA_WIDTH = 16;  // 与$unit中的同名参数冲突
  
  // 使用显式引用
  unit_data_t                  data_from_unit;   // 8位（来自$unit）
  logic [UNIT_DATA_WIDTH-1:0]  data_local;       // 16位（来自模块内部）
  logic [$unit::UNIT_DATA_WIDTH-1:0] data_explicit;  // 8位（显式引用$unit）
  
  initial begin
    unit_print_banner("example4_explicit_reference");
    
    $display("\n--- 命名冲突解决示例 ---");
    $display("$unit::UNIT_DATA_WIDTH = %0d", $unit::UNIT_DATA_WIDTH);
    $display("模块内部 UNIT_DATA_WIDTH = %0d", UNIT_DATA_WIDTH);
    $display("");
    $display("data_from_unit 位宽: %0d ($unit类型)", $bits(data_from_unit));
    $display("data_local 位宽: %0d (模块内部参数)", $bits(data_local));
    $display("data_explicit 位宽: %0d (显式引用$unit)", $bits(data_explicit));
  end
  
endmodule

//-----------------------------------------------------------------------------
// 示例5: 使用$unit函数
//-----------------------------------------------------------------------------
module example5_using_unit_functions;
  unit_data_t test_data;
  int bit_count;
  
  initial begin
    unit_print_banner("example5_using_unit_functions");
    
    // 调用$unit中的函数
    unit_print_time("测试开始");
    
    // 测试位计数函数
    test_data = 8'b10110101;
    bit_count = unit_count_bits(test_data);
    
    $display("\n测试数据: %b", test_data);
    $display("置位位数: %0d", bit_count);
    
    // 测试其他数据
    test_data = 8'b11111111;
    $display("\n测试数据: %b, 置位位数: %0d", 
             test_data, unit_count_bits(test_data));
    
    test_data = 8'b00000000;
    $display("测试数据: %b, 置位位数: %0d", 
             test_data, unit_count_bits(test_data));
    
    unit_print_time("测试结束");
  end
  
endmodule

//-----------------------------------------------------------------------------
// 示例6: $unit全局变量的风险演示（不推荐做法）
//-----------------------------------------------------------------------------
// 注意：以下代码演示了为什么不推荐在$unit中使用全局变量

// $unit中的全局变量（仅用于演示风险）
unit_data_t unit_global_data;

module example6_global_var_risk;
  // 这个示例展示了全局变量的竞争风险
  
  initial begin
    unit_print_banner("example6_global_var_risk");
    $display("\n--- 全局变量风险演示 ---");
    $display("警告：$unit中的全局变量可能导致竞争条件！");
    $display("");
    $display("问题：");
    $display("1. 多个模块同时驱动全局变量 → 结果不确定");
    $display("2. 读写顺序不确定 → 可能读到X态");
    $display("3. 难以追踪信号来源 → 调试困难");
    $display("");
    $display("解决方案：");
    $display("1. 使用接口传递信号");
    $display("2. 使用参数和局部变量");
    $display("3. 使用package替代$unit全局变量");
    
    // 演示全局变量使用
    unit_global_data = 8'hAA;
    $display("\n设置全局变量: unit_global_data = 0x%02h", unit_global_data);
    
    #10;
    $display("读取全局变量: unit_global_data = 0x%02h", unit_global_data);
  end
  
endmodule

//-----------------------------------------------------------------------------
// 示例7: package替代$unit的最佳实践
//-----------------------------------------------------------------------------
package global_types_pkg;
  // 参数定义
  parameter PKG_DATA_WIDTH = 8;
  parameter PKG_ADDR_WIDTH = 16;
  
  // 类型定义
  typedef logic [PKG_DATA_WIDTH-1:0] pkg_data_t;
  typedef logic [PKG_ADDR_WIDTH-1:0] pkg_addr_t;
  
  // 枚举类型
  typedef enum bit [1:0] {
    PKG_IDLE   = 2'b00,
    PKG_ACTIVE = 2'b01,
    PKG_DONE   = 2'b11
  } pkg_state_t;
  
  // 常量
  const int PKG_MAX_COUNT = 256;
  
  // 函数
  function void pkg_print_info(string msg);
    $display("[PKG] %s", msg);
  endfunction
endpackage

module example7_package_best_practice (
  input  logic       clk,
  input  logic       rst_n,
  input  pkg_data_t  data_in,
  output pkg_data_t  data_out
);
  // 导入package
  import global_types_pkg::*;
  
  // 使用package中的类型
  pkg_state_t state;
  int counter;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= PKG_IDLE;
      data_out  <= '0;
      counter   <= 0;
    end
    else begin
      case (state)
        PKG_IDLE: begin
          if (data_in != 0) begin
            state    <= PKG_ACTIVE;
            data_out <= data_in;
          end
        end
        PKG_ACTIVE: begin
          counter <= counter + 1;
          if (counter >= PKG_MAX_COUNT)
            state <= PKG_DONE;
        end
        PKG_DONE: begin
          state <= PKG_IDLE;
        end
      endcase
    end
  end
  
  initial begin
    pkg_print_info("example7_package_best_practice 实例化");
    $display("使用package的优势:");
    $display("1. 显式导入，来源清晰");
    $display("2. 命名空间隔离，避免冲突");
    $display("3. 可重用性好");
    $display("4. 推荐使用package替代$unit");
  end
  
endmodule

//-----------------------------------------------------------------------------
// 示例8: 完整的顶层测试模块
//-----------------------------------------------------------------------------
module example8_top_testbench;
  // 导入package
  import global_types_pkg::*;
  
  // 时钟和复位
  logic       clk;
  logic       rst_n;
  
  // 使用$unit类型
  unit_data_t unit_data_in;
  unit_data_t unit_data_out;
  
  // 使用package类型
  pkg_data_t  pkg_data_in;
  pkg_data_t  pkg_data_out;
  
  // 实例化使用$unit类型的模块
  example1_using_unit_types u_unit_example (
    .clk      (clk),
    .rst_n    (rst_n),
    .data_in  (unit_data_in),
    .data_out (unit_data_out)
  );
  
  // 实例化使用package的模块
  example7_package_best_practice u_pkg_example (
    .clk      (clk),
    .rst_n    (rst_n),
    .data_in  (pkg_data_in),
    .data_out (pkg_data_out)
  );
  
  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 测试激励
  initial begin
    $display("\n");
    $display("========================================");
    $display("  完整测试：$unit vs package");
    $display("========================================\n");
    
    // 初始化
    rst_n       = 0;
    unit_data_in = 0;
    pkg_data_in  = 0;
    
    // 复位
    repeat(2) @(posedge clk);
    rst_n = 1;
    
    // 测试数据传输
    repeat(5) begin
      @(posedge clk);
      unit_data_in = $random;
      pkg_data_in  = $random;
      
      @(posedge clk);
      $display("[%0t] $unit: in=0x%02h, out=0x%02h | package: in=0x%02h, out=0x%02h",
               $time, unit_data_in, unit_data_out, pkg_data_in, pkg_data_out);
    end
    
    #20;
    $display("\n测试完成！");
    $finish;
  end
  
endmodule

//-----------------------------------------------------------------------------
// $unit 使用总结
//-----------------------------------------------------------------------------
/*
┌─────────────────────────────────────────────────────────────────────────┐
│                        $unit 使用总结                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  适用场景:                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ ✓ 类型定义 (typedef)                    推荐度: ★★★☆☆         │   │
│  │ ✓ 参数定义 (parameter)                  推荐度: ★★★☆☆         │   │
│  │ ✓ 常量定义 (const)                      推荐度: ★★★☆☆         │   │
│  │ △ 函数定义 (function/task)              推荐度: ★★☆☆☆         │   │
│  │ ✗ 全局变量 (logic/wire)                 推荐度: ★☆☆☆☆         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  最佳实践:                                                              │
│  1. 优先使用 package 替代 $unit                                        │
│  2. 避免在 $unit 中定义全局变量                                        │
│  3. 使用 $unit:: 显式引用解决命名冲突                                  │
│  4. 注意编译顺序对 $unit 可见性的影响                                  │
│                                                                         │
│  $unit vs package:                                                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ 特性          │ $unit           │ package                      │  │
│  │ ──────────────────────────────────────────────────────────────── │  │
│  │ 可见性        │ 自动可见        │ 需显式import                 │  │
│  │ 命名冲突      │ 易发生          │ 通过::限定                   │  │
│  │ 可维护性      │ 较差            │ 较好                         │  │
│  │ 推荐程度      │ 谨慎使用        │ 推荐                         │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
*/
