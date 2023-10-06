Overview
--------
Accumulator module. A new addend is coming to "din" every clock cycle.
Sum of the addends is accumulated inside the module.
Current sum value is available at "dout".
Accumulator could be set to zero using "sclear".

External dependencies
---------------------
set_global_assignment -name SYSTEMVERILOG_FILE ../long_adder/s10_add_p.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../long_adder/p_g_carry.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../long_adder/p_g_carry_base.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../long_adder/long_adder_core.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../long_adder/fm_add_p.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../long_adder/long_adder.sv
