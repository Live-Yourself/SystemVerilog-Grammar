// ============================================================
// 模块5.2：握手协议实现 - 综合示例
// ============================================================

// -------------------- 公共变量 --------------------
bit clk;
bit rst;

// -------------------- 时钟生成 --------------------
initial begin : clk_gen
  clk = 0;
  forever #5 clk = ~clk;
end

// ============================================================
// 场景1：两阶段 Ready-Valid 握手
// ============================================================
initial begin : demo_ready_valid
  event valid_event;     // valid信号通知
  event ready_event;     // ready信号通知
  bit [7:0] tx_data;     // 传输的数据
  
  $display("\n=== 场景1: 两阶段 Ready-Valid 握手 ===");
  
  tx_data = 8'hA5;
  
  fork
    // ---- Master：发送数据 ----
    begin : master
      $display("[Master]  准备发送数据 0x%02h", tx_data);
      #7;  // 随机延迟
      $display("[Master]  拉高valid");
      ->valid_event;     // 通知Slave：valid拉高
      
      // 等待Slave的ready
      wait(ready_event.triggered);
      $display("[Master]  收到ready，握手成功！数据已传输");
    end
    
    // ---- Slave：接收数据 ----
    begin : slave
      $display("[Slave]   等待valid...");
      wait(valid_event.triggered);
      #4;  // Slave处理延迟
      $display("[Slave]   拉高ready，接收数据 0x%02h", tx_data);
      ->ready_event;     // 通知Master：ready拉高
    end
  join
  
  $display("[结果]   Ready-Valid握手完成\n");
end

// ============================================================
// 场景2：三阶段 REQ-ACK 握手
// ============================================================
initial begin : demo_req_ack
  event req_event;       // 请求事件
  event ack_event;       // 应答事件
  event req_rel_event;   // 请求释放事件
  bit [7:0] req_addr;
  bit [7:0] rsp_data;
  
  $display("\n=== 场景2: 三阶段 REQ-ACK 握手 ===");
  
  req_addr = 8'h40;
  rsp_data = 8'hFF;
  
  fork
    // ---- Master ----
    begin
      // 阶段1：发送请求
      $display("[Master]  阶段1: 发送请求 addr=0x%02h", req_addr);
      #3;
      ->req_event;
      
      // 阶段2：等待应答
      $display("[Master]  阶段2: 等待应答...");
      wait(ack_event.triggered);
      $display("[Master]  收到应答 data=0x%02h", rsp_data);
      
      // 阶段3：释放请求
      #2;
      $display("[Master]  阶段3: 释放请求");
      ->req_rel_event;
    end
    
    // ---- Slave ----
    begin
      // 阶段1：接收请求
      wait(req_event.triggered);
      $display("[Slave]   阶段1: 收到请求 addr=0x%02h", req_addr);
      
      // 阶段2：处理并发送应答
      #5;
      rsp_data = req_addr + 8'h10;  // 模拟读操作
      $display("[Slave]   阶段2: 发送应答 data=0x%02h", rsp_data);
      ->ack_event;
      
      // 阶段3：确认请求释放
      wait(req_rel_event.triggered);
      $display("[Slave]   阶段3: 请求已释放，握手完成");
    end
  join
  
  $display("[结果]   REQ-ACK三阶段握手完成\n");
end

// ============================================================
// 场景3：带超时保护的握手
// ============================================================
initial begin : demo_timeout
  event req_event;
  event ack_event;
  bit handshake_ok;
  bit simulate_timeout;   // 模拟超时场景（1=超时，0=正常）
  
  simulate_timeout = 0;  // 先测试正常情况
  
  $display("\n=== 场景3: 带超时保护的握手 ===");
  
  // ---- 测试A：正常握手 ----
  $display("--- 测试A: 正常握手 ---");
  handshake_ok = 0;
  
  fork
    // Master
    begin
      #3;
      ->req_event;
      wait(ack_event.triggered);
      handshake_ok = 1;
    end
    
    // Slave（正常应答）
    begin
      wait(req_event.triggered);
      #5;
      ->ack_event;
    end
    
    // 超时检测
    begin
      #30;  // 30ns超时
      $display("[超时]   握手超时！");
    end
  join_any
  
  if (handshake_ok)
    $display("[结果]   握手成功（正常）");
  else
    $display("[结果]   握手失败");
  
  // ---- 测试B：模拟超时 ----
  $display("\n--- 测试B: 模拟超时 ---");
  handshake_ok = 0;
  
  fork
    // Master
    begin
      #3;
      ->req_event;
      wait(ack_event.triggered);
      handshake_ok = 1;
    end
    
    // Slave（不应答，模拟故障）
    begin
      wait(req_event.triggered);
      // 故意不应答！
      $display("[Slave]   收到请求，但故意不应答...");
    end
    
    // 超时检测
    begin
      #15;  // 15ns超时
      $display("[超时]   握手超时！Slave无应答");
    end
  join_any
  
  disable fork;  // 清理后台线程
  
  if (handshake_ok)
    $display("[结果]   握手成功");
  else
    $display("[结果]   握手超时，已清理后台线程\n");
