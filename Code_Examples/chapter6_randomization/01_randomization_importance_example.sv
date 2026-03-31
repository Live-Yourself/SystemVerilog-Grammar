//=====================================================================
// 章节：第6章 随机化
// 知识点：6.1 随机化的重要性
// 文件名：01_randomization_importance_example.sv
// 描述：演示随机化测试相比定向测试的优势
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module randomization_importance_demo;

  //=====================================================================
  // 定义随机事务类 - 放在initial块外
  //=====================================================================
  class transaction;
    // 随机变量：定义在initial块外的类成员
    rand bit [31:0] addr;    // 随机地址
    rand bit [31:0] data;    // 随机数据
    rand bit        write;   // 随机读写标志（0=读，1=写）
    
    // 约束块：限制随机范围，确保生成有效事务
    constraint valid_addr {
      addr inside {[32'h0000_0000:32'h0FFF_FFFF]};  // 限制在有效地址范围内
    }
    
    constraint data_range {
      data inside {[0:1023]};  // 限制数据范围
    }
  endclass

  //=====================================================================
  // 定义统计信息类 - 放在initial块外
  //=====================================================================
  class coverage_stats;
    int total_transactions = 0;
    int write_count = 0;
    int read_count = 0;
    int addr_ranges[4] = '{0, 0, 0, 0};  // 4个地址范围的统计
    
    // 更新统计信息
    function void update_stats(bit [31:0] addr, bit write);
      total_transactions++;
      if (write) write_count++;
      else read_count++;
      
      // 统计地址范围
      if (addr < 32'h0400_0000) addr_ranges[0]++;
      else if (addr < 32'h0800_0000) addr_ranges[1]++;
      else if (addr < 32'h0C00_0000) addr_ranges[2]++;
      else addr_ranges[3]++;
    endfunction
    
    // 显示统计结果
    function void display_stats();
      $display("\n==============================================");
      $display("        随机化测试统计结果");
      $display("==============================================");
      $display("总事务数: %0d", total_transactions);
      $display("写事务数: %0d (%.1f%%)", write_count, 
               (write_count * 100.0) / total_transactions);
      $display("读事务数: %0d (%.1f%%)", read_count, 
               (read_count * 100.0) / total_transactions);
      $display("\n地址范围分布:");
      $display("  范围0 [0x0000_0000-0x03FF_FFFF]: %0d (%.1f%%)", 
               addr_ranges[0], (addr_ranges[0] * 100.0) / total_transactions);
      $display("  范围1 [0x0400_0000-0x07FF_FFFF]: %0d (%.1f%%)", 
               addr_ranges[1], (addr_ranges[1] * 100.0) / total_transactions);
      $display("  范围2 [0x0800_0000-0x0BFF_FFFF]: %0d (%.1f%%)", 
               addr_ranges[2], (addr_ranges[2] * 100.0) / total_transactions);
      $display("  范围3 [0x0C00_0000-0x0FFF_FFFF]: %0d (%.1f%%)", 
               addr_ranges[3], (addr_ranges[3] * 100.0) / total_transactions);
      $display("==============================================\n");
    endfunction
  endclass

  //=====================================================================
  // 测试执行 - 放在initial块内
  //=====================================================================
  initial begin
    // 定义局部变量
    transaction trans;      // 事务句柄
    coverage_stats stats;   // 统计信息句柄
    int success_count = 0;  // 成功随机化次数
    int fail_count = 0;     // 随机化失败次数
    
    // 创建对象
    trans = new();
    stats = new();
    
    $display("\n================================================");
    $display("        第6章 6.1 随机化的重要性 示例演示");
    $display("================================================");
    $display("\n【场景1】生成10个随机事务，展示随机化优势\n");
    
    // 生成10个随机事务
    for (int i = 0; i < 10; i++) begin
      if (trans.randomize()) begin  // 调用随机化函数
        success_count++;
        stats.update_stats(trans.addr, trans.write);
        
        $display("事务%0d: addr=0x%08h, data=%4d, %s", 
                 i, trans.addr, trans.data, trans.write ? "WRITE" : "READ");
      end else begin
        fail_count++;
        $display("事务%0d: 随机化失败", i);
      end
    end
    
    // 显示统计结果
    stats.display_stats();
    
    $display("\n【场景2】对比：定向测试 vs 随机化测试");
    $display("----------------------------------------------");
    $display("定向测试：需要手动编写每个测试用例");
    $display("  - 例如：固定地址0x1000_0000写入数据0x1234");
    $display("  - 测试场景有限，难以覆盖所有边界条件");
    $display("  - 代码重复度高，维护困难");
    $display("\n随机化测试：通过约束自动生成测试用例");
    $display("  - 自动生成10个不同的事务（见上方输出）");
    $display("  - 覆盖多个地址范围、读写类型和数据值");
    $display("  - 通过约束保证测试有效性，避免无效场景");
    $display("----------------------------------------------");
    
    $display("\n【场景3】随机化的可重现性演示");
    $display("设置随机种子，确保相同种子产生相同结果");
    $display("  - 使用$urandom(seed)或randomize()的种子参数");
    $display("  - 便于调试失败的测试用例");
    $display("  - 支持回归测试\n");
    
    // 演示种子控制
    process::self().srandom(100);  // 设置随机种子
    $display("设置随机种子=100，生成3个事务:");
    for (int i = 0; i < 3; i++) begin
      if (trans.randomize()) begin
        $display("  事务%0d: addr=0x%08h, data=%4d, %s", 
                 i, trans.addr, trans.data, trans.write ? "WRITE" : "READ");
      end
    end
    
    $display("\n================================================");
    $display("        演示结束");
    $display("================================================\n");
    
    #10 $finish;
  end

endmodule
