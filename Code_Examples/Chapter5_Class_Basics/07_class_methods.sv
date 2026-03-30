//==============================================================================
// 文件名: 07_class_methods.sv
// 知识点: 类的方法 (function / task)
// 章节: 第5章 - 类基础
// 说明: 演示function和task的区别、参数传递、返回值、默认参数
//==============================================================================

// =============================================================================
// 类1: Calculator -- 演示function(不消耗仿真时间,可有返回值)
// =============================================================================
class Calculator;
  int result;

  // void函数: 无返回值
  function void clear();
    result = 0;
  endfunction

  // 有返回值的函数
  function int add(int a, int b);
    return a + b;
  endfunction

  // 多参数函数, 结果存储在成员变量中
  function void multiply(int a, int b);
    result = a * b;
  endfunction

  // 函数可以在表达式中使用
  function bit [31:0] calc_checksum(bit [31:0] addr, bit [31:0] data);
    return addr ^ data;
  endfunction

  // 带默认值的参数
  function void display_result(string prefix = "CALC");
    $display("    [%0s] result = %0d", prefix, result);
  endfunction
endclass

// =============================================================================
// 类2: Driver -- 演示task(可包含时序控制, 消耗仿真时间)
// =============================================================================
class Driver;
  // 模拟简单的信号接口
  bit        clk;
  bit [31:0] addr;
  bit [31:0] data;
  bit        valid;
  bit        ready;

  // 产生时钟
  task run_clk(int cycles);
    repeat(cycles) #10 clk = ~clk;
  endtask

  // task可以包含时序控制(#delay, @event, wait)
  task drive(bit [31:0] a, bit [31:0] d);
    @(posedge clk);        // 等待时钟上升沿 (时序控制)
    addr  <= a;
    data  <= d;
    valid <= 1;
    @(posedge clk);
    @(posedge clk);
    valid <= 0;
  endtask

  // task调用其他task
  task send_and_wait(bit [31:0] a, bit [31:0] d);
    drive(a, d);            // 调用同对象的其他task
    wait(valid == 0);       // 等待条件满足
  endtask

  function void display();
    $display("    Driver: addr=0x%08h data=0x%08h valid=%0b ready=%0b",
             addr, data, valid, ready);
  endfunction
endclass

// =============================================================================
// 类3: ParamDemo -- 演示参数传递方式 (input / output / inout)
// =============================================================================
class ParamDemo;

  // input: 调用者传入,方法内部只读
  // output: 方法内部赋值,返回给调用者
  // inout: 双向传递
  function void swap(ref int a, ref int b);
    int temp;
    temp = a;
    a = b;
    b = temp;
  endfunction

  // output参数示例: 通过参数返回多个值
  function void divide(int dividend, int divisor, output int quotient, output int remainder);
    quotient  = dividend / divisor;
    remainder = dividend % divisor;
  endfunction
endclass

// =============================================================================
// 测试程序
// =============================================================================
module class_methods_test;

  Calculator calc;
  Driver     drv;
  ParamDemo  pd;

  initial begin
    $display("========================================");
    $display(" 知识点7: 类的方法 (function vs task)");
    $display("========================================\n");

    // =====================================================================
    // 示例1: function -- 不消耗仿真时间,可有返回值
    // =====================================================================
    $display("--- 示例1: function ---");
    calc = new();

    calc.clear();
    $display("clear后: result=%0d", calc.result);

    // 有返回值,可在表达式中使用
    int sum = calc.add(10, 20);
    $display("add(10, 20) = %0d", sum);

    // 函数调用作为表达式的一部分
    calc.multiply(3, 7);
    $display("multiply(3,7) → result=%0d", calc.result);

    // 带默认参数
    calc.display_result();         // 使用默认前缀 "CALC"
    calc.display_result("MYCALC");  // 自定义前缀

    // 函数可在表达式中直接使用
    bit [31:0] chk = calc.calc_checksum(32'hAAAA, 32'h5555);
    $display("checksum = 0x%08h", chk);
    $display("");

    // =====================================================================
    // 示例2: task -- 包含时序控制,消耗仿真时间
    // =====================================================================
    $display("--- 示例2: task (含时序控制) ---");
    drv = new();

    $display("产生时钟并驱动事务:");
    fork
      drv.run_clk(20);  // 在并行线程中产生时钟
    join_none

    #5;  // 等待时钟启动
    drv.send_and_wait(32'h1000_0000, 32'hDEAD_BEEF);
    $display("驱动完成: addr=0x%08h data=0x%08h", drv.addr, drv.data);
    $display("");

    // =====================================================================
    // 示例3: 参数传递方式 (output)
    // =====================================================================
    $display("--- 示例3: output参数(返回多个值) ---");
    pd = new();

    int q, r;
    pd.divide(17, 5, q, r);
    $display("17 / 5: quotient=%0d, remainder=%0d", q, r);

    pd.divide(100, 3, q, r);
    $display("100 / 3: quotient=%0d, remainder=%0d", q, r);
    $display("");

    // =====================================================================
    // 示例4: function vs task 对比总结
    // =====================================================================
    $display("--- 示例4: function vs task 对比 ---");
    $display("function:");
    $display("  - 不消耗仿真时间");
    $display("  - 可以有返回值, 可在表达式中使用");
    $display("  - 不能有 #/@/wait 等时序控制");
    $display("  - 适用: 计算, 查询, 转换");
    $display("");
    $display("task:");
    $display("  - 可以消耗仿真时间");
    $display("  - 无返回值, 只能作为语句调用");
    $display("  - 可以有 #/@/wait 等时序控制");
    $display("  - 适用: 驱动, 等待, 通信");
    $display("");

    // =====================================================================
    $display("========================================");
    $display(" 关键要点:");
    $display("  1. function不耗时, 可有返回值");
    $display("  2. task可含时序控制, 无返回值");
    $display("  3. 参数方向: input/output/inout/ref");
    $display("  4. void函数表示无返回值");
    $display("  5. 可为参数设置默认值");
    $display("========================================");

    $finish;
  end

endmodule

//==============================================================================
// 编译运行:
//   vlog 07_class_methods.sv
//   vsim -novopt class_methods_test -do "run -all"
//==============================================================================
