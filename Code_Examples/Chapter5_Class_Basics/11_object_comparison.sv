// =============================================================================
// 知识点11: 对象的比较 - 示例代码
// 基于《SystemVerilog验证 - 测试平台编写指南》第5章
// =============================================================================

// =============================================================================
// Transaction类: 含compare方法
// =============================================================================
class Transaction;
  bit [31:0] addr;
  bit [31:0] data;
  bit        write;

  function new(bit [31:0] addr, bit [31:0] data, bit write);
    this.addr  = addr;
    this.data  = data;
    this.write = write;
  endfunction

  function void display(string name = "tr");
    $display("  [%s] addr=0x%08h, data=0x%08h, write=%0d",
             name, addr, data, write);
  endfunction

  // 内容比较方法: 逐字段比较,返回1(相等)或0(不等)
  function bit compare(Transaction tr);
    compare = 1;
    if (this.addr != tr.addr) begin
      $display("    [FAIL] addr: 0x%08h vs 0x%08h", this.addr, tr.addr);
      compare = 0;
    end
    if (this.data != tr.data) begin
      $display("    [FAIL] data: 0x%08h vs 0x%08h", this.data, tr.data);
      compare = 0;
    end
    if (this.write != tr.write) begin
      $display("    [FAIL] write: %0d vs %0d", this.write, tr.write);
      compare = 0;
    end
  endfunction
endclass

// =============================================================================
// Header类: 用于嵌套对象比较演示
// =============================================================================
class Header;
  bit [7:0] src;
  bit [7:0] dst;

  function new(bit [7:0] s, bit [7:0] d);
    src = s;
    dst = d;
  endfunction

  function bit compare(Header h);
    if (this.src == h.src && this.dst == h.dst)
      return 1;
    else begin
      $display("    [FAIL] Header不匹配: src=%0h/%0h, dst=%0h/%0h",
               this.src, h.src, this.dst, h.dst);
      return 0;
    end
  endfunction
endclass

// =============================================================================
// Packet类: 含嵌套对象的compare
// =============================================================================
class Packet;
  bit [31:0] addr;
  Header     hdr;

  function new(bit [31:0] a, bit [7:0] s, bit [7:0] d);
    addr = a;
    hdr  = new(s, d);
  endfunction

  function void display(string name = "pkt");
    $display("  [%s] addr=0x%08h, hdr.src=0x%02h, hdr.dst=0x%02h",
             name, addr, hdr.src, hdr.dst);
  endfunction

  // 递归比较: 先比较自身成员,再比较嵌套对象
  function bit compare(Packet p);
    if (this.addr != p.addr) begin
      $display("    [FAIL] addr: 0x%08h vs 0x%08h", this.addr, p.addr);
      return 0;
    end
    if (this.hdr == null || p.hdr == null) begin
      $display("    [FAIL] hdr为null");
      return 0;
    end
    return this.hdr.compare(p.hdr);
  endfunction
endclass

// =============================================================================
// 简易Scoreboard: compare()的典型应用
// =============================================================================
class Scoreboard;
  static int pass_count = 0;
  static int fail_count = 0;

  static function void check(Transaction expected, Transaction actual);
    $display("  [Scoreboard] 比对:");
    expected.display("expected");
    actual.display("actual  ");
    if (expected.compare(actual)) begin
      $display("  [Scoreboard] PASS");
      pass_count = pass_count + 1;
    end else begin
      $display("  [Scoreboard] FAIL");
      fail_count = fail_count + 1;
    end
  endfunction

  static function void report();
    $display("  [Scoreboard] 总计: PASS=%0d, FAIL=%0d", pass_count, fail_count);
  endfunction
endclass

// =============================================================================
// 示例1: 句柄比较 -- ==比较地址,不比较内容
// =============================================================================
Transaction tr1_a, tr1_b, tr1_c;

initial begin
  $display("=== 示例1: 句柄比较 (==比较地址,不比较内容) ===");

  tr1_a = new(32'h1000, 32'hABCD, 1);
  tr1_b = tr1_a;                              // 句柄赋值,指向同一对象
  tr1_c = new(32'h1000, 32'hABCD, 1);         // 内容完全相同但不同对象

  $display("tr1_a和tr1_b: tr1_a == tr1_b → %0s (同一对象)", tr1_a == tr1_b ? "TRUE" : "FALSE");
  $display("tr1_a和tr1_c: tr1_a == tr1_c → %0s (内容相同但不同对象!)",
           tr1_a == tr1_c ? "TRUE" : "FALSE");
  $display("tr1_a和tr1_c: tr1_a != tr1_c → %0s", tr1_a != tr1_c ? "TRUE" : "FALSE");
  $display("");
end

// =============================================================================
// 示例2: 内容比较 -- compare()逐字段比较
// =============================================================================
Transaction tr2_a, tr2_b, tr2_c;

initial begin
  $display("=== 示例2: 内容比较 (compare()逐字段比较) ===");

  tr2_a = new(32'h1000, 32'hABCD, 1);
  tr2_b = new(32'h1000, 32'hABCD, 1);  // 内容相同
  tr2_c = new(32'h2000, 32'hABCD, 1);  // addr不同

  $display("tr2_a vs tr2_b (内容相同): compare = %0d", tr2_a.compare(tr2_b));
  $display("");
  $display("tr2_a vs tr2_c (addr不同): compare = %0d", tr2_a.compare(tr2_c));
  $display("");
end

// =============================================================================
// 示例3: null句柄的比较
// =============================================================================
Transaction tr3_a, tr3_b;

initial begin
  $display("=== 示例3: null句柄的比较 ===");

  // 两个null比较
  $display("两个null: tr3_a == tr3_b → %0s", tr3_a == tr3_b ? "TRUE" : "FALSE");

  // null与有效句柄比较
  tr3_b = new(32'h1000, 32'hABCD, 1);
  $display("null vs 有效: tr3_a == tr3_b → %0s", tr3_a == tr3_b ? "TRUE" : "FALSE");
  $display("null vs 有效: tr3_a != tr3_b → %0s", tr3_a != tr3_b ? "TRUE" : "FALSE");

  // 使用!= null判断句柄有效性
  if (tr3_b != null)
    $display("tr3_b != null → true, 句柄有效");
  $display("");
end

// =============================================================================
// 示例4: 嵌套对象的内容比较
// =============================================================================
Packet pkt4_a, pkt4_b, pkt4_c;

initial begin
  $display("=== 示例4: 嵌套对象的内容比较 ===");

  pkt4_a = new(32'h1000, 8'h10, 8'h20);
  pkt4_b = new(32'h1000, 8'h10, 8'h20);  // 内容相同
  pkt4_c = new(32'h1000, 8'h10, 8'hFF);  // dst不同

  $display("pkt4_a vs pkt4_b (完全相同): compare = %0d", pkt4_a.compare(pkt4_b));
  $display("");
  $display("pkt4_a vs pkt4_c (dst不同): compare = %0d", pkt4_a.compare(pkt4_c));
  $display("");
end

// =============================================================================
// 示例5: Scoreboard中的compare应用
// =============================================================================
Transaction exp5, act5_a, act5_b;

initial begin
  $display("=== 示例5: Scoreboard中的compare应用 ===");

  // 比对1: 匹配
  exp5   = new(32'h1000, 32'h1234, 0);
  act5_a = new(32'h1000, 32'h1234, 0);
  Scoreboard::check(exp5, act5_a);

  $display("");

  // 比对2: 不匹配
  act5_b = new(32'h1000, 32'h5678, 0);
  Scoreboard::check(exp5, act5_b);

  $display("");
  Scoreboard::report();
  $display("");
end
