//==============================================================================
// 文件名: 04_while_loop.sv
// 知识点: while循环
// 章节: 第3章 过程语句
// 说明: 演示while循环的用法
//==============================================================================

module while_loop;

  logic [7:0] counter;
  logic [7:0] sum_val;
  logic [4:0] idx;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本while循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: 基本while循环 =====");
    
    counter = 0;
    
    while (counter < 5) begin
      $display("counter = %0d", counter);
      counter++;
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: while循环求和
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: while循环求和 =====");
    
    sum_val = 0;
    idx = 1;
    
    // 计算1+2+...+10
    while (idx <= 10) begin
      sum_val = sum_val + idx;
      idx++;
    end
    
    $display("1+2+...+10 = %0d", sum_val);
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: while循环查找
  //--------------------------------------------------------------------------
  logic [7:0] data_arr [16];
  logic       found;
  logic [4:0] found_index;
  
  initial begin
    $display("===== 示例3: while循环查找 =====");
    
    // 初始化数组
    for (int i = 0; i < 16; i++) begin
      data_arr[i] = i * i;  // 0, 1, 4, 9, 16, ...
    end
    
    // 查找第一个大于100的数
    idx = 0;
    found = 0;
    
    while (idx < 16 && !found) begin
      if (data_arr[idx] > 100) begin
        found = 1;
        found_index = idx;
      end
      idx++;
    end
    
    if (found)
      $display("找到大于100的数: data_arr[%0d] = %0d", found_index, data_arr[found_index]);
    else
      $display("未找到大于100的数");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: while vs for 的选择
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: while vs for 的选择 =====");
    
    $display("使用while的场景:");
    $display("  - 循环次数不确定");
    $display("  - 需要基于复杂条件退出");
    $display("  - 等待某个事件发生");
    
    $display("");
    $display("使用for的场景:");
    $display("  - 循环次数已知");
    $display("  - 需要索引遍历");
    $display("  - 数组操作");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: while循环等待事件
  //--------------------------------------------------------------------------
  logic        clk;
  logic        ready;
  logic [7:0]  data;
  int          timeout;
  
  initial begin
    $display("===== 示例5: while循环等待事件 =====");
    
    ready = 0;
    timeout = 0;
    
    // 模拟等待ready信号 (带超时)
    while (!ready && timeout < 100) begin
      #1;
      timeout++;
      if (timeout == 10) ready = 1;  // 模拟ready在第10个时间单位变高
    end
    
    if (ready)
      $display("ready信号有效, 等待了%0d时间单位", timeout);
    else
      $display("超时! ready信号未有效");
    
    $display("");
    $finish;
  end
  
  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

endmodule
