# KP05 交叉覆盖 cross

## 核心概念

单个 coverpoint 只能跟踪一个变量。但验证中经常需要关注**多个变量的组合**是否都被覆盖到，例如"读操作 + 单字传输"这种组合是否出现过。`cross` 用于捕获多个 coverpoint 之间的值组合覆盖情况。

## 1. 基本语法

```systemverilog
covergroup MyCov;
  coverpoint op;      // 覆盖点 A
  coverpoint size;    // 覆盖点 B

  cross op, size;     // A 和 B 的交叉覆盖
endgroup
```

`cross` 引用的是 coverpoint 的名称（不是变量名），对参与交叉的各个 coverpoint 的 bin 做**笛卡尔积**。

## 2. 自动交叉分箱

如果 `op` 有 3 个 bin，`size` 有 4 个 bin，`cross op, size` 自动生成 3 x 4 = **12 个交叉 bin**：

```
auto[0]  = b_read  x b_byte
auto[1]  = b_read  x b_half
auto[2]  = b_read  x b_word
auto[3]  = b_read  x b_dword
auto[4]  = b_write x b_byte
...
auto[11] = b_burst x b_dword
```

只有当某次采样同时命中了对应的两个 bin 时，该交叉 bin 才算被覆盖。

## 3. 自定义交叉 bin

当自动交叉分箱数量过多，或者只关注特定组合时，可以用 `binsof` 自定义：

```systemverilog
cross op, size {
  // 指定两个条件都满足的组合
  bins read_word = binsof(op.b_read) && binsof(size.b_word);

  // binsof(cp) 不指定 bin 名 → 匹配该 coverpoint 的所有 bin
  bins write_any = binsof(op.b_write) && binsof(size);
}
```

`binsof()` 的两种用法：

| 写法 | 含义 |
|------|------|
| `binsof(cp.b_xxx)` | 仅匹配 coverpoint `cp` 中名为 `b_xxx` 的 bin |
| `binsof(cp)` | 匹配 coverpoint `cp` 的所有 bin |

多个条件用 `&&` 连接，表示"同时满足"。

## 4. 交叉覆盖中的 ignore / illegal

在 cross 内也可以使用 `ignore_bins` 和 `illegal_bins`，用于排除不需要或不允许的组合：

```systemverilog
cross op, size {
  ignore_bins ig_no_burst_read = binsof(op.b_read) && binsof(size.b_dword);
  illegal_bins il_burst_byte   = binsof(op.b_burst) && binsof(size.b_byte);
}
```

## 5. 交叉覆盖的价值

交叉覆盖是功能覆盖率中最有价值的部分之一。单个变量覆盖率达到 100% 并不意味着组合场景也被覆盖。例如 op 和 size 各自 100%，但可能 "burst + byte" 的组合从未出现，只有交叉覆盖才能发现这类缺口。

**典型场景**：操作码 x 地址空间、读/写 x 数据长度、请求类型 x 响应状态。

## 示例代码说明

配套示例代码 `05_cross_coverage.sv` 演示了：

1. **自动交叉分箱**：op（3 bin）x size（4 bin）= 12 种组合的笛卡尔积
2. **自定义交叉 bin**：使用 `binsof(op.b_read) && binsof(size.b_word)` 指定关注的组合
3. **binsof 的两种写法**：指定具体 bin 名 vs 匹配所有 bin

> **编译运行**：执行 `run_sv.bat Code_Examples/Chapter9_Coverage/05_cross_coverage.sv` 即可。
