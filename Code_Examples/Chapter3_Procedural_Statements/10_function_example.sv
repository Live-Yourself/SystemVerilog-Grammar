//==============================================================================
// 文件名: 10_function_example.sv
// 知识点: 函数function
// 章节: 第3章 过程语句
// 说明: 演示函数的定义、调用和返回值
//==============================================================================

module function_example;

  logic [7:0]  data;
  logic [15:0] result;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本函数定义和调用
  //--------------------------------------------------------------------------
  
  // 函数定义: 返回单个值
  function logic [7:0] double_value(input logic [7:0] value);
    return value * 2;
  endfunction
  
  initial begin
    $display("===== 示例1: 基本函数调用 =====");
    
    data = 10;
    result = double_value(data);
    $display("%0d * 2 = %0d", data, result);
    
    result = double_value(25);
    $display("25 * 2 = %0d", result);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: 函数返回值的方式
  //--------------------------------------------------------------------------
  
  // 方式1: 使用return语句
  function int add_return(input int a, input int b);
    return a + b;
  endfunction
  
  // 方式2: 使用函数名赋值 (Verilog风格)
  function int add_verilog_style(input int a, input int b);
    add_verilog_style = a + b;  // 函数名作为返回变量
  endfunction
  
  initial begin
    $display("===== 示例2: 函数返回值的方式 =====");
    
    int res1, res2;
    
    res1 = add_return(10, 20);
    $display("使用return: 10 + 20 = %0d", res1);
    
    res2 = add_verilog_style(10, 20);
    $display("使用函数名: 10 + 20 = %0d", res2);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: 函数的输入参数
  //--------------------------------------------------------------------------
  
  // 多个输入参数
  function logic [15:0] multiply(
    input logic [7:0] a,
    input logic [7:0] b
  );
    return a * b;
  endfunction
  
  // 带默认值的参数
  function int power(
    input int base,
    input int exp = 2  // 默认值为2
  );
    int result = 1;
    
    for (int i = 0; i < exp; i++) begin
      result *= base;
    end
    
    return result;
  endfunction
  
  initial begin
    $display("===== 示例3: 函数的输入参数 =====");
    
    result = multiply(12, 10);
    $display("12 * 10 = %0d", result);
    
    result = multiply(15, 15);
    $display("15 * 15 = %0d", result);
    
    // 使用默认参数
    result = power(3);      // 3^2 = 9
    $display("3^2 = %0d", result);
    
    result = power(2, 8);   // 2^8 = 256
    $display("2^8 = %0d", result);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: 函数可以调用其他函数
  //--------------------------------------------------------------------------
  
  function int square(input int x);
    return x * x;
  endfunction
  
  function int sum_of_squares(input int a, input int b);
    return square(a) + square(b);  // 调用其他函数
  endfunction
  
  initial begin
    $display("===== 示例4: 函数调用函数 =====");
    
    int res;
    
    res = square(5);
    $display("5^2 = %0d", res);
    
    res = sum_of_squares(3, 4);
    $display("3^2 + 4^2 = %0d", res);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: 函数可以访问模块变量
  //--------------------------------------------------------------------------
  
  logic [7:0] global_data;
  
  function logic [7:0] increment_global;
    // 函数可以读取但不能修改模块变量
    // global_data = global_data + 1;  // ✗ 错误! 不能修改
    
    // 只能读取
    return global_data + 1;  // ✓ 可以读取
  endfunction
  
  initial begin
    $display("===== 示例5: 函数访问模块变量 =====");
    
    global_data = 100;
    $display("global_data = %0d", global_data);
    
    result = increment_global();
    $display("increment_global() = %0d", result);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: 函数中的局部变量
  //--------------------------------------------------------------------------
  
  function logic [15:0] factorial(input int n);
    // 局部变量
    logic [15:0] result_local;
    
    result_local = 1;
    
    for (int i = 2; i <= n; i++) begin
      result_local = result_local * i;
    end
    
    return result_local;
  endfunction
  
  initial begin
    $display("===== 示例6: 函数中的局部变量 =====");
    
    result = factorial(5);
    $display("5! = %0d", result);
    
    result = factorial(7);
    $display("7! = %0d", result);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: 常用函数类型
  //--------------------------------------------------------------------------
  
  // 位操作函数
  function logic [7:0] reverse_bits(input logic [7:0] data);
    logic [7:0] reversed;
    
    for (int i = 0; i < 8; i++) begin
      reversed[i] = data[7-i];
    end
    
    return reversed;
  endfunction
  
  // 比较函数
  function logic [7:0] max_value(
    input logic [7:0] a,
    input logic [7:0] b
  );
    if (a > b)
      return a;
    else
      return b;
  endfunction
  
  // 校验和计算
  function logic [7:0] calculate_checksum(
    input logic [7:0] data[],
    input int length
  );
    logic [7:0] checksum;
    
    checksum = 0;
    for (int i = 0; i < length; i++) begin
      checksum = checksum ^ data[i];  // XOR校验
    end
    
    return checksum;
  endfunction
  
  initial begin
    $display("===== 示例7: 常用函数类型 =====");
    
    logic [7:0] test_data;
    logic [7:0] data_arr[];
    logic [7:0] checksum;
    
    test_data = 8'b11010010;
    $display("原数据: %b", test_data);
    $display("反转后: %b", reverse_bits(test_data));
    
    $display("max(10, 20) = %0d", max_value(10, 20));
    $display("max(30, 20) = %0d", max_value(30, 20));
    
    data_arr = new[4];
    data_arr = '{8'h11, 8'h22, 8'h33, 8'h44};
    checksum = calculate_checksum(data_arr, 4);
    $display("校验和: 0x%h", checksum);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: 自动函数(automatic)
  //--------------------------------------------------------------------------
  
  // automatic函数: 每次调用分配新的局部变量
  // 用于递归或并行调用
  function automatic int fibonacci(input int n);
    if (n <= 1)
      return n;
    else
      return fibonacci(n-1) + fibonacci(n-2);  // 递归调用
  endfunction
  
  initial begin
    $display("===== 示例8: 自动函数(递归) =====");
    
    int res;
    
    res = fibonacci(10);
    $display("fibonacci(10) = %0d", res);
    
    res = fibonacci(15);
    $display("fibonacci(15) = %0d", res);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例9: 函数vs表达式
  //--------------------------------------------------------------------------
  
  // 函数可以用于表达式
  function logic is_even(input int value);
    return (value % 2 == 0);
  endfunction
  
  initial begin
    $display("===== 示例9: 函数用于表达式 =====");
    
    int test_val;
    
    test_val = 10;
    $display("%0d 是偶数? %s", test_val, is_even(test_val) ? "是" : "否");
    
    test_val = 15;
    $display("%0d 是偶数? %s", test_val, is_even(test_val) ? "是" : "否");
    
    // 函数可以直接用于条件判断
    if (is_even(20))
      $display("20是偶数");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例10: 实际应用 - 数据包处理函数
  //--------------------------------------------------------------------------
  
  // 计算数据包长度
  function int get_packet_length(input logic [7:0] header);
    // 假设头部包含长度信息
    return header[3:0];  // 低4位表示长度
  endfunction
  
  // 验证数据包
  function logic validate_packet(
    input logic [7:0] header,
    input logic [7:0] payload[],
    input logic [7:0] expected_checksum
  );
    logic [7:0] calc_checksum;
    
    // 计算校验和
    calc_checksum = header;
    foreach (payload[i]) begin
      calc_checksum ^= payload[i];
    end
    
    // 比较校验和
    return (calc_checksum == expected_checksum);
  endfunction
  
  initial begin
    $display("===== 示例10: 数据包处理函数 =====");
    
    logic [7:0] pkt_header;
    logic [7:0] pkt_payload[];
    logic [7:0] pkt_checksum;
    int pkt_len;
    logic is_valid;
    
    // 构造数据包
    pkt_header = 8'hA3;  // 长度字段为3
    pkt_payload = new[3];
    pkt_payload = '{8'h11, 8'h22, 8'h33};
    pkt_checksum = 8'h87;  // A3^11^22^33 = 87
    
    // 获取长度
    pkt_len = get_packet_length(pkt_header);
    $display("数据包长度: %0d", pkt_len);
    
    // 验证数据包
    is_valid = validate_packet(pkt_header, pkt_payload, pkt_checksum);
    $display("数据包验证: %s", is_valid ? "通过" : "失败");
    
    // 测试错误校验和
    pkt_checksum = 8'h00;
    is_valid = validate_packet(pkt_header, pkt_payload, pkt_checksum);
    $display("错误校验和验证: %s", is_valid ? "通过" : "失败");
    
    $display("");
    $finish;
  end

endmodule
