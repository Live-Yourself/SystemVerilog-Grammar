//===========================================
// 知识点: 四值类型与双状态类型比较
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module type_comparison;
    logic [3:0] four_val;  // 四值类型
    bit   [3:0] two_val;   // 双状态类型
    int counter;
    initial begin
        $display("=== 四值类型 vs 双状态类型 ===\n");
        
        // 四值类型可以赋值X和Z
        four_val = 4'bX0XZ;
        $display("四值类型:");
        $display("  four_val = 4'bX0XZ");
        $display("  结果: %b", four_val);
        
        // 双状态类型不能保持X和Z
        two_val = 4'bX0XZ;  // X和Z转换为0
        $display("\n双状态类型:");
        $display("  two_val = 4'bX0XZ");
        $display("  结果: %b (X/Z转换为0)", two_val);
        
        // 在验证中的典型应用
        $display("\n=== 验证中的应用示例 ===");

        counter = 100;
        $display("计数器(counter) = %0d", counter);
        
        // 性能对比
        $display("\n=== 使用建议 ===");
        $display("1. 硬件建模: 使用 logic (四值类型)");
        $display("2. 验证环境: 使用 int/bit (双状态类型)");
        $display("3. 性能优势: 双状态类型仿真更快");
    end
endmodule
