//=============================================================================
// 文件名: 10_systemverilog_assertion.sv
// 章节: 第4章 连接设计和测试平台
// 知识点: 10. SystemVerilog断言(SVA)
// 说明: 演示立即断言、并发断言、序列和属性的使用
//=============================================================================

//-----------------------------------------------------------------------------
// 示例1: 立即断言(Immediate Assertion)
//-----------------------------------------------------------------------------
module example1_immediate_assertion (
  input  logic [7:0] data_in,
  input  logic       valid,
  output logic [7:0] data_out
);
  // 立即断言：在组合逻辑中检查条件
  always_comb begin
    // 基本立即断言
    assert (data_in < 200)
      else $error("数据超出范围: data_in=%0d", data_in);
  end
  
  // 带成功和失败分支的立即断言
  always @(posedge valid) begin
    assert (data_in != 0) begin
      // 断言成功时执行
      $display("[PASS] data_in = %0d (非零)", data_in);
    end
    else begin
      // 断言失败时执行
      $error("[FAIL] data_in 不能为 0");
    end
  end
  
  // 使用 $warning 的断言
  always_comb begin
    assert (data_out >= 0 && data_out <= 255)
      else $warning("输出可能异常: data_out=%0d", data_out);
  end
  
  assign data_out = valid ? data_in : 8'h00;
  
endmodule

