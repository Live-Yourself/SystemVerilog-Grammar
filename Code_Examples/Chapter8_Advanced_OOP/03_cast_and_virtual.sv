// KP03 向下类型转换（$cast）与虚方法
// 演示：向上/向下类型转换、$cast函数形式与任务形式、virtual与静态绑定的区别

// ============================================================
// 1. 基类 Transaction
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

    // 非 virtual 方法 —— 静态绑定，根据句柄类型调用
    function void display();
        $display("[Base.display] %0s: addr=0x%0h, data=0x%0h", name, addr, data);
    endfunction

    // virtual 方法 —— 动态绑定，根据实际对象类型调用
    virtual function void print_type();
        $display("[Base.print_type] This is Transaction: %0s", name);
    endfunction
endclass

// ============================================================
// 2. 子类 ReadWriteTxn
// ============================================================
class ReadWriteTxn extends Transaction;
    bit rw;   // 0=读, 1=写

    function new(string name = "rw_txn");
        super.new(name);
        this.rw = 0;
    endfunction

    // 覆盖 display（非 virtual —— 静态绑定）
    function void display();
        $display("[Child.display] %0s: %0s, addr=0x%0h, data=0x%0h",
                 name, rw ? "WRITE" : "READ", addr, data);
    endfunction

    // 覆盖 print_type（virtual —— 动态绑定）
    function void print_type();
        $display("[Child.print_type] This is ReadWriteTxn: %0s, rw=%0d", name, rw);
    endfunction
endclass

// ============================================================
// 3. 测试验证
// ============================================================
module tb_cast_virtual;

    Transaction base_txn;
    ReadWriteTxn rw_txn;
    int cast_result;

    initial begin
        $display("===== KP03 $cast 与虚方法 演示 =====\n");

        // -------------------------------------------------------
        // 3.1 向上类型转换（自动完成）
        // -------------------------------------------------------
        $display("--- 场景1: 向上类型转换 ---");
        rw_txn = new("my_rw");
        rw_txn.addr = 32'h100;
        rw_txn.data = 32'hABCD;
        rw_txn.rw   = 1;

        base_txn = rw_txn;   // 子类 → 父类，自动完成
        $display("向上转换完成: base_txn 指向 ReadWriteTxn 对象");
        $display("但 base_txn 只能访问父类成员: addr=%0h, data=%0h", base_txn.addr, base_txn.data);
        // base_txn.rw  // ERROR: 父类句柄看不到 rw
        $display("");

        // -------------------------------------------------------
        // 3.2 virtual vs 非 virtual 的关键区别
        // -------------------------------------------------------
        $display("--- 场景2: virtual vs 非 virtual ---");
        $display("base_txn 实际指向 ReadWriteTxn 对象，但句柄类型是 Transaction:");
        base_txn.display();     // 非 virtual → 静态绑定 → 调用 Transaction::display()
        base_txn.print_type();  // virtual   → 动态绑定 → 调用 ReadWriteTxn::print_type()
        $display("  display()   : 非virtual，根据句柄类型(Transaction)调用 → Base版本");
        $display("  print_type(): virtual，根据实际对象(ReadWriteTxn)调用 → Child版本");
        $display("");

        // -------------------------------------------------------
        // 3.3 向下类型转换 —— $cast 任务形式
        // -------------------------------------------------------
        $display("--- 场景3: $cast 任务形式（推荐） ---");
        begin
            ReadWriteTxn local_rw;
            // base_txn 实际指向 ReadWriteTxn 对象，$cast 成功
            $cast(local_rw, base_txn);
            $display("$cast 成功！现在可以访问子类特有成员: rw = %0d", local_rw.rw);
            local_rw.display();
        end
        $display("");

        // -------------------------------------------------------
        // 3.4 向下类型转换 —— $cast 函数形式（安全检查）
        // -------------------------------------------------------
        $display("--- 场景4: $cast 函数形式（可做错误处理） ---");
        begin
            Transaction real_base = new("pure_base");  // 纯父类对象
            ReadWriteTxn cast_try;

            // real_base 实际指向 Transaction 对象，不是 ReadWriteTxn → $cast 失败
            cast_result = $cast(cast_try, real_base);
            $display("$cast 返回值: %0d (0=失败, 1=成功)", cast_result);
            $display("说明: 不能把纯父类对象转换为子类句柄");
        end
        $display("");

        // -------------------------------------------------------
        // 3.5 $cast 任务形式失败时的运行时错误
        // -------------------------------------------------------
        $display("--- 场景5: $cast 任务形式失败（会报运行时错误） ---");
        $display("以下代码被注释掉，因为它会导致运行时 fatal error:");
        $display("  Transaction real_base = new(\"pure_base\");");
        $display("  ReadWriteTxn cast_try;");
        $display("  $cast(cast_try, real_base);  // ← 运行时报错: cast failed");
        $display("");

        // -------------------------------------------------------
        // 3.6 验证平台中的典型使用场景
        // -------------------------------------------------------
        $display("--- 场景6: 验证平台典型场景 ---");
        begin
            Transaction gen_txn;

            // 生成器产生一个 ReadWriteTxn
            gen_txn = new("gen_rw_txn");
            // 实际验证中这里可能是工厂模式创建的子类对象

            // 假设我们把它换成真正的 ReadWriteTxn
            rw_txn = new("driver_input");
            rw_txn.rw = 1;
            rw_txn.addr = 32'h200;
            rw_txn.data = 32'h5678;
            gen_txn = rw_txn;

            // 驱动器需要访问 rw 字段 → 用 $cast 向下转换
            begin
                ReadWriteTxn drv_txn;
                $cast(drv_txn, gen_txn);   // 还原子类类型
                $display("[Driver] 收到事务，类型转换成功");
                $display("[Driver] 操作类型: %0s", drv_txn.rw ? "WRITE" : "READ");
                $display("[Driver] 写入数据: 0x%0h -> addr 0x%0h", drv_txn.data, drv_txn.addr);
            end
        end

        $display("\n===== KP03 演示结束 =====");
    end

endmodule
