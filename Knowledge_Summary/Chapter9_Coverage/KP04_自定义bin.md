# KP04 自定义 bin

## 核心概念

自动分箱（auto_bin）粒度固定，无法按验证需求灵活划分。自定义 bin 让验证工程师精确控制值域分组，并区分"关心的值"、"不关心的值"和"非法值"。

## 1. 显式 bin 定义

### 单值 bin
```systemverilog
bins b_zero = {0};      // 仅当变量值为 0 时命中
```

### 值范围 bin
```systemverilog
bins b_short = {[1:4]};      // 值在 1~4 之间命中
bins b_range = {[1:3], [5:7]}; // 多个范围用逗号拼接
```

### 枚举范围 bin
```systemverilog
bins b_burst = {[CMD_BURST_R : CMD_BURST_W]};  // 两个连续枚举值归为一个 bin
```

### 多值组合
```systemverilog
bins b_special = {0, 15, 255};   // 列举多个离散值
```

## 2. default bin

`default bin` 捕获**所有未被其他显式 bin 覆盖的值**。它是一个"兜底"机制，确保不会遗漏未预期的值：

```systemverilog
coverpoint status {
  bins b_ok   = {0};
  bins b_err  = {1};
  default bin b_others;   // status 为 2~15 时全部落入此处
}
```

**注意**：default bin 不影响其他 bin 的覆盖率计算。它只是一个"观测窗口"，帮助你发现是否有未预期的值出现。

## 3. ignore_bins（忽略值）

`ignore_bins` 告诉仿真器"这些值可能出现，但我不关心，不要统计它们"：

```systemverilog
coverpoint addr {
  bins b_low  = {[0:31]};
  bins b_high = {[32:63]};
  ignore_bins ig_reserved = {[64:127]};  // 高地址区域,忽略
}
```

效果：
- 被 ignore 的值**不计入覆盖率分母**——覆盖率只按有效 bin 计算
- 不影响仿真运行，不会报错
- 典型场景：保留地址空间、测试模式下的特殊值

## 4. illegal_bins（非法值）

`illegal_bins` 告诉仿真器"这些值绝对不应该出现，如果出现就是 bug"：

```systemverilog
coverpoint cmd {
  bins b_read  = {CMD_READ};
  bins b_write = {CMD_WRITE};
  illegal_bins b_reserved = {3'b110, 3'b111};  // 保留命令码
}
```

效果：
- 仿真过程中一旦采样到非法值，仿真器**立即报严重错误**
- illegal_bins 的值也不计入覆盖率分母
- 典型场景：保留的状态码、不应出现的命令、无效的配置值

## 5. ignore_bins vs illegal_bins 对比

| 特性 | ignore_bins | illegal_bins |
|------|-------------|--------------|
| 值是否允许出现 | 允许，但忽略 | 不允许 |
| 采样到时的行为 | 静默跳过 | 报告运行时错误 |
| 是否计入覆盖率分母 | 否 | 否 |
| 典型用途 | 保留值域、不关心的范围 | 硬件设计中非法的状态/命令 |

## 示例代码说明

配套示例代码 `04_custom_bins.sv` 演示了：

1. **单值 bin + 范围 bin**：每个命令一个 bin，突发读/写合并为一个范围 bin
2. **illegal_bins**：保留的命令码 110/111 被标记为非法
3. **default bin**：status 未被显式覆盖的值（3~15）全部落入 default
4. **ignore_bins**：高地址区域 96~127 被忽略，不影响覆盖率计算

> **编译运行**：执行 `run_sv.bat Code_Examples/Chapter9_Coverage/04_custom_bins.sv` 即可。
