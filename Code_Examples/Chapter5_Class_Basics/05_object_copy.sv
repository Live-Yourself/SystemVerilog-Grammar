//==============================================================================
// 文件名: 05_object_copy.sv
// 知识点: 对象的赋值与复制
// 章节: 第5章 - 类基础
// 说明: 演示句柄赋值vs对象复制、浅复制vs深复制、copy()方法实现
//==============================================================================

// =============================================================================
// 辅助类: Header (用于演示浅复制/深复制中的嵌套对象)
// =============================================================================
class Header;
  bit [7:0] src;
  bit [7:0] dst;
  bit [7:0] ptype;

  function new(bit [7:0] s, bit [7:0] d, bit [7:0] p);
    src = s; dst = d; ptype = p;
  endfunction

  function void display();
    $display("      Header: src=0x%02h dst=0x%02h type=0x%02h",
             src, dst, ptype);
  endfunction
endclass

// =============================================================================
// 主类: Transaction (含嵌套Header, 支持浅复制和深复制)
// =============================================================================
class Transaction;
  bit [31:0] addr;
  bit [31:0] data;
  bit        write;
  Header     hdr;  // 嵌套对象

  function new(bit [31:0] a, bit [31:0] d, bit w,
               bit [7:0] s, bit [7:0] dt, bit [7:0] p);
    addr  = a;
    data  = d;
    write = w;
    hdr   = new(s, dt, p);  // 构造时创建嵌套对象
  endfunction

  function void display();
    $display("    Transaction: addr=0x%08h data=0x%08h %s",
             addr, data, write ? "WR" : "RD");
    if (hdr != null) hdr.display();
  endfunction

  // 浅复制: 只复制第一层成员, 嵌套对象仍然是共享的
  function Transaction shallow_copy();
    Transaction t = new(0, 0, 0, 0, 0, 0);
    t.addr  = this.addr;
    t.data  = this.data;
    t.write = this.write;
    t.hdr   = this.hdr;  // 共享同一个Header对象!
    return t;
  endfunction

  // 深复制: 递归复制所有层级, 完全独立
  function Transaction deep_copy();
    Transaction t = new(0, 0, 0, 0, 0, 0);
    t.addr  = this.addr;
    t.data  = this.data;
    t.write = this.write;
    t.hdr   = new();              // 创建新的Header对象
    t.hdr.src   = this.hdr.src;
    t.hdr.dst   = this.hdr.dst;
    t.hdr.ptype = this.hdr.ptype;
    return t;
  endfunction
endclass

// =============================================================================
// 测试程序
// =============================================================================
module object_copy_test;

  Transaction tr1;
  Transaction tr2;

  initial begin
    $display("========================================");
    $display(" 知识点5: 对象的赋值与复制");
    $display("========================================\n");

    // =====================================================================
    // 示例1: 句柄赋值 -- 共享同一个对象
    // =====================================================================
    $display("--- 示例1: 句柄赋值 ---");
    tr1 = new(32'h1000_0000, 32'hDEAD_BEEF, 1, 8'h10, 8'h20, 8'h01);
    $display("tr1创建:");
    tr1.display();

    tr2 = tr1;  // 句柄赋值
    $display("tr2 = tr1;  → 两个句柄指向同一对象");

    $display("通过tr2修改addr:");
    tr2.addr = 32'h2000_0000;
    tr2.display();

    $display("tr1查看 (受影响):");
    tr1.display();
    $display("  → 句柄赋值: tr1和tr2共享同一对象\n");

    // =====================================================================
    // 示例2: 浅复制 -- 非对象成员独立, 嵌套对象共享
    // =====================================================================
    $display("--- 示例2: 浅复制 ---");
    tr1 = new(32'h3000_0000, 32'hCAFEBABE, 0, 8'hAA, 8'hBB, 8'h02);
    tr2 = tr1.shallow_copy();
    $display("tr2 = tr1.shallow_copy();");

    $display("修改tr2的非对象成员 addr:");
    tr2.addr = 32'h4000_0000;
    $display("tr2:"); tr2.display();
    $display("tr1 (不受影响):"); tr1.display();
    $display("  → 非对象成员:值复制,互相独立");

    $display("\n修改tr2的嵌套对象 hdr.src:");
    tr2.hdr.src = 8'hFF;
    $display("tr2.hdr:"); tr2.hdr.display();
    $display("tr1.hdr (受影响!):"); tr1.hdr.display();
    $display("  → 浅复制的限制: 嵌套对象仍然共享!\n");

    // =====================================================================
    // 示例3: 深复制 -- 完全独立
    // =====================================================================
    $display("--- 示例3: 深复制 ---");
    tr1 = new(32'h5000_0000, 32'h11111111, 1, 8'h10, 8'h20, 8'h03);
    tr2 = tr1.deep_copy();
    $display("tr2 = tr1.deep_copy();");

    $display("修改tr2的非对象成员和嵌套对象:");
    tr2.addr = 32'h6000_0000;
    tr2.hdr.src = 8'hFF;
    $display("tr2:"); tr2.display();
    $display("tr1 (完全不受影响):"); tr1.display();
    $display("  → 深复制:所有层级完全独立,互不影响\n");

    // =====================================================================
    // 示例4: 句柄赋值 vs 浅复制 vs 深复制对比总结
    // =====================================================================
    $display("--- 示例4: 三种方式对比 ---");
    tr1 = new(32'h7000_0000, 32'hAAAAAAAA, 1, 8'h11, 8'h22, 8'h04);

    $display("原始对象tr1:");
    tr1.display();

    // 句柄赋值
    begin
      Transaction h_assign = tr1;
      h_assign.addr = 32'h0000_0001;
      $display("句柄赋值后修改addr → tr1.addr=0x%08h (共享)", tr1.addr);
    end

    // 浅复制
    begin
      Transaction s_copy = tr1.shallow_copy();
      s_copy.addr = 32'h0000_0002;
      $display("浅复制后修改addr   → tr1.addr=0x%08h (非对象独立)", tr1.addr);
      s_copy.hdr.src = 8'hFE;
      $display("浅复制后修改hdr.src → tr1.hdr.src=0x%02h (嵌套共享)", tr1.hdr.src);
    end

    // 深复制
    begin
      Transaction d_copy = tr1.deep_copy();
      d_copy.addr = 32'h0000_0003;
      $display("深复制后修改addr   → tr1.addr=0x%08h (非对象独立)", tr1.addr);
      d_copy.hdr.src = 8'hFD;
      $display("深复制后修改hdr.src → tr1.hdr.src=0x%02h (嵌套也独立)", tr1.hdr.src);
    end
    $display("");

    // =====================================================================
    $display("========================================");
    $display(" 关键要点:");
    $display("  1. 句柄赋值(tr2=tr1): 共享同一对象");
    $display("  2. 浅复制: 非对象成员独立, 嵌套对象共享");
    $display("  3. 深复制: 所有层级完全独立");
    $display("  4. 标准做法: 在类中定义copy()方法");
    $display("  5. 深复制需对每个嵌套对象调用new()");
    $display("========================================");

    $finish;
  end

endmodule

//==============================================================================
// 编译运行:
//   vlog 05_object_copy.sv
//   vsim -novopt object_copy_test -do "run -all"
//==============================================================================
