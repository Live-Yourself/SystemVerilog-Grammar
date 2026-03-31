//==============================================================================
// 文件名: 06_coverage_options.sv
// 知识点: KP06 覆盖率选项
// 章节: 第9章 - 覆盖率
// 说明: 演示 covergroup 常用选项: at_least, auto_bin_max, goal, per_instance 等
//==============================================================================

// =============================================================================
// 知识点讲解:
// 覆盖率选项用于精细控制覆盖率的收集行为:
//
//   option.at_least = N;      -- 每个 bin 至少命中 N 次才算覆盖
//   option.auto_bin_max = N;  -- 自动分箱的最大数量
//   option.goal = N;          -- 覆盖率目标百分比
//   option.per_instance = 1;  -- 按实例统计(而非按类型合并)
//   option.comment = "text";  -- 注释说明
//
// type_option 和 instance_option:
//   - option / type_option:   类型级,所有实例共享
//   - instance_option:        实例级,各实例独立设置
// =============================================================================

class ConfigPacket;
  rand bit [3:0] cmd;
  rand bit [7:0] addr;

  //--- 覆盖组1: at_least 演示 ---
  // at_least 指定每个 bin 至少命中多少次才算覆盖
  covergroup AtLeastCov;
    coverpoint cmd {
      bins b0 = {0};
      bins b1 = {1};
      bins b2 = {2};
      bins b3 = {3};
      option.at_least = 2;       // 每个 bin 至少命中 2 次
    }
  endgroup

  //--- 覆盖组2: goal 演示 ---
  // goal 指定覆盖率目标,默认 100
  covergroup GoalCov;
    coverpoint addr {
      bins b_low  = {[0:63]};
      bins b_mid  = {[64:127]};
      bins b_high = {[128:255]};
    }
    option.goal = 80;           // 目标覆盖率 80%
  endgroup

  //--- 覆盖组3: per_instance 演示 ---
  // 默认: 同一 covergroup 类型的所有实例覆盖率合并统计
  // per_instance=1: 各实例独立统计,不合并
  covergroup InstanceCov;
    coverpoint cmd {
      bins b_cmd[4] = {[0:3]};   // 自动生成 4 个 bin
    }
    option.per_instance = 1;    // 按实例独立统计
  endgroup

  //--- 覆盖组4: comment 演示 ---
  covergroup CommentCov;
    coverpoint addr {
      bins b_range[4] = {[0:255]};
    }
    option.comment = "Address coverage for ConfigPacket";
  endgroup

  function new();
    AtLeastCov  = new();
    GoalCov     = new();
    InstanceCov = new();
    CommentCov  = new();
  endfunction
endclass

//==============================================================================
// 测试模块
//==============================================================================
module coverage_options_test;

  ConfigPacket pkt1;
  ConfigPacket pkt2;

  initial begin
    pkt1 = new();
    pkt2 = new();

    $display("========================================");
    $display("KP06: 覆盖率选项");
    $display("========================================\n");

    //------------------------------------------------------------------
    // 1. at_least: 每个 bin 至少命中 N 次
    //------------------------------------------------------------------
    $display("--- 1. option.at_least = 2 ---");
    // 只让 bin[0] 命中 2 次, bin[1] 命中 1 次
    repeat (1) begin
      pkt1.cmd = 0;  pkt1.AtLeastCov.sample();  // b0 第1次
    end
    repeat (2) begin
      pkt1.cmd = 1;  pkt1.AtLeastCov.sample();  // b1 第1,2次
    end
    repeat (1) begin
      pkt1.cmd = 0;  pkt1.AtLeastCov.sample();  // b0 第2次
    end
    $display("  b0 命中 2 次, b1 命中 2 次 -> 都算覆盖");
    $display("  如果只命中 1 次,则不算覆盖(因为 at_least=2)\n");

    //------------------------------------------------------------------
    // 2. goal: 覆盖率目标
    //------------------------------------------------------------------
    $display("--- 2. option.goal = 80 ---");
    repeat (5) begin
      if (!pkt1.randomize())
        $fatal("随机化失败");
      pkt1.GoalCov.sample();
    end
    $display("  说明: goal 设置覆盖率目标为 80%");
    $display("        覆盖率报告会显示是否达到 goal\n");

    //------------------------------------------------------------------
    // 3. per_instance: 实例级统计
    //------------------------------------------------------------------
    $display("--- 3. option.per_instance = 1 ---");
    // pkt1 的 cmd 只采样 0 和 1
    repeat (5) begin
      pkt1.cmd = $urandom_range(0, 1);
      pkt1.InstanceCov.sample();
    end
    // pkt2 的 cmd 只采样 2 和 3
    repeat (5) begin
      pkt2.cmd = $urandom_range(2, 3);
      pkt2.InstanceCov.sample();
    end
    $display("  pkt1: cmd 只命中 0,1 -> 覆盖率 50%");
    $display("  pkt2: cmd 只命中 2,3 -> 覆盖率 50%");
    $display("  per_instance=1 使它们独立统计,不合并\n");

    //------------------------------------------------------------------
    // 4. comment: 注释
    //------------------------------------------------------------------
    $display("--- 4. option.comment ---");
    repeat (3) begin
      if (!pkt1.randomize())
        $fatal("随机化失败");
      pkt1.CommentCov.sample();
    end
    $display("  说明: comment 在覆盖率报告中显示,帮助理解覆盖组用途\n");

    $display("========================================");
    $display("关键要点:");
    $display("  1. at_least=N: 每个 bin 至少命中 N 次才算覆盖");
    $display("  2. auto_bin_max=N: 自动分箱最大数量");
    $display("  3. goal=N: 覆盖率目标百分比");
    $display("  4. per_instance=1: 按实例独立统计");
    $display("  5. comment: 注释说明,显示在报告中");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
//   vlog 06_coverage_options.sv
//   vsim -novopt coverage_options_test -do "run -all; coverage report -detail"
//==============================================================================
