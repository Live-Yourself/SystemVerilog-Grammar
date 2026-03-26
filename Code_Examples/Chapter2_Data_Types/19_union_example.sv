// 知识点19: 联合体类型 (Union)
// 演示packed联合体、unpacked联合体、结构体与联合体的配合使用

module union_example;

  // ========== 1. unpacked联合体 (非压缩联合体) ==========
  // 成员共享存储空间，但只能同时使用一个
  // 所有成员从同一地址开始存储
  
  typedef union {
    int   i_value;        // 整数视图 (4字节)
    real  r_value;        // 实数视图 (8字节)
    byte  b_array[4];     // 字节数组视图 (4字节)
  } data_union_t;
  
  data_union_t data1;     // 联合体变量

  // ========== 2. packed联合体 (压缩联合体) ==========
  // 所有成员位宽必须相同，共享同一存储空间
  // 可整体作为向量访问
  
  typedef union packed {
    logic [31:0] word;    // 32位整体视图
    logic [7:0]  bytes[4];// 4字节视图
    struct packed {
      logic [15:0] low;   // 低16位
      logic [15:0] high;  // 高16位
    } halves;             // 半字视图
  } word_view_t;
  
  word_view_t cpu_data;   // CPU数据视图

  // ========== 3. tagged联合体 (带标签联合体) ==========
  // SystemVerilog特性，存储当前活动成员信息
  // 注意: 部分仿真器可能不支持
  
  // typedef union tagged {
  //   void Invalid;          // 无效状态
  //   int  IntValue;         // 整数值
  //   real RealValue;        // 实数值
  // } tagged_data_t;

  // ========== 4. 协议数据包视图 ==========
  // 同一数据的不同协议解析视图
  
  typedef struct packed {
    logic       sop;      // 包头
    logic [7:0] data;     // 数据
    logic       eop;      // 包尾
  } simple_pkt_t;         // 简单数据包 (10位)
  
  typedef union packed {
    simple_pkt_t packet;  // 数据包视图
    logic [9:0]  raw;     // 原始位视图
    struct packed {
      logic [1:0] ctrl;   // 控制位
      logic [7:0] payload;// 有效载荷
    } fields;             // 字段视图
  } bus_data_t;
  
  bus_data_t bus_line;    // 总线数据

  // ========== 5. 寄存器多视图访问 ==========
  // 同一寄存器的不同位域访问
  
  typedef union packed {
    logic [31:0] full;    // 完整32位访问
    struct packed {
      logic [7:0]  byte0; // 字节0
      logic [7:0]  byte1; // 字节1
      logic [7:0]  byte2; // 字节2
      logic [7:0]  byte3; // 字节3
    } bytes;              // 按字节访问
    struct packed {
      logic        enable;  // 使能位
      logic        irq;     // 中断请求
      logic [5:0]  reserved;// 保留
      logic [23:0] value;   // 数值
    } cfg;                // 配置域访问
  } reg_view_t;
  
  reg_view_t control_reg; // 控制寄存器

  // 循环变量
  int i;
  
  initial begin
    $display("========================================");
    $display("    联合体类型 (Union) 示例");
    $display("========================================\n");
    
    // ----- 测试unpacked联合体 -----
    $display("【1. unpacked联合体】");
    $display("  特点: 成员共享存储空间，只能同时使用一个");
    
    // 使用整数视图
    data1.i_value = 32'h12345678;
    $display("  存储整数值: i_value = 0x%h", data1.i_value);
    
    // 切换到实数视图 (之前的数据不再有效)
    data1.r_value = 3.14159;
    $display("  切换到实数: r_value = %f", data1.r_value);
    $display("  注意: 此时i_value内容已改变");
    $display("");
    
    // ----- 测试packed联合体 -----
    $display("【2. packed联合体】");
    $display("  特点: 所有成员位宽相同，可整体访问");
    
    // 使用word视图写入
    cpu_data.word = 32'hDEADBEEF;
    $display("  整体视图: word = 0x%h", cpu_data.word);
    
    // 字节视图读取
    $display("  字节视图:");
    for (i = 0; i < 4; i++) begin
      $display("    bytes[%0d] = 0x%h", i, cpu_data.bytes[i]);
    end
    
    // 半字视图读取
    $display("  半字视图:");
    $display("    high = 0x%h, low = 0x%h", 
             cpu_data.halves.high, cpu_data.halves.low);
    $display("");
    
    // ----- 测试协议数据包视图 -----
    $display("【3. 协议数据包视图】");
    
    // 作为数据包写入
    bus_line.packet.sop  = 1'b1;
    bus_line.packet.data = 8'hA5;
    bus_line.packet.eop  = 1'b0;
    
    $display("  数据包视图:");
    $display("    sop=%b, data=0x%h, eop=%b", 
             bus_line.packet.sop, bus_line.packet.data, bus_line.packet.eop);
    
    // 作为原始位读取
    $display("  原始位视图: raw = %b (共%0d位)", 
             bus_line.raw, $bits(bus_line.raw));
    
    // 作为字段视图读取
    $display("  字段视图:");
    $display("    ctrl=%b, payload=0x%h", 
             bus_line.fields.ctrl, bus_line.fields.payload);
    $display("");
    
    // ----- 测试寄存器多视图访问 -----
    $display("【4. 寄存器多视图访问】");
    
    // 按配置域写入
    control_reg.cfg.enable   = 1'b1;
    control_reg.cfg.irq      = 1'b0;
    control_reg.cfg.reserved = 6'h0;
    control_reg.cfg.value    = 24'hABCDEF;
    
    $display("  配置域写入:");
    $display("    enable=%b, irq=%b, value=0x%h",
             control_reg.cfg.enable, control_reg.cfg.irq, control_reg.cfg.value);
    
    // 完整32位读取
    $display("  完整寄存器: 0x%h", control_reg.full);
    
    // 按字节读取
    $display("  字节视图:");
    $display("    byte3=0x%h, byte2=0x%h, byte1=0x%h, byte0=0x%h",
             control_reg.bytes.byte3, control_reg.bytes.byte2,
             control_reg.bytes.byte1, control_reg.bytes.byte0);
    $display("");
    
    // ----- Union vs Struct 对比 -----
    $display("【5. Union vs Struct 对比】");
    $display("  ┌─────────────┬─────────────────┬─────────────────┐");
    $display("  │   特性      │  Struct         │  Union          │");
    $display("  ├─────────────┼─────────────────┼─────────────────┤");
    $display("  │ 存储方式    │ 成员顺序存储    │ 成员共享存储    │");
    $display("  │ 空间占用    │ 所有成员之和    │ 最大成员大小    │");
    $display("  │ 同时使用    │ 所有成员可用    │ 只能用一个      │");
    $display("  │ 典型用途    │ 数据组合        │ 数据视图切换    │");
    $display("  └─────────────┴─────────────────┴─────────────────┘");
    $display("");
    
    // ----- 联合体典型应用 -----
    $display("【6. 联合体典型应用】");
    $display("  ✓ 寄存器多视图访问 (字节/字/位域)");
    $display("  ✓ 协议数据包解析 (不同协议头)");
    $display("  ✓ 大小端转换");
    $display("  ✓ CPU数据总线模拟");
    $display("  ✓ 内存位模式查看");
    $display("");
    
    // ----- 使用注意事项 -----
    $display("【7. 使用注意事项】");
    $display("  ⚠ 联合体不跟踪当前活动成员");
    $display("  ⚠ 程序员需自行管理使用哪个成员");
    $display("  ⚠ 误用成员会导致数据错误");
    $display("  ⚠ packed联合体成员位宽必须相同");
    $display("  ⚠ unpacked联合体可以有不同大小成员");
    
    $display("\n========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
