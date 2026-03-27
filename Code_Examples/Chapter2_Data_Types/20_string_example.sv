// 知识点20: 字符串类型 (String)
// 演示字符串声明、操作方法、格式化、字符串队列

module string_example;

  // ========== 1. 字符串声明与初始化 ==========
  string empty_str;            // 空字符串 (默认为"")
  string greeting;             // 字符串变量
  string name;                 // 名字字符串
  string message;              // 消息字符串

  // ========== 2. 字符串常量 ==========
  // 使用双引号定义
  // 注意: 字符串常量是byte数组类型

  // ========== 3. 用于演示的变量 ==========
  int    pos;                  // 位置索引
  int    len;                  // 长度
  string sub_str;              // 子字符串
  string tmp;                  // 临时字符串
  
  initial begin
    $display("========================================");
    $display("    字符串类型 (String) 示例");
    $display("========================================\n");
    
    // ----- 字符串声明与初始化 -----
    $display("【1. 字符串声明与初始化】");
    
    empty_str = "";             // 显式赋空串
    greeting  = "Hello";        // 直接赋值
    name      = "SystemVerilog";
    
    $display("  empty_str = \"%s\" (长度=%0d)", empty_str, empty_str.len());
    $display("  greeting  = \"%s\" (长度=%0d)", greeting, greeting.len());
    $display("  name      = \"%s\" (长度=%0d)", name, name.len());
    $display("");
    
    // ----- 字符串连接操作 -----
    $display("【2. 字符串连接操作】");
    
    // 方法1: 使用大括号 {}
    message = {greeting, ", ", name, "!"};
    $display("  连接方法1 ({}): \"%s\"", message);
    
    // 方法2: 使用 strcat() 方法
    tmp = "";
    tmp = tmp.strcat(greeting);
    tmp = tmp.strcat(" World!");
    $display("  连接方法2 (strcat): \"%s\"", tmp);
    
    // 方法3: 直接赋值合并
    message = greeting;
    message = {message, " World"};
    $display("  连接方法3 (追加): \"%s\"", message);
    $display("");
    
    // ----- 字符串查询方法 -----
    $display("【3. 字符串查询方法】");
    
    message = "Hello, SystemVerilog!";
    
    // len() - 获取长度
    $display("  len(): 字符串长度 = %0d", message.len());
    
    // atoi() - 字符串转整数
    message = "12345";
    $display("  atoi(): \"%s\" -> %0d", message, message.atoi());
    
    // atohex() - 十六进制字符串转整数
    message = "FF";
    $display("  atohex(): \"%s\" -> %0d (0x%h)", message, message.atohex(), message.atohex());
    
    // atoreal() - 字符串转实数
    message = "3.14159";
    $display("  atoreal(): \"%s\" -> %f", message, message.atoreal());
    $display("");
    
    // ----- 字符串搜索方法 -----
    $display("【4. 字符串搜索方法】");
    
    message = "Hello, SystemVerilog World!";
    
    // substr() - 提取子字符串
    sub_str = message.substr(7, 19);  // 索引7到19
    $display("  substr(7,19): \"%s\"", sub_str);
    
    // exists() - 查找子串是否存在
    message = "Hello, World!";
    if (message.exist("World"))
      $display("  exist(\"World\"): 找到");
    else
      $display("  exist(\"World\"): 未找到");
    
    // 字符查找
    pos = message.getc(0);  // 获取第一个字符的ASCII码
    $display("  getc(0): '%c' (ASCII=%0d)", pos, pos);
    $display("");
    
    // ----- 字符串比较 -----
    $display("【5. 字符串比较】");
    
    string str1, str2;
    str1 = "apple";
    str2 = "banana";
    
    // 使用 compare() 方法
    if (str1.compare(str2) < 0)
      $display("  compare(): \"%s\" < \"%s\"", str1, str2);
    
    // 使用 icompare() 忽略大小写
    str1 = "HELLO";
    str2 = "hello";
    if (str1.icompare(str2) == 0)
      $display("  icompare(): \"%s\" == \"%s\" (忽略大小写)", str1, str2);
    
    // 直接比较
    str1 = "test";
    str2 = "test";
    if (str1 == str2)
      $display("  直接比较: \"%s\" == \"%s\"", str1, str2);
    $display("");
    
    // ----- 字符串转换方法 -----
    $display("【6. 字符串转换方法】");
    
    int    i_val;
    real   r_val;
    
    // 整数转字符串
    i_val = 255;
    tmp = $sformatf("Value = %0d (0x%h)", i_val, i_val);
    $display("  整数转字符串: \"%s\"", tmp);
    
    // 使用 itoa()
    tmp.itoa(i_val);
    $display("  itoa(255): \"%s\"", tmp);
    
    // 使用 hextoa() 十六进制
    tmp.hextoa(i_val);
    $display("  hextoa(255): \"%s\"", tmp);
    
    // 实数转字符串
    r_val = 3.14159;
    tmp.realtoa(r_val);
    $display("  realtoa(3.14159): \"%s\"", tmp);
    $display("");
    
    // ----- 字符串大小写转换 -----
    $display("【7. 字符串大小写转换】");
    
    message = "Hello World";
    $display("  原字符串: \"%s\"", message);
    $display("  toupper(): \"%s\"", message.toupper());
    $display("  tolower(): \"%s\"", message.tolower());
    $display("");
    
    // ----- 字符串队列 -----
    $display("【8. 字符串队列】");
    
    string messages[$];        // 字符串队列
    string log_msg;            // 日志消息
    
    // 添加消息
    messages.push_back("Start simulation");
    messages.push_back("Configuring DUT");
    messages.push_back("Running test");
    messages.push_back("Check results");
    messages.push_back("End simulation");
    
    $display("  日志消息队列 (%0d条):", messages.size());
    foreach (messages[i])
      $display("    [%0d] %s", i, messages[i]);
    
    // 弹出消息
    log_msg = messages.pop_front();
    $display("  pop_front(): \"%s\"", log_msg);
    $display("  剩余消息数: %0d", messages.size());
    $display("");
    
    // ----- 特殊字符处理 -----
    $display("【9. 特殊字符处理】");
    
    message = "Line1\nLine2\tTabbed";  // 包含换行和制表符
    $display("  包含转义字符:");
    $display("  %s", message);
    
    // 转义引号
    message = "He said \"Hello\"";
    $display("  包含引号: %s", message);
    $display("");
    
    // ----- 字符串常用格式化 -----
    $display("【10. 字符串格式化 ($sformatf)】");
    
    int    addr;
    int    data;
    string timestamp;
    
    addr = 32'h1000;
    data = 32'hDEADBEEF;
    
    // 格式化字符串
    message = $sformatf("WRITE: addr=0x%08h, data=0x%08h", addr, data);
    $display("  %s", message);
    
    timestamp = $sformatf("Time: %0t", $time);
    $display("  %s", timestamp);
    $display("");
    
    // ----- 字符串方法汇总 -----
    $display("【11. 字符串常用方法汇总】");
    $display("  ┌──────────────┬─────────────────────────────┐");
    $display("  │ 方法         │ 功能                        │");
    $display("  ├──────────────┼─────────────────────────────┤");
    $display("  │ len()        │ 返回字符串长度              │");
    $display("  │ atoi()       │ 字符串转整数                │");
    $display("  │ atohex()     │ 十六进制字符串转整数        │");
    $display("  │ atoreal()    │ 字符串转实数                │");
    $display("  │ itoa(n)      │ 整数转字符串                │");
    $display("  │ hextoa(n)    │ 整数转十六进制字符串        │");
    $display("  │ realtoa(r)   │ 实数转字符串                │");
    $display("  │ substr(i,j)  │ 提取子字符串[i,j]           │");
    $display("  │ getc(i)      │ 获取第i个字符ASCII码        │");
    $display("  │ toupper()    │ 转大写                      │");
    $display("  │ tolower()    │ 转小写                      │");
    $display("  │ compare(s)   │ 字符串比较                  │");
    $display("  │ icompare(s)  │ 忽略大小写比较              │");
    $display("  │ exist(s)     │ 检查子串是否存在            │");
    $display("  │ strcat(s)    │ 连接字符串                  │");
    $display("  └──────────────┴─────────────────────────────┘");
    
    $display("\n========================================");
    $display("         示例运行完成");
    $display("========================================");
  end

endmodule
