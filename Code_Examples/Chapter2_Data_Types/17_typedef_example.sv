// 知识点17: typedef类型定义
// 演示typedef创建自定义类型，提高代码可读性和复用性

module typedef_example;

  // ========== 1. 基本类型别名 ==========
  // 为常用类型创建别名，便于跨平台移植
  typedef int    uint32_t;      // 32位无符号整数
  typedef bit    bool_t;        // 布尔类型
  typedef byte   char_t;        // 字符类型
  
  // 使用自定义类型声明变量
  uint32_t data_word;           // 等价于 int data_word
  bool_t   flag;                // 等价于 bit flag
  char_t   ch;                  // 等价于 byte ch

  // ========== 2. 数组类型定义 ==========
  // 简化复杂数组声明
  typedef int    int_array_8[8];     // 8元素整数数组
  typedef logic  logic_vec[7:0];     // 8位logic向量
  typedef byte   byte_matrix[4][4];  // 4x4字节矩阵
  
  int_array_8   arr1;           // 等价于 int arr1[8]
  logic_vec     vec1;           // 等价于 logic vec1[7:0]
  byte_matrix   mat1;           // 等价于 byte mat1[4][4]

  // ========== 3. 枚举类型定义 ==========
  // 状态机状态定义
  typedef enum bit [2:0] {
    IDLE  = 3'b000,
    START = 3'b001,
    DATA  = 3'b010,
    STOP  = 3'b011,
    ERROR = 3'b100
  } state_t;
  
  // 操作码定义
  typedef enum bit [3:0] {
    OP_ADD  = 4'h0,
    OP_SUB  = 4'h1,
    OP_MUL  = 4'h2,
    OP_DIV  = 4'h3,
    OP_NOP  = 4'hF
  } opcode_t;
  
  state_t   current_state;      // 当前状态
  state_t   next_state;         // 下一状态
  opcode_t  instruction;        // 指令操作码

  // ========== 4. 结构体类型定义 ==========
  // 数据包结构
  typedef struct packed {
    logic       valid;          // 有效位
    logic [2:0] opcode;         // 操作码
    logic [3:0] addr;           // 地址
    logic [7:0] data;           // 数据
  } packet_t;
  
  // 寄存器配置结构
  typedef struct packed {
    bit         enable;         // 使能位
    bit [2:0]   mode;           // 工作模式
    bit [11:0]  threshold;      // 阈值
  } config_reg_t;
  
  packet_t    pkt;              // 数据包实例
  config_reg_t cfg;             // 配置寄存器实例

  // ========== 5. 联合体类型定义 ==========
  // 同一数据的多种视图
  typedef union packed {
    int         word;           // 32位整体视图
    byte        bytes[4];       // 4字节视图
    logic [31:0] bits;          // 32位向量视图
  } data_view_t;
  
  data_view_t raw_data;         // 可用多种方式访问

  // ========== 6. 参数化类型 ==========
  // 类参数化（在类中常用）
  // typedef class #(parameter WIDTH=8) my_class;
  
  // 常量定义
  int i;                        // 循环变量
  
  initial begin
    $display("========================================");
    $display("    typedef类型定义示例");
    $display("========================================\n");
    
    // ----- 测试基本类型别名 -----
    $display("【1. 基本类型别名】");
    data_word = 32'hDEADBEEF;
    flag      = 1'b1;
    ch        = "A";
    $display("  data_word = 0x%h", data_word);
    $display("  flag      = %b", flag);
    $display("  ch        = %c (ASCII: %0d)", ch, ch);
    $display("");
    
    // ----- 测试数组类型 -----
    $display("【2. 数组类型定义】");
    arr1 = '{0, 1, 2, 3, 4, 5, 6, 7};
    foreach (arr1[i])
      $display("  arr1[%0d] = %0d", i, arr1[i]);
    $display("");
    
    // ----- 测试枚举类型 -----
    $display("【3. 枚举类型定义】");
    current_state = IDLE;
    $display("  当前状态: %s (值=%0d)", current_state.name(), current_state);
    current_state = current_state.next();  // 获取下一状态
    $display("  下一状态: %s (值=%0d)", current_state.name(), current_state);
    
    instruction = OP_ADD;
    $display("  指令: %s (值=%0d)", instruction.name(), instruction);
    $display("");
    
    // ----- 测试结构体类型 -----
    $display("【4. 结构体类型定义】");
    pkt.valid  = 1'b1;
    pkt.opcode = 3'b010;
    pkt.addr   = 4'hA;
    pkt.data   = 8'hFF;
    $display("  数据包: valid=%b, opcode=%b, addr=%h, data=%h",
             pkt.valid, pkt.opcode, pkt.addr, pkt.data);
    
    cfg.enable    = 1'b1;
    cfg.mode      = 3'b101;
    cfg.threshold = 12'hFFF;
    $display("  配置寄存器: enable=%b, mode=%b, threshold=%h",
             cfg.enable, cfg.mode, cfg.threshold);
    $display("");
    
    // ----- 测试联合体类型 -----
    $display("【5. 联合体类型定义】");
    raw_data.word = 32'h12345678;
    $display("  整体视图: 0x%h", raw_data.word);
    $display("  字节视图: [0]=%h, [1]=%h, [2]=%h, [3]=%h",
             raw_data.bytes[0], raw_data.bytes[1],
             raw_data.bytes[2], raw_data.bytes[3]);
    $display("  位视图: %b", raw_data.bits);
    $display("  (注: 大端序下 bytes[0] 为高位字节)");
    $display("");
    
    // ----- typedef的优势 -----
    $display("【6. typedef的优势】");
    $display("  ✓ 代码可读性: state_t 比 enum bit[2:0] {...} 更清晰");
    $display("  ✓ 类型复用: 可在多处使用同一类型定义");
    $display("  ✓ 易于修改: 修改类型只需改一处定义");
    $display("  ✓ 类型安全: 编译器进行类型检查");
    $display("  ✓ 团队协作: 统一命名规范 (如 _t 后缀)");
    
    $display("\n========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
