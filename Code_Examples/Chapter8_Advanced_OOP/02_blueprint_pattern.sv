// KP02 蓝图模式（Blueprint Pattern）
// 演示：copy()方法实现、蓝图对象创建、工作副本批量生成、蓝图与随机化结合

// ============================================================
// 1. Transaction 类 —— 包含 copy() 方法
// ============================================================
class Transaction;
    rand bit [31:0] addr;
    rand bit [31:0] data;
         bit [7:0]  length;      // 非随机字段
         string     name;

    // 约束：地址范围 0~255
    constraint c_addr { addr < 256; }

    // 构造函数
    function new(string name = "txn");
        this.name = name;
        this.addr = 0;
        this.data = 0;
        this.length = 1;
    endfunction

    // === 核心：copy() 方法 ===
    // 创建一个新对象，将所有属性从 this 复制过去
    function Transaction copy();
        Transaction c = new();
        c.addr   = this.addr;
        c.data   = this.data;
        c.length = this.length;
        c.name   = this.name;
        return c;
    endfunction

    // 打印方法
    function void display();
        $display("[TXN] %0s: addr=0x%0h, data=0x%0h, len=%0d",
                 this.name, this.addr, this.data, this.length);
    endfunction
endclass

// ============================================================
// 2. 扩展：ReadWriteTxn —— 演示继承中的 copy()
// ============================================================
class ReadWriteTxn extends Transaction;
    rand bit rw;   // 0=读, 1=写

    function new(string name = "rw_txn");
        super.new(name);
        this.rw = 0;
    endfunction

    // 子类的 copy()：先拷贝父类部分，再拷贝子类特有的字段
    function Transaction copy();
        ReadWriteTxn c = new();
        // 拷贝父类成员
        c.addr   = this.addr;
        c.data   = this.data;
        c.length = this.length;
        c.name   = this.name;
        // 拷贝子类特有成员
        c.rw     = this.rw;
        return c;
    endfunction

    function void display();
        $display("[TXN] %0s: %0s, addr=0x%0h, data=0x%0h, len=%0d",
                 this.name, this.rw ? "WRITE" : "READ",
                 this.addr, this.data, this.length);
    endfunction
endclass

// ============================================================
// 3. 测试验证
// ============================================================
module tb_blueprint;

    initial begin
        $display("===== KP02 蓝图模式 演示 =====\n");

        // -------------------------------------------------------
        // 3.1 基本蓝图模式：创建蓝图 → 拷贝 → 修改工作副本
        // -------------------------------------------------------
        $display("--- 场景1: 基本蓝图模式 ---");
        begin
            Transaction blueprint, txn1, txn2, txn3;

            // Step 1: 创建蓝图，配置默认属性
            blueprint = new("blueprint");
            blueprint.addr   = 32'h10;
            blueprint.data   = 32'hFFFF;
            blueprint.length = 4;
            $display("[蓝图配置完成]");
            blueprint.display();

            // Step 2: 从蓝图拷贝生成工作副本
            txn1 = blueprint.copy();
            txn1.name = "txn_1";

            txn2 = blueprint.copy();
            txn2.name = "txn_2";
            txn2.addr = 32'h20;    // 修改个别属性

            txn3 = blueprint.copy();
            txn3.name = "txn_3";
            txn3.data = 32'h0000;  // 修改个别属性

            // Step 3: 验证 —— 蓝图本身不变
            $display("\n[工作副本]:");
            txn1.display();
            txn2.display();
            txn3.display();
            $display("\n[蓝图未被修改]:");
            blueprint.display();
        end
        $display("");

        // -------------------------------------------------------
        // 3.2 蓝图 + 随机化结合
        // -------------------------------------------------------
        $display("--- 场景2: 蓝图模式 + 随机化 ---");
        begin
            Transaction blueprint, txn;

            // 蓝图设置固定框架
            blueprint = new("fixed_addr");
            blueprint.addr   = 32'hA0;     // 固定地址
            blueprint.length = 8;           // 固定长度

            // 拷贝后只随机化 data
            repeat (3) begin
                txn = blueprint.copy();
                txn.name = "rand_txn";
                txn.randomize(data);         // 只随机化 data，addr 和 length 保持蓝图值
                txn.display();
            end
        end
        $display("");

        // -------------------------------------------------------
        // 3.3 继承中的蓝图模式
        // -------------------------------------------------------
        $display("--- 场景3: 继承中的蓝图模式 ---");
        begin
            ReadWriteTxn rw_bp, rw1, rw2;

            rw_bp = new("rw_blueprint");
            rw_bp.addr = 32'h50;
            rw_bp.rw   = 1;  // 写操作

            // 拷贝并修改
            rw1 = rw_bp.copy();
            rw1.name = "write_1";
            rw1.data = 32'h1234;

            rw2 = rw_bp.copy();
            rw2.name = "read_1";
            rw2.rw   = 0;    // 改为读操作

            $display("[继承蓝图 - 工作副本]:");
            rw1.display();
            rw2.display();
            $display("[蓝图保持不变]:");
            rw_bp.display();
        end

        $display("\n===== KP02 演示结束 =====");
    end

endmodule
