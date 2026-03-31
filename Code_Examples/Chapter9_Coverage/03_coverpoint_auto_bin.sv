//==============================================================================
// 文件名: 03_coverpoint_auto_bin.sv
// 知识点: KP03 coverpoint与自动分箱
// 章节: 第9章 - 覆盖率
// 说明: 演示 coverpoint 的声明方式、自动分箱(auto_bin)生成规则、iff 条件采样
//==============================================================================

// =============================================================================
// 知识点讲解:
// coverpoint 指定要采样的变量。
// 如果不显式定义 bin,仿真器会自动生成 auto_bin。
//
// 自动分箱规则:
//   - 2值变量: 默认生成 64 个 auto_bin,每个 bin 覆盖一个值
//   - 如果变量值域 > 64,则将值域均匀分成 64 个区间
//   - auto_bin_max 选项可以调整自动分箱的最大数量(默认 64)
//
// iff 条件:
//   - coverpoint addr iff (enable);  仅当 enable 为真时才采样 addr
//   - 用于选择性采样,例如仅在有效时钟沿、有效事务时采样
// =============================================================================

// 定义总线事务类
class BusTransaction;
  rand bit [2:0] cmd;        // 3位命令,值域 0~7
  rand bit [7:0] addr;
  rand bit [7:0] data;
  bit           valid;       // 有效标志

  //--- 覆盖组1: 自动分箱 ---
  // cmd 是 3 位变量,值域 0~7,共 8 个值
  // 不定义 bin,仿真器自动生成 auto[0]~auto[7]
  covergroup CmdAutoCov;
    coverpoint cmd;          // 自动分箱: 每个值一个 bin
  endgroup

  //--- 覆盖组2: 使用 iff 条件 ---
  // 仅当 valid==1 时才采样 addr
  covergroup AddrCovCond;
    coverpoint addr iff (valid) {
      // 自动分箱: 8 位变量值域 0~255,默认分成 64 个区间
    }
  endgroup

  //--- 覆盖组3: 带字符串名称的覆盖点 ---
  covergroup NamedCov;
    coverpoint cmd {
      // auto_bin_max = 4: 将 0~7 均匀分成 4 个区间
      option.auto_bin_max = 4;
    }
  endgroup

  function new();
    CmdAutoCov  = new();
    AddrCovCond = new();
    NamedCov    = new();
  endfunction

  function void display();
    $display("  cmd=%0d, addr=0x%02h, data=0x%02h, valid=%b",
             cmd, addr, data, valid);
  endfunction
endclass

//==============================================================================
// 测试模块
//==============================================================================
module coverpoint_auto_bin_test;

  BusTransaction txn;

  initial begin
    txn = new();

    $display("========================================");
    $display("KP03: coverpoint 与自动分箱");
    $display("========================================\n");

    //------------------------------------------------------------------
    // 1. 自动分箱: cmd 有 8 个可能值,自动生成 8 个 bin
    //------------------------------------------------------------------
    $display("--- 1. 自动分箱 (cmd, 3-bit, 值域 0~7) ---");
    repeat (10) begin
      txn.valid = 1;
      if (!txn.randomize())
        $fatal("随机化失败");
      txn.CmdAutoCov.sample();
      txn.display();
    end
    $display("  说明: 不定义 bin 时,仿真器自动为每个值生成一个 auto_bin");
    $display("        8 个可能值 → auto[0]~auto[7],每个 bin 覆盖一个值\n");

    //------------------------------------------------------------------
    // 2. iff 条件采样: 仅 valid==1 时才采样
    //------------------------------------------------------------------
    $display("--- 2. iff 条件采样 ---");
    repeat (6) begin
      if (!txn.randomize())
        $fatal("随机化失败");
      // 随机设置 valid,约一半事务会被跳过
      txn.valid = ($urandom % 2);
      txn.AddrCovCond.sample();   // valid=0 时不采样 addr
      txn.display();
    end
    $display("  说明: iff(valid) 表示仅 valid 为真时才采样");
    $display("        valid=0 的事务不会被计入覆盖率统计\n");

    //------------------------------------------------------------------
    // 3. auto_bin_max 调整自动分箱数量
    //------------------------------------------------------------------
    $display("--- 3. auto_bin_max 控制分箱数量 ---");
    repeat (10) begin
      txn.valid = 1;
      if (!txn.randomize())
        $fatal("随机化失败");
      txn.NamedCov.sample();
      txn.display();
    end
    $display("  说明: option.auto_bin_max = 4");
    $display("        cmd 值域 0~7 被均匀分成 4 个区间:");
    $display("        auto[0]={0,1}, auto[1]={2,3}, auto[2]={4,5}, auto[3]={6,7}\n");

    $display("========================================");
    $display("关键要点:");
    $display("  1. coverpoint 指定采样的变量");
    $display("  2. 不定义 bin 时,仿真器自动生成 auto_bin");
    $display("  3. 2值变量默认最多 64 个 auto_bin");
    $display("  4. iff 条件实现选择性采样");
    $display("  5. auto_bin_max 可调整自动分箱的最大数量");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
//   vlog 03_coverpoint_auto_bin.sv
//   vsim -novopt coverpoint_auto_bin_test -do "run -all; coverage report -detail"
//==============================================================================
