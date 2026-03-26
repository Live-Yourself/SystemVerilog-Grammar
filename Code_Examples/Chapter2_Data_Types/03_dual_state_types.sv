//===========================================
// 知识点: 双状态数据类型
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module dual_state_types;
    // 双状态类型声明
    bit          single_bit;      // 1位,无符号
    byte         signed_byte;     // 8位,有符号
    shortint     short_int;       // 16位,有符号
    int          integer_32;      // 32位,有符号
    longint      long_integer;    // 64位,有符号
    
    // 双状态数组
    bit [7:0]    byte_array;      // 8位无符号向量
    int   [15:0] int_array [4];   // 4个32位整数的数组
    
    // 用于X/Z转换测试的四值和双状态变量
    logic [7:0]  four_state;      // 四值类型变量,用于对比测试
    bit  [7:0]   two_state;       // 双状态类型变量,用于对比测试
    
    initial begin
        // 双状态类型初始化默认为0
        $display("=== 双状态类型初始化 ===");
        $display("single_bit = %b (默认值)", single_bit);
        
        // 赋值
        single_bit  = 1;
        signed_byte = -128;  // byte范围: -128 ~ 127
        short_int   = 32767;
        integer_32  = 32'hDEADBEEF;
        long_integer = 64'h123456789ABCDEF0;
        
        $display("\n=== 赋值后 ===");
        $display("signed_byte = %d", signed_byte);
        $display("short_int   = %d", short_int);
        $display("integer_32  = 0x%h", integer_32);
        $display("long_integer= 0x%h", long_integer);
        
        // 注意:双状态类型遇到X或Z会转换为0
        $display("\n=== X/Z转换测试 ===");
        four_state = 8'bXXXX_XXXX;
        
        $display("four_state = %b", four_state);
        two_state = four_state;  // X转换为0
        $display("two_state  = %b (X转换为0)", two_state);
        
        // 字节数组赋值
        byte_array = 8'hAA;
        $display("\nbyte_array = 0x%h", byte_array);
        
        // 整型数组赋值
        foreach (int_array[i]) begin
            int_array[i] = i * 100;
        end
        $display("int_array = %p", int_array);
    end
endmodule
