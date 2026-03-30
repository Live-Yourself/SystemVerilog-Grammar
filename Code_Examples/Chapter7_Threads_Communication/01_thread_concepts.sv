//=============================================================================
// 文件名: 01_thread_concepts.sv
// 模块: 模块1 - 线程的基本概念
// 知识点: 1.1-1.3 线程概念、硬件并发关系、验证环境并发需求
//=============================================================================

program thread_concepts_example;
  
  //===========================================================================
  // 变量定义区（在initial块外部）
  //===========================================================================
  bit clk;
  bit [7:0] data_bus;
  bit valid_sig, ready_sig;
  bit timeout_flag;
  bit monitor_done, driver_done;
  
  //===========================================================================
  // 示例1: 单线程 vs 多线程的对比
  //===========================================================================
  initial begin : single_vs_multi_thread
    $display("\n===========================================================");
    $display("     知识点1: 线程的基本概念 - 单线程vs多线程");
    $display("===========================================================");
    
    // 示例1.1: 单线程顺序执行
    $display("\n---------- 示例1.1: 单线程顺序执行 ----------");
    $display("[%0t] 开始顺序执行任务", $time);
    #10 $display("[%0t] 任务1完成", $time);
    #5  $display("[%0t] 任务2完成", $time);
    #8  $display("[%0t] 任务3完成", $time);
    $display("[%0t] 顺序执行完成，总耗时 = 10+5+8 = %0dns", $time, $time);
    
    // 等待一会儿，准备下一个示例
    #2;
    
    // 示例1.2: 多线程并行执行
    $display("\n---------- 示例1.2: 多线程并行执行 ----------");
    $display("[%0t] 开始并行执行任务", $time);
    fork
      begin : task1
        #10 $display("[%0t] 任务1完成", $time);
      end
      begin : task2
        #5  $display("[%0t] 任务2完成", $time);
      end
      begin : task3
        #8  $display("[%0t] 任务3完成", $time);
      end
    join
    $display("[%0t] 并行执行完成，总耗时 = max(10,5,8) = %0dns", $time, $time);
    $display("效率提升: %0d%%", ((23 - $time) * 100) / 23);
  end
  
  //===========================================================================
  // 示例2: 模拟硬件并发行为
  //===========================================================================
  initial begin : hardware_concurrency_demo
    $display("\n===========================================================");
    $display("     知识点2: 线程与硬件并发的关系");
    $display("===========================================================");
    
    // 模拟一个简单处理器的三个并行模块
    $display("\n---------- 示例2.1: 模拟硬件并行模块 ----------");
    $display("[%0t] 启动处理器并行模块模拟", $time);
    
    fork
      // 模块1: ALU（算术逻辑单元）
      begin : alu_module
        $display("[%0t] ALU模块启动，执行加法运算...", $time);
        #8; // 模拟计算延迟
        $display("[%0t] ALU模块完成: 5+3=8", $time);
      end
      
      // 模块2: Register File（寄存器文件）
      begin : register_file
        $display("[%0t] Register模块启动，读写寄存器...", $time);
        #6; // 模拟读写延迟
        $display("[%0t] Register模块完成: R1=0xAA, R2=0xBB", $time);
      end
      
      // 模块3: Control Unit（控制单元）
      begin : control_unit
        $display("[%0t] Control模块启动，解码指令...", $time);
        #10; // 模拟解码延迟
        $display("[%0t] Control模块完成: ADD R1,R2,R3", $time);
      end
    join
    
    $display("[%0t] 所有模块并行执行完成", $time);
    $display("说明: 这三个模块在真实硬件中是同时工作的!");
  end
  
  //===========================================================================
  // 示例3: 验证环境中的并发需求 - 多接口驱动
  //===========================================================================
  initial begin : multi_interface_demo
    $display("\n===========================================================");
    $display("     知识点3.1: 验证环境并发需求 - 多接口驱动");
    $display("===========================================================");
    
    $display("\n---------- 示例3.1: 同时驱动多个接口 ----------");
    $display("[%0t] DUT有三个输入接口，需要同时发送激励", $time);
    
    fork
      // 接口A驱动
      begin : interface_a_driver
        $display("[%0t] 接口A驱动器启动", $time);
        #5;
        data_bus = 8'hA5;
        valid_sig = 1;
        $display("[%0t] 接口A发送数据: 0x%02h, valid=1", $time, data_bus);
      end
      
      // 接口B驱动
      begin : interface_b_driver
        $display("[%0t] 接口B驱动器启动", $time);
        #3;
        data_bus = 8'h3C;
        ready_sig = 1;
        $display("[%0t] 接口B发送数据: 0x%02h, ready=1", $time, data_bus);
      end
      
      // 接口C驱动
      begin : interface_c_driver
        $display("[%0t] 接口C驱动器启动", $time);
        #7;
        data_bus = 8'hF0;
        valid_sig = 0;
        ready_sig = 0;
        $display("[%0t] 接口C发送数据: 0x%02h, valid=0, ready=0", $time, data_bus);
      end
    join
    
    $display("[%0t] 所有接口并行驱动完成", $time);
    $display("说明: 模拟真实硬件环境的多通道同时输入");
  end
  
  //===========================================================================
  // 示例4: 验证环境中的并发需求 - 监控与驱动并行
  //===========================================================================
  initial begin : monitor_driver_parallel_demo
    $display("\n===========================================================");
    $display("     知识点3.2: 验证环境并发需求 - 监控与驱动并行");
    $display("===========================================================");
    
    $display("\n---------- 示例4: 边驱动边监控 ----------");
    $display("[%0t] 启动驱动器和监控器并行工作", $time);
    
    fork
      // 驱动线程: 持续发送激励
      begin : stimulus_driver
        $display("[%0t] 驱动线程启动", $time);
        for (int i = 0; i < 3; i++) begin
          #4;
          data_bus = 8'h10 + i;
          valid_sig = 1;
          $display("[%0t] 驱动发送: data=0x%02h, valid=1", $time, data_bus);
          #2;
          valid_sig = 0;
        end
        driver_done = 1;
        $display("[%0t] 驱动线程完成", $time);
      end
      
      // 监控线程: 持续监控输出
      begin : output_monitor
        $display("[%0t] 监控线程启动", $time);
        for (int i = 0; i < 5; i++) begin
          #3;
          $display("[%0t] 监控采样: data=0x%02h, valid=%b, ready=%b", 
                   $time, data_bus, valid_sig, ready_sig);
        end
        monitor_done = 1;
        $display("[%0t] 监控线程完成", $time);
      end
    join_any
    
    // 等待两个线程都完成
    wait(driver_done && monitor_done);
    $display("[%0t] 驱动和监控并行执行完成", $time);
    $display("说明: 边驱动边监控，提高验证效率");
  end
  
  //===========================================================================
  // 示例5: 验证环境中的并发需求 - 超时检测
  //===========================================================================
  initial begin : timeout_detection_demo
    $display("\n===========================================================");
    $display("     知识点3.3: 验证环境并发需求 - 超时检测");
    $display("===========================================================");
    
    $display("\n---------- 示例5: 超时检测机制 ----------");
    
    bit operation_complete;
    int operation_delay;
    
    // 随机生成操作延迟（可能超过超时阈值）
    operation_delay = $urandom_range(30, 80);
    
    $display("[%0t] 启动操作（预期延迟%0dns）和超时检测（阈值50ns）", 
             $time, operation_delay);
    
    fork
      // 主操作线程
      begin : main_operation
        $display("[%0t] 主操作开始执行...", $time);
        #operation_delay;
        operation_complete = 1;
        $display("[%0t] ✓ 主操作完成", $time);
      end
      
      // 超时检测线程
      begin : timeout_timer
        #50;  // 50ns超时阈值
        if (!operation_complete) begin
          timeout_flag = 1;
          $display("[%0t] ⚠ 超时警告: 操作未在50ns内完成！", $time);
        end
      end
    join_any
    
    // 检查结果
    #1;
    if (timeout_flag)
      $display("[%0t] 测试失败: 操作超时", $time);
    else if (operation_complete)
      $display("[%0t] 测试通过: 操作在%0dns内完成", $time, operation_delay);
    
    disable fork;  // 终止所有后台线程
    
    $display("说明: 使用并行线程实现超时保护，防止测试挂死");
  end
  
  //===========================================================================
  // 示例6: 验证环境中的并发需求 - 协议握手
  //===========================================================================
  initial begin : protocol_handshake_demo
    $display("\n===========================================================");
    $display("     知识点3.4: 验证环境并发需求 - 协议握手");
    $display("===========================================================");
    
    $display("\n---------- 示例6: 协议握手交互 ----------");
    $display("[%0t] 模拟简单的请求-应答协议", $time);
    
    bit request_sent, response_received;
    bit [7:0] request_data, response_data;
    
    fork
      // 请求发送线程
      begin : request_sender
        $display("[%0t] 发送请求线程启动", $time);
        #2;
        request_data = 8'h55;
        request_sent = 1;
        $display("[%0t] →→ 发送请求: data=0x%02h", $time, request_data);
        #30;
        request_sent = 0;
      end
      
      // 响应等待线程
      begin : response_waiter
        $display("[%0t] 等待响应线程启动", $time);
        wait(request_sent);
        $display("[%0t] 检测到请求已发送，等待响应...", $time);
        #8;
        response_data = 8'hAA;
        response_received = 1;
        $display("[%0t] ←← 收到响应: data=0x%02h", $time, response_data);
      end
      
      // 超时检测线程
      begin : handshake_timeout
        #20;
        if (!response_received) begin
          $display("[%0t] ✗ 握手超时: 20ms内未收到响应", $time);
        end
      end
    join_any
    
    wait(response_received || timeout_flag);
    if (response_received)
      $display("[%0t] 协议握手成功完成", $time);
    
    disable fork;
    $display("说明: 多线程协作实现复杂的协议交互逻辑");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    // 等待前面的所有演示完成
    #100;
    
    $display("\n===========================================================");
    $display("                    模块1 知识点总结");
    $display("===========================================================");
    $display("1. 线程是程序执行的基本单元，可以并发运行");
    $display("2. 线程模拟了硬件的并行行为");
    $display("3. 验证环境中需要并发的原因:");
    $display("   - 多接口同时驱动");
    $display("   - 监控与驱动并行");
    $display("   - 超时检测保护");
    $display("   - 复杂协议握手");
    $display("4. 合理使用线程是高效验证的关键");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// 模块1 线程的基本概念
//-----------------------------------------------------------------------------
// 1. 单线程顺序执行: 总耗时 = 10+5+8 = 23ns
// 2. 多线程并行执行: 总耗时 = max(10,5,8) = 10ns
// 3. 硬件并发模拟: 三个模块并行工作
// 4. 多接口驱动: 同时驱动三个接口
// 5. 监控与驱动并行: 边驱动边监控
// 6. 超时检测: 防止测试挂死
// 7. 协议握手: 请求-应答-超时检测
//=============================================================================
