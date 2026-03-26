// ===================================
// 队列补充示例: 字符串队列与void'用法
// 知识点9补充: 第2章 SystemVerilog数据类型
// ===================================

module queue_string_and_void_example;
  
  // 字符串队列
  string tasks[$];             // 字符串类型队列,每个元素是一个完整字符串
  
  // 整数队列(用于滑动窗口示例)
  int window[$];               // 滑动窗口队列
  int window_size = 4;         // 窗口大小
  
  // 临时变量
  int i;                       // 循环变量
  int val;                     // 临时存储值
  string str_val;              // 临时存储字符串
  
  // 示例2: 字符数组队列对比
  byte char_queue[$];          // 字节队列,每个元素是一个字符,用于对比演示
  
  // 示例3: void'演示队列
  int test_q[$];               // 用于演示void'用法的队列
  
  // 示例5: 其他void'用法演示队列
  int demo_q[$];               // 用于演示void'其他用法的队列
  
  initial begin
    $display("========================================");
    $display("队列补充示例: 字符串队列与void'用法");
    $display("========================================\n");
    
    //================================================================
    // 示例1: 字符串在队列中的存储方式
    //================================================================
    $display("【示例1】字符串队列的存储方式");
    $display("----------------------------------------");
    
    // 每个字符串占用一个索引位置
    tasks.push_back("NORMAL_TASK");
    tasks.push_back("HIGH_PRIORITY");
    tasks.push_back("IDLE");
    tasks.push_back("URGENT");
    
    $display("\n字符串队列: %p", tasks);
    $display("队列大小: %0d", tasks.size());
    
    $display("\n逐个访问:");
    foreach (tasks[i]) begin
      $display("  tasks[%0d] = \"%s\" (长度: %0d字符)", 
               i, tasks[i], tasks[i].len());
    end
    
    // 证明每个字符串是一个元素
    $display("\n验证: 每个字符串占用一个索引");
    $display("  tasks[0] = %s", tasks[0]);
    $display("  tasks[$] = %s", tasks[$]);
    
    // 弹出测试
    str_val = tasks.pop_front();
    $display("\npop_front()后:");
    $display("  弹出的值: %s", str_val);
    $display("  剩余队列: %p", tasks);
    $display("  队列大小: %0d", tasks.size());
    
    //================================================================
    // 示例2: 对比 - 字符数组队列
    //================================================================
    $display("\n【示例2】对比: 字符数组队列");
    $display("----------------------------------------");
    
    // 每个字符占用一个索引
    char_queue.push_back("H");
    char_queue.push_back("E");
    char_queue.push_back("L");
    char_queue.push_back("L");
    char_queue.push_back("O");
    
    $display("\n字符队列: %p", char_queue);
    $display("队列大小: %0d", char_queue.size());
    $display("解释: 每个字符占用一个索引位置");
    
    //================================================================
    // 示例3: void' 的作用演示
    //================================================================
    $display("\n【示例3】void' 的作用演示");
    $display("----------------------------------------");
    
    test_q = '{10, 20, 30, 40, 50};  // 初始化队列
    
    $display("初始队列: %p", test_q);
    
    // 方法1: 不使用返回值(可能产生警告)
    $display("\n方法1: 不使用返回值");
    // test_q.pop_front();  // 某些工具会警告
    
    // 方法2: 使用void'明确忽略返回值(推荐)
    $display("方法2: 使用void'忽略返回值");
    void'(test_q.pop_front());
    $display("  void'(test_q.pop_front()) 执行后");
    $display("  队列: %p", test_q);
    
    // 方法3: 使用返回值
    $display("\n方法3: 使用返回值");
    val = test_q.pop_front();
    $display("  val = test_q.pop_front()");
    $display("  弹出值: %0d", val);
    $display("  队列: %p", test_q);
    
    //================================================================
    // 示例4: 滑动窗口实际应用
    //================================================================
    $display("\n【示例4】滑动窗口实际应用");
    $display("----------------------------------------");
    
    // 模拟数据流处理
    $display("模拟数据流,窗口大小 = %0d", window_size);
    $display("\n处理过程:");
    
    for (i = 1; i <= 8; i++) begin
      // 添加新数据
      window.push_back(i * 10);
      
      // 保持窗口大小,删除最旧的数据
      if (window.size() > window_size) begin
        // 只想删除旧数据,不关心删除的值
        void'(window.pop_front());
      end
      
      $display("  添加数据%0d: 窗口内容 = %p (大小:%0d)", 
               i*10, window, window.size());
    end
    
    $display("\n最终窗口: %p", window);
    
    //================================================================
    // 示例5: void' 的其他用法
    //================================================================
    $display("\n【示例5】void' 的其他用法");
    $display("----------------------------------------");
    
    demo_q = '{100, 200, 300};  // 初始化队列
    
    // 场景1: 只想知道队列是否为空,弹出元素但不使用
    if (demo_q.size() > 0) begin
      void'(demo_q.pop_front());  // 删除一个元素
      $display("弹出一个元素后,队列大小: %0d", demo_q.size());
    end
    
    // 场景2: 清空队列
    $display("\n清空队列:");
    while (demo_q.size() > 0) begin
      void'(demo_q.pop_front());
      $display("  弹出元素,剩余大小: %0d", demo_q.size());
    end
    
    //================================================================
    // 总结
    //================================================================
    $display("\n【总结】");
    $display("========================================");
    $display("1. 字符串队列: string q[$]");
    $display("   - 每个元素是一个完整的字符串");
    $display("   - 一个字符串占用一个索引位置");
    $display("");
    $display("2. void' 的作用:");
    $display("   - 显式忽略函数/方法的返回值");
    $display("   - 避免编译器警告");
    $display("   - 常用于只删除元素不使用返回值的场景");
    $display("========================================");
  end
  
endmodule
