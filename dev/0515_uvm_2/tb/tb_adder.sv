interface adder_if();
    logic clk;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] y;
endinterface //adder_if()

`include "uvm_macros.svh"
import uvm_pkg::*;

class adder_seq_item extends uvm_sequence_item;
    rand bit [7:0] a;
    rand bit [7:0] b;
    bit [8:0] y;
    
    function new(string name = "ADDER_ITEM");
        super.new(name);
    endfunction //new()

    `uvm_object_utils_begin(adder_seq_item);
        `uvm_field_int(a,UVM_DEFAULT);
        `uvm_field_int(b,UVM_DEFAULT);
        `uvm_field_int(y,UVM_DEFAULT);
    `uvm_object_utils_end
endclass //adder_seq_item extends uvm_sequence_item

class Adder_sequence extends uvm_sequence #(adder_seq_item);
    `uvm_object_utils(Adder_sequence);
    function new(string name = "SEQ");
        super.new(name);
    endfunction //new()

    adder_seq_item adder_item;

    virtual task  body();
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");
        
        for (int i = 0; i<10; i++) begin
            start_item(adder_item);
            adder_item.randomize();

            `uvm_info("SEQ", $sformatf("adder item to driver a:%d, b:%d", adder_item.a, adder_item.b), UVM_LOW);
            // adder_item.print(uvm_default_line_printer);

            finish_item(adder_item);
        end
    endtask //
endclass //Adder_sequence extends uvm_sequence #(adder_seq_item)

class Adder_driver extends uvm_driver #(adder_seq_item);
    `uvm_component_utils(Adder_driver);

    function new(string name = "DRV", uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    adder_seq_item adder_item;
    virtual adder_if adder_intf;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");

        if(!uvm_config_db#(virtual adder_if)::get(this,"", "adder_intf", adder_intf)) begin
            `uvm_fatal("DRV", "adder_intf not fount uvm_config_db");
        end
    endfunction

    virtual task  run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(adder_item);

            @(posedge adder_intf.clk);
            adder_intf.a = adder_item.a;
            adder_intf.b = adder_item.b;

            `uvm_info("DRV", $sformatf("Drive DUT a:%d, b:%d", adder_intf.a, adder_intf.b), UVM_LOW);
            // adder_item.print(uvm_default_line_printer);
            
            seq_item_port.item_done();
        end
    endtask //
endclass //Adder_driver extends uvm_driver #(adder_seq_item)

class Adder_monitor extends uvm_monitor;
    `uvm_component_utils(Adder_monitor); //factory 등록

    uvm_analysis_port #(adder_seq_item) send; // 보내는 트랜젝션 핸들러

    function new(string name = "MON", uvm_component parent); 
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction //new()

    adder_seq_item adder_item;
    virtual adder_if adder_intf;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");
        if(!uvm_config_db #(virtual adder_if)::get(this, "", "adder_intf", adder_intf)) 
            `uvm_fatal("MON", "adder_intf not found in uvm_config_db");
    endfunction

    virtual task  run_phase(uvm_phase phase);
        forever begin
            @(posedge adder_intf.clk) #1;
            adder_item.a = adder_intf.a;
            adder_item.b = adder_intf.b;
            adder_item.y = adder_intf.y;

            `uvm_info("MON", $sformatf("sampled a:%d, b:%d, y:%d", adder_item.a, adder_item.b,adder_item.y), UVM_LOW);
            // adder_item.print(uvm_default_line_printer);

            send.write(adder_item);
        end
    endtask //
endclass //Adder_monitor extends uvm_monitor

class Adder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(Adder_scoreboard) // factory 등록 매크로
    
    uvm_analysis_imp #(adder_seq_item, Adder_scoreboard) recv; // 받는 트랜젝션 핸들러

    adder_seq_item adder_item;

    function new(string name = "SCO", uvm_component parent);
        super.new(name,parent);
        recv = new("READ", this);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_item = adder_seq_item::type_id::create("ADDER_ITEM");
    endfunction 

    virtual function void write(adder_seq_item item);
        adder_item = item;
        `uvm_info("SCO", $sformatf("Received a:%d, b:%d, y:%d", item.a, item.b, item.y), UVM_LOW);
        // adder_item.print(uvm_default_line_printer);

        if(adder_item.y == adder_item.a + adder_item.b) begin
            `uvm_info("SCO", "*** TEST PASSED ***", UVM_NONE);
        end else begin
            `uvm_error("SCO", "*** TEST FAILDED ***");
        end
    endfunction
endclass //Adder_scoreboard extends uvm_scoreboard

class Adder_agent extends uvm_agent;
    `uvm_component_utils(Adder_agent) // factory 등록 매크로
    function new(string name = "AGT", uvm_component parent);
        super.new(name,parent);        
    endfunction //new()

    Adder_monitor adder_mon;
    Adder_driver adder_drv;
    uvm_sequencer #(adder_seq_item) adder_sqr;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_mon = Adder_monitor::type_id::create("Mon", this);
        adder_drv = Adder_driver::type_id::create("DRV", this);
        adder_sqr = uvm_sequencer#(adder_seq_item) ::type_id::create("SQR", this);
    endfunction

    virtual function void cunnect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_drv.seq_item_port.connect(adder_sqr.seq_item_export);
    endfunction
endclass //Adder_agent extends uvm_agt

class Adder_envirnment extends uvm_env;
    `uvm_component_utils(Adder_envirnment) // factory 등록 매크로
    
    function new(string name = "ENV", uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    Adder_scoreboard adder_sco;
    Adder_agent adder_agt;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        adder_sco = Adder_scoreboard::type_id::create("SCO", this);
        adder_agt = Adder_agent::type_id::create("AGT", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_agt.adder_mon.send.connect(adder_sco.recv); // TLM Port 연결
    endfunction
endclass //Adder_envirnment extends uvm_env

class test extends uvm_test; // uvm프레임워크의 uvm테스트를 상속 받은 클래스(클래스명은 니맘대로지어라)
    `uvm_component_utils(test) // factory 등록 매크로

    function new(string name = "TEST", uvm_component parent);
        super.new(name, parent);
    endfunction //new()
    
    Adder_sequence adder_seq;
    Adder_envirnment adder_env;
    
    virtual function void build_phase(uvm_phase phase); //overriding
        super.build_phase(phase);
        adder_seq = Adder_sequence::type_id::create("SEQ", this); // factory excute.
        adder_env = Adder_envirnment::type_id::create("ENV",this); // factory excute.
    endfunction

    virtual task run_phase(uvm_phase phase); //overriding
        phase.raise_objection(phase); // drop전 까지 시뮬레이션이 끝나지 않는다.  
        adder_seq.start(adder_env.adder_agt.adder_sqr);  
        phase.drop_objection(phase); // objection 해제. run_phase 종료  

    endtask //
endclass //test extends uvm_test

module tb_adder();
    test adder_test;
    adder_if adder_intf();
    adder dut(
        .a(adder_intf.a),
        .b(adder_intf.a),
        .y(adder_intf.a)
    );

    always #5 adder_intf.clk = ~adder_intf.clk;

    initial begin
        adder_intf.clk = 0;
        adder_test = new("TEST", null);

        uvm_config_db #(virtual adder_if)::set(null, "*", "adder_if", adder_intf); 
        // uvm_config_db: 시뮬레이션 데이터를 세팅하는 거시기

        run_test();
        // run_test: test시작시키는 거시기
    end
endmodule