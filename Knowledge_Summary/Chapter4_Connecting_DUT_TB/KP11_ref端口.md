# 知识点11: ref端口

| 特性 | 说明 |
|------|------|
| **书中小节** | 4.9 |
| **核心关键字** | `ref` |
| **主要作用** | 实现引用传递，提高效率和灵活性 |

## 11.1 ref端口基本概念

**ref端口**是SystemVerilog中的一种特殊端口类型，它使用**引用传递**方式传递参数，而不是传统的**值传递**。

```
┌─────────────────────────────────────────────────────────────┐
│                    值传递 vs 引用传递                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   值传递 (input/output/inout):                               │
│   ┌─────────────────────────────────────────┐              │
│   │  调用者              被调用模块           │              │
│   │  ┌─────┐            ┌─────┐             │              │
│   │  │data │ ──复制──► │data'│             │              │
│   │  │ 10  │            │ 10  │             │              │
│   │  └─────┘            └─────┘             │              │
│   │                      修改不影响原变量    │              │
│   └─────────────────────────────────────────┘              │
│                                                             │
│   引用传递 (ref):                                            │
│   ┌─────────────────────────────────────────┐              │
│   │  调用者              被调用模块           │              │
│   │  ┌─────┐            ┌─────┐             │              │
│   │  │data │ ═══共享═══►│data │             │              │
│   │  │ 10  │            │ 10  │             │              │
│   │  └─────┘            └─────┘             │              │
│   │          修改会直接影响原变量            │              │
│   └─────────────────────────────────────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 11.2 端口类型对比

| 端口类型 | 传递方式 | 方向 | 复制开销 | 适用场景 |
|----------|----------|------|----------|----------|
| `input` | 值传递 | 单向（入） | 有 | 只读输入 |
| `output` | 值传递 | 单向（出） | 有 | 输出结果 |
| `inout` | 值传递 | 双向 | 有 | 双向总线 |
| `ref` | 引用传递 | 双向 | **无** | 高效数据传递 |
| `const ref` | 只读引用 | 单向（入） | **无** | 只读高效传递 |

## 11.3 ref端口的基本语法

```systemverilog
// 模块定义使用ref端口
module my_module (
  ref logic [7:0] shared_data,    // 引用传递
  const ref logic [7:0] cfg_reg, // 只读引用
  input logic clk
);
  // 可以直接读写shared_data
  always @(posedge clk) begin
    shared_data <= shared_data + 1;  // 直接修改外部变量
  end
endmodule
```

## 11.4 ref端口与interface结合使用

**ref端口最常用的场景是与interface结合**，实现高效的接口传递。

```systemverilog
// 定义接口
interface bus_if;
  logic [7:0] data;
  logic       valid;
  logic       ready;
  
  modport MASTER (output data, valid, input ready);
  modport SLAVE  (input data, valid, output ready);
endinterface

// 使用ref传递interface
module dut (
  ref bus_if.MASTER bus    // 引用传递interface
);
  always @(posedge clk) begin
    bus.data  <= data_reg;
    bus.valid <= 1'b1;
  end
endmodule
```

## 11.5 ref端口的优势

| 优势 | 说明 |
|------|------|
| **效率优势** | 对大型数据结构效率高 |
| **实时同步** | 修改立即对所有引用者可见 |
| **简化连接** | 无需显式传递大量端口信号 |

## 11.6 ref端口与task/function

**ref不仅用于端口，也常用于task和function参数**。

```systemverilog
module ref_example;
  // 使用ref传递参数
  task automatic swap(ref int a, ref int b);
    int temp;
    temp = a;
    a    = b;
    b    = temp;
  endtask
  
  // 使用const ref（只读引用）
  function automatic int sum_array(const ref int arr[]);
    sum_array = 0;
    foreach (arr[i])
      sum_array += arr[i];
  endfunction
endmodule
```

## 11.7 ref端口的注意事项

### 1. 不能对网络类型(net)使用ref

```systemverilog
module net_example;
  wire [7:0] net_sig;       // wire是net类型
  
  // ✗ 错误：不能对net类型使用ref
  // module sub (ref wire [7:0] sig);
  
  // ✓ 正确：ref只能用于变量类型
  logic [7:0] var_sig;      // logic是变量类型
  module sub (ref logic [7:0] sig);
endmodule
```

### 2. ref不可综合（重要）

**ref端口是验证专用特性，不可综合！**

| 应用场景 | ref可用性 | 原因 |
|----------|-----------|------|
| **RTL设计（可综合）** | ✗ 不可用 | 综合工具不支持引用传递 |
| **验证平台（testbench）** | ✓ 推荐使用 | 仅用于仿真，无需综合 |
| **行为级建模** | ✓ 可用 | 纯仿真模型 |

```systemverilog
// ✗ 错误：RTL设计中使用ref（不可综合）
module rtl_adder (
  ref logic [31:0] a,    // 综合工具会报错！
  ref logic [31:0] b,
  ref logic [31:0] sum
);
  assign sum = a + b;
endmodule

// ✓ 正确：RTL设计使用传统端口
module rtl_adder (
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] sum
);
  assign sum = a + b;
endmodule
```

### 3. ref与传统端口的使用场景选择

| 场景 | 推荐方式 | 原因 |
|------|----------|------|
| **RTL设计（可综合代码）** | input/output | 可综合，符合硬件建模 |
| **双向总线** | inout + wire | 支持三态，符合硬件特性 |
| **验证环境中的interface传递** | **ref** | 高效，避免复制 |
| **共享计数器/状态变量** | **ref** | 多模块实时同步 |
| **大型数组/结构体传递** | **ref** | 避免复制开销 |
| **只读访问大数据** | **const ref** | 高效+保护数据 |

```
选择决策树:

需要传递数据到模块？
│
├─ 是双向总线？
│   └─ 是 → 使用 inout + wire
│
├─ 是RTL设计（需要综合）？
│   └─ 是 → 使用 input/output（传统方式）
│
├─ 需要传递大型数据结构？
│   └─ 是 → 使用 ref（验证环境）
│
└─ 只读访问大型数据？
    └─ 是 → 使用 const ref
```

### 4. ref与inout的区别

| 特性 | ref | inout |
|------|-----|-------|
| **传递方式** | 引用传递 | 值传递 |
| **适用类型** | 变量(variable) | 网络(net)和变量 |
| **可综合性** | **不可综合** | 可综合 |
| **典型用途** | 验证环境数据传递 | RTL双向总线 |

## 11.8 关键要点总结

| 要点 | 说明 |
|------|------|
| **传递方式** | 引用传递，不复制数据 |
| **效率优势** | 对大型数据结构效率高 |
| **实时同步** | 修改立即对所有引用者可见 |
| **适用类型** | 只能用于变量类型，不能用于net |
| **不可综合** | **仅用于验证环境，RTL设计不能使用** |
| **const ref** | 只读引用，保护数据不被修改 |
| **典型应用** | 传递interface、共享变量、大型数据结构 |
| **场景选择** | RTL用传统端口，验证环境用ref |

## 示例文件

参见: `Code_Examples/Chapter4_Connecting_DUT_TB/11_ref_port.sv`
