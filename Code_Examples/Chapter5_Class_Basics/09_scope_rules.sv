// =============================================================================
// 知识点9: 类的作用域 - 示例代码
// 基于《SystemVerilog验证 - 测试平台编写指南》第5章
// =============================================================================

// $unit作用域: 编译单元级别的声明
typedef enum { READ, WRITE, IDLE } op_t;
int global_counter = 0;

// 基础Transaction类
class Transaction;
  // 类作用域: 成员变量
  bit [31:0] addr;
  bit [31:0] data;
  op_t        op;        // 使用$unit作用域中定义的类型

  // 类作用域内的嵌套类型定义
  typedef enum { INIT, RUNNING, DONE } state_t;
  state_t state;

  function new(bit [31:0] addr, bit [31:0] data, op_t op);
    this.addr = addr;
    this.data = data;
    this.op   = op;
    this.state = INIT;
  endfunction

  function void display();
    $display("  [Transaction] addr=0x%08h, data=0x%08h, op=%0s, state=%0s",
             addr, data, op.name(), state.name());
  endfunction

  // 演示: 局部变量与成员变量同名 → 遮蔽
  function void shadow_demo(bit [31:0] addr);
    // 参数addr遮蔽了成员addr
    $display("  [遮蔽演示] 不带this的addr = 0x%08h (局部参数)", addr);
    $display("  [遮蔽演示] this.addr     = 0x%08h (成员变量)", this.addr);
    this.addr = addr;  // 用this消除遮蔽,赋值给成员
    $display("  [遮蔽演示] 赋值后 this.addr = 0x%08h", this.addr);
  endfunction

  // 演示: 局部变量仅在本方法内可见
  function void local_scope_demo();
    int temp;  // 局部变量
    temp = addr + data;
    $display("  [局部作用域] temp = addr + data = 0x%08h + 0x%08h = 0x%08h",
             addr, data, temp);
  endfunction

  function void other_method();
    // temp在此不可见! 它是local_scope_demo的局部变量
    $display("  [局部作用域] 在other_method中可以直接访问成员: addr=0x%08h", addr);
  endfunction
endclass

// =============================================================================
// 示例1: 类作用域 vs 方法作用域 vs $unit作用域
// =============================================================================
Transaction tr1;

initial begin
  $display("=== 示例1: 三层作用域演示 ===");

  tr1 = new(32'h1000, 32'hABCD, READ);
  tr1.display();

  // $unit作用域的变量
  $display("  [$unit作用域] global_counter = %0d", global_counter);

  // 类作用域内的嵌套类型
  $display("  [类作用域嵌套类型] Transaction::INIT   = %0d", Transaction::INIT);
  $display("  [类作用域嵌套类型] Transaction::RUNNING = %0d", Transaction::RUNNING);
  $display("  [类作用域嵌套类型] Transaction::DONE   = %0d", Transaction::DONE);
  $display("");
end

// =============================================================================
// 示例2: 局部变量遮蔽成员变量
// =============================================================================
Transaction tr2;

initial begin
  $display("=== 示例2: 局部变量遮蔽成员变量 ===");

  tr2 = new(32'h5000, 32'h1234, WRITE);
  $display("调用前成员addr:");
  tr2.display();

  $display("调用shadow_demo(0xAABB) - 参数addr遮蔽成员addr:");
  tr2.shadow_demo(32'hAABB);

  $display("调用后成员addr:");
  tr2.display();
  $display("");
end

// =============================================================================
// 示例3: 局部变量仅在本方法内可见
// =============================================================================
Transaction tr3;

initial begin
  $display("=== 示例3: 局部变量仅在声明它的方法内可见 ===");

  tr3 = new(32'h2000, 32'h3000, READ);
  tr3.local_scope_demo();
  tr3.other_method();  // other_method无法访问temp
  $display("");
end

// =============================================================================
// 示例4: begin/end块中的嵌套作用域
// =============================================================================
initial begin
  $display("=== 示例4: begin/end块中的嵌套作用域 ===");

  begin
    int x = 10;
    $display("  外层: x = %0d", x);
    begin
      int x = 20;  // 内层x遮蔽外层x
      $display("  内层: x = %0d (遮蔽了外层)", x);
    end
    $display("  外层: x = %0d (不受内层影响)", x);
  end
  $display("");
end

// =============================================================================
// 示例5: 不同方法的同名局部变量互不影响
// =============================================================================
Transaction tr5;

initial begin
  $display("=== 示例5: $unit作用域的枚举类型在类中使用 ===");

  tr5 = new(32'h3000, 32'h4000, IDLE);
  $display("  Transaction使用$unit中定义的op_t:");
  tr5.display();

  // 直接使用$unit作用域的枚举
  $display("  直接访问$unit枚举: READ=%0d, WRITE=%0d, IDLE=%0d",
           READ, WRITE, IDLE);
  $display("");
end
