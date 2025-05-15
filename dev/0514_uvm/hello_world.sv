program automatic test;
	import uvm_pkg::*;

	class hello_world extends uvm_test;
		`uvm_component_utils(hello_world)
		
		function new(string name, uvm_component parent);
			super.new(name, parent);
		endfunction

		virtual task run_phase(uvm_phase phase);
			phase.raise_objection(this); // 시뮬레이션 busy
			`uvm_info("TEST", "Hello world!", UVM_MEDIUM); // inform display id, string, verbosity
			phase.drop_objection(this); // 시뮬레이션 done
		endtask
	endclass

	initial begin
		run_test();
	end
endprogram
