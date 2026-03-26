//===========================================
// 知识点: 压缩与非压缩数组
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module packed_vs_unpacked;
    // 压缩数组 - 连续位
    logic [7:0] packed_arr;      // 8位向量
    logic [3:0][7:0] packed_2d;  // 4个8位向量压缩
    
    // 非压缩数组 - 独立元素
    logic unpacked_arr[8];        // 8个独立的1位变量
    logic unpacked_2d[4][8];      // 4x8个独立的1位变量
    
    // 混合数组
    logic [7:0] mixed[4];  // 4个8位压缩向量的非压缩数组
    
    // 用于演示位操作的向量变量
    logic [15:0] vec;       // 16位向量,用于演示位选择和部分选择
    
    initial begin
        $display("=== 压缩数组 vs 非压缩数组 ===\n");
        
        // 压缩数组操作
        $display("1. 压缩数组 (Packed Array):");
        packed_arr = 8'hA5;           // 整体赋值
        packed_arr[3:0] = 4'hF;       // 部分选择
        $display("   packed_arr = 0x%h", packed_arr);
        $display("   可整体访问,可位选择");
        
        // 压缩二维数组
        $display("\n2. 压缩二维数组:");
        packed_2d = 32'hDEAD_BEEF;
        $display("   packed_2d     = 0x%h", packed_2d);
        $display("   packed_2d[0]  = 0x%h (第0个字节)", packed_2d[0]);
        $display("   packed_2d[3]  = 0x%h (第3个字节)", packed_2d[3]);
        
        // 非压缩数组操作
        $display("\n3. 非压缩数组 (Unpacked Array):");
        foreach (unpacked_arr[i]) begin
            unpacked_arr[i] = i[0];  // 只能逐个访问
        end
        $display("   unpacked_arr = %p", unpacked_arr);
        $display("   只能逐元素访问");
        
        // 混合数组
        $display("\n4. 混合数组 (Mixed Array):");
        mixed[0] = 8'h11;
        mixed[1] = 8'h22;
        mixed[2] = 8'h33;
        mixed[3] = 8'h44;
        $display("   mixed = %p", mixed);
        $display("   4个8位压缩向量的非压缩数组");
        
        // 压缩数组位操作
        $display("\n5. 压缩数组位操作:");
        vec = 16'hABCD;
        $display("   vec       = 0x%h", vec);
        $display("   vec[15:8] = 0x%h (高字节)", vec[15:8]);
        $display("   vec[7:0]  = 0x%h (低字节)", vec[7:0]);
        
        // 总结
        $display("\n=== 总结 ===");
        $display("压缩数组:   [size] 在类型前 - 连续存储,可整体访问");
        $display("非压缩数组: [size] 在变量后 - 独立存储,逐元素访问");
        $display("混合数组:   结合两者优点,常用于寄存器堆");
    end
endmodule
