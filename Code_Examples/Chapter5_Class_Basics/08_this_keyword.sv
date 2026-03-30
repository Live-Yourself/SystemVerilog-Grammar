// =============================================================================
// 知识点8: this关键字 - 示例代码
// 基于《SystemVerilog验证 - 测试平台编写指南》第5章
// =============================================================================

// 基础Transaction类,贯穿所有示例
class Transaction;
  bit [31:0] addr;
  bit [31:0] data;
  bit        write;

  // 构造函数: 使用this区分同名参数和成员变量
  function new(bit [31:0] addr, bit [31:0] data, bit write);
    this.addr  = addr;
    this.data  = data;
    this.write = write;
  endfunction

  // display方法: 隐式使用this
  function void display();
    $display("  [Transaction] addr=0x%08h, data=0x%08h, write=%0d", addr, data, write);
  endfunction

  // set方法: 使用this区分同名参数
  function void set(bit [31:0] addr, bit [31:0] data);
    this.addr = addr;
    this.data = data;
  endfunction

  // copy方法: 使用this引用源对象
  function Transaction copy();
    Transaction t = new(this.addr, this.data, this.write);
    return t;
  endfunction

  // 链式set方法: 返回this实现链式调用
  function Transaction set_addr(bit [31:0] addr);
    this.addr = addr;
    return this;
  endfunction

  function Transaction set_data(bit [31:0] data);
    this.data = data;
    return this;
  endfunction

  function Transaction set_write(bit w);
    this.write = w;
    return this;
  endfunction
endclass

// Monitor类: 用于演示this作为参数传递
class Monitor;
  function void register(Transaction tr);
    $display("  [Monitor] 收到注册, addr=0x%08h", tr.addr);
  endfunction
endclass

// =============================================================================
// 示例1: this在构造函数中区分同名变量
// =============================================================================
Transaction tr1;
Monitor    mon1;

initial begin
  $display("=== 示例1: this在构造函数中区分同名变量 ===");

  tr1 = new(32'h1000, 32'hABCD, 1);
  $display("构造完成:");
  tr1.display();

  // 使用set方法(参数名与成员名相同)
  tr1.set(32'h2000, 32'h1234);
  $display("set(0x2000, 0x1234)后:");
  tr1.display();
  $display("");
end

// =============================================================================
// 示例2: this在copy()方法中引用源对象
// =============================================================================
Transaction tr2, tr2_copy;

initial begin
  $display("=== 示例2: this在copy()方法中引用源对象 ===");

  tr2 = new(32'h5000, 32'hFFFF, 0);
  $display("原始对象:");
  tr2.display();

  tr2_copy = tr2.copy();  // copy()内部this指向tr2
  $display("复制后副本:");
  tr2_copy.display();

  // 修改副本,验证独立性
  tr2_copy.addr = 32'h9999;
  $display("修改副本addr后:");
  $display("  原始: addr=0x%08h", tr2.addr);
  $display("  副本: addr=0x%08h", tr2_copy.addr);
  $display("");
end

// =============================================================================
// 示例3: 链式调用 - 返回this实现连续调用
// =============================================================================
Transaction tr3;

initial begin
  $display("=== 示例3: 链式调用 ===");

  tr3 = new(0, 0, 0);
  $display("初始状态:");
  tr3.display();

  // 每个set方法返回this,可以连续调用
  tr3.set_addr(32'h3000).set_data(32'hBEEF).set_write(1);
  $display("链式调用 set_addr().set_data().set_write() 后:");
  tr3.display();

  // 部分链式调用
  tr3.set_addr(32'h4000).set_data(32'hCAFE);
  $display("部分链式调用 set_addr().set_data() 后:");
  tr3.display();
  $display("");
end

// =============================================================================
// 示例4: this作为参数传递给其他对象
// =============================================================================
Transaction tr4;
Monitor    mon4;

initial begin
  $display("=== 示例4: this作为参数传递 ===");

  mon4 = new();
  tr4  = new(32'h6000, 32'hDEAD, 1);

  // 在Transaction类中定义send_to方法: mon.register(this)
  // 这里直接演示this作为参数传递的效果
  $display("将tr4注册到Monitor:");
  mon4.register(tr4);  // 等价于在方法内部调用 mon.register(this)
  $display("");
end

// =============================================================================
// 示例5: this的隐式使用 vs 显式使用
// =============================================================================
Transaction tr5;

initial begin
  $display("=== 示例5: 隐式this vs 显式this ===");

  tr5 = new(32'h7000, 32'h1111, 0);

  // 在方法内部, addr 和 this.addr 完全等价
  $display("隐式访问: addr  = 0x%08h", tr5.addr);
  $display("显式访问: this.addr 不需要在此处使用,因为已在方法外部");

  // 修改成员: 通过句柄直接修改
  tr5.addr = 32'h8000;
  tr5.display();
  $display("");
end

// =============================================================================
// 示例6: 静态方法中不能使用this
// =============================================================================
initial begin
  $display("=== 示例6: 静态方法中不能使用this ===");
  $display("  静态方法属于类级别,不绑定具体对象,因此没有this指针");
  $display("  只有实例方法(非static)中才能使用this关键字");
  $display("");
end
