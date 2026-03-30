//==============================================================================
// 文件名: 01_class_definition.sv
// 知识点: 类的定义与实例化
// 章节: 第5章 - 类基础
// 说明: 演示类的基本定义、句柄声明和对象创建
//==============================================================================

// =============================================================================
// 知识点讲解:
// SystemVerilog中的类使用class/endclass定义
// 创建对象分为两步:
//   1. 声明句柄(不分配内存)
//   2. 调用new()构造对象(分配内存)
// =============================================================================

// 定义一个简单的类: Transaction(事务)
class Transaction;
  // 成员变量(属性)
  bit [31:0] addr;
  bit [31:0] data;
  bit        write;  // 0=read, 1=write
  
  // 成员方法: 显示事务信息
  function void display();
    $display("Transaction:");
    $display("  addr  = 0x%08h", addr);
    $display("  data  = 0x%08h", data);
    $display("  write = %0b (%s)", write, write ? "WRITE" : "READ");
  endfunction
  
  // 成员方法: 初始化事务
  function void init(bit [31:0] a, bit [31:0] d, bit w);
    addr  = a;
    data  = d;
    write = w;
  endfunction
endclass

// =============================================================================
// 测试程序
// =============================================================================
module class_definition_test;

  // 步骤1: 声明句柄(此时不分配内存)
  Transaction trans1;  // 句柄trans1,初始值为null
  Transaction trans2;  // 句柄trans2,初始值为null
  
  initial begin
    $display("========================================");
    $display("示例1: 类的定义与实例化");
    $display("========================================\n");
    
    // 演示: 声明后句柄为null
    $display("1. 声明句柄后:");
    if (trans1 == null)
      $display("   trans1 = null (尚未指向对象)");
    else
      $display("   trans1 指向对象");
    
    $display("\n2. 创建第一个对象:");
    // 步骤2: 构造对象
    trans1 = new();  // 分配内存,返回对象地址
    
    // 初始化事务
    trans1.init(32'h1000_0000, 32'hDEAD_BEEF, 1);
    trans1.display();
    
    $display("\n3. 创建第二个对象:");
    // 可以在声明时直接构造
    trans2 = new();
    trans2.init(32'h2000_0000, 32'hCAFEBABE, 0);
    trans2.display();
    
    $display("\n4. 多个句柄指向同一对象:");
    Transaction trans3;  // 声明新句柄
    trans3 = trans1;     // trans3和trans1指向同一对象
    $display("   trans1 和 trans3 指向同一对象");
    trans3.addr = 32'h3000_0000;  // 通过trans3修改
    $display("   通过trans3修改addr后:");
    trans1.display();  // trans1也看到变化
    
    $display("\n========================================");
    $display("关键要点:");
    $display("1. 类使用class/endclass定义");
    $display("2. 声明句柄不分配内存,初始为null");
    $display("3. new()构造对象,分配内存");
    $display("4. 句柄赋值是引用复制,不是对象复制");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
// 编译器: QuestaSim, VCS, Xcelium等支持SystemVerilog的仿真器
// 编译命令示例(QuestaSim):
//   vlog 01_class_definition.sv
//   vsim -novopt class_definition_test -do "run -all"
//==============================================================================
