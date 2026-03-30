# 知识点10: SystemVerilog断言(SVA)

| 特性 | 说明 |
|------|------|
| **书中小节** | 4.8 |
| **核心概念** | 立即断言、并发断言、序列、属性 |
| **主要作用** | 自动检测设计正确性，提高验证效率和覆盖率 |

## 10.1 断言的基本概念

**断言(Assertion)** 是用于检查设计行为的声明性代码。当设计行为与预期不符时，断言会自动报告错误。

### 断言的优势

| 优势 | 说明 |
|------|------|
| **声明式语法** | 简洁直观 |
| **自动持续监控** | 无需手动编写检查代码 |
| **详细失败信息** | 提供具体的错误位置和原因 |
| **功能覆盖率** | 可收集功能覆盖率 |

## 10.2 断言的类型

| 类型 | 关键字 | 执行时机 | 典型用途 |
|------|--------|----------|----------|
| **立即断言** | `assert` | 立即执行 | 过程块中的即时检查 |
| **并发断言** | `assert property` | 时钟驱动 | 时序行为的持续监控 |
| **假设断言** | `assume property` | 时钟驱动 | 约束输入行为 |
| **覆盖断言** | `cover property` | 时钟驱动 | 功能覆盖率收集 |

## 10.3 立即断言(Immediate Assertion)

立即断言在过程块中立即执行，类似于 `if` 语句。

```systemverilog
module immediate_assertion_example (
  input  logic [7:0] data,
  input  logic       valid
);
  // 立即断言：检查当前状态
  always_comb begin
    assert (data < 100) 
      else $error("data超出范围: data=%0d", data);
  end
  
  // 带有成功和失败处理的立即断言
  always @(posedge valid) begin
    assert (data != 0) begin
      // 断言成功时执行
      $display("断言成功: data=%0d", data);
    end
    else begin
      // 断言失败时执行
      $error("断言失败: data不能为0");
    end
  end
endmodule
```

## 10.4 并发断言(Concurrent Assertion)

并发断言基于时钟持续监控，用于检查时序行为。

```systemverilog
module concurrent_assertion_example (
  input  logic clk,
  input  logic rst_n,
  input  logic req,
  input  logic ack
);
  // 最简单的并发断言
  assert property (@(posedge clk) req |-> ##1 ack)
    else $error("请求没有得到应答");

  // 带复位的断言
  assert property (@(posedge clk) disable iff (!rst_n) req |-> ##1 ack)
    else $error("复位后请求未得到应答");
endmodule
```

## 10.5 序列运算符

| 运算符 | 含义 | 示例 |
|--------|------|------|
| `##n` | 延迟n个时钟周期 | `##1` (下一周期) |
| `##[a:b]` | 延迟a到b个周期 | `##[1:3]` (1~3周期内) |
| `##[a:$]` | 延迟至少a个周期 | `##[1:$]` (至少1周期) |
| `a \|-> b` | a发生则b立即开始 | `req \|-> ack` |
| `a \|=> b` | a发生则b下一周期开始 | `req \|=> ack` |
| `a [*n]` | a连续重复n次 | `valid [*3]` |
| `a [*m:n]` | a连续重复m~n次 | `valid [*1:5]` |
| `a [->n]` | a非连续重复n次 | `ack [->3]` |
| `a and b` | a和b同时发生 | `req and ack` |
| `a or b` | a或b发生 | `done or timeout` |
| `not a` | a不发生 | `not error` |
| `a until b` | a保持直到b发生 | `busy until done` |

## 10.6 常用断言模式

### 模式1: 请求-应答协议

```systemverilog
property req_ack;
  @(posedge clk) disable iff (!rst_n)
    req |-> ##[1:3] ack;
endproperty

assert property (req_ack)
  else $error("请求未得到应答");
```

### 模式2: FIFO满/空检查

```systemverilog
// FIFO满时不能写入
assert property (@(posedge clk) full |-> !wr_en)
  else $error("FIFO满时尝试写入");

// FIFO空时不能读取
assert property (@(posedge clk) empty |-> !rd_en)
  else $error("FIFO空时尝试读取");
```

### 模式3: 有效数据检查

```systemverilog
// valid为高时，data不能为X或Z
assert property (@(posedge clk) valid |-> !$isunknown(data))
  else $error("有效数据为未知态");
```

## 10.7 常用概念详解

| 概念 | 含义 | 典型用途 |
|------|------|----------|
| `disable iff (条件)` | 条件为真时禁用断言 | 复位期间禁用检查 |
| `$isunknown(expr)` | 检查是否包含X或Z | 验证数据有效性 |
| `assert property (...)` | 直接定义并断言 | 简单、一次性断言 |
| `property...endproperty` | 定义可重用的属性模板 | 复杂逻辑、多处引用 |

## 10.8 关键要点总结

| 要点 | 说明 |
|------|------|
| **立即断言** | 过程块中立即执行，`assert (条件)` |
| **并发断言** | 基于时钟持续监控，`assert property (...)` |
| **序列** | 描述时序行为，`sequence ... endsequence` |
| **属性** | 封装序列和逻辑，`property ... endproperty` |
| **延迟操作** | `##n` 延迟n周期，`##[a:b]` 延迟a到b周期 |
| **蕴含操作** | `\|->` 重叠蕴含，`\|=>` 非重叠蕴含 |
| **重复操作** | `[*n]` 连续重复，`[->n]` 非连续重复 |
| **disable iff** | 禁用条件，通常用于复位 |

## 示例文件

参见: `Code_Examples/Chapter4_Connecting_DUT_TB/10_systemverilog_assertion.sv`
