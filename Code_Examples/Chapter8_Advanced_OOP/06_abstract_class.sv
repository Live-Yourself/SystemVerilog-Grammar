// KP06 抽象类与纯虚方法（Abstract Class & Pure Virtual Method）
// 演示：virtual class 定义、pure virtual 强制实现、多态调用

// ============================================================
// 抽象基类 Driver —— 定义驱动器"必须做什么"
// ============================================================
virtual class Driver;
    protected string name; //表示这个 name 成员只有本类和子类能访问，外部（模块和其他类）看不到

    function new(string name = "driver");
        this.name = name;
    endfunction

    // 纯虚方法：只定义接口，不提供实现
    // 所有子类必须实现这三个方法
    pure virtual function void drive(int addr, int data);
    pure virtual function void reset();
    pure virtual function string get_protocol();
endclass

// ============================================================
// 具体子类 ApbDriver —— 实现 APB 协议驱动器
// ============================================================
class ApbDriver extends Driver;
    function new(string name = "apb_drv");
        super.new(name);
    endfunction

    // 实现纯虚方法
    function void drive(int addr, int data);
        $display("  [%0s] APB drive: PSEL=1, PADDR=0x%0h, PWDATA=0x%0h", name, addr, data);
    endfunction

    function void reset();
        $display("  [%0s] APB reset: PRESETn=0", name);
    endfunction

    function string get_protocol();
        return "APB";
    endfunction
endclass

// ============================================================
// 具体子类 AxiDriver —— 实现 AXI 协议驱动器
// ============================================================
class AxiDriver extends Driver;
    function new(string name = "axi_drv");
        super.new(name);
    endfunction

    // 实现纯虚方法（不同的协议细节）
    function void drive(int addr, int data);
        $display("  [%0s] AXI drive: AWADDR=0x%0h, WDATA=0x%0h, AWVALID=1", name, addr, data);
    endfunction

    function void reset();
        $display("  [%0s] AXI reset: ARESETn=0", name);
    endfunction

    function string get_protocol();
        return "AXI";
    endfunction
endclass

// ============================================================
// 不完整的子类 IncompleteDriver —— 故意不实现所有纯虚方法
// （被注释掉，因为会导致编译错误）
// ============================================================
// class IncompleteDriver extends Driver;
//     function void drive(int addr, int data);
//         $display("incomplete drive");
//     endfunction
//     // 忘记实现 reset() 和 get_protocol() → 子类也是抽象的，不能实例化
// endclass

// ============================================================
// 测试验证
// ============================================================
module tb_abstract;

    initial begin
        $display("========================================");
        $display("  KP06 抽象类与纯虚方法");
        $display("========================================\n");

        // ================================================
        // 场景1：抽象类不能直接实例化
        // ================================================
        $display("--- 场景1: 抽象类不能 new ---");
        $display("  Driver d = new(\"test\");  ← 编译错误！");
        $display("  virtual class 不能直接创建对象，只能通过子类实例化\n");

        // ================================================
        // 场景2：子类实现所有纯虚方法后可以实例化
        // ================================================
        $display("--- 场景2: 完整子类可以实例化 ---");
        begin
            ApbDriver apb = new("master_apb");
            AxiDriver axi = new("master_axi");

            $display("  创建 APB 驱动器和 AXI 驱动器:");
            apb.drive(32'h1000, 32'hABCD);
            apb.reset();
            axi.drive(32'h2000, 32'h1234);
            axi.reset();
        end
        $display("");

        // ================================================
        // 场景3：多态 —— 父类句柄统一调用不同子类
        // ================================================
        $display("--- 场景3: 多态调用（核心优势） ---");
        begin
            Driver drivers[2];   // 父类句柄数组
            int i;

            // 父类句柄指向不同子类对象(按赋值顺序)
            drivers[0] = new("apb_port0");   // 实际是 ApbDriver
            drivers[1] = new("axi_port0");   // 实际是 AxiDriver

            // 用统一的接口调用，自动分派到对应子类实现
            $display("  用父类句柄统一调用 drive():");
            for (i = 0; i < 2; i++) begin
                $display("  [%0s] 协议=%0s", drivers[i].name, drivers[i].get_protocol());
                drivers[i].drive(32'h100 + i * 32'h10, 32'hFF00 + i);
                drivers[i].reset();
                $display("");
            end
        end

        // ================================================
        // 场景4：纯虚方法遗漏的后果
        // ================================================
        $display("--- 场景4: 遗漏纯虚方法的后果 ---");
        $display("  如果子类没有实现所有 pure virtual 方法:");
        $display("  ├── 子类自动成为抽象类");
        $display("  ├── 子类也不能用 new() 实例化");
        $display("  └── 编译器会给出警告或错误提示");

        $display("\n========================================");
        $display("  总结");
        $display("  ├── virtual class     : 定义抽象类，不能直接 new");
        $display("  ├── pure virtual      : 定义纯虚方法，子类必须实现");
        $display("  └── 多态价值          : 父类句柄统一接口，子类各自实现");
        $display("========================================");
    end

endmodule
