//=====================================================================
// 章节：第6章 随机化
// 知识点：6.8 随机化的高级话题
// 文件名：08_randomization_advanced_example.sv
// 描述：演示随机化稳定性、多对象联合随机化（std::randomize）、
//       调试技巧（约束冲突定位）、覆盖率驱动随机化
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module randomization_advanced_demo;

  //=====================================================================
  // 类1：稳定性演示 —— 同一种子复现
  //=====================================================================
  class StabilityDemo;
    rand bit [7:0] val;
    rand bit [15:0] code;

    constraint c_val {
      val inside {[0:99]};
    }

    constraint c_code {
      code inside {[1000:9999]};
    }
  endclass

  //=====================================================================
  // 类2：多对象随机化
  //=====================================================================
  class MasterTxn;
    rand bit [7:0] src_addr;
    rand bit [7:0] payload;

    constraint c_src {
      src_addr inside {[0:15]};
    }

    constraint c_payload {
      payload inside {[1:200]};
    }
  endclass

  class SlaveTxn;
    rand bit [7:0] dst_addr;
    rand bit [7:0] response;

    constraint c_dst {
      dst_addr inside {[0:15]};
    }

    constraint c_resp {
      response inside {[0:3]};
    }
  endclass

  //=====================================================================
  // 类3：约束冲突调试演示
  //=====================================================================
  class DebugPacket;
    rand bit [7:0] addr;
    rand bit [7:0] data;
    rand bit [3:0] len;

    constraint c_addr {
      addr inside {[0:31]};
    }

    constraint c_data {
      data inside {[0:255]};
    }

    constraint c_len {
      len inside {[1:8]};
    }

    // 可能冲突的约束：data 必须 >= addr * 10
    constraint c_relation {
      data >= addr * 10;
    }

    // 潜在冲突：当 addr 较大时 data 范围受限
    constraint c_data_nz {
      data != 0;
    }
  endclass

  //=====================================================================
  // 类4：覆盖率驱动随机化
  //=====================================================================
  class CoverageDrivenTxn;
    rand bit [7:0] addr;
    rand bit [1:0] op;
    rand bit [7:0] data;

    constraint c_addr {
      addr inside {[0:255]};
    }

    constraint c_op {
      op inside {[0:3]};
    }

    constraint c_data {
      data inside {[1:254]};
    }

    // 手动覆盖率统计
    static int addr_low_cnt, addr_mid_cnt, addr_high_cnt;
    static int op_cnt [4];
    static int total_cnt;

    function void post_randomize();
      total_cnt++;
      if (addr < 64)        addr_low_cnt++;
      else if (addr < 192)  addr_mid_cnt++;
      else                  addr_high_cnt++;
      op_cnt[op]++;
    endfunction

    // 打印覆盖率报告
    function void print_coverage();
      $display("    总事务数: %0d", total_cnt);
      $display("    地址区间覆盖: low=%0d(%0.1f%%), mid=%0d(%0.1f%%), high=%0d(%0.1f%%)",
               addr_low_cnt,  real'(addr_low_cnt)/total_cnt*100,
               addr_mid_cnt,  real'(addr_mid_cnt)/total_cnt*100,
               addr_high_cnt, real'(addr_high_cnt)/total_cnt*100);
      $display("    操作码覆盖: op0=%0d, op1=%0d, op2=%0d, op3=%0d",
               op_cnt[0], op_cnt[1], op_cnt[2], op_cnt[3]);
    endfunction
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    StabilityDemo        stab_pkt1, stab_pkt2;
    MasterTxn            m_txn;
    SlaveTxn             s_txn;
    DebugPacket          debug_pkt;
    CoverageDrivenTxn    cov_pkt;

    stab_pkt1 = new();
    stab_pkt2 = new();
    m_txn     = new();
    s_txn     = new();
    debug_pkt = new();
    cov_pkt   = new();

    $display("\n================================================");
    $display("        第6章 6.8 随机化的高级话题 示例演示");
    $display("================================================\n");

    //=====================================================================
    // 场景1：稳定性 —— 同一种子复现
    //=====================================================================
    $display("【场景1】随机化稳定性（同一种子 → 相同序列）\n");

    $display("  --- 第一次运行（seed=42）---");
    process::self().srandom(42);
    for (int i = 0; i < 4; i++) begin
      void'(stab_pkt1.randomize());
      $display("  %0d: val=%3d, code=%5d", i, stab_pkt1.val, stab_pkt1.code);
    end

    $display("  --- 第二次运行（seed=42）---");
    process::self().srandom(42);
    for (int i = 0; i < 4; i++) begin
      void'(stab_pkt2.randomize());
      $display("  %0d: val=%3d, code=%5d", i, stab_pkt2.val, stab_pkt2.code);
    end
    $display("  验证：两次序列完全一致 → 可复现\n");

    $display("  --- 第三次运行（seed=99，不同种子）---");
    process::self().srandom(99);
    for (int i = 0; i < 4; i++) begin
      void'(stab_pkt1.randomize());
      $display("  %0d: val=%3d, code=%5d", i, stab_pkt1.val, stab_pkt1.code);
    end
    $display("  说明：不同种子 → 不同序列\n");

    //=====================================================================
    // 场景2：多对象联合随机化
    //=====================================================================
    $display("【场景2】多对象联合随机化\n");

    $display("  --- 各自独立随机化（无关联）---");
    for (int i = 0; i < 3; i++) begin
      m_txn.randomize();
      s_txn.randomize();
      $display("  m_src=%2d, s_dst=%2d (可能不同)",
               m_txn.src_addr, s_txn.dst_addr);
    end

    $display("  --- std::randomize 联合约束（src == dst）---");
    for (int i = 0; i < 3; i++) begin
      std::randomize(m_txn.src_addr, s_txn.dst_addr) with {
        m_txn.src_addr == s_txn.dst_addr;
        m_txn.src_addr inside {[0:15]};
      };
      $display("  m_src=%2d, s_dst=%2d (始终相同)",
               m_txn.src_addr, s_txn.dst_addr);
    end
    $display("  说明：std::randomize 可以跨越对象边界建立约束关系\n");

    $display("  --- std::randomize 随机化局部变量 ---");
    for (int i = 0; i < 3; i++) begin
      bit [7:0] local_a, local_b;
      std::randomize(local_a, local_b) with {
        local_a + local_b < 50;
        local_a inside {[0:30]};
        local_b inside {[0:30]};
      };
      $display("  local_a=%2d, local_b=%2d, sum=%2d (<50)",
               local_a, local_b, local_a + local_b);
    end
    $display("  说明：std::randomize 可以随机化非类成员变量\n");

    //=====================================================================
    // 场景3：调试 —— 约束冲突定位
    //=====================================================================
    $display("【场景3】调试技巧 —— 约束冲突定位\n");

    $display("  --- 正常随机化 ---");
    for (int i = 0; i < 3; i++) begin
      if (debug_pkt.randomize()) begin
        $display("  addr=%2d, data=%3d, len=%2d (data >= addr*10: %s)",
                 debug_pkt.addr, debug_pkt.data, debug_pkt.len,
                 (debug_pkt.data >= debug_pkt.addr * 10) ? "YES" : "NO");
      end
    end

    $display("  --- 制造冲突：addr=30，要求 data>=300，但 data∈[0:255] ---");
    for (int i = 0; i < 3; i++) begin
      if (debug_pkt.randomize() with { addr == 30; }) begin
        $display("  addr=%2d, data=%3d (成功)", debug_pkt.addr, debug_pkt.data);
      end else begin
        $display("  addr=30, 随机化失败！（data>=300 超出 [0:255] 范围）");
      end
    end

    $display("  --- 调试方法：逐个禁用约束定位冲突 ---");
    debug_pkt.constraint_mode(0);
    $display("  禁用所有约束: %s", debug_pkt.randomize() ? "成功" : "失败");

    debug_pkt.c_relation.constraint_mode(1);
    $display("  启用 c_relation: %s", debug_pkt.randomize() ? "成功" : "失败");

    debug_pkt.c_addr.constraint_mode(1);
    $display("  启用 c_addr: %s", debug_pkt.randomize() ? "成功" : "失败");

    debug_pkt.c_relation.constraint_mode(1);
    debug_pkt.c_data.constraint_mode(1);
    debug_pkt.c_data_nz.constraint_mode(1);
    debug_pkt.c_len.constraint_mode(1);
    debug_pkt.c_addr.constraint_mode(1);
    $display("  启用所有约束: %s", debug_pkt.randomize() ? "成功" : "失败");

    $display("  --- 定向测试：固定 addr=5 确认功能 ---");
    for (int i = 0; i < 3; i++) begin
      if (debug_pkt.randomize() with { addr == 5; data == 50; len == 4; }) begin
        $display("  addr=%2d, data=%3d, len=%2d (定向测试)",
                 debug_pkt.addr, debug_pkt.data, debug_pkt.len);
      end
    end
    $display("  说明：通过 inline 约束将随机测试转为定向测试\n");

    debug_pkt.constraint_mode(1);  // 恢复所有约束

    //=====================================================================
    // 场景4：覆盖率驱动随机化
    //=====================================================================
    $display("【场景4】覆盖率驱动随机化\n");

    $display("  --- 阶段1：纯随机 50 次事务 ---");
    for (int i = 0; i < 50; i++) begin
      cov_pkt.randomize();
    end
    $display("  阶段1覆盖率:");
    cov_pkt.print_coverage();

    $display("\n  --- 阶段2：引导高地址区（发现 high 覆盖不足）---");
    for (int i = 0; i < 50; i++) begin
      cov_pkt.randomize() with { addr inside {[192:255]}; };
    end
    $display("  阶段2覆盖率（含引导）:");
    cov_pkt.print_coverage();

    $display("\n  说明：阶段1纯随机，高地址区覆盖可能不足；阶段2通过 inline 约束引导，");
    $display("        补充覆盖高地址区域。这就是覆盖率驱动的验证思路。\n");

    #10 $finish;
  end

endmodule
