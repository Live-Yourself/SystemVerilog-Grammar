//=====================================================================
// 章节：第6章 随机化
// 知识点：6.3 约束（Constraints）
// 文件名：03_constraints_example.sv
// 描述：演示constraint基本语法、inside、dist、条件约束、foreach等
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module constraints_demo;

  //=====================================================================
  // 类1：inside集合约束
  //=====================================================================
  class InsideDemo;
    rand bit [7:0]  addr;
    rand bit [31:0] data;
    rand bit [3:0]  cmd;
    
    // inside：限定变量在指定范围或值集合内
    constraint c_addr_range {
      addr inside {[8:15], [20:30], 100};  // 三种写法混合
    }
    
    // inside：限定特定值列表
    constraint c_cmd_valid {
      cmd inside {0, 2, 4, 8};  // 只能是这几个值之一
    }
    
    // !inside：排除特定值
    constraint c_data_exclude {
      data !inside {0, 32'hFFFF_FFFF};  // 不能是全0或全1
    }
  endclass

  //=====================================================================
  // 类2：dist权重约束
  //=====================================================================
  class DistDemo;
    rand bit [7:0] pkt_len;
    rand bit [3:0] priority;
    
    // dist := 每个值单独分配权重
    constraint c_len_dist {
      // 小包:40, 中包:40, 大包:20  （相对权重比 2:2:1）
      pkt_len dist {[64:127]   := 40,
                    [128:255]  := 40,
                    [256:511]  := 20};
    }
    
    // dist :/ 范围总权重，自动均分给范围中每个值
    constraint c_priority_dist {
      // 总权重30，范围内3个值各得10
      // 总权重70，范围内7个值各得10
      // 实际效果：高优先级(0-2)概率 30/100，低优先级(3-9)概率 70/100
      priority dist {[0:2] :/ 30,
                     [3:9] :/ 70};
    }
  endclass

  //=====================================================================
  // 类3：条件约束（if-else 和 ->）
  //=====================================================================
  class ConditionalDemo;
    rand bit        rw;       // 0=读, 1=写
    rand bit [31:0] addr;
    rand bit [31:0] wdata;
    rand bit [7:0]  burst_len;
    
    // if-else：根据rw决定约束
    constraint c_rw_if_else {
      if (rw == 1) begin
        // 写操作：地址4字节对齐，数据有效
        addr[1:0] == 2'b00;
        wdata != 0;
      end else begin
        // 读操作：wdata无意义，不约束
        wdata == 0;
      end
    }
    
    // -> 隐含操作符：rw为写时，突发长度1-16
    constraint c_burst_impl {
      (rw == 1) -> burst_len inside {[1:16]};
      (rw == 0) -> burst_len == 1;  // 读操作固定长度
    }
    
    // -> 另一种写法：地址在有效范围内
    constraint c_addr_valid {
      (rw == 0) -> addr inside {[32'h0000_0000:32'h0000_03FF]};
      (rw == 1) -> addr inside {[32'h0000_0400:32'h0000_0FFF]};
    }
  endclass

  //=====================================================================
  // 类4：foreach迭代约束（动态数组）
  //=====================================================================
  class ForeachDemo;
    rand bit [7:0] payload[];   // 动态数组
    rand int         array_size;
    
    // 约束数组大小
    constraint c_size {
      array_size inside {[3:8]};
      payload.size() == array_size;
    }
    
    // foreach：约束每个数组元素
    constraint c_payload_range {
      foreach (payload[i]) {
        payload[i] inside {[10:99]};  // 每个元素在10-99之间
      }
    }
    
    // foreach + 元素间关系：递增序列
    constraint c_payload_incr {
      foreach (payload[i]) {
        if (i > 0) {
          payload[i] > payload[i-1];  // 后一个比前一个大
        }
      }
    }
  endclass

  //=====================================================================
  // 类5：关系约束 + solve...before
  //=====================================================================
  class RelationDemo;
    rand bit [7:0] total;
    rand bit [7:0] part_a;
    rand bit [7:0] part_b;
    
    // 关系约束：total = part_a + part_b
    constraint c_sum {
      total == part_a + part_b;
    }
    
    // 范围约束
    constraint c_range {
      part_a inside {[0:50]};
      part_b inside {[0:50]};
    }
    
    // solve...before：先求解part_a，再求解part_b和total
    // 这样part_a的分布更均匀
    constraint c_solve_order {
      solve part_a before part_b;
    }
  endclass

  //=====================================================================
  // 类6：软约束（soft）
  //=====================================================================
  class SoftDemo;
    rand bit [7:0] length;
    rand bit [31:0] addr;
    
    // 硬约束：必须满足
    constraint c_hard {
      length > 0;
      length <= 255;
    }
    
    // 软约束：优先满足，但可被覆盖
    constraint c_soft_default {
      soft length == 64;      // 默认值为64
      soft addr == 32'h1000;  // 默认地址
    }
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    InsideDemo       inside_pkt;
    DistDemo         dist_pkt;
    ConditionalDemo  cond_pkt;
    ForeachDemo      foreach_pkt;
    RelationDemo     relation_pkt;
    SoftDemo         soft_pkt;
    
    // 创建对象
    inside_pkt   = new();
    dist_pkt     = new();
    cond_pkt     = new();
    foreach_pkt  = new();
    relation_pkt = new();
    soft_pkt     = new();
    
    $display("\n================================================");
    $display("        第6章 6.3 约束（Constraints）示例演示");
    $display("================================================\n");
    
    //=====================================================================
    // 场景1：inside集合约束
    //=====================================================================
    $display("【场景1】inside集合约束");
    $display("  addr限定在{[8:15],[20:30],100}范围内");
    $display("  cmd限定在{0,2,4,8}中\n");
    
    for (int i = 0; i < 8; i++) begin
      if (inside_pkt.randomize()) begin
        $display("  %0d: addr=%3d, cmd=%d, data=0x%08h",
                 i, inside_pkt.addr, inside_pkt.cmd, inside_pkt.data);
      end
    end
    
    $display("  验证：所有addr都在指定范围内，cmd只有0/2/4/8\n");
    
    //=====================================================================
    // 场景2：dist权重约束
    //=====================================================================
    $display("【场景2】dist权重约束");
    $display("  pkt_len: 小包[64:127]:=40, 中包[128:255]:=40, 大包[256:511]:=20");
    $display("  priority: 高[0:2]:/30, 低[3:9]:/70\n");
    
    // 统计各范围出现次数
    int small_cnt = 0, mid_cnt = 0, large_cnt = 0;
    int high_cnt = 0, low_cnt = 0;
    
    for (int i = 0; i < 100; i++) begin
      if (dist_pkt.randomize()) begin
        if (dist_pkt.pkt_len <= 127) small_cnt++;
        else if (dist_pkt.pkt_len <= 255) mid_cnt++;
        else large_cnt++;
        
        if (dist_pkt.priority <= 2) high_cnt++;
        else low_cnt++;
      end
    end
    
    $display("  pkt_len分布(100次): 小包=%0d%%, 中包=%0d%%, 大包=%0d%%",
             small_cnt, mid_cnt, large_cnt);
    $display("  priority分布(100次): 高优先级=%0d%%, 低优先级=%0d%%",
             high_cnt, low_cnt);
    $display("  说明：分布接近权重比 2:2:1 和 3:7\n");
    
    //=====================================================================
    // 场景3：条件约束（if-else 和 ->）
    //=====================================================================
    $display("【场景3】条件约束（if-else 和 ->）");
    $display("  写操作：地址4字节对齐，突发长度1-16");
    $display("  读操作：地址0x000-0x3FF，突发长度固定为1\n");
    
    // 生成5个写操作
    $display("  --- 写操作示例 ---");
    for (int i = 0; i < 5; i++) begin
      if (cond_pkt.randomize() with { rw == 1; }) begin
        $display("  WRITE: addr=0x%08h, wdata=0x%08h, burst=%0d",
                 cond_pkt.addr, cond_pkt.wdata, cond_pkt.burst_len);
      end
    end
    
    // 生成5个读操作
    $display("  --- 读操作示例 ---");
    for (int i = 0; i < 5; i++) begin
      if (cond_pkt.randomize() with { rw == 0; }) begin
        $display("  READ:  addr=0x%08h, wdata=0x%08h, burst=%0d",
                 cond_pkt.addr, cond_pkt.wdata, cond_pkt.burst_len);
      end
    end
    $display("  验证：写地址4字节对齐，读地址<=0x3FF，读burst固定1\n");
    
    //=====================================================================
    // 场景4：foreach迭代约束
    //=====================================================================
    $display("【场景4】foreach迭代约束");
    $display("  数组大小3-8，元素范围10-99，递增序列\n");
    
    for (int i = 0; i < 5; i++) begin
      if (foreach_pkt.randomize()) begin
        $write("  数组[%0d]: ", foreach_pkt.payload.size());
        for (int j = 0; j < foreach_pkt.payload.size(); j++) begin
          $write("%0d ", foreach_pkt.payload[j]);
        end
        $display("(递增序列)");
      end
    end
    $display("  验证：每个元素10-99，后一个严格大于前一个\n");
    
    //=====================================================================
    // 场景5：关系约束 + solve...before
    //=====================================================================
    $display("【场景5】关系约束 total = part_a + part_b");
    $display("  solve part_a before part_b\n");
    
    for (int i = 0; i < 5; i++) begin
      if (relation_pkt.randomize()) begin
        $display("  %0d: part_a=%3d + part_b=%3d = total=%3d  (验证: %s)",
                 i, relation_pkt.part_a, relation_pkt.part_b, relation_pkt.total,
                 (relation_pkt.part_a + relation_pkt.part_b == relation_pkt.total) ? "PASS" : "FAIL");
      end
    end
    $display("  验证：total始终等于part_a+part_b\n");
    
    //=====================================================================
    // 场景6：软约束
    //=====================================================================
    $display("【场景6】软约束（soft）");
    $display("  默认: length==64, addr==0x1000 (软约束，可被覆盖)\n");
    
    $display("  --- 默认随机化 ---");
    for (int i = 0; i < 3; i++) begin
      if (soft_pkt.randomize()) begin
        $display("  %0d: length=%0d, addr=0x%08h", i, soft_pkt.length, soft_pkt.addr);
      end
    end
    
    $display("  --- 用with覆盖软约束 ---");
    for (int i = 0; i < 3; i++) begin
      if (soft_pkt.randomize() with { length == 128; }) begin
        $display("  %0d: length=%0d, addr=0x%08h (length被强制为128)",
                 i, soft_pkt.length, soft_pkt.addr);
      end
    end
    $display("  说明：软约束被with子句覆盖，不产生冲突\n");
    
    #10 $finish;
  end

endmodule
