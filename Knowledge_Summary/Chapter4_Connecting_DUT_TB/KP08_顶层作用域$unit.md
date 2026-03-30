# 知识点8: 顶层作用域$unit

| 特性 | 说明 |
|------|------|
| **书中小节** | 4.6 |
| **核心概念** | 编译单元作用域、$unit声明、全局可见性 |
| **主要作用** | 在多个模块间共享声明，实现真正的全局定义 |

## 8.1 $unit 基本概念

**$unit** 是SystemVerilog中的**编译单元作用域**(Compilation Unit Scope)，它代表编译单元的顶层作用域，位于所有模块、接口、程序块之外。

```
┌─────────────────────────────────────────────────────────────┐
│                    $unit 编译单元作用域                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   $unit (编译单元顶层作用域)                                 │
│   ├── 参数定义: parameter WIDTH = 8;                        │
│   ├── 类型定义: typedef logic [7:0] byte_t;                 │
│   ├── 常量定义: const int MAX_VALUE = 100;                  │
│   ├── 变量定义: logic global_signal;                        │
│   └── 函数定义: function void global_task();                │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │  module dut (...);                                  │  │
│   │  interface bus_if (...);                            │  │
│   │  program tb (...);                                  │  │
│   │  package my_pkg (...);                              │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
│   $unit中的声明对所有模块、接口、程序块可见                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 8.2 $unit 的定义方式（重要）

**$unit 没有专门的语法关键字！** 这是理解 $unit 的关键。

### package 与 $unit 的定义方式对比

| 特性 | package | $unit |
|------|---------|-------|
| **定义语法** | `package 名称 ... endpackage` | **无专门语法**，文件顶层自动属于$unit |
| **作用域边界** | 有明确的 `package` 和 `endpackage` | 文件中所有模块之外的区域 |
| **使用时** | 需要 `import 包名::` 或 `包名::` | 自动可见（同一编译单元内） |

```systemverilog
// ========== package 需要显式定义 ==========
package my_pkg;
  parameter WIDTH = 8;           // 必须在 package...endpackage 内
  typedef logic [7:0] byte_t;
endpackage

// ========== $unit 是隐式的，直接定义 ==========
// 没有 $unit...endunit 这样的语法！
// 只要在模块外定义，就自动属于 $unit

parameter WIDTH = 8;              // 这就是 $unit 中的声明！
typedef logic [7:0] byte_t;       // 这也是 $unit 中的声明！

// 以下是模块定义，上面的声明都在模块之外
module dut;
  // 这里的代码属于模块作用域，不是 $unit
  logic [WIDTH-1:0] data;         // 使用 $unit 中的 WIDTH
endmodule
```

### $unit 作用域的识别

```
┌─────────────────────────────────────────────────────────────┐
│  文件结构示例：识别 $unit 作用域                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  // ===== 这里是 $unit 作用域（文件顶层，模块之外）=====      │
│                                                             │
│  `timescale 1ns/1ps           // 编译指令                    │
│  parameter P1 = 10;            // $unit 参数                 │
│  typedef logic [7:0] data_t;   // $unit 类型                 │
│  const int MAX = 100;          // $unit 常量                 │
│                                                             │
│  function void debug();        // $unit 函数                 │
│    $display("debug");                                        │
│  endfunction                                                │
│                                                             │
│  // ===== 以下是模块定义（模块作用域）=====                   │
│                                                             │
│  module dut;                 // 模块开始                    │
│    // 这里是模块内部作用域                                   │
│    data_t signal;            // 使用 $unit 的类型            │
│  endmodule                   // 模块结束                    │
│                                                             │
│  // ===== 模块结束后，又回到 $unit 作用域 =====               │
│                                                             │
│  parameter P2 = 20;           // 还是 $unit 参数             │
│                                                             │
│  module tb;                  // 另一个模块                   │
│    // 模块内部                                               │
│  endmodule                                                  │
│                                                             │
│  // 文件结束，整个文件顶层的声明都属于 $unit                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**核心要点**：任何在文件中、所有模块/接口/程序块之外的定义，都自动属于 `$unit`。它不需要像 `package` 那样的显式包装语法。

## 8.3 $unit 与 package 的对比

| 特性 | $unit | package |
|------|-------|---------|
| **定义方式** | 文件顶层直接声明 | `package ... endpackage` |
| **可见性** | 自动可见（同编译单元） | 需显式`import` |
| **作用域** | 编译单元范围 | 显式引用范围 |
| **命名冲突** | 易产生冲突 | 可通过`::`限定 |
| **可维护性** | 较差 | 较好 |
| **推荐程度** | 谨慎使用 | 推荐使用 |

## 8.4 使用 $unit 的注意事项

### 1. 避免全局变量

```systemverilog
// ❌ 不推荐：$unit中的全局变量可能导致竞争
logic global_data;

module driver;
  initial global_data = 8'hAA;  // 驱动1
endmodule

module monitor;
  initial $display("data = %h", global_data);  // 可能读到X
endmodule

// ✓ 推荐：使用接口或参数传递
```

### 2. 编译顺序依赖

```systemverilog
// 文件A.sv
parameter WIDTH = 8;  // $unit中的定义

// 文件B.sv
module dut;
  logic [WIDTH-1:0] data;  // 依赖文件A的编译顺序！
endmodule

// 问题：如果B.sv先编译，WIDTH未定义
// 解决：使用package或确保编译顺序
```

### 3. 使用 `::` 显式引用

```systemverilog
// 当存在命名冲突时，使用 $unit:: 显式引用
parameter WIDTH = 8;

module dut;
  parameter WIDTH = 16;  // 模块内部覆盖
  
  logic [$unit::WIDTH-1:0] data1;  // 使用$unit的WIDTH (8位)
  logic [WIDTH-1:0]        data2;  // 使用模块的WIDTH (16位)
endmodule
```

## 8.5 关键要点总结

| 要点 | 说明 |
|------|------|
| **定义位置** | 所有模块、接口、程序块之外 |
| **可见性** | 对同一编译单元内的所有模块可见 |
| **推荐用途** | 类型定义、参数、常量 |
| **不推荐** | 全局变量（可能导致竞争） |
| **显式引用** | 使用 `$unit::名称` 解决命名冲突 |
| **更好的选择** | 使用 package 替代 $unit |

## 示例文件

参见: `Code_Examples/Chapter4_Connecting_DUT_TB/08_unit_scope.sv`
