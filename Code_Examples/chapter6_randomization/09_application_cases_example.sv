//=====================================================================
// 章节：第6章 随机化
// 知识点：6.9 实际应用案例
// 文件名：09_application_cases_example.sv
// 描述：四个贴近真实工程的综合案例：
//   1. 以太网 MAC 层数据包随机生成
//   2. AXI 总线事务随机化
//   3. 寄存器配置随机化
//   4. 错误注入随机化
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module application_cases_demo;

  //=====================================================================
  // 案例一：以太网 MAC 层数据包
  //=====================================================================
  typedef enum bit [15:0] {
    ETH_IPV4  = 16'h0800,
    ETH_ARP   = 16'h0806,
    ETH_VLAN  = 16'h8100,
    ETH_IPV6  = 16'h86DD
  } eth_type_e;

  class EthPacket;
    rand bit [47:0] dst_mac;
    rand bit [47:0] src_mac;
    rand eth_type_e eth_type;
    rand bit [7:0]  payload[];
    rand bit [31:0] fcs;

    // 类型权重：IPv4 出现最多
    constraint c_type {
      eth_type dist {
        ETH_IPV4 := 50,
        ETH_ARP  := 20,
        ETH_VLAN := 15,
        ETH_IPV6 := 15
      };
    }

    // 载荷长度 46~1500（以太网最小/最大帧限制）
    constraint c_payload_size {
      payload.size() inside {[46:64]};  // 缩小范围方便演示
    }

    // 载荷值约束
    constraint c_payload_val {
      foreach (payload[i]) payload[i] inside {[0:255]};
    }

    // 广播地址（可选软约束，默认不启用）
    constraint c_broadcast {
      soft dst_mac != 48'hFFFF_FFFF_FFFF;
    }

    // post_randomize 计算 FCS（简化版：用异或校验代替 CRC32）
    function void post_randomize();
      fcs = 32'hDEAD_BEEF;  // 简化处理
      foreach (payload[i]) begin
        fcs = fcs ^ (32'(payload[i]) << (8 * (i % 4)));
      end
    endfunction

    // 打印函数
    function void display(int idx);
      $display("  [%0d] %s dst=%02h:%02h:%02h:%02h:%02h:%02h src=%02h:%02h:%02h:%02h:%02h:%02h type=0x%04h len=%0d fcs=0x%08h",
               idx, eth_type.name(),
               dst_mac[47:40], dst_mac[39:32], dst_mac[31:24],
               dst_mac[23:16], dst_mac[15:8],  dst_mac[7:0],
               src_mac[47:40], src_mac[39:32], src_mac[31:24],
               src_mac[23:16], src_mac[15:8],  src_mac[7:0],
               eth_type, payload.size(), fcs);
    endfunction
  endclass

  //=====================================================================
  // 案例二：AXI 总线事务
  //=====================================================================
  typedef enum bit [1:0] {
    FIXED  = 2'b00,
    INCR   = 2'b01,
    WRAP   = 2'b10
  } axi_burst_e;

  typedef enum bit [2:0] {
    BURST_LEN_1  = 3'b000,
    BURST_LEN_4  = 3'b010,
    BURST_LEN_8  = 3'b011,
    BURST_LEN_16 = 3'b111
  } axi_len_e;

  typedef enum {
    AXI_WRITE,
    AXI_READ
  } axi_dir_e;

  class AxiTransaction;
    rand axi_dir_e   direction;
    rand bit [31:0]  addr;
    rand axi_burst_e burst;
    rand axi_len_e   len;
    rand bit [2:0]   size;     // 数据宽度：000=1B, 001=2B, 010=4B, 011=8B
    rand bit [7:0]   data[];
    rand bit [7:0]   strb[];

    // 读事务无数据
    constraint c_no_read_data {
      (direction == AXI_READ) -> data.size() == 0;
      (direction == AXI_READ) -> strb.size() == 0;
    }

    // 写事务数据大小与 burst len 匹配
    constraint c_write_data {
      (direction == AXI_WRITE) -> data.size() == get_burst_len();
      (direction == AXI_WRITE) -> strb.size() == get_burst_len();
    }

    // 地址对齐约束
    constraint c_align {
      (size == 3'b000) -> (addr % 1 == 0);
      (size == 3'b001) -> (addr % 2 == 0);
      (size == 3'b010) -> (addr % 4 == 0);
      (size == 3'b011) -> (addr % 8 == 0);
    }

    // 地址范围
    constraint c_addr {
      addr inside {[32'h0000_0000 : 32'h0000_FFFF]};
    }

    // 数据值
    constraint c_data_val {
      foreach (data[i]) data[i] inside {[0:255]};
    }

    // strobe 与 size 匹配
    constraint c_strb {
      foreach (strb[i]) strb[i] inside {[0:15]};
    }

    // 辅助函数：获取 burst 长度
    function int get_burst_len();
      case (len)
        BURST_LEN_1:  return 1;
        BURST_LEN_4:  return 4;
        BURST_LEN_8:  return 8;
        BURST_LEN_16: return 16;
        default:      return 1;
      endcase
    endfunction

    // 打印函数
    function void display(int idx);
      $write("  [%0d] %s addr=0x%08h burst=%s len=%s size=%0d",
             idx, direction.name(), addr, burst.name(), len.name(),
             2**(int'(size)));
      if (direction == AXI_WRITE) begin
        $write(" data[%0d]=", data.size());
        for (int i = 0; i < data.size() && i < 4; i++)
          $write("%02h", data[i]);
        if (data.size() > 4) $write("...");
      end
      $display("");
    endfunction
  endclass

  //=====================================================================
  // 案例三：寄存器配置随机化
  //=====================================================================
  class RegisterConfig;
    // 寄存器0：控制寄存器
    rand bit [1:0] mode;        // 00=正常, 01=低功耗, 10=高性能, 11=测试
    rand bit       int_enable;  // 中断使能
    rand bit       dma_en;      // DMA 使能

    // 寄存器1：定时器配置
    rand bit [15:0] timer_period;
    rand bit [3:0]  timer_prescaler;

    // 寄存器2：地址窗口
    rand bit [31:0] base_addr;
    rand bit [11:0] window_size;

    // 互斥约束：测试模式和 DMA 不能同时使能
    constraint c_test_dma_mutex {
      (mode == 2'b11) -> dma_en == 0;
    }

    // 低功耗模式下不使能 DMA
    constraint c_lp_no_dma {
      (mode == 2'b01) -> dma_en == 0;
    }

    // 地址对齐到 4KB 边界
    constraint c_base_align {
      base_addr[11:0] == 12'h000;
    }

    // 地址范围
    constraint c_addr_range {
      base_addr inside {[32'h2000_0000 : 32'h2000_F000]};
    }

    // 窗口大小必须为 4KB 的整数倍
    constraint c_window {
      window_size inside {12'h001, 12'h004, 12'h010, 12'h040};
    }

    // 定时器参数
    constraint c_timer {
      timer_period inside {[100:65535]};
      timer_prescaler inside {[1:15]};
    }

    // 模式权重：正常模式出现更多
    constraint c_mode_weight {
      mode dist {
        2'b00 := 50,
        2'b01 := 20,
        2'b10 := 20,
        2'b11 := 10
      };
    }

    // 打印函数
    function void display(int idx);
      string mode_str;
      case (mode)
        2'b00: mode_str = "NORMAL ";
        2'b01: mode_str = "LP     ";
        2'b10: mode_str = "HIGH   ";
        2'b11: mode_str = "TEST   ";
      endcase
      $display("  [%0d] mode=%s int=%0b dma=%0b | timer: period=%0d prescale=%0d | addr=0x%08h win=%0dKB",
               idx, mode_str, int_enable, dma_en,
               timer_period, timer_prescaler,
               base_addr, window_size * 4);
    endfunction
  endclass

  //=====================================================================
  // 案例四：错误注入
  //=====================================================================
  typedef enum bit [2:0] {
    ERR_NONE     = 3'b000,
    ERR_CRC      = 3'b001,  // CRC 校验错误
    ERR_PARITY   = 3'b010,  // 奇偶校验错误
    ERR_TIMEOUT  = 3'b011,  // 超时
    ERR_PROTOCOL = 3'b100,  // 协议违例
    ERR_DATA_CORRUPT = 3'b101  // 数据损坏
  } err_type_e;

  class ErrorInjectionTxn;
    rand bit [7:0]  addr;
    rand bit [31:0] data;
    rand bit [3:0]  length;      // 事务长度
    rand bit        inject_err;  // 是否注入错误
    rand err_type_e err_type;    // 错误类型
    rand bit [2:0]  err_pos;     // 错误位置（第几个 beat）

    // 默认不注入错误
    constraint c_no_inject {
      soft inject_err == 0;
    }

    // 地址和数据范围
    constraint c_addr {
      addr inside {[0:63]};
    }

    constraint c_data {
      data inside {[1:32'hFFFF_FFFE]};
    }

    constraint c_len {
      length inside {[1:8]};
    }

    // 注入错误时，错误位置有效
    constraint c_err_pos {
      (inject_err == 1) -> err_pos < length;
      (inject_err == 1) -> err_pos > 0;  // 第一个 beat 不出错
    }

    // 错误类型权重
    constraint c_err_weight {
      err_type dist {
        ERR_CRC         := 30,
        ERR_PARITY      := 25,
        ERR_TIMEOUT     := 15,
        ERR_PROTOCOL    := 15,
        ERR_DATA_CORRUPT := 15
      };
    }

    // 注入错误后的数据修改（软约束，可在 post 中处理）
    function void post_randomize();
      if (inject_err) begin
        case (err_type)
          ERR_CRC:         data = data ^ 32'hFFFF_0000;
          ERR_PARITY:      data[0] = ~data[0];
          ERR_DATA_CORRUPT: data = 32'hDEAD_BEEF;
          default: ;  // TIMEOUT 和 PROTOCOL 不改 data
        endcase
      end
    endfunction

    // 打印函数
    function void display(int idx);
      if (inject_err) begin
        $display("  [%0d] *** ERROR *** addr=0x%02h data=0x%08h len=%0d err_type=%s err_pos=%0d",
                 idx, addr, data, length, err_type.name(), err_pos);
      end else begin
        $display("  [%0d]    NORMAL    addr=0x%02h data=0x%08h len=%0d",
                 idx, addr, data, length);
      end
    endfunction
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    EthPacket         eth_pkt;
    AxiTransaction    axi_pkt;
    RegisterConfig    reg_cfg;
    ErrorInjectionTxn err_txn;

    eth_pkt = new();
    axi_pkt = new();
    reg_cfg = new();
    err_txn = new();

    $display("\n================================================");
    $display("        第6章 6.9 实际应用案例 示例演示");
    $display("================================================\n");

    //=====================================================================
    // 案例一：以太网数据包
    //=====================================================================
    $display("【案例一】以太网 MAC 层数据包随机生成\n");

    for (int i = 0; i < 5; i++) begin
      if (eth_pkt.randomize()) begin
        eth_pkt.display(i);
      end
    end

    $display("  --- 广播包（覆盖 soft 约束）---");
    for (int i = 0; i < 2; i++) begin
      if (eth_pkt.randomize() with { dst_mac == 48'hFFFF_FFFF_FFFF; }) begin
        eth_pkt.display(i);
      end
    end
    $display("  说明：dist 控制协议类型权重，payload.size() 控制帧长，post 计算 FCS\n");

    //=====================================================================
    // 案例二：AXI 总线事务
    //=====================================================================
    $display("\n【案例二】AXI 总线事务随机化\n");

    $display("  --- 混合读写事务 ---");
    for (int i = 0; i < 6; i++) begin
      if (axi_pkt.randomize()) begin
        axi_pkt.display(i);
      end
    end

    $display("  --- 强制读事务 ---");
    for (int i = 0; i < 3; i++) begin
      if (axi_pkt.randomize() with { direction == AXI_READ; burst == INCR; len == BURST_LEN_4; }) begin
        axi_pkt.display(i);
      end
    end
    $display("  说明：条件约束确保读事务无数据，地址对齐保证协议合法\n");

    //=====================================================================
    // 案例三：寄存器配置
    //=====================================================================
    $display("\n【案例三】寄存器配置随机化\n");

    $display("  --- 随机配置 ---");
    for (int i = 0; i < 5; i++) begin
      if (reg_cfg.randomize()) begin
        reg_cfg.display(i);
      end
    end

    $display("  --- 测试模式配置 ---");
    for (int i = 0; i < 3; i++) begin
      if (reg_cfg.randomize() with { mode == 2'b11; int_enable == 1; }) begin
        reg_cfg.display(i);
      end
    end
    $display("  验证：测试模式下 DMA 必须关闭（互斥约束生效）\n");

    //=====================================================================
    // 案例四：错误注入
    //=====================================================================
    $display("\n【案例四】错误注入随机化\n");

    $display("  --- 正常事务（软约束生效，不注入错误）---");
    for (int i = 0; i < 3; i++) begin
      if (err_txn.randomize()) begin
        err_txn.display(i);
      end
    end

    $display("  --- 注入错误（覆盖软约束）---");
    for (int i = 0; i < 5; i++) begin
      if (err_txn.randomize() with { inject_err == 1; }) begin
        err_txn.display(i);
      end
    end

    $display("  --- 指定错误类型：CRC 错误 ---");
    for (int i = 0; i < 3; i++) begin
      if (err_txn.randomize() with { inject_err == 1; err_type == ERR_CRC; }) begin
        err_txn.display(i);
      end
    end
    $display("  说明：soft 默认不注入，inline 覆盖后按 dist 权重选错误类型，post_randomize 修改数据\n");

    #10 $finish;
  end

endmodule
