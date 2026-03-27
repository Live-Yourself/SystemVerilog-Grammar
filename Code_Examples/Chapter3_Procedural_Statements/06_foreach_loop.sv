//==============================================================================
// 文件名: 06_foreach_loop.sv
// 知识点: foreach循环
// 章节: 第3章 过程语句
// 说明: 演示foreach循环遍历数组的用法
//==============================================================================

module foreach_loop;

  logic [7:0] simple_arr [16];
  logic [7:0] matrix [4][8];  // 4行8列
  logic [7:0] cube [2][4][8]; // 2层4行8列
  
  //--------------------------------------------------------------------------
  // 示例1: foreach遍历一维数组
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: foreach遍历一维数组 =====");
    
    // 初始化
    foreach (simple_arr[i]) begin
      simple_arr[i] = i * 10;
    end
    
    // 打印
    foreach (simple_arr[i]) begin
      $display("simple_arr[%0d] = %0d", i, simple_arr[i]);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: foreach遍历二维数组
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: foreach遍历二维数组 =====");
    
    // 初始化矩阵
    foreach (matrix[row, col]) begin
      matrix[row][col] = row * 8 + col;
    end
    
    // 打印矩阵
    $display("矩阵内容:");
    foreach (matrix[row]) begin
      $write("  行%0d: ", row);
      foreach (matrix[row, col]) begin
        $write("%3d ", matrix[row][col]);
      end
      $display("");
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: foreach遍历三维数组
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例3: foreach遍历三维数组 =====");
    
    // 初始化三维数组
    foreach (cube[layer, row, col]) begin
      cube[layer][row][col] = layer * 100 + row * 10 + col;
    end
    
    // 打印部分元素
    $display("三维数组示例元素:");
    foreach (cube[layer, row, col]) begin
      if (row == 0 && col < 3) begin  // 只打印每层的前3个元素
        $display("  cube[%0d][%0d][%0d] = %0d", 
                 layer, row, col, cube[layer][row][col]);
      end
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: foreach vs for 对比
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: foreach vs for 对比 =====");
    
    logic [7:0] test_arr [8];
    
    // 方式1: for循环
    $display("使用for循环:");
    for (int i = 0; i < 8; i++) begin
      test_arr[i] = i;
      $display("  test_arr[%0d] = %0d", i, test_arr[i]);
    end
    
    // 方式2: foreach循环
    $display("使用foreach循环:");
    foreach (test_arr[i]) begin
      test_arr[i] = i * 2;
      $display("  test_arr[%0d] = %0d", i, test_arr[i]);
    end
    
    $display("");
    $display("foreach的优势:");
    $display("  ✓ 语法简洁,不需要索引变量");
    $display("  ✓ 自动遍历所有元素");
    $display("  ✓ 避免数组越界错误");
    $display("  ✓ 不需要知道数组大小");
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: foreach遍历动态数组
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例5: foreach遍历动态数组 =====");
    
    logic [7:0] dyn_arr[];
    
    // 分配内存
    dyn_arr = new[10];
    
    // 初始化
    foreach (dyn_arr[i]) begin
      dyn_arr[i] = $urandom_range(0, 255);
    end
    
    // 打印
    $display("动态数组内容:");
    foreach (dyn_arr[i]) begin
      $display("  dyn_arr[%0d] = %0d", i, dyn_arr[i]);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: foreach遍历队列
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例6: foreach遍历队列 =====");
    
    logic [7:0] queue_arr[$];
    
    // 填充队列
    queue_arr.push_back(10);
    queue_arr.push_back(20);
    queue_arr.push_back(30);
    queue_arr.push_back(40);
    
    // 遍历队列
    $display("队列内容:");
    foreach (queue_arr[i]) begin
      $display("  queue_arr[%0d] = %0d", i, queue_arr[i]);
    end
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: foreach遍历关联数组
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例7: foreach遍历关联数组 =====");
    
    logic [7:0] assoc_arr[int];
    
    // 填充关联数组
    assoc_arr[10] = 100;
    assoc_arr[20] = 200;
    assoc_arr[30] = 300;
    
    // 遍历关联数组
    $display("关联数组内容:");
    foreach (assoc_arr[key]) begin
      $display("  assoc_arr[%0d] = %0d", key, assoc_arr[key]);
    end
    
    $display("");
    $display("注意: 关联数组的遍历顺序不确定!");
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: foreach只读特性
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例8: foreach的只读索引 =====");
    
    logic [7:0] arr [8];
    
    // foreach的循环变量是只读的,不能修改
    foreach (arr[i]) begin
      arr[i] = i * 10;  // ✓ 可以修改数组元素
      // i = i + 1;      // ✗ 错误! 不能修改循环变量i
    end
    
    $display("foreach循环变量是只读的,不能在循环体内修改");
    $display("");
    
    $finish;
  end

endmodule
