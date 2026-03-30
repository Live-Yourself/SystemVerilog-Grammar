// =============================================================================
// 知识点10: 参数化的类 - 示例代码
// 基于《SystemVerilog验证 - 测试平台编写指南》第5章
// =============================================================================

// =============================================================================
// 参数化的寄存器类: 值参数示例
// =============================================================================
class Register #(parameter int WIDTH = 8);
  bit [WIDTH-1:0] value;

  function new();
    value = 0;
  endfunction

  function void write(bit [WIDTH-1:0] val);
    value = val;
  endfunction

  function bit [WIDTH-1:0] read();
    return value;
  endfunction

  function void display(string name = "reg");
    $display("  [%s][%0d-bit] value = 0x%0h (%0d)",
             name, WIDTH, value, value);
  endfunction
endclass

// =============================================================================
// 参数化的栈类: 类型参数示例
// =============================================================================
class Stack #(type T = int);
  T    items[$];
  int  max_size;

  function new(int max);
    max_size = max;
  endfunction

  function void push(T item);
    if (items.size() < max_size)
      items.push_back(item);
    else
      $display("  [Stack] 错误: 栈已满(max_size=%0d)", max_size);
  endfunction

  function T pop();
    if (items.size() > 0)
      return items.pop_back();
    else begin
      $display("  [Stack] 错误: 栈为空");
      return items[0];  // 返回默认值
    end
  endfunction

  function void display();
    $display("  [Stack] size=%0d/%0d", items.size(), max_size);
    for (int i = 0; i < items.size(); i++) begin
      $display("    [%0d] = %0s", i, items[i]);
    end
  endfunction
endclass

// =============================================================================
// 参数化的事务类: 多参数示例
// =============================================================================
class BusTransaction #(parameter int ADDR_W = 32,
                       parameter int DATA_W = 32);
  bit [ADDR_W-1:0] addr;
  bit [DATA_W-1:0] data;
  bit              write;

  function new(bit [ADDR_W-1:0] a, bit [DATA_W-1:0] d, bit w);
    addr  = a;
    data  = d;
    write = w;
  endfunction

  function void display();
    $display("  [BusTransaction][A=%0d, D=%0d] addr=0x%0h, data=0x%0h, write=%0d",
             ADDR_W, DATA_W, addr, data, write);
  endfunction
endclass

// =============================================================================
// 示例1: 值参数 -- 不同位宽的寄存器
// =============================================================================
Register #(8)   reg8;
Register #(16)  reg16;
Register #(32)  reg32;

initial begin
  $display("=== 示例1: 值参数 -- 不同位宽的寄存器 ===");

  reg8  = new();
  reg16 = new();
  reg32 = new();

  reg8.write(8'hAB);
  reg16.write(16'h1234);
  reg32.write(32'hDEAD_BEEF);

  reg8.display("reg8");
  reg16.display("reg16");
  reg32.display("reg32");
  $display("");
end

// =============================================================================
// 示例2: 类型参数 -- 不同数据类型的栈
// =============================================================================
Stack #(int)        int_stack;
Stack #(string)     str_stack;
Stack #(bit [7:0])  byte_stack;

initial begin
  $display("=== 示例2: 类型参数 -- 不同数据类型的栈 ===");

  // int类型的栈
  int_stack = new(5);
  $display("  -- int栈 --");
  int_stack.push(10);
  int_stack.push(20);
  int_stack.push(30);
  int_stack.display();
  $display("  pop() = %0d", int_stack.pop());
  int_stack.display();

  // string类型的栈
  str_stack = new(3);
  $display("  -- string栈 --");
  str_stack.push("hello");
  str_stack.push("world");
  str_stack.display();

  // bit[7:0]类型的栈
  byte_stack = new(4);
  $display("  -- bit[7:0]栈 --");
  byte_stack.push(8'hAA);
  byte_stack.push(8'hBB);
  byte_stack.push(8'hCC);
  byte_stack.display();
  $display("");
end

// =============================================================================
// 示例3: 多参数 -- 不同总线宽度的事务
// =============================================================================
BusTransaction #(16, 16)  bus_tr_16;
BusTransaction #(32, 64)  bus_tr_32;
BusTransaction #(64, 128) bus_tr_64;

initial begin
  $display("=== 示例3: 多参数 -- 不同总线宽度的事务 ===");

  bus_tr_16 = new(16'h1000, 16'hABCD, 1);
  bus_tr_32 = new(32'h2000_0000, 64'h1234_5678_9ABC_DEF0, 0);
  bus_tr_64 = new(64'hFFFF_FFFF_FFFF_0000, 128'h0, 1);

  bus_tr_16.display();
  bus_tr_32.display();
  bus_tr_64.display();
  $display("");
end

// =============================================================================
// 示例4: 默认参数 -- 不指定参数使用默认值
// =============================================================================
Register #()  reg_default;  // WIDTH=8(默认)

initial begin
  $display("=== 示例4: 默认参数 ===");

  reg_default = new();
  reg_default.write(8'h55);
  reg_default.display("default");
  $display("");
end

// =============================================================================
// 示例5: 参数不同则类型不同,不能互相赋值
// =============================================================================
Register #(8)  r8_a, r8_b;
Register #(16) r16;

initial begin
  $display("=== 示例5: 参数不同则类型不同 ===");

  r8_a  = new();
  r8_b  = new();
  r16   = new();

  // 同参数: 类型相同,可以赋值(句柄赋值,共享对象)
  r8_b = r8_a;  // 正确: Register#(8) = Register#(8)
  $display("  r8_b = r8_a; // 正确,同类型句柄赋值");

  // 不同参数: 类型不同,不能赋值
  // r16 = r8_a;  // 编译错误! Register#(16) != Register#(8)
  $display("  r16 = r8_a;  // 编译错误! Register#(16) != Register#(8)");
  $display("  参数不同产生不同的类类型,不可互相赋值");
  $display("");
end
