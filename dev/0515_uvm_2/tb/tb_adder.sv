interface adder_if();
    logic clk;
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] y;
endinterface //adder_if()

`include "uvm_macros.svh"
import uvm_pkg::*;

class adder_seq_item extends uvm_sequence_item;
    rand bit [7:0] a;
    rand bit [7:0] b;
    bit [8:0] y;

    function new(string name = "ITEM");
        super.new(name);
    endfunction //new()

    `uvm_object_utils_begin(adder_seq_item) // a, b, y 값 factory 등록
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end
endclass //adder_seq_item extends uvm_sequence_item

class adder_sequence extends uvm_sequence #(adder_seq_item);
    `uvm_object_utils(adder_sequence) // factory 등록

    function new(string name = "SEQ"); // component 상속이 아니므로 name만 적으면 됨
        super.new(name);
    endfunction //new()

    adder_seq_item adder_item;

    virtual task body();
        adder_item = adder_seq_item::type_id::create("ITEM");

        for (int i = 0; i < 100; i++) begin // test 횟수
            start_item(adder_item);

            adder_item.randomize();
            $display(""); // 한줄 띄우기
            `uvm_info("SEQ", $sformatf("adder item to drive a:%0d, b:%0d", adder_item.a, adder_item.b), UVM_NONE);
            // adder_item.print(uvm_default_line_printer);

            finish_item(adder_item);
        end
    endtask //
endclass //adder_sequence extends uvm_sequence #(adder_seq_item)

class adder_driver extends uvm_driver #(adder_seq_item);
    `uvm_component_utils(adder_driver)

    function new(string name = "DRV", uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    adder_seq_item adder_item;
    virtual adder_if a_if;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ITEM");

        if (!uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if)) begin
            `uvm_fatal("DRV", "adder_if not found in uvm_config_db");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(adder_item);
            @(posedge a_if.clk);
            
            a_if.a = adder_item.a;
            a_if.b = adder_item.b;
            `uvm_info("DRV", $sformatf("Drive DUT a:%0d, b:%0d", adder_item.a, adder_item.b), UVM_LOW); // 받은 값 출력
            // adder_item.print(uvm_default_line_printer);

            #1; // clk 맞추기 위한 delay
            seq_item_port.item_done();
            // #10;
        end
    endtask //

endclass //adder_driver extends uvm_driver #(adder_seq_item)

class adder_monitor extends uvm_monitor;
    `uvm_component_utils(adder_monitor)

    uvm_analysis_port #(adder_seq_item) send; // scoreboard 와의 통로 (mon : 보내는 쪽, scb : 받는 쪽)

    function new(string name = "MON", uvm_component parent);
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction //new()

    adder_seq_item adder_item;
    
    virtual adder_if a_if; // handler

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ITEM");
        if (!uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if)) begin
            `uvm_fatal("MON", "adder_if not found in uvm_config_db");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            // #10;
            @(posedge a_if.clk);
            #1; // dut 처리 될 시간을 준다
            adder_item.a = a_if.a;
            adder_item.b = a_if.b;
            adder_item.y = a_if.y;

            `uvm_info("MON", $sformatf("sampled a:%0d, b:%0d, y:%0d", adder_item.a, adder_item.b, adder_item.y), UVM_LOW);
            // adder_item.print(uvm_default_line_printer); // 내용 화면에 찍는다

            send.write(adder_item); // send to scoreboard
        end
    endtask // monitor 동작
endclass //adder_monitor

class adder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(adder_scoreboard)

    uvm_analysis_imp #(adder_seq_item, adder_scoreboard) recv; // mailbox 역할 adder_seq_item : transaction

    adder_seq_item adder_item;

    function new(string name = "SCO", uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ITEM");
    endfunction

    virtual function void write(adder_seq_item item);
        adder_item = item;
        `uvm_info("SCO", $sformatf("Recived a:%0d, b:%0d, y:%0d", item.a, item.b, item.y), UVM_LOW);
        adder_item.print(uvm_default_line_printer);

        if (adder_item.y == adder_item.a + adder_item.b) begin
           `uvm_info("SCO", "*** TEST PASSED ***", UVM_NONE); 
        end else begin
            `uvm_error("SCO", "*** TEST FAILED ***");
        end
    endfunction
endclass //adder_scoreboard

class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent)

    function new(string name = "AGT", uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    adder_monitor adder_mon; // handler
    adder_driver adder_drv; // handler
    uvm_sequencer #(adder_seq_item) adder_sqr;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_mon = adder_monitor::type_id::create("MON", this);
        adder_drv = adder_driver::type_id::create("DRV", this);
        adder_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SQR", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_drv.seq_item_port.connect(adder_sqr.seq_item_export); // export connect
    endfunction

endclass //adder_agent

class adder_environment extends uvm_env;
    `uvm_component_utils(adder_environment) // factory 등록

    function new(string name = "ENV", uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    adder_scoreboard adder_sco; // handler
    adder_agent adder_agt; // handler

    // build phase에서 실체화
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // 부모클래스에 넣어줌
        adder_sco = adder_scoreboard::type_id::create("SCO", this);
        adder_agt = adder_agent::type_id::create("AGT", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_agt.adder_mon.send.connect(adder_sco.recv); // TLM port 연결
    endfunction

    
endclass //adder_environment

class test extends uvm_test; // test 구현 (UVM에서 상속받음 -> 기능 확장)
    `uvm_component_utils(test) // factory에 등록 매크로

    function new(string name = "TEST", uvm_component parent);
        super.new(name, parent); // parent is null
    endfunction //new()

    adder_sequence adder_seq; // sequence : SV's generator
    adder_environment adder_env;

    virtual function void build_phase(uvm_phase phase); // overriding
        super.build_phase(phase);
        adder_seq = adder_sequence::type_id::create("SEQ", this);
        adder_env = adder_environment::type_id::create("ENV", this); // factory excute  adder_seq = new();
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().print_topology(); // 토폴로지 출력(시스템 구조)
    endfunction

    virtual task run_phase(uvm_phase phase); // overriding test가 env를 다 실행시킴
        phase.raise_objection(this); // drop전까지 simulation이 끝나지 않는다
        adder_seq.start(adder_env.adder_agt.adder_sqr);
        phase.drop_objection(this); // objection 해제 -> run_phase 종료
    endtask

endclass //test extends uvm_test

module tb_adder();
   adder_if a_if();

   adder dut(
      .a(a_if.a),
      .b(a_if.b),
      .y(a_if.y)
   );

    always #5 a_if.clk = ~a_if.clk;

    initial begin
        // 시놉시스 버디를 위한 정보저장
        $fsdbDumpvars(0); // 모든정보를 수집할거다
        $fsdbDumpfile("wave.fsdb"); // "파일명"에다가 수집한정보를 저장(dump)할것

        a_if.clk = 0;  
        uvm_config_db #(virtual adder_if)::set(null, "*", "a_if", a_if);

        run_test(); // UVM 전체 동작
    end

endmodule
