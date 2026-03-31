//==============================================================================
// 文件名: 02_covergroup_basic.sv
// 知识点: KP02 covergroup基本定义
// 章节: 第9章 - 覆盖率
// 说明: 演示 covergroup 的完整定义方式、在类中嵌入覆盖组、sample() 采样机制
//==============================================================================

// =============================================================================
// 知识点讲解:
// covergroup 是定义功能覆盖率的基本单元,语法结构为:
//   covergroup <名称>;
//     coverpoint <变量> { ... }   // 覆盖点
//   endgroup
//
// 使用流程:
//   1. 声明 covergroup 类型 (或在类中直接定义)
//   2. 创建 covergroup 实例 (调用 new())
//   3. 调用 sample() 进行采样
//
// 在类中嵌入覆盖组是最常见的用法:
//   - 覆盖组与事务数据绑定在一起
//   - 可以通过 new() 构造函数自动实例化
//   - sample() 可以在类方法中自动调用
// =============================================================================

//------------------------------------------------------------------------------
// 方式一: 在类中嵌入 covergroup (推荐用法)
//------------------------------------------------------------------------------
class BusTransaction;
  rand bit [7:0] addr;
  rand bit [7:0] data;
  rand bit       rw;       // 0=read, 1=write

  // 在类中直接定义 covergroup
  covergroup AddrCov;
    coverpoint addr {
      bins low    = {[0:63]};      // 低地址空间
      bins mid    = {[64:127]};    // 中地址空间
      bins high   = {[128:255]};   // 高地址空间
    }
  endgroup

  // 构造函数中自动创建覆盖组实例
  function new();
    AddrCov = new();      // covergroup 实例化
  endfunction

  // 封装 sample() 调用,使采样更方便
  function void sample_cov();
    AddrCov.sample();      // 采样当前 addr 值
  endfunction

  function void display();
    $display("  addr=0x%02h, data=0x%02h, rw=%s",
             addr, data, rw ? "WR" : "RD");
  endfunction
endclass

//------------------------------------------------------------------------------
// 方式二: 独立定义 covergroup (用于更灵活的场景)
//------------------------------------------------------------------------------
// 独立的覆盖组可以通过参数传入变量,或在采样时指定

covergroup DataCovGroup;
  coverpoint data {
    bins zero     = {0};
    bins small    = {[1:15]};
    bins medium   = {[16:127]};
    bins large    = {[128:255]};
  }
endgroup

//==============================================================================
// 测试模块
//==============================================================================
module covergroup_basic_test;

  BusTransaction  txn;       // 内含 covergroup 的类
  bit [7:0]       data;      // 独立变量,用于独立 covergroup
  DataCovGroup    data_cov;  // 独立 covergroup 实例

  initial begin
    txn       = new();       // 构造时自动创建内部 covergroup
    data_cov  = new();       // 手动创建独立 covergroup

    $display("========================================");
    $display("KP02: covergroup 基本定义");
    $display("========================================\n");

    //------------------------------------------------------------------
    // 1. 在类中使用嵌入的 covergroup
    //------------------------------------------------------------------
    $display("--- 方式一: 类中嵌入 covergroup ---");
    repeat (8) begin
      if (!txn.randomize())
        $fatal("随机化失败");
      txn.sample_cov();      // 通过类方法采样
      txn.display();
    end

    $display("\n  说明: AddrCov 在类内部定义和实例化,");
    $display("        通过 sample_cov() 方法自动采样 addr 值。\n");

    //------------------------------------------------------------------
    // 2. 独立使用 covergroup
    //------------------------------------------------------------------
    $display("--- 方式二: 独立 covergroup ---");
    repeat (8) begin
      data = $urandom_range(0, 255);   // 生成随机数据
      data_cov.sample();               // 手动采样
      $display("  data = 0x%02h", data);
    end

    $display("\n  说明: DataCovGroup 独立定义,手动创建实例,手动采样。\n");

    //------------------------------------------------------------------
    // 3. 演示 covergroup 是一个"类型",可以创建多个实例
    //------------------------------------------------------------------
    $display("--- covergroup 可以创建多个实例 ---");
    DataCovGroup cov_inst1 = new();
    DataCovGroup cov_inst2 = new();

    cov_inst1.sample();     // 各自独立统计
    cov_inst2.sample();
    $display("  cov_inst1 和 cov_inst2 的覆盖率是独立计算的。\n");

    $display("========================================");
    $display("关键要点:");
    $display("  1. covergroup 定义覆盖率模型(模板)");
    $display("  2. 调用 new() 创建 covergroup 实例");
    $display("  3. 调用 sample() 对当前值进行采样");
    $display("  4. 覆盖组通常嵌入在类中,随对象一起创建");
    $display("  5. 一个 covergroup 类型可以创建多个独立实例");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
//   vlog 02_covergroup_basic.sv
//   vsim -novopt covergroup_basic_test -do "run -all; coverage report -detail"
//==============================================================================
