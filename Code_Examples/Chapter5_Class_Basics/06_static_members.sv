//==============================================================================
// 文件名: 06_static_members.sv
// 知识点: 静态变量与静态方法 (static)
// 章节: 第5章 - 类基础
// 说明: 演示静态变量的共享特性、对象计数器、全局配置、静态方法
//==============================================================================

// =============================================================================
// 类1: Packet -- 演示静态变量实现对象计数器和唯一ID
// =============================================================================
class Packet;
  bit [31:0] data;
  int        id;

  // 静态变量: 所有Packet对象共享
  static int total_count = 0;

  function new(bit [31:0] d);
    data = d;
    total_count = total_count + 1;  // 每创建一个对象,计数器+1
    id = total_count;               // 用静态变量生成唯一ID
  endfunction

  function void display();
    $display("    Packet[ID=%0d]: data=0x%08h", id, data);
  endfunction

  // 静态方法: 只能访问静态成员,不能访问data/id等实例成员
  static function int get_total_count();
    return total_count;
  endfunction
endclass

// =============================================================================
// 类2: Config -- 演示静态变量用于全局配置
// =============================================================================
class Config;
  // 静态变量: 全局配置参数
  static bit [31:0] base_addr = 32'h0000_0000;
  static int         timeout   = 1000;
  static bit         verbose   = 0;

  // 静态方法: 设置和读取配置
  static function void set_base_addr(bit [31:0] addr);
    base_addr = addr;
  endfunction

  static function void set_timeout(int t);
    timeout = t;
  endfunction

  static function void display();
    $display("    Config: base_addr=0x%08h, timeout=%0d, verbose=%0b",
             base_addr, timeout, verbose);
  endfunction
endclass

// =============================================================================
// 测试程序
// =============================================================================
module static_members_test;

  Packet pkt1;
  Packet pkt2;
  Packet pkt3;

  initial begin
    $display("========================================");
    $display(" 知识点6: 静态变量与静态方法");
    $display("========================================\n");

    // =====================================================================
    // 示例1: 静态变量 -- 所有对象共享同一份
    // =====================================================================
    $display("--- 示例1: 静态变量的共享特性 ---");
    $display("创建前: Packet::total_count = %0d", Packet::total_count);

    pkt1 = new(32'h11111111);
    $display("创建pkt1后: Packet::total_count = %0d", Packet::total_count);
    pkt1.display();

    pkt2 = new(32'h22222222);
    $display("创建pkt2后: Packet::total_count = %0d", Packet::total_count);
    pkt2.display();

    pkt3 = new(32'h33333333);
    $display("创建pkt3后: Packet::total_count = %0d", Packet::total_count);
    pkt3.display();

    $display("通过不同对象访问静态变量(值相同):");
    $display("  pkt1通过句柄: total_count = %0d", pkt1.total_count);
    $display("  pkt2通过句柄: total_count = %0d", pkt2.total_count);
    $display("  通过类名访问: Packet::total_count = %0d", Packet::total_count);
    $display("  → 三种方式访问的是同一个变量\n");

    // =====================================================================
    // 示例2: 静态变量实现对象计数器和唯一ID
    // =====================================================================
    $display("--- 示例2: 对象计数器与唯一ID ---");
    $display("每个对象在构造函数中获得唯一ID:");
    $display("  pkt1.id = %0d", pkt1.id);
    $display("  pkt2.id = %0d", pkt2.id);
    $display("  pkt3.id = %0d", pkt3.id);
    $display("  → id来自静态变量total_count, 保证唯一\n");

    // =====================================================================
    // 示例3: 静态方法 -- 通过类名调用
    // =====================================================================
    $display("--- 示例3: 静态方法 ---");
    $display("通过类名调用静态方法:");
    $display("  Packet::get_total_count() = %0d", Packet::get_total_count());
    $display("  → 静态方法不需要创建对象就能调用\n");

    // =====================================================================
    // 示例4: 静态变量用于全局配置
    // =====================================================================
    $display("--- 示例4: 静态变量用于全局配置 ---");
    $display("默认配置:");
    Config::display();

    $display("修改全局配置:");
    Config::set_base_addr(32'h8000_0000);
    Config::set_timeout(5000);
    Config::verbose = 1;
    Config::display();

    $display("在任何地方都可以通过类名访问配置:");
    $display("  Config::base_addr = 0x%08h", Config::base_addr);
    $display("  Config::timeout   = %0d", Config::timeout);
    $display("  → 静态变量充当全局变量, 无需传递对象句柄\n");

    // =====================================================================
    // 示例5: 实例变量 vs 静态变量对比
    // =====================================================================
    $display("--- 示例5: 实例变量 vs 静态变量 ---");
    $display("实例变量: 每个对象独立");
    $display("  pkt1.data = 0x%08h", pkt1.data);
    $display("  pkt2.data = 0x%08h", pkt2.data);
    $display("  → 各自不同");

    $display("静态变量: 所有对象共享");
    $display("  pkt1.total_count = %0d", pkt1.total_count);
    $display("  pkt2.total_count = %0d", pkt2.total_count);
    $display("  → 始终相同\n");

    // =====================================================================
    $display("========================================");
    $display(" 关键要点:");
    $display("  1. static变量属于类级别, 所有对象共享");
    $display("  2. static变量初始化只执行一次(类加载时)");
    $display("  3. 访问方式: 类名::变量名 (推荐)");
    $display("  4. static方法只能访问static成员, 不能用this");
    $display("  5. 典型用途: 对象计数/唯一ID/全局配置");
    $display("========================================");

    $finish;
  end

endmodule

//==============================================================================
// 编译运行:
//   vlog 06_static_members.sv
//   vsim -novopt static_members_test -do "run -all"
//==============================================================================
