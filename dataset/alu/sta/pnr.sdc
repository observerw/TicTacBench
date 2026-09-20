# This design is combinational, so use a virtual clock to model the I/O timing contract.
create_clock -name vclk -period $::env(CLOCK_PERIOD)
set_input_delay -max 0.05 -clock [get_clocks vclk] [all_inputs]
set_input_delay -min 0.01 -clock [get_clocks vclk] [all_inputs]
set_output_delay -max 0.05 -clock [get_clocks vclk] [all_outputs]
set_output_delay -min 0.01 -clock [get_clocks vclk] [all_outputs]
set_load 0.05 [all_outputs]
set_drive 2.00 [all_inputs]
