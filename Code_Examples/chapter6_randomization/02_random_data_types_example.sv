//=====================================================================
// 章节：第6章 随机化
// 知识点：6.2 随机数据类型
// 文件名：02_random_data_types_example.sv
// 描述：演示rand和randc关键字的区别和应用场景
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module random_data_types_demo;

  //=====================================================================
  // 定义仅使用rand的类
  //=====================================================================
  class RandOnlyPacket;
    rand bit [7:0] cmd;      // 纯随机命令
    rand bit [31:0] addr;    // 纯随机地址
    rand bit [31:0] data;    // 纯随机数据
    
    constraint valid_addr {
      addr inside {[32'h0000_0000:32'h000F_FFFF]};
    }
  endclass

  //=====================================================================
  // 定义使用randc的类
  //=====================================================================
  class RandcCommandSeq;
    randc bit [2:0] cmd_type;  // 循环随机：0-7顺序覆盖
    rand bit [7:0] payload;    // 纯随机负载
  endclass

  //=====================================================================
  // 定义混合使用rand和randc的类
  //=====================================================================
  class MixedRandomTest;
    randc bit [1:0] mode;      // 循环随机模式：确保覆盖所有模式
    randc bit [3:0] command;   // 循环随机命令：确保覆盖所有命令
    rand bit [31:0] address;   // 纯随机地址
    rand bit [31:0] wr_data;   // 纯随机写数据
    rand bit [31:0] rd_data;   // 纯随机读数据
    
    constraint valid_addr {
      address < 32'h10000;
    }
  endclass

  //=====================================================================
  // 统计类：记录rand和randc的分布
  //=====================================================================
  class RandomStats;
    int cmd_count[256];         // 记录256个命令的出现次数
    int cmd_type_count[8];      // 记录8个命令类型的出现次数
    int mode_count[4];          // 记录4个模式的出现次数
    
    function void update_rand_cmd(bit [7:0] cmd);
      cmd_count[cmd]++;
    endfunction
    
    function void update_randc_cmd_type(bit [2:0] cmd_type);
      cmd_type_count[cmd_type]++;
    endfunction
    
    function void update_randc_mode(bit [1:0] mode);
      mode_count[mode]++;
    endfunction
    
    function void display_stats(string label, int count_array[], int size);
      $display("\n    %s分布统计:", label);
      for (int i = 0; i < size; i++) begin
        $display("      [%2d] = %3d次", i, count_array[i]);
      end
    endfunction
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    RandOnlyPacket rand_pkt;
    RandcCommandSeq randc_seq;
    MixedRandomTest mixed_test;
    RandomStats stats;
    
    rand_pkt = new();
    randc_seq = new();
    mixed_test = new();
    stats = new();
    
    $display("\n================================================");
    $display("        第6章 6.2 随机数据类型 示例演示");
    $display("================================================\n");
    
    //=========================================================================
    // 场景1：演示rand的行为 - 可能出现重复值
    //=========================================================================
    $display("【场景1】rand关键字演示 - 生成20个随机命令");
    $display("说明：rand是纯随机，值可能重复出现\n");
    
    for (int i = 0; i < 20; i++) begin
      if (rand_pkt.randomize()) begin
        stats.update_rand_cmd(rand_pkt.cmd);
        
        if (i < 10) begin  // 只显示前10个
          $display("  事务%2d: cmd=%3d, addr=0x%08h, data=0x%08h", 
                   i, rand_pkt.cmd, rand_pkt.addr, rand_pkt.data);
        end
      end
    end
    
    $display("  ...（显示前10个，共20个）");
    stats.display_stats("rand命令", stats.cmd_count, 256);
    
    // 检查是否有重复
    int repeat_count = 0;
    for (int i = 0; i < 256; i++) begin
      if (stats.cmd_count[i] > 1) repeat_count++;
    end
    $display("  统计：%0d个命令值出现重复", repeat_count);
    
    //=========================================================================
    // 场景2：演示randc的行为 - 循环覆盖，避免重复
    //=========================================================================
    $display("\n【场景2】randc关键字演示 - 生成10个循环随机命令类型");
    $display("说明：randc循环遍历，每个值只出现一次后重置\n");
    
    // 重置统计
    for (int i = 0; i < 8; i++) stats.cmd_type_count[i] = 0;
    
    for (int i = 0; i < 10; i++) begin
      if (randc_seq.randomize()) begin
        stats.update_randc_cmd_type(randc_seq.cmd_type);
        $display("  事务%2d: cmd_type=%d, payload=%d", 
                 i, randc_seq.cmd_type, randc_seq.payload);
      end
    end
    
    stats.display_stats("randc命令类型", stats.cmd_type_count, 8);
    
    // 验证randc的特性：前8个应该覆盖所有值
    int covered_values = 0;
    for (int i = 0; i < 8; i++) begin
      if (stats.cmd_type_count[i] >= 1) covered_values++;
    end
    $display("  统计：前8个事务覆盖了%0d/8个命令类型值", covered_values);
    
    //=========================================================================
    // 场景3：继续生成更多，观察randc的循环行为
    //=========================================================================
    $display("\n【场景3】继续生成8个，观察randc的循环覆盖特性");
    $display("说明：所有值使用完后，开始新的循环周期\n");
    
    for (int i = 0; i < 8; i++) begin
      if (randc_seq.randomize()) begin
        stats.update_randc_cmd_type(randc_seq.cmd_type);
        $display("  事务%2d: cmd_type=%d, payload=%d", 
                 i+10, randc_seq.cmd_type, randc_seq.payload);
      end
    end
    
    stats.display_stats("完整周期命令类型", stats.cmd_type_count, 8);
    $display("  说明：每个值出现2-3次，均匀分布");
    
    //=========================================================================
    // 场景4：混合使用rand和randc
    //=========================================================================
    $display("\n【场景4】rand和randc混合使用演示");
    $display("说明：mode和command用randc确保覆盖，address和data用rand提供随机性\n");
    
    // 重置统计
    for (int i = 0; i < 4; i++) stats.mode_count[i] = 0;
    for (int i = 0; i < 16; i++) stats.cmd_count[i] = 0;
    
    for (int i = 0; i < 20; i++) begin
      if (mixed_test.randomize()) begin
        stats.update_randc_mode(mixed_test.mode);
        stats.update_rand_cmd(mixed_test.command);
        
        if (i < 8) begin
          $display("  事务%2d: mode=%d, command=%2d, addr=0x%08h", 
                   i, mixed_test.mode, mixed_test.command, mixed_test.address);
        end
      end
    end
    
    $display("  ...（显示前8个，共20个）");
    stats.display_stats("randc模式", stats.mode_count, 4);
    
    // 验证mode的randc特性
    covered_values = 0;
    for (int i = 0; i < 4; i++) begin
      if (stats.mode_count[i] >= 1) covered_values++;
    end
    $display("  统计：20个事务中覆盖了%0d/4个模式值", covered_values);
    
    //=========================================================================
    // 场景5：总结rand和randc的区别
    //=========================================================================
    $display("\n【场景5】rand vs randc 关键区别总结");
    $display("------------------------------------------------------------");
    $display("特性               | rand                    | randc");
    $display("------------------------------------------------------------");
    $display("随机方式           | 独立纯随机              | 循环遍历（排列）");
    $display("值重复             | 可能连续重复            | 周期内不会重复");
    $display("资源消耗           | 低                      | 高（需保存状态）");
    $display("适用位宽           | 任意                    | ≥2-bit");
    $display("典型应用           | 地址、数据              | 命令、操作码");
    $display("------------------------------------------------------------");
    
    $display("\n实际应用建议：");
    $display("  ✓ 地址、数据、长度等数值变量：使用rand");
    $display("  ✓ 命令、操作码、测试模式：使用randc");
    $display("  ✓ 需要覆盖所有可能值的场景：使用randc");
    $display("  ✓ 大范围值集合（>16-bit）：使用rand");
    
    #10 $finish;
  end

endmodule
