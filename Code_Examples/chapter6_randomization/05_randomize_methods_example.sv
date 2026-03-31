//=====================================================================
// 章节：第6章 随机化
// 知识点：6.5 随机化方法
// 文件名：05_randomize_methods_example.sv
// 描述：演示 randomize()、pre/post_randomize、
//       inline约束、随机化失败处理、种子控制
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module randomize_methods_demo;

  //=====================================================================
  // 类1：pre/post_randomize 回调演示
  //=====================================================================
  class Transaction;
    rand bit [7:0] addr;
    rand bit [7:0] data;
         bit [7:0] checksum;  // 非随机，由 post_randomize 计算
         bit [7:0] parity;    // 非随机，奇偶校验

    constraint c_addr {
      addr inside {[0:31]};
    }

    constraint c_data {
      data inside {[1:254]};  // 排除全0和全1
    }

    // 随机化前回调：打印提示
    function void pre_randomize();
      $display("    [PRE] 准备随机化 addr 和 data...");
    endfunction

    // 随机化后回调：计算校验和和奇偶校验
    function void post_randomize();
      checksum = addr ^ data;
      parity   = ^data;  // 对 data 所有位异或，结果为奇偶校验位
      $display("    [POST] addr=0x%02h, data=0x%02h, checksum=0x%02h, parity=%0d",
               addr, data, checksum, parity);
    endfunction
  endclass

  //=====================================================================
  // 类2：inline 约束演示
  //=====================================================================
  class Packet;
    rand bit [7:0] src_addr;
    rand bit [7:0] dst_addr;
    rand bit [15:0] length;
    rand bit [7:0] payload[];

    constraint c_src {
      src_addr inside {[0:7]};
    }

    constraint c_dst {
      dst_addr inside {[0:15]};
    }

    constraint c_len {
      length inside {[8:64]};
    }

    constraint c_payload_size {
      payload.size() == length;
    }

    constraint c_payload_val {
      foreach (payload[i]) payload[i] inside {[0:255]};
    }
  endclass

  //=====================================================================
  // 类3：随机化失败处理演示
  //=====================================================================
  class StrictPacket;
    rand bit [3:0] value;
    rand bit [3:0] code;

    // 两个约束可能冲突
    constraint c_val {
      value inside {[0:7]};
    }

    constraint c_code {
      code inside {[8:15]};
    }

    // 潜在冲突：有时 value + code 需要等于特定值
    constraint c_sum_soft {
      soft value + code == 10;
    }
  endclass

  //=====================================================================
  // 类4：种子控制演示
  //=====================================================================
  class SeedDemo;
    rand bit [7:0] val1;
    rand bit [7:0] val2;
    rand bit [7:0] val3;

    constraint c_range {
      val1 inside {[0:99]};
      val2 inside {[0:99]};
      val3 inside {[0:99]};
    }
  endclass

  //=====================================================================
  // 类5：randomize 指定变量
  //=====================================================================
  class PartialRandom;
    rand bit [7:0] addr;
    rand bit [7:0] data;
    rand bit [7:0] len;
    rand bit       parity;

    constraint c_addr { addr inside {[0:31]}; }
    constraint c_data { data inside {[0:255]}; }
    constraint c_len  { len inside {[1:64]}; }
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    Transaction    txn;
    Packet         pkt;
    StrictPacket   strict_pkt;
    SeedDemo       seed_pkt1, seed_pkt2;
    PartialRandom  partial_pkt;
    int            fail_count;

    txn       = new();
    pkt       = new();
    strict_pkt = new();
    seed_pkt1 = new();
    seed_pkt2 = new();
    partial_pkt = new();

    $display("\n================================================");
    $display("        第6章 6.5 随机化方法 示例演示");
    $display("================================================\n");

    //=====================================================================
    // 场景1：pre_randomize 和 post_randomize 回调
    //=====================================================================
    $display("【场景1】pre_randomize / post_randomize 回调\n");

    $display("  --- 3次随机化，观察回调执行顺序 ---");
    for (int i = 0; i < 3; i++) begin
      $display("  第%0d次:", i+1);
      void'(txn.randomize());  // 使用 void' 忽略返回值（此处已知不会失败）
    end
    $display("  说明：每次 randomize() 都先执行 pre，求解成功后执行 post\n");

    //=====================================================================
    // 场景2：inline 约束（randomize with）
    //=====================================================================
    $display("【场景2】inline 约束（randomize with { ... }）\n");

    $display("  --- 无 inline 约束（默认随机）---");
    for (int i = 0; i < 3; i++) begin
      if (pkt.randomize()) begin
        $display("  src=%2d, dst=%2d, len=%2d",
                 pkt.src_addr, pkt.dst_addr, pkt.length);
      end
    end

    $display("  --- inline 约束：强制 src=3 ---");
    for (int i = 0; i < 3; i++) begin
      if (pkt.randomize() with { src_addr == 3; }) begin
        $display("  src=%2d(fixed), dst=%2d, len=%2d",
                 pkt.src_addr, pkt.dst_addr, pkt.length);
      end
    end
    $display("  说明：src 固定为 3，dst 和 len 仍在各自约束内随机\n");

    $display("  --- inline 约束：额外限制 len > 50 ---");
    for (int i = 0; i < 3; i++) begin
      if (pkt.randomize() with { length > 50; }) begin
        $display("  src=%2d, dst=%2d, len=%2d",
                 pkt.src_addr, pkt.dst_addr, pkt.length);
      end
    end
    $display("  说明：原约束 len∈[8:64]，inline 限制 len>50，合并为 len∈(50:64]\n");

    //=====================================================================
    // 场景3：随机化失败处理
    //=====================================================================
    $display("【场景3】随机化失败处理\n");

    $display("  --- 故意制造冲突（value=10，但约束 value∈[0:7]）---");
    fail_count = 0;
    for (int i = 0; i < 5; i++) begin
      if (!strict_pkt.randomize() with { value == 10; }) begin
        fail_count++;
      end
    end
    $display("  失败次数: %0d/5（每次都失败，因为 value==10 与 value∈[0:7] 冲突）\n", fail_count);

    $display("  --- 软约束冲突（inline 覆盖软约束，成功）---");
    for (int i = 0; i < 3; i++) begin
      if (strict_pkt.randomize() with { value + code == 20; }) begin
        $display("  value=%2d, code=%2d, sum=%2d",
                 strict_pkt.value, strict_pkt.code,
                 strict_pkt.value + strict_pkt.code);
      end
    end
    $display("  说明：软约束 value+code==10 被 inline 的 value+code==20 覆盖，随机化成功\n");

    //=====================================================================
    // 场景4：种子控制（可复现性）
    //=====================================================================
    $display("【场景4】种子控制（srandom）\n");

    $display("  --- 同一种子，两次随机化序列相同 ---");
    process::self().srandom(42);  // 设置种子为 42
    $display("  种子=42 第一次:");
    for (int i = 0; i < 3; i++) begin
      void'(seed_pkt1.randomize());
      $display("    val1=%3d, val2=%3d, val3=%3d",
               seed_pkt1.val1, seed_pkt1.val2, seed_pkt1.val3);
    end

    process::self().srandom(42);  // 重置相同种子
    $display("  种子=42 第二次:");
    for (int i = 0; i < 3; i++) begin
      void'(seed_pkt2.randomize());
      $display("    val1=%3d, val2=%3d, val3=%3d",
               seed_pkt2.val1, seed_pkt2.val2, seed_pkt2.val3);
    end
    $display("  验证：两次的 val1/val2/val3 序列完全相同\n");

    $display("  --- 不同种子，随机序列不同 ---");
    process::self().srandom(99);  // 不同种子
    $display("  种子=99:");
    for (int i = 0; i < 3; i++) begin
      void'(seed_pkt1.randomize());
      $display("    val1=%3d, val2=%3d, val3=%3d",
               seed_pkt1.val1, seed_pkt1.val2, seed_pkt1.val3);
    end
    $display("  说明：不同种子产生不同序列，但同一种子始终可复现\n");

    //=====================================================================
    // 场景5：randomize 指定变量（只随机化部分变量）
    //=====================================================================
    $display("【场景5】randomize 指定变量\n");

    $display("  --- 只随机化 data 和 len（addr 保持不变）---");
    for (int i = 0; i < 3; i++) begin
      partial_pkt.addr = 10;  // 手动设置
      if (partial_pkt.randomize(addr)) begin  // 只随机化 addr
        $display("  addr=%2d, data=%3d, len=%2d",
                 partial_pkt.addr, partial_pkt.data, partial_pkt.len);
      end
    end
    $display("  说明：randomize(addr) 只随机化 addr，data 和 len 保持原值\n");

    $display("  --- 只随机化 data（addr=20 固定）---");
    for (int i = 0; i < 3; i++) begin
      partial_pkt.addr = 20;
      if (partial_pkt.randomize(data)) begin
        $display("  addr=%2d(fixed), data=%3d, len=%2d",
                 partial_pkt.addr, partial_pkt.data, partial_pkt.len);
      end
    end
    $display("  说明：randomize(data) 只随机化 data，addr=20 和 len 保持不变\n");

    #10 $finish;
  end

endmodule
