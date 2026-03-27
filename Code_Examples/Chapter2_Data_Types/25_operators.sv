// 知识点19: 操作符 (Operators)
// 演示各类操作符: 算术、逻辑、关系、位操作、移位、条件操作符

module operators;

  // ========== 用于演示的变量 ==========
  int   a, b;                 // 操作数
  int   result;               // 结果
  logic [7:0] data_a;         // 8位数据
  logic [7:0] data_b;         // 8位数据
  logic [15:0] shift_data;    // 移位数据
  logic       flag;           // 标志位
  int         cond_val;       // 条件值
  
  initial begin
    $display("========================================");
    $display("    操作符 (Operators) 示例");
    $display("========================================\n");
    
    // ============================================================
    // 一、算术操作符
    // ============================================================
    $display("【一、算术操作符】\n");
    
    a = 10;
    b = 3;
    
    $display("  a = %0d, b = %0d", a, b);
    $display("");
    $display("  加法:  a + b  = %0d", a + b);     // 13
    $display("  减法:  a - b  = %0d", a - b);     // 7
    $display("  乘法:  a * b  = %0d", a * b);     // 30
    $display("  除法:  a / b  = %0d", a / b);     // 3 (整数除法)
    $display("  取模:  a %% b  = %0d", a % b);     // 1
    $display("  幂运算: a ** b = %0d", a ** b);   // 1000 (10^3)
    $display("");
    
    // 注意整数除法
    $display("  整数除法示例:");
    a = 7;
    b = 2;
    $display("    7 / 2 = %0d (小数部分被截断)", a / b);
    $display("");
    
    // ============================================================
    // 二、关系操作符
    // ============================================================
    $display("【二、关系操作符】\n");
    
    a = 5;
    b = 10;
    
    $display("  a = %0d, b = %0d", a, b);
    $display("");
    $display("  大于:    a > b  = %b", a > b);     // 0
    $display("  小于:    a < b  = %b", a < b);     // 1
    $display("  大于等于: a >= b = %b", a >= b);   // 0
    $display("  小于等于: a <= b = %b", a <= b);   // 1
    $display("");
    
    // ============================================================
    // 三、相等操作符
    // ============================================================
    $display("【三、相等操作符】\n");
    
    a = 5;
    b = 5;
    
    $display("  a = %0d, b = %0d", a, b);
    $display("");
    $display("  相等:     a == b  = %b", a == b);   // 1
    $display("  不等:     a != b  = %b", a != b);   // 0
    
    // 四值逻辑的比较
    data_a = 8'hX0;
    data_b = 8'hX0;
    $display("");
    $display("  四值逻辑比较 (data_a=8'hX0, data_b=8'hX0):");
    $display("    逻辑相等:   data_a == data_b  = %b", data_a == data_b);   // X
    $display("    case相等:   data_a === data_b = %b", data_a === data_b); // 1
    $display("    case不等:   data_a !== data_b = %b", data_a !== data_b); // 0
    $display("");
    $display("  说明:");
    $display("    ==  : 包含X/Z时结果可能为X");
    $display("    === : 逐位精确比较(包括X/Z)");
    $display("    !== : case不等于");
    $display("");
    
    // ============================================================
    // 四、逻辑操作符
    // ============================================================
    $display("【四、逻辑操作符】\n");
    
    a = 5;
    b = 0;
    
    $display("  a = %0d (真), b = %0d (假)", a, b);
    $display("");
    $display("  逻辑与: a && b = %b", a && b);     // 0
    $display("  逻辑或: a || b = %b", a || b);     // 1
    $display("  逻辑非: !b    = %b", !b);         // 1
    $display("");
    $display("  短路求值:");
    $display("    (b != 0) && (a/b > 0) → 不会执行 a/b");
    $display("    (a > 0) || (b++ > 0) → b++ 可能不执行");
    $display("");
    
    // ============================================================
    // 五、按位操作符
    // ============================================================
    $display("【五、按位操作符】\n");
    
    data_a = 8'b1010_1010;
    data_b = 8'b1100_1100;
    
    $display("  data_a = 8'b%b", data_a);
    $display("  data_b = 8'b%b", data_b);
    $display("");
    $display("  按位与: data_a & data_b = %b", data_a & data_b);   // 10001000
    $display("  按位或: data_a | data_b = %b", data_a | data_b);   // 11101110
    $display("  按位异或: data_a ^ data_b = %b", data_a ^ data_b); // 01100110
    $display("  按位同或: data_a ~^ data_b = %b", data_a ~^ data_b); // 10011001
    $display("  按位非: ~data_a = %b", ~data_a);                     // 01010101
    $display("");
    
    // ============================================================
    // 六、归约操作符
    // ============================================================
    $display("【六、归约操作符 (单目操作)】\n");
    
    data_a = 8'b1010_0001;
    
    $display("  data_a = 8'b%b", data_a);
    $display("");
    $display("  归约与: &data_a  = %b (所有位相与)", &data_a);     // 0
    $display("  归约或: |data_a  = %b (所有位相或)", |data_a);     // 1
    $display("  归约异或: ^data_a = %b (所有位异或，奇偶校验)", ^data_a); // 1
    $display("  归约与非: ~&data_a = %b", ~&data_a);               // 1
    $display("  归约或非: ~|data_a = %b", ~|data_a);               // 0
    $display("  归约同或: ~^data_a = %b", ~^data_a);               // 0
    $display("");
    $display("  典型应用:");
    $display("    检测全0: |data_a == 0");
    $display("    检测全1: &data_a == 1");
    $display("    奇偶校验: ^data_a");
    $display("");
    
    // ============================================================
    // 七、移位操作符
    // ============================================================
    $display("【七、移位操作符】\n");
    
    shift_data = 16'h00FF;
    
    $display("  shift_data = 16'h%h = %b", shift_data, shift_data);
    $display("");
    
    // 逻辑移位
    $display("  【逻辑移位 - 空位补0】");
    $display("    左移:  shift_data << 4  = 16'h%h = %b", shift_data << 4, shift_data << 4);
    $display("    右移:  shift_data >> 4  = 16'h%h = %b", shift_data >> 4, shift_data >> 4);
    $display("");
    
    // 算术移位
    shift_data = 16'hF000;  // 负数
    $display("  【算术移位 - 保持符号位】");
    $display("    shift_data = 16'h%h = %b", shift_data, shift_data);
    $display("    逻辑右移: shift_data >> 4  = 16'h%h = %b", shift_data >> 4, shift_data >> 4);
    $display("    算术右移: shift_data >>> 4 = 16'h%h = %b", shift_data >>> 4, shift_data >>> 4);
    $display("    (算术右移保持符号位，补1而非0)");
    $display("");
    
    // ============================================================
    // 八、条件操作符
    // ============================================================
    $display("【八、条件操作符 (三元运算符)】\n");
    
    a = 10;
    b = 20;
    
    $display("  a = %0d, b = %0d", a, b);
    $display("");
    $display("  语法: condition ? true_expr : false_expr");
    $display("");
    $display("  取较大值: (a > b) ? a : b = %0d", (a > b) ? a : b);
    $display("  取较小值: (a < b) ? a : b = %0d", (a < b) ? a : b);
    $display("");
    
    // 嵌套条件操作符
    cond_val = 85;
    $display("  嵌套条件 - 成绩等级判断:");
    $display("    score = %0d", cond_val);
    $display("    grade = (score>=90) ? \"A\" : (score>=80) ? \"B\" : (score>=60) ? \"C\" : \"D\"");
    $display("    结果: %s", (cond_val>=90) ? "A" : (cond_val>=80) ? "B" : (cond_val>=60) ? "C" : "D");
    $display("");
    
    // ============================================================
    // 九、拼接操作符
    // ============================================================
    $display("【九、拼接操作符】\n");
    
    logic [3:0] nibble1 = 4'hA;
    logic [3:0] nibble2 = 4'hB;
    logic [7:0] byte_val;
    
    $display("  nibble1 = 4'h%h, nibble2 = 4'h%h", nibble1, nibble2);
    $display("");
    $display("  拼接: {nibble1, nibble2} = 8'h%h", {nibble1, nibble2});
    $display("  复制: {2{nibble1}} = 8'h%h", {2{nibble1}});
    $display("  混合: {nibble1, 4'h0, nibble2} = 12'h%h", {nibble1, 4'h0, nibble2});
    $display("");
    
    // ============================================================
    // 十、赋值操作符
    // ============================================================
    $display("【十、赋值操作符】\n");
    
    a = 10;
    $display("  a = %0d", a);
    $display("");
    $display("  复合赋值操作符:");
    a += 5;   $display("    a += 5   → a = %0d", a);   // 15
    a -= 3;   $display("    a -= 3   → a = %0d", a);   // 12
    a *= 2;   $display("    a *= 2   → a = %0d", a);   // 24
    a /= 4;   $display("    a /= 4   → a = %0d", a);   // 6
    a %= 4;   $display("    a %%= 4   → a = %0d", a);   // 2
    a <<= 2;  $display("    a <<= 2  → a = %0d", a);   // 8
    a >>= 1;  $display("    a >>= 1  → a = %0d", a);   // 4
    a &= 8'h0F; $display("    a &= 8'h0F → a = %0d", a); // 4
    a |= 8'hF0; $display("    a |= 8'hF0 → a = %0d", a); // 244
    a ^= 8'hFF; $display("    a ^= 8'hFF → a = %0d", a); // 11
    $display("");
    
    // ============================================================
    // 十一、操作符优先级
    // ============================================================
    $display("【十一、操作符优先级 (从高到低)】\n");
    
    $display("  ┌────────────────────────────────────────────┐");
    $display("  │ 优先级 │ 操作符                            │");
    $display("  ├────────────────────────────────────────────┤");
    $display("  │  最高  │ () [] :: .                        │");
    $display("  │        │ + - ! ~ & | ^ ~& ~| ~^ (单目)      │");
    $display("  │        │ **                                │");
    $display("  │        │ * / %%                             │");
    $display("  │        │ + - (双目)                         │");
    $display("  │        │ << >> <<< >>>                     │");
    $display("  │        │ < <= > >=                         │");
    $display("  │        │ == != === !==                     │");
    $display("  │        │ & (双目)                           │");
    $display("  │        │ ^ ~^ (双目)                        │");
    $display("  │        │ | (双目)                           │");
    $display("  │        │ &&                                │");
    $display("  │        │ ||                                │");
    $display("  │  最低  │ ?: (条件)                          │");
    $display("  └────────────────────────────────────────────┘");
    $display("");
    $display("  建议: 复杂表达式使用括号明确优先级");
    $display("");
    
    // ============================================================
    // 十二、操作符汇总表
    // ============================================================
    $display("【十二、操作符汇总表】\n");
    $display("  ┌──────────────┬─────────────────────────────────┐");
    $display("  │ 类型         │ 操作符                          │");
    $display("  ├──────────────┼─────────────────────────────────┤");
    $display("  │ 算术         │ + - * / %% **                    │");
    $display("  │ 关系         │ > < >= <=                       │");
    $display("  │ 相等         │ == != === !==                   │");
    $display("  │ 逻辑         │ && || !                         │");
    $display("  │ 按位(双目)   │ & | ^ ~^                        │");
    $display("  │ 按位(单目)   │ ~                               │");
    $display("  │ 归约(单目)   │ & | ^ ~& ~| ~^                  │");
    $display("  │ 移位         │ << >> <<< >>>                   │");
    $display("  │ 条件         │ ?:                              │");
    $display("  │ 拼接         │ {} {{}}                         │");
    $display("  │ 赋值         │ = += -= *= /= %%= <<= >>= &= |= ^= │");
    $display("  └──────────────┴─────────────────────────────────┘");
    
    $display("\n========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
