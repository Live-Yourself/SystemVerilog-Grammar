//==============================================================================
// 文件名: 08_break_continue.sv
// 知识点: break和continue
// 章节: 第3章 过程语句
// 说明: 演示break和continue的循环控制用法
//==============================================================================

module break_continue;

  logic [7:0] data_arr [16];
  logic [4:0] idx;
  
  //--------------------------------------------------------------------------
  // 示例1: break提前退出循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: break提前退出循环 =====");
    
    // 初始化数组
    for (int i = 0; i < 16; i++) begin
      data_arr[i] = i * i;  // 0, 1, 4, 9, 16, 25, ...
    end
    
    // 查找第一个大于50的数
    for (idx = 0; idx < 16; idx++) begin
      if (data_arr[idx] > 50) begin
        $display("找到: data_arr[%0d] = %0d > 50", idx, data_arr[idx]);
        break;  // 找到后立即退出循环
      end
    end
    
    $display("循环结束, idx = %0d", idx);
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: continue跳过当前迭代
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: continue跳过当前迭代 =====");
    
    $display("打印0-9中的奇数:");
    for (int i = 0; i < 10; i++) begin
      // 跳过偶数
      if (i % 2 == 0) begin
        continue;  // 跳过本次迭代,继续下一次
      end
      
      $display("  i = %0d (奇数)", i);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: break在while循环中的应用
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例3: break在while循环中 =====");
    
    logic [7:0] value;
    int count;
    
    value = 0;
    count = 0;
    
    while (count < 20) begin
      value = $urandom_range(0, 100);
      count++;
      
      $display("迭代%0d: value=%0d", count, value);
      
      // 如果找到大于90的数就退出
      if (value > 90) begin
        $display("找到大于90的数, 退出循环");
        break;
      end
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: continue过滤数据
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: continue过滤数据 =====");
    
    logic [7:0] valid_count;
    
    valid_count = 0;
    
    $display("过滤有效数据 (10-90范围):");
    
    for (int i = 0; i < 10; i++) begin
      logic [7:0] test_val;
      test_val = $urandom_range(0, 100);
      
      // 跳过无效数据
      if (test_val < 10 || test_val > 90) begin
        $display("  跳过无效数据: %0d", test_val);
        continue;
      end
      
      // 处理有效数据
      valid_count++;
      $display("  有效数据%0d: %0d", valid_count, test_val);
    end
    
    $display("有效数据总数: %0d", valid_count);
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: break和continue对比
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例5: break vs continue =====");
    
    $display("使用break:");
    for (int i = 0; i < 5; i++) begin
      if (i == 3) break;
      $display("  i = %0d", i);  // 输出: 0, 1, 2
    end
    
    $display("");
    $display("使用continue:");
    for (int i = 0; i < 5; i++) begin
      if (i == 3) continue;
      $display("  i = %0d", i);  // 输出: 0, 1, 2, 4
    end
    
    $display("");
    $display("break:    完全退出循环");
    $display("continue: 跳过当前迭代,继续下一次");
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: break在嵌套循环中的作用范围
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例6: break的作用范围 =====");
    
    $display("break只影响最内层循环:");
    
    for (int i = 0; i < 3; i++) begin
      $display("外层循环: i = %0d", i);
      
      for (int j = 0; j < 5; j++) begin
        if (j == 2) break;  // 只退出内层循环
        
        $display("  内层循环: j = %0d", j);
      end
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: return也可以退出循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例7: return退出循环 =====");
    $display("return会在函数中讲解,可以立即退出整个函数");
    $display("如果在函数的循环中使用return,会同时退出循环和函数");
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: 实际应用 - 查找特定模式
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例8: 实际应用 - 查找特定模式 =====");
    
    logic [7:0] packet [10];
    logic       pattern_found;
    int         pattern_pos;
    
    // 初始化数据包
    for (int i = 0; i < 10; i++) begin
      packet[i] = i * 10;  // 0, 10, 20, 30, ...
    end
    
    // 在特定位置插入模式
    packet[5] = 8'hAA;  // 模式标记
    
    // 查找模式
    pattern_found = 0;
    
    for (int i = 0; i < 10; i++) begin
      // 跳过非目标数据
      if (packet[i] < 100) continue;
      
      // 检查模式
      if (packet[i] == 8'hAA) begin
        pattern_found = 1;
        pattern_pos = i;
        break;  // 找到后立即退出
      end
    end
    
    if (pattern_found)
      $display("找到模式8'hAA在位置%0d", pattern_pos);
    else
      $display("未找到模式");
    
    $display("");
    $finish;
  end

endmodule
