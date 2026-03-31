// KP05 深拷贝与浅拷贝（Deep Copy vs Shallow Copy）
// 演示：浅拷贝的陷阱、深拷贝的正确做法、对象成员的递归拷贝

// ============================================================
// 基础类 Transaction —— 字段都是基本类型
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

    // 深拷贝方法：创建新对象，逐字段赋值
    function Transaction copy();
        Transaction c = new(this.name);
        c.addr = this.addr;
        c.data = this.data;
        return c;
    endfunction

    function void display();
        $display("  [%0s] addr=0x%0h, data=0x%0h", name, addr, data);
    endfunction
endclass

// ============================================================
// 复合类 Packet —— 内部包含一个 Transaction 对象
// ============================================================
class Packet;
    string name;
    Transaction header;    // 成员是另一个对象（不是基本类型！）

    function new(string name = "pkt");
        this.name = name;
        this.header = new("header");   // 创建内部对象
    endfunction

    // 错误的拷贝：浅拷贝内部对象
    function Packet shallow_copy();
        Packet c = new(this.name);
        c.header = this.header;    // ← 只是复制了句柄，两个 Packet 共享同一个 header！
        return c;
    endfunction

    // 正确的拷贝：深拷贝内部对象
    function Packet deep_copy();
        Packet c = new(this.name);
        c.header = this.header.copy();   // ← 递归调用 copy()，创建新的 header 对象
        return c;
    endfunction

    function void display();
        $display("  [%0s] header.addr=0x%0h, header.data=0x%0h",
                 name, header.addr, header.data);
    endfunction
endclass

// ============================================================
// 测试验证
// ============================================================
module tb_copy;

    initial begin
        $display("========================================");
        $display("  KP05 深拷贝 vs 浅拷贝");
        $display("========================================\n");

        // ================================================
        // 场景1：浅拷贝 —— 只复制句柄
        // ================================================
        $display("--- 场景1: 浅拷贝（两个遥控器，一台电视） ---");
        begin
            Transaction t1, t2;
            t1 = new("t1");
            t1.addr = 32'h100;
            t1.data = 32'hAAAA;
            $display("  设置 t1: addr=0x%0h, data=0x%0h", t1.addr, t1.data);

            t2 = t1;                    // 浅拷贝：t2 和 t1 指向同一个对象
            $display("  t2 = t1;  (浅拷贝，t2 和 t1 指向同一个对象)");

            t2.addr = 32'h200;          // 修改 t2
            $display("  修改 t2.addr = 0x200 后:");
            $display("    t1.addr = 0x%0h  ← 被影响了！", t1.addr);
            $display("    t2.addr = 0x%0h", t2.addr);
        end
        $display("  结论：浅拷贝只是多了一个遥控器，改任何一个都影响同一个对象\n");

        // ================================================
        // 场景2：深拷贝 —— 复制对象本身
        // ================================================
        $display("--- 场景2: 深拷贝（两台独立的电视） ---");
        begin
            Transaction t1, t2;
            t1 = new("t1");
            t1.addr = 32'h100;
            t1.data = 32'hAAAA;
            $display("  设置 t1: addr=0x%0h, data=0x%0h", t1.addr, t1.data);

            t2 = t1.copy();             // 深拷贝：创建了新对象
            $display("  t2 = t1.copy();  (深拷贝，内存中有两个独立对象)");

            t2.addr = 32'h200;          // 修改 t2
            $display("  修改 t2.addr = 0x200 后:");
            $display("    t1.addr = 0x%0h  ← 没有被影响", t1.addr);
            $display("    t2.addr = 0x%0h", t2.addr);
        end
        $display("  结论：深拷贝创建了一个全新对象，修改互不影响\n");

        // ================================================
        // 场景3：对象成员的浅拷贝陷阱
        // ================================================
        $display("--- 场景3: 对象成员的浅拷贝陷阱 ---");
        begin
            Packet p1, p2;
            p1 = new("p1");
            p1.header.addr = 32'h500;
            p1.header.data = 32'h1111;
            $display("  设置 p1: header.addr=0x%0h, header.data=0x%0h",
                     p1.header.addr, p1.header.data);

            p2 = p1.shallow_copy();     // 浅拷贝 Packet
            $display("  p2 = p1.shallow_copy();  (浅拷贝)");

            p2.header.addr = 32'h600;   // 修改 p2 的 header
            $display("  修改 p2.header.addr = 0x600 后:");
            $display("    p1.header.addr = 0x%0h  ← 被影响了！", p1.header.addr);
            $display("    p2.header.addr = 0x%0h", p2.header.addr);
            $display("  原因：p1.header 和 p2.header 指向同一个 Transaction 对象");
        end
        $display("  结论：浅拷贝只复制了 header 的句柄，两个 Packet 共享同一个 header\n");

        // ================================================
        // 场景4：对象成员的深拷贝
        // ================================================
        $display("--- 场景4: 对象成员的深拷贝（正确做法） ---");
        begin
            Packet p1, p2;
            p1 = new("p1");
            p1.header.addr = 32'h500;
            p1.header.data = 32'h1111;
            $display("  设置 p1: header.addr=0x%0h, header.data=0x%0h",
                     p1.header.addr, p1.header.data);

            p2 = p1.deep_copy();        // 深拷贝 Packet
            $display("  p2 = p1.deep_copy();  (深拷贝)");

            p2.header.addr = 32'h600;   // 修改 p2 的 header
            $display("  修改 p2.header.addr = 0x600 后:");
            $display("    p1.header.addr = 0x%0h  ← 没有被影响", p1.header.addr);
            $display("    p2.header.addr = 0x%0h", p2.header.addr);
            $display("  原因：deep_copy 内部调用了 header.copy()，创建了新的 header 对象");
        end
        $display("  结论：深拷贝时，对象成员也必须递归深拷贝\n");

        // ================================================
        // 场景5：验证平台中的典型用法
        // ================================================
        $display("--- 场景5: Scoreboard 中的典型用法 ---");
        begin
            Transaction sent_txn, rcvd_txn, saved_txn;

            // 发送端产生事务
            sent_txn = new("sent");
            sent_txn.addr = 32'hA0;
            sent_txn.data = 32'hBEEF;

            // Scoreboard 深拷贝保存（不用浅拷贝！）
            saved_txn = sent_txn.copy();
            $display("  发送事务: addr=0x%0h, data=0x%0h (已深拷贝保存)", saved_txn.addr, saved_txn.data);

            // 发送端后续修改了事务（如果用浅拷贝，saved 也会被改）
            sent_txn.data = 32'hDEAD;
            $display("  发送端后续修改 data=0x%0h", sent_txn.data);
            $display("  Scoreboard 保存的副本: data=0x%0h  ← 没有被影响", saved_txn.data);

            // 接收端收到事务，用深拷贝保存
            rcvd_txn = new("rcvd");
            rcvd_txn.addr = 32'hA0;
            rcvd_txn.data = 32'hBEEF;
            $display("  接收事务: addr=0x%0h, data=0x%0h", rcvd_txn.addr, rcvd_txn.data);
            $display("  对比结果: %0s",
                     (saved_txn.addr == rcvd_txn.addr && saved_txn.data == rcvd_txn.data)
                     ? "PASS" : "FAIL");
        end

        $display("\n========================================");
        $display("  总结");
        $display("  ├── 浅拷贝: 复制句柄 → 两个变量指向同一个对象");
        $display("  ├── 深拷贝: 复制对象 → 两个独立对象互不影响");
        $display("  └── 对象成员也必须递归深拷贝，否则仍是浅拷贝");
        $display("========================================");
    end

endmodule
