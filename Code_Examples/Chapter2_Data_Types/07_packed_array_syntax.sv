//===========================================
// 知识点: 压缩数组语法详解
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module packed_array_syntax;
    // ❌ 错误写法 - 编译错误!
    // logic [7] wrong;        // Error: 必须指定范围
    
    // ✅ 正确写法 - 必须指定上下界
    logic [7:0]  correct1;      // 8位向量,位索引7到0(降序)
    logic [0:7]  correct2;      // 8位向量,位索引0到7(升序)
    
    // 对比说明
    logic [7:0]  data_down;     // 降序: data_down[7]是最高位(MSB)
    logic [0:7]  data_up;       // 升序: data_up[7]是最低位(LSB)
    
    initial begin
        $display("=== 压缩数组索引方向 ===\n");
        
        // 降序索引(推荐,符合硬件习惯)
        data_down = 8'b1000_0000;  // bit[7]=1, 其他为0
        $display("降序索引 [7:0]:");
        $display("  data_down      = %b", data_down);
        $display("  data_down[7]   = %b (最高位,MSB)", data_down[7]);
        $display("  data_down[0]   = %b (最低位,LSB)", data_down[0]);
        
        // 升序索引(较少用)
        data_up = 8'b1000_0000;    // bit[0]=1, 其他为0
        $display("\n升序索引 [0:7]:");
        $display("  data_up        = %b", data_up);
        $display("  data_up[0]     = %b (最高位,MSB)", data_up[0]);
        $display("  data_up[7]     = %b (最低位,LSB)", data_up[7]);
        
        $display("\n=== 关键区别 ===");
        $display("压缩数组: 必须指定范围 [msb:lsb], 不支持简写 [N]");
        $display("非压缩数组: 支持简写 [N], 等价于 [0:N-1]");
    end
endmodule
