//===========================================
// 知识点: logic类型
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module logic_example;
    // 声明logic类型变量
    logic [7:0] data_bus;
    logic       clk;
    logic       reset_n;
    
    // 连续赋值驱动logic变量
    assign clk = 1'b0;
    
    // 过程赋值驱动logic变量
    initial begin
        reset_n = 1'b0;
        #10 reset_n = 1'b1;
        data_bus = 8'hFF;
        
        $display("Time: %0t, reset_n = %b, data_bus = 0x%h", 
                 $time, reset_n, data_bus);
    end
    
    // 注意:logic类型不能有多个驱动
    // 以下代码会报错:
    // logic a;
    // assign a = b;        // 驱动1
    // always @(c) a = c;   // 驱动2 - 错误!
    
endmodule
