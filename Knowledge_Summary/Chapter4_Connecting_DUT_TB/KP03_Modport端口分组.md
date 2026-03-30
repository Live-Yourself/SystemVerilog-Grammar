# 知识点3: Modport端口分组

| 特性 | 说明 |
|------|------|
| **书中小节** | 4.2 |
| **核心关键字** | `modport` |
| **主要作用** | 定义信号方向、区分不同视角 |

## 3.1 Modport基本概念

**Modport**(Module Port)用于在接口中定义信号的方向，为不同的模块提供不同的视角。

### 为什么需要Modport？

```
问题场景:
┌─────────────┐         ┌─────────────┐
│  Testbench  │         │     DUT     │
│             │         │             │
│  data  ─────┼────────►│ data (输入) │  同一个信号
│  valid ─────┼────────►│ valid(输入) │  不同视角
│  ready ◄────┼─────────│ ready(输出) │
│             │         │             │
└─────────────┘         └─────────────┘

Testbench视角: data/valid是输出, ready是输入
DUT视角:       data/valid是输入, ready是输出

Modport解决方案:
┌──────────────────────────────────────────────────────────┐
│                      interface bus_if                    │
│                                                          │
│   modport TEST (output data, valid, input ready);        │
│   modport DUT  (input  data, valid, output ready);       │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## 3.2 Modport基本语法

```systemverilog
interface 接口名;
  // 信号声明
  logic signal1, signal2, signal3;
  
  // Modport定义
  modport 名称1 (方向1 信号列表1, 方向2 信号列表2, ...);
  modport 名称2 (方向1 信号列表1, 方向2 信号列表2, ...);
  
endinterface
```

## 3.3 信号方向定义

| 方向关键字 | 说明 | 对应Verilog |
|-----------|------|-------------|
| `input` | 输入信号 | input |
| `output` | 输出信号 | output |
| `inout` | 双向信号 | inout |
| `ref` | 引用传递(传引用) | - (SV特有) |

## 3.4 Modport使用示例

```systemverilog
interface bus_if;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  logic       clk;
  
  // 测试平台视角
  modport TEST (
    output data, valid,
    input  ready, clk
  );
  
  // DUT视角
  modport DUT (
    input  data, valid, clk,
    output ready
  );
  
  // 监控器视角(只读)
  modport MONITOR (
    input data, valid, ready, clk
  );
endinterface
```

## 3.5 Modport的优点

| 优点 | 说明 |
|------|------|
| **方向明确** | 编译器检查信号方向，防止误连接 |
| **多视角支持** | 同一接口可为不同模块定义不同视角 |
| **可读性强** | 清晰表达每个模块看到的接口 |
| **编译时检查** | 方向不匹配会在编译时报错 |

## 3.6 典型应用场景

```
┌─────────────────────────────────────────────────────────────┐
│                     典型验证架构                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    ┌─────────────┐                          │
│                    │  Testbench  │                          │
│                    │  (TEST)     │                          │
│                    └──────┬──────┘                          │
│                           │                                 │
│                           ▼                                 │
│              ┌────────────────────────┐                     │
│              │      Interface         │                     │
│              │  ┌──────────────────┐  │                     │
│              │  │ TEST modport     │  │                     │
│              │  │ DUT  modport     │  │                     │
│              │  │ MONITOR modport  │  │                     │
│              │  └──────────────────┘  │                     │
│              └────────┬───────────────┘                     │
│                       │                                     │
│          ┌────────────┼────────────┐                        │
│          │            │            │                        │
│          ▼            ▼            ▼                        │
│    ┌─────────┐  ┌─────────┐  ┌─────────┐                   │
│    │   DUT   │  │ Monitor │  │  其他    │                   │
│    │ (DUT)   │  │(MONITOR)│  │ (自定义) │                   │
│    └─────────┘  └─────────┘  └─────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 3.7 Modport实例化方式

```systemverilog
// 方式1: 在端口列表中使用modport
module dut(bus_if.DUT bus);  // 使用DUT modport
  // bus.data是输入, bus.ready是输出
endmodule

// 方式2: 在模块内部指定
module dut(bus_if bus);
  // 使用 bus.TB.data 或 bus.DUT.data
endmodule
```

## 3.8 关键要点总结

| 要点 | 说明 |
|------|------|
| **定义位置** | 在interface内部定义 |
| **语法格式** | `modport 名称 (方向 信号, ...);` |
| **方向类型** | input, output, inout, ref |
| **使用方式** | `interface名.modport名` |
| **编译检查** | 方向不匹配会报编译错误 |

## 示例文件

参见: `Code_Examples/Chapter4_Connecting_DUT_TB/03_modport.sv`
