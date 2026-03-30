// ============================================================
// 模块5.3：验证平台典型架构 - 综合示例
// ============================================================
// 本示例实现一个简化版的验证平台，展示线程与通信的综合运用

// -------------------- 时钟与复位 --------------------
bit clk;
bit rst_n;

initial begin : clock_gen
  clk = 0;
  forever #5 clk = ~clk;
end

// -------------------- DUT接口信号 --------------------
bit        req_valid;
bit        req_ready;
bit [7:0]  req_addr;
bit [7:0]  req_data;
bit        rsp_valid;
bit [7:0]  rsp_data;

// -------------------- 事务定义 --------------------
class transaction;
  rand bit [7:0] addr;
  rand bit [7:0] data;
  rand bit        rw;       // 0=读, 1=写
  
  function string display();
    return $sformatf("[%s] addr=0x%02h data=0x%02h",
      rw ? "WR" : "RD", addr, data);
  endfunction
  
  function transaction copy();
    copy = new();
    copy.addr = this.addr;
    copy.data = this.data;
    copy.rw   = this.rw;
    return copy;
  endfunction
endclass

// -------------------- 通信通道 --------------------
mailbox #(transaction) gen2drv_mb;   // Generator → Driver
mailbox #(transaction) mon2sb_mb;    // Monitor → Scoreboard
mailbox #(transaction) ref2sb_mb;    // Ref Model → Scoreboard

// -------------------- 控制信号 --------------------
event   test_done;                    // 测试完成
event   all_checked;                  // 所有结果已比较
int     total_sent;                   // 总发送事务数
int     pass_count;                   // 通过数
int     fail_count;                   // 失败数
int     sb_checked;                   // 已比较数

// ============================================================
// Generator：生成激励
// ============================================================
task run_generator(int num_tx);
  $display("[Generator] 开始生成%0d个事务", num_tx);
  
  for (int i = 0; i < num_tx; i++) begin
    transaction tx = new();
    tx.randomize();
    #($urandom_range(1, 5));  // 随机间隔
    gen2drv_mb.put(tx);
    total_sent++;
    $display("[Generator] 生成 #%0d: %s", i+1, tx.display());
  end
  
  $display("[Generator] 全部生成完毕，共%0d个", num_tx);
  ->test_done;
endtask

// ============================================================
// Driver：驱动DUT
// ============================================================
task run_driver();
  $display("[Driver] 启动");
  
  forever begin
    transaction tx;
    gen2drv_mb.get(tx);   // 阻塞等待事务
    
    // 等待时钟沿
    @(posedge clk);
    
    // 驱动DUT接口
    req_valid = 1;
    req_addr  = tx.addr;
    req_data  = tx.data;
    
    // 等待ready
    fork
      begin : wait_ready
        forever begin
          @(posedge clk);
          if (req_ready) begin
            req_valid = 0;
            $display("[Driver]   驱动完成: %s", tx.display());
            disable wait_ready;
          end
        end
      end
      begin : drv_timeout
        #50;
        $display("[Driver]   超时：ready未拉高");
        req_valid = 0;
        disable wait_ready;
      end
    join_any
  end
endtask

// ============================================================
// Monitor：采集DUT响应
// ============================================================
task run_monitor();
  $display("[Monitor] 启动");
  
  forever begin
    @(posedge clk);
    if (rsp_valid) begin
      transaction tx = new();
      tx.addr = req_addr;       // 采样地址
      tx.data = rsp_data;       // 采样响应数据
      tx.rw   = 0;              // 标记为响应
      mon2sb_mb.put(tx);
      $display("[Monitor]  采集响应: addr=0x%02h data=0x%02h",
               tx.addr, tx.data);
    end
  end
endtask

// ============================================================
// Ref Model：参考模型
// ============================================================
task run_ref_model();
  $display("[RefModel] 启动");
  
  forever begin
    transaction tx;
    gen2drv_mb.peek(tx);   // 偷看事务（不取出）
    
    // 等待Driver驱动完成
    fork
      begin : wait_drive
        forever begin
          @(posedge clk);
          if (req_ready && req_valid) begin
            transaction ref_tx = tx.copy();
            // 简单参考模型：读操作返回addr+1, 写操作返回data
            if (tx.rw == 0)
              ref_tx.data = tx.addr + 8'h01;
            else
              ref_tx.data = tx.data;
            
            #2;  // 模拟计算延迟
            ref2sb_mb.put(ref_tx);
            $display("[RefModel] 参考结果: addr=0x%02h data=0x%02h",
                     ref_tx.addr, ref_tx.data);
            disable wait_drive;
          end
        end
      end
    join
    
    // 让Driver先取出事务
    #1;
  end
