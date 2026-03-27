//==============================================================================
// 文件名: 03_for_loop.sv
// 知识点: for循环
// 章节: 第3章 过程语句
// 说明: 演示for循环的各种用法和注意事项
//==============================================================================

module for_loop;

  logic [7:0] data_array [16];
  logic [7:0] sum_result;
  logic [3:0] i;  // 循环变量
  logic [3:0] j;  // 循环变量
  logic [2:0] row, col;  // 多维数组索引
  logic [7:0] matrix [4][8];  // 4行8列矩阵
  
  //--------------------------------------------------------------------------
  // 示例1: 基本for循环
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: 基本for循环 =====");
    
    // 初始化数组
    for (i = 0; i < 16; i++) begin
      data_array[i] = i * 10;
    end
    
    // 打印数组内容
    for (i = 0; i < 16; i++) begin
      $display("data_array[%0d] = %0d", i, data_array[i]);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: for循环计算数组求和
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: for循环数组求和 =====");
    
    sum_result = 0;
    
    for (i = 0; i < 16; i++) begin
      sum_result = sum_result + data_array[i];
    end
    
    $display("数组总和 = %0d", sum_result);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: for循环的不同写法
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例3: for循环的不同写法 =====");
    
    // 写法1: 标准形式
    $display("写法1: 标准形式 (递增)");
    for (i = 0; i < 5; i++) begin
      $display("  i = %0d", i);
    end
    
    // 写法2: 递减循环
    $display("写法2: 递减循环");
    for (i = 7; i >= 4; i--) begin
      $display("  i = %0d", i);
    end
    
    // 写法3: 步长为2
    $display("写法3: 步长为2");
    for (i = 0; i < 10; i = i + 2) begin
      $display("  i = %0d", i);
    end
    
    // 写法4: 多个循环变量
    $display("写法4: 多个循环变量");
    for (i = 0, j = 15; i < 4; i++, j--) begin
      $display("  i=%0d, j=%0d", i, j);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: for循环遍历多维数组
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: for循环遍历多维数组 =====");
    
    // 初始化矩阵
    for (row = 0; row < 4; row++) begin
      for (col = 0; col < 8; col++) begin
        matrix[row][col] = row * 8 + col;
      end
    end
    
    // 打印矩阵
    $display("矩阵内容:");
    for (row = 0; row < 4; row++) begin
      $write("  行%0d: ", row);
      for (col = 0; col < 8; col++) begin
        $write("%3d ", matrix[row][col]);
      end
      $display("");
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: for循环与数组的复制和比较
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例5: for循环数组操作 =====");
    
    logic [7:0] source_arr [8];
    logic [7:0] dest_arr [8];
    logic       arrays_equal;
    
    // 初始化源数组
    for (i = 0; i < 8; i++) begin
      source_arr[i] = i * 5;
    end
    
    // 使用for循环复制数组
    for (i = 0; i < 8; i++) begin
      dest_arr[i] = source_arr[i];
    end
    
    $display("数组复制完成");
    
    // 使用for循环比较数组
    arrays_equal = 1;
    for (i = 0; i < 8; i++) begin
      if (dest_arr[i] != source_arr[i]) begin
        arrays_equal = 0;
        break;  // 发现不等,提前退出
      end
    end
    
    if (arrays_equal)
      $display("数组相等");
    else
      $display("数组不相等");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: for循环实现寄存器堆初始化
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例6: 寄存器堆初始化 =====");
    
    // 初始化所有寄存器为0
    for (int reg_idx = 0; reg_idx < 32; reg_idx++) begin
      register_file[reg_idx] = 32'h0;
    end
    
    // 初始化特殊寄存器
    register_file[0]  = 32'h0000_0000;  // R0总是0
    register_file[1]  = 32'h0000_0001;  // R1
    register_file[31] = 32'hFFFF_FFFF;  // R31
    
    $display("寄存器R0  = %h", register_file[0]);
    $display("寄存器R1  = %h", register_file[1]);
    $display("寄存器R31 = %h", register_file[31]);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: for循环在组合逻辑中的应用
  //--------------------------------------------------------------------------
  
  // 优先级编码器 (组合逻辑)
  logic [7:0] request_bus;
  logic [2:0] grant_index;
  logic       grant_valid;
  
  always_comb begin
    // ✓ 必须初始化所有输出,避免锁存器
    grant_valid = 0;
    grant_index = 0;
    
    // 从高位到低位查找第一个有效的请求
    // 注意: 即使if没有else,也不会产生锁存器
    // 原因: grant_valid和grant_index已经在循环前初始化
    for (int idx = 7; idx >= 0; idx--) begin
      if (request_bus[idx]) begin
        grant_index = idx[2:0];  // 只取低3位
        grant_valid = 1;
      end
      // 这里没有else是安全的,因为初始值已经设置为0
    end
  end
  
  //--------------------------------------------------------------------------
  // 示例8: for循环在时序逻辑中的应用
  //--------------------------------------------------------------------------
  
  logic        clk;
  logic        rst_n;
  logic [7:0]  shift_register [8];
  logic        shift_en;
  logic [7:0]  shift_in;
  
  // 移位寄存器
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位: 所有寄存器清零
      for (int idx = 0; idx < 8; idx++) begin
        shift_register[idx] <= 8'h00;
      end
    end else if (shift_en) begin
      // 移位操作
      for (int idx = 7; idx > 0; idx--) begin
        shift_register[idx] <= shift_register[idx-1];
      end
      shift_register[0] <= shift_in;
    end
  end
  
  //--------------------------------------------------------------------------
  // 示例9: for循环的优化 - 静态展开
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例9: for循环的静态展开 =====");
    
    // 编译时确定循环次数的for循环会被综合器展开
    // 这对于硬件实现非常重要
    
    $display("综合器会将for循环展开为并行硬件:");
    $display("  for (i=0; i<4; i++) begin");
    $display("    out[i] = in[i] & mask;");
    $display("  end");
    $display("");
    $display("展开后等价于:");
    $display("  out[0] = in[0] & mask;");
    $display("  out[1] = in[1] & mask;");
    $display("  out[2] = in[2] & mask;");
    $display("  out[3] = in[3] & mask;");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例10: for循环与generate的区别
  //--------------------------------------------------------------------------
  
  // generate for: 实例化多个模块
  // 以下代码展示generate的用法(与过程for循环对比)
  
  logic [7:0] parallel_in [4];
  logic [7:0] parallel_out [4];
  
  // 使用generate for实例化多个模块(综合时展开)
  genvar gi;
  generate
    for (gi = 0; gi < 4; gi++) begin : gen_buffer
      // 这里可以实例化模块,例如:
      // buffer u_buf (.in(parallel_in[gi]), .out(parallel_out[gi]));
      
      // 简单示例: 直接赋值
      assign parallel_out[gi] = parallel_in[gi];
    end
  endgenerate
  
  //--------------------------------------------------------------------------
  // 示例11: 测试组合逻辑优先级编码器
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例11: 测试优先级编码器 =====");
    
    // 测试用例1: 单个请求
    request_bus = 8'b0000_0100;
    #1;
    $display("request=%b -> grant_index=%0d, valid=%b", 
             request_bus, grant_index, grant_valid);
    
    // 测试用例2: 多个请求 (高优先级获胜)
    request_bus = 8'b0101_0100;
    #1;
    $display("request=%b -> grant_index=%0d, valid=%b", 
             request_bus, grant_index, grant_valid);
    
    // 测试用例3: 无请求
    request_bus = 8'b0000_0000;
    #1;
    $display("request=%b -> grant_index=%0d, valid=%b", 
             request_bus, grant_index, grant_valid);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例12: 测试移位寄存器
  //--------------------------------------------------------------------------
  
  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $display("===== 示例12: 测试移位寄存器 =====");
    
    // 初始化
    rst_n = 0;
    shift_en = 0;
    shift_in = 8'h00;
    
    // 复位
    #10 rst_n = 1;
    $display("复位完成");
    
    // 移位操作
    shift_en = 1;
    
    shift_in = 8'hAA;
    @(posedge clk);
    $display("时间%0t: shift_in=%h, R0=%h", $time, shift_in, shift_register[0]);
    
    shift_in = 8'hBB;
    @(posedge clk);
    $display("时间%0t: shift_in=%h, R0=%h, R1=%h", 
             $time, shift_in, shift_register[0], shift_register[1]);
    
    shift_in = 8'hCC;
    @(posedge clk);
    $display("时间%0t: shift_in=%h, R0=%h, R1=%h, R2=%h", 
             $time, shift_in, shift_register[0], 
             shift_register[1], shift_register[2]);
    
    #20;
    $display("");
    $display("最终寄存器状态:");
    for (int idx = 0; idx < 8; idx++) begin
      $display("  R[%0d] = %h", idx, shift_register[idx]);
    end
    
    #20 $finish;
  end

endmodule
