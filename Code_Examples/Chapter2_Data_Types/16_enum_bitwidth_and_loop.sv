// ===================================
// 枚举位宽与do-while遍历说明
// 补充示例
// ===================================

module enum_bitwidth_and_loop_example;
  
  //================================================================
  // 1. 位宽与表示范围演示
  //================================================================
  
  // 2位 → 可表示4个值 (2^2 = 4)
  enum bit [1:0] {
    TWO_BIT_A,  // 2'b00 = 0
    TWO_BIT_B,  // 2'b01 = 1
    TWO_BIT_C,  // 2'b10 = 2
    TWO_BIT_D   // 2'b11 = 3
  } two_bit_enum;
  
  // 3位 → 可表示8个值 (2^3 = 8)
  enum bit [2:0] {
    THREE_BIT_0, THREE_BIT_1, THREE_BIT_2, THREE_BIT_3,
    THREE_BIT_4, THREE_BIT_5, THREE_BIT_6, THREE_BIT_7
  } three_bit_enum;
  
  // 计数变量
  int count;
  
  initial begin
    $display("========================================");
    $display("枚举位宽说明");
    $display("========================================\n");
    
    //================================================================
    // 示例1: 2位枚举的值范围
    //================================================================
    $display("【示例1】2位枚举的值范围");
    $display("----------------------------------------");
    $display("声明: enum bit [1:0] {A, B, C, D}");
    $display("位宽: 2位");
    $display("可表示值数量: 2^2 = 4个\n");
    
    $display("枚举值对应关系:");
    $display("  TWO_BIT_A = %b (十进制 %0d)", TWO_BIT_A, TWO_BIT_A);
    $display("  TWO_BIT_B = %b (十进制 %0d)", TWO_BIT_B, TWO_BIT_B);
    $display("  TWO_BIT_C = %b (十进制 %0d)", TWO_BIT_C, TWO_BIT_C);
    $display("  TWO_BIT_D = %b (十进制 %0d)", TWO_BIT_D, TWO_BIT_D);
    
    //================================================================
    // 示例2: 3位枚举的值范围
    //================================================================
    $display("\n【示例2】3位枚举的值范围");
    $display("----------------------------------------");
    $display("声明: enum bit [2:0] {0,1,2,3,4,5,6,7}");
    $display("位宽: 3位");
    $display("可表示值数量: 2^3 = 8个\n");
    
    three_bit_enum = three_bit_enum.first();
    $display("枚举值列表:");
    count = 0;
    do begin
      $display("  [%0d] %s = %b (十进制 %0d)", 
               count, three_bit_enum.name(), three_bit_enum, three_bit_enum);
      three_bit_enum = three_bit_enum.next(1);
      count++;
    end while (three_bit_enum != three_bit_enum.first());
    
    //================================================================
    // 示例3: 位宽不足的问题
    //================================================================
    $display("\n【示例3】位宽选择原则");
    $display("----------------------------------------");
    $display("如果需要5个枚举值:");
    $display("  2位最多表示4个值 (2^2=4) → 不够!");
    $display("  3位最多表示8个值 (2^3=8) → 足够!");
    $display("");
    $display("位宽选择公式:");
    $display("  所需位宽 = ceil(log2(枚举值个数))");
    $display("  例如: 5个值 → ceil(log2(5)) = 3位");
    $display("       10个值 → ceil(log2(10)) = 4位");
    $display("       20个值 → ceil(log2(20)) = 5位");
    
    //================================================================
    // 示例4: do-while vs while 循环对比
    //================================================================
    $display("\n【示例4】do-while vs while 循环对比");
    $display("========================================\n");
    
    //----------------------------------------------------------------
    // 4.1 使用 do-while 遍历枚举
    //----------------------------------------------------------------
    $display("【方法1】do-while 循环:");
    $display("----------------------------------------");
    
    two_bit_enum = two_bit_enum.first();
    count = 0;
    
    do begin
      $display("  第%0d次循环: %s = %0d", count, two_bit_enum.name(), two_bit_enum);
      two_bit_enum = two_bit_enum.next(1);
      count++;
    end while (two_bit_enum != two_bit_enum.first());
    
    $display("\n执行流程:");
    $display("  1. 先执行循环体(至少执行1次)");
    $display("  2. 然后检查条件");
    $display("  3. 条件为真则继续循环");
    $display("  → 保证至少执行1次");
    
    //----------------------------------------------------------------
    // 4.2 使用 while 遍历枚举
    //----------------------------------------------------------------
    $display("\n【方法2】while 循环:");
    $display("----------------------------------------");
    
    two_bit_enum = two_bit_enum.first();
    count = 0;
    
    // 方式A: 使用计数器
    while (count < two_bit_enum.num()) begin
      $display("  第%0d次循环: %s = %0d", count, two_bit_enum.name(), two_bit_enum);
      two_bit_enum = two_bit_enum.next(1);
      count++;
    end
    
    $display("\n执行流程:");
    $display("  1. 先检查条件");
    $display("  2. 条件为真才执行循环体");
    $display("  3. 条件为假则跳过循环");
    $display("  → 可能一次都不执行");
    
    //----------------------------------------------------------------
    // 4.3 关键区别演示
    //----------------------------------------------------------------
    $display("\n【关键区别】初始条件不满足时:");
    $display("----------------------------------------");
    
    int empty_val;
    empty_val = 0;  // 假设初始条件为假
    
    $display("\n使用 do-while:");
    do begin
      $display("  循环体执行了! (即使条件为假)");
      empty_val = 1;  // 改变条件
    end while (empty_val == 0);
    $display("  → 至少执行1次");
    
    empty_val = 1;  // 重置条件为"假"
    $display("\n使用 while:");
    while (empty_val == 0) begin
      $display("  循环体不会执行");
    end
    $display("  条件不满足,循环体未执行");
    $display("  → 可能一次都不执行");
    
    //================================================================
    // 示例5: 为什么遍历枚举推荐 do-while
    //================================================================
    $display("\n【示例5】遍历枚举推荐 do-while 的原因");
    $display("========================================\n");
    
    $display("原因1: 保证至少访问一次");
    $display("----------------------------------------");
    $display("枚举遍历通常需要:");
    $display("  1. 从first()开始");
    $display("  2. 打印或处理该值");
    $display("  3. 移动到next()");
    $display("  4. 检查是否回到first()");
    $display("");
    $display("do-while流程:");
    $display("  val = val.first();");
    $display("  do {");
    $display("    处理val;        // 至少执行1次");
    $display("    val = val.next();");
    $display("  } while (val != val.first());");
    $display("");
    
    $display("原因2: 循环终止条件清晰");
    $display("----------------------------------------");
    $display("枚举遍历是循环的:");
    $display("  A → B → C → D → A(回到起点)");
    $display("  当回到first()时,说明遍历完成");
    $display("");
    $display("do-while终止条件:");
    $display("  while (val != val.first())");
    $display("  → 清晰表达"回到起点就停止"");
    
    $display("\n原因3: 避免边界问题");
    $display("----------------------------------------");
    $display("如果枚举只有1个元素:");
    $display("");
    $display("do-while:");
    $display("  执行1次 → 检查条件 → 退出 ✓");
    $display("");
    $display("while (需要额外处理):");
    $display("  检查条件 → 可能需要特殊处理");
    
    //================================================================
    // 总结
    //================================================================
    $display("\n【总结】");
    $display("========================================");
    $display("1. 位宽与表示范围:");
    $display("   - N位可表示 2^N 个值");
    $display("   - 2位 → 4个值, 3位 → 8个值");
    $display("   - 选择位宽: ceil(log2(枚举数量))");
    $display("");
    $display("2. do-while vs while:");
    $display("   - do-while: 先执行后检查,至少执行1次");
    $display("   - while: 先检查后执行,可能0次执行");
    $display("");
    $display("3. 遍历枚举推荐 do-while:");
    $display("   - 保证至少处理first()一次");
    $display("   - 终止条件清晰(回到first())");
    $display("   - 避免边界情况问题");
    $display("========================================");
    
    $display("\n示例完成!");
  end
  
endmodule
