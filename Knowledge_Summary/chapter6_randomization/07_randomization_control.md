# 6.7 随机化的控制

## 核心概念

在前面的章节中我们已经接触过 `constraint_mode()` 和 `rand_mode()`（6.4 节）。本节对其进行系统性总结，并补充局部变量随机化、动态约束开关以及性能考量等内容。随机化的控制能力让我们可以在运行时灵活地调整验证策略，是构建高效测试平台的关键技术。

> 注意：6.4 节已经演示了 `constraint_mode` 和 `rand_mode` 的基本用法，本节在此基础上进行更深入的讲解，避免内容重复。

## 1. constraint_mode() —— 约束的动态开关

### 对象级控制

```systemverilog
// 禁用/启用对象的所有约束
pkt.constraint_mode(0);  // 禁用全部约束
pkt.constraint_mode(1);  // 启用全部约束

// 禁用/启用单个约束块
pkt.c_addr_range.constraint_mode(0);  // 只禁用 c_addr_range
pkt.c_addr_range.constraint_mode(1);  // 只启用 c_addr_range
```

### 典型应用场景

- **分层测试**：基础测试启用所有约束，压力测试禁用部分约束扩大随机范围
- **错误注入**：禁用正常行为的约束，启用错误约束
- **调试**：逐步禁用约束定位约束冲突问题

### 与 inline 约束的对比

| 特性 | constraint_mode | inline 约束 (with) |
|------|----------------|-------------------|
| 作用域 | 对象级别，持续生效 | 仅本次 randomize() 调用 |
| 是否修改类 | 否 | 否 |
| 可叠加 | 多个 constraint_mode 同时生效 | 每次调用独立 |
| 适用场景 | 长期切换验证模式 | 临时调整个别值 |

## 2. rand_mode() —— 随机变量的动态开关

```systemverilog
// 禁用/启用对象的所有 rand 变量
pkt.rand_mode(0);  // 禁用全部随机化
pkt.rand_mode(1);  // 启用全部随机化

// 禁用/启用单个 rand 变量
pkt.addr.rand_mode(0);  // addr 不再随机，保持当前值
pkt.addr.rand_mode(1);  // addr 恢复随机
```

### 关键细节

- `rand_mode(0)` 后，该变量保持**当前值**不变（不是默认值）
- `rand_mode(0)` 后，对该变量的约束**仍会被求解器检查**，如果当前值违反约束，随机化失败
- 因此禁用某变量前，应确保其当前值满足所有约束，或者同时禁用相关约束

### 典型应用

```systemverilog
// 固定地址，随机数据
pkt.addr = 32'h1000;
pkt.addr.rand_mode(0);   // addr 固定为 0x1000
pkt.randomize();          // 只随机化 data 等其他变量
pkt.addr.rand_mode(1);   // 恢复
```

## 3. 局部变量的随机化

`randomize()` 可以传入参数，只随机化指定的变量。这在需要**精确控制**哪些变量参与随机化时非常有用。

### 基本语法

```systemverilog
// 只随机化 data，其余变量保持当前值
pkt.randomize(data);
```

### 与 rand_mode 的区别

| 特性 | randomize(data) | data.rand_mode(0) |
|------|----------------|------------------|
| 作用范围 | 仅本次调用 | 持续到恢复 |
| 其他变量 | 保持当前值（不受约束影响） | 保持当前值（仍受约束检查） |
| 返回值 | 可检查 | 正常 randomize 返回值 |
| 适用场景 | 临时控制 | 长期固定 |

### 传入非成员变量

```systemverilog
class Test;
  rand bit [7:0] a, b;
endclass

bit [7:0] x, y;  // 局部变量（非类成员）

Test t = new();
// 随机化 a, b 和局部变量 x, y
t.randomize(a, b, x, y);
```

`randomize()` 可以随机化非类成员的局部变量，只要在参数列表中指定即可。

## 4. 动态约束构建

除了用 `constraint_mode` 开关约束块，还可以在 `with` 中动态构建约束逻辑。

### 使用 with 传递外部变量

```systemverilog
bit [7:0] target_addr;
target_addr = 8'hAB;

// 外部变量 target_addr 参与 inline 约束
pkt.randomize() with { addr == target_addr; };
```

### 根据 testbench 状态动态调整约束

```systemverilog
class Env;
  bit is_error_test;  // 测试模式标志

  task run_test();
    Transaction pkt = new();
    if (is_error_test) begin
      pkt.randomize() with { inject_err == 1; err_type inside {[1:5]}; };
    end else begin
      pkt.randomize();  // 使用默认约束
    end
  endtask
endclass
```

## 5. 随机化的性能考虑

### 约束求解的复杂性

约束求解器的性能取决于约束的复杂度。以下情况可能导致性能问题：

- **数组过大**：动态数组 size 上限过高（如 `[0:1024]`）
- **强交叉约束**：多个随机变量之间有复杂的相互依赖
- **唯一性约束**：N 个元素的唯一性约束需要 N*(N-1)/2 个不等式
- **条件约束过多**：大量 if-else 嵌套

### 优化建议

- 合理设置数组大小范围，避免过大的上限
- 使用 `solve...before` 引导求解方向，减少回溯
- 避免在 `foreach` 中使用复杂的条件逻辑
- 对于大数组，考虑在 `post_randomize()` 中处理而非用约束
- 禁用不需要的约束（`constraint_mode`）可以减少求解负担

### 监控求解性能

```systemverilog
initial begin
  // 仿真命令行参数控制
  if ($value$plusargs("RANDOM_DEBUG", debug)) begin
    // 在 VCS 中可使用 -randomize_debug 查看求解过程
  end
end
```

## 总结

| 控制方法 | 作用 | 作用范围 | 适用场景 |
|---------|------|---------|---------|
| `constraint_mode()` | 开关约束 | 对象级/约束块级 | 切换验证模式、调试 |
| `rand_mode()` | 开关随机化 | 对象级/变量级 | 固定某些变量 |
| `randomize(vars)` | 指定随机化变量 | 本次调用 | 精确控制随机化范围 |
| `with { ... }` | 添加临时约束 | 本次调用 | 临时调整、传外部变量 |
