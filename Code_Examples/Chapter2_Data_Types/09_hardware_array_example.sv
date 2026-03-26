//===========================================
// 知识点: 数组在硬件建模中的应用
// 章节: 第2章 SystemVerilog数据类型
//===========================================

module hardware_array_example(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        wr_en,
    input  logic        rd_en,
    output logic [31:0] data_out,
    output logic        full,
    output logic        empty
);
    // 寄存器堆 - 非压缩数组(16个8位寄存器)
    logic [7:0] register_file [0:15];
    
    // FIFO缓冲 - 非压缩数组(16个32位数据)
    logic [31:0] fifo_buffer [16];
    
    // FIFO指针
    int fifo_wr_ptr = 0;
    int fifo_rd_ptr = 0;
    int fifo_count  = 0;
    
    // FIFO状态信号
    assign full  = (fifo_count == 16);
    assign empty = (fifo_count == 0);
    
    // 寄存器堆写入(简化示例:写入地址0)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            register_file[0] <= 8'h00;
        end else if (wr_en && !full) begin
            register_file[0] <= data_in;
            $display("[%0t] 写寄存器: reg[0] = 0x%h", $time, data_in);
        end
    end
    
    // FIFO操作
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count  <= 0;
            for (int i = 0; i < 16; i++) begin
                fifo_buffer[i] <= 32'h0;
            end
        end else begin
            // 写FIFO
            if (wr_en && !full) begin
                fifo_buffer[fifo_wr_ptr] <= {4{data_in}};
                fifo_wr_ptr <= (fifo_wr_ptr + 1) % 16;
                fifo_count <= fifo_count + 1;
                $display("[%0t] FIFO写入: buffer[%0d] = 0x%h", 
                         $time, fifo_wr_ptr, {4{data_in}});
            end
            
            // 读FIFO
            if (rd_en && !empty) begin
                fifo_rd_ptr <= (fifo_rd_ptr + 1) % 16;
                fifo_count <= fifo_count - 1;
                $display("[%0t] FIFO读取: buffer[%0d] = 0x%h", 
                         $time, fifo_rd_ptr, fifo_buffer[fifo_rd_ptr]);
            end
        end
    end
    
    // 输出数据
    assign data_out = fifo_buffer[fifo_rd_ptr];
    
endmodule

// 测试平台
module tb_hardware_array;
    logic        clk;
    logic        rst_n;
    logic [7:0]  data_in;
    logic        wr_en;
    logic        rd_en;
    logic [31:0] data_out;
    logic        full;
    logic        empty;
    
    // 实例化
    hardware_array_example uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 测试
    initial begin
        $display("=== 硬件数组应用测试 ===\n");
        
        // 初始化
        rst_n = 0;
        data_in = 0;
        wr_en = 0;
        rd_en = 0;
        
        // 复位
        #20 rst_n = 1;
        #10;
        
        // 写入数据
        repeat(3) begin
            @(posedge clk);
            data_in = $urandom_range(0, 255);
            wr_en = 1;
            $display("[%0t] 输入数据: 0x%h", $time, data_in);
        end
        
        @(posedge clk);
        wr_en = 0;
        
        // 读取数据
        #20;
        repeat(3) begin
            @(posedge clk);
            rd_en = 1;
        end
        
        @(posedge clk);
        rd_en = 0;
        
        #50 $finish;
    end
endmodule
