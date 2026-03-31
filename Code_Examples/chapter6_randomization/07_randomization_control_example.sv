//=====================================================================
// 章节：第6章 随机化
// 知识点：6.7 随机化的控制
// 文件名：07_randomization_control_example.sv
// 描述：演示 constraint_mode 深入用法、rand_mode 注意事项、
//       randomize 指定变量、局部变量随机化、动态约束构建
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module randomization_control_demo;

  //=====================================================================
  // 类1：constraint_mode 深入 —— 分层测试模式
  //=====================================================================
  class LayeredTestPacket;
    rand bit [7:0] addr;
    rand bit [7:0] data;
    rand bit [3:0] cmd;

    // 基础约束：正常运行范围
    constraint c_addr_normal {
      addr inside {[0:31]};
    }

    constraint c_data_valid {
      data inside {[1:254]};
    }

    constraint c_cmd_valid {
      cmd inside {0, 1, 2};
    }

    // 边界约束：用于边界测试
    constraint c_addr_boundary {
      soft addr inside {[28:31]};  // 边界地址
    }

    // 错误约束：用于错误注入
    constraint c_err_data {
      soft data == 0;  // 非法数据
    }
  endclass

  //=====================================================================
  // 类2：rand_mode 注意事项 —— 禁用后仍受约束检查
  //=====================================================================
  class RandModeCaution;
    rand bit [7:0] val;
    rand bit [3:0] code;

    constraint c_val {
      val inside {[10:50]};
    }

    constraint c_code {
      code inside {[0:9]};
    }

    constraint c_relation {
      val == code * 5;  // val 必须等于 code 的 5 倍
    }
  endclass

  //=====================================================================
  // 类3：randomize 指定变量 + 局部变量随机化
  //=====================================================================
  class SelectiveRandom;
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit [7:0] c;

    constraint c_a { a inside {[0:31]}; }
    constraint c_b { b inside {[0:63]}; }
    constraint c_c { c inside {[0:127]}; }
  endclass

  //=====================================================================
  // 类4：动态约束 —— 外部变量参与 inline 约束
  //=====================================================================
  class DynamicConstraintPacket;
    rand bit [15:0] addr;
    rand bit [7:0]  data;
    rand bit        parity;

    constraint c_data {
      data inside {[1:254]};
    }

    constraint c_parity {
      parity == ^data;  // 奇偶校验
    }
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    LayeredTestPacket     layered_pkt;
    RandModeCaution       caution_pkt;
    SelectiveRandom       sel_pkt;
    DynamicConstraintPacket dyn_pkt;
    bit [7:0] local_var1, local_var2;  // 局部变量

    layered_pkt = new();
    caution_pkt = new();
    sel_pkt     = new();
    dyn_pkt     = new();

    $display("\n================================================");
    $display("        第6章 6.7 随机化的控制 示例演示");
    $display("================================================\n");

    //=====================================================================
    // 场景1：constraint_mode 分层测试
    //=====================================================================
    $display("【场景1】constraint_mode 分层测试模式\n");

    $display("  --- 正常模式：所有基础约束启用 ---");
    for (int i = 0; i < 3; i++) begin
      layered_pkt.c_addr_boundary.constraint_mode(0);
      layered_pkt.c_err_data.constraint_mode(0);
      if (layered_pkt.randomize()) begin
        $display("  addr=%2d, data=%3d, cmd=%d",
                 layered_pkt.addr, layered_pkt.data, layered_pkt.cmd);
      end
    end

    $display("  --- 边界模式：启用边界约束 ---");
    for (int i = 0; i < 3; i++) begin
      layered_pkt.c_addr_boundary.constraint_mode(1);
      layered_pkt.c_err_data.constraint_mode(0);
      if (layered_pkt.randomize()) begin
        $display("  addr=%2d, data=%3d, cmd=%d",
                 layered_pkt.addr, layered_pkt.data, layered_pkt.cmd);
      end
    end
    $display("  说明：addr 被 soft 约束到 [28:31] 边界区域\n");

    $display("  --- 错误模式：启用错误约束 ---");
    for (int i = 0; i < 3; i++) begin
      layered_pkt.c_addr_boundary.constraint_mode(0);
      layered_pkt.c_err_data.constraint_mode(1);
      if (layered_pkt.randomize()) begin
        $display("  addr=%2d, data=%3d, cmd=%d",
                 layered_pkt.addr, layered_pkt.data, layered_pkt.cmd);
      end
    end
    $display("  说明：data 被 soft 约束为 0（非法值）\n");

    // 恢复默认
    layered_pkt.c_addr_boundary.constraint_mode(0);
    layered_pkt.c_err_data.constraint_mode(0);

    //=====================================================================
    // 场景2：rand_mode 注意事项
    //=====================================================================
    $display("【场景2】rand_mode 注意事项\n");

    $display("  --- 正常随机化（val == code * 5）---");
    for (int i = 0; i < 3; i++) begin
      if (caution_pkt.randomize()) begin
        $display("  val=%2d, code=%2d (val == code*5: %s)",
                 caution_pkt.val, caution_pkt.code,
                 (caution_pkt.val == caution_pkt.code * 5) ? "YES" : "NO");
      end
    end

    $display("  --- 禁用 val 随机化，val=30（满足 val==code*5，code=6）---");
    caution_pkt.val = 30;
    caution_pkt.val.rand_mode(0);
    for (int i = 0; i < 3; i++) begin
      if (caution_pkt.randomize()) begin
        $display("  val=%2d(fixed), code=%2d (val==code*5: %s)",
                 caution_pkt.val, caution_pkt.code,
                 (caution_pkt.val == caution_pkt.code * 5) ? "YES" : "NO");
      end
    end
    $display("  说明：val=30 固定，code 被约束求解为 6\n");

    $display("  --- 禁用 val 随机化，val=33（不满足 val==code*5，code 必须为 6.6 -> 失败）---");
    caution_pkt.val = 33;
    // val=33, val==code*5 => code=6.6，但 code 是整数且 ∈[0:9]，无法满足
    for (int i = 0; i < 3; i++) begin
      if (caution_pkt.randomize()) begin
        $display("  val=%2d, code=%2d (成功)", caution_pkt.val, caution_pkt.code);
      end else begin
        $display("  val=%2d, 随机化失败！（val=33 不满足 val==code*5）", caution_pkt.val);
      end
    end
    $display("  说明：rand_mode(0) 后，val=33 仍受约束 val==code*5 检查，无解导致失败\n");

    caution_pkt.val.rand_mode(1);  // 恢复

    //=====================================================================
    // 场景3：randomize 指定变量
    //=====================================================================
    $display("【场景3】randomize() 指定变量\n");

    sel_pkt.a = 10; sel_pkt.b = 20; sel_pkt.c = 30;
    $display("  --- 只随机化 a（b=20, c=30 不变）---");
    for (int i = 0; i < 3; i++) begin
      sel_pkt.b = 20; sel_pkt.c = 30;  // 每次恢复
      if (sel_pkt.randomize(a)) begin
        $display("  a=%2d, b=%2d(fixed), c=%2d(fixed)",
                 sel_pkt.a, sel_pkt.b, sel_pkt.c);
      end
    end

    $display("  --- 只随机化 a 和 c（b=50 不变）---");
    for (int i = 0; i < 3; i++) begin
      sel_pkt.b = 50;
      if (sel_pkt.randomize(a, c)) begin
        $display("  a=%2d, b=%2d(fixed), c=%2d",
                 sel_pkt.a, sel_pkt.b, sel_pkt.c);
      end
    end
    $display("  说明：randomize(a) 只随机化 a，b/c 保持当前值且不受类内约束影响\n");

    //=====================================================================
    // 场景4：局部变量随机化
    //=====================================================================
    $display("【场景4】局部变量随机化\n");

    $display("  --- 随机化类成员 a, b 和局部变量 local_var1 ---");
    for (int i = 0; i < 3; i++) begin
      if (sel_pkt.randomize(a, b, local_var1)) begin
        $display("  a=%2d, b=%2d, c=%2d(未参与), local_var1=%2d",
                 sel_pkt.a, sel_pkt.b, sel_pkt.c, local_var1);
      end
    end
    $display("  说明：local_var1 不是类成员，但可以通过参数列表传入 randomize\n");

    //=====================================================================
    // 场景5：动态约束 —— 外部变量参与 inline 约束
    //=====================================================================
    $display("【场景5】动态约束（外部变量参与 inline 约束）\n");

    $display("  --- 外部变量 target_addr 参与约束 ---");
    for (int i = 0; i < 4; i++) begin
      bit [15:0] target_addr;
      target_addr = 16'(i * 0x1000);  // 0x0000, 0x1000, 0x2000, 0x3000
      if (dyn_pkt.randomize() with { addr == target_addr; }) begin
        $display("  target=0x%04h -> addr=0x%04h, data=%3d, parity=%0d",
                 target_addr, dyn_pkt.addr, dyn_pkt.data, dyn_pkt.parity);
      end
    end
    $display("  说明：外部变量 target_addr 通过 inline 约束控制 addr 的值\n");

    $display("  --- 使用 solve...before 引导求解方向 ---");
    for (int i = 0; i < 3; i++) begin
      if (dyn_pkt.randomize() with { addr inside {[16'h1000:16'h1FFF]}; }) begin
        $display("  addr=0x%04h, data=%3d, parity=%0d",
                 dyn_pkt.addr, dyn_pkt.data, dyn_pkt.parity);
      end
    end
    $display("  说明：inline 约束可以在运行时灵活调整随机范围\n");

    #10 $finish;
  end

endmodule
