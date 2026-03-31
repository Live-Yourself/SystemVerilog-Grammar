// KP08 参数化的类（Parameterized Class）
// 演示：type/int 参数定义、不同类型实例化、参数化与继承结合

// ============================================================
// 1. 参数化栈类 —— type 参数控制元素类型，int 参数控制深度
// ============================================================
class Stack #(type T = int, int MAX_DEPTH = 8);
    protected string stack_name;
    protected T items[$];   // 动态队列，元素类型由参数 T 决定

    function new(string name = "stack");
        this.stack_name = name;
    endfunction

    // push：压入元素（类型 T 由参数决定）
    function void push(T val);
        if (items.size() < MAX_DEPTH)
            items.push_back(val);
        else
            $display("    [%0s] 栈已满！最大深度=%0d", stack_name, MAX_DEPTH);
    endfunction

    // pop：弹出元素
    function T pop();
        if (items.size() > 0) begin
            T val = items[$];    // 取最后一个元素（类型 T）
            items.pop_back();
            return val;
        end else begin
            $display("    [%0s] 栈为空！", stack_name);
            T default_val;
            return default_val;
        end
    endfunction

    // size：返回当前元素个数
    function int size();
        return items.size();
    endfunction

    // display：打印栈内容
    function void display();
        $display("    [%0s] 深度限制=%0d, 当前元素=%0d", stack_name, MAX_DEPTH, items.size());
    endfunction
endclass

// ============================================================
// 2. 参数化事务类 —— 不同位宽的地址和数据
// ============================================================
class GenericTxn #(type ADDR_T = bit[31:0], type DATA_T = bit[31:0]);
    ADDR_T addr;
    DATA_T data;
    string name;

    function new(string name = "txn");
        this.name = name;
        this.addr = 0;
        this.data = 0;
    endfunction

    function void display();
        $display("    [%0s] addr=%0h, data=%0h", name, addr, data);
    endfunction
endclass

// ============================================================
// 3. 继承参数化类 —— 固定参数的子类
// ============================================================
// 固定 T=string 的字符串栈
class StringStack extends Stack #(string);
    function new(string name = "str_stack");
        super.new(name);
    endfunction

    // 可以添加子类特有的方法
    function void push_upper(string s);
        s.toupper();          // SystemVerilog 字符串方法
        this.push(s);
    endfunction
endclass

// ============================================================
// 测试验证
// ============================================================
module tb_parameterized;

    initial begin
        $display("========================================");
        $display("  KP08 参数化的类");
        $display("========================================\n");

        // ================================================
        // 场景1：用不同类型实例化同一个参数化栈类
        // ================================================
        $display("--- 场景1: 不同类型的栈 ---");
        begin
            // int 栈：T=int, MAX_DEPTH=默认8
            Stack #(int) int_stack;
            // string 栈：T=string, MAX_DEPTH=默认8
            Stack #(string) str_stack;
            // bit[7:0] 栈：T=bit[7:0], MAX_DEPTH=4（自定义深度）
            Stack #(bit[7:0], 4) byte_stack;

            int_stack = new("int_stack");
            str_stack = new("str_stack");
            byte_stack = new("byte_stack");

            // --- int 栈操作 ---
            int_stack.push(100);
            int_stack.push(200);
            int_stack.push(300);
            $display("  int 栈压入 100, 200, 300:");
            int_stack.display();

            // --- string 栈操作 ---
            str_stack.push("hello");
            str_stack.push("world");
            $display("  string 栈压入 hello, world:");
            str_stack.display();

            // --- byte 栈操作（深度限制为4） ---
            byte_stack.push(8'hAA);
            byte_stack.push(8'hBB);
            byte_stack.push(8'hCC);
            $display("  byte 栈压入 AA, BB, CC (深度限制=4):");
            byte_stack.display();
        end
        $display("");

        // ================================================
        // 场景2：弹出元素，验证类型安全
        // ================================================
        $display("--- 场景2: 弹出元素 ---");
        begin
            Stack #(int) stk = new("test");
            int val;

            stk.push(10);
            stk.push(20);
            val = stk.pop();   // pop() 返回 int 类型
            $display("  pop() 返回值: %0d (类型自动匹配为 int)", val);
            val = stk.pop();
            $display("  再次 pop(): %0d", val);
        end
        $display("");

        // ================================================
        // 场景3：参数化事务类 —— 不同位宽
        // ================================================
        $display("--- 场景3: 参数化事务类（不同位宽） ---");
        begin
            // 32位地址 + 32位数据（默认）
            GenericTxn #() txn32;
            // 16位地址 + 8位数据
            GenericTxn #(bit[15:0], bit[7:0]) txn_small;
            // 64位地址 + 128位数据（大位宽）
            GenericTxn #(bit[63:0], bit[127:0]) txn_big;

            txn32 = new("txn_32");
            txn32.addr = 32'hFFFF0000;
            txn32.data = 32'h12345678;
            $display("  32位事务:");
            txn32.display();

            txn_small = new("txn_small");
            txn_small.addr = 16'hABCD;
            txn_small.data = 8'hFF;
            $display("  16位地址+8位数据事务:");
            txn_small.display();

            txn_big = new("txn_big");
            txn_big.addr = 64'hDEAD_BEEF_CAFE_BABE;
            txn_big.data = 128'h1;
            $display("  64位地址+128位数据事务:");
            txn_big.display();
        end
        $display("");

        // ================================================
        // 场景4：继承参数化类 —— 固定参数的子类
        // ================================================
        $display("--- 场景4: 继承参数化类 ---");
        begin
            // StringStack 继承 Stack #(string)，T 已经固定为 string
            StringStack ss;
            string s;

            ss = new("my_str_stack");
            ss.push("first");
            ss.push("second");
            $display("  StringStack (继承自 Stack#(string)):");
            ss.display();

            s = ss.pop();
            $display("  pop() 返回: \"%0s\" (类型自动为 string)", s);
        end

        $display("\n========================================");
        $display("  总结");
        $display("  ├── #(type T)       : 用类型做参数，一个类适配多种类型");
        $display("  ├── #(int N=8)      : 用值做参数，控制位宽/深度等");
        $display("  ├── 实例化时指定参数 : Stack#(string, 4) s;");
        $display("  └── 继承时可以固定参数 : class A extends B#(int);");
        $display("========================================");
    end

endmodule
