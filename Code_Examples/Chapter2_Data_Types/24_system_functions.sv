// 知识点24: 系统函数 (System Functions)
// 演示常用系统函数: $bits, $clog2, $countones, $isunknown, $onehot等

module system_functions;

  // ========== 用于演示的变量 ==========
  logic [31:0] data_bus;        // 32位数据总线
  logic [7:0]  status_reg;      // 8位状态寄存器
  logic [3:0]  flags;           // 4位标志位
  logic        x_val;           // 包含X的值
  logic        z_val;           // 包含Z的值
  
  // 结构体定义
  typedef struct packed {
    logic [15:0] addr;
    logic [7:0]  data;
    logic        valid;
    logic        ready;
  } bus_pkt_t;
  
  bus_pkt_t packet;             // 总线数据包
  
  // 数组定义
  logic [7:0] mem [0:15];       // 16x8存储器
  
  // 循环变量
  int i;
  
  initial begin
    $display("========================================");
    $display("    系统函数 (System Functions) 示例");
    $display("========================================\n");
    
    // ============================================================
    // 一、位宽相关函数
    // ============================================================
    $display("【一、位宽相关函数】\n");
    
    // ----- $bits: 获取位宽 -----
    $display("  1. $bits(expression) - 获取位宽");
    $display("     返回表达式或类型的位宽");
    $display("");
    $display("     示例:");
    
    data_bus = 32'hDEADBEEF;
    $display("       logic [31:0] data_bus;");
    $display("       $bits(data_bus)        = %0d (变量位宽)", $bits(data_bus));
    $display("       $bits(logic [31:0])    = %0d (类型位宽)", $bits(logic [31:0]));
    $display("       $bits(logic [7:0])     = %0d", $bits(logic [7:0]));
    
    // 结构体位宽
    packet.addr  = 16'h1000;
    packet.data  = 8'hA5;
    packet.valid = 1'b1;
    packet.ready = 1'b0;
    $display("");
    $display("       struct packed {addr:16, data:8, valid:1, ready:1}");
    $display("       $bits(packet)          = %0d (结构体总位宽)", $bits(packet));
    $display("       $bits(bus_pkt_s)       = %0d (类型位宽)", $bits(bus_pkt_s));
    
    // 数组位宽
    $display("");
    $display("       logic [7:0] mem [0:15];");
    $display("       $bits(mem)             = %0d (单个元素位宽)", $bits(mem));
    $display("       $bits(mem[0])          = %0d", $bits(mem[0]));
    $display("");
    
    // ----- $clog2: 计算地址位宽 -----
    $display("  2. $clog2(N) - 计算表示N所需的最小位宽");
    $display("     数学含义: ⌈log₂(N)⌉ 向上取整");
    $display("     典型用途: 计算存储器地址位宽");
    $display("");
    $display("     示例:");
    $display("       $clog2(1)   = %0d  (1个数需要0位地址)", $clog2(1));
    $display("       $clog2(2)   = %0d  (2个数需要1位地址)", $clog2(2));
    $display("       $clog2(4)   = %0d  (4个数需要2位地址)", $clog2(4));
    $display("       $clog2(8)   = %0d  (8个数需要3位地址)", $clog2(8));
    $display("       $clog2(9)   = %0d  (9个数需要4位地址)", $clog2(9));
    $display("       $clog2(16)  = %0d  (16个数需要4位地址)", $clog2(16));
    $display("       $clog2(100) = %0d  (100个数需要7位地址)", $clog2(100));
    $display("       $clog2(256) = %0d  (256个数需要8位地址)", $clog2(256));
    $display("");
    $display("     典型应用:");
    $display("       parameter DEPTH = 256;");
    $display("       localparam ADDR_BITS = $clog2(DEPTH);  // = 8");
    $display("       logic [ADDR_BITS-1:0] addr;  // logic [7:0] addr");
    $display("");
    
    // ============================================================
    // 二、位统计函数
    // ============================================================
    $display("\n【二、位统计函数】\n");
    
    // ----- $countones: 统计1的个数 -----
    $display("  3. $countones(expression) - 统计1的个数");
    $display("     返回表达式中值为1的位的数量");
    $display("");
    $display("     示例:");
    
    flags = 4'b1011;
    $display("       flags = 4'b1011");
    $display("       $countones(flags) = %0d (有3个1)", $countones(flags));
    
    data_bus = 32'hFFFF_0000;
    $display("       data_bus = 32'hFFFF_0000");
    $display("       $countones(data_bus) = %0d (有16个1)", $countones(data_bus));
    
    status_reg = 8'b10101010;
    $display("       status_reg = 8'b10101010");
    $display("       $countones(status_reg) = %0d (有4个1)", $countones(status_reg));
    $display("");
    
    // ----- $onehot: 检查是否单热码 -----
    $display("  4. $onehot(expression) - 检查是否单热码");
    $display("     返回: 1=只有一个1, 0=其他情况");
    $display("");
    $display("     示例:");
    
    flags = 4'b0001;
    $display("       flags = 4'b0001 → $onehot = %0d (只有1个1，是单热码)", $onehot(flags));
    
    flags = 4'b0010;
    $display("       flags = 4'b0010 → $onehot = %0d (只有1个1，是单热码)", $onehot(flags));
    
    flags = 4'b0011;
    $display("       flags = 4'b0011 → $onehot = %0d (有2个1，不是单热码)", $onehot(flags));
    
    flags = 4'b0000;
    $display("       flags = 4'b0000 → $onehot = %0d (没有1，不是单热码)", $onehot(flags));
    $display("");
    
    // ----- $onehot0: 检查是否零或单热码 -----
    $display("  5. $onehot0(expression) - 检查是否0个或1个1");
    $display("     返回: 1=0个或1个1, 0=多个1");
    $display("");
    $display("     示例:");
    
    flags = 4'b0000;
    $display("       flags = 4'b0000 → $onehot0 = %0d (0个1)", $onehot0(flags));
    
    flags = 4'b0001;
    $display("       flags = 4'b0001 → $onehot0 = %0d (1个1)", $onehot0(flags));
    
    flags = 4'b0011;
    $display("       flags = 4'b0011 → $onehot0 = %0d (2个1)", $onehot0(flags));
    $display("");
    
    // ============================================================
    // 三、X/Z检测函数
    // ============================================================
    $display("\n【三、X/Z检测函数】\n");
    
    // ----- $isunknown: 检测X或Z -----
    $display("  6. $isunknown(expression) - 检测是否包含X或Z");
    $display("     返回: 1=包含X或Z, 0=全是0/1");
    $display("");
    $display("     示例:");
    
    data_bus = 32'h0000_0001;
    $display("       data_bus = 32'h0000_0001 → $isunknown = %0d", $isunknown(data_bus));
    
    data_bus = 32'h0000_000X;
    $display("       data_bus = 32'h0000_000X → $isunknown = %0d (包含X)", $isunknown(data_bus));
    
    data_bus = 32'hZZZZ_0000;
    $display("       data_bus = 32'hZZZZ_0000 → $isunknown = %0d (包含Z)", $isunknown(data_bus));
    
    flags = 4'b10X0;
    $display("       flags = 4'b10X0 → $isunknown = %0d (包含X)", $isunknown(flags));
    $display("");
    $display("     典型应用:");
    $display("       if ($isunknown(data_in))");
    $display("         $error(\"输入数据包含未知态!\");");
    $display("");
    
    // ============================================================
    // 四、范围相关函数
    // ============================================================
    $display("\n【四、范围相关函数】\n");
    
    // ----- $high/$low/$left/$right/$size/$increment -----
    $display("  7. 数组范围函数:");
    $display("");
    
    // 非压缩数组
    logic [7:0] arr_high [15:0];  // 索引15到0
    logic [7:0] arr_low  [0:15];  // 索引0到15
    
    $display("     logic [7:0] arr_high [15:0];  // 索引递减");
    $display("       $left(arr_high)  = %0d (左边界)", $left(arr_high));
    $display("       $right(arr_high) = %0d (右边界)", $right(arr_high));
    $display("       $low(arr_high)   = %0d (最小索引)", $low(arr_high));
    $display("       $high(arr_high)  = %0d (最大索引)", $high(arr_high));
    $display("       $size(arr_high)  = %0d (元素个数)", $size(arr_high));
    $display("       $increment(arr_high) = %0d (递增方向: -1递减)", $increment(arr_high));
    $display("");
    $display("     logic [7:0] arr_low [0:15];   // 索引递增");
    $display("       $left(arr_low)  = %0d (左边界)", $left(arr_low));
    $display("       $right(arr_low) = %0d (右边界)", $right(arr_low));
    $display("       $low(arr_low)   = %0d (最小索引)", $low(arr_low));
    $display("       $high(arr_low)  = %0d (最大索引)", $high(arr_low));
    $display("       $size(arr_low)  = %0d (元素个数)", $size(arr_low));
    $display("       $increment(arr_low) = %0d (递增方向: +1递增)", $increment(arr_low));
    $display("");
    
    // 压缩数组
    logic [15:0] packed_arr;
    $display("     logic [15:0] packed_arr;      // 压缩数组");
    $display("       $left(packed_arr)  = %0d", $left(packed_arr));
    $display("       $right(packed_arr) = %0d", $right(packed_arr));
    $display("       $bits(packed_arr)  = %0d", $bits(packed_arr));
    $display("");
    
    // ============================================================
    // 五、系统函数汇总表
    // ============================================================
    $display("\n【五、系统函数汇总表】\n");
    $display("  ┌───────────────┬─────────────────────────────────────────┐");
    $display("  │ 函数          │ 功能                                    │");
    $display("  ├───────────────┼─────────────────────────────────────────┤");
    $display("  │ $bits(x)      │ 返回位宽                                │");
    $display("  │ $clog2(N)     │ 返回⌈log₂(N)⌉，计算地址位宽            │");
    $display("  │ $countones(x) │ 统计1的个数                             │");
    $display("  │ $onehot(x)    │ 检查是否单热码(只有1个1)               │");
    $display("  │ $onehot0(x)   │ 检查是否0或单热码(0或1个1)              │");
    $display("  │ $isunknown(x) │ 检查是否包含X或Z                        │");
    $display("  │ $left(arr)    │ 数组左边界                              │");
    $display("  │ $right(arr)   │ 数组右边界                              │");
    $display("  │ $low(arr)     │ 数组最小索引                            │");
    $display("  │ $high(arr)    │ 数组最大索引                            │");
    $display("  │ $size(arr)    │ 数组元素个数                            │");
    $display("  │ $increment    │ 数组递增方向(+1/-1)                     │");
    $display("  └───────────────┴─────────────────────────────────────────┘");
    
    $display("\n========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
