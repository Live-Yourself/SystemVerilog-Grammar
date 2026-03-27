//==============================================================================
// 文件名: 01_if_else.sv
// 知识点: if-else条件语句
// 章节: 第3章 过程语句
// 说明: 演示if-else语句的各种用法和注意事项
//==============================================================================

module if_else_example;

  logic        clk;
  logic [3:0]  counter;
  logic [7:0]  data_in;
  logic [7:0]  data_out;
  logic        valid;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本if-else语句
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: 基本if-else语句 =====");
    
    counter = 5;
    
    // 单分支if
    if (counter > 3)
      $display("counter > 3");
    
    // 双分支if-else
    if (counter == 10)
      $display("counter等于10");
    else
      $display("counter不等于10, 实际值为%0d", counter);
    
    // 多分支if-else if-else
    if (counter < 3)
      $display("counter很小");
    else if (counter < 7)
      $display("counter中等");  // 会执行这里
    else
      $display("counter很大");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: 块语句begin...end
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: 块语句begin...end =====");
    
    data_in = 100;
    valid = 1;
    
    // 多条语句需要用begin...end包围
    if (valid) begin
      data_out = data_in;
      $display("数据传输: data_in=%0d -> data_out=%0d", data_in, data_out);
      $display("传输完成");
    end
    
    // 常见错误示例(如果不使用begin...end)
    // if (valid)
    //   data_out = data_in;    // 只有这一句在if内
    //   $display("传输完成");  // 这句总是会执行!
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: 嵌套if语句
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例3: 嵌套if语句 =====");
    
    logic [3:0] mode;
    logic       enable;
    
    mode = 2;
    enable = 1;
    
    // 嵌套if
    if (enable) begin
      $display("设备已使能");
      
      if (mode == 0)
        $display("模式0: 待机");
      else if (mode == 1)
        $display("模式1: 正常工作");
      else if (mode == 2)
        $display("模式2: 调试模式");  // 会执行这里
      else
        $display("未知模式");
    end else begin
      $display("设备未使能");
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: if的常见陷阱
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: if的常见陷阱 =====");
    
    logic [7:0] value;
    
    // 陷阱1: 悬空else问题
    value = 50;
    if (value > 30)
      if (value > 60)
        $display("value > 60");
      else
        $display("value <= 60");  // 这个else匹配内层if
    // 解决方案: 使用begin...end明确层次
    
    $display("");
    
    // 陷阱2: 使用=而不是== (会警告但可能通过编译)
    // if (value = 50)  // 危险! 这是赋值,不是比较
    //   $display("value被赋值为50");
    // 正确写法:
    if (value == 50)
      $display("value等于50");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: 条件表达式中的X和Z
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例5: 条件表达式中的X和Z =====");
    
    logic [3:0] unknown_val;
    
    // 如果条件表达式中包含X或Z,if判断结果不确定
    unknown_val = 4'b10X0;
    
    // 这是危险的做法
    if (unknown_val == 4'b10X0)  // 可能不会按预期执行
      $display("匹配成功");
    else
      $display("匹配失败");
    
    // 安全的做法: 使用casez或casex,或者先检查X/Z
    if (!$isunknown(unknown_val)) begin
      if (unknown_val == 4'b1000)
        $display("值确定,等于1000");
    end else begin
      $display("警告: 值包含X或Z");
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: 综合中的if语句
  //--------------------------------------------------------------------------
  // 以下代码展示可综合的if语句用法
  
  // 组合逻辑: 使用always_comb
  logic [7:0] mux_out;
  logic [1:0] sel;
  logic [7:0] in0, in1, in2, in3;
  
  always_comb begin
    if (sel == 2'b00)
      mux_out = in0;
    else if (sel == 2'b01)
      mux_out = in1;
    else if (sel == 2'b10)
      mux_out = in2;
    else
      mux_out = in3;
  end
  
  // 时序逻辑: 使用always_ff
  logic [7:0] registered_data;
  
  always_ff @(posedge clk) begin
    if (valid)
      registered_data <= data_in;
  end
  
  //--------------------------------------------------------------------------
  // 示例7: if与三元运算符对比
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例7: if与三元运算符对比 =====");
    
    logic [7:0] a, b, max_val;
    
    a = 100;
    b = 80;
    
    // 使用if-else
    if (a > b)
      max_val = a;
    else
      max_val = b;
    $display("使用if-else: max_val = %0d", max_val);
    
    // 使用三元运算符 (更简洁)
    max_val = (a > b) ? a : b;
    $display("使用三元运算符: max_val = %0d", max_val);
    
    $display("");
  end

  //--------------------------------------------------------------------------
  // 测试组合逻辑
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 测试组合逻辑MUX =====");
    
    in0 = 10; in1 = 20; in2 = 30; in3 = 40;
    
    sel = 2'b00; #1;
    $display("sel=%b -> mux_out=%0d", sel, mux_out);
    
    sel = 2'b01; #1;
    $display("sel=%b -> mux_out=%0d", sel, mux_out);
    
    sel = 2'b10; #1;
    $display("sel=%b -> mux_out=%0d", sel, mux_out);
    
    sel = 2'b11; #1;
    $display("sel=%b -> mux_out=%0d", sel, mux_out);
    
    $display("");
  end
  
  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  //--------------------------------------------------------------------------
  // 测试时序逻辑
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 测试时序逻辑寄存器 =====");
    
    // 初始化
    data_in = 0;
    valid = 0;
    
    // 等待时钟上升沿
    @(posedge clk);
    valid = 1;
    data_in = 55;
    $display("时间%0t: 设置valid=1, data_in=%0d", $time, data_in);
    
    @(posedge clk);
    $display("时间%0t: registered_data=%0d", $time, registered_data);
    
    #20 $finish;
  end

endmodule
