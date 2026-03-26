// ===================================
// 关联数组示例 (Associative Array)
// 知识点8: 第2章 SystemVerilog数据类型
// ===================================

module associative_array_example;
  
  // 1. 声明不同类型的关联数组
  int mem_model[*];           // 通配符索引(任意整数索引),用于大容量存储器建模
  logic [31:0] reg_file[bit[7:0]];  // 8位地址索引,用于寄存器文件建模
  string config_table[string];       // 字符串索引,用于配置参数表
  int sparse_mem[integer];            // 整数索引(明确类型),用于稀疏存储器
  
  // 用于遍历的变量
  int key;                    // 整数键,用于遍历整数索引的关联数组
  string str_key;             // 字符串键,用于遍历字符串索引的关联数组
  bit [7:0] addr;             // 地址键,用于遍历寄存器文件
  
  // 稀疏存储器模型
  int huge_mem[*];            // 稀疏存储器数组,模拟大地址空间但只存储实际使用的地址
  
  initial begin
    $display("========================================");
    $display("关联数组示例");
    $display("========================================\n");
    
    //================================================================
    // 2. 整数索引关联数组 - 大容量存储器建模
    //================================================================
    $display("【示例1】大容量存储器建模");
    $display("----------------------------------------");
    
    // 只存储实际使用的地址,节省内存
    mem_model[32'h0000_1000] = 32'hDEAD_BEEF;
    mem_model[32'h0000_2000] = 32'hCAFE_BABE;
    mem_model[32'hFFFF_0000] = 32'h1234_5678;
    
    $display("存储器大小: %0d 个条目", mem_model.num());
    $display("地址 0x00001000: 0x%h", mem_model[32'h0000_1000]);
    $display("地址 0x00002000: 0x%h", mem_model[32'h0000_2000]);
    $display("地址 0xFFFF0000: 0x%h", mem_model[32'hFFFF_0000]);
    
    // 检查地址是否存在
    $display("\n地址存在性检查:");
    $display("  0x00001000 存在? %b", mem_model.exists(32'h0000_1000));
    $display("  0x00003000 存在? %b", mem_model.exists(32'h0000_3000));
    
    // 访问不存在的键返回默认值
    $display("  未初始化地址 0x00003000: 0x%h (默认值)", mem_model[32'h0000_3000]);
    
    //================================================================
    // 3. 定宽数字索引 - 寄存器文件
    //================================================================
    $display("\n【示例2】寄存器文件建模");
    $display("----------------------------------------");
    
    // 只定义实际存在的寄存器
    reg_file[8'h00] = 32'h1000_0000;  // 控制寄存器
    reg_file[8'h04] = 32'h2000_0000;  // 状态寄存器
    reg_file[8'h08] = 32'h3000_0000;  // 数据寄存器
    reg_file[8'h0C] = 32'h4000_0000;  // 中断寄存器
    
    $display("寄存器文件大小: %0d 个寄存器", reg_file.size());
    
    // 遍历所有寄存器
    $display("\n寄存器列表:");
    if (reg_file.first(addr)) begin
      do begin
        $display("  Reg[0x%02h] = 0x%h", addr, reg_file[addr]);
      end while (reg_file.next(addr));
    end
    
    //================================================================
    // 4. 字符串索引关联数组 - 配置表
    //================================================================
    $display("\n【示例3】配置参数表");
    $display("----------------------------------------");
    
    // 使用字符串作为键,便于理解和维护
    config_table["MAX_BURST_LEN"] = "16";
    config_table["CACHE_SIZE"] = "1024";
    config_table["FIFO_DEPTH"] = "256";
    config_table["BUS_WIDTH"] = "64";
    
    $display("配置参数数量: %0d", config_table.num());
    
    $display("\n配置参数列表:");
    if (config_table.first(str_key)) begin
      do begin
        $display("  %s = %s", str_key, config_table[str_key]);
      end while (config_table.next(str_key));
    end
    
    //================================================================
    // 5. 关联数组遍历方法
    //================================================================
    $display("\n【示例4】关联数组遍历方法");
    $display("----------------------------------------");
    
    // 方法1: first/next遍历
    $display("方法1: first/next遍历");
    if (mem_model.first(key)) begin
      $display("  正序遍历:");
      do begin
        $display("    mem[0x%08h] = 0x%08h", key, mem_model[key]);
      end while (mem_model.next(key));
    end
    
    // 方法2: last/prev遍历(逆序)
    $display("\n方法2: last/prev遍历(逆序)");
    if (mem_model.last(key)) begin
      $display("  逆序遍历:");
      do begin
        $display("    mem[0x%08h] = 0x%08h", key, mem_model[key]);
      end while (mem_model.prev(key));
    end
    
    // 方法3: foreach遍历(最简洁)
    $display("\n方法3: foreach遍历(最简洁)");
    foreach (mem_model[k])
      $display("    mem[0x%08h] = 0x%08h", k, mem_model[k]);
    
    //================================================================
    // 6. 删除元素
    //================================================================
    $display("\n【示例5】删除元素");
    $display("----------------------------------------");
    
    $display("删除前大小: %0d", mem_model.num());
    mem_model.delete(32'h0000_1000);  // 删除指定键
    $display("删除地址 0x00001000 后大小: %0d", mem_model.num());
    $display("地址 0x00001000 存在? %b", mem_model.exists(32'h0000_1000));
    
    // 删除整个数组
    mem_model.delete();
    $display("清空数组后大小: %0d", mem_model.size());
    
    //================================================================
    // 7. 实际应用: 稀疏存储器模型
    //================================================================
    $display("\n【示例6】实际应用: 稀疏存储器模型");
    $display("----------------------------------------");
    
    // 模拟1GB地址空间,但只存储实际使用的地址
    // huge_mem已在模块级别声明
    
    // 只写入少量数据
    huge_mem[32'h0000_0000] = 100;
    huge_mem[32'h1000_0000] = 200;
    huge_mem[32'h2000_0000] = 300;
    huge_mem[32'h3000_0000] = 400;
    
    $display("模拟地址空间: 1GB (32位地址)");
    $display("实际存储条目: %0d", huge_mem.num());
    $display("内存占用: 远小于定宽数组(需1GB内存)");
    
    $display("\n稀疏存储器内容:");
    foreach (huge_mem[addr])
      $display("  Addr[0x%08h] = %0d", addr, huge_mem[addr]);
    
    //================================================================
    // 8. 关联数组 vs 定宽数组 vs 动态数组对比
    //================================================================
    $display("\n【对比总结】");
    $display("========================================");
    $display("数组类型      | 大小确定 | 内存占用    | 适用场景");
    $display("--------------|---------|------------|------------------");
    $display("定宽数组      | 编译时   | 固定        | 固定大小数据");
    $display("动态数组      | 运行时   | 连续分配    | 动态大小数据");
    $display("关联数组      | 动态增长 | 稀疏存储    | 稀疏数据/大空间");
    $display("========================================");
    
    $display("\n示例完成!");
  end
  
endmodule
