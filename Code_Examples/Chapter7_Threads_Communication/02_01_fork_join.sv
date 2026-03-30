//=============================================================================
// 文件名: 02_01_fork_join.sv
// 模块: 模块2 - fork...join
// 知识点: 2.1 等待所有线程完成
//=============================================================================

program fork_join_example;
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  int result1, result2, result3;
  
  //===========================================================================
  // 示例1: 基本fork...join
  //===========================================================================
  initial begin : basic_fork_join
    $display("\n===========================================================");
    $display("     示例1: 基本fork...join");
    $display("===========================================================");
    
    $display("[%0t] 启动三个并行任务", $time);
    
    // 清零结果
    result1 = 0; result2 = 0; result3 = 0;
    
    fork
      // 任务1: 耗时10ns
      begin
        $display("[%0t] 任务1开始执行", $time);
        #10;
        result1 = 100;
        $display("[%0t] 任务1完成，result1=%0d", $time, result1);
      end
      
      // 任务2: 耗时5ns（最先完成，但join继续等待）
      begin
        $display("[%0t] 任务2开始执行", $time);
        #5;
        result2 = 200;
        $display("[%0t] 任务2完成，result2=%0d", $time, result2);
      end
      
      // 任务3: 耗时15ns（最慢，决定总时间）
      begin
        $display("[%0t] 任务3开始执行", $time);
        #15;
        result3 = 300;
        $display("[%0t] 任务3完成，result3=%0d", $time, result3);
      end
    join
    
    // join会阻塞，直到所有任务完成
    $display("\n[%0t] fork...join结束，所有任务完成", $time);
    $display("  最终结果: result1=%0d, result2=%0d, result3=%0d", 
             result1, result2, result3);
    $display("  总耗时 = max(10, 5, 15) = %0dns", $time);
    $display("  说明: join等待所有线程完成才解除阻塞");
  end
  
  //===========================================================================
  // 示例2: 顺序执行 vs 并行执行的时间对比
  //===========================================================================
  initial begin : timing_comparison
    int seq_time, par_time;
    int time_saved;
    
    $display("\n===========================================================");
    $display("     示例2: 顺序执行 vs 并行执行");
    $display("===========================================================");
    
    // 顺序执行
    $display("\n[%0t] === 顺序执行 ===", $time);
    seq_time = $time;
    #10;  // 任务1
    #5;   // 任务2
    #8;   // 任务3
    seq_time = $time - seq_time;
    $display("[%0t] 顺序执行完成，总时间 = 10 + 5 + 8 = %0dns", 
             $time, seq_time);
    
    #2;  // 间隔
    
    // 并行执行（fork...join）
    $display("\n[%0t] === 并行执行（fork...join） ===", $time);
    par_time = $time;
    fork
      #10;  // 任务1: 10ns
      #5;   // 任务2: 5ns
      #8;   // 任务3: 8ns
    join
    par_time = $time - par_time;
    $display("[%0t] 并行执行完成，总时间 = max(10, 5, 8) = %0dns", 
             $time, par_time);
    
    time_saved = seq_time - par_time;
    $display("\n  节省时间: %0dns", time_saved);
    $display("  效率提升: %0d%%", (time_saved * 100) / seq_time);
  end
  
  //===========================================================================
  // 示例3: 使用命名块
  //===========================================================================
  initial begin : named_blocks
    $display("\n===========================================================");
    $display("     示例3: 使用命名块");
    $display("===========================================================");
    
    $display("\n[%0t] 使用命名块便于调试和控制", $time);
    
    fork
      // 命名块: process_alpha
      begin : process_alpha
        $display("[%0t] process_alpha启动", $time);
        #12;
        $display("[%0t] process_alpha完成", $time);
      end
      
      // 命名块: process_beta
      begin : process_beta
        $display("[%0t] process_beta启动", $time);
        #8;
        $display("[%0t] process_beta完成", $time);
      end
      
      // 命名块: process_gamma
      begin : process_gamma
        $display("[%0t] process_gamma启动", $time);
        #10;
        $display("[%0t] process_gamma完成", $time);
      end
    join
    
    $display("[%0t] 所有命名块完成", $time);
    $display("  说明: 命名块可以通过名字引用，便于disable控制");
  end
  
  //===========================================================================
  // 示例4: 模拟多接口并行驱动
  //===========================================================================
  initial begin : multi_interface_drive
    bit [7:0] data_bus;
    bit valid_sig, ready_sig;
    
    $display("\n===========================================================");
    $display("     示例4: 模拟多接口并行驱动");
    $display("===========================================================");
    
    $display("\n[%0t] DUT有三个接口，需要并行驱动", $time);
    
    fork
      // 接口A驱动
      begin : interface_A
        $display("[%0t] 接口A驱动器启动", $time);
        #2;
        data_bus = 8'hA5;
        valid_sig = 1;
        $display("[%0t] 接口A: data=0x%02h, valid=1", $time, data_bus);
      end
      
      // 接口B驱动
      begin : interface_B
        $display("[%0t] 接口B驱动器启动", $time);
        #3;
        data_bus = 8'h3C;
        ready_sig = 1;
        $display("[%0t] 接口B: data=0x%02h, ready=1", $time, data_bus);
      end
      
      // 接口C驱动
      begin : interface_C
        $display("[%0t] 接口C驱动器启动", $time);
        #5;
        data_bus = 8'hF0;
        valid_sig = 0;
        ready_sig = 0;
        $display("[%0t] 接口C: data=0x%02h, valid=0, ready=0", $time, data_bus);
      end
    join
    
    $display("[%0t] 所有接口并行驱动完成", $time);
    $display("  说明: 三个接口同时开始驱动，模拟真实硬件行为");
  end
  
  //===========================================================================
  // 示例5: 变量在fork外部声明
  //===========================================================================
  initial begin : variable_scope
    int shared_counter;
    int local_a, local_b;
    
    $display("\n===========================================================");
    $display("     示例5: 变量作用域");
    $display("===========================================================");
    
    $display("\n[%0t] 变量在fork外部声明", $time);
    
    shared_counter = 0;
    
    fork
      // 分支1
      begin
        local_a = 10;
        #3;
        shared_counter = shared_counter + local_a;
        $display("[%0t] 分支1: shared_counter = %0d", $time, shared_counter);
      end
      
      // 分支2
      begin
        local_b = 20;
        #6;
        shared_counter = shared_counter + local_b;
        $display("[%0t] 分支2: shared_counter = %0d", $time, shared_counter);
      end
    join
    
    $display("[%0t] 最终 shared_counter = %0d", $time, shared_counter);
    $display("  说明: 变量应在fork外部声明，所有分支可访问");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #80;  // 等待前面的示例完成
    
    $display("\n===========================================================");
    $display("                    fork...join 总结");
    $display("===========================================================");
    $display("1. fork...join创建并行执行的线程");
    $display("2. 所有线程同时开始执行");
    $display("3. join阻塞直到所有线程完成");
    $display("4. 总耗时 = 最长线程的时间");
    $display("5. 变量应在fork外部声明");
    $display("6. 使用命名块便于调试和控制");
    $display("7. 适用场景: 多接口驱动、并行计算、同步点");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// fork...join示例演示:
// 1. 基本用法: 三个任务分别耗时10ns, 5ns, 15ns
//    - 所有任务从0ns同时开始
//    - 任务2在5ns最先完成（但join继续等待）
//    - 任务1在10ns完成（join继续等待）
//    - 任务3在15ns完成（join解除阻塞）
//    - 总耗时 = 15ns
//
// 2. 时间对比: 顺序执行(23ns) vs 并行执行(10ns)
//    - 并行执行节省13ns，效率提升56.5%
//
// 3. 命名块: 便于线程控制
// 4. 多接口驱动: 模拟真实硬件并行行为
// 5. 变量作用域: 外部声明，所有分支共享
//=============================================================================
