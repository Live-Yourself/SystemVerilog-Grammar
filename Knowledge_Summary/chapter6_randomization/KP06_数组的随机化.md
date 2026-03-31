# 6.6 数组的随机化

## 核心概念

数组是验证中大量使用的数据结构，如数据包的 payload、FIFO 的数据队列、配置寄存器组等。SystemVerilog 支持对定长数组、动态数组和关联数组进行随机化，并通过约束控制数组的大小和元素的值。

## 1. 定长数组的随机化

定长数组声明时大小固定，使用 `rand` 修饰后，每个元素独立随机化。

```systemverilog
class FixedArrayDemo;
  rand bit [7:0] arr[8];  // 8个元素，每个独立随机

  constraint c_val {
    foreach (arr[i]) arr[i] inside {[10:99]};
  }
endclass
```

### 特点

- 数组大小在编译时确定，不可通过约束修改
- 每个 `rand` 元素独立求解，默认互不影响
- 可通过 `foreach` + 条件约束实现元素间关系（如唯一性、排序等，见 6.4 节）

## 2. 动态数组的随机化

动态数组的大小和元素都可以被随机化，这是验证中**最常用**的数组随机化方式。

```systemverilog
class DynArrayDemo;
  rand bit [7:0] payload[];  // 大小和元素都可随机

  // 约束数组大小
  constraint c_size {
    payload.size() inside {[1:16]};
  }

  // 约束每个元素
  constraint c_val {
    foreach (payload[i]) payload[i] inside {[0:255]};
  }
endclass
```

### 关键点

- `payload.size()` 用于约束数组长度
- `size()` 约束是**必须的**——如果不约束大小，求解器会尝试各种可能的大小，效率极低
- 每次调用 `randomize()`，数组大小和元素都会重新求解
- 如果需要保持上次的大小，可以用 `randomize(payload)` 并在 inline 中固定 `payload.size() == last_size`

### inline 约束控制大小

```systemverilog
pkt.randomize() with { payload.size() == 8; };      // 固定大小为 8
pkt.randomize() with { payload.size() inside {[4:8]}; }; // 大小在 4-8 之间
```

## 3. 关联数组的随机化

关联数组（associative array）的随机化与动态数组类似，但需要用 `num()` 约束元素个数。

```systemverilog
class AssocArrayDemo;
  rand bit [7:0] config_reg[int];  // 以 int 为索引的关联数组

  constraint c_num {
    config_reg.num() inside {[3:8]};  // 约束元素个数
  }

  constraint c_idx {
    foreach (config_reg[idx]) idx inside {[0:15]};  // 约束索引范围
  }

  constraint c_val {
    foreach (config_reg[idx]) config_reg[idx] inside {[0:255]};
  }
endclass
```

### 关键点

- `num()` 用于约束关联数组的元素个数（等价于动态数组的 `size()`）
- 可以约束索引范围和值的范围
- 关联数组的索引不一定是连续的

## 4. 数组约束的常用技巧

### 数组求和

```systemverilog
constraint c_sum {
  arr.sum() with (int'(item)) < 500;
}
```

- `sum()` 是数组缩减方法，返回所有元素之和
- `with (int'(item))` 指定累加时的类型转换（防止位宽溢出）

### 数组大小相关的条件约束

```systemverilog
constraint c_cond {
  if (payload.size() > 4) {
    payload[0] == 0xFF;  // 大数组第一个元素固定
  }
}
```

### 数组元素的交叉约束

```systemverilog
// 前半部分与后半部分有特定关系
constraint c_cross {
  if (arr.size() >= 4) begin
    arr[0] + arr[arr.size()-1] < 200;
  end
}
```

### 数组元素与标量变量的约束

```systemverilog
rand bit [7:0] header;
rand bit [7:0] payload[];

constraint c_rel {
  payload.size() == header;           // 数组大小由标量决定
  payload[0] == header;               // 第一个元素等于 header
  foreach (payload[i]) payload[i] >= header;  // 所有元素 >= header
}
```

## 5. 队列的随机化

队列（queue，用 `$` 声明）本质上也是动态数组，随机化方式相同：

```systemverilog
rand bit [7:0] data_q[$];  // 队列

constraint c_q_size {
  data_q.size() inside {[0:32]};
}
```

队列支持在 `post_randomize()` 中使用 `push_back`、`push_front`、`insert` 等操作来进一步处理随机结果。

## 6. 注意事项

- **必须约束大小**：动态数组和关联数组不约束 `size()` / `num()` 会导致性能极差
- **约束范围要合理**：过大的范围（如 0 到 2^32）使求解困难；过小可能无解
- **避免过强的交叉约束**：多个数组元素之间的复杂关系会增加求解难度
- **`foreach` 中避免依赖其他随机变量**：如果 foreach 内的约束依赖另一个 rand 变量，可能导致求解效率降低

## 总结

| 数组类型 | 声明方式 | 大小约束方法 | 适用场景 |
|---------|---------|------------|---------|
| 定长数组 | `arr[N]` | 无需约束（编译时确定） | 大小固定的缓冲区、寄存器组 |
| 动态数组 | `arr[]` | `arr.size()` | 变长数据包、可变深度队列 |
| 关联数组 | `arr[type]` | `arr.num()` | 稀疏配置、地址映射 |
| 队列 | `arr[$]` | `arr.size()` | FIFO/缓冲区建模 |
