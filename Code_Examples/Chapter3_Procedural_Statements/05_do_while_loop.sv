//==============================================================================
// 文件名: 05_do_while_loop.sv
// 知识点: do-while循环
// 章节: 第3章 过程语句
// 说明: 演示do-while循环的用法
//==============================================================================

module do_while_loop;

  logic [7:0] counter;
  logic [7:0] sum_val;
  logic [4:0] idx;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本do-while循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: 基本do-while循环 =====");
    
    counter = 0;
    
    do begin
      $display("counter = %0d", counter);
      counter++;
    end while (counter < 5);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: do-while vs while的区别
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: do-while vs while的区别 =====");
    
    // while: 先检查条件,可能一次都不执行
    counter = 10;
    $display("while循环 (counter初始值=10):");
    while (counter < 5) begin
      $display("  执行循环体");  // 不会执行
      counter++;
    end
    $display("  while循环体未执行");
    
    // do-while: 先执行一次,再检查条件
    counter = 10;
    $display("do-while循环 (counter初始值=10):");
    do begin
      $display("  执行循环体, counter=%0d", counter);  // 至少执行一次
      counter++;
    end while (counter < 5);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: do-while用于菜单选择
  //--------------------------------------------------------------------------
  logic [7:0] user_input;
  logic       valid_choice;
  int         attempt_count;
  
  initial begin
    $display("===== 示例3: do-while用于输入验证 =====");
    
    attempt_count = 0;
    
    // 模拟用户输入验证 (至少执行一次)
    do begin
      attempt_count++;
      
      // 模拟用户输入 (第3次才输入正确)
      if (attempt_count == 1)
        user_input = 8'd5;   // 无效输入
      else if (attempt_count == 2)
        user_input = 8'd9;   // 无效输入
      else
        user_input = 8'd2;   // 有效输入 (1-4范围)
      
      $display("尝试%0d: 输入=%0d", attempt_count, user_input);
      
      // 验证输入是否在1-4范围
      valid_choice = (user_input >= 1 && user_input <= 4);
      
      if (!valid_choice)
        $display("  无效输入! 请输入1-4之间的数");
      
    end while (!valid_choice);
    
    $display("有效输入: %0d", user_input);
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: do-while实现斐波那契数列
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: do-while生成斐波那契数列 =====");
    
    int fib_prev, fib_curr, fib_next;
    int count;
    
    fib_prev = 0;
    fib_curr = 1;
    count = 0;
    
    $display("斐波那契数列前10项:");
    
    do begin
      $display("  F[%0d] = %0d", count, fib_prev);
      
      fib_next = fib_prev + fib_curr;
      fib_prev = fib_curr;
      fib_curr = fib_next;
      
      count++;
    end while (count < 10);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: do-while在验证中的应用
  //--------------------------------------------------------------------------
  logic [7:0] test_data;
  logic       test_pass;
  int         test_iteration;
  
  initial begin
    $display("===== 示例5: do-while在验证中的应用 =====");
    
    test_iteration = 0;
    test_pass = 0;
    
    // 至少执行一次测试,如果失败则重试
    do begin
      test_iteration++;
      
      // 模拟测试 (第2次才通过)
      test_data = $urandom_range(0, 100);
      
      $display("测试迭代%0d: test_data=%0d", test_iteration, test_data);
      
      // 测试条件: 数据在20-80范围
      test_pass = (test_data >= 20 && test_data <= 80);
      
      if (!test_pass)
        $display("  测试失败, 重试...");
      
    end while (!test_pass && test_iteration < 5);
    
    if (test_pass)
      $display("测试通过! 迭代次数=%0d", test_iteration);
    else
      $display("测试失败! 达到最大重试次数");
    
    $display("");
    $finish;
  end

endmodule
