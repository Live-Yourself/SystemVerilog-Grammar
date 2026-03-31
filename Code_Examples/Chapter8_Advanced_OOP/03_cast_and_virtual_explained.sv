// KP03 向下类型转换与虚方法 —— 通俗版详细示例
// 用"电视+遥控器"的比喻，逐步演示每个概念

// ============================================================
// 基类 Transaction —— "普通电视"
// ============================================================
class Transaction;
    int addr;
    int data;
    string name;

    function new(string name = "txn");
        this.name = name;
        this.addr = 0;
        this.data = 0;
    endfunction

    // 【重点】这里没有 virtual
    // 调用时只看"遥控器类型"，不看实际电视类型
    function void display();
        $display("  [%s.display] -> 调用 Transaction 版本 (看遥控器类型)", name);
    endfunction

    // 【重点】这里有 virtual
    // 调时看"实际电视类型"，不看遥控器类型
    virtual function void print_type();
        $display("  [%s.print_type] -> 我是 Transaction (普通电视)", name);
    endfunction
endclass

// ============================================================
// 子类 ReadWriteTxn —— "升级版电视"，多了 rw 功能
// ============================================================
class ReadWriteTxn extends Transaction;
    bit rw;   // 子类特有：0=读, 1=写

    function new(string name = "rw_txn");
        super.new(name);
        this.rw = 0;
    endfunction

    // 覆盖 display —— 父类没有 virtual，所以这个覆盖在某些场景下会"失效"
    function void display();
        $display("  [%s.display] -> 调用 ReadWriteTxn 版本 (看遥控器类型)", name);
    endfunction

    // 覆盖 print_type —— 父类有 virtual，所以这个覆盖在任何场景下都生效
    function void print_type();
        $display("  [%s.print_type] -> 我是 ReadWriteTxn (升级版电视), rw=%0d", name, rw);
    endfunction
endclass

// ============================================================
// 测试：一步步演示
// ============================================================
module tb_explained;

    Transaction base_txn;     // "普通遥控器"
    ReadWriteTxn rw_txn;      // "升级版遥控器"

    initial begin
        $display("========================================");
        $display("  KP03 $cast 与 virtual —— 通俗讲解版");
        $display("========================================\n");

        // ================================================
        // 第一步：理解"句柄=遥控器，对象=电视"
        // ================================================
        $display("【第1步】句柄=遥控器，对象=电视");
        $display("  Transaction base_txn;       // 声明了一个遥控器，还没买电视");
        $display("  base_txn = new(\"base\");    // 买了一台普通电视，遥控器绑定到它");
        base_txn = new("base");
        $display("  base_txn.name = %0s  (遥控器控制的是这台电视)", base_txn.name);
        $display("");

        // ================================================
        // 第2步：继承 = 升级版电视
        // ================================================
        $display("【第2步】继承 = 升级版电视");
        $display("  ReadWriteTxn 是 Transaction 的升级版，多了 rw 按钮");
        rw_txn = new("upgrade");
        rw_txn.addr = 100;
        rw_txn.rw = 1;
        $display("  rw_txn.addr = %0d  (父类的频道按钮) ✓", rw_txn.addr);
        $display("  rw_txn.rw   = %0d  (子类新增的按钮) ✓", rw_txn.rw);
        $display("");

        // ================================================
        // 第3步：向上转换 = 普通遥控器控制升级版电视
        // ================================================
        $display("【第3步】向上转换 = 普通遥控器 → 升级版电视");
        $display("  base_txn = rw_txn;  // 用普通遥控器指向升级版电视");
        base_txn = rw_txn;
        $display("  base_txn.addr = %0d  ✓ 普通遥控器有这个按钮", base_txn.addr);
        $display("  base_txn.rw = ???     ✗ 普通遥控器没有这个按钮！(编译报错)");
        $display("  → 电视本身是升级版的，但遥控器看不到 rw");
        $display("");

        // ================================================
        // 第4步：virtual 的区别（最关键！）
        // ================================================
        $display("【第4步】virtual 的区别 —— 这是核心！");
        $display("  现在：base_txn 是普通遥控器，但连的是升级版电视");
        $display("  ---");
        $display("  base_txn.display();    // display 没有 virtual");
        base_txn.display();
        $display("  ↑ 看遥控器类型(Transaction) → 调用 Transaction 版本");
        $display("");
        $display("  base_txn.print_type(); // print_type 有 virtual");
        base_txn.print_type();
        $display("  ↑ 看实际电视(ReadWriteTxn) → 调用 ReadWriteTxn 版本");
        $display("");
        $display("  规则总结：");
        $display("  ├── 没有 virtual → 编译时决定 → 看遥控器上写的类型");
        $display("  └── 有   virtual → 运行时决定 → 看实际连的电视类型");
        $display("");

        // ================================================
        // 第5步：$cast = 换遥控器
        // ================================================
        $display("【第5步】$cast = 换遥控器");
        $display("  我知道电视是升级版的，想用升级版遥控器按 rw 按钮");
        begin
            ReadWriteTxn upgraded_remote;   // 准备升级版遥控器
            $cast(upgraded_remote, base_txn);  // 换遥控器！
            $display("  $cast(upgraded_remote, base_txn) 成功！");
            $display("  upgraded_remote.rw = %0d  ✓ 现在能按 rw 了", upgraded_remote.rw);
            $display("  upgraded_remote.addr = %0d  ✓ 也能按 addr", upgraded_remote.addr);
        end
        $display("");

        // ================================================
        // 第6步：$cast 失败的情况
        // ================================================
        $display("【第6步】$cast 什么时候失败？");
        $display("  如果电视本身就是普通版的，就不能用升级版遥控器");
        begin
            Transaction pure_base = new("普通电视");  // 买的是普通电视
            ReadWriteTxn try_rw;
            int ok;

            $display("  pure_base = new(\"普通电视\");  // 纯普通电视");
            $display("");
            $display("  函数形式 $cast (不会报错，返回 0)：");
            ok = $cast(try_rw, pure_base);
            $display("    返回值 = %0d (0=失败)  → 电视没有 rw 功能，转换失败", ok);
            $display("");
            $display("  任务形式 $cast (会直接报错，被注释掉)：");
            $display("    // $cast(try_rw, pure_base);  ← 会 fatal error！");
            $display("    // 因为电视是普通版的，升级版遥控器不匹配");
        end

        $display("\n========================================");
        $display("  总结：");
        $display("  1. 句柄类型 = 能看到什么按钮");
        $display("  2. virtual    = 按按钮时看实际电视还是看遥控器标签");
        $display("  3. $cast      = 安全换遥控器");
        $display("========================================");
    end

endmodule
