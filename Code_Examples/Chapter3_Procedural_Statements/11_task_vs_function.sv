//==============================================================================
// 文件名: 11_task_vs_function.sv
// 知识点: 任务与函数的区别
// 章节: 第3章 过程语句
// 说明: 详细对比task和function的差异和使用场景
//==============================================================================

module task_vs_function;

  logic        clk;
  logic [7:0]  data_reg;
  
  //--------------------------------------------------------------------------
  // 示例1: 返回值对比
  //--------------------------------------------------------------------------
  
  // 函数: 必须有返回值(至少一个output或inout,或返回值)
  function int func_add(input int a, input int b);
    return a + b;
  endfunction
  
  // 任务: 可以没有返回值
  task task_print_sum(input int a, input int b);
    $display("%0d + %0d = %0d", a, b, a + b);
  endtask
  
  initial begin
    $display("===== 示例1: 返回值对比 =====");
    
    int result;
    
    // 函数: 可以在表达式中使用
    result = func_add(10, 20);
    $display("函数返回值: %0d", result);
    
    // 也可以直接用于表达式
    $display("函数表达式: %0d", func_add(5, 10));
    
    // 任务: 必须作为独立语句调用
    task_print_sum(10, 20);
    // result = task_print_sum(10, 20);  // ✗ 错误! 任务不能用于表达式
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: 时序控制对比
  //--------------------------------------------------------------------------
  
  // 函数: 不能包含时序控制(#, @, wait)
  function int func_delayed_add(input int a, input int b);
    // #10;  // ✗ 错误! 函数不能包含延时
    // @(posedge clk);  // ✗ 错误! 函数不能包含事件控制
    return a + b;
  endfunction
  
  // 任务: 可以包含时序控制
  task task_delayed_print(input int value);
    $display("时间%0t: 准备打印", $time);
    
    #10;  // ✓ 任务可以包含延时
    
    $display("时间%0t: 值 = %0d", $time, value);
    
    @(posedge clk);  // ✓ 任务可以包含事件控制
    
    $display("时间%0t: 打印完成", $time);
  endtask
  
  initial begin
    $display("===== 示例2: 时序控制对比 =====");
    
    $display("函数执行:");
    $display("结果: %0d", func_delayed_add(5, 10));
    
    $display("");
    $display("任务执行:");
    task_delayed_print(100);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: 调用方式对比
  //--------------------------------------------------------------------------
  
  function int func_square(input int x);
    return x * x;
  endfunction
  
  task task_square(input int x, output int result);
    result = x * x;
  endtask
  
  initial begin
    $display("===== 示例3: 调用方式对比 =====");
    
    int res;
    
    // 函数调用方式
    res = func_square(5);
    $display("函数调用: res = %0d", res);
    
    // 函数可以直接用于表达式
    if (func_square(4) > 10)
      $display("4^2 > 10");
    
    // 任务调用方式
    task_square(5, res);  // 必须作为独立语句
    $display("任务调用: res = %0d", res);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: 参数传递对比
  //--------------------------------------------------------------------------
  
  // 函数: 默认input参数,可以有output/inout,但较少使用
  function void func_swap(
    inout int a,
    inout int b
  );
    int temp;
    temp = a;
    a = b;
    b = temp;
  endfunction
  
  // 任务: 常用input/output/inout参数
  task task_swap(
    inout int a,
    inout int b
  );
    int temp;
    temp = a;
    a = b;
    b = temp;
  endtask
  
  initial begin
    $display("===== 示例4: 参数传递对比 =====");
    
    int x, y;
    
    x = 10; y = 20;
    $display("交换前: x=%0d, y=%0d", x, y);
    
    func_swap(x, y);
    $display("函数交换后: x=%0d, y=%0d", x, y);
    
    task_swap(x, y);
    $display("任务交换后: x=%0d, y=%0d", x, y);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: 互相调用规则
  //--------------------------------------------------------------------------
  
  function int func_multiply(input int a, input b);
    return a * b;
  endfunction
  
  // 任务可以调用函数
  task task_multiply_and_print(input int a, input int b);
    int result;
    result = func_multiply(a, b);  // ✓ 任务可以调用函数
    $display("%0d * %0d = %0d", a, b, result);
  endtask
  
  // 函数不能调用任务
  function int func_use_task(input int a, input int b);
    // task_multiply_and_print(a, b);  // ✗ 错误! 函数不能调用任务
    return func_multiply(a, b);  // ✓ 函数可以调用函数
  endfunction
  
  initial begin
    $display("===== 示例5: 互相调用规则 =====");
    
    $display("任务调用函数:");
    task_multiply_and_print(10, 20);
    
    $display("");
    $display("函数调用函数:");
    $display("结果: %0d", func_use_task(5, 6));
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: 使用场景对比
  //--------------------------------------------------------------------------
  
  // 场景1: 计算数值 - 用函数
  function logic [7:0] calculate_crc(input logic [7:0] data);
    logic [7:0] crc;
    crc = data;
    crc = crc ^ (crc << 4);
    return crc;
  endfunction
  
  // 场景2: 发送数据包 - 用任务
  task send_data_packet(
    input logic [7:0] header,
    input logic [7:0] payload[]
  );
    logic [7:0] crc;
    
    // 等待时钟
    @(posedge clk);
    
    // 发送头部
    data_reg = header;
    $display("时间%0t: 发送头部 0x%h", $time, header);
    
    // 发送载荷
    foreach (payload[i]) begin
      @(posedge clk);
      data_reg = payload[i];
      $display("时间%0t: 发送数据[%0d] 0x%h", $time, i, payload[i]);
    end
    
    // 发送CRC
    crc = calculate_crc(header);  // 调用函数计算CRC
    foreach (payload[i]) begin
      crc = calculate_crc(crc ^ payload[i]);
    end
    
    @(posedge clk);
    data_reg = crc;
    $display("时间%0t: 发送CRC 0x%h", $time, crc);
    
  endtask
  
  initial begin
    $display("===== 示例6: 使用场景对比 =====");
    
    logic [7:0] pkt_data[];
    logic [7:0] crc_result;
    
    // 使用函数: 计算CRC
    crc_result = calculate_crc(8'hA5);
    $display("CRC计算结果: 0x%h", crc_result);
    
    // 使用任务: 发送数据包
    pkt_data = new[2];
    pkt_data = '{8'h11, 8'h22};
    
    send_data_packet(8'hAA, pkt_data);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: 综合对比表
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例7: task vs function 综合对比 =====");
    $display("");
    $display("| 特性                | task     | function |");
    $display("|---------------------|----------|----------|");
    $display("| 返回值              | 可选     | 必须     |");
    $display("| 时序控制(#,@,wait)  | 支持     | 不支持   |");
    $display("| 用于表达式          | 不可以   | 可以     |");
    $display("| 调用其他函数        | 可以     | 可以     |");
    $display("| 调用其他任务        | 可以     | 不可以   |");
    $display("| 耗时操作            | 支持     | 不支持   |");
    $display("| 执行时间            | 可耗时   | 0时刻    |");
    $display("| 典型用途            | 行为建模 | 计算逻辑 |");
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: 选择指南
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例8: task/function 选择指南 =====");
    $display("");
    $display("使用 function 的场景:");
    $display("  ✓ 纯计算逻辑 (如数学运算、位操作)");
    $display("  ✓ 需要返回值用于表达式");
    $display("  ✓ 组合逻辑建模");
    $display("  ✓ 不需要时序控制");
    $display("  ✓ 可综合的硬件描述");
    $display("");
    $display("使用 task 的场景:");
    $display("  ✓ 需要时序控制 (延时、事件等待)");
    $display("  ✓ 验证环境中的操作序列");
    $display("  ✓ 需要多个输出参数");
    $display("  ✓ 不需要返回值");
    $display("  ✓ 复杂的行为建模");
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 时钟生成
  //--------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  //--------------------------------------------------------------------------
  // 示例9: 实际案例对比
  //--------------------------------------------------------------------------
  
  // 案例1: 用函数实现状态编码
  function logic [2:0] encode_state(input logic [1:0] state);
    case (state)
      2'b00: return 3'b001;
      2'b01: return 3'b010;
      2'b10: return 3'b100;
      default: return 3'b000;
    endcase
  endfunction
  
  // 案例2: 用任务实现复位序列
  task execute_reset_sequence;
    $display("时间%0t: 开始复位序列", $time);
    
    // 拉低复位
    data_reg = 0;
    #20;
    
    // 等待时钟稳定
    repeat (5) @(posedge clk);
    
    $display("时间%0t: 复位完成", $time);
  endtask
  
  initial begin
    $display("===== 示例9: 实际案例对比 =====");
    
    logic [1:0] state;
    logic [2:0] encoded;
    
    // 使用函数: 状态编码
    state = 2'b01;
    encoded = encode_state(state);
    $display("状态%b 编码为 %b", state, encoded);
    
    // 使用任务: 复位序列
    execute_reset_sequence();
    
    $display("");
    $finish;
  end

endmodule