end

// ============================================================
// 场景4：多次连续握手传输（使用mailbox）
// ============================================================
initial begin : demo_multi_transfer
  mailbox #(bit [7:0]) req_mb;
  mailbox #(bit [7:0]) rsp_mb;
  int transfer_count;
  
  $display("\n=== 场景4: 多次连续握手传输 ===");
  
  req_mb = new();
  rsp_mb = new();
  transfer_count = 0;
  
  fork
    // ---- Master：发送多个请求 ----
    begin
      for (int i = 0; i < 4; i++) begin
        bit [7:0] addr = i * 16;
        #4;
        req_mb.put(addr);
        $display("[Master]  发送请求 #%0d, addr=0x%02h", i+1, addr);
      end
      $display("[Master]  所有请求已发送");
    end
    
    // ---- Slave：处理请求并返回应答 ----
    begin
      forever begin
        bit [7:0] addr, data;
        req_mb.get(addr);
        #3;  // 处理延迟
        data = addr + 8'h01;
        rsp_mb.put(data);
        transfer_count++;
        $display("[Slave]   应答 #%0d, addr=0x%02h -> data=0x%02h",
                 transfer_count, addr, data);
        if (transfer_count == 4) begin
          $display("[Slave]   所有请求已处理");
          break;
        end
      end
    end
    
    // ---- Master：接收应答 ----
    begin
      for (int i = 0; i < 4; i++) begin
        bit [7:0] data;
        rsp_mb.get(data);
        $display("[Master]  收到应答 #%0d, data=0x%02h", i+1, data);
      end
    end
  join
  
  $display("[结果]   完成%0d次连续握手传输\n", transfer_count);
end

// ============================================================
// 场景5：多通道并行握手
// ============================================================
initial begin : demo_multi_channel
  event ch_a_req, ch_a_ack;
  event ch_b_req, ch_b_ack;
  
  $display("\n=== 场景5: 多通道并行握手 ===");
  
  fork
    // ---- 通道A握手 ----
    begin
      $display("[通道A]  开始握手...");
      fork
        begin  // Master A
          #3;
          ->ch_a_req;
          $display("[通道A]  Master发送请求");
          wait(ch_a_ack.triggered);
          $display("[通道A]  握手完成！");
        end
        begin  // Slave A
          wait(ch_a_req.triggered);
          #6;
          ->ch_a_ack;
        end
      join
    end
    
    // ---- 通道B握手 ----
    begin
      $display("[通道B]  开始握手...");
      fork
        begin  // Master B
          #5;
          ->ch_b_req;
          $display("[通道B]  Master发送请求");
          wait(ch_b_ack.triggered);
          $display("[通道B]  握手完成！");
        end
        begin  // Slave B
          wait(ch_b_req.triggered);
          #2;
          ->ch_b_ack;
        end
      join
    end
  join
  
  $display("[结果]   两个通道并行握手完成\n");
end

// ============================================================
// 主线程：控制执行顺序
// ============================================================
initial begin
  $display("============================================");
  $display("  模块5.2: 握手协议实现 综合示例");
  $display("============================================");
  
  // 依次等待各场景完成
  #50;   // 场景1: Ready-Valid
  #40;   // 场景2: REQ-ACK
  #60;   // 场景3: 超时保护
  #60;   // 场景4: 多次传输
  #40;   // 场景5: 多通道
  
  $display("============================================");
  $display("  所有场景执行完毕");
  $display("============================================");
  $finish;
end
