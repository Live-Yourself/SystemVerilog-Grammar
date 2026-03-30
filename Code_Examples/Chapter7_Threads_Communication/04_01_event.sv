//=============================================================================
// 文件名: 04_01_event.sv
// 模块: 模块4.1 - event事件
// 知识点: event声明、触发、等待、合并
//=============================================================================

program event_example;
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  event data_ready, transfer_done, sync_point, timeout, error;
  bit [7:0] shared_data;
  bit error_condition;
  int ready_count;
  
  //===========================================================================
  // 示例1: 基本event使用 - 数据就绪通知
  //===========================================================================
  initial begin : basic_event_demo
    $display("\n========== 示例1: 基本event使用 ==========");
    
    fork
      // 消费者线程
      begin
        $display("等待数据就绪...");
        @data_ready;  // 等待事件
        $display("收到数据: 0x%02h", shared_data);
      end
      
      // 生产者线程
      begin
        #10;
        shared_data = 8'hA5;
        $display("数据就绪，触发事件");
        ->data_ready;  // 触发事件
      end
    join
  end
  
  //===========================================================================
  // 示例2: @与wait(e.triggered)的区别
  //===========================================================================
  initial begin : wait_triggered_demo
    event e1, e2;
    
    $display("\n========== 示例2: @与wait(e.triggered) ==========");
    
    // 场景1: 事件先触发，后等待
    fork
      begin
        #5;
        ->e1;
        $display("事件e1已触发");
      end
      
      begin
        #10;
        $display("检查事件e1...");
        // 使用wait(e.triggered)，即使事件已触发也能检测到
        wait(e1.triggered);
        $display("wait(e1.triggered)返回");
      end
    join
    
    #2;
    
    // 场景2: 使用@可能错过事件
    fork
      begin
        #5;
        ->e2;
        $display("事件e2已触发");
      end
      
      begin
        #10;
        $display("等待事件e2...");
        // 如果事件已触发，@会永远等待
        // @e2;  // 这行会挂死！
        wait(e2.triggered);  // 使用wait更安全
        $display("收到事件e2");
      end
    join
  end
  
  //===========================================================================
  // 示例3: 握手协议
  //===========================================================================
  initial begin : handshake_demo
    event request_sent, response_received;
    
    $display("\n========== 示例3: 握手协议 ==========");
    
    fork
      // 请求发送线程
      begin
        #5;
        $display("发送请求");
        ->request_sent;  // 请求已发送
        
        $display("等待响应...");
        @response_received;  // 等待响应
        $display("收到响应，握手完成");
      end
      
      // 响应接收线程
      begin
        @request_sent;  // 等待请求发送
        $display("检测到请求，发送响应");
        #8;
        ->response_received;  // 响应已接收
      end
    join
  end
  
  //===========================================================================
  // 示例4: 多线程同步点
  //===========================================================================
  initial begin : sync_point_demo
    event sync_point;
    ready_count = 0;
    
    $display("\n========== 示例4: 多线程同步点 ==========");
    
    fork
      // 线程1
      begin
        #8;
        $display("线程1准备就绪");
        ready_count++;
        @sync_point;  // 等待同步
        $display("线程1通过同步点");
      end
      
      // 线程2
      begin
        #12;
        $display("线程2准备就绪");
        ready_count++;
        @sync_point;  // 等待同步
        $display("线程2通过同步点");
      end
      
      // 线程3
      begin
        #6;
        $display("线程3准备就绪");
        ready_count++;
        @sync_point;  // 等待同步
        $display("线程3通过同步点");
      end
      
      // 同步控制线程
      begin
        wait(ready_count == 3);  // 等待所有线程就绪
        #1;
        $display("所有线程就绪，触发同步点");
        ->sync_point;  // 触发同步
      end
    join
  end
  
  //===========================================================================
  // 示例5: event合并 - 等待多个事件
  //===========================================================================
  initial begin : event_merge_demo
    $display("\n========== 示例5: event合并 ==========");
    
    fork
      // 数据接收线程
      begin
        #15;
        $display("数据接收完成");
        ->data_ready;
      end
      
      // 超时监控线程
      begin
        #20;
        $display("超时！");
        ->timeout;
      end
      
      // 错误检测线程
      begin
        #25;
        $display("检测到错误！");
        ->error;
      end
    join_none
    
    // 等待任意一个事件
    $display("等待数据、超时或错误...");
    @(data_ready or timeout or error);
    
    if (data_ready.triggered)
      $display("数据接收成功");
    else if (timeout.triggered)
      $display("接收超时");
    else if (error.triggered)
      $display("接收错误");
  end
  
  //===========================================================================
  // 示例6: 事件的多次触发
  //===========================================================================
  initial begin : repeated_trigger_demo
    event periodic_event;
    int trigger_count;
    
    $display("\n========== 示例6: 事件多次触发 ==========");
    
    trigger_count = 0;
    
    fork
      // 事件触发线程
      begin
        for (int i = 0; i < 3; i++) begin
          #10;
          trigger_count++;
          $display("触发事件 #%0d", trigger_count);
          ->periodic_event;
        end
      end
      
      // 事件接收线程
      begin
        for (int i = 0; i < 3; i++) begin
          @periodic_event;
          $display("收到事件 #%0d", i + 1);
        end
      end
    join
    
    $display("所有事件触发和接收完成");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #100;
    
    $display("\n===========================================================");
    $display("                    event事件总结");
    $display("===========================================================");
    $display("1. event三要素: 声明、触发、等待");
    $display("2. 触发方式: ->event");
    $display("3. 等待方式: @event 或 wait(event.triggered)");
    $display("4. 适用场景: 数据就绪、握手协议、多线程同步");
    $display("5. event合并: @(e1 or e2 or e3)");
    $display("6. 注意事项: 避免错过事件，建议使用wait()");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// 1. 基本event: 生产者-消费者模型，数据就绪通知
// 2. @与wait(): 演示两种等待方式的区别
// 3. 握手协议: 请求-响应的同步机制
// 4. 同步点: 多线程在同步点等待
// 5. event合并: 等待多个事件中的任意一个
// 6. 多次触发: 事件的重复触发和接收
//=============================================================================
