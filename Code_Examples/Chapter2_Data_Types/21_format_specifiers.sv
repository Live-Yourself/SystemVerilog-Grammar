// 知识点21: 格式化参数总结 ($display, $write, $sformatf)
// 演示各种格式化参数的使用方法

module format_specifiers;

  // ========== 用于演示的变量 ==========
  logic [31:0]  hex_val;       // 十六进制值
  logic [15:0]  dec_val;       // 十进制值
  logic [7:0]   bin_val;       // 二进制值
  logic [3:0]   oct_val;       // 八进制值
  int           signed_val;    // 有符号值
  real          real_val;      // 实数
  string        str_val;       // 字符串
  logic [7:0]   char_val;      // 字符
  logic [31:0]  time_val;      // 时间值
  logic         bit_val;       // 单bit
  
  initial begin
    $display("================================================================");
    $display("          SystemVerilog 格式化参数完整总结");
    $display("================================================================\n");
    
    // 初始化变量
    hex_val   = 32'hDEADBEEF;
    dec_val   = 16'd255;
    bin_val   = 8'b10101010;
    oct_val   = 4'o7;
    signed_val = -123;
    real_val  = 3.14159;
    str_val   = "Hello";
    char_val  = "A";
    bit_val   = 1'b1;
    
    // ============================================================
    // 一、数值格式
    // ============================================================
    $display("【一、数值格式】\n");
    
    // ----- 1. %h / %H : 十六进制 -----
    $display("  1. %%h / %%H - 十六进制 (Hexadecimal)");
    $display("     语法: %%h, %%H, %%%d.h (指定宽度)");
    $display("     示例:");
    $display("       %%h      = %h", hex_val);
    $display("       %%H      = %H", hex_val);
    $display("       %%8h     = %8h", dec_val);
    $display("       %%08h    = %08h", dec_val);
    $display("       %%0h     = %0h", hex_val);    // 无前导空格
    $display("     应用: 地址显示、数据总线值\n");
    
    // ----- 2. %d / %D : 十进制 -----
    $display("  2. %%d / %%D - 十进制 (Decimal)");
    $display("     语法: %%d, %%D, %%%d.d");
    $display("     示例:");
    $display("       %%d      = %d", dec_val);
    $display("       %%D      = %D", dec_val);
    $display("       %%8d     = %8d", dec_val);
    $display("       %%08d    = %08d", dec_val);
    $display("       %%0d     = %0d", dec_val);
    $display("     应用: 计数器值、数组索引\n");
    
    // ----- 3. %b / %B : 二进制 -----
    $display("  3. %%b / %%B - 二进制 (Binary)");
    $display("     语法: %%b, %%B, %%%d.b");
    $display("     示例:");
    $display("       %%b      = %b", bin_val);
    $display("       %%B      = %B", bin_val);
    $display("       %%8b     = %8b", bin_val);
    $display("       %%08b    = %08b", bin_val);
    $display("       %%0b     = %0b", bin_val);
    $display("     应用: 寄存器位状态、标志位显示\n");
    
    // ----- 4. %o / %O : 八进制 -----
    $display("  4. %%o / %%O - 八进制 (Octal)");
    $display("     语法: %%o, %%O, %%%d.o");
    $display("     示例:");
    $display("       %%o      = %o", oct_val);
    $display("       %%O      = %O", oct_val);
    $display("       %%4o     = %4o", oct_val);
    $display("       %%04o    = %04o", oct_val);
    $display("     应用: Unix文件权限、历史遗留系统\n");
    
    // ============================================================
    // 二、特殊数值格式
    // ============================================================
    $display("\n【二、特殊数值格式】\n");
    
    // ----- 5. %s / %S : 字符串 -----
    $display("  5. %%s / %%S - 字符串 (String)");
    $display("     示例:");
    $display("       %%s      = %s", str_val);
    $display("       %%10s    = %10s", str_val);     // 右对齐
    $display("       %%-10s   = %-10sEND", str_val); // 左对齐
    $display("     应用: 消息输出、日志记录\n");
    
    // ----- 6. %c / %C : 字符 -----
    $display("  6. %%c / %%C - 字符 (Character)");
    $display("     示例:");
    $display("       %%c      = %c", char_val);
    $display("       %%C      = %C", char_val);
    $display("       ASCII 65= %c", 8'd65);
    $display("     应用: 单个字符显示\n");
    
    // ----- 7. %t / %T : 时间 -----
    $display("  7. %%t / %%T - 时间 (Time)");
    $display("     示例:");
    $display("       %%t      = %t", $time);
    $display("       %%0t     = %0t", $time);
    $display("     注: 时间格式由 $timeformat 设置");
    $display("     应用: 仿真时间戳、波形调试\n");
    
    // ----- 8. %m / %M : 模块路径 -----
    $display("  8. %%m / %%M - 模块层次路径 (Module path)");
    $display("     示例:");
    $display("       %%m      = %m");
    $display("     应用: 调试信息、追踪模块实例\n");
    
    // ----- 9. %l / %L : 库信息 -----
    $display("  9. %%l / %%L - 库绑定信息 (Library binding)");
    $display("     应用: 显示模块来源库\n");
    
    // ============================================================
    // 三、实数格式
    // ============================================================
    $display("\n【三、实数格式】\n");
    
    // ----- 10. %e / %E : 科学计数法 -----
    $display("  10. %%e / %%E - 科学计数法 (Exponential)");
    $display("      示例:");
    $display("        %%e      = %e", real_val);
    $display("        %%E      = %E", real_val);
    $display("        %%.3e    = %.3e", real_val);   // 3位小数
    $display("        %%15e    = %15e", real_val);
    $display("      应用: 科学计算、大数显示\n");
    
    // ----- 11. %f / %F : 浮点数 -----
    $display("  11. %%f / %%F - 浮点数 (Fixed-point)");
    $display("      示例:");
    $display("        %%f      = %f", real_val);
    $display("        %%F      = %F", real_val);
    $display("        %%.2f    = %.2f", real_val);   // 2位小数
    $display("        %%.5f    = %.5f", real_val);   // 5位小数
    $display("        %%10.3f  = %10.3f", real_val); // 总宽10，3位小数
    $display("      应用: 时间测量、模拟值显示\n");
    
    // ----- 12. %g / %G : 自动选择 -----
    $display("  12. %%g / %%G - 自动选择 %%e 或 %%f (General)");
    $display("      示例:");
    $display("        %%g      = %g", real_val);
    $display("        %%G      = %G", real_val);
    $display("        %%g      = %g", 0.00001);      // 自动用科学计数法
    $display("        %%g      = %g", 12345.6);     // 自动用浮点数
    $display("      应用: 自适应格式输出\n");
    
    // ============================================================
    // 四、SystemVerilog特殊格式
    // ============================================================
    $display("\n【四、SystemVerilog特殊格式】\n");
    
    // ----- 13. %p / %P : 结构体/数组打印 -----
    $display("  13. %%p / %%P - 结构体/数组打印 (Pattern)");
    $display("      示例:");
    
    // 结构体
    begin
      typedef struct packed {
        logic [7:0] data;
        logic       valid;
      } pkt_t;
      pkt_t pkt;
      pkt.data = 8'hA5;
      pkt.valid = 1'b1;
      $display("        结构体: %%p = %p", pkt);
    end
    
    // 数组
    begin
      int arr[4] = '{1, 2, 3, 4};
      $display("        数组:   %%p = %p", arr);
    end
    $display("      应用: 调试复杂数据结构\n");
    
    // ----- 14. %u / %U : 未格式化二进制 -----
    $display("  14. %%u / %%U - 未格式化二进制 (Unformatted)");
    $display("      用于 $fwrite 等写文件操作");
    $display("      应用: 高效二进制文件输出\n");
    
    // ----- 15. %z / %Z : 压缩二进制 -----
    $display("  15. %%z / %%Z - 压缩二进制");
    $display("      应用: 二进制文件I/O\n");
    
    // ============================================================
    // 五、格式控制
    // ============================================================
    $display("\n【五、格式控制语法】\n");
    
    $display("  语法: %%[flags][width][.precision]format");
    $display("  ┌─────────────────────────────────────────────────────────┐");
    $display("  │  字段          │  说明                                  │");
    $display("  ├─────────────────────────────────────────────────────────┤");
    $display("  │  flags:        │                                        │");
    $display("  │    0           │  用0填充 (如 %%08h)                    │");
    $display("  │    -           │  左对齐 (如 %%-10s)                     │");
    $display("  │    +           │  显示正负号 (如 %%+d)                   │");
    $display("  │    空格        │  正数前加空格                           │");
    $display("  ├─────────────────────────────────────────────────────────┤");
    $display("  │  width:        │  最小字段宽度                           │");
    $display("  │    数字        │  固定宽度 (如 %%8d)                     │");
    $display("  │    0           │  无前导空格 (如 %%0d)                   │");
    $display("  │    *           │  动态宽度 (如 %%.d, width, val)         │");
    $display("  ├─────────────────────────────────────────────────────────┤");
    $display("  │  precision:    │  精度 (主要用于实数)                    │");
    $display("  │    .数字       │  小数位数 (如 %%.3f)                    │");
    $display("  └─────────────────────────────────────────────────────────┘");
    $display("");
    
    // ============================================================
    // 六、格式化函数对比
    // ============================================================
    $display("\n【六、格式化函数对比】\n");
    
    $display("  ┌──────────────────┬────────────────────────────────────────┐");
    $display("  │ 函数             │ 说明                                   │");
    $display("  ├──────────────────┼────────────────────────────────────────┤");
    $display("  │ $display()       │ 格式化输出 + 自动换行                  │");
    $display("  │ $write()         │ 格式化输出 + 不换行                    │");
    $display("  │ $monitor()       │ 变量变化时自动输出                     │");
    $display("  │ $strobe()        │ 时间步结束时输出                       │");
    $display("  │ $sformatf()      │ 返回格式化字符串                       │");
    $display("  │ $sformat()       │ 输出到字符串变量                       │");
    $display("  └──────────────────┴────────────────────────────────────────┘");
    $display("");
    
    // $sformatf 示例
    begin
      string msg;
      msg = $sformatf("Value = 0x%08h", hex_val);
      $display("  $sformatf 示例: \"%s\"", msg);
    end
    
    // ============================================================
    // 七、常用组合示例
    // ============================================================
    $display("\n【七、常用组合示例】\n");
    
    // 事务日志格式
    $display("  事务日志:");
    $display("    [%0t] WR: addr=0x%08h, data=0x%08h", $time, 32'h1000, 32'hDEADBEEF);
    
    // 调试信息
    $display("  调试信息:");
    $display("    [%m] state=%s, cnt=%0d", "IDLE", 100);
    
    // 波形标记
    $display("  波形标记:");
    $display("    === Packet Start @ %0t ===", $time);
    
    // 数据转储
    $display("  数据转储:");
    begin
      logic [7:0] mem[4];
      mem[0] = 8'h11; mem[1] = 8'h22; mem[2] = 8'h33; mem[3] = 8'h44;
      $display("    mem[0]=0x%02h, mem[1]=0x%02h, mem[2]=0x%02h, mem[3]=0x%02h",
               mem[0], mem[1], mem[2], mem[3]);
    end
    
    // ============================================================
    // 八、格式化参数速查表
    // ============================================================
    $display("\n【八、格式化参数速查表】\n");
    
    $display("  ┌───────┬────────────────┬─────────────────────────────────┐");
    $display("  │ 格式  │ 类型           │ 说明                            │");
    $display("  ├───────┼────────────────┼─────────────────────────────────┤");
    $display("  │ %%h   │ 整数           │ 十六进制 (小写)                 │");
    $display("  │ %%d   │ 整数           │ 十进制                          │");
    $display("  │ %%b   │ 整数           │ 二进制                          │");
    $display("  │ %%o   │ 整数           │ 八进制                          │");
    $display("  ├───────┼────────────────┼─────────────────────────────────┤");
    $display("  │ %%s   │ 字符串         │ 字符串输出                      │");
    $display("  │ %%c   │ 整数           │ ASCII字符                       │");
    $display("  │ %%t   │ 时间           │ 仿真时间                        │");
    $display("  │ %%m   │ -              │ 模块层次路径                    │");
    $display("  ├───────┼────────────────┼─────────────────────────────────┤");
    $display("  │ %%e   │ 实数           │ 科学计数法 (小写)               │");
    $display("  │ %%f   │ 实数           │ 浮点数                          │");
    $display("  │ %%g   │ 实数           │ 自动选择 %%e/%%f                 │");
    $display("  ├───────┼────────────────┼─────────────────────────────────┤");
    $display("  │ %%p   │ 结构体/数组    │ 格式化打印 (SV特有)             │");
    $display("  │ %%u   │ 二进制         │ 未格式化二进制                  │");
    $display("  │ %%z   │ 二进制         │ 压缩二进制                      │");
    $display("  └───────┴────────────────┴─────────────────────────────────┘");
    
    $display("\n================================================================");
    $display("                 示例运行完成");
    $display("================================================================");
  end

endmodule
