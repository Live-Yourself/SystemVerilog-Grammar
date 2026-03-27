//==============================================================================
// 文件名: 07_repeat_forever_loop.sv
// 知识点: repeat和forever循环
// 章节: 第3章 过程语句
// 说明: 演示repeat和forever循环的用法
//==============================================================================

module repeat_forever_loop;

  logic        clk;
  logic [7:0]  counter;
  logic [7:0]  data_packet;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本repeat循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: 基本repeat循环 =====");
    
    counter = 0;
    
    // 重复执行5次
    repeat (5) begin
      $display("counter = %0d", counter);
      counter++;
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: repeat生成测试数据
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: repeat生成测试数据 =====");
    
    logic [7:0] test_data;
    
    // 生成10个随机测试数据
    repeat (10) begin
      test_data = $urandom_range(0, 255);
      $display("test_data = %0d (0x%h)", test_data, test_data);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: repeat等待时钟边沿
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例3: repeat等待时钟边沿 =====");
    
    counter = 0;
    
    // 等待10个时钟上升沿
    repeat (10) begin
      @(posedge clk);
      counter++;
      $display("时间%0t: counter=%0d", $time, counter);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: repeat发送数据包
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: repeat发送数据包 =====");
    
    // 发送4个数据包
    repeat (4) begin
      data_packet = $urandom_range(0, 255);
      $display("发送数据包: 0x%h", data_packet);
      #10;  // 数据包间隔
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: forever循环 - 无限循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例5: forever循环 =====");
    
    counter = 0;
    
    // forever循环: 无限执行,除非遇到$finish或disable
    forever begin
      counter++;
      $display("forever循环: counter=%0d", counter);
      
      if (counter >= 5) begin
        $display("达到条件,退出forever循环");
        $finish;  // 结束仿真
      end
      
      #5;
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: forever生成时钟
  //--------------------------------------------------------------------------
  // 使用forever生成时钟是最常见的用法
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  //--------------------------------------------------------------------------
  // 示例7: repeat vs for 对比
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例7: repeat vs for 对比 =====");
    
    logic [7:0] sum;
    int i;
    
    // 使用repeat
    sum = 0;
    repeat (10) begin
      sum++;
    end
    $display("repeat结果: sum = %0d", sum);
    
    // 使用for
    sum = 0;
    for (i = 0; i < 10; i++) begin
      sum++;
    end
    $display("for结果: sum = %0d", sum);
    
    $display("");
    $display("repeat vs for:");
    $display("  repeat: 只关心次数,不需要索引");
    $display("  for:    需要索引或条件控制");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: repeat返回值
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例8: repeat的返回值 =====");
    
    int result;
    
    // repeat返回1表示成功执行完所有迭代
    result = repeat (3) begin
      $display("执行repeat循环体");
    end
    
    $display("repeat返回值: %0d", result);
    $display("");
  end

endmodule
