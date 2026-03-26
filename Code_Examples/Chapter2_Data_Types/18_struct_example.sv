// 知识点18: 结构体类型 (Struct)
// 演示packed与unpacked结构体、嵌套结构体、结构体数组

module struct_example;

  // ========== 1. unpacked结构体 (非压缩结构体) ==========
  // 成员独立存储，不能整体作为向量访问
  // 注意: Icarus Verilog对unpacked struct支持有限
  
  typedef struct {
    int    id;              // ID字段
    string name;            // 名称字段
    bit    active;          // 激活标志
  } user_t;
  
  user_t user1;             // 用户1
  user_t user2;             // 用户2

  // ========== 2. packed结构体 (压缩结构体) ==========
  // 成员连续存储，可整体作为向量访问
  // 所有成员必须是bit/logic等标量类型(不能有string等)
  
  typedef struct packed {
    bit         valid;      // 有效位    (1位)
    bit [2:0]   opcode;     // 操作码    (3位)
    bit [3:0]   addr;       // 地址      (4位)
    bit [7:0]   data;       // 数据      (8位)
  } packet_t;               // 总共16位
  
  packet_t pkt_send;        // 发送数据包
  packet_t pkt_recv;        // 接收数据包
  logic [15:0] raw_bits;    // 原始位向量

  // ========== 3. 嵌套结构体 ==========
  // 结构体中包含其他结构体
  
  // 时间戳结构
  typedef struct packed {
    bit [4:0]  hour;        // 小时 (0-23)
    bit [5:0]  minute;      // 分钟 (0-59)
    bit [5:0]  second;      // 秒   (0-59)
  } timestamp_t;
  
  // 带时间戳的数据包
  typedef struct packed {
    packet_t    payload;    // 嵌套: 数据包
    timestamp_t time;       // 嵌套: 时间戳
  } timed_packet_t;
  
  timed_packet_t timed_pkt; // 带时间戳的数据包

  // ========== 4. 结构体数组 ==========
  // 数组的每个元素是一个结构体
  
  typedef struct packed {
    bit [7:0] value;        // 值
    bit       parity;       // 奇偶校验位
  } data_word_t;
  
  data_word_t reg_file[8];  // 寄存器文件: 8个结构体元素
  
  // ========== 5. 匿名结构体 ==========
  // 直接声明结构体变量，不使用typedef
  
  struct packed {
    bit [3:0] cmd;
    bit [3:0] status;
  } control_reg;            // 控制寄存器

  // 循环变量
  int i;
  
  initial begin
    $display("========================================");
    $display("    结构体类型 (Struct) 示例");
    $display("========================================\n");
    
    // ----- 测试unpacked结构体 -----
    $display("【1. unpacked结构体】");
    user1.id     = 1001;
    user1.name   = "Alice";
    user1.active = 1;
    
    user2.id     = 1002;
    user2.name   = "Bob";
    user2.active = 0;
    
    $display("  用户1: ID=%0d, Name=%s, Active=%b", 
             user1.id, user1.name, user1.active);
    $display("  用户2: ID=%0d, Name=%s, Active=%b", 
             user2.id, user2.name, user2.active);
    $display("  特点: 成员独立存储，可包含string等复杂类型");
    $display("");
    
    // ----- 测试packed结构体 -----
    $display("【2. packed结构体】");
    pkt_send.valid  = 1'b1;
    pkt_send.opcode = 3'b010;
    pkt_send.addr   = 4'hA;
    pkt_send.data   = 8'hFF;
    
    $display("  结构体成员访问:");
    $display("    valid  = %b", pkt_send.valid);
    $display("    opcode = %b", pkt_send.opcode);
    $display("    addr   = %h", pkt_send.addr);
    $display("    data   = %h", pkt_send.data);
    
    // packed结构体可整体赋值给向量
    raw_bits = pkt_send;
    $display("  整体作为向量: 0x%h (%b)", raw_bits, raw_bits);
    
    // 向量可整体赋值给packed结构体
    pkt_recv = 16'hB123;
    $display("  从向量赋值: valid=%b, opcode=%b, addr=%h, data=%h",
             pkt_recv.valid, pkt_recv.opcode, pkt_recv.addr, pkt_recv.data);
    $display("  特点: 连续存储，可整体访问，不能含string");
    $display("");
    
    // ----- 测试嵌套结构体 -----
    $display("【3. 嵌套结构体】");
    timed_pkt.payload.valid  = 1'b1;
    timed_pkt.payload.opcode = 3'b101;
    timed_pkt.payload.addr   = 4'h5;
    timed_pkt.payload.data   = 8'hAA;
    timed_pkt.time.hour      = 5'd14;
    timed_pkt.time.minute    = 6'd30;
    timed_pkt.time.second    = 6'd45;
    
    $display("  数据包: valid=%b, opcode=%b, addr=%h, data=%h",
             timed_pkt.payload.valid, timed_pkt.payload.opcode,
             timed_pkt.payload.addr, timed_pkt.payload.data);
    $display("  时间戳: %0d:%0d:%0d",
             timed_pkt.time.hour, timed_pkt.time.minute, timed_pkt.time.second);
    $display("");
    
    // ----- 测试结构体数组 -----
    $display("【4. 结构体数组】");
    // 初始化寄存器文件
    for (i = 0; i < 8; i++) begin
      reg_file[i].value  = i * 16;
      reg_file[i].parity = ^reg_file[i].value;  // 奇偶校验
    end
    
    $display("  寄存器文件内容:");
    for (i = 0; i < 8; i++) begin
      $display("    reg[%0d]: value=%h, parity=%b", 
               i, reg_file[i].value, reg_file[i].parity);
    end
    $display("");
    
    // ----- 测试匿名结构体 -----
    $display("【5. 匿名结构体】");
    control_reg.cmd    = 4'h5;
    control_reg.status = 4'h0;
    $display("  控制寄存器: cmd=%h, status=%h", 
             control_reg.cmd, control_reg.status);
    $display("  (直接声明，无typedef)");
    $display("");
    
    // ----- 结构体操作 -----
    $display("【6. 结构体操作】");
    
    // 结构体整体赋值
    user2 = user1;
    $display("  整体赋值后 user2.name = %s", user2.name);
    
    // packed结构体比较
    pkt_recv = pkt_send;
    if (pkt_recv == pkt_send)
      $display("  结构体比较: pkt_recv == pkt_send (相等)");
    
    // 使用%p格式打印结构体
    $display("  使用%%p打印: pkt_send = %p", pkt_send);
    $display("");
    
    // ----- packed vs unpacked对比 -----
    $display("【7. packed vs unpacked 对比】");
    $display("  ┌─────────────┬─────────────────┬─────────────────┐");
    $display("  │   特性      │  packed         │  unpacked       │");
    $display("  ├─────────────┼─────────────────┼─────────────────┤");
    $display("  │ 存储方式    │ 连续存储        │ 独立存储        │");
    $display("  │ 整体访问    │ 支持            │ 不支持          │");
    $display("  │ 成员类型    │ 仅标量类型      │ 任意类型        │");
    $display("  │ 位操作      │ 支持            │ 不支持          │");
    $display("  │ 硬件映射    │ 直接映射        │ 抽象数据        │");
    $display("  └─────────────┴─────────────────┴─────────────────┘");
    
    $display("\n========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
