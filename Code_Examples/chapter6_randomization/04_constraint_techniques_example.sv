//=====================================================================
// 章节：第6章 随机化
// 知识点：6.4 约束的技巧
// 文件名：04_constraint_techniques_example.sv
// 描述：演示高级约束技巧：唯一性、求和、条件控制、
//       constraint_mode、rand_mode、错误注入等
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module constraint_techniques_demo;

  //=====================================================================
  // 类1：数组唯一性约束 + 求和约束
  //=====================================================================
  class ArrayUniqueDemo;
    rand bit [7:0] unique_arr[6];   // 元素互不相同的数组
    rand bit [7:0] sorted_arr[5];   // 递增排序的数组
    rand int         total_sum;
    
    // 唯一性约束：每个元素必须互不相同
    constraint c_unique {
      foreach (unique_arr[i]) begin
        foreach (unique_arr[j]) begin
          if (i != j) unique_arr[i] != unique_arr[j];
        end
        unique_arr[i] inside {[1:50]};  // 范围1-50
      end
    }
    
    // 排序约束：非递减序列
    constraint c_sorted {
      foreach (sorted_arr[i]) begin
        sorted_arr[i] inside {[0:99]};
        if (i > 0) sorted_arr[i] >= sorted_arr[i-1];
      end
    }
    
    // 数组求和约束
    constraint c_sum {
      total_sum == sorted_arr.sum() with (int'(item));
      total_sum < 400;
    }
  endclass

  //=====================================================================
  // 类2：状态机转换约束
  //=====================================================================
  typedef enum {IDLE, FETCH, EXEC, WB} state_e;

  class StateMachineDemo;
    rand state_e current_state;
    rand state_e next_state;
    rand bit [7:0] delay_cycles;
    
    // 状态转换规则
    constraint c_transition {
      (current_state == IDLE)  -> next_state inside {IDLE, FETCH};
      (current_state == FETCH) -> next_state inside {FETCH, EXEC};
      (current_state == EXEC)  -> next_state inside {EXEC, WB};
      (current_state == WB)    -> next_state inside {WB, IDLE};
    }
    
    // 延迟约束：根据状态调整延迟
    constraint c_delay {
      if (current_state == IDLE)  delay_cycles inside {[1:5]};
      else if (current_state == FETCH) delay_cycles inside {[3:10]};
      else delay_cycles inside {[1:3]};
    }
  endclass

  //=====================================================================
  // 类3：约束控制（constraint_mode / rand_mode）
  //=====================================================================
  class ConstraintControlDemo;
    rand bit [7:0] addr;
    rand bit [7:0] data;
    rand bit [3:0] cmd;
    
    constraint c_addr_range {
      addr inside {[10:20]};
    }
    
    constraint c_data_range {
      data inside {[0:99]};
    }
    
    constraint c_cmd_valid {
      cmd inside {0, 2, 4, 8};
    }
  endclass

  //=====================================================================
  // 类4：错误注入约束
  //=====================================================================
  class ErrorInjectionDemo;
    rand bit        inject_err;
    rand bit [2:0]  err_type;     // 1-5有效错误类型
    rand bit [31:0] payload;
    rand bit [7:0]  checksum;
    
    // 默认不注入错误
    constraint c_err_control {
      soft inject_err == 0;
      (inject_err == 1) -> err_type inside {[1:5]};
    }
    
    // 正常事务约束
    constraint c_normal {
      payload != 0;
    }
    
    // 错误注入：payload设为特殊值
    constraint c_err_payload {
      (inject_err == 1) -> payload inside {
        32'hDEAD_BEEF,
        32'hCAFE_BABE,
        32'hFFFF_FFFF
      };
    }
    
    // 计算校验和
    constraint c_checksum {
      if (inject_err == 0) begin
        // 正常时校验和正确
        checksum == payload[7:0] ^ payload[15:8] ^ 
                     payload[23:16] ^ payload[31:24];
      end else begin
        // 注入错误时校验和故意错误
        checksum != (payload[7:0] ^ payload[15:8] ^ 
                     payload[23:16] ^ payload[31:24]);
      end
    }
  endclass

  //=====================================================================
  // 类5：FIFO验证约束
  //=====================================================================
  class FifoDemo;
    rand bit       push_en;
    rand bit       pop_en;
    rand bit [7:0] push_data;
    rand int       fifo_level;  // 当前FIFO中数据量
    
    // FIFO不能为空时弹出
    constraint c_no_empty_pop {
      (fifo_level == 0) -> pop_en == 0;
    }
    
    // FIFO不能为满时推入
    constraint c_no_full_push {
      (fifo_level == 16) -> push_en == 0;
    }
    
    // 推入数据有效
    constraint c_push_valid {
      (push_en == 1) -> push_data != 0;
    }
    
    // FIFO级别范围
    constraint c_fifo_level {
      fifo_level inside {[0:16]};
    }
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    ArrayUniqueDemo       unique_pkt;
    StateMachineDemo      state_pkt;
    ConstraintControlDemo ctrl_pkt;
    ErrorInjectionDemo    err_pkt;
    FifoDemo              fifo_pkt;
    
    unique_pkt = new();
    state_pkt  = new();
    ctrl_pkt   = new();
    err_pkt    = new();
    fifo_pkt   = new();
    
    $display("\n================================================");
    $display("        第6章 6.4 约束的技巧 示例演示");
    $display("================================================\n");
    
    //=====================================================================
    // 场景1：数组唯一性 + 排序 + 求和
    //=====================================================================
    $display("【场景1】数组唯一性 + 排序 + 求和约束\n");
    
    for (int i = 0; i < 5; i++) begin
      if (unique_pkt.randomize()) begin
        $write("  唯一数组: ");
        for (int j = 0; j < 6; j++) $write("%3d ", unique_pkt.unique_arr[j]);
        $display("(6个值互不相同)");
        
        $write("  排序数组: ");
        for (int j = 0; j < 5; j++) $write("%3d ", unique_pkt.sorted_arr[j]);
        $display("(非递减) sum=%0d", unique_pkt.total_sum);
        $display("");
      end
    end
    
    //=====================================================================
    // 场景2：状态机转换约束
    //=====================================================================
    $display("【场景2】状态机转换约束\n");
    $display("  合法转换: IDLE->FETCH, FETCH->EXEC, EXEC->WB, WB->IDLE\n");
    
    for (int i = 0; i < 8; i++) begin
      if (state_pkt.randomize()) begin
        $display("  %0d: %s --(%0d cycles)--> %s",
                 i,
                 state_pkt.current_state.name(),
                 state_pkt.delay_cycles,
                 state_pkt.next_state.name());
      end
    end
    $display("  验证：所有状态转换都是合法的\n");
    
    //=====================================================================
    // 场景3：constraint_mode 控制
    //=====================================================================
    $display("【场景3】constraint_mode 控制\n");
    
    $display("  --- 所有约束启用（默认）---");
    for (int i = 0; i < 3; i++) begin
      if (ctrl_pkt.randomize()) begin
        $display("  addr=%3d, data=%3d, cmd=%d",
                 ctrl_pkt.addr, ctrl_pkt.data, ctrl_pkt.cmd);
      end
    end
    
    $display("  --- 禁用c_addr_range约束 ---");
    ctrl_pkt.c_addr_range.constraint_mode(0);  // 禁用地址范围约束
    for (int i = 0; i < 3; i++) begin
      if (ctrl_pkt.randomize()) begin
        $display("  addr=%3d, data=%3d, cmd=%d",
                 ctrl_pkt.addr, ctrl_pkt.data, ctrl_pkt.cmd);
      end
    end
    $display("  说明：addr不再受[10:20]限制，可为任意值\n");
    
    $display("  --- 禁用所有约束 ---");
    ctrl_pkt.constraint_mode(0);  // 禁用全部约束
    for (int i = 0; i < 3; i++) begin
      if (ctrl_pkt.randomize()) begin
        $display("  addr=%3d, data=%3d, cmd=%d",
                 ctrl_pkt.addr, ctrl_pkt.data, ctrl_pkt.cmd);
      end
    end
    $display("  说明：addr/data/cmd都是全范围随机，cmd可能为1/3/5/7\n");
    
    // 恢复约束
    ctrl_pkt.constraint_mode(1);
    
    //=====================================================================
    // 场景4：rand_mode 控制
    //=====================================================================
    $display("【场景4】rand_mode 控制\n");
    
    ctrl_pkt.addr = 15;  // 手动设置addr
    ctrl_pkt.addr.rand_mode(0);  // 禁用addr的随机化
    $display("  addr固定为15（rand_mode=0）:");
    for (int i = 0; i < 3; i++) begin
      if (ctrl_pkt.randomize()) begin
        $display("  addr=%3d(fixed), data=%3d, cmd=%d",
                 ctrl_pkt.addr, ctrl_pkt.data, ctrl_pkt.cmd);
      end
    end
    $display("  说明：addr始终为15，data和cmd仍随机化\n");
    ctrl_pkt.addr.rand_mode(1);  // 恢复
    
    //=====================================================================
    // 场景5：错误注入约束
    //=====================================================================
    $display("【场景5】错误注入约束\n");
    
    $display("  --- 正常事务（软约束生效，不注入错误）---");
    for (int i = 0; i < 3; i++) begin
      if (err_pkt.randomize()) begin
        $display("  err=%0d, payload=0x%08h, checksum=0x%02h",
                 err_pkt.inject_err, err_pkt.payload, err_pkt.checksum);
      end
    end
    
    $display("  --- 注入错误（用with覆盖软约束）---");
    for (int i = 0; i < 3; i++) begin
      if (err_pkt.randomize() with { inject_err == 1; }) begin
        $display("  err=%0d, type=%0d, payload=0x%08h, checksum=0x%02h",
                 err_pkt.inject_err, err_pkt.err_type,
                 err_pkt.payload, err_pkt.checksum);
      end
    end
    $display("  说明：正常事务payload和checksum匹配；错误事务payload为特殊值，checksum故意错误\n");
    
    //=====================================================================
    // 场景6：FIFO验证约束
    //=====================================================================
    $display("【场景6】FIFO验证约束\n");
    
    $display("  --- 正常FIFO操作 ---");
    fifo_pkt.fifo_level = 5;  // FIFO中有5个数据
    for (int i = 0; i < 5; i++) begin
      if (fifo_pkt.randomize() with { fifo_level == 5; }) begin
        $display("  level=%2d: push=%0d, pop=%0d, data=0x%02h",
                 fifo_pkt.fifo_level, fifo_pkt.push_en,
                 fifo_pkt.pop_en, fifo_pkt.push_data);
      end
    end
    
    $display("  --- FIFO为空时（level=0）---");
    for (int i = 0; i < 3; i++) begin
      if (fifo_pkt.randomize() with { fifo_level == 0; }) begin
        $display("  level=%2d: push=%0d, pop=%0d",
                 fifo_pkt.fifo_level, fifo_pkt.push_en, fifo_pkt.pop_en);
      end
    end
    $display("  验证：FIFO为空时pop_en始终为0\n");
    
    $display("  --- FIFO为满时（level=16）---");
    for (int i = 0; i < 3; i++) begin
      if (fifo_pkt.randomize() with { fifo_level == 16; }) begin
        $display("  level=%2d: push=%0d, pop=%0d, data=0x%02h",
                 fifo_pkt.fifo_level, fifo_pkt.push_en,
                 fifo_pkt.pop_en, fifo_pkt.push_data);
      end
    end
    $display("  验证：FIFO为满时push_en始终为0\n");
    
    #10 $finish;
  end

endmodule
