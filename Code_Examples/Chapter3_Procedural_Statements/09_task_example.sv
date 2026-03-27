//==============================================================================
// 文件名: 09_task_example.sv
// 知识点: 任务task
// 章节: 第3章 过程语句
// 说明: 演示任务的定义、调用和参数传递
//==============================================================================

module task_example;

  logic        clk;
  logic [7:0]  data_out;
  logic        valid;
  logic [7:0]  result;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本任务定义和调用
  //--------------------------------------------------------------------------
  
  // 任务定义: 无参数,无返回值
  task print_hello;
    $display("Hello from task!");
  endtask
  
  initial begin
    $display("===== 示例1: 基本任务调用 =====");
    
    // 调用任务
    print_hello();
    print_hello;  // 括号可省略
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: 带输入参数的任务
  //--------------------------------------------------------------------------
  
  // 任务定义: 带输入参数
  task print_value(input logic [7:0] value);
    $display("值为: %0d (0x%h)", value, value);
  endtask
  
  // 任务定义: 多个输入参数
  task print_sum(input int a, input int b);
    int sum;
    sum = a + b;
    $display("%0d + %0d = %0d", a, b, sum);
  endtask
  
  initial begin
    $display("===== 示例2: 带输入参数的任务 =====");
    
    print_value(100);
    print_value(8'hAB);
    
    print_sum(10, 20);
    print_sum(5, 15);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: 带输出参数的任务
  //--------------------------------------------------------------------------
  
  // 任务定义: 带输出参数
  task calculate_square(
    input  logic [7:0] value,
    output logic [15:0] square
  );
    square = value * value;
  endtask
  
  // 任务定义: 带输入输出参数
  task increment(
    inout logic [7:0] counter
  );
    counter = counter + 1;
  endtask
  
  initial begin
    $display("===== 示例3: 带输出参数的任务 =====");
    
    logic [15:0] square_result;
    
    calculate_square(8, square_result);
    $display("8的平方 = %0d", square_result);
    
    calculate_square(15, square_result);
    $display("15的平方 = %0d", square_result);
    
    // inout参数示例
    data_out = 100;
    $display("调用前: data_out = %0d", data_out);
    increment(data_out);
    $display("调用后: data_out = %0d", data_out);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: 任务可以包含时序控制
  //--------------------------------------------------------------------------
  
  // 任务可以包含延时和事件控制
  task send_data(
    input logic [7:0] data,
    input int delay_cycles
  );
    $display("时间%0t: 准备发送数据 0x%h", $time, data);
    
    // 等待指定时钟周期
    repeat (delay_cycles) begin
      @(posedge clk);
    end
    
    $display("时间%0t: 发送数据 0x%h", $time, data);
    data_out = data;
    valid = 1;
    
    @(posedge clk);
    valid = 0;
    
    $display("时间%0t: 数据发送完成", $time);
  endtask
  
  initial begin
    $display("===== 示例4: 任务包含时序控制 =====");
    
    send_data(8'hA5, 3);  // 等待3个时钟周期后发送
    send_data(8'h3C, 2);  // 等待2个时钟周期后发送
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: 任务可以调用其他任务
  //--------------------------------------------------------------------------
  
  task task_A;
    $display("任务A开始");
    task_B();  // 调用其他任务
    $display("任务A结束");
  endtask
  
  task task_B;
    $display("  任务B执行");
  endtask
  
  initial begin
    $display("===== 示例5: 任务嵌套调用 =====");
    
    task_A();
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: 任务的默认参数值
  //--------------------------------------------------------------------------
  
  // SystemVerilog支持默认参数值
  task wait_cycles(input int cycles = 1);
    $display("等待%0d个时钟周期", cycles);
    repeat (cycles) @(posedge clk);
  endtask
  
  initial begin
    $display("===== 示例6: 任务的默认参数 =====");
    
    wait_cycles();     // 使用默认值1
    wait_cycles(5);    // 指定值5
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: 数组作为任务参数
  //--------------------------------------------------------------------------
  
  task print_array(input logic [7:0] arr[], input string name);
    $display("数组 %s 内容:", name);
    foreach (arr[i]) begin
      $display("  %s[%0d] = %0d", name, i, arr[i]);
    end
  endtask
  
  task sum_array(
    input  logic [7:0] arr[],
    output logic [15:0] sum
  );
    sum = 0;
    foreach (arr[i]) begin
      sum += arr[i];
    end
  endtask
  
  initial begin
    $display("===== 示例7: 数组作为任务参数 =====");
    
    logic [7:0] my_arr[];
    logic [15:0] total;
    
    my_arr = new[5];
    my_arr = '{10, 20, 30, 40, 50};
    
    print_array(my_arr, "my_arr");
    
    sum_array(my_arr, total);
    $display("数组总和 = %0d", total);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: 全局任务 vs 模块内任务
  //--------------------------------------------------------------------------
  
  // 模块内的任务可以访问模块内的信号
  task drive_valid;
    valid = 1;
    #10;
    valid = 0;
  endtask
  
  initial begin
    $display("===== 示例8: 模块内任务访问信号 =====");
    
    valid = 0;
    $display("调用前: valid = %b", valid);
    
    drive_valid();  // 直接访问模块内的valid信号
    
    #1;
    $display("调用后: valid = %b", valid);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例9: 任务中的局部变量
  //--------------------------------------------------------------------------
  
  task complex_calculation(
    input  int a,
    input  int b,
    output int result
  );
    // 局部变量
    int temp1, temp2;
    
    temp1 = a * 2;
    temp2 = b * 3;
    result = temp1 + temp2;
    
    $display("计算: %0d*2 + %0d*3 = %0d", a, b, result);
  endtask
  
  initial begin
    $display("===== 示例9: 任务中的局部变量 =====");
    
    int res;
    
    complex_calculation(5, 10, res);
    
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
  // 示例10: 实际应用 - 数据包发送任务
  //--------------------------------------------------------------------------
  
  task send_packet(
    input logic [7:0] header,
    input logic [7:0] payload[],
    input logic [7:0] checksum
  );
    $display("时间%0t: ===== 发送数据包 =====", $time);
    
    // 发送头部
    @(posedge clk);
    data_out = header;
    valid = 1;
    $display("  头部: 0x%h", header);
    
    // 发送载荷
    foreach (payload[i]) begin
      @(posedge clk);
      data_out = payload[i];
      $display("  数据[%0d]: 0x%h", i, payload[i]);
    end
    
    // 发送校验和
    @(posedge clk);
    data_out = checksum;
    $display("  校验和: 0x%h", checksum);
    
    // 结束
    @(posedge clk);
    valid = 0;
    $display("时间%0t: 数据包发送完成", $time);
    
  endtask
  
  initial begin
    $display("===== 示例10: 数据包发送任务 =====");
    
    logic [7:0] pkt_payload[];
    
    pkt_payload = new[3];
    pkt_payload = '{8'h11, 8'h22, 8'h33};
    
    #50;  // 等待之前的操作完成
    
    send_packet(8'hAA, pkt_payload, 8'h66);
    
    #50;
    $display("");
    $finish;
  end

endmodule
