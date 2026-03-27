// 知识点22: 类型转换 (Type Casting)
// 演示静态转换、动态转换、位宽转换、符号转换

module type_casting;

  // ========== 用于演示的变量 ==========
  logic [31:0]  logic_val;     // 四值逻辑变量
  bit  [31:0]   bit_val;       // 双状态变量
  int           int_val;       // 有符号整数
  int           result;        // 结果变量
  real          real_val;      // 实数
  int           int_from_real; // 实数转整数
  
  // 枚举类型
  typedef enum bit [2:0] {
    IDLE  = 3'b000,
    START = 3'b001,
    DATA  = 3'b010,
    STOP  = 3'b011
  } state_t;
  
  state_t       current_state; // 枚举变量
  int           state_int;     // 枚举转整数
  
  // 结构体
  typedef struct packed {
    bit [7:0] data;
    bit       valid;
  } pkt_s;                     // 结构体命名默认加 _s
  
  pkt_s         packet;        // 结构体变量
  logic [8:0]   raw_bits;      // 原始位向量
  
  // 类句柄（用于$cast演示）
  // 注: 需要在类上下文中使用
  
  initial begin
    $display("========================================");
    $display("    类型转换 (Type Casting) 示例");
    $display("========================================\n");
    
    // ============================================================
    // 一、隐式类型转换
    // ============================================================
    $display("【一、隐式类型转换】");
    $display("  特点: 自动进行，无需显式指定");
    $display("");
    
    // 小位宽 → 大位宽 (自动扩展)
    logic [7:0]  small_val = 8'hA5;
    logic [15:0] large_val;
    large_val = small_val;  // 自动扩展到16位
    $display("  小→大: 8'h%h → 16'h%h (自动扩展)", small_val, large_val);
    
    // 无符号 → 有符号 (按位复制)
    bit [7:0]  unsigned_val = 8'hFF;    // 255
    int signed_val;
    signed_val = unsigned_val;  // 隐式转换
    $display("  无符号→有符号: %0d → %0d", unsigned_val, signed_val);
    
    // 整数 → 实数
    int i_val = 10;
    real r_val;
    r_val = i_val;
    $display("  整数→实数: %0d → %f", i_val, r_val);
    $display("");
    
    // ============================================================
    // 二、静态类型转换 (Static Cast)
    // ============================================================
    $display("【二、静态类型转换 (编译时检查)】");
    $display("  语法: type'(expression)");
    $display("");
    
    // ----- 1. 实数转整数 -----
    $display("  1. 实数转整数:");
    real_val = 3.7;
    int_from_real = int'(real_val);  // 截断小数部分
    $display("     int'(3.7) = %0d (截断)", int_from_real);
    
    real_val = -3.7;
    int_from_real = int'(real_val);
    $display("     int'(-3.7) = %0d", int_from_real);
    $display("");
    
    // ----- 2. 位宽转换 -----
    $display("  2. 位宽转换:");
    logic [15:0] wide_val = 16'hABCD;
    logic [7:0]  narrow_val;
    
    // 大位宽 → 小位宽 (截断高位)
    narrow_val = 8'(wide_val);
    $display("     8'(16'hABCD) = 8'h%h (截断高位)", narrow_val);
    
    // 小位宽 → 大位宽 (扩展)
    logic [7:0]  small = 8'hA5;
    logic [15:0] large;
    large = 16'(small);
    $display("     16'(8'hA5) = 16'h%h (扩展)", large);
    $display("");
    
    // ----- 3. 符号转换 -----
    $display("  3. 符号转换:");
    int signed_i = -1;
    bit [31:0] unsigned_b;
    
    // 有符号 → 无符号
    unsigned_b = bit [31:0]'(signed_i);
    $display("     无符号化: -1 → 32'h%h", unsigned_b);
    
    // 无符号 → 有符号
    bit [7:0] u_val = 8'hFF;  // 255
    int s_val;
    s_val = signed'(u_val);
    $display("     signed'(255) = %0d", s_val);
    $display("");
    
    // ----- 4. 四值→双状态转换 -----
    $display("  4. 四值→双状态转换:");
    logic [7:0] four_state = 8'hXZ;
    bit  [7:0]  two_state;
    
    two_state = bit [7:0]'(four_state);
    $display("     四值(8'hXZ) → 双状态: 8'h%h", two_state);
    $display("     注: X和Z转换为0");
    $display("");
    
    // ----- 5. 整数转枚举 -----
    $display("  5. 整数转枚举 (静态转换):");
    state_int = 2;  // 对应DATA状态
    
    // 静态转换 - 编译时不检查范围
    current_state = state_t'(state_int);
    $display("     state_t'(2) = %s (值=%0d)", 
             current_state.name(), current_state);
    
    // 危险: 超出枚举范围
    state_int = 5;  // 不在枚举范围内
    current_state = state_t'(state_int);
    $display("     state_t'(5) = %s (值=%0d) - 超出范围!",
             current_state.name(), current_state);
    $display("     警告: 静态转换不检查范围!");
    $display("");
    
    // ----- 6. 结构体与位向量互转 -----
    $display("  6. 结构体与位向量互转:");
    packet.data  = 8'hA5;
    packet.valid = 1'b1;
    
    // 结构体 → 位向量
    raw_bits = logic [8:0]'(packet);
    $display("     pkt → bits: %b (9位)", raw_bits);
    
    // 位向量 → 结构体
    raw_bits = 9'b1_1010_1010;
    packet = pkt_s'(raw_bits);
    $display("     bits → pkt: data=0x%h, valid=%b", packet.data, packet.valid);
    $display("");
    
    // ============================================================
    // 三、动态类型转换 ($cast)
    // ============================================================
    $display("【三、动态类型转换 $cast (运行时检查)】");
    $display("  语法: $cast(dest, source) 返回成功/失败");
    $display("");
    
    // ----- 1. 枚举类型安全转换 -----
    $display("  1. 枚举类型安全转换:");
    
    // 有效值
    state_int = 2;  // DATA
    if ($cast(current_state, state_int))
      $display("     $cast成功: %d → %s", state_int, current_state.name());
    else
      $display("     $cast失败: %d 不在枚举范围内", state_int);
    
    // 无效值
    state_int = 7;  // 不在枚举范围
    if ($cast(current_state, state_int))
      $display("     $cast成功: %d → %s", state_int, current_state.name());
    else
      $display("     $cast失败: %d 不在枚举范围内", state_int);
    $display("");
    
    // ----- 2. $cast作为任务调用 -----
    $display("  2. $cast作为任务调用:");
    state_int = 1;  // START
    $cast(current_state, state_int);  // 不检查返回值
    $display("     $cast(current_state, 1) = %s", current_state.name());
    $display("     注: 不检查返回值可能导致运行时错误");
    $display("");
    
    // ============================================================
    // 四、转换函数
    // ============================================================
    $display("【四、内置转换函数】");
    $display("");
    
    // $signed / $unsigned
    $display("  1. $signed() / $unsigned():");
    bit [7:0] u_data = 8'hFF;
    int signed_result;
    
    signed_result = $signed(u_data);
    $display("     $signed(8'hFF) = %0d", signed_result);
    $display("     $unsigned(-1) = %0d", $unsigned(-1));
    $display("");
    
    // ============================================================
    // 五、转换方式对比
    // ============================================================
    $display("【五、类型转换方式对比】\n");
    
    $display("  ┌─────────────┬────────────────┬─────────────────────────┐");
    $display("  │ 方式        │ 检查时机       │ 特点                    │");
    $display("  ├─────────────┼────────────────┼─────────────────────────┤");
    $display("  │ 隐式转换    │ 无检查         │ 自动进行，可能丢失数据  │");
    $display("  │ type'()     │ 编译时         │ 快速，不检查运行时范围  │");
    $display("  │ $cast()     │ 运行时         │ 安全，检查有效性        │");
    $display("  │ $signed()   │ 无检查         │ 转换为有符号            │");
    $display("  │ $unsigned() │ 无检查         │ 转换为无符号            │");
    $display("  └─────────────┴────────────────┴─────────────────────────┘");
    $display("");
    
    // ============================================================
    // 六、最佳实践
    // ============================================================
    $display("【六、类型转换最佳实践】");
    $display("  ✓ 使用 $cast 进行枚举类型转换 (运行时安全)");
    $display("  ✓ 位宽截断时使用静态转换并添加注释");
    $display("  ✓ 四值→双状态时注意 X/Z 会变成 0");
    $display("  ✓ 实数转整数会截断，注意精度损失");
    $display("  ✓ 有符号/无符号混合运算要小心");
    $display("  ✓ 使用 $signed/$unsigned 明确意图");
    $display("");
    
    // ============================================================
    // 七、常见陷阱
    // ============================================================
    $display("【七、常见陷阱】");
    $display("  ✗ 有符号数扩展: 8'hFF 扩展到16位是 16'h00FF 还是 16'hFFFF?");
    $display("  ✗ 四值X/Z: logic的X/Z转bit后变成0");
    $display("  ✗ 枚举越界: 静态转换不检查枚举范围");
    $display("  ✗ 实数截断: 3.9 转整数是3而非4");
    $display("  ✗ 溢出: 大数转小位宽会截断高位");
    $display("");
    
    $display("========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
