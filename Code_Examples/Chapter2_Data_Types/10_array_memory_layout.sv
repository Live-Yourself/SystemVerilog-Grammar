//===========================================
// 知识点: 数组的内存布局
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module array_memory_layout;
    // 二维数组
    int arr[3][4];  // 3行4列
    
    // 内存布局示意:
    // arr[0][0], arr[0][1], arr[0][2], arr[0][3],
    // arr[1][0], arr[1][1], arr[1][2], arr[1][3],
    // arr[2][0], arr[2][1], arr[2][2], arr[2][3]
    
    initial begin
        $display("=== 二维数组内存布局 ===\n");
        
        // 初始化二维数组
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 4; j++) begin
                arr[i][j] = i * 10 + j;
            end
        end
        
        // 打印数组 - 逐行显示
        $display("2D Array Contents:");
        $display("最右边的维度变化最快\n");
        for (int i = 0; i < 3; i++) begin
            $write("Row %0d: ", i);
            for (int j = 0; j < 4; j++) begin
                $write("%2d ", arr[i][j]);
            end
            $write("\n");
        end
        
        // $display格式化打印整个数组
        $display("\n完整数组: %p", arr);
        
        // 内存顺序遍历
        $display("\n内存顺序遍历:");
        foreach (arr[i, j]) begin
            $display("arr[%0d][%0d] = %0d", i, j, arr[i][j]);
        end
    end
endmodule

// 仿真输出:
// Row 0:  0  1  2  3 
// Row 1: 10 11 12 13 
// Row 2: 20 21 22 23
