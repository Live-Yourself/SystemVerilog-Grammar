// 知识点20: 过程块 (Procedural Blocks)
// 演示initial块、always块的不同形式和应用场景

module procedural_blocks;

  // ========== 信号定义 ==========
  logic        clk;           // 时钟信号
  logic        rst_n;         // 复位信号(低有效)
  logic [7:0]  counter;       // 计数器
  logic [3:0]  state;         // 状态寄存器
  int          sim_time;      // 仿真时间
  
  // ========== 参数定义 ==========
  parameter CLK_PERIOD = 10;  // 时钟周期
  
  // ============================================================
  // 一、initial块 - 只执行一次
  // ============================================================
  
  // initial块在仿真开始时执行一次，然后永远挂起
  initial begin
    $display("========================================");
    $display("    过程块 (Procedural Blocks) 示例");
    $display("========================================\n");
    
    $display("【一、initial块特点】");
    $display("  - 仿真开始时执行一次");
    $display("  - 执行完毕后永远挂起");
    $display("  - 用于初始化、测试激励");
    $display("  - 多个initial块并行执行");
    $display("");
  end
  
  // 初始化initial块
  initial begin
    // 初始化信号
    clk     = 0;
    rst_n   = 0;
    counter = 0;
    state   = 0;
    sim_time = 0;
    
    $display("【二、initial块 - 初始化】");
    $display("  信号初始化完成");
    $display("  clk=%b, rst_n=%b, counter=%0d", clk, rst_n, counter);
    $display("");
  end
  
  // 测试激励initial块
  initial begin
    // 等待初始化完成
    #5;
    
    $display("【三、initial块 - 测试激励】");
    $display("  仿真时间: %0t", $time);
    $display("");
    
    // 复位序列
    $display("  复位序列开始...");
    #10 rst_n = 1;  // 释放复位
    $display("    [%0t] rst_n = 1 (复位释放)", $time);
    
    // 等待几个时钟周期
    #50;
    
    $display("");
    $display("  仿真运行中...");
    $display("    [%0t] counter = %0d", $time, counter);
    
    // 继续仿真
    #100;
    
    $display("");
    $display("  仿真结束");
    $display("    [%0t] 最终 counter = %0d", $time, counter);
    $display("");
    
    $display("========================================");
    $display("         示例运行完成");
    $display("========================================");
    
    $finish;
  end
  
  // ============================================================
  // 二、always块 - 重复执行
  // ============================================================
  
  // always块在仿真期间无限循环执行
  
  // 1. always_comb - 组合逻辑块 (SystemVerilog推荐)
  // 自动推断敏感列表，仿真结束后检查稳定性
  logic [7:0] next_counter;
  
  always_comb begin
    // 组合逻辑：计算下一状态
    next_counter = counter + 1;
  end
  
  // 2. always_ff - 时序逻辑块 (SystemVerilog推荐)
  // 用于寄存器建模，只在时钟边沿触发
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 0;
      state   <= 0;
    end else begin
      counter <= counter + 1;
      if (counter == 10)
        state <= state + 1;
    end
  end
  
  // 3. always_latch - 锁存器逻辑块 (SystemVerilog推荐)
  // 用于电平敏感的锁存器
  logic latch_en;
  logic [7:0] latch_data;
  logic [7:0] latched_val;
  
  initial begin
    latch_en = 0;
    latch_data = 0;
  end
  
  always_latch begin
    if (latch_en)
      latched_val <= latch_data;
  end
  
  // 4. 传统always块 - Verilog风格
  // 需要手动指定敏感列表
  
  // 组合逻辑风格
  logic [7:0] sum;
  logic [7:0] a_in, b_in;
  
  initial begin
    a_in = 5;
    b_in = 10;
  end
  
  always @(*) begin  // 或 always @(a_in, b_in)
    sum = a_in + b_in;
  end
  
  // 时序逻辑风格
  logic [7:0] reg_a;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reg_a <= 0;
    else
      reg_a <= sum;
  end
  
  // ============================================================
  // 三、时钟生成
  // ============================================================
  
  // 方式1: initial + forever
  initial begin
    forever begin
      #(CLK_PERIOD/2) clk = ~clk;
    end
  end
  
  // 方式2: always块 (更简洁)
  // always #(CLK_PERIOD/2) clk = ~clk;
  
  // ============================================================
  // 四、多个initial/always块的执行顺序
  // ============================================================
  
  initial begin
    #1;
    $display("");
    $display("【四、过程块执行顺序】");
    $display("  多个initial/always块并行执行");
    $display("  执行顺序不确定，由调度器决定");
    $display("  使用#延迟控制时序");
    $display("");
  end
  
  // ============================================================
  // 五、过程块对比汇总
  // ============================================================
  
  initial begin
    #2;
    $display("【五、过程块对比】");
    $display("");
    $display("  ┌──────────────┬─────────────────────────────────┐");
    $display("  │ 过程块       │ 特点                            │");
    $display("  ├──────────────┼─────────────────────────────────┤");
    $display("  │ initial      │ 执行一次，用于初始化/测试        │");
    $display("  │ always       │ 无限循环，需指定敏感列表         │");
    $display("  │ always_comb  │ 组合逻辑，自动敏感列表           │");
    $display("  │ always_ff    │ 时序逻辑，边沿触发               │");
    $display("  │ always_latch │ 锁存器，电平敏感                 │");
    $display("  └──────────────┴─────────────────────────────────┘");
    $display("");
    $display("  SystemVerilog推荐使用:");
    $display("    - always_comb  替代 always @(*)");
    $display("    - always_ff    替代 always @(posedge clk)");
    $display("    - always_latch 用于锁存器建模");
    $display("");
  end

endmodule
