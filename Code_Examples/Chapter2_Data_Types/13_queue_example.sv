// ===================================
// 队列示例 (Queue)
// 知识点9: 第2章 SystemVerilog数据类型
// ===================================

module queue_example;
  
  // 1. 队列声明
  int unbounded_q[$];           // 无界队列,大小无限制
  int bounded_q[$:15];          // 有界队列,最大15个元素
  logic [7:0] data_q[$];        // 8位向量队列
  
  // 用于存储临时数据
  int temp_val;                 // 临时变量,用于存储弹出的值
  int i;                        // 循环索引变量
  
  // FIFO缓冲区相关变量
  logic [31:0] fifo[$];         // FIFO缓冲队列,用于演示生产者-消费者模型
  logic [31:0] tx_data;         // 发送数据,生产者写入的数据
  logic [31:0] rx_data;         // 接收数据,消费者读取的数据
  
  // 事务调度相关变量
  string transaction_q[$];      // 事务队列,用于演示事务调度
  string trans;                 // 事务名称,临时存储弹出的事务
  
  // 数据包缓冲相关定义
  typedef struct packed {       // 使用packed关键字,确保兼容性
    bit [7:0] addr;             // 数据包地址字段
    bit [31:0] data;            // 数据包数据字段
    bit [3:0]  cmd;             // 数据包命令字段
  } packet_t;                   // 数据包结构体类型定义
  
  packet_t pkt_q[$];            // 数据包队列,用于演示复杂数据类型的队列
  packet_t pkt;                 // 临时数据包,用于构建数据包
  
  initial begin
    $display("========================================");
    $display("队列示例 (Queue)");
    $display("========================================\n");
    
    //================================================================
    // 2. 队列初始化和基本操作
    //================================================================
    $display("【示例1】队列基本操作");
    $display("----------------------------------------");
    
    // 队列初始化
    unbounded_q = '{1, 2, 3, 4, 5};  // 使用单引号初始化
    $display("初始队列: %p", unbounded_q);
    $display("队列大小: %0d", unbounded_q.size());
    
    // 索引访问
    $display("\n索引访问:");
    $display("  q[0]  = %0d (第一个元素)", unbounded_q[0]);
    $display("  q[$]  = %0d (最后一个元素)", unbounded_q[$]);
    // 注意: 某些仿真器不支持$-1表达式,使用size()-1代替
    $display("  q[$-1]= %0d (倒数第二个)", unbounded_q[unbounded_q.size()-1]);
    
    //================================================================
    // 3. 插入操作
    //================================================================
    $display("\n【示例2】插入操作");
    $display("----------------------------------------");
    
    // 头部插入 push_front
    unbounded_q.push_front(0);
    $display("push_front(0): %p", unbounded_q);
    
    // 尾部插入 push_back
    unbounded_q.push_back(6);
    $display("push_back(6):  %p", unbounded_q);
    
    // 指定位置插入 insert
    unbounded_q.insert(3, 100);
    $display("insert(3,100): %p", unbounded_q);
    
    //================================================================
    // 4. 删除操作
    //================================================================
    $display("\n【示例3】删除操作");
    $display("----------------------------------------");
    
    // 头部弹出 pop_front
    temp_val = unbounded_q.pop_front();
    $display("pop_front() = %0d", temp_val);
    $display("队列: %p", unbounded_q);
    
    // 尾部弹出 pop_back
    temp_val = unbounded_q.pop_back();
    $display("\npop_back() = %0d", temp_val);
    $display("队列: %p", unbounded_q);
    
    // 删除指定索引
    unbounded_q.delete(2);  // 删除索引2的元素
    $display("\ndelete(2): %p", unbounded_q);
    
    // 清空队列
    unbounded_q.delete();
    $display("清空队列: %p (大小=%0d)", unbounded_q, unbounded_q.size());
    
    //================================================================
    // 5. 有界队列
    //================================================================
    $display("\n【示例4】有界队列");
    $display("----------------------------------------");
    
    bounded_q = '{10, 20, 30, 40, 50};
    $display("有界队列[0:15]: %p", bounded_q);
    $display("当前大小: %0d, 最大容量: 16", bounded_q.size());
    
    // 注意:有界队列超过最大值会报错
    // bounded_q.push_back(60);  // 如果超过15会报错
    
    //================================================================
    // 6. 队列方法 - 查找和统计
    //================================================================
    $display("\n【示例5】队列方法");
    $display("----------------------------------------");
    
    unbounded_q = '{5, 10, 15, 20, 25, 30};
    $display("队列: %p", unbounded_q);
    
    $display("\n统计方法:");
    $display("  size()    = %0d", unbounded_q.size());
    $display("  sum()     = %0d", unbounded_q.sum());
    $display("  product() = %0d", unbounded_q.product());
    $display("  min()     = %p", unbounded_q.min());
    $display("  max()     = %p", unbounded_q.max());
    
    // 排序
    unbounded_q = '{30, 10, 50, 20, 40};
    $display("\n排序前: %p", unbounded_q);
    unbounded_q.sort();
    $display("sort():  %p (升序)", unbounded_q);
    unbounded_q.rsort();
    $display("rsort(): %p (降序)", unbounded_q);
    
    // 反转
    unbounded_q.reverse();
    $display("reverse(): %p", unbounded_q);
    
    //================================================================
    // 7. 实际应用1: FIFO缓冲区
    //================================================================
    $display("\n【示例6】实际应用: FIFO缓冲区");
    $display("----------------------------------------");
    
    // 生产者:写入FIFO
    for (i = 0; i < 5; i++) begin
      tx_data = $urandom_range(0, 100);
      fifo.push_back(tx_data);  // 尾部写入
      $display("[生产] 写入FIFO: data=%0d, size=%0d", tx_data, fifo.size());
    end
    
    // 消费者:从FIFO读取
    $display("\n消费者读取:");
    while (fifo.size() > 0) begin
      rx_data = fifo.pop_front();  // 头部读取
      $display("[消费] 读取FIFO: data=%0d, size=%0d", rx_data, fifo.size());
    end
    
    //================================================================
    // 8. 实际应用2: 事务调度队列
    //================================================================
    $display("\n【示例7】实际应用: 事务调度");
    $display("----------------------------------------");
    
    // 添加事务到队列
    transaction_q.push_back("READ");
    transaction_q.push_back("WRITE");
    transaction_q.push_back("READ");
    transaction_q.push_back("IDLE");
    transaction_q.push_back("WRITE");
    
    $display("事务队列: %p", transaction_q);
    
    // 高优先级事务插入队首
    transaction_q.push_front("URGENT_READ");
    $display("\n插入紧急事务: %p", transaction_q);
    
    // 处理事务
    $display("\n处理事务:");
    while (transaction_q.size() > 0) begin
      trans = transaction_q.pop_front();
      $display("  执行: %s", trans);
    end
    
    //================================================================
    // 9. 实际应用3: 数据包缓冲
    //================================================================
    $display("\n【示例8】实际应用: 数据包缓冲");
    $display("----------------------------------------");
    
    // 构建数据包
    for (i = 0; i < 3; i++) begin
      pkt.addr = i * 4;
      pkt.data = $urandom();
      pkt.cmd  = i % 4;
      pkt_q.push_back(pkt);
    end
    
    $display("数据包队列大小: %0d", pkt_q.size());
    
    // 遍历数据包
    foreach (pkt_q[i])
      $display("  Packet[%0d]: addr=0x%h, data=0x%h, cmd=%0d", 
               i, pkt_q[i].addr, pkt_q[i].data, pkt_q[i].cmd);
    
    //================================================================
    // 10. 队列 vs 动态数组 vs 关联数组对比
    //================================================================
    $display("\n【对比总结】");
    $display("========================================");
    $display("特性          | 队列        | 动态数组    | 关联数组");
    $display("--------------|------------|------------|----------");
    $display("大小调整      | 自动       | 手动new    | 自动");
    $display("索引访问      | 支持       | 支持       | 支持");
    $display("插入/删除效率 | 高(O(1)/O(n))| 低(O(n)) | 高(O(1))");
    $display("内存占用      | 中         | 低         | 高");
    $display("适用场景      | FIFO/消息  | 动态数据   | 稀疏数据");
    $display("========================================");
    
    $display("\n示例完成!");
  end
  
endmodule