//-----------------------------------------------------------------------------
// 示例2: 基本并发断言(Concurrent Assertion)
//-----------------------------------------------------------------------------
module example2_concurrent_assertion (
  input  logic clk,
  input  logic rst_n,
  input  logic req,
  input  logic ack
);
  // 最基本的并发断言
  // 要求：req后1个周期必须收到ack
  assert property (@(posedge clk) req |-> ##1 ack)
    else $error("[并发断言] 请求后未收到应答");
  
  // 带复位的并发断言
  assert property (@(posedge clk) disable iff (!rst_n) req |-> ##1 ack)
    else $error("[带复位断言] 复位后请求未得到应答");
  
  // 使用序列定义
  sequence req_ack_seq;
    req ##1 ack;
  endsequence
  
  assert property (@(posedge clk) req_ack_seq)
    else $error("[序列断言] req_ack序列未匹配");
    
endmodule

//-----------------------------------------------------------------------------
// 示例3: 序列运算符演示
//-----------------------------------------------------------------------------
module example3_sequence_operators (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic done,
  input  logic busy,
  input  logic error
);
  // ##n - 固定延迟
  sequence fixed_delay;
    start ##1 done;  // start后1周期done
  endsequence
  
  // ##[a:b] - 范围延迟
  sequence range_delay;
    start ##[1:3] done;  // start后1~3周期内done
  endsequence
  
  // ##[a:$] - 无限延迟
  sequence unbounded_delay;
    start ##[1:$] done;  // start后至少1周期done
  endsequence
  
  // [*n] - 连续重复
  sequence consecutive_repeat;
    busy [*3];  // busy连续3个周期
  endsequence
  
  // [*m:n] - 范围重复
  sequence range_repeat;
    busy [*1:5];  // busy连续1~5个周期
  endsequence
  
  // [->n] - 非连续重复(直到第n次)
  sequence goto_repeat;
    error [->2];  // error非连续出现2次
  endsequence
  
  // [=n] - 非连续出现n次
  sequence non_consecutive;
    error [=2];  // error总共出现2次
  endsequence
  
  // 实例化断言
  assert property (@(posedge clk) disable iff (!rst_n) fixed_delay)
    else $error("fixed_delay 失败");
    
  assert property (@(posedge clk) disable iff (!rst_n) range_delay)
    else $error("range_delay 失败");
    
endmodule

//-----------------------------------------------------------------------------
// 示例4: 蕴含操作符
//-----------------------------------------------------------------------------
module example4_implication_operators (
  input  logic clk,
  input  logic rst_n,
  input  logic a,
  input  logic b
);
  // |-> 重叠蕴含: a发生时b必须同时发生
  property overlap_implication;
    @(posedge clk) disable iff (!rst_n)
      a |-> b;
  endproperty
  
  // |=> 非重叠蕴含: a发生后下一周期b必须发生
  property non_overlap_implication;
    @(posedge clk) disable iff (!rst_n)
      a |=> b;
  endproperty
  
  assert property (overlap_implication)
    else $error("重叠蕴含失败: a=1时b!=1");
    
  assert property (non_overlap_implication)
    else $error("非重叠蕴含失败: a后下一周期b!=1");
    
endmodule

//-----------------------------------------------------------------------------
// 示例5: 组合操作符
//-----------------------------------------------------------------------------
module example5_combination_operators (
  input  logic clk,
  input  logic rst_n,
  input  logic a,
  input  logic b,
  input  logic c,
  input  logic d
);
  // and: 两个序列同时发生
  sequence seq_and;
    a ##1 b and c ##1 d;  // 两个序列同时完成
  endsequence
  
  // or: 两个序列至少一个发生
  sequence seq_or;
    a ##1 b or c ##1 d;  // 任一序列完成即可
  endsequence
  
  // intersect: 两个序列同时开始且同时结束
  sequence seq_intersect;
    (a ##[1:3] b) intersect (c ##[1:3] d);
  endsequence
  
  // throughout: 整个期间保持某条件
  sequence seq_throughout;
    a throughout (b ##1 c ##1 d);  // a在整个序列期间保持为1
  endsequence
  
  // within: 一个序列在另一个序列期间发生
  sequence seq_within;
    (b ##1 c) within (a ##1 b ##1 c ##1 d);  // b##c在a..d期间发生
  endsequence
  
  assert property (@(posedge clk) disable iff (!rst_n) seq_or)
    else $error("seq_or 失败");
    
endmodule

//-----------------------------------------------------------------------------
// 示例6: not和until操作符
//-----------------------------------------------------------------------------
module example6_not_until_operators (
  input  logic clk,
  input  logic rst_n,
  input  logic error,
  input  logic busy,
  input  logic done
);
  // not: 断言某序列不发生
  property no_error;
    @(posedge clk) disable iff (!rst_n)
      not error;  // error不应该发生
  endproperty
  
  // until: a保持直到b发生
  property busy_until_done;
    @(posedge clk) disable iff (!rst_n)
      busy until done;  // busy保持直到done发生
  endproperty
  
  // s_until: 严格until，b必须发生
  property busy_strict_until_done;
    @(posedge clk) disable iff (!rst_n)
      busy s_until done;  // busy保持直到done发生，done必须发生
  endproperty
  
  assert property (no_error)
    else $error("检测到error信号！");
    
  assert property (busy_until_done)
    else $error("busy未保持到done");
    
endmodule

//-----------------------------------------------------------------------------
// 示例7: 请求-应答协议断言
//-----------------------------------------------------------------------------
interface req_ack_if;
  logic clk;
  logic rst_n;
  logic req;
  logic ack;
  logic [7:0] data;
  
  // 请求后必须在1~3个周期内得到应答
  property req_ack_timing;
    @(posedge clk) disable iff (!rst_n)
      req |-> ##[1:3] ack;
  endproperty
  
  // 无应答时不能发起新请求
  property no_new_req_before_ack;
    @(posedge clk) disable iff (!rst_n)
      req |-> !req until ack;
  endproperty
  
  // 断言实例化
  assert property (req_ack_timing)
    else $error("[协议错误] 请求后1~3周期未收到应答");
    
  assert property (no_new_req_before_ack)
    else $error("[协议错误] 应答前发起新请求");
    
endinterface

module example7_req_ack_protocol (
  req_ack_if bus
);
  // DUT逻辑
  always_ff @(posedge bus.clk or negedge bus.rst_n) begin
    if (!bus.rst_n)
      bus.ack <= 0;
    else if (bus.req && !bus.ack)
      bus.ack <= 1;  // 延迟1周期响应
    else
      bus.ack <= 0;
  end
  
endmodule

//-----------------------------------------------------------------------------
// 示例8: FIFO断言
//-----------------------------------------------------------------------------
module example8_fifo_assertions #(
  parameter DEPTH = 4
)(
  input  logic clk,
  input  logic rst_n,
  input  logic wr_en,
  input  logic rd_en,
  input  logic full,
  input  logic empty,
  input  logic [7:0] wr_data,
  input  logic [7:0] rd_data
);
  // 满时不能写
  property no_write_when_full;
    @(posedge clk) disable iff (!rst_n)
      full |-> !wr_en;
  endproperty
  
  // 空时不能读
  property no_read_when_empty;
    @(posedge clk) disable iff (!rst_n)
      empty |-> !rd_en;
  endproperty
  
  // 写数据不能是X或Z
  property valid_write_data;
    @(posedge clk) disable iff (!rst_n)
      wr_en |-> !$isunknown(wr_data);
  endproperty
  
  // 读数据不能是X或Z（非空时）
  property valid_read_data;
    @(posedge clk) disable iff (!rst_n)
      (rd_en && !empty) |-> !$isunknown(rd_data);
  endproperty
  
  // 实例化断言
  assert property (no_write_when_full)
    else $error("[FIFO错误] 满时尝试写入");
    
  assert property (no_read_when_empty)
    else $error("[FIFO错误] 空时尝试读取");
    
  assert property (valid_write_data)
    else $error("[FIFO错误] 写入数据为未知态");
    
  assert property (valid_read_data)
    else $error("[FIFO错误] 读出数据为未知态");
    
endmodule

//-----------------------------------------------------------------------------
// 示例9: 状态机断言
//-----------------------------------------------------------------------------
module example9_fsm_assertions (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic done
);
  typedef enum logic [1:0] {
    IDLE   = 2'b00,
    ACTIVE = 2'b01,
    DONE   = 2'b10
  } state_t;
  
  state_t state, next_state;
  
  // 状态转换逻辑
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  always_comb begin
    case (state)
      IDLE:   next_state = start ? ACTIVE : IDLE;
      ACTIVE: next_state = done  ? DONE   : ACTIVE;
      DONE:   next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end
  
  // 状态转换断言
  property idle_to_active;
    @(posedge clk) disable iff (!rst_n)
      (state == IDLE && start) |=> (state == ACTIVE);
  endproperty
  
  property active_to_done;
    @(posedge clk) disable iff (!rst_n)
      (state == ACTIVE && done) |=> (state == DONE);
  endproperty
  
  property done_to_idle;
    @(posedge clk) disable iff (!rst_n)
      (state == DONE) |=> (state == IDLE);
  endproperty
  
  // 任何状态只能转换到合法状态
  property valid_state_transition;
    @(posedge clk) disable iff (!rst_n)
      $onehot0(state) && 
      (state inside {IDLE, ACTIVE, DONE});
  endproperty
  
  assert property (idle_to_active)
    else $error("[FSM错误] IDLE->ACTIVE转换失败");
    
  assert property (active_to_done)
    else $error("[FSM错误] ACTIVE->DONE转换失败");
    
  assert property (done_to_idle)
    else $error("[FSM错误] DONE->IDLE转换失败");
    
  assert property (valid_state_transition)
    else $error("[FSM错误] 非法状态值");
    
endmodule

//-----------------------------------------------------------------------------
// 示例10: 功能覆盖率
//-----------------------------------------------------------------------------
module example10_functional_coverage (
  input  logic       clk,
  input  logic [7:0] addr,
  input  logic       wr_en,
  input  logic       rd_en,
  input  logic [7:0] wdata
);
  // 检查写操作是否发生
  cover property (@(posedge clk) wr_en)
    $display("[覆盖] 检测到写操作");
  
  // 检查读操作是否发生
  cover property (@(posedge clk) rd_en)
    $display("[覆盖] 检测到读操作");
  
  // 检查特定地址范围是否被访问
  cover property (@(posedge clk) addr inside {[0:63]})
    $display("[覆盖] 访问了地址范围0-63");
    
  cover property (@(posedge clk) addr inside {[64:127]})
    $display("[覆盖] 访问了地址范围64-127");
  
  // 检查连续写操作
  sequence burst_write;
    wr_en [*3];
  endsequence
  
  cover property (@(posedge clk) burst_write)
    $display("[覆盖] 检测到连续3次写操作");
  
  // 检查读后写序列
  sequence read_after_write;
    rd_en ##[1:5] wr_en;
  endsequence
  
  cover property (@(posedge clk) read_after_write)
    $display("[覆盖] 检测到读后写序列");
    
endmodule

//-----------------------------------------------------------------------------
// SVA 总结
//-----------------------------------------------------------------------------
/*
┌─────────────────────────────────────────────────────────────────────────┐
│                    SystemVerilog断言(SVA)总结                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  断言类型:                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  立即断言: assert (条件)          // 过程块中立即执行            │   │
│  │  并发断言: assert property (...)   // 基于时钟持续监控           │   │
│  │  假设断言: assume property (...)   // 约束输入                  │   │
│  │  覆盖断言: cover property (...)    // 功能覆盖率                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  常用运算符:                                                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ##n        延迟n周期              |->    重叠蕴含              │   │
│  │  ##[a:b]    延迟a~b周期            |=>    非重叠蕴含            │   │
│  │  [*n]       连续重复n次            not    否定                  │   │
│  │  [->n]      非连续重复             until  保持直到              │   │
│  │  and/or     组合操作               disable iff  禁用条件        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  最佳实践:                                                              │
│  1. 在接口中定义断言，提高可重用性                                      │
│  2. 使用disable iff处理复位                                            │
│  3. 提供有意义的错误信息                                                │
│  4. 结合cover收集功能覆盖率                                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
*/
