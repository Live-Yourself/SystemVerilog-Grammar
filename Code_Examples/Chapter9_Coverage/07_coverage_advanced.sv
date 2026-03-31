//==============================================================================
// 文件名: 07_coverage_advanced.sv
// 知识点: KP07 覆盖率高级应用
// 章节: 第9章 - 覆盖率
// 说明: 演示参数化覆盖组、覆盖率权重设置、覆盖组在验证平台中的组织方式
//==============================================================================

// =============================================================================
// 知识点讲解:
// 高级应用涵盖:
//   1. 参数化覆盖组: 通过参数传递变量,使 covergroup 更灵活
//   2. 覆盖率权重: weight 选项控制各覆盖组的重要性
//   3. 覆盖组在类中的组织: 典型验证平台结构
//   4. 覆盖率回调: 在特定时机采样
// =============================================================================

//------------------------------------------------------------------------------
// 1. 参数化覆盖组
// SystemVerilog 支持通过 new() 传递参数来控制覆盖组行为
//------------------------------------------------------------------------------

// 定义一个通用的地址范围覆盖组
class AddressMonitor #(int ADDR_WIDTH=8, int NUM_BINS=4);
  rand bit [ADDR_WIDTH-1:0] addr;

  // 覆盖组参数化: 通过参数控制分箱数量
  covergroup AddrCov;
    coverpoint addr {
      // 自动分成 NUM_BINS 个区间
      bins b_range[NUM_BINS] = {[0:(2**ADDR_WIDTH)-1]};
    }
  endgroup

  function new();
    AddrCov = new();
  endfunction

  function void sample(bit [ADDR_WIDTH-1:0] a);
    addr = a;
    AddrCov.sample();
  endfunction
endclass

//------------------------------------------------------------------------------
// 2. 带权重的覆盖组
//------------------------------------------------------------------------------
class WeightedCoverage;
  rand bit [1:0] mode;
  rand bit [3:0] cfg;

  // 主覆盖组: 权重高
  covergroup ModeCov;
    coverpoint mode {
      bins b_idle  = {0};
      bins b_read  = {1};
      bins b_write = {2};
      bins b_rsrv  = {3};
    }
    option.weight = 10;         // 高权重
    option.comment = "Primary mode coverage";
  endgroup

  // 次要覆盖组: 权重低
  covergroup CfgCov;
    coverpoint cfg {
      bins b_cfg[4] = {[0:15]};
    }
    option.weight = 2;          // 低权重
    option.comment = "Secondary config coverage";
  endgroup

  function new();
    ModeCov = new();
    CfgCov  = new();
  endfunction

  function void sample(bit [1:0] m, bit [3:0] c);
    mode = m;
    cfg  = c;
    ModeCov.sample();
    CfgCov.sample();
  endfunction
endclass

//------------------------------------------------------------------------------
// 3. 验证平台中的覆盖率组织 (Transaction 内嵌覆盖组)
//------------------------------------------------------------------------------
typedef enum bit [2:0] {
  CMD_READ  = 3'b000,
  CMD_WRITE = 3'b001,
  CMD_IDLE  = 3'b010,
  CMD_BURST = 3'b011
} cmd_e;

class BusTransaction;
  rand cmd_e    cmd;
  rand bit [7:0] addr;
  rand bit [7:0] data;
  rand bit       rw;

  // 完整的覆盖率模型封装在事务类中
  covergroup TransactionCov;
    // 命令覆盖
    coverpoint cmd {
      bins b_read  = {CMD_READ};
      bins b_write = {CMD_WRITE};
      bins b_idle  = {CMD_IDLE};
      bins b_burst = {CMD_BURST};
      ignore_bins ig_unused = {3'b100, 3'b101, 3'b110, 3'b111};
    }

    // 地址空间覆盖
    coverpoint addr {
      bins b_low    = {[0:63]};
      bins b_mid    = {[64:127]};
      bins b_high   = {[128:191]};
      bins b_top    = {[192:255]};
    }

    // 读写方向覆盖
    coverpoint rw {
      bins b_read  = {0};
      bins b_write = {1};
    }

    // 交叉覆盖: 命令 x 地址空间
    cross cmd, addr {
      ignore_bins ig_idle = binsof(cmd.b_idle);  // IDLE 命令不关心地址
    }
  endgroup

  function new();
    TransactionCov = new();
  endfunction

  function void sample_cov();
    TransactionCov.sample();
  endfunction

  function void display();
    $display("  cmd=%0s, addr=0x%02h, data=0x%02h, rw=%b",
             cmd.name(), addr, data, rw);
  endfunction
