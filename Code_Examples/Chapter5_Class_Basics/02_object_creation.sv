//==============================================================================
// 文件名: 02_object_creation.sv
// 知识点: 对象的动态创建 - new()构造函数
// 章节: 第5章 - 类基础
// 说明: 演示构造函数的定义、重载和使用
//==============================================================================

// =============================================================================
// 知识点讲解:
// 1. 构造函数名必须为new(),用于初始化对象
// 2. 不定义时使用默认无参构造函数
// 3. 支持构造函数重载(不同参数列表)
// 4. 构造函数在对象创建时自动调用
// =============================================================================

// =============================================================================
// 示例1: 默认构造函数
// =============================================================================
class SimplePacket;
  bit [7:0] data;
  bit       valid;
  
  // 不定义构造函数,使用默认的new()
  // 默认构造函数:
  // function new();
  //   // 空实现
  // endfunction
endclass

// =============================================================================
// 示例2: 自定义无参构造函数
// =============================================================================
class ConfigPacket;
  bit [31:0] addr;
  bit [31:0] data;
  bit        write;
  
  // 自定义无参构造函数 - 初始化所有成员
  function new();
    addr  = 32'h0000_0000;
    data  = 32'h0000_0000;
    write = 0;
    $display("[ConfigPacket] Object created with default values");
  endfunction
  
  function void display();
    $display("ConfigPacket: addr=0x%08h, data=0x%08h, write=%0b", 
             addr, data, write);
  endfunction
endclass

// =============================================================================
// 示例3: 带参数的构造函数
// =============================================================================
class Transaction;
  bit [31:0] addr;
  bit [31:0] data;
  bit        write;
  int        id;
  
  // 带参数的构造函数 - 初始化时设置所有字段
  function new(input bit [31:0] a, input bit [31:0] d, input bit w, input int i);
    addr  = a;
    data  = d;
    write = w;
    id    = i;
    $display("[Transaction] ID=%0d created: addr=0x%08h, data=0x%08h, write=%0b", 
             id, addr, data, write);
  endfunction
  
  function void display();
    $display("Transaction[ID=%0d]: addr=0x%08h, data=0x%08h, write=%0b", 
             id, addr, data, write);
  endfunction
endclass

// =============================================================================
// 示例4: 构造函数重载
// =============================================================================
class FlexiblePacket;
  bit [7:0] payload[];
  bit       valid;
  string    name;
  
  // 构造函数1: 无参数 - 创建默认包
  function new();
    payload = new[8];  // 默认8字节
    valid   = 0;
    name    = "DefaultPacket";
    $display("[FlexiblePacket] Created default packet: size=8, name=%s", name);
  endfunction
  
  // 构造函数2: 指定大小
  function new(input int size);
    payload = new[size];
    valid   = 0;
    name    = $sformatf("Size%0dPacket", size);
    $display("[FlexiblePacket] Created packet: size=%0d, name=%s", size, name);
  endfunction
  
  // 构造函数3: 指定数据和名称
  function new(input bit [7:0] data[], input string n);
    payload = data;
    valid   = 1;
    name    = n;
    $display("[FlexiblePacket] Created packet: size=%0d, name=%s, valid=%0b", 
             payload.size(), name, valid);
  endfunction
  
  function void display();
    $display("FlexiblePacket[%s]: size=%0d, valid=%0b", name, payload.size(), valid);
  endfunction
endclass

// =============================================================================
// 示例5: 构造函数中使用this关键字
// =============================================================================
class DataPacket;
  bit [31:0] addr;
  bit [31:0] data;
  
  // 使用this区分成员变量和参数
  function new(input bit [31:0] addr, input bit [31:0] data);
    this.addr = addr;  // this.addr是成员变量,addr是参数
    this.data = data;  // this.data是成员变量,data是参数
    $display("[DataPacket] Created: addr=0x%08h, data=0x%08h", this.addr, this.data);
  endfunction
  
  function void display();
    $display("DataPacket: addr=0x%08h, data=0x%08h", addr, data);
  endfunction
endclass

// =============================================================================
// 测试程序
// =============================================================================
module object_creation_test;

  // 声明句柄(不分配内存)
  SimplePacket    simple;
  ConfigPacket    config1, config2;
  Transaction     trans1, trans2;
  FlexiblePacket  flex1, flex2, flex3;
  DataPacket      data_pkt;

  initial begin
    $display("========================================");
    $display("知识点2: 对象的动态创建 - new()构造函数");
    $display("========================================\n");
    
    // -------------------------------------------------------------------------
    $display("【示例1】默认构造函数:");
    $display("----------------------------------------");
    simple = new();  // 使用默认构造函数
    $display("simple.data = 0x%02h, simple.valid = %0b", simple.data, simple.valid);
    $display("  (默认构造函数不初始化,成员为默认值)\n");
    
    // -------------------------------------------------------------------------
    $display("【示例2】自定义无参构造函数:");
    $display("----------------------------------------");
    config1 = new();  // 调用自定义无参构造函数
    config1.display();
    
    config2 = new();
    config2.addr  = 32'h1000_0000;
    config2.data  = 32'hDEAD_BEEF;
    config2.write = 1;
    config2.display();
    $display("");
    
    // -------------------------------------------------------------------------
    $display("【示例3】带参数的构造函数:");
    $display("----------------------------------------");
    trans1 = new(32'h2000_0000, 32'hCAFEBABE, 1, 1);  // 创建时指定所有参数
    trans2 = new(32'h3000_0000, 32'h12345678, 0, 2);
    trans1.display();
    trans2.display();
    $display("");
    
    // -------------------------------------------------------------------------
    $display("【示例4】构造函数重载:");
    $display("----------------------------------------");
    // 调用不同的构造函数
    flex1 = new();                                      // 无参构造
    flex1.display();
    
    flex2 = new(16);                                    // 指定大小
    flex2.display();
    
    flex3 = new('{8'hAA, 8'hBB, 8'hCC, 8'hDD}, "CustomPacket"); // 指定数据和名称
    flex3.display();
    $display("");
    
    // -------------------------------------------------------------------------
    $display("【示例5】构造函数中使用this关键字:");
    $display("----------------------------------------");
    data_pkt = new(32'h4000_0000, 32'hFEEDFACE);
    data_pkt.display();
    $display("");
    
    // -------------------------------------------------------------------------
    $display("========================================");
    $display("关键要点总结:");
    $display("========================================");
    $display("1. 构造函数名必须为new()");
    $display("2. 不定义时使用默认无参构造函数");
    $display("3. 可自定义构造函数实现对象初始化");
    $display("4. 支持构造函数重载(不同参数列表)");
    $display("5. 构造函数在对象创建时自动执行一次");
    $display("6. 使用this关键字区分成员变量和参数");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
// 编译器: QuestaSim, VCS, Xcelium等支持SystemVerilog的仿真器
// 编译命令示例(QuestaSim):
//   vlog 02_object_creation.sv
//   vsim -novopt object_creation_test -do "run -all"
//==============================================================================
