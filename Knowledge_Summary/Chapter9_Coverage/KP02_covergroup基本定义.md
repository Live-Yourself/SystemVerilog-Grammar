# KP02 covergroup 基本定义

## 核心概念

`covergroup` 是定义功能覆盖率的语法结构。它定义了一套"覆盖率模板"，通过 `new()` 实例化后，调用 `sample()` 对数据进行采样统计。

## 1. covergroup 的语法结构

```systemverilog
covergroup GroupName;
  coverpoint variable_name {
    // bin 定义
  }
endgroup
```

- `covergroup` / `endgroup`：定义覆盖率组的边界
- `coverpoint`：指定要跟踪采样的变量（下一节详细讲解）
- `bin`：将变量的值划分成若干区间，每个区间就是一个"桶"，统计该区间是否被命中

## 2. covergroup 的使用流程（三步）

```systemverilog
// 第一步: 定义 (已经通过 covergroup 语法定义好)
// 第二步: 实例化
MyCovGroup cov_inst = new();

// 第三步: 采样
cov_inst.sample();   // 将当前变量的值记录到对应的 bin 中
```

`sample()` 是 SystemVerilog 自动生成的方法，调用时覆盖组内所有 coverpoint 会同时采样。

## 3. 在类中嵌入 covergroup（推荐用法）

这是验证平台中最常见的用法。将 covergroup 定义在类内部，覆盖率与数据天然绑定：

```systemverilog
class BusTransaction;
  rand bit [7:0] addr;

  covergroup AddrCov;       // 在类中定义
    coverpoint addr { ... }
  endgroup

  function new();
    AddrCov = new();        // 构造时自动实例化
  endfunction

  function void sample_cov();
    AddrCov.sample();       // 封装采样调用
  endfunction
endclass
```

优势：对象创建时覆盖组自动就绪，通过类方法封装 `sample()` 调用，使用简洁。

## 4. 独立 covergroup

也可以在类外部独立定义 covergroup，然后手动实例化和采样：

```systemverilog
covergroup DataCovGroup;
  coverpoint data { ... }
endgroup

// 使用
DataCovGroup cov = new();
cov.sample();
```

## 5. covergroup 是"类型"

一个 covergroup 定义就是一个类型，可以创建**多个实例**，每个实例的覆盖率**独立统计**：

```systemverilog
DataCovGroup cov1 = new();   // 实例1,独立统计
DataCovGroup cov2 = new();   // 实例2,独立统计
```

## 示例代码说明

配套示例代码 `02_covergroup_basic.sv` 演示了：

1. **类中嵌入 covergroup**：在 `BusTransaction` 类内部定义 `AddrCov`，构造函数中自动实例化
2. **独立 covergroup**：外部定义 `DataCovGroup`，手动实例化和采样
3. **多实例独立性**：同一个 covergroup 类型创建多个实例，覆盖率各自独立

> **编译运行**：执行 `run_sv.bat Code_Examples/Chapter9_Coverage/02_covergroup_basic.sv` 即可。
