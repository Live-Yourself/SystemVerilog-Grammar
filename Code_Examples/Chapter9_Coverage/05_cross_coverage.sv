//==============================================================================
// 文件名: 05_cross_coverage.sv
// 知识点: KP05 交叉覆盖 cross
// 章节: 第9章 - 覆盖率
// 说明: 演示 cross 交叉覆盖的语法、自动分箱、自定义交叉 bin
//==============================================================================

// =============================================================================
// 知识点讲解:
// 单个 coverpoint 只能跟踪一个变量,但验证中经常需要关注多个变量的组合。
// cross 用于捕获多个 coverpoint 之间的值组合是否都被覆盖到。
//
// 语法:
//   cross cp1, cp2;   // cp1 和 cp2 的所有 bin 做笛卡尔积
//
// 自动交叉分箱:
//   如果 cp1 有 N 个 bin,cp2 有 M 个 bin,
//   则 cross 自动生成 N*M 个交叉 bin,每个对应一种组合。
//
// 自定义交叉 bin:
//   binsof(cp1) 和 binsof(cp2) 用于指定组合条件
// =============================================================================

typedef enum bit [1:0] {
  OP_READ  = 2'b00,
  OP_WRITE = 2'b01,
  OP_BURST = 2'b10
} op_e;

typedef enum bit [1:0] {
  SZ_BYTE  = 2'b00,
  SZ_HALF  = 2'b01,
  SZ_WORD  = 2'b10,
  SZ_DWORD = 2'b11
} size_e;

class Transaction;
  rand op_e   op;
  rand size_e size;

  covergroup OpSizeCov;
    //--- 覆盖点1: 操作类型 ---
    coverpoint op {
      bins b_read  = {OP_READ};
      bins b_write = {OP_WRITE};
      bins b_burst = {OP_BURST};
      // OP 为 2-bit,值 3 未定义,忽略
      ignore_bins ig_undef = {2'b11};
    }

    //--- 覆盖点2: 传输大小 ---
    coverpoint size {
      bins b_byte  = {SZ_BYTE};
      bins b_half  = {SZ_HALF};
      bins b_word  = {SZ_WORD};
      bins b_dword = {SZ_DWORD};
    }

    //--- 交叉覆盖: op x size 的所有组合 ---
    // op 有 3 个有效 bin, size 有 4 个 bin
    // 自动生成 3*4 = 12 个交叉 bin
    cross op, size;
  endgroup

  //--- 覆盖组2: 演示自定义交叉 bin ---
  covergroup CrossCustomCov;
    coverpoint op {
      bins b_read  = {OP_READ};
      bins b_write = {OP_WRITE};
      bins b_burst = {OP_BURST};
      ignore_bins ig_undef = {2'b11};
    }

    coverpoint size {
      bins b_byte  = {SZ_BYTE};
      bins b_half  = {SZ_HALF};
      bins b_word  = {SZ_WORD};
      bins b_dword = {SZ_DWORD};
    }

    // 自定义交叉 bin: 只关注特定组合
    cross op, size {
      // 读操作 + 单字大小 (最常见组合)
      bins read_word  = binsof(op.b_read)  && binsof(size.b_word);

      // 写操作 + 任意大小
      bins write_any  = binsof(op.b_write) && binsof(size);

      // 突发操作 + 双字大小
      bins burst_dword = binsof(op.b_burst) && binsof(size.b_dword);
    }
  endgroup

  function new();
    OpSizeCov      = new();
    CrossCustomCov = new();
  endfunction

  function void display();
    $display("  op=%0s, size=%0s", op.name(), size.name());
  endfunction
endclass

//==============================================================================
// 测试模块
//==============================================================================
module cross_coverage_test;

  Transaction txn;

  initial begin
    txn = new();

    $display("========================================");
    $display("KP05: 交叉覆盖 cross");
    $display("========================================\n");

    //------------------------------------------------------------------
    // 1. 自动交叉分箱: op(3 bin) x size(4 bin) = 12 种组合
    //------------------------------------------------------------------
    $display("--- 1. 自动交叉分箱 (op x size = 3 x 4 = 12 组合) ---");
    repeat (20) begin
      if (!txn.randomize())
        $fatal("随机化失败");
      txn.OpSizeCov.sample();
      txn.display();
    end
    $display("  说明: op 有 3 个 bin,size 有 4 个 bin");
    $display("        cross 自动生成 12 个交叉 bin (笛卡尔积):");
    $display("        read*byte, read*half, read*word, read*dword,");
    $display("        write*byte, ..., burst*dword");
    $display("        查看覆盖率报告可看到哪些组合未被命中\n");

    //------------------------------------------------------------------
    // 2. 自定义交叉 bin: 指定关注的组合
    //------------------------------------------------------------------
    $display("--- 2. 自定义交叉 bin ---");
    repeat (20) begin
      if (!txn.randomize())
        $fatal("随机化失败");
      txn.CrossCustomCov.sample();
      txn.display();
    end
    $display("  说明:");
    $display("    read_word  = binsof(op.b_read)  && binsof(size.b_word)");
    $display("    write_any  = binsof(op.b_write) && binsof(size)");
    $display("    burst_dword = binsof(op.b_burst) && binsof(size.b_dword)");
    $display("  binsof(cp) 匹配该 coverpoint 的任意 bin\n");

    $display("========================================");
    $display("关键要点:");
    $display("  1. cross cp1, cp2; 生成笛卡尔积交叉 bin");
    $display("  2. 交叉 bin 数量 = cp1_bin数 * cp2_bin数");
    $display("  3. binsof(cp.xxx) 指定匹配某个 coverpoint 的特定 bin");
    $display("  4. binsof(cp) 不指定 bin 名则匹配该 cp 的所有 bin");
    $display("  5. 用 && 连接多个 binsof 条件定义组合");
    $display("========================================\n");
  end

endmodule

//==============================================================================
// 编译运行说明:
//   vlog 05_cross_coverage.sv
//   vsim -novopt cross_coverage_test -do "run -all; coverage report -detail"
//==============================================================================
