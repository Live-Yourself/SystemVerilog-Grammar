// 知识点23: 常量定义 (parameter / localparam / const)
// 演示parameter、localparam、const的使用场景和区别

module constants #(
  // ========== 1. parameter: 模块参数(可覆盖) ==========
  // 用于模块实例化时可配置的参数
  parameter DATA_WIDTH = 8,           // 数据位宽
  parameter ADDR_WIDTH = 16,          // 地址位宽
  parameter DEPTH      = 256          // 深度
) (
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic [DATA_WIDTH-1:0]  data_in,
  output logic [DATA_WIDTH-1:0]  data_out
);

  // ========== 2. localparam: 局部参数(不可覆盖) ==========
  // 用于模块内部固定的常量，不能被实例覆盖
  localparam MEM_SIZE   = DEPTH * DATA_WIDTH / 8;  // 内存大小(字节)
  localparam ADDR_MASK  = {ADDR_WIDTH{1'b1}};       // 地址掩码
  localparam IDLE_STATE = 3'b000;                   // 空闲状态
  localparam MAX_COUNT  = 100;                      // 最大计数
  
  // 基于parameter计算localparam
  localparam WORD_BITS  = DATA_WIDTH;               // 字位数
  localparam BYTE_BITS  = 8;                        // 字节位数
  localparam NUM_BYTES  = (DATA_WIDTH + 7) / 8;     // 字节数(向上取整)
  
  // ========== 3. const: 运行时常量(SV特性) ==========
  // 在运行时初始化后不可改变
  const int RESET_CYCLES = 10;          // 复位周期数
  const string MODULE_NAME = "constants";  // 模块名
  const int TIMEOUT = 1000;             // 超时值
  
  // ========== 4. 枚举常量 ==========
  typedef enum bit [2:0] {
    STATE_IDLE  = 3'b000,               // 空闲状态
    STATE_READ  = 3'b001,               // 读状态
    STATE_WRITE = 3'b010,               // 写状态
    STATE_DONE  = 3'b011                // 完成状态
  } state_t;
  
  state_t current_state, next_state;    // 状态变量
  
  // ========== 5. 位宽计算常量 ==========
  // 使用系统函数计算位宽
  localparam COUNTER_BITS = $clog2(MAX_COUNT);  // 计数器位宽
  localparam DEPTH_BITS   = $clog2(DEPTH);      // 深度位宽
  
  // ========== 6. 数组常量 ==========
  // 使用localparam定义常量数组
  localparam logic [7:0] INIT_DATA [4] = '{
    8'h00, 8'h11, 8'h22, 8'h33
  };
  
  // ========== 7. 结构体常量 ==========
  typedef struct packed {
    logic [7:0]  opcode;
    logic [15:0] address;
    logic [7:0]  length;
  } cmd_s;                   // 结构体命名默认加 _s
  
  localparam cmd_s DEFAULT_CMD = '{
    opcode:  8'h00,
    address: 16'h0000,
    length:  8'h01
  };
  
  // ========== 8. 内部变量 ==========
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];  // 存储器
  logic [DEPTH_BITS-1:0] addr_ptr;          // 地址指针
  int                   cycle_count;        // 周期计数
  int                   i;                  // 循环变量
  
  // ========== 9. `define 宏常量 ==========
  // 预处理器定义，全局可见
  `define MAX_DELAY 100
  `define CLK_PERIOD 10
  
  initial begin
    $display("========================================");
    $display("  常量定义 (parameter/localparam/const)");
    $display("========================================\n");
    
    // ----- parameter演示 -----
    $display("【1. parameter (模块参数，可覆盖)】");
    $display("  用途: 模块实例化时可配置");
    $display("  特点:");
    $display("    ✓ 可在实例化时通过 #() 覆盖");
    $display("    ✓ 可作为其他常量计算的基础");
    $display("    ✓ 常用于: 位宽、深度、配置参数");
    $display("");
    $display("  当前值:");
    $display("    DATA_WIDTH = %0d", DATA_WIDTH);
    $display("    ADDR_WIDTH = %0d", ADDR_WIDTH);
    $display("    DEPTH      = %0d", DEPTH);
    $display("");
    $display("  实例化覆盖示例:");
    $display("    module_name #(.DATA_WIDTH(16)) u_inst (...);");
    $display("");
    
    // ----- localparam演示 -----
    $display("【2. localparam (局部参数，不可覆盖)】");
    $display("  用途: 模块内部固定常量");
    $display("  特点:");
    $display("    ✓ 不能被实例化覆盖");
    $display("    ✓ 可基于parameter计算");
    $display("    ✓ 常用于: 状态编码、派生参数");
    $display("");
    $display("  当前值:");
    $display("    MEM_SIZE    = %0d (DEPTH * DATA_WIDTH / 8)", MEM_SIZE);
    $display("    NUM_BYTES   = %0d ((DATA_WIDTH + 7) / 8)", NUM_BYTES);
    $display("    COUNTER_BITS= %0d ($clog2(MAX_COUNT))", COUNTER_BITS);
    $display("    DEPTH_BITS  = %0d ($clog2(DEPTH))", DEPTH_BITS);
    $display("");
    
    // ----- const演示 -----
    $display("【3. const (运行时常量，SV特性)】");
    $display("  用途: 运行时初始化后不可改变");
    $display("  特点:");
    $display("    ✓ 在initial/task/function中初始化");
    $display("    ✓ 初始化后不可修改");
    $display("    ✓ 可用于验证环境配置");
    $display("");
    $display("  当前值:");
    $display("    RESET_CYCLES = %0d", RESET_CYCLES);
    $display("    MODULE_NAME  = \"%s\"", MODULE_NAME);
    $display("    TIMEOUT      = %0d", TIMEOUT);
    $display("");
    
    // ----- 枚举常量演示 -----
    $display("【4. 枚举常量】");
    $display("  用途: 定义一组命名的常量");
    $display("  当前值:");
    $display("    STATE_IDLE  = %b (%s)", STATE_IDLE, STATE_IDLE.name());
    $display("    STATE_READ  = %b (%s)", STATE_READ, STATE_READ.name());
    $display("    STATE_WRITE = %b (%s)", STATE_WRITE, STATE_WRITE.name());
    $display("    STATE_DONE  = %b (%s)", STATE_DONE, STATE_DONE.name());
    $display("");
    
    // ----- 数组常量演示 -----
    $display("【5. 数组常量】");
    $display("  INIT_DATA = %p", INIT_DATA);
    $display("");
    
    // ----- 结构体常量演示 -----
    $display("【6. 结构体常量】");
    $display("  DEFAULT_CMD = %p", DEFAULT_CMD);
    $display("");
    
    // ----- `define演示 -----
    $display("【7. `define 宏常量】");
    $display("  特点:");
    $display("    ✓ 预处理器文本替换");
    $display("    ✓ 全局可见(跨文件)");
    $display("    ✓ 无类型检查");
    $display("    ✗ 调试困难");
    $display("");
    $display("  当前值:");
    $display("    `MAX_DELAY  = %0d", `MAX_DELAY);
    $display("    `CLK_PERIOD = %0d", `CLK_PERIOD);
    $display("");
    
    // ----- 三者对比 -----
    $display("【8. parameter vs localparam vs const 对比】");
    $display("  ┌─────────────┬──────────────┬──────────────┬──────────────┐");
    $display("  │ 特性        │ parameter    │ localparam   │ const        │");
    $display("  ├─────────────┼──────────────┼──────────────┼──────────────┤");
    $display("  │ 可覆盖      │ ✓ 是         │ ✗ 否         │ ✗ 否         │");
    $display("  │ 定义位置    │ 模块头       │ 模块体内     │ 模块体内     │");
    $display("  │ 计算时机    │ 编译时       │ 编译时       │ 运行时       │");
    $display("  │ 类型检查    │ 有           │ 有           │ 有           │");
    $display("  │ 适用场景    │ 可配置参数   │ 固定常量     │ 运行时配置   │");
    $display("  │ 跨模块      │ 实例传递     │ 不可见       │ 不可见       │");
    $display("  └─────────────┴──────────────┴──────────────┴──────────────┘");
    $display("");
    
    // ----- 最佳实践 -----
    $display("【9. 最佳实践】");
    $display("  ✓ 位宽/深度用 parameter (可配置)");
    $display("  ✓ 状态编码用 localparam 或 enum");
    $display("  ✓ 验证参数用 const");
    $display("  ✓ 全局配置用 `define (谨慎使用)");
    $display("  ✓ 使用 $clog2 计算位宽");
    $display("  ✓ 派生参数用 localparam 基于 parameter");
    $display("  ✓ 避免魔数(magic number)，使用命名常量");
    $display("");
    
    // ----- 常见用法示例 -----
    $display("【10. 常见用法示例】");
    $display("");
    $display("  // FIFO深度配置");
    $display("  parameter FIFO_DEPTH = 16;");
    $display("  localparam FIFO_ADDR_BITS = $clog2(FIFO_DEPTH);");
    $display("");
    $display("  // 状态机定义");
    $display("  typedef enum bit [1:0] {{IDLE, ACTIVE, DONE}} state_t;");
    $display("");
    $display("  // 复位周期");
    $display("  const int RESET_CLKS = 100;");
    $display("");
    
    $display("========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
