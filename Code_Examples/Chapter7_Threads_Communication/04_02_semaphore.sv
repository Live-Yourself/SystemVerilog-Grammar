//=============================================================================
// 文件名: 04_02_semaphore.sv
// 模块: 模块4.2 - semaphore旗语
// 知识点: semaphore创建、get/put、try_get
//=============================================================================

program semaphore_example;
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  semaphore resource_sem, mutex_sem, rate_limiter_sem;
  int shared_counter;
  
  //===========================================================================
  // 示例1: 基本semaphore - 资源池控制
  //===========================================================================
  initial begin : basic_semaphore_demo
    $display("\n========== 示例1: 资源池控制 ==========");
    
    resource_sem = new(3);  // 3个资源（如DMA通道）
    
    fork
      // 线程1
      begin
        $display("线程1请求资源...");
        resource_sem.get();  // 获取资源
        $display("线程1获得资源，剩余资源: %0d", resource_sem.get_keys());
        #20;  // 使用资源
        resource_sem.put();  // 释放资源
        $display("线程1释放资源，剩余资源: %0d", resource_sem.get_keys());
      end
      
      // 线程2
      begin
        $display("线程2请求资源...");
        resource_sem.get();  // 获取资源
        $display("线程2获得资源，剩余资源: %0d", resource_sem.get_keys());
        #15;  // 使用资源
        resource_sem.put();  // 释放资源
        $display("线程2释放资源，剩余资源: %0d", resource_sem.get_keys());
      end
      
      // 线程3
      begin
        $display("线程3请求资源...");
        resource_sem.get();  // 获取资源
        $display("线程3获得资源，剩余资源: %0d", resource_sem.get_keys());
        #10;  // 使用资源
        resource_sem.put();  // 释放资源
        $display("线程3释放资源，剩余资源: %0d", resource_sem.get_keys());
      end
      
      // 线程4（需要等待）
      begin
        #1;  // 等待一下
        $display("线程4请求资源（等待）...");
        resource_sem.get();  // 等待资源
        $display("线程4获得资源，剩余资源: %0d", resource_sem.get_keys());
        resource_sem.put();  // 释放资源
        $display("线程4释放资源，剩余资源: %0d", resource_sem.get_keys());
      end
    join
  end
  
  //===========================================================================
  // 示例2: 互斥锁（mutex）
  //===========================================================================
  initial begin : mutex_demo
    $display("\n========== 示例2: 互斥锁 ==========");
    
    mutex_sem = new(1);  // 互斥锁，只有1个资源
    shared_counter = 0;
    
    fork
      // 线程1
      begin : thread1
        for (int i = 0; i < 3; i++) begin
          mutex_sem.get();  // 获取锁
          shared_counter++;  // 临界区操作
          $display("线程1: counter=%0d", shared_counter);
          mutex_sem.put();  // 释放锁
          #5;
        end
      end
      
      // 线程2
      begin : thread2
        for (int i = 0; i < 3; i++) begin
          mutex_sem.get();  // 获取锁
          shared_counter++;  // 临界区操作
          $display("线程2: counter=%0d", shared_counter);
          mutex_sem.put();  // 释放锁
          #5;
        end
      end
    join
    
    $display("最终counter值: %0d", shared_counter);
  end
  
  //===========================================================================
  // 示例3: 限流控制
  //===========================================================================
  initial begin : rate_limit_demo
    $display("\n========== 示例3: 限流控制 ==========");
    
    rate_limiter_sem = new(3);  // 最多3个并发任务
    
    // 启动10个任务，但限制并发数为3
    for (int i = 0; i < 8; i++) begin
      fork
        automatic int id = i;
        begin
          rate_limiter_sem.get();  // 获取限流资源
          $display("任务%0d开始（时间%0t）", id, $time);
          #($urandom_range(15, 30));  // 随机工作时间
          $display("任务%0d完成（时间%0t）", id, $time);
          rate_limiter_sem.put();  // 释放限流资源
        end
      join_none
    end
    
    // 等待所有任务完成
    wait fork;
    $display("所有任务完成");
  end
  
  //===========================================================================
  // 示例4: try_get()非阻塞获取
  //===========================================================================
  initial begin : try_get_demo
    semaphore try_sem;
    bit resource_acquired;
    
    $display("\n========== 示例4: try_get()非阻塞获取 ==========");
    
    try_sem = new(1);
    
    // 主任务获取资源
    try_sem.get();
    $display("主任务占用资源");
    
    fork
      // 后台任务尝试获取资源
      begin
        #5;
        $display("后台任务尝试获取资源...");
        
        // 使用try_get()非阻塞获取
        if (try_sem.try_get()) begin
          $display("后台任务获取资源成功");
          #10;
          try_sem.put();
          $display("后台任务释放资源");
        end
        else begin
          $display("后台任务获取资源失败，资源被占用");
        end
      end
    join_none
    
    #30;
    $display("主任务释放资源");
    try_sem.put();
    
    #10;
    $display("测试完成");
  end
  
  //===========================================================================
  // 示例5: 生产者-消费者模型
  //===========================================================================
  initial begin : producer_consumer_demo
    semaphore empty_buffers, full_buffers;
    mailbox #(int) buffer_mb;
    
    $display("\n========== 示例5: 生产者-消费者 ==========");
    
    // 初始化为3个空缓冲区
    empty_buffers = new(3);
    full_buffers = new(0);
    buffer_mb = new();
    
    fork
      // 生产者线程
      begin : producer
        for (int i = 0; i < 5; i++) begin
          empty_buffers.get();  // 等待空缓冲区
          #3;
          int data = $urandom_range(0, 255);
          buffer_mb.put(data);
          $display("生产: data=%0d", data);
          full_buffers.put();  // 增加满缓冲区
        end
      end
      
      // 消费者线程
      begin : consumer
        for (int i = 0; i < 5; i++) begin
          full_buffers.get();  // 等待满缓冲区
          int data;
          buffer_mb.get(data);
          $display("消费: data=%0d", data);
          #5;
          empty_buffers.put();  // 增加空缓冲区
        end
      end
    join
    
    $display("生产消费完成");
  end
  
  //===========================================================================
  // 示例6: semaphore vs 无控制对比
  //===========================================================================
  initial begin : comparison_demo
    int counter_with_sem = 0;
    int counter_no_sem = 0;
    semaphore comp_sem;
    
    $display("\n========== 示例6: 有无semaphore对比 ==========");
    
    // 有semaphore保护
    $display("\n--- 有semaphore保护 ---");
    comp_sem = new(1);
    counter_with_sem = 0;
    
    fork
      begin
        for (int i = 0; i < 100; i++) begin
          comp_sem.get();
          counter_with_sem++;
          comp_sem.put();
        end
      end
      
      begin
        for (int i = 0; i < 100; i++) begin
          comp_sem.get();
          counter_with_sem++;
          comp_sem.put();
        end
      end
    join
    
    $display("有semaphore: counter=%0d", counter_with_sem);
    
    #10;
    
    // 无semaphore保护
    $display("\n--- 无semaphore保护 ---");
    counter_no_sem = 0;
    
    fork
      begin
        for (int i = 0; i < 100; i++) begin
          counter_no_sem++;
        end
      end
      
      begin
        for (int i = 0; i < 100; i++) begin
          counter_no_sem++;
        end
      end
    join
    
    $display("无semaphore: counter=%0d (预期: 200, 实际: <200)");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #150;
    
    $display("\n===========================================================");
    $display("                    semaphore总结");
    $display("===========================================================");
    $display("1. semaphore = new(N): 创建N个资源的旗语");
    $display("2. get(): 获取资源（阻塞）");
    $display("3. put(): 释放资源");
    $display("4. try_get(): 非阻塞尝试获取");
    $display("5. 适用场景: 共享资源池、互斥锁、限流控制");
    $display("6. 注意事项: 必须成对使用get/put");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// 1. 资源池控制: 3个资源，4个线程竞争
// 2. 互斥锁: 保护共享变量，防止竞态
// 3. 限流控制: 最多3个并发任务
// 4. try_get(): 非阻塞获取，获取失败不等待
// 5. 生产者-消费者: 使用semaphore同步
// 6. 有无semaphore对比: 无semaphore导致竞态
//=============================================================================
