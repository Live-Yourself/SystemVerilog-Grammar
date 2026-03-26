// ===================================
// 枚举类型示例 (Enumeration)
// 知识点10: 第2章 SystemVerilog数据类型
// ===================================

module enum_example;
  
  //================================================================
  // 1. 基本枚举声明
  //================================================================
  
  // 默认类型int,自动编号从0开始
  enum {RED, GREEN, BLUE} color;
  
  // 指定基础类型
  enum bit [2:0] {
    IDLE  = 3'b000,
    START = 3'b001,
    DATA  = 3'b010,
    STOP  = 3'b011
  } state;
  
  // 部分指定值,其余自动递增
  enum int {
    INIT,           // 0 (自动)
    WAIT = 5,       // 5 (指定)
    READY,          // 6 (自动递增)
    DONE            // 7 (自动递增)
  } status;
  
  //================================================================
  // 2. 用于状态机的枚举
  //================================================================
  
  // 有限状态机(FSM)状态定义
  typedef enum bit [3:0] {
    FSM_IDLE     = 4'd0,
    FSM_FETCH    = 4'd1,
    FSM_DECODE   = 4'd2,
    FSM_EXECUTE  = 4'd3,
    FSM_WRITEBACK = 4'd4,
    FSM_ERROR    = 4'd15
  } fsm_state_t;
  
  fsm_state_t current_state;   // 当前状态
  fsm_state_t next_state;      // 下一状态
  
  //================================================================
  // 3. 操作码枚举
  //================================================================
  
  typedef enum bit [5:0] {
    OP_NOP   = 6'b000000,
    OP_ADD   = 6'b100000,
    OP_SUB   = 6'b100010,
    OP_AND   = 6'b100100,
    OP_OR    = 6'b100101,
    OP_XOR   = 6'b100110,
    OP_LOAD  = 6'b110000,
    OP_STORE = 6'b110001
  } opcode_t;
  
  opcode_t instruction;        // 指令操作码
  
  //================================================================
  // 4. 临时变量
  //================================================================
  
  int i;                       // 循环变量
  string enum_name;            // 枚举名称字符串
  
  initial begin
    $display("========================================");
    $display("枚举类型示例 (Enumeration)");
    $display("========================================\n");
    
    //================================================================
    // 示例1: 基本枚举使用
    //================================================================
    $display("【示例1】基本枚举使用");
    $display("----------------------------------------");
    
    // 赋值和使用
    color = RED;
    $display("color = RED");
    $display("  数值: %0d", color);
    $display("  名称: %s", color.name());
    
    color = GREEN;
    $display("\ncolor = GREEN");
    $display("  数值: %0d", color);
    $display("  名称: %s", color.name());
    
    color = BLUE;
    $display("\ncolor = BLUE");
    $display("  数值: %0d", color);
    $display("  名称: %s", color.name());
    
    //================================================================
    // 示例2: 枚举方法
    //================================================================
    $display("\n【示例2】枚举方法");
    $display("----------------------------------------");
    
    color = color.first();  // 获取第一个枚举值
    $display("first() = %s (值=%0d)", color.name(), color);
    
    color = color.last();   // 获取最后一个枚举值
    $display("last()  = %s (值=%0d)", color.name(), color);
    
    color = color.first();
    color = color.next(1);  // 获取下一个枚举值
    $display("next(1) = %s (值=%0d)", color.name(), color);
    
    color = color.last();
    color = color.prev(1);  // 获取前一个枚举值
    $display("prev(1) = %s (值=%0d)", color.name(), color);
    
    $display("\n枚举元素个数: %0d", color.num());
    
    //================================================================
    // 示例3: 状态机枚举
    //================================================================
    $display("\n【示例3】状态机枚举");
    $display("----------------------------------------");
    
    current_state = FSM_IDLE;
    $display("当前状态: %s (值=%0d)", current_state.name(), current_state);
    
    // 状态转换演示
    next_state = FSM_FETCH;
    $display("下一状态: %s (值=%0d)", next_state.name(), next_state);
    
    // 状态序列遍历
    $display("\n状态机状态序列:");
    current_state = current_state.first();
    do begin
      $display("  %s = %0d", current_state.name(), current_state);
      current_state = current_state.next(1);
    end while (current_state != current_state.first());
    
    //================================================================
    // 示例4: 操作码枚举
    //================================================================
    $display("\n【示例4】操作码枚举");
    $display("----------------------------------------");
    
    // 模拟指令执行
    instruction = OP_ADD;
    $display("指令: %s (二进制: %b)", instruction.name(), instruction);
    
    instruction = OP_LOAD;
    $display("指令: %s (二进制: %b)", instruction.name(), instruction);
    
    // 遍历所有操作码
    $display("\n所有操作码列表:");
    instruction = instruction.first();
    for (i = 0; i < instruction.num(); i++) begin
      $display("  [%0d] %s = %b", i, instruction.name(), instruction);
      instruction = instruction.next(1);
    end
    
    //================================================================
    // 示例5: 部分指定值的枚举
    //================================================================
    $display("\n【示例5】部分指定枚举值");
    $display("----------------------------------------");
    
    status = status.first();
    do begin
      $display("  %s = %0d", status.name(), status);
      status = status.next(1);
    end while (status != status.first());
    
    //================================================================
    // 示例6: 枚举类型安全
    //================================================================
    $display("\n【示例6】枚举类型安全");
    $display("----------------------------------------");
    
    // ✅ 正确: 赋值为有效的枚举值
    color = RED;
    $display("color = RED: %s (值=%0d)", color.name(), color);
    
    // ✅ 正确: 使用枚举变量赋值
    enum bit [2:0] {STOP_LIGHT=0, GO_LIGHT=1} traffic_light;
    traffic_light = GO_LIGHT;
    $display("traffic_light = GO_LIGHT: %s (值=%0d)", traffic_light.name(), traffic_light);
    
    // ⚠️ 注意: 直接赋数字会警告,需要类型转换
    // color = 1;  // 警告或错误
    color = color.first().next(1);  // 正确方式
    
    //================================================================
    // 示例7: 枚举在case语句中的应用
    //================================================================
    $display("\n【示例7】枚举在case语句中的应用");
    $display("----------------------------------------");
    
    current_state = FSM_FETCH;
    
    case (current_state)
      FSM_IDLE:    $display("状态机空闲");
      FSM_FETCH:   $display("状态机取指");
      FSM_DECODE:  $display("状态机译码");
      FSM_EXECUTE: $display("状态机执行");
      default:     $display("其他状态");
    endcase
    
    //================================================================
    // 示例8: 实际应用 - 协议状态机
    //================================================================
    $display("\n【示例8】实际应用: 协议状态机");
    $display("----------------------------------------");
    
    // 定义协议状态
    typedef enum bit [2:0] {
      RESET,
      SYN_SENT,
      SYN_RECEIVED,
      ESTABLISHED,
      FIN_WAIT
    } tcp_state_t;
    
    tcp_state_t tcp_state;
    
    tcp_state = RESET;
    $display("TCP状态: %s", tcp_state.name());
    
    // 模拟状态转换
    tcp_state = SYN_SENT;
    $display("TCP状态: %s", tcp_state.name());
    
    tcp_state = ESTABLISHED;
    $display("TCP状态: %s", tcp_state.name());
    
    //================================================================
    // 总结
    //================================================================
    $display("\n【总结】");
    $display("========================================");
    $display("枚举类型的优点:");
    $display("1. 提高代码可读性 - 用名称代替数字");
    $display("2. 类型安全 - 只能赋值有效的枚举值");
    $display("3. 易于维护 - 修改枚举值只需改一处");
    $display("4. 调试友好 - 可打印名称而非数字");
    $display("");
    $display("典型应用场景:");
    $display("- 状态机状态定义");
    $display("- 操作码和指令集");
    $display("- 配置选项和模式选择");
    $display("- 协议状态和消息类型");
    $display("========================================");
    
    $display("\n示例完成!");
  end
  
endmodule
