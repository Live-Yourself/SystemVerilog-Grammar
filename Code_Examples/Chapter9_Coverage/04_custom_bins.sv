//==============================================================================
// 文件名: 04_custom_bins.sv
// 知识点: KP04 自定义 bin
// 章节: 第9章 - 覆盖率
// 说明: 演示显式定义 bin 的各种方式,以及 ignore_bins 和 illegal_bins 的用法
//==============================================================================

// =============================================================================
// 知识点讲解:
// 自定义 bin 让验证工程师按需求精确控制值域划分:
//
//   bin b0 = {0};              // 单值 bin
//   bin b1 = {[1:3], [5:7]};   // 值范围 bin (多个范围用逗号分隔)
//   bin b2 = default;          // 默认 bin (捕获所有未命中的值)
//   ignore_bins ig = {[8:15]}; // 忽略这些值 (不计入覆盖率)
//   illegal_bins il = {4};     // 非法值 (采样到时报错)
//
// ignore_bins vs illegal_bins:
//   - ignore_bins:  值可能出现,但我们不关心,直接忽略,不影响覆盖率统计
//   - illegal_bins: 值不应该出现,如果采样到则报告严重错误
// =============================================================================

// 定义命令枚举
typedef enum bit [2:0] {
  CMD_READ    = 3'b000,
  CMD_WRITE   = 3'b001,
  CMD_RESET   = 3'b010,
  CMD_IDLE    = 3'b011,
  CMD_BURST_R = 3'b100,
  CMD_BURST_W = 3'b101
  // 110, 111 为保留值,不应出现
} cmd_e;

class Packet;
  rand cmd_e   cmd;
  rand bit [3:0] len;     // 包长度 0~15

  covergroup CmdLenCov;
    //--- 覆盖点1: 命令分箱 ---
    coverpoint cmd {
      // 单值 bin: 每个有效命令一个 bin
      bins b_read    = {CMD_READ};
      bins b_write   = {CMD_WRITE};
      bins b_reset   = {CMD_RESET};
      bins b_idle    = {CMD_IDLE};
      // 范围 bin: 两个命令共用一个 bin (突发读/写归为一类)
      bins b_burst   = {[CMD_BURST_R : CMD_BURST_W]};

      // 非法值: 110 和 111 不应该出现
      illegal_bins b_reserved = {3'b110, 3'b111};

      // 说明: 这里没有定义 default bin,
      //       因为所有可能的值已被上述 bin 完全覆盖
    }

    //--- 覆盖点2: 长度分箱 ---
    coverpoint len {
      bins b_zero  = {0};         // 空包
      bins b_short = {[1:4]};     // 短包
      bins b_mid   = {[5:10]};    // 中等包
      bins b_long  = {[11:15]};   // 长包
    }
  endgroup

  //--- 覆盖组2: 演示 default bin 和 ignore_bins ---
  covergroup StatusCov;
    coverpoint status {
      // 显式列出关心的状态
      bins b_ok   = {0};
      bins b_err  = {1};
      bins b_busy = {2};

      // default: 捕获所有未被上述 bin 覆盖的值
      // 这里 status 为 3~15 都会落入 default
      default bin b_others;

      // ignore_bins 示例 (注释掉,因为已用 default 覆盖所有值)
      // ignore_bins ig_ignored = {[8:15]};
    }
  endgroup

  // 用于测试 ignore_bins 的覆盖组
  covergroup AddrCov;
    coverpoint addr {
      bins b_low    = {[0:31]};
      bins b_mid    = {[32:63]};
      bins b_high   = {[64:95]};

      // 忽略高地址区域,不计入覆盖率
      ignore_bins ig_reserved = {[96:127]};
    }
  endgroup

  bit [6:0] addr;
  bit [3:0] status;

  function new();
    CmdLenCov = new();
    StatusCov = new();
    AddrCov   = new();
  endfunction

  function void display();
    $display("  cmd=%0s, len=%0d, status=%0d, addr=%0d",
             cmd.name(), len, status, addr);
  endfunction
endclass

//==============================================================================
// 测试模块
//==============================================================================
module custom_bins_test;

  Packet pkt;

  initial begin
    pkt = new();

    $display("========================================");
    $display("KP04: 自定义 bin");
    $display("========================================\n");

    //------------------------------------------------------------------
    // 1. 基本自定义 bin: 单值 bin + 范围 bin
    //------------------------------------------------------------------
    $display("--- 1. 单值 bin + 范围 bin + illegal_bins ---");
    repeat (15) begin
      if (!pkt.randomize())
        $fatal("随机化失败");
      pkt.CmdLenCov.sample();
      pkt.display();
    end
    $display("  说明:");
    $display("    - b_read~b_idle: 各一个有效命令一个 bin");
    $display("    - b_burst: 范围 bin,覆盖 BURST_R 和 BURST_W");
    $display("    - b_reserved(illegal): 如果采样到会报错\n");

    //------------------------------------------------------------------
    // 2. default bin: 捕获未覆盖的值
    //------------------------------------------------------------------
    $display("--- 2. default bin ---");
    repeat (10) begin
      pkt.status = $urandom_range(0, 15);
      pkt.StatusCov.sample();
      $display("  status = %0d", pkt.status);
    end
    $display("  说明: status 3~15 都会落入 default bin 'b_others'");
    $display("        default bin 确保不会遗漏任何未预期的值\n");

    //------------------------------------------------------------------
    // 3. ignore_bins: 忽略不关心的值
    //------------------------------------------------------------------
    $display("--- 3. ignore_bins ---");
    repeat (10) begin
      pkt.addr = $urandom_range(0, 127);
      pkt.AddrCov.sample();
      $display("  addr = %0d", pkt.addr);
    end
    $display("  说明: addr 96~127 被 ignore_bins 忽略");
    $display("        这些值不会出现在覆盖率报告中,也不影响覆盖率计算");
    $display("        即使全部采样到 96~127,覆盖率仍按 b_low/b_mid/b_high 计算\n");

    $display("========================================");
    $display("关键要点:");
    $display("  1. bins b_name = {值/范围};       -- 显式定义分箱");
    $display("  2. bins b_name = {[lo:hi]};       -- 值范围分箱");
    $display("  3. bins b_name = {v1, [l:h]};    -- 多值/范围组合");
    $display("  4. default bin b_name;            -- 捕获未覆盖的值");
    $display("  5. ignore_bins ig = {值};         -- 忽略,不影响覆盖率");
    $display("  6. illegal_bins il = {值};        -- 非法值,采样到报错");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
//   vlog 04_custom_bins.sv
//   vsim -novopt custom_bins_test -do "run -all; coverage report -detail"
//==============================================================================