endclass

//------------------------------------------------------------------------------
// 4. 覆盖率回调: 在验证组件中使用
//------------------------------------------------------------------------------
class Monitor;
  BusTransaction txn;
  int            sample_count;

  function new();
    txn = new();
    sample_count = 0;
  endfunction

  // 模拟监测总线并采样覆盖率
  task run(int num_cycles);
    repeat (num_cycles) begin
      if (!txn.randomize())
        $fatal("随机化失败");
      txn.sample_cov();
      txn.display();
      sample_count++;
    end
    $display("\n  Monitor sampled %0d transactions", sample_count);
  endtask
endclass

//==============================================================================
// 测试模块
//==============================================================================
module coverage_advanced_test;

  AddressMonitor #(8, 8) addr_mon_8bit;   // 8 位地址, 8 个 bin
  AddressMonitor #(16, 16) addr_mon_16bit; // 16 位地址, 16 个 bin

  WeightedCoverage  weighted_cov;
  BusTransaction    txn;
  Monitor           mon;

  initial begin
    $display("========================================");
    $display("KP07: 覆盖率高级应用");
    $display("========================================\n");

    //------------------------------------------------------------------
    // 1. 参数化覆盖组
    //------------------------------------------------------------------
    $display("--- 1. 参数化覆盖组 ---");
    addr_mon_8bit  = new();
    addr_mon_16bit = new();

    repeat (5) begin
      bit [7:0]  a8  = $urandom_range(0, 255);
      bit [15:0] a16 = $urandom_range(0, 65535);
      addr_mon_8bit.sample(a8);
      addr_mon_16bit.sample(a16);
      $display("  8bit addr=%0d, 16bit addr=%0d", a8, a16);
    end
    $display("  说明: 通过参数 ADDR_WIDTH 和 NUM_BINS 控制覆盖组行为\n");

    //------------------------------------------------------------------
    // 2. 带权重的覆盖组
    //------------------------------------------------------------------
    $display("--- 2. 覆盖率权重 (weight) ---");
    weighted_cov = new();

    repeat (10) begin
      bit [1:0] m = $urandom_range(0, 3);
      bit [3:0] c = $urandom_range(0, 15);
      weighted_cov.sample(m, c);
    end
    $display("  ModeCov.weight = 10 (高权重,重要)");
    $display("  CfgCov.weight  = 2  (低权重,次要)");
    $display("  权重用于计算总体覆盖率时的加权平均\n");

    //------------------------------------------------------------------
    // 3. 完整的覆盖率组织 (在 Monitor 中使用)
    //------------------------------------------------------------------
    $display("--- 3. 验证平台中的覆盖率组织 ---");
    mon = new();
    mon.run(15);

    $display("\n========================================");
    $display("关键要点:");
    $display("  1. 参数化覆盖组提高复用性");
    $display("  2. weight 控制各覆盖组在总体覆盖率中的权重");
    $display("  3. 覆盖率封装在 Transaction 类中,随对象创建");
    $display("  4. 在 Monitor/Driver 组件中调用 sample_cov()");
    $display("  5. 合理组织覆盖组,便于维护和报告分析");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
//   vlog 07_coverage_advanced.sv
//   vsim -novopt coverage_advanced_test -do "run -all; coverage report -detail"
//==============================================================================
