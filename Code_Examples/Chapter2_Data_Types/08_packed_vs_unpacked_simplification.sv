//===========================================
// 知识点: 压缩数组vs非压缩数组 - 简化语法对比
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module packed_vs_unpacked_simplification;
    // ============ 压缩数组 ============
    // 必须明确指定范围,不支持简写!
    logic [7:0]   byte_data;     // ✅ 正确: 8位向量,降序索引
    logic [0:7]   byte_data_up;  // ✅ 正确: 8位向量,升序索引
    // logic [8]    byte_bad;     // ❌ 错误! 不支持这种简写
    
    // ============ 非压缩数组 ============
    // 支持简写形式
    logic unpacked1[16];      // ✅ 正确: 16个元素,索引0-15
    logic unpacked2[0:15];    // ✅ 正确: 同上(完整形式)
    logic unpacked3[15:0];    // ✅ 正确: 16个元素,索引15-0(降序)
    
    // ============ 混合数组 ============
    logic [7:0]  mixed1[16];      // ✅ 正确: 16个8位向量
    logic [7:0]  mixed2[0:15];    // ✅ 正确: 同上
    logic [0:7]  mixed3[15:0];    // ✅ 正确: 16个8位向量(升序位+降序索引)
    // logic [8]   mixed4[16];     // ❌ 错误! 压缩维度不支持简写
    
    initial begin
        $display("=== 压缩数组 vs 非压缩数组 - 语法对比 ===\n");
        
        // 压缩数组 - 降序索引(推荐,硬件常用)
        $display("【压缩数组】必须指定范围 [msb:lsb]:");
        byte_data = 8'b1000_0000;
        $display("  logic [7:0] byte_data;");
        $display("  byte_data[7] = %b (最高位,MSB)", byte_data[7]);
        $display("  byte_data[0] = %b (最低位,LSB)", byte_data[0]);
        
        // 压缩数组 - 升序索引
        byte_data_up = 8'b1000_0000;
        $display("\n  logic [0:7] byte_data_up;");
        $display("  byte_data_up[0] = %b (最高位,MSB)", byte_data_up[0]);
        $display("  byte_data_up[7] = %b (最低位,LSB)", byte_data_up[7]);
        
        $display("\n【非压缩数组】支持简写 [N]:");
        // 升序索引(简写)
        unpacked1[0]  = 1;
        unpacked1[15] = 0;
        $display("  logic unpacked1[16];      // 索引范围 0-15");
        $display("  等价于: logic unpacked2[0:15];");
        
        // 降序索引
        unpacked3[15] = 1;  // 第一个元素
        unpacked3[0]  = 0;  // 最后一个元素
        $display("\n  logic unpacked3[15:0];    // 索引范围 15-0");
        $display("  unpacked3[15] 是第一个元素");
        
        $display("\n【混合数组】结合两者特点:");
        mixed1[0]  = 8'hAA;
        mixed1[15] = 8'hFF;
        $display("  logic [7:0] mixed1[16];   // 16个8位向量");
        $display("  mixed1[0]  = 0x%h", mixed1[0]);
        $display("  mixed1[15] = 0x%h", mixed1[15]);
        
        $display("\n=== 语法总结 ===");
        $display("压缩数组:   [size] 不支持, 必须用 [msb:lsb]");
        $display("非压缩数组: [size] 支持, 等价于 [0:size-1]");
        $display("推荐习惯:   压缩用降序[7:0], 非压缩用升序[16]");
    end
endmodule