endtask

// ============================================================
// Scoreboard：比较结果
// ============================================================
task run_scoreboard();
  $display("[Scoreboard] 启动");
  
  forever begin
    transaction actual_tx, expected_tx;
    
    // 从两个通道获取数据
    fork
      begin : get_actual
        mon2sb_mb.get(actual_tx);
      end
      begin : get_expected
        ref2sb_mb.get(expected_tx);
      end
      begin : sb_timeout
        #200;
        $display("[Scoreboard] 等待超时");
        disable get_actual;
        disable get_expected;
      end
    join_any
    
    sb_checked++;
    
    // 比较
    if (actual_tx.addr == expected_tx.addr &&
        actual_tx.data == expected_tx.data) begin
      pass_count++;
      $display("[Scoreboard] PASS #%0d: addr=0x%02h data=0x%02h",
               sb_checked, actual_tx.addr, actual_tx.data);
    end else begin
      fail_count++;
      $display("[Scoreboard] FAIL #%0d: actual(addr=0x%02h data=0x%02h) " +
               "vs expected(addr=0x%02h data=0x%02h)",
               sb_checked, actual_tx.addr, actual_tx.data,
               expected_tx.addr, expected_tx.data);
    end
    
    // 检查是否全部比较完成
    if (sb_checked >= total_sent) begin
      $display("[Scoreboard] 全部比较完成");
      ->all_checked;
    end
  end
endtask

// ============================================================
// 简化DUT行为模型
// ============================================================
task run_dut_model();
  // 简化DUT：收到请求后2个周期返回响应
  forever begin
    @(posedge clk);
    if (req_valid) begin
      req_ready = 1;
      #10;
      rsp_valid = 1;
      rsp_data  = req_addr + 8'h01;  // 简单行为
      @(posedge clk);
      rsp_valid = 0;
      req_ready = 0;
    end
  end
endtask

// ============================================================
// 主线程：搭建并启动验证平台
// ============================================================
initial begin : tb_main
  $display("============================================");
  $display("  模块5.3: 验证平台典型架构");
  $display("============================================");
  
  // 初始化
  gen2drv_mb = new();
  mon2sb_mb  = new();
  ref2sb_mb  = new();
  rst_n      = 0;
  req_valid  = 0;
  rsp_valid  = 0;
  req_ready  = 0;
  total_sent = 0;
  pass_count = 0;
  fail_count = 0;
  sb_checked = 0;
  
  // 复位
  #20;
  rst_n = 1;
  $display("[TB] 复位完成\n");
  
  // 启动所有组件（并行后台运行）
  fork
    run_dut_model();     // join_none 启动
  join_none
  
  fork
    run_generator(5);    // 生成5个事务
  join_none
  
  fork
    run_driver();
  join_none
  
  fork
    run_monitor();
  join_none
  
  fork
    run_ref_model();
  join_none
  
  fork
    run_scoreboard();
  join_none
  
  // 等待测试完成
  $display("[TB] 等待测试完成...\n");
  
  fork
    // 正常完成
    begin
      wait(all_checked.triggered);
      #10;  // 等待pipeline排空
    end
    // 超时保护
    begin
      #500;
      $display("[TB] 仿真超时！");
    end
  join_any
  
  // 清理所有后台线程
  disable fork;
  
  // 最终报告
  $display("\n============================================");
  $display("  验证结果报告");
  $display("============================================");
  $display("  总发送事务: %0d", total_sent);
  $display("  总比较事务: %0d", sb_checked);
  $display("  通过: %0d", pass_count);
  $display("  失败: %0d", fail_count);
  if (fail_count == 0 && sb_checked > 0)
    $display("  结果: ALL PASS");
  else
    $display("  结果: HAS FAILURES");
  $display("============================================");
  
  $finish;
end
