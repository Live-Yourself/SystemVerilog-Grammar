// KP07 回调机制（Callback Mechanism）
// 演示：回调基类定义、Monitor 回调触发、多注册者解耦

// ============================================================
// 1. 简单事务类
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

    function void display();
        $display("    [%0s] addr=0x%0h, data=0x%0h", name, addr, data);
    endfunction
endclass

// ============================================================
// 2. 回调抽象基类 —— 定义回调接口
// ============================================================
virtual class Callback;
    protected string cb_name;

    function new(string name = "cb");
        this.cb_name = name;
    endfunction

    // 事务前回调
    pure virtual function void pre_trans(Transaction txn);

    // 事务后回调
    pure virtual function void post_trans(Transaction txn);
endclass

// ============================================================
// 3. Monitor —— 回调的调用者
// ============================================================
class Monitor;
    string name;
    Callback cbs[$];   // 动态队列，存放所有注册的回调对象

    function new(string name = "monitor");
        this.name = name;
    endfunction

    // 注册回调
    function void register_cb(Callback cb);
        cbs.push_back(cb);
        $display("  [Monitor:%0s] 注册回调: %0s (当前共%0d个)",
                 this.name, cb.cb_name, cbs.size());
    endfunction

    // 删除回调
    function void unregister_cb(Callback cb);
        foreach (cbs[i])
            if (cbs[i] == cb) begin
                cbs.delete(i);
                $display("  [Monitor:%0s] 移除回调: %0s", this.name, cb.cb_name);
                return;
            end
    endfunction

    // Monitor 主任务：模拟接收事务
    task run(Transaction txn);
        int i;

        $display("  [Monitor:%0s] 收到事务:", this.name);

        // ---- 事务前：触发 pre_trans 回调 ----
        foreach (cbs[i])
            cbs[i].pre_trans(txn);

        // ---- 模拟事务处理 ----
        $display("  [Monitor:%0s] 正在处理事务...", this.name);
        txn.display();

        // ---- 事务后：触发 post_trans 回调 ----
        foreach (cbs[i])
            cbs[i].post_trans(txn);

        $display("  [Monitor:%0s] 事务处理完成\n", this.name);
    endtask
endclass

// ============================================================
// 4. 注册者1：Scoreboard —— 事务后比对
// ============================================================
class ScoreboardCB extends Callback;
    function new(string name = "scoreboard");
        super.new(name);
    endfunction

    // Scoreboard 不关心 pre_trans，给个空实现
    function void pre_trans(Transaction txn);
        // 不做事
    endfunction

    // post_trans 时记录收到的事务
    function void post_trans(Transaction txn);
        $display("    [Scoreboard] 记录事务用于后续比对:");
        txn.display();
    endfunction
endclass

// ============================================================
// 5. 注册者2：Coverage —— 事务前后都关注
// ============================================================
class CoverageCB extends Callback;
    function new(string name = "coverage");
        super.new(name);
    endfunction

    // pre_trans 时记录事务开始
    function void pre_trans(Transaction txn);
        $display("    [Coverage] 采样前: addr=0x%0h", txn.addr);
    endfunction

    // post_trans 时记录事务完成
    function void post_trans(Transaction txn);
        $display("    [Coverage] 采样后: addr=0x%0h, data=0x%0h", txn.addr, txn.data);
    endfunction
endclass

// ============================================================
// 6. 注册者3：Logger —— 事务后打印日志
// ============================================================
class LoggerCB extends Callback;
    function new(string name = "logger");
        super.new(name);
    endfunction

    function void pre_trans(Transaction txn);
        // 不做事
    endfunction

    function void post_trans(Transaction txn);
        $display("    [Logger] LOG: txn=%0s addr=0x%0h data=0x%0h",
                 txn.name, txn.addr, txn.data);
    endfunction
endclass

// ============================================================
// 测试验证
// ============================================================
module tb_callback;

    Monitor     mon;
    ScoreboardCB sb;
    CoverageCB  cov;
    LoggerCB    log;

    initial begin
        $display("========================================");
        $display("  KP07 回调机制");
        $display("========================================\n");

        // 创建组件
        mon = new("bus_monitor");
        sb  = new("my_scoreboard");
        cov = new("my_coverage");
        log = new("my_logger");

        // ================================================
        // 场景1：注册多个回调
        // ================================================
        $display("--- 场景1: 注册多个回调 ---");
        mon.register_cb(sb);    // 注册 Scoreboard
        mon.register_cb(cov);   // 注册 Coverage
        mon.register_cb(log);   // 注册 Logger
        $display("");

        // ================================================
        // 场景2：Monitor 运行，自动触发所有回调
        // ================================================
        $display("--- 场景2: Monitor 运行事务 ---");
        begin
            Transaction txn = new("write_001");
            txn.addr = 32'h1000;
            txn.data = 32'hABCD;
            mon.run(txn);    // Monitor 内部会自动调用 sb/cov/log 的回调
        end

        // ================================================
        // 场景3：Monitor 不知道注册者是谁 —— 解耦
        // ================================================
        $display("--- 场景3: 回调解耦效果 ---");
        $display("  Monitor 代码中没有引用 Scoreboard、Coverage、Logger");
        $display("  它只是按顺序调用 cbs[i].pre_trans() 和 cbs[i].post_trans()");
        $display("  将来新增一个 Checker，只需:");
        $display("    1. 新建 class CheckerCB extends Callback");
        $display("    2. mon.register_cb(new CheckerCB)");
        $display("  Monitor 代码一行不改！\n");

        // ================================================
        // 场景4：移除回调
        // ================================================
        $display("--- 场景4: 移除 Coverage 回调 ---");
        mon.unregister_cb(cov);
        begin
            Transaction txn = new("read_002");
            txn.addr = 32'h2000;
            txn.data = 32'h5678;
            $display("  移除 Coverage 后，只有 Scoreboard 和 Logger 的回调被触发:");
            mon.run(txn);
        end

        $display("========================================");
        $display("  总结");
        $display("  ├── Monitor 不需要知道注册者是谁 → 解耦");
        $display("  ├── 注册/移除回调可以动态增减功能");
        $display("  └── 新增 Listener 不需要修改 Monitor 代码");
        $display("========================================");
    end

endmodule
