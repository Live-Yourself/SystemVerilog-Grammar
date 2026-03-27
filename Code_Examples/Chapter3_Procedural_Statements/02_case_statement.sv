//==============================================================================
// 文件名: 02_case_statement.sv
// 知识点: case语句
// 章节: 第3章 过程语句
// 说明: 演示case/casez/casex语句的用法和区别
//==============================================================================

module case_statement;

  logic [1:0]  sel;
  logic [7:0]  in0, in1, in2, in3;
  logic [7:0]  mux_out;
  
  logic [3:0]  opcode;
  logic [7:0]  alu_result;
  logic [7:0]  operand_a, operand_b;
  
  logic [3:0]  irq_source;
  logic [31:0] irq_handler;
  
  //--------------------------------------------------------------------------
  // 示例1: 基本case语句 (精确匹配)
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例1: 基本case语句 =====");
    
    in0 = 10; in1 = 20; in2 = 30; in3 = 40;
    
    // 4选1多路选择器
    sel = 2'b00;
    case (sel)
      2'b00: mux_out = in0;
      2'b01: mux_out = in1;
      2'b10: mux_out = in2;
      2'b11: mux_out = in3;
    endcase
    $display("sel=%b -> mux_out=%0d", sel, mux_out);
    
    sel = 2'b10;
    case (sel)
      2'b00: mux_out = in0;
      2'b01: mux_out = in1;
      2'b10: mux_out = in2;
      2'b11: mux_out = in3;
    endcase
    $display("sel=%b -> mux_out=%0d", sel, mux_out);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例2: case与default分支
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例2: case与default分支 =====");
    
    opcode = 4'b1111;  // 无效操作码
    
    // default处理未匹配的情况
    case (opcode)
      4'b0000: begin
        alu_result = operand_a + operand_b;
        $display("加法操作");
      end
      4'b0001: begin
        alu_result = operand_a - operand_b;
        $display("减法操作");
      end
      4'b0010: begin
        alu_result = operand_a & operand_b;
        $display("与操作");
      end
      4'b0011: begin
        alu_result = operand_a | operand_b;
        $display("或操作");
      end
      default: begin
        alu_result = 8'h00;
        $display("错误: 未知操作码 %b", opcode);
      end
    endcase
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例3: 多个case项共享同一操作
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例3: 多个case项共享操作 =====");
    
    logic [3:0] hex_digit;
    logic       is_hex_letter;
    
    // 检测是否为A-F的十六进制字母
    hex_digit = 4'hC;
    
    case (hex_digit)
      4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF: begin
        is_hex_letter = 1;
        $display("%h 是十六进制字母", hex_digit);
      end
      default: begin
        is_hex_letter = 0;
        $display("%h 不是十六进制字母", hex_digit);
      end
    endcase
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例4: casez语句 (Z作为通配符)
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例4: casez语句 (Z作为通配符) =====");
    
    logic [7:0] address;
    logic [3:0] region;
    
    // 地址译码: Z表示"不关心"该位
    address = 8'hF0;
    
    casez (address)
      8'b1zzz_zzzz: begin  // 0x80-0xFF
        region = 4'd1;
        $display("地址 %h 在区域1 (外设区)", address);
      end
      8'b01zz_zzzz: begin  // 0x40-0x7F
        region = 4'd2;
        $display("地址 %h 在区域2 (RAM区)", address);
      end
      8'b001z_zzzz: begin  // 0x20-0x3F
        region = 4'd3;
        $display("地址 %h 在区域3 (ROM区)", address);
      end
      8'b0001_zzzz: begin  // 0x10-0x1F
        region = 4'd4;
        $display("地址 %h 在区域4 (IO区)", address);
      end
      default: begin
        region = 4'd0;
        $display("地址 %h 在区域0 (保留区)", address);
      end
    endcase
    
    address = 8'h45;
    casez (address)
      8'b1zzz_zzzz: region = 1;
      8'b01zz_zzzz: begin
        region = 2;
        $display("地址 %h 在区域2 (RAM区)", address);
      end
      default: region = 0;
    endcase
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例5: casex语句 (X和Z作为通配符)
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例5: casex语句 (X/Z作为通配符) =====");
    
    logic [7:0] pattern;
    logic       match_found;
    
    // 中断优先级译码: X和Z都表示"不关心"
    // 注意: casez更安全,推荐优先使用casez
    
    pattern = 8'b1X00_0000;
    
    casex (pattern)
      8'b1xxx_xxxx: begin  // 最高位为1
        match_found = 1;
        $display("模式 %b 匹配: 最高优先级中断", pattern);
      end
      8'b01xx_xxxx: begin  // 次高位为1
        match_found = 1;
        $display("模式 %b 匹配: 中等优先级中断", pattern);
      end
      8'b001x_xxxx: begin
        match_found = 1;
        $display("模式 %b 匹配: 低优先级中断", pattern);
      end
      default: begin
        match_found = 0;
        $display("模式 %b 无匹配", pattern);
      end
    endcase
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例6: casez vs casex 对比
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例6: casez vs casex 对比 =====");
    
    logic [3:0] test_val;
    
    test_val = 4'b1X00;
    
    $display("测试值 = %b", test_val);
    
    // casez: 只把Z当作通配符
    // test_val中的X会被当作真实的X进行匹配
    casez (test_val)
      4'b1zzz: $display("casez: 匹配 1zzz");
      4'b10zz: $display("casez: 匹配 10zz");
      default: $display("casez: 无匹配 (X不是通配符)");
    endcase
    
    // casex: 把X和Z都当作通配符
    // test_val中的X会被当作通配符
    casex (test_val)
      4'b1zzz: $display("casex: 匹配 1zzz");
      4'b10zz: $display("casex: 匹配 10zz");
      default: $display("casex: 无匹配");
    endcase
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例7: 使用?代替Z (语法糖)
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例7: 使用?代替Z =====");
    
    logic [7:0] data;
    logic [1:0] type_id;
    
    data = 8'hA5;
    
    // 在casez中,?等价于Z,表示"不关心"
    casez (data)
      8'b????_??00: type_id = 2'b00;  // 低2位为00
      8'b????_??01: type_id = 2'b01;  // 低2位为01
      8'b????_??10: type_id = 2'b10;  // 低2位为10
      8'b????_??11: type_id = 2'b11;  // 低2位为11
    endcase
    
    $display("data = %b, type_id = %b", data, type_id);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例8: 综合中的case语句
  //--------------------------------------------------------------------------
  
  // 组合逻辑: 并行case (使用unique case)
  logic [7:0] parallel_mux;
  
  always_comb begin
    unique case (sel)
      2'b00: parallel_mux = in0;
      2'b01: parallel_mux = in1;
      2'b10: parallel_mux = in2;
      2'b11: parallel_mux = in3;
    endcase
  end
  
  // 优先级case (使用priority case)
  logic [3:0] priority_encoder;
  logic [7:0] request;
  logic [2:0] grant;
  
  always_comb begin
    priority case (1'b1)  // 从上到下优先级递减
      request[7]: grant = 3'd7;
      request[6]: grant = 3'd6;
      request[5]: grant = 3'd5;
      request[4]: grant = 3'd4;
      request[3]: grant = 3'd3;
      request[2]: grant = 3'd2;
      request[1]: grant = 3'd1;
      request[0]: grant = 3'd0;
      default:   grant = 3'd0;
    endcase
  end
  
  //--------------------------------------------------------------------------
  // 示例9: unique case vs priority case
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例9: unique case vs priority case =====");
    
    // unique case: 
    // - 告诉编译器case项互斥(不会同时匹配多项)
    // - 综合为并行逻辑(MUX)
    // - 运行时检查重叠,发现重叠会警告
    
    // priority case:
    // - 告诉编译器case项可能重叠,按顺序优先
    // - 综合为优先级逻辑(级联)
    // - 第一个匹配的项被执行
    
    $display("unique case   -> 综合为并行MUX (速度快,面积大)");
    $display("priority case -> 综合为优先级编码器 (速度慢,面积小)");
    
    // 示例: 优先级编码器测试
    request = 8'b00100100;  // bit2和bit5同时为1
    
    $display("request = %b", request);
    
    priority case (1'b1)
      request[7]: grant = 3'd7;
      request[6]: grant = 3'd6;
      request[5]: grant = 3'd5;  // 匹配这里 (最高优先级)
      request[4]: grant = 3'd4;
      request[3]: grant = 3'd3;
      request[2]: grant = 3'd2;  // 不会匹配,虽然为1
      request[1]: grant = 3'd1;
      request[0]: grant = 3'd0;
      default:   grant = 3'd0;
    endcase
    
    $display("grant = %0d (最高优先级的有效请求)", grant);
    
    $display("");
  end
  
  //--------------------------------------------------------------------------
  // 示例10: case在状态机中的应用
  //--------------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE   = 3'b000,
    START  = 3'b001,
    READ   = 3'b010,
    WRITE  = 3'b011,
    WAIT   = 3'b100,
    DONE   = 3'b101
  } state_t;
  
  state_t current_state, next_state;
  logic        start_cmd, done_cmd;
  logic [7:0]  data_reg;
  
  // 状态机: 状态转移逻辑
  always_comb begin
    next_state = current_state;  // 默认保持当前状态
    
    case (current_state)
      IDLE: begin
        if (start_cmd)
          next_state = START;
      end
      
      START: begin
        next_state = READ;
      end
      
      READ: begin
        next_state = WRITE;
      end
      
      WRITE: begin
        next_state = WAIT;
      end
      
      WAIT: begin
        if (done_cmd)
          next_state = DONE;
      end
      
      DONE: begin
        next_state = IDLE;
      end
      
      default: next_state = IDLE;
    endcase
  end

  //--------------------------------------------------------------------------
  // 测试状态机
  //--------------------------------------------------------------------------
  initial begin
    $display("===== 示例10: case在状态机中的应用 =====");
    
    current_state = IDLE;
    start_cmd = 1;
    done_cmd = 0;
    
    #1;
    $display("当前状态: %s, 下一状态: %s", current_state.name(), next_state.name());
    
    current_state = next_state;  // START
    start_cmd = 0;
    #1;
    $display("当前状态: %s, 下一状态: %s", current_state.name(), next_state.name());
    
    current_state = next_state;  // READ
    #1;
    $display("当前状态: %s, 下一状态: %s", current_state.name(), next_state.name());
    
    current_state = next_state;  // WRITE
    #1;
    $display("当前状态: %s, 下一状态: %s", current_state.name(), next_state.name());
    
    current_state = next_state;  // WAIT
    done_cmd = 1;
    #1;
    $display("当前状态: %s, 下一状态: %s", current_state.name(), next_state.name());
    
    #10;
    $finish;
  end

endmodule
