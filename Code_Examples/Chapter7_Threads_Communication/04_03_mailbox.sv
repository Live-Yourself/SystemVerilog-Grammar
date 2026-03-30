//=============================================================================
// 文件名: 04_03_mailbox.sv
// 模块: 模块4.3 - mailbox信箱
// 知识点: mailbox创建、put/get/try_get/peek
//=============================================================================

program mailbox_example;
  
  //===========================================================================
  // 事务类定义
  //===========================================================================
  class transaction;
    int id;
    bit [7:0] data;
    
    function new(int id = 0, bit [7:0] data = 0);
      this.id = id;
      this.data = data;
    endfunction
    
    function void display();
      $display("事务: id=%0d, data=0x%02h", id, data);
    endfunction
  endclass
  
  //===========================================================================
  // 变量定义
  //===========================================================================
  mailbox #(int) int_mb;
  mailbox #(string) str_mb;
  mailbox #(transaction) tx_mb;
  mailbox #(int) bounded_mb, unbounded_mb;
  
  //===========================================================================
  // 示例1: 基本mailbox - 生产者-消费者
  //===========================================================================
  initial begin : basic_mailbox_demo
    $display("\n========== 示例1: 生产者-消费者 ==========");
    
    int_mb = new(5);  // 容量为5
    
    fork
      // 生产者
      begin
        for (int i = 0; i < 5; i++) begin
          #3;
          int_mb.put(i);  // 放入数据
          $display("生产者: 放入%0d", i);
        end
      end
      
      // 消费者
      begin
        for (int i = 0; i < 5; i++) begin
          int data;
          int_mb.get(data);  // 取出数据
          $display("消费者: 取出%0d", data);
        end
      end
    join
    
    $display("生产消费完成");
  end
  
  //===========================================================================
  // 示例2: 有类型mailbox - 传递事务
  //===========================================================================
  initial begin : typed_mailbox_demo
    $display("\n========== 示例2: 传递事务 ==========");
    
    tx_mb = new();  // 无界mailbox
    
    fork
      // 生产者
      begin
        for (int i = 0; i < 3; i++) begin
          #4;
          transaction tx = new(i, $urandom_range(0, 255));
          tx_mb.put(tx);  // 放入事务
          $display("生产者: 放入");
          tx.display();
        end
      end
      
      // 消费者
      begin
        for (int i = 0; i < 3; i++) begin
          transaction tx;
          tx_mb.get(tx);  // 取出事务
          $display("消费者: 取出");
          tx.display();
          #5;
        end
      end
    join
    
    $display("事务传递完成");
  end
  
  //===========================================================================
  // 示例3: try_put()非阻塞发送
  //===========================================================================
  initial begin : try_put_demo
    $display("\n========== 示例3: try_put()非阻塞发送 ==========");
    
    bounded_mb = new(2);  // 容量为2的有界mailbox
    
    fork
      // 快速生产者
      begin
        for (int i = 0; i < 6; i++) begin
          #5;
          if (bounded_mb.try_put(i)) begin
            $display("生产者: 放入%0d成功", i);
          end
          else begin
            $display("生产者: 放入%0d失败，信箱满", i);
          end
        end
      end
      
      // 慢速消费者
      begin
        forever begin
          int data;
          #15;
          bounded_mb.get(data);
          $display("消费者: 取出%0d", data);
        end
      end
    join_none
    
    #80;  // 等待完成
    $display("非阻塞发送示例完成");
  end
  
  //===========================================================================
  // 示例4: 有界mailbox vs 无界mailbox
  //===========================================================================
  initial begin : bounded_vs_unbounded_demo
    mailbox #(int) bounded = new(1);  // 容量为1
    mailbox #(int) unbounded = new();  // 容量无限
    int count = 0;
    
    $display("\n========== 示例4: 有界vs无界 ==========");
    
    fork
      // 向有界mailbox放入
      begin
        $display("\n--- 有界mailbox (容量=1) ---");
        for (int i = 0; i < 3; i++) begin
          #2;
          if (bounded.try_put(i)) begin
            $display("放入%0d成功", i);
          end
          else begin
            $display("放入%0d失败，容量: %0d", i, bounded.num());
          end
        end
      end
      
      // 向无界mailbox放入
      begin
        $display("\n--- 无界mailbox (容量=无限) ---");
        for (int i = 0; i < 3; i++) begin
          #2;
          if (unbounded.try_put(i)) begin
            $display("放入%0d成功", i);
          end
          else begin
            $display("放入%0d失败，容量: %0d", i, unbounded.num());
          end
        end
      end
    join
    
    $display("\n有界mailbox最终容量: %0d", bounded.num());
    $display("无界mailbox最终容量: %0d", unbounded.num());
  end
  
  //===========================================================================
  // 示例5: peek()查看数据
  //===========================================================================
  initial begin : peek_demo
    mailbox #(int) mb;
    int data;
    
    $display("\n========== 示例5: peek()查看数据 ==========");
    
    mb = new();
    mb.put(100);
    mb.put(200);
    
    $display("信箱中有%0d个消息", mb.num());
    
    mb.peek(data);  // 查看但不移除
    $display("peek(): %0d", data);
    $display("peek后容量: %0d", mb.num());
    
    mb.peek(data);  // 再次查看，还是同一个
    $display("再次peek(): %0d", data);
    $display("再次peek后容量: %0d", mb.num());
    
    mb.get(data);  // 真正取出
    $display("get(): %0d", data);
    $display("get后容量: %0d", mb.num());
    
    mb.peek(data);  // 现在peek是200
    $display("现在peek(): %0d", data);
  end
  
  //===========================================================================
  // 示例6: 驱动器-监视器-记分板通信
  //===========================================================================
  initial begin : tb_communication_demo
    mailbox #(transaction) drv2sb_mb, mon2sb_mb;
    int match_count = 0;
    
    $display("\n========== 示例6: TB通信 ==========");
    
    drv2sb_mb = new();
    mon2sb_mb = new();
    
    fork
      // 驱动器线程
      begin : driver
        for (int i = 0; i < 3; i++) begin
          #6;
          transaction tx = new(i, $urandom_range(0, 255));
          tx.display();
          drv2sb_mb.put(tx);  // 发送给记分板
        end
      end
      
      // 监视器线程
      begin : monitor
        for (int i = 0; i < 3; i++) begin
          #8;
          transaction tx = new(i, $urandom_range(0, 255));
          tx.display();
          mon2sb_mb.put(tx);  // 发送给记分板
        end
      end
      
      // 记分板线程
      begin : scoreboard
        repeat (3) begin
          transaction tx1, tx2;
          drv2sb_mb.get(tx1);
          $display("记分板收到驱动器事务: id=%0d", tx1.id);
          
          mon2sb_mb.get(tx2);
          $display("记分板收到监视器事务: id=%0d", tx2.id);
          
          if (tx1.id == tx2.id) begin
            $display("✓ 事务id匹配");
            match_count++;
          end
          else begin
            $display("✗ 事务id不匹配");
          end
        end
      end
    join
    
    $display("记分板比较完成，匹配数: %0d/3", match_count);
  end
  
  //===========================================================================
  // 示例7: 多驱动器数据分发
  //===========================================================================
  initial begin : multi_driver_demo
    mailbox #(transaction) drv_mb[3];
    int tx_id = 0;
    
    $display("\n========== 示例7: 多驱动器分发 ==========");
    
    // 创建3个驱动器的信箱
    foreach (drv_mb[i]) begin
      drv_mb[i] = new();
    end
    
    // 数据分发线程
    fork
      begin : distributor
        for (int i = 0; i < 6; i++) begin
          #5;
          transaction tx = new(tx_id++, $urandom_range(0, 255));
          
          // 根据id分发到不同的驱动器
          int drv_index = tx_id % 3;
          drv_mb[drv_index].put(tx);
          $display("分发: tx%0d -> driver%0d", tx.id, drv_index);
        end
      end
      
      // 3个驱动器线程
      for (int i = 0; i < 3; i++) begin
        automatic int drv_id = i;
        fork
          begin
            repeat (2) begin
              transaction tx;
              drv_mb[drv_id].get(tx);
              $display("Driver%0d: 发送事务id=%0d", drv_id, tx.id);
              #8;  // 模拟驱动时间
            end
          end
        join_none
      end
    join
    
    $display("多驱动器分发完成");
  end
  
  //===========================================================================
  // 总结
  //===========================================================================
  initial begin : summary
    #100;
    
    $display("\n===========================================================");
    $display("                    mailbox总结");
    $display("===========================================================");
    $display("1. mailbox #(type) mb = new(size): 创建有类型信箱");
    $display("2. put(): 发送数据（阻塞）");
    $display("3. get(): 接收数据（阻塞）");
    $display("4. try_put()/try_get(): 非阻塞尝试");
    $display("5. peek(): 查看数据（不移除）");
    $display("6. num(): 查询消息数量");
    $display("7. 适用场景: 生产者-消费者、TB组件通信");
    $display("===========================================================");
    
    $finish;
  end
  
endprogram

//=============================================================================
// 仿真结果预期:
//-----------------------------------------------------------------------------
// 1. 生产者-消费者: int类型的数据传递
// 2. 传递事务: 自定义类类型的数据传递
// 3. try_put(): 非阻塞发送，信箱满时立即返回
// 4. 有界vs无界: 有界mailbox容量受限
// 5. peek(): 查看数据但不移除
// 6. TB通信: 驱动器-监视器-记分板的数据流
// 7. 多驱动器: 根据条件分发到不同驱动器
//=============================================================================
