# KP03 coverpoint 与自动分箱

## 核心概念

`coverpoint` 是 covergroup 中的基本采样单元，指定要跟踪统计的变量。如果在 coverpoint 中**不显式定义 bin**，仿真器会自动生成 **auto_bin**（自动分箱）。

## 1. coverpoint 的声明

```systemverilog
covergroup MyCov;
  coverpoint variable_name;   // 最简声明,使用自动分箱
endgroup
```

每个 coverpoint 只能指定一个变量。一个 covergroup 内可以包含多个 coverpoint，`sample()` 时所有 coverpoint 同时采样。

## 2. 自动分箱（auto_bin）的生成规则

| 情况 | 默认行为 |
|------|----------|
| 变量值域 <= 64 | 每个可能值一个 bin（共 N 个 bin） |
| 变量值域 > 64 | 值域均匀分成 64 个区间 |

例如：

```systemverilog
bit [2:0] cmd;    // 值域 0~7,共 8 个值 → 自动生成 auto[0]~auto[7]
bit [7:0] addr;   // 值域 0~255 > 64 → 自动生成 64 个区间
```

自动分箱的 bin 名称统一为 `auto[0]`、`auto[1]`、`auto[2]` ...

## 3. iff 条件（选择性采样）

`iff` 用于控制"什么时候采样"，仅在条件为真时才将当前值计入覆盖率：

```systemverilog
coverpoint addr iff (valid);   // 仅当 valid==1 时采样
coverpoint data iff (en && rdy); // 仅当 en 和 rdy 都为真时采样
```

典型场景：仅在事务有效时采样、仅在复位释放后采样。

## 4. auto_bin_max 选项

通过 `option.auto_bin_max` 调整自动分箱的最大数量：

```systemverilog
coverpoint cmd {
  option.auto_bin_max = 4;   // 将值域均匀分成 4 个区间
}
```

当 `cmd` 值域为 0~7 时，4 个 bin 的划分结果：
- `auto[0]` = {0, 1}
- `auto[1]` = {2, 3}
- `auto[2]` = {4, 5}
- `auto[3]` = {6, 7}

## 5. 自动分箱的局限性

自动分箱虽然方便，但**粒度往往不符合验证需求**。例如对于命令字、状态码等离散枚举值，自动分箱无法区分"合法值"和"无效值"，也无法按功能含义分组。因此在实际项目中，通常会使用下一节介绍的**自定义 bin**。

## 示例代码说明

配套示例代码 `03_coverpoint_auto_bin.sv` 演示了：

1. **自动分箱生成**：3 位 `cmd` 变量自动生成 8 个 bin，每个覆盖一个值
2. **iff 条件采样**：仅当 `valid==1` 时才采样 `addr`，`valid=0` 的事务被跳过
3. **auto_bin_max 调整**：将 `cmd` 的 8 个值划分为 4 个区间

> **编译运行**：执行 `run_sv.bat Code_Examples/Chapter9_Coverage/03_coverpoint_auto_bin.sv` 即可。
