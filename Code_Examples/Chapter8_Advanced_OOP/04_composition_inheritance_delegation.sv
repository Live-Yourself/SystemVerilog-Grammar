// KP04 组合、继承和替代（Composition, Inheritance, and Delegation）
// 演示：三种复用类功能的方式对比

// ============================================================
// 公共基础类 Transaction —— 模拟一个基础事务
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

    virtual function void display();
        $display("  [%0s] addr=0x%0h, data=0x%0h", name, addr, data);
    endfunction
endclass

// ============================================================
// 方式一：继承（Inheritance）—— "是一种"
// ============================================================
class ReadWriteTxn extends Transaction;
    bit rw;   // 0=读, 1=写

    function new(string name = "rw_txn");
        super.new(name);
        this.rw = 0;
    endfunction

    // 覆盖 display，加入 rw 信息
    function void display();
        $display("  [%0s] %0s, addr=0x%0h, data=0x%0h",
                 name, rw ? "WRITE" : "READ", addr, data);
    endfunction
endclass

// ============================================================
// 方式二：组合（Composition）—— "有一个"
// ============================================================
class Driver;
    string name;
    Transaction txn;   // Driver 内部"有一个" Transaction

    function new(string name = "driver");
        this.name = name;
        this.txn = new("driver_txn");   // 创建内部的事务对象
    endfunction

    // Driver 提供自己的接口，内部通过 txn 操作
    function void set_transaction(int addr, int data);
        this.txn.addr = addr;
        this.txn.data = data;
        $display("  [Driver:%0s] 设置事务: addr=0x%0h, data=0x%0h",
                 this.name, addr, data);
    endfunction

    function void send();
        $display("  [Driver:%0s] 发送事务:", this.name);
        this.txn.display();
    endfunction
endclass

// ============================================================
// 方式三：委托（Delegation）—— "借用功能"
// ============================================================
class BusTxn;
    string name;
    Transaction impl;   // 内部持有一个 Transaction，但不直接暴露

    function new(string name = "bus_txn");
        this.name = name;
        this.impl = new("impl");   // 创建内部实现对象
    endfunction

    // 外部调用 set_addr，实际转发给 impl.addr
    function void set_addr(int a);
        impl.addr = a;
    endfunction

    // 外部调用 get_addr，实际从 impl.addr 读取
    function int get_addr();
        return impl.addr;
    endfunction

    // 外部调用 set_data，实际转发给 impl.data
    function void set_data(int d);
        impl.data = d;
    endfunction

    // BusTxn 有自己的 display，内部调用 impl 的信息
    function void display();
        $display("  [BusTxn:%0s] bus_addr=0x%0h, bus_data=0x%0h",
                 name, impl.addr, impl.data);
    endfunction
endclass

// ============================================================
// 测试验证
// ============================================================
module tb_design_choice;

    initial begin
        $display("========================================");
        $display("  KP04 组合、继承、替代 —— 三种方式对比");
        $display("========================================\n");

        // ================================================
        // 场景1：继承 —— "是一种"
        // ================================================
        $display("--- 方式一：继承（is-a） ---");
        $display("  ReadWriteTxn 是一种 Transaction");
        $display("  → 自动拥有 addr, data, name, display()");
        begin
            ReadWriteTxn rw;
            rw = new("my_rw");
            rw.rw   = 1;
            rw.addr = 32'h100;
            rw.data = 32'hABCD;
            rw.display();   // 调用覆盖后的 display
        end
        $display("  关系：ReadWriteTxn 「是一种」 Transaction");
        $display("  适用：子类是父类的特殊版本\n");

        // ================================================
        // 场景2：组合 —— "有一个"
        // ================================================
        $display("--- 方式二：组合（has-a） ---");
        $display("  Driver 有一个 Transaction");
        $display("  → Driver 不是 Transaction，只是内部包含它");
        begin
            Driver drv;
            drv = new("master_drv");
            drv.set_transaction(32'h200, 32'h1234);
            drv.send();
        end
        $display("  关系：Driver 「有一个」 Transaction");
        $display("  适用：整体-部分关系，如 Driver 包含 Transaction\n");

        // ================================================
        // 场景3：委托 —— "借用功能"
        // ================================================
        $display("--- 方式三：委托（delegation） ---");
        $display("  BusTxn 借用 Transaction 的功能");
        $display("  → 外部只看到 BusTxn 的接口，不知道内部有 Transaction");
        begin
            BusTxn bus;
            bus = new("axi_bus");
            bus.set_addr(32'h300);
            bus.set_data(32'h5678);
            bus.display();
            $display("  内部地址值(通过 get_addr): 0x%0h", bus.get_addr());
        end
        $display("  关系：BusTxn 「借用」 Transaction 的功能");
        $display("  适用：想复用功能但不想暴露内部实现\n");

        // ================================================
        // 总结
        // ================================================
        $display("========================================");
        $display("  总结");
        $display("  ┌──────────┬──────────────────────────┐");
        $display("  │  方式    │  关系                    │");
        $display("  ├──────────┼──────────────────────────┤");
        $display("  │  继承    │  子类「是一种」父类       │");
        $display("  │  组合    │  类A「有一个」类B        │");
        $display("  │  委托    │  类A「借用」类B的功能    │");
        $display("  └──────────┴──────────────────────────┘");
        $display("========================================");
    end

endmodule
