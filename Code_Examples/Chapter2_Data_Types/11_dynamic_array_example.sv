// ===================================
// 动态数组示例 (Dynamic Array)
// 知识点7: 第2章 SystemVerilog数据类型
// ===================================

module dynamic_array_example;
  
  // 1. 声明动态数组 (方括号为空)
  int dyn_arr[];      // 动态整型数组,用于演示动态数组基本操作
  logic [7:0] data[]; // 动态8位向量数组,用于演示向量类型的动态数组
  
  // 定宽数组与动态数组转换示例
  int fixed_arr[5];            // 定宽数组,用于演示定宽到动态的转换
  int dynamic_arr[];           // 动态数组,用于演示数组转换
  
  // 数据包缓冲示例
  logic [7:0] packet[];        // 数据包缓冲区,用于演示实际应用场景
  int packet_size;             // 数据包大小,用于确定动态数组尺寸
  
  initial begin
    $display("========================================");
    $display("动态数组示例");
    $display("========================================\n");
    
    // 2. 分配内存 - 方法1: 使用new[size]
    dyn_arr = new[5];  // 分配5个元素
    $display("步骤1: 分配5个元素的空间");
    $display("数组大小: %0d", dyn_arr.size());
    
    // 3. 初始化数组
    foreach (dyn_arr[i])
      dyn_arr[i] = i * 10;
    
    $display("\n数组内容: %p", dyn_arr);
    
    // 4. 调整大小并保留原数据
    $display("\n步骤2: 扩展数组到8个元素,保留原数据");
    dyn_arr = new[8](dyn_arr);  // 扩展到8个元素,保留原数据
    $display("新数组大小: %0d", dyn_arr.size());
    $display("数组内容: %p", dyn_arr);  // 前5个元素保留,后3个为默认值0
    
    // 5. 缩小数组
    $display("\n步骤3: 缩小数组到3个元素");
    dyn_arr = new[3](dyn_arr);  // 缩小到3个元素,保留前3个
    $display("新数组大小: %0d", dyn_arr.size());
    $display("数组内容: %p", dyn_arr);
    
    // 6. 删除数组
    $display("\n步骤4: 删除数组");
    dyn_arr.delete();
    $display("删除后数组大小: %0d", dyn_arr.size());
    
    // 7. 动态数组与定宽数组的转换
    $display("\n========================================");
    $display("动态数组与定宽数组的转换");
    $display("========================================");
    
    // 初始化定宽数组
    fixed_arr = '{10, 20, 30, 40, 50};
    
    // 定宽 -> 动态 (自动分配内存并复制)
    dynamic_arr = fixed_arr;
    $display("\n定宽数组: %p", fixed_arr);
    $display("动态数组: %p", dynamic_arr);
    $display("动态数组大小: %0d", dynamic_arr.size());
    
    // 8. 动态数组的数组方法
    $display("\n========================================");
    $display("动态数组的数组方法");
    $display("========================================");
    
    dynamic_arr = new[6];
    foreach (dynamic_arr[i])
      dynamic_arr[i] = $urandom_range(1, 100);
    
    $display("\n随机数组: %p", dynamic_arr);
    $display("数组大小: %0d", dynamic_arr.size());
    $display("数组求和: %0d", dynamic_arr.sum());
    $display("最大值: %p", dynamic_arr.max());
    $display("最小值: %p", dynamic_arr.min());
    
    // 排序
    dynamic_arr.sort();
    $display("升序排序: %p", dynamic_arr);
    
    dynamic_arr.rsort();
    $display("降序排序: %p", dynamic_arr);
    
    // 9. 实际应用场景
    $display("\n========================================");
    $display("实际应用场景: 数据包缓冲");
    $display("========================================");
    
    // 仿真时根据实际数据包大小分配内存
    packet_size = 10 + $urandom_range(0, 20);  // 10-30字节随机大小
    packet = new[packet_size];
    
    // 填充数据
    foreach (packet[i])
      packet[i] = $urandom_range(0, 255);
    
    $display("\n数据包大小: %0d 字节", packet_size);
    $display("数据包内容: %p", packet);
    
    // 处理后需要更大缓冲区
    packet = new[packet_size * 2](packet);  // 扩展2倍
    $display("\n扩展后大小: %0d 字节", packet.size());
    
    $display("\n========================================");
    $display("示例完成");
    $display("========================================");
  end
  
endmodule
