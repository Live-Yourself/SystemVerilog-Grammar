//=============================================================================
// 文件名: 02_03_fork_join_none.sv
// 模块: 模块2 - fork...join_none
// 知识点: 2.3 非阻塞并行
//=============================================================================

program fork_join_none_example;
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  bit background_done;
  bit clk;
  bit [7:0] monitored_data;
  int sample_count;
  
  //===========================================================================
  // 示例1: 基本fork...join_none
  //===========================================================================
  initial begin : basic_fork_join_none
    $display("\n===========================================================");
    $display("     示例1: 基本fork...join_none");
    $display("===========================================================");
    
    $display("\n[%0t] 启动后台任务，主线程立即继续", $time);
    
    // 启动后台任务
    fork
      // 后台任务1: 耗时20ns
      begin : bg_task1
        $display("[%0t] 后台任务1开始", $time);
        #20;
        $display("[%0t] 后台任务1完成", $time);
      end
      
      // 后台任务2: 耗时30ns
      begin : bg_task2
        $display("[%0t] 后台任务2开始", $time);
        #30;
        $display("[%0t] 后台任务2完成", $time);
      end
    join_none
    
    // join_none立即返回，不等待任何任务
    $display("[%0t] fork...join_none立即返回，主线程继续执行！", $time);
    $display("  说明: 所有任务都在后台运行，主线程不等待");
    
    // 主线程继续工作
    for (int i = 0; i < 3; i++) begin
      #8;
      $display("[%0t] 主线程工作中...", $time);
    end
    
    $display("[%0t] 主线程结束", $time);
  end
  
  //===========================================================================
  // 示例2: 时钟生成器
  //===========================================================================
  initial begin : clock_generator
    $display("\n===========================================================");
    $display("     示例2: 时钟生成器");
    $display("===========================================================");
    
    $display("\n[%0t] 启动独立时钟发生器", $time);
    
    // 启动时钟生成器（后台运行）
    fork
      forever begin
        #5 clk = ~clk;  // 时钟周期10ns
      end
    join_none
    
    $display("[%0t] 时钟发生器已启动，主线程继续", $time);
    
    // 观察时钟信号
    for (int i = 0; i < 5; i++) begin
      @(posedge clk);
      $display("[%0t] 检测到clk上升沿，clk=%b", $time, clk);
    end
    
    $display("[%0t] 主线程使用时钟完成", $time);
    $display("  说明: join_none启动后台时钟，主线程同步使用");
  end
  
  //===========================================================================
  // 示例3: 后台监控进程
  //===========================================================================
  initial begin : background_monitor
    $display("\n===========================================================");
    $display("     示例3: 后台监控进程");
    $display("===========================================================");
    
    sample_count = 0;
    monitored_data = 0;
    
    $display("\n[%0t] 启动后台监控（每5ns采样一次）", $time);
    
    // 启动后台监控
    fork
      begin : monitor_process
        forever begin
          #5;
          sample_count++;
          $display("[%0t] 后台监控采样%0d: data=0x%02h", 
                   $time, sample_count, monitored_data);
        end
      end
    join_none
    
    $display("[%0t] 后台监控已启动，主线程继续", $time);
    
    // 主线程改变数据，观察监控效果
    for (int i = 0; i < 3; i++) begin
      #8;
      monitored_data = 8'hA0 + i;
      $display("[%0t] 主线程: monitored_data = 0x%02h", 
               $time, monitored_data);
    end
    
    #15;  // 等待更多采样
    $display("[%0t] 主线程结束", $time);
    $display("  说明: 后台监控持续运行，与主线程并发执行");
  end
  
  //===========================================================================
  // 示例4: 多个后台监控进程
  //===========================================================================
  initial begin : multiple_monitors
    bit [7:0] data_bus, addr_bus;
    bit valid_sig;
    
    $display("\n===========================================================");
    $display("     示例4: 多个后台监控进程");
    $display("===========================================================");
    
    $display("\n[%0t] 启动多个后台监控进程", $time);
    
    fork
      // 监控1: 监控数据总线
      begin : data_monitor
        forever begin
          #4;
          $display("[%0t] [数据监控] data_bus=0x%02h", $time, data_bus);
        end
      end
      
      // 监控2: 监控地址总线
      begin : addr_monitor
        forever begin
          #6;
          $display("[%0t] [地址监控] addr_bus=0x%02h", $time, addr_bus);
        end
      end
      
      // 监控3: 监控控制信号
      begin : control_monitor
        forever begin
          #5;
          $display("[%0t] [控制监控] valid=%b", $time, valid_sig);
        end
      end
    join_none
    
    $display("[%0t] 所有监控器已启动", $time);
    
    // 主线程改变信号，观察监控效果
    #2;
    data_bus = 8'h55;
    #3;
    addr_bus = 8'hAA;
    valid_sig = 1;
    #4;
    data_bus = 8'h66;
    #5;
    addr_bus = 8'hBB;
    valid_sig = 0;
    #10;
    
    $display("[%0t] 主线程结束", $time);
    $display("  说明: 多个监控器并行运行，互不干扰");
  end
  
  //===========================================================================
  // 示例5: 后台初始化任务
  //===========================================================================
  initial begin : background_initialization
    bit init_complete;
    int init_progress;
    
    $display("\n===========================================================");
    $display("     示例5: 后台初始化任务");
    $display("===========================================================");
    
    init_complete = 0;
    init_progress = 0;
    
    $display("\n[%0t] 启动后台初始化任务", $time);
    
    // 启动后台初始化
    fork
      begin : init_process
        $display("[%0t] 后台初始化开始...", $time);
        for (int i = 0; i < 5; i++) begin
          #7;
          init_progress = (i + 1) * 20;
          $display("[%0t] 初始化进度: %0d%%", $time, init_progress);
        end
        init_complete = 1;
        $display("[%0t] ✓ 后台初始化完成", $time);
      end
    join_none
    
    $display("[%0t] 后台初始化已启动，主线程继续执行其他任务", $time);
    
    // 主线程执行其他工作，不等待初始化
    for (int i = 0; i < 3; i++) begin
      #10;
      $display("[%0t] 主线程执行其他工作...", $time);
    end
    
    // 检查初始化是否完成
    if (init_complete)
      $display("[%0t] 初始化已完成，可以使用资源", $time);
    else
      $display("[%0t] 初始化未完成，需要等待", $time);
    
    $display("  说明: 后台初始化与主线程并行执行");
  end
  
  //===========================================================================
  // 示例6: 异步日志记录
  //===========================================================================
  initial begin : async_logging
    mailbox #(string) log_mb;
    string log_msg;
    
    $display("\n===========================================================");
    $display("     示例6: 异步日志记录");
    $display("===========================================================");
    
    log_mb = new();  // 创建信箱
    
    $display("\n[%0t] 启动后台日志记录进程", $time);
    
    // 启动后台日志写入进程
    fork
      begin : logger_process
        string msg;
        forever begin
          log_mb.get(msg);  // 等待日志消息
          // 模拟写入文件（这里用display代替）
          $display("[%0t] [日志] %s", $time, msg);
        end
      end
    join_none
    
    $display("[%0t] 日志记录器已启动", $time);
    
    // 主线程发送日志消息（不等待写入完成）
    #2;
    log_mb.put("测试开始");
    #3;
    log_mb.put("发送数据: 0x55");
    #4;
    log_mb.put("接收响应: 0xAA");
    #5;
    log_mb.put("测试完成");
    
    #10;  // 等待日志写入
    
    $display("[%0t] 主线程结束", $time);
    $display("  说明: 主线程发送日志后立即继续，不等待I/O");
  end
  
  //===========================================================================
  // 示例7: 后台数据收集
  //===========================================================================
  initial begin : background_data_collection
    mailbox #(int) data_mb;
    int collected_data [];
    
    $display("\n===========================================================");
    $display("     示例7: 后台数据收集");
    $display("===========================================================");
    
    data_mb = new();  // 创建信箱
    collected_data = new[10];  // 分配数组
    
    $display("\n[%0t] 启动后台数据收集进程", $time);
    
    // 启动后台收集
    fork
      begin : collector_process
        for (int i = 0; i < 10; i++) begin
          #6;
          int data = $urandom_range(0, 255);
          data_mb.put(data);  // 收集数据
          $display("[%0t] 收集数据[%0d]: %0d", $time, i, data);
        end
      end
    join_none
    
    $display("[%0t] 数据收集器已启动", $time);
    
    // 主线程继续执行其他工作
    #20;
    $display("[%0t] 主线程: 执行其他任务...", $time);
    
    // 稍后读取收集的数据
    #50;
    $display("[%0t] 主线程: 读取收集的数据...", $time);
    for (int i = 0; i < 10; i++) begin
      int data;
      data_mb.get(data);
      collected_data[i] = data;
    end
    
    $display("[%0t] 数据读取完成，共%0d个样本", $time, collected_data.size());
    $display("  说明: 后台收集数据，主线程后续处理");
  end
  
  //===========================================================================
  // 示例8: 管理后台进程
  //===========================================================================
  initial begin : manage_background
    bit terminate_flag;
    
    $display("\n===========================================================");
    $display("     示例8: 管理后台进程");
    $display("===========================================================");
    
    terminate_flag = 0;
    
    $display("\n[%0t] 启动可控制的后台进程", $time);
    
    fork
      begin : bg_worker
        int count = 0;
        while (!terminate_flag) begin
          #8;
          count++;
          $display("[%0t] 后台工作%0d次", $time, count);
        end
        $display("[%0t] 后台进程正常退出", $time);
      end
    join_none
    
    $display("[%0t] 后台进程已启动", $time);
    
    // 主线程工作一段时间
    #20;
    $display("[%0t] 主线程: 工作20ns...", $time);
    
    // 发出终止信号
    #5;
    $display("[%0t] 主线程: 发出终止信号", $time);
    terminate_flag = 1;
    
    // 等待后台进程退出
    #10;
    $display("[%0t] 主线程: 后台进程已终止", $time);
    
    $display("  说明: 通过标志位控制后台进程退出");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #100;  // 等待前面的示例完成
    
    $display("\n===========================================================");
    $display("                    fork...join_none 总结");
    $display("===========================================================");
    $display("1. fork...join_none: 立即返回，不等待任何线程");
    $display("2. 所有线程都在后台运行");
    $display("3. 适用场景:");
    $display("   - 时钟生成");
    $display("   - 后台监控");
    $display("   - 异步日志");
    $display("   - 后台初始化");
    $display("   - 数据收集");
    $display("4. 通过标志位或disable fork管理后台进程");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// fork...join_none示例演示:
// 1. 基本用法: 立即返回，不等待任何任务
//    - 后台任务1: 20ns, 后台任务2: 30ns
//    - 主线程立即继续执行
//    - 主线程与后台任务并发运行
//
// 2. 时钟生成器: 独立时钟信号产生
// 3. 后台监控: 持续采样，不影响主线程
// 4. 多监控器: 多个监控任务并行运行
// 5. 后台初始化: 初始化与主线程并行
// 6. 异步日志: 日志I/O不阻塞主线程
// 7. 数据收集: 后台收集，主线程后续处理
// 8. 进程管理: 通过标志位控制后台进程退出
//=============================================================================
