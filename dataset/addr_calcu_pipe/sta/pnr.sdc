create_clock [get_ports clk] -name $::env(CLOCK_PORT) -period $::env(CLOCK_PERIOD)

set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) [get_clocks clk]

set_input_delay -max 0.05 -clock [get_clocks clk] [get_ports {address ptr1 ptr2 b control reset}]
set_input_delay -min 0.01 -clock [get_clocks clk] [get_ports {address ptr1 ptr2 b control reset}]

set_output_delay -max 0.05 -clock [get_clocks clk] [all_outputs]
set_output_delay -min 0.01 -clock [get_clocks clk] [all_outputs]

set_load 0.05 [all_outputs]
set_drive 2.00 [get_ports {address ptr1 ptr2 b control reset}]
