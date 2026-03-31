// KP09 静态变量与单例模式（Static Variables & Singleton Pattern）
// 演示：static 变量共享、static 方法、Singleton 全局配置

// ============================================================
// 1. 静态变量演示 —— 对象计数器
// ============================================================
class Counter;
    // 静态变量：所有对象共享，只有一份
    static int total_count = 0;

    // 普通成员：每个对象各有一份
    int my_id;
    string name;

    function new(string name = "counter");
        this.name = name;
        this.my_id = total_count;   // 记录自己是第几个创建的
        total_count++;              // 每创建一个对象，总数 +1
    endfunction

    function void display();
        $display("    [%0s] 我的ID=%0d, 全局总数=%0d", name, my_id, total_count);
    endfunction

    // 静态方法：通过类名直接调用
    static function int get_total();
        return total_count;
    endfunction
endclass

// ============================================================
// 2. 单例模式 —— 全局配置对象
// ============================================================
class GlobalConfig;
    // 静态变量：持有唯一实例
    protected static GlobalConfig instance = null;

    // 配置参数（普通成员）
    int max_transactions;
    int timeout_cycles;
    bit enable_coverage;
    string test_name;

    // 构造函数设为 protected —— 外部不能 new()
    protected function new();
        max_transactions  = 100;
        timeout_cycles    = 1000;
        enable_coverage   = 1;
        test_name         = "default_test";
    endfunction

    // 全局访问点 —— 唯一能获取实例的方式
    static function GlobalConfig get();
        if (instance == null) begin
            instance = new();      // 只在第一次调用时创建
            $display("    [Config] 首次创建全局配置对象");
        end
        return instance;
    endfunction

    function void display();
        $display("    [Config] test=%0s, max_txn=%0d, timeout=%0d, cov=%0d",
                 test_name, max_transactions, timeout_cycles, enable_coverage);
    endfunction
endclass

// ============================================================
// 3. 模拟一个使用 Config 的组件
// ============================================================
class Driver;
    string name;

    function new(string name = "driver");
        this.name = name;
    endfunction

    task run();
        GlobalConfig cfg = GlobalConfig::get();  // 获取全局配置
        $display("    [%0s] 读取全局配置: max_txn=%0d, timeout=%0d",
                 name, cfg.max_transactions, cfg.timeout_cycles);
    endtask
endclass

class Scoreboard;
    task run();
        GlobalConfig cfg = GlobalConfig::get();  // 获取的是同一个对象
        $display("    [Scoreboard] 读取全局配置: enable_cov=%0d, test=%0s",
                 cfg.enable_coverage, cfg.test_name);
    endtask
endclass

// ============================================================
// 测试验证
// ============================================================
module tb_static_singleton;

    Counter c1, c2, c3;

    initial begin
        $display("========================================");
        $display("  KP09 静态变量与单例模式");
        $display("========================================\n");

        // ================================================
        // 场景1：静态变量 —— 所有对象共享
        // ================================================
        $display("--- 场景1: 静态变量共享 ---");
        $display("  创建3个 Counter 对象，观察 total_count 的变化:");
        c1 = new("counter_A");
        c1.display();

        c2 = new("counter_B");
        c2.display();

        c3 = new("counter_C");
        c3.display();

        $display("  通过类名直接访问静态变量:");
        $display("    Counter::total_count = %0d", Counter::total_count);
        $display("  通过静态方法访问:");
        $display("    Counter::get_total() = %0d", Counter::get_total());
        $display("");

        // ================================================
        // 场景2：普通成员 vs 静态成员
        // ================================================
        $display("--- 场景2: 普通成员各有一份，静态成员共享 ---");
        $display("  c1.my_id = %0d, c2.my_id = %0d, c3.my_id = %0d (各不相同)",
                 c1.my_id, c2.my_id, c3.my_id);
        $display("  Counter::total_count = %0d (三个对象共享同一个值)",
                 Counter::total_count);
        $display("");

        // ================================================
        // 场景3：单例模式 —— 全局只有一个 Config 对象
        // ================================================
        $display("--- 场景3: 单例模式 ---");
        $display("  通过 GlobalConfig::get() 获取配置:");
        begin
            GlobalConfig cfg1 = GlobalConfig::get();  // 第一次调用，创建对象
            cfg1.test_name    = "reg_access_test";
            cfg1.max_transactions = 50;
            cfg1.display();

            GlobalConfig cfg2 = GlobalConfig::get();  // 第二次调用，返回同一个对象
            $display("  cfg2 是不是同一个对象？");
            cfg2.display();   // test_name 已经是 "reg_access_test" → 说明是同一个对象

            $display("  验证: 修改 cfg1.max_transactions = 999");
            cfg1.max_transactions = 999;
            $display("  cfg2.max_transactions = %0d (也变了！因为是同一个对象)", cfg2.max_transactions);
        end
        $display("");

        // ================================================
        // 场景4：不同组件共享同一个 Config
        // ================================================
        $display("--- 场景4: 组件共享全局配置 ---");
        $display("  修改全局配置后，所有组件读到的都是最新值:");
        begin
            GlobalConfig cfg = GlobalConfig::get();
            cfg.test_name   = "full_chip_test";
            cfg.timeout_cycles = 5000;
            $display("  [设置] test=%0s, timeout=%0d", cfg.test_name, cfg.timeout_cycles);

            Driver drv = new("master_drv");
            Scoreboard sb;

            drv.run();              // Driver 读到的配置
            sb.run();               // Scoreboard 读到的配置（同一个对象）
        end
        $display("");

        // ================================================
        // 场景5：构造函数被保护，外部不能 new
        // ================================================
        $display("--- 场景5: 单例的保护机制 ---");
        $display("  GlobalConfig cfg = new();  ← 编译错误！");
        $display("  因为构造函数是 protected 的，外部无法直接 new");
        $display("  只能通过 GlobalConfig::get() 获取唯一实例");

        $display("\n========================================");
        $display("  总结");
        $display("  ├── static 变量  : 所有对象共享，通过 类名:: 访问");
        $display("  ├── static 方法  : 通过 类名:: 调用，不能访问非 static 成员");
        $display("  └── 单例模式      : 全局只有一个实例，protected 构造 + static get()");
        $display("========================================");
    end

endmodule
