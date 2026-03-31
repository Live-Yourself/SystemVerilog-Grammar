// KP01 继承简介（Inheritance Basics）
// 演示：基类定义、extends继承、super.new()构造、方法覆盖、可见性规则

// ============================================================
// 1. 基类 Transaction —— 模拟一个基础事务包
// ============================================================
class Transaction;
    // local 成员：仅本类可访问，子类不可见
    local int local_id;

    // protected 成员：本类和子类可访问，外部不可见
    protected int protected_addr;

    // public 成员：所有地方都可访问（默认就是 public）
    int data;
    string name;

    // 静态计数器，用于分配 ID
    static int id_counter = 0;

    // 构造函数
    function new(string name = "txn");
        this.name = name;
        this.local_id = id_counter++;    // local 成员赋值
        this.protected_addr = 0;         // protected 成员赋值
        this.data = 0;
        $display("[Base] %0s created, local_id=%0d", this.name, this.local_id);
    endfunction

    // 普通方法
    function void display();
        $display("[Base] %0s: addr=%0h, data=%0h, id=%0d",
                 this.name, this.protected_addr, this.data, this.local_id);
    endfunction

    // 方法：设置地址（protected成员）
    function void set_addr(int addr);
        this.protected_addr = addr;
    endfunction

    // 方法：获取地址
    function int get_addr();
        return this.protected_addr;
    endfunction

    // 方法：打印——子类会覆盖此方法
    virtual function void print_type();
        $display("[Base] This is a base Transaction: %0s", this.name);
    endfunction
endclass

// ============================================================
// 2. 子类 BadTxn —— 继承 Transaction，模拟一个错误事务
// ============================================================
class BadTxn extends Transaction;
    // 子类新增的成员
    int error_code;

    // 注意：这里定义了一个同名的 local_id，不会与父类冲突
    // 因为父类的 local_id 是 local 的，子类看不到
    local int local_id;

    // 构造函数：必须第一条语句调用 super.new()
    function new(string name = "bad_txn");
        super.new(name);          // <-- 必须是第一条语句，初始化父类部分
        this.error_code = 0;
        this.local_id = 999;      // 子类自己的 local_id
        $display("[Child] %0s (BadTxn) created, error_code=%0d, child_local_id=%0d",
                 this.name, this.error_code, this.local_id);
    endfunction

    // 覆盖父类的 display 方法（保留父类行为 + 添加子类信息）
    function void display();
        super.display();           // 先调用父类的 display
        $display("[Child] %0s: error_code=%0d", this.name, this.error_code);
    endfunction

    // 覆盖父类的 print_type 方法
    function void print_type();
        $display("[Child] This is a BadTxn (error transaction): %0s", this.name);
    endfunction

    // 子类可以直接访问父类的 protected 成员
    function void set_addr_and_error(int addr, int err);
        this.protected_addr = addr;  // OK: protected 成员在子类中可访问
        this.error_code = err;
    endfunction

    // 注意：以下代码如果取消注释会导致编译错误
    // function void try_access_local();
    //     this.local_id = 10;  // ERROR: 父类的 local_id 是 local 的，子类无法访问
    // endfunction
endclass

// ============================================================
// 3. 测试验证
// ============================================================
module tb_inheritance;

    Transaction txn;    // 基类句柄
    BadTxn     bad;     // 子类句柄

    initial begin
        $display("===== KP01 继承简介 演示 =====\n");

        // --- 3.1 创建基类对象 ---
        $display("--- 创建基类 Transaction ---");
        txn = new("base_txn");
        txn.set_addr(32'h1000);
        txn.data = 32'hABCD;
        txn.display();
        txn.print_type();
        $display("");

        // --- 3.2 创建子类对象 ---
        $display("--- 创建子类 BadTxn ---");
        bad = new("my_bad_txn");
        bad.set_addr_and_error(32'h2000, 3);  // 使用子类特有方法
        bad.data = 32'h1234;
        bad.display();
        bad.print_type();
        $display("");

        // --- 3.3 多态：父类句柄指向子类对象 ---
        $display("--- 多态：父类句柄指向子类对象 ---");
        txn = bad;  // OK: 子类句柄赋给父类句柄（向上类型转换，自动完成）
        // txn.set_addr_and_error(...);  // ERROR: 父类句柄只能看到父类的成员
        txn.display();       // 调用的是子类覆盖后的 display（因为方法不是 virtual 的，这里调用的是静态绑定的父类版本）
        txn.print_type();    // 调用的是子类覆盖后的 print_type（因为 print_type 是 virtual 的）
        $display("");

        // --- 3.4 可见性演示 ---
        $display("--- 可见性规则演示 ---");
        $display("public成员 data 可直接访问: txn.data = %0h", txn.data);
        $display("通过 public 方法访问 protected 成员: txn.get_addr() = %0h", txn.get_addr());
        // $display("local_id = %0d", txn.local_id);  // ERROR: local 成员外部不可访问
        $display("（local成员无法在外部直接访问，这行被注释掉了）");

        $display("\n===== KP01 演示结束 =====");
    end

endmodule
