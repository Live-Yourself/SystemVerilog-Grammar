// KP10 测试注册表与工厂模式（Registry & Factory Pattern）
// 演示：简单工厂、注册表查表创建、动态类型选择

// ============================================================
// 1. 基类 Transaction
// ============================================================
class Transaction;
    string txn_type;
    int addr;
    int data;

    function new(string txn_type = "base");
        this.txn_type = txn_type;
        this.addr = 0;
        this.data = 0;
    endfunction

    virtual function void display();
        $display("    [%0s Transaction] addr=0x%0h, data=0x%0h", txn_type, addr, data);
    endfunction

    virtual function Transaction copy();
        Transaction c = new(this.txn_type);
        c.addr = this.addr;
        c.data = this.data;
        return c;
    endfunction
endclass

// ============================================================
// 2. 具体子类
// ============================================================
class ReadTxn extends Transaction;
    function new(string name = "read");
        super.new("READ");
    endfunction

    function void display();
        $display("    [READ Transaction] addr=0x%0h (读操作)", addr);
    endfunction
endclass

class WriteTxn extends Transaction;
    function new(string name = "write");
        super.new("WRITE");
    endfunction

    function void display();
        $display("    [WRITE Transaction] addr=0x%0h, data=0x%0h (写操作)", addr, data);
    endfunction
endfunction

class ResetTxn extends Transaction;
    function new(string name = "reset");
        super.new("RESET");
    endfunction

    function void display();
        $display("    [RESET Transaction] (复位操作)");
    endfunction
endclass

// ============================================================
// 3. 简单工厂 —— 用 if-else 根据类型名创建对象
// ============================================================
class SimpleFactory;
    static function Transaction create(string type_name);
        if (type_name == "READ")
            return new("read");
        else if (type_name == "WRITE")
            return new("write");
        else if (type_name == "RESET")
            return new("reset");
        else begin
            $display("    [SimpleFactory] 未知类型: %0s", type_name);
            return null;
        end
    endfunction
endclass

// ============================================================
// 4. 注册表 + 工厂 —— 用关联数组查表
// ============================================================
class Factory;
    // 函数指针类型：输入 string，返回 Transaction 对象
    typedef function Transaction automatic (string);

    // 注册表：字符串 → 创建函数的映射
    static Transaction (*registry[string])(string);

    // 注册：把类型名和创建函数绑定
    static function void register_type(string type_name, Transaction (creator)(string));
        registry[type_name] = creator;
    endfunction

    // 创建：查注册表，调用对应的创建函数
    static function Transaction create(string type_name);
        if (registry.exists(type_name))
            return registry[type_name](type_name);
        else begin
            $display("    [Factory] 未注册的类型: %0s", type_name);
            return null;
        end
    endfunction

    // 查看已注册的类型
    static function void list_types();
        string keys[$];
        int i;
        registry.keys(keys);
        $display("    [Factory] 已注册类型 (%0d个):", keys.size());
        for (i = 0; i < keys.size(); i++)
            $display("      - %0s", keys[i]);
    endfunction
endclass

// ============================================================
// 5. 使用工厂的组件 —— 不知道具体类名
// ============================================================
class Generator;
    string name;
    string txn_type_name;   // 用字符串指定要创建的事务类型

    function new(string name = "gen", string type_name = "READ");
        this.name = name;
        this.txn_type_name = type_name;
    endfunction

    // 通过工厂创建事务 —— 完全不知道具体是哪个子类
    task generate_txn(output Transaction txn);
        txn = Factory::create(txn_type_name);
        if (txn != null)
            $display("    [Generator:%0s] 创建了 %0s 类型的事务", name, txn_type_name);
    endtask
endclass

// ============================================================
// 测试验证
// ============================================================
module tb_factory;

    initial begin
        $display("========================================");
        $display("  KP10 注册表与工厂模式");
        $display("========================================\n");

        // ================================================
        // 场景1：简单工厂
        // ================================================
        $display("--- 场景1: 简单工厂（if-else） ---");
        begin
            Transaction t1, t2, t3;
            t1 = SimpleFactory::create("READ");
            t1.addr = 32'h1000;
            t1.display();

            t2 = SimpleFactory::create("WRITE");
            t2.addr = 32'h2000;
            t2.data = 32'hABCD;
            t2.display();

            t3 = SimpleFactory::create("RESET");
            t3.display();
        end
        $display("");

        // ================================================
        // 场景2：注册表 + 工厂
        // ================================================
        $display("--- 场景2: 注册所有类型 ---");
        // 把类型名和对应的创建函数绑定
        Factory::register_type("READ",  ReadTxn::new);    // 这里简化写法
        Factory::register_type("WRITE", WriteTxn::new);
        Factory::register_type("RESET", ResetTxn::new);
        Factory::list_types();
        $display("");

        // ================================================
        // 场景3：通过工厂创建对象
        // ================================================
        $display("--- 场景3: 工厂创建对象 ---");
        begin
            Transaction t;
            t = Factory::create("WRITE");
            t.addr = 32'h3000;
            t.data = 32'h5678;
            t.display();    // 调用的是 WriteTxn 的 display（virtual）
        end
        $display("");

        // ================================================
        // 场景4：Generator 不知道具体类名
        // ================================================
        $display("--- 场景4: 组件通过字符串动态创建 ---");
        begin
            Transaction txn;
            Generator gen;

            // 创建一个"写事务"生成器
            gen = new("master_gen", "WRITE");
            gen.generate_txn(txn);
            txn.display();

            // 同一个 Generator，换个类型名就能生成读事务
            gen.txn_type_name = "READ";
            txn.addr = 32'h4000;
            gen.generate_txn(txn);
            txn.display();

            gen.txn_type_name = "RESET";
            gen.generate_txn(txn);
            txn.display();
        end
        $display("");

        // ================================================
        // 场景5：新增子类只需注册，不改已有代码
        // ================================================
        $display("--- 场景5: 扩展性演示 ---");
        $display("  如果要新增一个 IdleTxn 类型:");
        $display("  1. 定义 class IdleTxn extends Transaction; ... endclass");
        $display("  2. Factory::register_type(\"IDLE\", IdleTxn::new);");
        $display("  3. 之后就可以 Factory::create(\"IDLE\")");
        $display("  → Generator、Scoreboard 等所有组件的代码一行不改！");
        $display("  → 这就是 UVM 中 uvm_factory + uvm_object_registry 的原理");

        $display("\n========================================");
        $display("  总结");
        $display("  ├── 工厂模式 : 调用方不需要知道具体类名");
        $display("  ├── 注册表   : 字符串 → 创建函数的映射");
        $display("  ├── 结合使用 : 注册表存映射，工厂查表创建");
        $display("  └── 扩展性   : 新增子类只需注册，不改已有代码");
        $display("========================================");
    end

endmodule
