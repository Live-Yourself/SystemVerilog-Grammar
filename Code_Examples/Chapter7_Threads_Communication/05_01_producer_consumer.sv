// ============================================================
// 模块5.1：生产者-消费者模型 - 综合示例
// ============================================================

// -------------------- 事务定义 --------------------
class transaction;
  rand bit [7:0] addr;
  rand bit [7:0] data;
  rand bit        rw;    // 0=读, 1=写
  
  function string display();
    return $sformatf("addr=0x%02h, data=0x%02h, rw=%s",
      addr, data, rw ? "W" : "R");
  endfunction
endclass

// -------------------- 公共变量 --------------------
int total_tx_count;       // 事务总数
int consumed_count;       // 已消费数量
event test_done;          // 测试完成事件
mailbox #(transaction) shared_mb;  // 共享信箱

// ============================================================
// 场景1：单生产者-单消费者（1P1C）基本模型
// ============================================================
initial begin : demo_1p1c
  mailbox #(transaction) mb;
  int produced, consumed;
  
  $display("\n=== 场景1: 单生产者-单消费者 (1P1C) ===");
  
  mb = new();       // 无界mailbox
  produced = 0;
  consumed = 0;
  
  fork
    // ---- 生产者 ----
    begin
      for (int i = 0; i < 3; i++) begin
        transaction tx = new();
        tx.addr = i * 16;
        tx.data = i * 8;
        tx.rw   = (i % 2 == 0) ? 1 : 0;
        #2;
        mb.put(tx);
        produced++;
        $display("[生产者] 发送事务 #%0d: %s", produced, tx.display());
      end
      $display("[生产者] 发送完毕，共%0d个事务", produced);
    end
    
    // ---- 消费者 ----
    begin
      forever begin
        transaction tx;
        mb.get(tx);  // 阻塞等待
        consumed++;
        $display("[消费者] 接收事务 #%0d: %s", consumed, tx.display());
        #3;  // 模拟处理耗时
        if (consumed == 3) begin
          $display("[消费者] 全部消费完毕");
          break;
        end
      end
    end
  join
  
  $display("[结果] 生产=%0d, 消费=%0d\n", produced, consumed);
end

// ============================================================
// 场景2：多生产者-单消费者（NP1C）
// ============================================================
initial begin : demo_np1c
  mailbox #(transaction) mb;
  int total_produced;
  bit [1:0] producer_id;
  
  $display("\n=== 场景2: 多生产者-单消费者 (NP1C) ===");
  
  mb = new();
  total_produced = 0;
  
  fork
    // ---- 生产者A ----
    begin : producer_A
      for (int i = 0; i < 2; i++) begin
        transaction tx = new();
        tx.addr = 8'h10 + i;
        tx.data = 8'hA0 + i;
        tx.rw   = 1;
        #3;
        mb.put(tx);
        $display("[生产者A] 发送: %s", tx.display());
      end
    end
    
    // ---- 生产者B ----
    begin : producer_B
      for (int i = 0; i < 2; i++) begin
        transaction tx = new();
        tx.addr = 8'h20 + i;
        tx.data = 8'hB0 + i;
        tx.rw   = 0;
        #5;
        mb.put(tx);
        $display("[生产者B] 发送: %s", tx.display());
      end
    end
    
    // ---- 消费者 ----
    begin : consumer
      forever begin
        transaction tx;
        mb.get(tx);
        total_produced++;
        $display("[消费者]   接收事务 #%0d: %s", total_produced, tx.display());
        if (total_produced == 4) begin
          $display("[消费者]   全部接收完毕");
          break;
        end
      end
    end
  join
  
  $display("[结果] 共接收%0d个事务\n", total_produced);
end

// ============================================================
// 场景3：带速率控制的有界mailbox
// ============================================================
initial begin : demo_bounded
  mailbox #(transaction) mb;
  int produced, consumed;
  
  $display("\n=== 场景3: 有界mailbox速率控制 ===");
  
  mb = new(2);      // 容量仅为2！
  produced = 0;
  consumed = 0;
  
  fork
    // ---- 快速生产者 ----
    begin
      for (int i = 0; i < 5; i++) begin
        transaction tx = new();
        tx.randomize();
        #2;  // 每2ns生产一个
        $display("[生产者] 尝试发送 #%0d (mb容量=%0d)", i+1, mb.num());
        mb.put(tx);  // 容量满时阻塞！
        produced++;
        $display("[生产者] 发送成功 #%0d", produced);
      end
      $display("[生产者] 完成");
    end
    
    // ---- 慢速消费者 ----
    begin
      forever begin
        transaction tx;
        #6;  // 每6ns消费一个（比生产慢）
        mb.get(tx);
        consumed++;
        $display("[消费者] 消费事务 #%0d: %s", consumed, tx.display());
        if (consumed == 5) begin
          $display("[消费者] 完成");
          break;
        end
      end
    end
  join
  
  $display("[结果] 生产=%0d, 消费=%0d\n", produced, consumed);
end

// ============================================================
// 场景4：使用event的优雅终止机制
// ============================================================
initial begin : demo_event_stop
  mailbox #(transaction) mb;
  int produced, consumed;
  event producer_done;    // 生产者完成事件
  event consumer_done;    // 消费者完成事件
  
  $display("\n=== 场景4: event优雅终止机制 ===");
  
  mb = new();
  produced = 0;
  consumed = 0;
  
  fork
    // ---- 生产者 ----
    begin
      for (int i = 0; i < 4; i++) begin
        transaction tx = new();
        tx.randomize();
        #2;
        mb.put(tx);
        produced++;
        $display("[生产者] 发送 #%0d", produced);
      end
      $display("[生产者] 生产完毕，通知消费者");
      ->producer_done;   // 通知消费者：没有更多数据了
    end
    
    // ---- 消费者 ----
    begin
      // 消费者需要同时监听mailbox和event
      fork
        // 等待新事务
        begin : wait_data
          forever begin
            transaction tx;
            mb.get(tx);
            consumed++;
            $display("[消费者] 接收 #%0d: %s", consumed, tx.display());
            #3;
          end
        end
        
        // 等待生产者完成信号
        begin : wait_done
          wait(producer_done.triggered);
          #5;  // 等待mailbox中残留数据处理完
          $display("[消费者] 收到终止信号，退出");
          disable wait_data;   // 终止等待数据的线程
          ->consumer_done;    // 通知主线程
        end
      join_any
    end
    
    // ---- 超时保护 ----
    begin
      #100;
      $display("[超时] 测试超时！");
    end
  join_any
  
  // 清理后台线程
  disable fork;
  
  $display("[结果] 生产=%0d, 消费=%0d\n", produced, consumed);
end

// ============================================================
// 主线程：控制执行顺序
// ============================================================
initial begin
  $display("============================================");
  $display("  模块5.1: 生产者-消费者模型 综合示例");
  $display("============================================");
  
  // 依次运行各场景（通过延迟隔离）
  #80;   // 等待场景1完成
  #70;   // 等待场景2完成
  #80;   // 等待场景3完成
  #60;   // 等待场景4完成
  
  $display("============================================");
  $display("  所有场景执行完毕");
  $display("============================================");
  $finish;
end
