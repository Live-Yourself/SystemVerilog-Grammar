//============================================================
// 文件名: 03_modport.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 4.2 Modport端口分组
// 说明: 演示Modport定义信号方向、区分不同视角的方法
//============================================================

// ==================== 基本Modport定义 ====================
// 接口包含多个modport，为不同模块提供不同视角
interface basic_bus_if;
  // 信号声明
  logic        clk;
  logic        rst_n;
  logic [7:0]  addr;
  logic [7:0]  wdata;
  logic [7:0]  rdata;
  logic        write;    // 1=写, 0=读
  logic        valid;
  logic        ready;
  
  // ========== Modport定义 ==========
  
  // 测试平台视角(TEST)
  // - 驱动激励信号
  // - 接收响应信号
  modport TEST (
    output addr, wdata, write, valid,
    input  rdata, ready, clk, rst_n
  );
  
  // DUT视角(DUT)
  // - 接收激励信号
  // - 发送响应信号
  modport DUT (
    input  addr, wdata, write, valid, clk, rst_n,
    output rdata, ready
  );
  
  // 监控器视角(MONITOR)
  // - 只读所有信号
  modport MONITOR (
    input addr, wdata, rdata, write, valid, ready, clk, rst_n
  );
  
endinterface


// ==================== 使用Modport的DUT ====================
// 方式1: 在端口列表中指定modport
module modport_dut(basic_bus_if.DUT bus);
  // 内部存储器
  logic [7:0] mem [0:255];
  
  // 注意：bus.addr, bus.wdata, bus.valid, bus.write 都是输入
  //       bus.rdata, bus.ready 都是输出
  
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n) begin
      bus.rdata <= 8'h00;
      bus.ready <= 1'b0;
    end
    else if (bus.valid) begin
      if (bus.write) begin
        mem[bus.addr] <= bus.wdata;
        $display("[%0t] DUT写入: addr=0x%02h, data=0x%02h", 
                 $time, bus.addr, bus.wdata);
      end
      else begin
        bus.rdata <= mem[bus.addr];
        $display("[%0t] DUT读取: addr=0x%02h, data=0x%02h", 
                 $time, bus.addr, bus.rdata);
      end
      bus.ready <= 1'b1;
    end
    else begin
      bus.ready <= 1'b0;
    end
  end
endmodule


// ==================== 使用Modport的测试平台 ====================
module modport_tb(basic_bus_if.TEST bus);
  
  initial begin
    $display("===== Modport使用示例 =====");
    $display("TEST modport: addr/wdata/write/valid为输出, rdata/ready为输入");
    $display("");
    
    // 初始化 - 这些都是TEST modport的output信号
    bus.addr  = 8'h00;
    bus.wdata = 8'h00;
    bus.write = 1'b0;
    bus.valid = 1'b0;
    
    // 等待复位释放
    @(posedge bus.rst_n);
    $display("[%0t] 检测到复位释放", $time);
    
    // 写操作
    repeat(2) begin
      @(posedge bus.clk);
      bus.addr  = $urandom_range(0, 15);
      bus.wdata = $urandom_range(0, 255);
      bus.write = 1'b1;
      bus.valid = 1'b1;
      
      @(posedge bus.clk);
      bus.valid = 1'b0;
      
      wait(bus.ready);  // 等待DUT响应
    end
    
    // 读操作
    bus.write = 1'b0;
    repeat(2) begin
      @(posedge bus.clk);
      bus.addr  = $urandom_range(0, 15);
      bus.valid = 1'b1;
      
      wait(bus.ready);
      $display("[%0t] TB收到: addr=0x%02h, rdata=0x%02h", 
               $time, bus.addr, bus.rdata);
      
      @(posedge bus.clk);
      bus.valid = 1'b0;
    end
    
    $display("\n===== 测试完成 =====");
    #10 $finish;
  end
endmodule


// ==================== 使用Modport的监控器 ====================
module modport_monitor(basic_bus_if.MONITOR bus);
  // MONITOR modport所有信号都是input，只能观察
  
  always @(posedge bus.clk) begin
    if (bus.valid && bus.ready) begin
      if (bus.write)
        $display("[Monitor] 写操作: addr=0x%02h, data=0x%02h", 
                 bus.addr, bus.wdata);
      else
        $display("[Monitor] 读操作: addr=0x%02h, data=0x%02h", 
                 bus.addr, bus.rdata);
    end
  end
endmodule


// ==================== 顶层模块 ====================
module top_modport_demo;
  // 实例化接口
  basic_bus_if bus();
  
  // 时钟和复位生成
  initial begin
    bus.clk = 0;
    forever #5 bus.clk = ~bus.clk;
  end
  
  initial begin
    bus.rst_n = 0;
    #20 bus.rst_n = 1;
  end
  
  // 实例化各模块，使用对应的modport
  modport_dut     dut     (bus.DUT);      // DUT使用DUT modport
  modport_tb      tb      (bus.TEST);     // TB使用TEST modport
  modport_monitor monitor (bus.MONITOR);  // Monitor使用MONITOR modport
  
endmodule


// ==================== Modport编译检查演示 ====================
// 演示modport的方向检查功能
interface check_bus_if;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  
  modport MASTER (output data, valid, input ready);
  modport SLAVE  (input  data, valid, output ready);
endinterface

// 主设备模块
module master_module(check_bus_if.MASTER bus);
  // bus.data和bus.valid是output，可以赋值
  // bus.ready是input，只能读取
  
  initial begin
    bus.data  = 8'hAA;  // OK: data是output
    bus.valid = 1'b1;   // OK: valid是output
    
    // 读取ready信号
    wait(bus.ready);    // OK: ready是input，可以读取
    
    $display("Master: 收到ready响应");
  end
