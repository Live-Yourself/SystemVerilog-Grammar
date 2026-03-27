# 第3章 SystemVerilog过程语句

> 基于《SystemVerilog验证 - 测试平台编写指南》

---

## 知识点索引

| 序号 | 知识点 | 说明 |
|------|--------|------|
| 1 | [if-else条件语句](#知识点1-if-else条件语句) | 条件分支控制 |
| 2 | [case语句](#知识点2-case语句) | 多路分支选择 |
| 3 | [for循环](#知识点3-for循环) | 计数循环 |
| 4 | [while循环](#知识点4-while循环) | 条件循环 |
| 5 | [do-while循环](#知识点5-do-while循环) | 先执行后判断 |
| 6 | [foreach循环](#知识点6-foreach循环) | 数组遍历 |
| 7 | [repeat循环](#知识点7-repeat循环) | 固定次数循环 |
| 8 | [forever循环](#知识点8-forever循环) | 无限循环 |
| 9 | [break和continue](#知识点9-break和continue) | 循环控制 |
| 10 | [任务task](#知识点10-任务task) | 可复用代码块 |
| 11 | [函数function](#知识点11-函数function) | 有返回值的代码块 |
| 12 | [任务与函数的区别](#知识点12-任务与函数的区别) | 使用场景选择 |
| 13 | [参数传递方式](#知识点13-参数传递方式) | 值传递vs引用传递 |
| 14 | [return语句](#知识点14-return语句) | 提前返回 |
| 15 | [void函数](#知识点15-void函数) | 无返回值的函数 |

---

## 知识点1: if-else条件语句

| 特性 | 说明 |
|------|------|
| **作用** | 根据条件执行不同的代码分支 |
| **形式** | 单分支、双分支、多分支 |
| **语法** | `if (condition) statement; else statement;` |
| **块语句** | 多条语句需用`begin...end`包围 |

**基本语法:**

```systemverilog
// 单分支
if (condition)
  statement;

// 双分支
if (condition)
  statement1;
else
  statement2;

// 多分支
if (condition1)
  statement1;
else if (condition2)
  statement2;
else
  statement3;
```

**块语句begin...end:**

```systemverilog
// 多条语句必须用begin...end包围
if (condition) begin
  statement1;
  statement2;
  statement3;
end else begin
  statement4;
  statement5;
end
```

**常见陷阱:**

| 陷阱 | 错误示例 | 正确做法 |
|------|----------|----------|
| **悬空else** | else匹配最近的if | 用begin...end明确层次 |
| **赋值vs比较** | `if (a = b)` | `if (a == b)` |
| **缺少begin...end** | 只执行第一条语句 | 用begin...end包围 |
| **X/Z态判断** | `if (x_val == 4'b10X0)` | 先用`!$isunknown()`检查 |

**从示例代码讲解:**

```systemverilog
// 示例代码第24-35行: 基本if-else用法
counter = 5;

// 双分支if-else
if (counter == 10)
  $display("counter等于10");
else
  $display("counter不等于10, 实际值为%0d", counter);

// 多分支if-else if-else
if (counter < 3)
  $display("counter很小");
else if (counter < 7)
  $display("counter中等");  // 会执行这里 (5 < 7)
else
  $display("counter很大");
```

```systemverilog
// 示例代码第50-56行: 块语句的正确用法
if (valid) begin
  data_out = data_in;
  $display("数据传输: data_in=%0d -> data_out=%0d", data_in, data_out);
  $display("传输完成");
end
```

```systemverilog
// 示例代码第150-158行: 组合逻辑中的if
always_comb begin
  if (sel == 2'b00)
    mux_out = in0;
  else if (sel == 2'b01)
    mux_out = in1;
  else if (sel == 2'b10)
    mux_out = in2;
  else
    mux_out = in3;
end
```

**if与三元运算符对比:**

```systemverilog
// if-else写法
if (a > b)
  max_val = a;
else
  max_val = b;

// 三元运算符写法 (更简洁)
max_val = (a > b) ? a : b;
```

**综合注意事项:**
- ✅ 组合逻辑中必须覆盖所有分支,否则产生锁存器
- ✅ 时序逻辑中使用非阻塞赋值 `<=`
- ✅ 组合逻辑中使用阻塞赋值 `=`
- ⚠ 避免在条件中使用X或Z判断

**最佳实践:**
- ✓ 始终使用begin...end包围多条语句
- ✓ 条件表达式中使用`==`而非`=`
- ✓ 对X/Z敏感的逻辑先检查`$isunknown()`
- ✓ 组合逻辑确保所有输入都在敏感列表中

---

## 知识点2: case语句

| 特性 | 说明 |
|------|------|
| **作用** | 多路分支选择,比if-else更清晰 |
| **形式** | case / casez / casex |
| **特点** | 并行匹配,适合多选项场景 |
| **综合** | 可综合为MUX或优先级编码器 |

**三种case对比:**

| 类型 | 通配符 | 用途 | 安全性 |
|------|--------|------|--------|
| `case` | 无 | 精确匹配 | 最安全 |
| `casez` | Z或? | 不关心某些位 | 安全 |
| `casex` | X和Z | 不关心X/Z位 | ⚠ 谨慎使用 |

**基本语法:**

```systemverilog
case (expression)
  value1: statement1;
  value2: statement2;
  value3, value4: statement3;  // 多个值共享操作
  default: default_statement;
endcase
```

**casez语法 (Z作为通配符):**

```systemverilog
casez (expression)
  8'b1zzz_zzzz: statement1;  // 最高位为1,其他不关心
  8'b01zz_zzzz: statement2;  // 高2位为01,其他不关心
  default: statement3;
endcase

// 可以用?代替Z
casez (data)
  8'b????_??00: type_id = 2'b00;  // 低2位为00
  8'b????_??01: type_id = 2'b01;
endcase
```

**从示例代码讲解:**

```systemverilog
// 示例代码第20-37行: 基本4选1 MUX
case (sel)
  2'b00: mux_out = in0;
  2'b01: mux_out = in1;
  2'b10: mux_out = in2;
  2'b11: mux_out = in3;
endcase
```

```systemverilog
// 示例代码第89-105行: casez地址译码
casez (address)
  8'b1zzz_zzzz: region = 4'd1;  // 0x80-0xFF 外设区
  8'b01zz_zzzz: region = 4'd2;  // 0x40-0x7F RAM区
  8'b001z_zzzz: region = 4'd3;  // 0x20-0x3F ROM区
  default:       region = 4'd0;
endcase
```

```systemverilog
// 示例代码第150-161行: 多个case项共享操作
case (hex_digit)
  4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF: begin
    is_hex_letter = 1;
    $display("%h 是十六进制字母", hex_digit);
  end
  default: is_hex_letter = 0;
endcase
```

**unique case vs priority case:**

| 修饰符 | 含义 | 综合结果 | 检查 |
|--------|------|----------|------|
| `unique case` | case项互斥 | 并行MUX | 运行时检查重叠 |
| `priority case` | case项可能重叠 | 优先级逻辑 | 按顺序匹配 |

```systemverilog
// 示例代码第233-242行: unique case (并行MUX)
unique case (sel)
  2'b00: parallel_mux = in0;
  2'b01: parallel_mux = in1;
  2'b10: parallel_mux = in2;
  2'b11: parallel_mux = in3;
endcase

// 示例代码第256-270行: priority case (优先级编码器)
priority case (1'b1)
  request[7]: grant = 3'd7;  // 最高优先级
  request[6]: grant = 3'd6;
  request[5]: grant = 3'd5;
  // ...
  default:   grant = 3'd0;
endcase
```

**casez vs casex 对比:**

```systemverilog
// 示例代码第175-192行
test_val = 4'b1X00;

// casez: X不是通配符,只匹配真实的X
casez (test_val)
  4'b1zzz: $display("匹配 1zzz");      // 不匹配
  default: $display("无匹配");          // 执行这里
endcase

// casex: X是通配符,可以匹配任意值
casex (test_val)
  4'b1zzz: $display("匹配 1zzz");      // 匹配成功
  default: $display("无匹配");
endcase
```

**⚠ 使用建议:**
- **优先使用casez而非casex** (casez更安全,避免X态混淆)
- **用?代替Z提高可读性** (`8'b1???_????` 比 `8'b1zzz_zzzz` 更清晰)
- **综合时优先使用unique case** (并行逻辑速度快)
- **优先级编码时使用priority case** (明确优先级意图)

**case在状态机中的应用:**

```systemverilog
// 示例代码第296-327行: 状态转移逻辑
typedef enum logic [2:0] {
  IDLE, START, READ, WRITE, WAIT, DONE
} state_t;

case (current_state)
  IDLE:   if (start_cmd) next_state = START;
  START:  next_state = READ;
  READ:   next_state = WRITE;
  WRITE:  next_state = WAIT;
  WAIT:   if (done_cmd) next_state = DONE;
  DONE:   next_state = IDLE;
  default: next_state = IDLE;
endcase
```

**最佳实践:**
- ✓ 始终添加default分支(避免锁存器,处理异常)
- ✓ 使用枚举类型定义状态(可读性好,类型安全)
- ✓ 优先使用casez,避免casex的X态混淆
- ✓ 综合时使用unique/priority明确意图
- ✓ 多个值共享操作用逗号分隔

---

## 知识点3: for循环

| 特性 | 说明 |
|------|------|
| **作用** | 重复执行代码块,适合已知循环次数的场景 |
| **语法** | `for (初始化; 条件; 更新) begin ... end` |
| **特点** | 编译时可确定循环次数,综合器会展开为并行硬件 |
| **适用场景** | 数组遍历、批量初始化、流水线操作 |

**基本语法:**

```systemverilog
for (初始化; 循环条件; 迭代更新) begin
  // 循环体
end

// 示例
for (int i = 0; i < 16; i++) begin
  data_array[i] = i * 10;
end
```

**for循环的不同形式:**

| 形式 | 示例 | 用途 |
|------|------|------|
| 递增循环 | `for (i=0; i<N; i++)` | 从小到大遍历 |
| 递减循环 | `for (i=N-1; i>=0; i--)` | 从大到小遍历 |
| 自定义步长 | `for (i=0; i<N; i+=2)` | 步长为2 |
| 多循环变量 | `for (i=0, j=N-1; i<N; i++, j--)` | 双向遍历 |

**从示例代码讲解:**

```systemverilog
// 示例代码第20-25行: 基本for循环 - 数组初始化
for (i = 0; i < 16; i++) begin
  data_array[i] = i * 10;
end

// 示例代码第33-37行: 数组求和
sum_result = 0;
for (i = 0; i < 16; i++) begin
  sum_result = sum_result + data_array[i];
end
```

```systemverilog
// 示例代码第49-66行: 不同写法
// 递减循环
for (i = 7; i >= 4; i--) begin
  $display("i = %0d", i);
end

// 步长为2
for (i = 0; i < 10; i = i + 2) begin
  $display("i = %0d", i);
end

// 多个循环变量
logic [3:0] j;
for (i = 0, j = 15; i < 4; i++, j--) begin
  $display("i=%0d, j=%0d", i, j);
end
```

```systemverilog
// 示例代码第74-90行: 遍历多维数组
logic [7:0] matrix [4][8];  // 4行8列

for (row = 0; row < 4; row++) begin
  for (col = 0; col < 8; col++) begin
    matrix[row][col] = row * 8 + col;
  end
end
```

**for循环在硬件中的应用:**

```systemverilog
// 示例代码第151-164行: 组合逻辑 - 优先级编码器
always_comb begin
  grant_valid = 0;
  grant_index = 0;
  
  for (int idx = 7; idx >= 0; idx--) begin
    if (request_bus[idx]) begin
      grant_index = idx[2:0];
      grant_valid = 1;
    end
  end
end
```

```systemverilog
// 示例代码第178-193行: 时序逻辑 - 移位寄存器
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    // 复位: 所有寄存器清零
    for (int idx = 0; idx < 8; idx++) begin
      shift_register[idx] <= 8'h00;
    end
  end else if (shift_en) begin
    // 移位操作
    for (int idx = 7; idx > 0; idx--) begin
      shift_register[idx] <= shift_register[idx-1];
    end
    shift_register[0] <= shift_in;
  end
end
```

**for循环的静态展开:**

```systemverilog
// 示例代码第201-217行说明
// 编译时循环次数确定,综合器展开为并行硬件:

for (i=0; i<4; i++) begin
  out[i] = in[i] & mask;
end

// 展开后等价于:
out[0] = in[0] & mask;
out[1] = in[1] & mask;
out[2] = in[2] & mask;
out[3] = in[3] & mask;
```

⚠ **关键概念:**
- for循环在综合时会被**静态展开**为并行硬件
- 循环次数必须在**编译时确定** (不能是变量)
- 展开后所有操作**并行执行** (不是顺序执行!)

**for循环 vs generate for:**

| 特性 | 过程for循环 | generate for |
|------|-------------|--------------|
| **用途** | 过程代码中 | 实例化模块 |
| **循环变量** | `int i` | `genvar i` |
| **综合结果** | 展开为逻辑 | 展开为实例 |
| **适用场景** | 数组操作、初始化 | 模块复制 |

```systemverilog
// 过程for循环 - 逻辑操作
for (int i = 0; i < 4; i++) begin
  out[i] = in[i] & mask;
end

// generate for - 模块实例化
genvar gi;
generate
  for (gi = 0; gi < 4; gi++) begin : gen_inst
    my_module u_mod (.in(in[gi]), .out(out[gi]));
  end
endgenerate
```

**最佳实践:**
- ✓ 循环次数使用常量或参数 (编译时确定)
- ✓ 循环变量声明为`int`类型 (有符号,32位)
- ✓ 使用有意义的循环变量名 (如`idx`, `row`, `col`)
- ✓ 避免在循环内使用`#延迟` (仿真效率低)
- ✓ 注意综合展开后的硬件资源消耗

---

## 知识点4: while循环

| 特性 | 说明 |
|------|------|
| **作用** | 条件循环,先判断后执行 |
| **语法** | `while (condition) begin ... end` |
| **特点** | 循环次数不确定,根据条件动态控制 |
| **适用场景** | 等待事件、条件查找、状态轮询 |

**基本语法:**

```systemverilog
while (条件表达式) begin
  // 循环体
  // 必须修改条件相关变量,避免死循环
end
```

**从示例代码讲解:**

```systemverilog
// 示例代码第17-25行: 基本while循环
counter = 0;
while (counter < 5) begin
  $display("counter = %0d", counter);
  counter++;
end
```

```systemverilog
// 示例代码第63-75行: while等待事件
ready = 0;
timeout = 0;

while (!ready && timeout < 100) begin
  #1;
  timeout++;
  if (timeout == 10) ready = 1;
end
```

**while vs for 选择:**

| 特性 | while | for |
|------|-------|-----|
| 循环次数 | 不确定 | 确定 |
| 条件类型 | 复杂条件 | 简单计数 |
| 典型场景 | 等待事件、查找 | 数组遍历 |

**最佳实践:**
- ✓ 确保条件会改变,避免死循环
- ✓ 添加超时机制(等待事件时)
- ✓ 循环次数不确定时使用while

---

## 知识点5: do-while循环

| 特性 | 说明 |
|------|------|
| **作用** | 条件循环,先执行后判断 |
| **语法** | `do begin ... end while (condition);` |
| **特点** | 至少执行一次 |
| **适用场景** | 输入验证、菜单选择、重试机制 |

**基本语法:**

```systemverilog
do begin
  // 循环体
  // 至少执行一次
end while (条件表达式);
```

**do-while vs while 对比:**

```systemverilog
// 示例代码第33-53行

// while: 先检查,可能不执行
counter = 10;
while (counter < 5) begin
  $display("执行");  // 不会执行
  counter++;
end

// do-while: 先执行,至少一次
counter = 10;
do begin
  $display("执行");  // 会执行一次
  counter++;
end while (counter < 5);
```

**典型应用:**

```systemverilog
// 示例代码第61-85行: 输入验证
do begin
  user_input = get_input();
  valid_choice = (user_input >= 1 && user_input <= 4);
  
  if (!valid_choice)
    $display("无效输入! 请重试");
    
end while (!valid_choice);
```

**最佳实践:**
- ✓ 需要至少执行一次时使用do-while
- ✓ 输入验证、重试机制等场景
- ✓ 避免死循环,确保条件会改变

---

## 知识点6: foreach循环

| 特性 | 说明 |
|------|------|
| **作用** | 专门用于遍历数组 |
| **语法** | `foreach (array[index]) begin ... end` |
| **特点** | 自动遍历所有元素,索引只读 |
| **适用场景** | 数组遍历、队列遍历、关联数组遍历 |

**基本语法:**

```systemverilog
// 一维数组
foreach (array_name[idx]) begin
  // 使用array_name[idx]访问元素
end

// 二维数组
foreach (array_name[row, col]) begin
  // 使用array_name[row][col]访问元素
end
```

**从示例代码讲解:**

```systemverilog
// 示例代码第17-24行: 遍历一维数组
foreach (simple_arr[i]) begin
  simple_arr[i] = i * 10;  // 初始化
end

foreach (simple_arr[i]) begin
  $display("simple_arr[%0d] = %0d", i, simple_arr[i]);
end
```

```systemverilog
// 示例代码第30-42行: 遍历二维数组
foreach (matrix[row, col]) begin
  matrix[row][col] = row * 8 + col;
end

// 也可以分开写
foreach (matrix[row]) begin
  foreach (matrix[row, col]) begin
    $write("%3d ", matrix[row][col]);
  end
end
```

**foreach遍历各种数组:**

| 数组类型 | 语法示例 | 说明 |
|----------|----------|------|
| 定宽数组 | `foreach (arr[i])` | 按索引遍历 |
| 动态数组 | `foreach (dyn[i])` | 按索引遍历 |
| 队列 | `foreach (q[i])` | 按索引遍历 |
| 关联数组 | `foreach (assoc[key])` | 按key遍历(顺序不确定) |

**foreach vs for 对比:**

```systemverilog
// foreach: 简洁,不需要索引变量
foreach (arr[i]) begin
  arr[i] = i * 10;
end

// for: 需要手动管理索引
for (int i = 0; i < $size(arr); i++) begin
  arr[i] = i * 10;
end
```

**关键要点:**
- ✓ **循环变量是只读的**,不能修改
- ✓ 自动处理数组边界,不会越界
- ✓ 不需要知道数组大小
- ✓ 关联数组遍历顺序不确定

**最佳实践:**
- ✓ 优先使用foreach遍历数组(比for更简洁安全)
- ✓ 多维数组用逗号分隔索引: `foreach (arr[i,j,k])`
- ✓ 不需要修改索引时使用foreach

---

## 知识点7: repeat循环

| 特性 | 说明 |
|------|------|
| **作用** | 固定次数重复执行 |
| **语法** | `repeat (N) begin ... end` |
| **特点** | 只关心次数,不需要索引 |
| **适用场景** | 重复操作、生成测试数据、等待时钟 |

**基本语法:**

```systemverilog
repeat (次数) begin
  // 循环体
end
```

**从示例代码讲解:**

```systemverilog
// 示例代码第17-25行: 基本repeat
counter = 0;
repeat (5) begin
  $display("counter = %0d", counter);
  counter++;
end

// 示例代码第57-64行: repeat等待时钟
repeat (10) begin
  @(posedge clk);
  counter++;
end
```

**典型应用:**

```systemverilog
// 生成测试数据
repeat (10) begin
  test_data = $urandom_range(0, 255);
  $display("test_data = %h", test_data);
end

// 发送数据包
repeat (4) begin
  data_packet = $urandom();
  send_packet(data_packet);
  #10;
end
```

**repeat vs for:**

| 特性 | repeat | for |
|------|--------|-----|
| 索引访问 | 不支持 | 支持 |
| 语法简洁度 | 更简洁 | 较复杂 |
| 适用场景 | 纯重复操作 | 需要索引 |

**最佳实践:**
- ✓ 不需要索引时使用repeat(更简洁)
- ✓ 生成测试数据、重复操作等场景
- ✓ 等待固定次数的时钟边沿

---

## 知识点8: forever循环

| 特性 | 说明 |
|------|------|
| **作用** | 无限循环,永不停止 |
| **语法** | `forever begin ... end` |
| **特点** | 无条件执行,直到仿真结束 |
| **适用场景** | 时钟生成、监控进程 |

**基本语法:**

```systemverilog
forever begin
  // 循环体
  // 必须有延时或事件等待,否则死循环
end
```

**从示例代码讲解:**

```systemverilog
// 示例代码第96-102行: forever生成时钟
initial begin
  clk = 0;
  forever #5 clk = ~clk;
end

// 示例代码第81-93行: 带退出条件的forever
counter = 0;
forever begin
  counter++;
  $display("counter=%0d", counter);
  
  if (counter >= 5) begin
    $display("退出forever循环");
    $finish;  // 结束仿真
  end
  
  #5;
end
```

**典型应用:**

```systemverilog
// 时钟生成 (最常见)
initial begin
  clk = 0;
  forever #5 clk = ~clk;
end

// 监控进程
initial begin
  forever begin
    @(posedge clk);
    if (error_detected)
      $display("错误检测!");
  end
end
```

**注意事项:**
- ⚠ forever不会自动停止,必须用`$finish`或`disable`退出
- ⚠ 必须包含延时或事件等待,否则仿真挂死
- ⚠ 通常用于时钟生成和监控进程

**最佳实践:**
- ✓ 时钟生成使用forever(最简洁)
- ✓ 添加退出条件或超时机制
- ✓ 确保循环体内有延时或事件等待

---

## 知识点9: break和continue

| 特性 | 说明 |
|------|------|
| **break作用** | 立即退出整个循环 |
| **continue作用** | 跳过当前迭代,继续下一次 |
| **适用范围** | for, while, do-while, foreach, repeat, forever |
| **嵌套行为** | 只影响最内层循环 |

**break示例:**

```systemverilog
// 示例代码第17-31行: break提前退出
for (idx = 0; idx < 16; idx++) begin
  if (data_arr[idx] > 50) begin
    $display("找到: data_arr[%0d] = %0d", idx, data_arr[idx]);
    break;  // 找到后立即退出
  end
end
```

**continue示例:**

```systemverilog
// 示例代码第37-48行: continue跳过奇数
for (int i = 0; i < 10; i++) begin
  if (i % 2 == 0) continue;  // 跳过偶数
  $display("i = %0d (奇数)", i);  // 只输出奇数
end
```

**break vs continue 对比:**

```systemverilog
// 示例代码第108-123行
$display("使用break:");
for (int i = 0; i < 5; i++) begin
  if (i == 3) break;
  $display("i = %0d", i);  // 输出: 0, 1, 2
end

$display("使用continue:");
for (int i = 0; i < 5; i++) begin
  if (i == 3) continue;
  $display("i = %0d", i);  // 输出: 0, 1, 2, 4
end
```

**嵌套循环中的作用范围:**

```systemverilog
// 示例代码第129-141行
// break只影响最内层循环
for (int i = 0; i < 3; i++) begin
  for (int j = 0; j < 5; j++) begin
    if (j == 2) break;  // 只退出内层循环
    $display("j = %0d", j);
  end
  $display("外层循环继续: i = %0d", i);
end
```

**实际应用:**

```systemverilog
// 示例代码第159-187行: 查找特定模式
for (int i = 0; i < 10; i++) begin
  // 跳过非目标数据
  if (packet[i] < 100) continue;
  
  // 检查模式
  if (packet[i] == 8'hAA) begin
    pattern_found = 1;
    break;  // 找到后立即退出
  end
end
```

**最佳实践:**
- ✓ 使用break优化搜索效率(找到即退出)
- ✓ 使用continue过滤数据(跳过无效项)
- ✓ 注意嵌套循环中break的作用范围
- ✓ 避免过多break/continue,影响可读性

---

## 知识点10: 任务task

| 特性 | 说明 |
|------|------|
| **作用** | 封装可复用的代码块 |
| **返回值** | 无返回值(通过输出参数返回) |
| **时序控制** | ✅ 可以包含延时、事件等待 |
| **参数类型** | input、output、inout、ref |
| **调用方式** | `task_name();` 或 `task_name;` |

**基本语法:**

```systemverilog
task task_name(
  input  type input_param,
  output type output_param,
  inout  type inout_param
);
  // 任务体
endtask
```

**参数类型:**

| 参数类型 | 说明 | 用途 |
|----------|------|------|
| `input` | 输入参数 | 传递数据到任务 |
| `output` | 输出参数 | 从任务返回数据 |
| `inout` | 双向参数 | 既输入又输出 |
| `ref` | 引用传递 | 高效传递大数组 |

**关键特点:**
- ✅ 可以包含时序控制 (`#`, `@`, `wait`)
- ✅ 可以调用其他任务
- ✅ 可以有多个output参数
- ✅ 可以访问模块变量

**示例文件:** `09_task_example.sv`

**最佳实践:**
- ✓ 任务用于需要时序控制的操作
- ✓ 使用描述性命名,动词开头(如`send_data`)
- ✓ 复杂操作封装为任务提高可读性
- ✓ 输出参数放在参数列表后面

---

## 知识点11: 函数function

| 特性 | 说明 |
|------|------|
| **作用** | 封装计算逻辑,返回单个值 |
| **返回值** | ✅ 必须有返回值 |
| **时序控制** | ❌ 不能包含延时、事件等待 |
| **参数类型** | input、output、inout、ref (默认input) |
| **调用方式** | `result = function_name(args);` |

**基本语法:**

```systemverilog
// 方式1: 使用return语句 (推荐)
function return_type function_name(input type param);
  return result;
endfunction

// 方式2: 使用函数名赋值 (Verilog风格)
function return_type function_name(input type param);
  function_name = result;
endfunction
```

**关键特点:**
- ✅ 必须有返回值
- ❌ 不能包含时序控制 (`#`, `@`, `wait`)
- ❌ 不能调用任务
- ✅ 可以调用其他函数
- ✅ 可以用于表达式
- ✅ 支持递归 (需声明automatic)

**automatic关键字:**
```systemverilog
// 每次调用创建新的局部变量副本
function automatic int fibonacci(input int n);
  if (n <= 1) return n;
  else return fibonacci(n-1) + fibonacci(n-2);
endfunction
```

**示例文件:** `10_function_example.sv`

**最佳实践:**
- ✓ 函数用于纯计算逻辑
- ✓ 使用return语句(更清晰)
- ✓ 递归函数必须声明automatic
- ✓ 函数名用名词或动名词(如`max_value`, `square`)

---

## 知识点12: 任务与函数的区别

| 特性 | 任务task | 函数function |
|------|---------|--------------|
| **返回值** | ❌ 无 | ✅ 必须有 |
| **时序控制** | ✅ 支持 | ❌ 不支持 |
| **调用任务** | ✅ 支持 | ❌ 不支持 |
| **调用函数** | ✅ 支持 | ✅ 支持 |
| **参数类型** | input/output/inout/ref | input(默认) |
| **执行时间** | 可以消耗仿真时间 | 0仿真时间 |
| **使用场景** | 时序操作、复杂流程 | 计算、判断 |
| **表达式使用** | ❌ 不能用于表达式 | ✅ 可用于表达式 |

**选择指南:**

| 场景 | 推荐 | 原因 |
|------|------|------|
| 数学计算 | function | 需要返回值 |
| 条件判断 | function | 用于表达式 |
| 数据校验 | function | 返回真/假 |
| 发送数据 | task | 需要时序控制 |
| 等待事件 | task | 需要@或wait |
| 复杂流程 | task | 可能调用其他任务 |
| 协议处理 | task | 需要时序和状态 |

**决策树:**
```
需要返回值用于表达式?
├─ 是 → 用function
└─ 否
    ├─ 需要时序控制?
    │   ├─ 是 → 用task
    │   └─ 否
    │       ├─ 需要调用task?
    │       │   ├─ 是 → 用task
    │       │   └─ 否 → 用function
    │       └─ 多个输出值?
    │           ├─ 是 → 用task
    │           └─ 否 → 用function
```

---

## 知识点13: 参数传递方式

| 方式 | 关键字 | 特点 | 用途 |
|------|--------|------|------|
| 值传递 | input | 复制值,函数内修改不影响外部 | 传递输入数据 |
| 输出传递 | output | 从函数输出值到外部变量 | 返回结果 |
| 双向传递 | inout | 双向传递,可读可写 | 双向数据流 |
| 引用传递 | ref | 传递引用,直接修改外部变量 | 高效传递大数组 |

**input vs ref (效率对比):**

```systemverilog
// input: 复制整个数组 (效率低)
task process_input(input logic [7:0] arr[1000]);
  // 复制1000个元素
endtask

// ref: 传递引用 (效率高)
task process_ref(ref logic [7:0] arr[1000]);
  // 不复制,直接访问原数组
endtask
```

**最佳实践:**
- ✓ 小数据用input (简单清晰)
- ✓ 大数组用ref (高效,避免复制)
- ✓ 需要返回值用output
- ✓ 需要双向修改用inout或ref

---

## 知识点14: return语句

| 特性 | 说明 |
|------|------|
| **作用** | 提前退出函数并返回值 |
| **适用范围** | function (task也可用return退出) |
| **语法** | `return value;` |
| **多个return** | ✅ 支持 |

**基本用法:**

```systemverilog
// 单个return
function int add(input int a, input int b);
  return a + b;
endfunction

// 多个return (条件返回)
function int max(input int a, input int b);
  if (a > b)
    return a;
  else
    return b;
endfunction

// 提前退出
function int find_first_one(input logic [7:0] data);
  if (data == 0)
    return -1;  // 提前退出
  
  for (int i = 0; i < 8; i++) begin
    if (data[i])
      return i;  // 找到就返回
  end
  
  return -1;
endfunction
```

---

## 知识点15: void函数

| 特性 | 说明 |
|------|------|
| **作用** | 无返回值的函数 |
| **语法** | `function void func_name(...);` |
| **用途** | 打印、验证、副作用操作 |
| **时序控制** | ❌ 仍不能包含时序控制 |

**典型应用:**

```systemverilog
// 打印信息
function void print_info(input string msg);
  $display("[INFO] %s", msg);
endfunction

// 数据验证
function void check_range(
  input logic [7:0] value,
  input logic [7:0] min,
  input logic [7:0] max
);
  if (value < min || value > max)
    $error("值超出范围!");
endfunction
```

**void函数 vs task:**

| 特性 | void函数 | task |
|------|----------|------|
| 返回值 | 无 | 无 |
| 时序控制 | ❌ 不支持 | ✅ 支持 |
| 调用task | ❌ 不支持 | ✅ 支持 |

**选择:** 无时序控制 + 无返回值 → void函数

---

## 学习建议

1. **任务vs函数选择**:
   - 计算逻辑 → function
   - 时序操作 → task
   - 无返回值的计算 → void function

2. **参数传递**:
   - 小数据 → input/output
   - 大数组 → ref
   - 需要双向修改 → inout/ref

3. **代码风格**:
   - 函数名用名词或动名词(max, square)
   - 任务名用动词开头(send_data, process_packet)
   - 参数命名清晰,有默认值的参数放后面

---

**更新日期:** 2026年3月26日
