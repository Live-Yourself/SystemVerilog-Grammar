//===========================================
// 知识点: 数组操作方法
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module array_operations;
    int arr[8] = '{10, 20, 30, 40, 50, 60, 70, 80};
    
    // 数组复制用的临时数组
    int arr_copy[8];             // 用于演示数组复制
    
    // 数组比较用的数组
    int arr2[8];                 // 用于演示数组比较
    
    // 数组统计变量
    int sum_val;                 // 数组求和结果
    int product;                 // 数组求积结果
    int max_val[$];              // 数组最大值(返回队列类型)
    int min_val[$];              // 数组最小值(返回队列类型)
    
    // 排序用的数组
    int unsorted[5];             // 未排序的原始数组
    int sorted[5];               // 排序后的数组
    
    // 反转用的数组
    int reversed[5];             // 反转后的数组
    
    initial begin
        $display("=== 数组操作方法 ===\n");
        
        // 初始化比较数组
        arr2 = '{10, 20, 30, 40, 50, 60, 70, 80};
        
        // 初始化排序数组
        unsorted = '{30, 10, 50, 20, 40};
        
        // 1. 数组长度
        $display("1. 数组长度");
        $display("   arr.size() = %0d", arr.size());
        
        // 2. 遍历数组 - foreach循环
        $display("\n2. foreach循环遍历:");
        foreach (arr[i]) begin
            $display("   arr[%0d] = %0d", i, arr[i]);
        end
        
        // 3. 数组复制
        $display("\n3. 数组复制:");
        arr_copy = arr;  // 直接赋值
        $display("   arr_copy = %p", arr_copy);
        
        // 4. 数组比较
        $display("\n4. 数组比较:");
        if (arr == arr2) begin
            $display("   arr == arr2: 相等");
        end
        
        // 5. 数组求和、积、最大最小值
        $display("\n5. 数组统计:");
        sum_val = arr.sum();      // 求和
        product = arr.product();  // 求积
        max_val = arr.max();      // 最大值(返回队列)
        min_val = arr.min();      // 最小值(返回队列)
        
        $display("   sum()    = %0d", sum_val);
        $display("   product()= %0d", product);
        $display("   max()    = %p", max_val);
        $display("   min()    = %p", min_val);
        
        // 6. 数组排序
        $display("\n6. 数组排序:");
        sorted = unsorted;
        sorted.sort();      // 升序排序
        $display("   原数组:    %p", unsorted);
        $display("   sort():   %p (升序)", sorted);
        
        sorted.rsort();     // 降序排序
        $display("   rsort():  %p (降序)", sorted);
        
        // 7. 数组反转
        $display("\n7. 数组反转:");
        reversed = unsorted;
        reversed.reverse();
        $display("   原数组:      %p", unsorted);
        $display("   reverse():  %p", reversed);
    end
endmodule