endmodule

// 从设备模块
module slave_module(check_bus_if.SLAVE bus);
  // bus.data和bus.valid是input，只能读取
  // bus.ready是output，可以赋值
  
  initial begin
    wait(bus.valid);    // OK: valid是input，可以读取
    
    // 读取data信号
    $display("Slave: 收到data=0x%02h", bus.data);  // OK
    
    bus.ready = 1'b1;   // OK: ready是output
  end
endmodule

/*
// 错误示例：方向不匹配会编译报错
module wrong_master(check_bus_if.MASTER bus);
  initial begin
    // 错误！ready是input，不能赋值
    bus.ready = 1'b1;  // 编译错误！
  end
endmodule

module wrong_slave(check_bus_if.SLAVE bus);
  initial begin
    // 错误！data是input，不能赋值
    bus.data = 8'h55;  // 编译错误！
  end
endmodule
*/


// ==================== 完整的APB风格接口示例 ====================
// 宨际项目中常用的总线接口结构
interface apb_bus_if #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32);
  // APB总线信号
  logic                       pclk;
  logic                       preset_n;
  logic [ADDR_WIDTH-1:0]      paddr;
  logic                       psel;
  logic                       penable;
  logic                       pwrite;
  logic [DATA_WIDTH-1:0]      pwdata;
  logic [DATA_WIDTH-1:0]      prdata;
  logic                       pready;
  logic                       pslverr;
  
  // APB主设备视角
  modport MASTER (
    output paddr, psel, penable, pwrite, pwdata,
    input  pclk, preset_n, prdata, pready, pslverr
  );
  
  // APB从设备视角
  modport SLAVE (
    input  pclk, preset_n, paddr, psel, penable, pwrite, pwdata,
    output prdata, pready, pslverr
  );
  
  // APB监控器视角
  modport MONITOR (
    input pclk, preset_n, paddr, psel, penable, pwrite, 
          pwdata, prdata, pready, pslverr
  );
  
endinterface


// APB从设备示例
module apb_slave(apb_bus_if.SLAVE bus);
  logic [31:0] mem [0:255];
  
  // APB协议状态机
  typedef enum logic [1:0] {
    IDLE,
    SETUP,
    ACCESS
  } state_t;
  
  state_t state;
  
  always_ff @(posedge bus.pclk or negedge bus.preset_n) begin
    if (!bus.preset_n) begin
      state      <= IDLE;
      bus.prdata <= 32'h0;
      bus.pready <= 1'b1;
      bus.pslverr <= 1'b0;
    end
    else begin
      case (state)
        IDLE: begin
          if (bus.psel && !bus.penable) begin
            state <= SETUP;
          end
        end
        
        SETUP: begin
          if (bus.psel && bus.penable) begin
            state <= ACCESS;
            if (bus.pwrite) begin
              mem[bus.paddr[7:0]] <= bus.pwdata;
              $display("[%0t] APB写: addr=0x%08h, data=0x%08h",
                       $time, bus.paddr, bus.pwdata);
            end
            else begin
              bus.prdata <= mem[bus.paddr[7:0]];
              $display("[%0t] APB读: addr=0x%08h, data=0x%08h",
                       $time, bus.paddr, mem[bus.paddr[7:0]]);
            end
          end
        end
        
        ACCESS: begin
          state <= IDLE;
        end
        
        default: state <= IDLE;
      endcase
    end
  end
endmodule


// APB主设备示例
module apb_master(apb_bus_if.MASTER bus);
  
  initial begin
    // 初始化
    bus.paddr   = 32'h0;
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
    bus.pwrite  = 1'b0;
    bus.pwdata  = 32'h0;
    
    wait(bus.preset_n);
    $display("===== APB总线示例 =====");
    
    // 写操作
    @(posedge bus.pclk);
    bus.paddr  = 32'h0000_0010;
    bus.pwdata = 32'hDEAD_BEEF;
    bus.pwrite = 1'b1;
    bus.psel   = 1'b1;       // SETUP阶段
    
    @(posedge bus.pclk);
    bus.penable = 1'b1;      // ACCESS阶段
    
    @(posedge bus.pclk);
    bus.psel    = 1'b0;      // 完成传输
    bus.penable = 1'b0;
    
    // 读操作
    @(posedge bus.pclk);
    bus.paddr  = 32'h0000_0010;
    bus.pwrite = 1'b0;
    bus.psel   = 1'b1;
    
    @(posedge bus.pclk);
    bus.penable = 1'b1;
    
    @(posedge bus.pclk);
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
    
    $display("[%0t] 读回数据: 0x%08h", $time, bus.prdata);
    $display("===== APB示例完成 =====\n");
    
    #20 $finish;
  end
endmodule


// APB顶层
module top_apb;
  apb_bus_if bus();
  
  initial begin
    bus.pclk = 0;
    forever #5 bus.pclk = ~bus.pclk;
  end
  
  initial begin
    bus.preset_n = 0;
    #20 bus.preset_n = 1;
  end
  
  apb_slave  u_slave (bus.SLAVE);
  apb_master u_master(bus.MASTER);
endmodule


// ==================== 仿真配置 ====================
/*
仿真说明:

1. 运行 top_modport_demo:
   - 演示三种modport的使用: TEST, DUT, MONITOR
   - 每个模块看到不同的信号方向

2. 运行 top_apb:
   - 演示完整的APB总线接口
   - MASTER和SLAVE modport的实际应用

要点总结:
  - modport为不同模块定义不同的信号视角
  - 编译器会检查信号方向是否正确
  - MASTER modport: 输出地址/数据/控制信号
  - SLAVE modport: 输出响应信号
  - MONITOR modport: 所有信号都是输入(只读)
*/
