//===========================================
// 知识点: 定宽数组声明与初始化
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module fixed_array_example;
    // 一维定宽数组
    int    arr1[8];           // 8个int元素,索引0-7
    int    arr2[0:7];         // 同上
    int    arr3[15:8];        // 8个元素,索引15-8(降序)
    
    // 多维定宽数组
    int    matrix[4][8];      // 4行8列的二维数组
    logic  cube[2][4][8];     // 三维数组
    
    // 数组初始化
    int    init_arr[4] = '{0, 1, 2, 3};           // 单引号+花括号
    int    init_arr2[4] = '{4{8}};                // 所有元素初始化为8
    int    init_arr4[4] = '{0, 2{1}, 2};          // {0, 1, 1, 2}
    
    initial begin
        $display("=== 定宽数组示例 ===\n");
        
        // 数组元素访问
        arr1[0] = 10;
        arr1[7] = 20;
        $display("arr1[0]=%0d, arr1[7]=%0d", arr1[0], arr1[7]);
        
        // 多维数组访问
        matrix[0][0] = 100;
        matrix[3][7] = 200;
        
        // 遍历数组
        for (int i = 0; i < 8; i++) begin
            arr1[i] = i * 2;
        end
        
        // 打印数组
        $display("\narr1 = %p", arr1);
        $display("\n初始化数组:");
        $display("init_arr  = %p", init_arr);
        $display("init_arr2 = %p", init_arr2);
        $display("init_arr4 = %p", init_arr4);
        
        // 降序索引数组
        $display("\n降序索引数组arr3[15:8]:");
        for (int i = 15; i >= 8; i--) begin
            arr3[i] = i;
            $display("arr3[%0d] = %0d", i, arr3[i]);
        end
    end
endmodule
