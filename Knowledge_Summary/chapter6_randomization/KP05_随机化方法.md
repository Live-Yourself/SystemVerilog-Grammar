# 6.5 随机化方法

## 核心概念

随机化方法是控制"何时随机化"以及"随机化前后做什么"的机制。前面几节讲了 rand/randc 声明和 constraint 约束的编写，本节聚焦于**随机化的执行层面**。

## 1. randomize() 函数

`randomize()` 是触发随机化的核心函数，对所有 rand/randc 变量按照约束求解并赋值。

### 基本用法

```systemverilog
class Packet;
  rand bit [7:0] addr;
  rand bit [7:0] data;
  constraint c_addr { addr inside {[0:15]}; }
endclass

Packet pkt = new();
if (pkt.randomize()) begin
  $display("addr=%0d, data=%0d", pkt.addr, pkt.data);
end else begin
  $error("随机化失败！");
end
```

### 关键要点

- 返回值：成功返回 1，失败返回 0（约束冲突导致无解）
- **必须检查返回值**：忽略返回值可能导致使用未有效随机化的数据
- 每次调用 `randomize()` 会为所有启用的 rand/randc 变量重新求解

### inline 约束（with 语句）

`randomize() with { ... }` 可以在调用时添加额外的内联约束，无需修改类定义：

```systemverilog
// 临时强制 addr=5，其余约束不变
pkt.randomize() with { addr == 5; };

// 临时添加约束
pkt.randomize() with { addr > 10; data < 50; };
```

- inline 约束与类内约束**合并求解**，二者共同生效
- 如果产生冲突（inline 与类内硬约束矛盾），随机化失败
- inline 约束可以覆盖类内的软约束（soft）

## 2. pre_randomize() 和 post_randomize() 回调函数

这两个是 SystemVerilog 提供的**自动回调函数**，分别在随机化求解前后自动执行。

### pre_randomize()

- 在 `randomize()` 开始求解约束之前自动调用
- 典型用途：为随机化准备环境（如初始化非随机变量、调整约束条件）

### post_randomize()

- 在 `randomize()` 成功求解并赋值之后自动调用
- 典型用途：根据随机结果计算派生值、打印调试信息、更新覆盖率

```systemverilog
class Transaction;
  rand bit [7:0] addr;
  rand bit [7:0] data;
       bit [7:0] checksum;  // 非随机，由 post_randomize 计算

  function void pre_randomize();
    $display("[PRE] 准备随机化...");
  endfunction

  function void post_randomize();
    checksum = addr ^ data;  // 根据随机结果计算校验和
    $display("[POST] addr=0x%02h, data=0x%02h, checksum=0x%02h",
             addr, data, checksum);
  endfunction
endclass
```

### 注意事项

- 如果 `randomize()` 失败（返回 0），`post_randomize()` **不会被调用**
- `pre_randomize()` 无论成功与否都会被调用
- 这两个函数中**不应**修改 rand/randc 变量的值（会导致不可预测行为）

## 3. 随机化失败的处理

当约束之间互相矛盾，求解器无法找到满足所有约束的解时，随机化失败。

### 常见失败原因

- 约束之间互相冲突（如 `a > 10` 且 `a < 5`）
- inline 约束与类内约束冲突
- 数组唯一性约束的范围过小（要求 100 个唯一值但范围只有 0-9）
- randc 变量的候选值已耗尽

### 处理策略

```systemverilog
// 策略1：检查返回值并处理
if (!pkt.randomize()) begin
  $warning("随机化失败，使用默认值");
  pkt.addr = 0;
  pkt.data = 0;
end

// 策略2：禁用部分约束后重试
pkt.c_strict.constraint_mode(0);  // 禁用严格约束
if (!pkt.randomize()) begin
  $error("即使放宽约束仍然失败");
end
pkt.c_strict.constraint_mode(1);  // 恢复
```

## 4. 随机化种子（seed）控制

种子决定了随机数序列的起点。相同种子产生相同的随机序列。

### 设置种子

```systemverilog
// 方法1：在仿真选项中设置（推荐，保证整个仿真可复现）
// 命令行: +ntb_random_seed=12345

// 方法2：代码中设置
process p = process::self();
p.srandom(12345);  // 为当前进程设置种子
```

### 种子的重要性

- **可复现性**：相同种子 + 相同代码 + 相同工具 = 完全相同的随机序列
- **调试**：发现 bug 后用相同种子重跑，可稳定复现问题
- **回归测试**：每次回归使用相同种子，确保结果一致性
- **换种子**：一次回归通过后，更换种子再做一轮，增加覆盖

## 总结

| 方法 | 作用 | 使用场景 |
|------|------|---------|
| `randomize()` | 执行随机化求解 | 每次生成新事务时调用 |
| `randomize() with {}` | 添加临时约束 | 特定测试场景需要额外约束 |
| `pre_randomize()` | 随机化前回调 | 准备环境、初始化变量 |
| `post_randomize()` | 随机化后回调 | 计算派生值、收集覆盖率 |
| `srandom()` | 设置随机种子 | 调试复现、回归测试 |
