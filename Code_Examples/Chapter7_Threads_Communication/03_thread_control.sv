//=============================================================================
// 文件名: 03_thread_control.sv
// 模块: 模块3 - 线程的控制
// 知识点: wait fork / disable fork / disable 命名块
//=============================================================================

program thread_control_example;
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  bit task_done [3];
  bit timeout_occurred;
  bit operation_complete;
  
  //===========================================================================
  // 示例1: wait fork - 等待所有后台线程完成
  //===========================================================================
  initial begin : wait_fork_demo
    $display("\n========== 示例1: wait fork ==========");
    
    task_done[0] = 0; task_done[1] = 0; task_done[2] = 0;
    
    fork
      begin #10; task_done[0] = 1; $display("任务A完成"); end
      begin #5;  task_done[1] = 1; $display("任务B完成（最先）"); end
      begin #15; task_done[2] = 1; $display("任务C完成"); end
    join_any
    
    $display("join_any返回，继续执行...");
    #3; $display("执行其他操作...");
    
    $display("调用wait fork...");
    wait fork;
    $display("wait fork返回，所有任务完成");
  end
  
  //===========================================================================
  // 示例2: wait fork在多阶段任务中的应用
  //===========================================================================
  initial begin : multi_stage_demo
    $display("\n========== 示例2: 多阶段任务 ==========");
    
    // 阶段1
    $display("阶段1: 并行配置...");
    fork
      begin #8;  $display("模块A配置完成"); end
      begin #6;  $display("模块B配置完成"); end
      begin #10; $display("模块C配置完成"); end
    join_any
    $display("第一个模块配置完成");
    
    wait fork;
    $display("阶段1全部完成，进入阶段2...");
    
    // 阶段2
    fork
      begin #5; $display("模块A启动完成"); end
      begin #7; $display("模块B启动完成"); end
      begin #4; $display("模块C启动完成"); end
    join
    $display("阶段2全部完成");
  end
  
  //===========================================================================
  // 示例3: disable fork - 终止所有后台线程
  //===========================================================================
  initial begin : disable_fork_demo
    $display("\n========== 示例3: disable fork ==========");
    
    operation_complete = 0;
    timeout_occurred = 0;
    
    fork
      begin #60; operation_complete = 1; $display("工作任务完成"); end
      begin #50; timeout_occurred = 1; $display("超时！"); end
    join_any
    
    if (timeout_occurred) begin
      $display("检测到超时，终止工作任务...");
      disable fork;
      $display("disable fork执行，所有后台线程已终止");
    end
  end
  
  //===========================================================================
  // 示例4: disable fork清理后台监控
  //===========================================================================
  initial begin : cleanup_demo
    $display("\n========== 示例4: 清理后台监控 ==========");
    
    fork
      begin : bg_monitor
        forever begin
          #10; $display("后台监控运行中...");
        end
      end
    join_none
    
    $display("后台监控已启动");
    #25; $display("主线程工作25ns");
    
    $display("禁用后台监控...");
    disable fork;
    $display("后台监控已停止");
  end
  
  //===========================================================================
  // 示例5: disable 命名块 - 终止特定线程
  //===========================================================================
  initial begin : disable_named_demo
    $display("\n========== 示例5: disable 命名块 ==========");
    
    fork
      begin : data_monitor
        forever begin
          #7; $display("数据监控运行中...");
        end
      end
      
      begin : timeout_monitor
        #50; $display("超时监控触发！");
      end
    join_none
    
    $display("两个监控器已启动");
    #20; $display("20ns后");
    
    $display("禁用数据监控（保留超时监控）...");
    disable data_monitor;
    $display("数据监控已停止，超时监控继续运行");
    
    #40; $display("40ns后，主线程结束");
  end
  
  //===========================================================================
  // 示例6: disable 命名块精确控制
  //===========================================================================
  initial begin : precise_control_demo
    bit fast_done, slow_done;
    
    $display("\n========== 示例6: 精确控制 ==========");
    
    fork
      begin : fast_task
        #5; fast_done = 1; $display("快速任务完成");
      end
      
      begin : slow_task
        #30; slow_done = 1; $display("慢速任务完成");
      end
    join_any
    
    if (fast_done) begin
      $display("使用快速任务结果，终止慢速任务...");
      disable slow_task;
    end
    
    #10; $display("主线程继续");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #100;
    
    $display("\n===========================================================");
    $display("                    线程控制总结");
    $display("===========================================================");
    $display("1. wait fork: 等待所有fork线程完成（被动等待）");
    $display("2. disable fork: 终止所有fork线程（主动清理）");
    $display("3. disable 命名块: 终止特定线程（精确控制）");
    $display("4. 最佳实践: 始终管理后台线程，使用命名块");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// 1. wait fork: join_any后等待所有后台线程完成
// 2. 多阶段任务: 阶段1和阶段2的同步控制
// 3. disable fork: 超时后终止所有后台线程
// 4. 清理监控: 停止后台监控进程
// 5. disable命名块: 精确终止特定线程
// 6. 精确控制: 选择性终止，保留需要的线程
//=============================================================================
