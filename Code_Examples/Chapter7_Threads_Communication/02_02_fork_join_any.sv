//=============================================================================
// 文件名: 02_02_fork_join_any.sv
// 模块: 模块2 - fork...join_any
// 知识点: 2.2 任意一个线程完成即继续
//=============================================================================

program fork_join_any_example;
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  bit task_done [3];
  bit timeout_occurred;
  bit operation_complete;
  bit resource_a_ready, resource_b_ready;
  bit [7:0] data_a, data_b;
  
  //===========================================================================
  // 示例1: 基本fork...join_any
  //===========================================================================
  initial begin : basic_fork_join_any
    $display("\n===========================================================");
    $display("     示例1: 基本fork...join_any");
    $display("===========================================================");
    
    $display("\n[%0t] 启动三个并行任务", $time);
    
    // 清零任务完成标志
    task_done[0] = 0; task_done[1] = 0; task_done[2] = 0;
    
    fork
      // 任务0: 耗时10ns
      begin
        $display("[%0t] 任务0开始", $time);
        #10;
        task_done[0] = 1;
        $display("[%0t] 任务0完成", $time);
      end
      
      // 任务1: 耗时5ns（最先完成）
      begin
        $display("[%0t] 任务1开始", $time);
        #5;
        task_done[1] = 1;
        $display("[%0t] 任务1完成（最先！）", $time);
      end
      
      // 任务2: 耗时15ns
      begin
        $display("[%0t] 任务2开始", $time);
        #15;
        task_done[2] = 1;
        $display("[%0t] 任务2完成", $time);
      end
    join_any
    
    // join_any在任务1完成时（5ns）立即解除阻塞
    $display("\n[%0t] join_any解除阻塞，主线程继续！", $time);
    $display("  当前任务状态:");
    $display("    任务0: %s", task_done[0] ? "完成" : "后台运行中");
    $display("    任务1: %s", task_done[1] ? "完成" : "后台运行中");
    $display("    任务2: %s", task_done[2] ? "完成" : "后台运行中");
    $display("  说明: 任务1最先完成(5ns)，join_any立即返回");
    $display("  ⚠ 警告: 任务0和任务2仍在后台运行！");
    
    // 等待足够时间观察后台进程
    #20;
    $display("\n[%0t] 20ns后，所有任务状态:");
    $display("    任务0: %s", task_done[0] ? "完成" : "未完成");
    $display("    任务1: %s", task_done[1] ? "完成" : "未完成");
    $display("    任务2: %s", task_done[2] ? "完成" : "未完成");
  end
  
  //===========================================================================
  // 示例2: join_any后的后台进程管理 - wait fork
  //===========================================================================
  initial begin : wait_for_background
    $display("\n===========================================================");
    $display("     示例2: 后台进程管理 - wait fork");
    $display("===========================================================");
    
    $display("\n[%0t] 启动并行任务，使用join_any快速响应", $time);
    
    task_done[0] = 0; task_done[1] = 0; task_done[2] = 0;
    
    fork
      begin #5;  task_done[0] = 1; $display("[%0t] 任务0完成", $time); end
      begin #15; task_done[1] = 1; $display("[%0t] 任务1完成", $time); end
      begin #25; task_done[2] = 1; $display("[%0t] 任务2完成", $time); end
    join_any
    
    $display("[%0t] 第一个任务完成！此时状态:", $time);
    for (int i = 0; i < 3; i++)
      $display("  任务%0d: %s", i, task_done[i] ? "完成" : "运行中");
    
    $display("\n[%0t] 使用wait fork等待所有后台任务完成...", $time);
    wait fork;
    
    $display("[%0t] wait fork返回，所有任务已完成", $time);
    $display("  说明: wait fork会等待所有fork线程完成");
  end
  
  //===========================================================================
  // 示例3: join_any后的后台进程管理 - disable fork
  //===========================================================================
  initial begin : disable_background
    $display("\n===========================================================");
    $display("     示例3: 后台进程管理 - disable fork");
    $display("===========================================================");
    
    $display("\n[%0t] 启动并行任务，使用join_any快速响应", $time);
    
    task_done[0] = 0; task_done[1] = 0; task_done[2] = 0;
    
    fork
      begin #5;  task_done[0] = 1; $display("[%0t] 任务0完成", $time); end
      begin #15; task_done[1] = 1; $display("[%0t] 任务1完成", $time); end
      begin #25; task_done[2] = 1; $display("[%0t] 任务2完成", $time); end
    join_any
    
    $display("[%0t] 第一个任务完成！此时状态:", $time);
    for (int i = 0; i < 3; i++)
      $display("  任务%0d: %s", i, task_done[i] ? "完成" : "运行中");
    
    $display("\n[%0t] 使用disable fork终止所有后台任务...", $time);
    disable fork;
    
    #1;  // 等待1ns观察
    $display("[%0t] disable fork执行后，所有后台任务被终止", $time);
    $display("  说明: disable fork会立即终止所有fork线程");
  end
  
  //===========================================================================
  // 示例4: 超时检测模式
  //===========================================================================
  initial begin : timeout_detection
    int operation_delay;
    
    $display("\n===========================================================");
    $display("     示例4: 超时检测模式");
    $display("===========================================================");
    
    // 随机生成操作延迟（可能超过50ns）
    operation_delay = $urandom_range(30, 80);
    operation_complete = 0;
    timeout_occurred = 0;
    
    $display("[%0t] 启动操作（预期延迟%0dns）", $time, operation_delay);
    $display("[%0t] 超时阈值: 50ns", $time);
    
    fork
      // 工作任务
      begin : work_task
        $display("[%0t] 工作任务开始...", $time);
        #operation_delay;
        operation_complete = 1;
        $display("[%0t] ✓ 工作任务完成", $time);
      end
      
      // 超时检测任务（50ns）
      begin : timeout_task
        #50;
        if (!operation_complete) begin
          timeout_occurred = 1;
          $display("[%0t] ⚠ 超时！操作未在50ns内完成", $time);
        end
      end
    join_any
    
    // 检查结果
    if (operation_complete)
      $display("[%0t] 测试通过: 操作成功（耗时%0dns < 50ns）", 
               $time, operation_delay);
    else if (timeout_occurred)
      $display("[%0t] 测试失败: 操作超时", $time);
    
    $display("  说明: join_any实现超时检测，任一完成即继续");
    
    // 清理后台线程
    disable fork;
  end
  
  //===========================================================================
  // 示例5: 多资源竞争模式
  //===========================================================================
  initial begin : resource_competition
    $display("\n===========================================================");
    $display("     示例5: 多资源竞争模式");
    $display("===========================================================");
    
    $display("\n[%0t] 同时请求资源A和资源B，任一就绪即使用", $time);
    
    resource_a_ready = 0;
    resource_b_ready = 0;
    
    fork
      // 请求资源A
      begin : request_A
        int delay = $urandom_range(10, 30);
        $display("[%0t] 请求资源A（预计%0dns）", $time, delay);
        #delay;
        resource_a_ready = 1;
        data_a = 8'hAA;
        $display("[%0t] ✓ 资源A就绪，data=0x%02h", $time, data_a);
      end
      
      // 请求资源B
      begin : request_B
        int delay = $urandom_range(10, 30);
        $display("[%0t] 请求资源B（预计%0dns）", $time, delay);
        #delay;
        resource_b_ready = 1;
        data_b = 8'hBB;
        $display("[%0t] ✓ 资源B就绪，data=0x%02h", $time, data_b);
      end
    join_any
    
    // 使用第一个就绪的资源
    if (resource_a_ready) begin
      $display("[%0t] 使用资源A的数据: 0x%02h", $time, data_a);
    end
    else if (resource_b_ready) begin
      $display("[%0t] 使用资源B的数据: 0x%02h", $time, data_b);
    end
    
    $display("  说明: 任一资源就绪即继续，不必等待所有资源");
    
    // 清理后台线程
    disable fork;
  end
  
  //===========================================================================
  // 示例6: 快速响应模式（多算法竞争）
  //===========================================================================
  initial begin : quick_response
    bit algorithm_a_done, algorithm_b_done;
    int result_a, result_b;
    
    $display("\n===========================================================");
    $display("     示例6: 快速响应模式（多算法竞争）");
    $display("===========================================================");
    
    $display("\n[%0t] 算法A和算法B同时计算，取最快结果", $time);
    
    algorithm_a_done = 0;
    algorithm_b_done = 0;
    
    fork
      // 算法A
      begin : algorithm_A
        $display("[%0t] 算法A开始计算（预计12ns）", $time);
        #12;
        result_a = 42;
        algorithm_a_done = 1;
        $display("[%0t] 算法A完成，结果=%0d", $time, result_a);
      end
      
      // 算法B
      begin : algorithm_B
        $display("[%0t] 算法B开始计算（预计8ns）", $time);
        #8;
        result_b = 43;
        algorithm_b_done = 1;
        $display("[%0t] 算法B完成，结果=%0d", $time, result_b);
      end
    join_any
    
    // 使用最先完成的算法结果
    if (algorithm_a_done && algorithm_b_done) begin
      $display("[%0t] 两个算法同时完成，使用算法B的结果: %0d", $time, result_b);
    end
    else if (algorithm_a_done) begin
      $display("[%0t] 算法A最快完成，结果: %0d", $time, result_a);
    end
    else if (algorithm_b_done) begin
      $display("[%0t] 算法B最快完成，结果: %0d", $time, result_b);
    end
    
    $display("  说明: 多算法并行，使用最快结果");
    
    // 清理后台线程
    disable fork;
  end
  
  //===========================================================================
  // 示例7: join_any与fork...join的时间对比
  //===========================================================================
  initial begin : timing_comparison
    int join_time, any_time;
    
    $display("\n===========================================================");
    $display("     示例7: join_any vs fork...join 时间对比");
    $display("===========================================================");
    
    // fork...join
    $display("\n[%0t] === fork...join ===", $time);
    join_time = $time;
    fork
      #10;
      #5;
      #15;
    join
    join_time = $time - join_time;
    $display("[%0t] fork...join完成，耗时: %0dns", $time, join_time);
    
    #2;
    
    // fork...join_any
    $display("\n[%0t] === fork...join_any ===", $time);
    any_time = $time;
    fork
      #10;
      #5;
      #15;
    join_any
    any_time = $time - any_time;
    $display("[%0t] fork...join_any完成，耗时: %0dns", $time, any_time);
    $display("  效率提升: %0d%%", ((join_time - any_time) * 100) / join_time);
    
    disable fork;  // 清理后台
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #100;  // 等待前面的示例完成
    
    $display("\n===========================================================");
    $display("                    fork...join_any 总结");
    $display("===========================================================");
    $display("1. fork...join_any: 任一线程完成即继续");
    $display("2. 未完成线程在后台继续运行");
    $display("3. 适用场景:");
    $display("   - 超时检测");
    $display("   - 多路等待");
    $display("   - 资源竞争");
    $display("   - 快速响应");
    $display("4. 后台管理: wait fork / disable fork");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// fork...join_any示例演示:
// 1. 基本用法: 任一线程完成即继续
//    - 三个任务: 10ns, 5ns, 15ns
//    - 任务1在5ns最先完成，join_any立即返回
//    - 其他任务继续在后台运行
//
// 2. 后台管理: wait fork等待所有完成
// 3. 后台管理: disable fork终止所有线程
// 4. 超时检测: 工作任务 + 超时检测并行
// 5. 资源竞争: 多个资源请求，使用第一个就绪的
// 6. 快速响应: 多算法并行，取最快结果
// 7. 时间对比: join_any比fork...join更快响应
//=============================================================================
