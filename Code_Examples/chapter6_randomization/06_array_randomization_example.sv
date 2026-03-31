//=====================================================================
// 章节：第6章 随机化
// 知识点：6.6 数组的随机化
// 文件名：06_array_randomization_example.sv
// 描述：演示定长数组、动态数组、关联数组、队列的随机化，
//       以及数组大小约束、元素约束、求和约束、交叉约束等
// 作者：数字IC验证工程师
// 日期：2026.03.27
//=====================================================================

`timescale 1ns/1ps

module array_randomization_demo;

  //=====================================================================
  // 类1：定长数组随机化
  //=====================================================================
  class FixedArrayDemo;
    rand bit [7:0] arr[8];  // 固定8个元素

    constraint c_val {
      foreach (arr[i]) arr[i] inside {[10:99]};
    }
  endclass

  //=====================================================================
  // 类2：动态数组随机化
  //=====================================================================
  class DynArrayDemo;
    rand bit [7:0] payload[];

    constraint c_size {
      payload.size() inside {[2:12]};
    }

    constraint c_val {
      foreach (payload[i]) payload[i] inside {[0:255]};
    }
  endclass

  //=====================================================================
  // 类3：关联数组随机化
  //=====================================================================
  class AssocArrayDemo;
    rand int       idx[];
    rand bit [7:0] config_reg[int];

    constraint c_num {
      config_reg.num() inside {[2:6]};
    }

    constraint c_idx {
      foreach (config_reg[i]) i inside {[0:15]};
    }

    constraint c_val {
      foreach (config_reg[i]) config_reg[i] inside {[1:100]};
    }
  endclass

  //=====================================================================
  // 类4：数组求和与交叉约束
  //=====================================================================
  class ArraySumDemo;
    rand bit [7:0] data[];
    rand int       total;

    constraint c_size {
      data.size() inside {[3:8]};
    }

    constraint c_val {
      foreach (data[i]) data[i] inside {[0:50]};
    }

    // 数组求和约束
    constraint c_sum {
      total == data.sum() with (int'(item));
    }

    // 求和上限约束
    constraint c_sum_limit {
      total < 200;
    }
  endclass

  //=====================================================================
  // 类5：数组与标量变量的交叉约束
  //=====================================================================
  class CrossConstraintDemo;
    rand bit [3:0] header;      // 标量变量
    rand bit [7:0] payload[];

    constraint c_size {
      payload.size() inside {[1:8]};
    }

    // 数组大小由 header 决定
    constraint c_header_size {
      payload.size() == header + 1;  // header=0→size=1, header=15→size=16
      header inside {[0:7]};          // 限制 header 范围，避免 size 过大
    }

    // 所有元素 >= header 值
    constraint c_elem_ge {
      foreach (payload[i]) payload[i] >= header * 10;
    }
  endclass

  //=====================================================================
  // 类6：队列随机化
  //=====================================================================
  class QueueDemo;
    rand int       data_q[$];  // 整型队列
    rand bit [7:0] byte_q[$];  // 字节队列

    constraint c_q1_size {
      data_q.size() inside {[2:6]};
    }

    constraint c_q1_val {
      foreach (data_q[i]) data_q[i] inside {[0:99]};
    }

    constraint c_q2_size {
      byte_q.size() inside {[1:4]};
    }

    constraint c_q2_val {
      foreach (byte_q[i]) byte_q[i] inside {[0:255]};
    }
  endclass

  //=====================================================================
  // 测试执行
  //=====================================================================
  initial begin
    FixedArrayDemo      fixed_pkt;
    DynArrayDemo        dyn_pkt;
    AssocArrayDemo      assoc_pkt;
    ArraySumDemo        sum_pkt;
    CrossConstraintDemo cross_pkt;
    QueueDemo           queue_pkt;

    fixed_pkt = new();
    dyn_pkt   = new();
    assoc_pkt = new();
    sum_pkt   = new();
    cross_pkt = new();
    queue_pkt = new();

    $display("\n================================================");
    $display("        第6章 6.6 数组的随机化 示例演示");
    $display("================================================\n");

    //=====================================================================
    // 场景1：定长数组
    //=====================================================================
    $display("【场景1】定长数组随机化（固定8个元素，每个∈[10:99]）\n");

    for (int i = 0; i < 3; i++) begin
      if (fixed_pkt.randomize()) begin
        $write("  第%0d次: ", i+1);
        for (int j = 0; j < 8; j++) $write("%3d ", fixed_pkt.arr[j]);
        $display("(size=8 固定)");
      end
    end
    $display("  说明：数组大小固定为8，每次只随机化元素值\n");

    //=====================================================================
    // 场景2：动态数组 —— 大小和元素都随机
    //=====================================================================
    $display("【场景2】动态数组随机化（size∈[2:12]，元素∈[0:255]）\n");

    for (int i = 0; i < 5; i++) begin
      if (dyn_pkt.randomize()) begin
        $write("  第%0d次: size=%2d, val=[", i+1, dyn_pkt.payload.size());
        for (int j = 0; j < dyn_pkt.payload.size(); j++) begin
          $write("%3d", dyn_pkt.payload[j]);
          if (j < dyn_pkt.payload.size()-1) $write(",");
        end
        $display("]");
      end
    end
    $display("  说明：每次随机化，数组大小和元素值都不同\n");

    // inline 约束固定大小
    $display("  --- inline 约束：固定 size=5 ---");
    for (int i = 0; i < 3; i++) begin
      if (dyn_pkt.randomize() with { payload.size() == 5; }) begin
        $write("  size=%2d, val=[", dyn_pkt.payload.size());
        for (int j = 0; j < dyn_pkt.payload.size(); j++) begin
          $write("%3d", dyn_pkt.payload[j]);
          if (j < dyn_pkt.payload.size()-1) $write(",");
        end
        $display("]");
      end
    end
    $display("  说明：inline 约束覆盖类内约束，大小固定为 5\n");

    //=====================================================================
    // 场景3：关联数组
    //=====================================================================
    $display("【场景3】关联数组随机化（num∈[2:6]，索引∈[0:15]，值∈[1:100]）\n");

    for (int i = 0; i < 3; i++) begin
      if (assoc_pkt.randomize()) begin
        $display("  第%0d次: num=%0d", i+1, assoc_pkt.config_reg.num());
        foreach (assoc_pkt.config_reg[idx]) begin
          $display("    config_reg[%2d] = %3d", idx, assoc_pkt.config_reg[idx]);
        end
      end
    end
    $display("  说明：关联数组的索引不连续，元素个数随机\n");

    //=====================================================================
    // 场景4：数组求和约束
    //=====================================================================
    $display("【场景4】数组求和约束（total == sum(data)，且 total < 200）\n");

    for (int i = 0; i < 5; i++) begin
      if (sum_pkt.randomize()) begin
        $write("  第%0d次: size=%2d, data=[", i+1, sum_pkt.data.size());
        for (int j = 0; j < sum_pkt.data.size(); j++) begin
          $write("%2d", sum_pkt.data[j]);
          if (j < sum_pkt.data.size()-1) $write("+");
        end
        $display("] = %0d (< 200)", sum_pkt.total);
      end
    end
    $display("  说明：total 自动等于数组元素之和，且受到 < 200 的约束\n");

    //=====================================================================
    // 场景5：数组与标量变量的交叉约束
    //=====================================================================
    $display("【场景5】数组与标量交叉约束\n");
    $display("  约束: payload.size() == header+1, payload[i] >= header*10\n");

    for (int i = 0; i < 5; i++) begin
      if (cross_pkt.randomize()) begin
        $write("  header=%2d, size=%2d, payload=[", 
               cross_pkt.header, cross_pkt.payload.size());
        for (int j = 0; j < cross_pkt.payload.size(); j++) begin
          $write("%3d", cross_pkt.payload[j]);
          if (j < cross_pkt.payload.size()-1) $write(",");
        end
        $display("]");
      end
    end
    $display("  验证：size = header+1，所有元素 >= header*10\n");

    //=====================================================================
    // 场景6：队列随机化
    //=====================================================================
    $display("【场景6】队列随机化\n");

    for (int i = 0; i < 3; i++) begin
      if (queue_pkt.randomize()) begin
        $write("  data_q (size=%2d): [", queue_pkt.data_q.size());
        for (int j = 0; j < queue_pkt.data_q.size(); j++) begin
          $write("%3d", queue_pkt.data_q[j]);
          if (j < queue_pkt.data_q.size()-1) $write(",");
        end
        $write("]  byte_q (size=%2d): [", queue_pkt.byte_q.size());
        for (int j = 0; j < queue_pkt.byte_q.size(); j++) begin
          $write("%3d", queue_pkt.byte_q[j]);
          if (j < queue_pkt.byte_q.size()-1) $write(",");
        end
        $display("]");
      end
    end
    $display("  说明：队列的随机化方式与动态数组完全相同\n");

    #10 $finish;
  end

endmodule
