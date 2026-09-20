create_clock [get_ports clk] -name $::env(CLOCK_PORT) -period $::env(CLOCK_PERIOD)

set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) [get_clocks clk]

# Treat asynchronous reset as a control signal, not as synchronous data.
set_false_path -from [get_ports rst_n]

set_input_delay -max 0.05 -clock [get_clocks clk] [get_ports {mul_a mul_b mul_en_in}]
set_input_delay -min 0.01 -clock [get_clocks clk] [get_ports {mul_a mul_b mul_en_in}]

set_output_delay -max 0.05 -clock [get_clocks clk] [all_outputs]
set_output_delay -min 0.01 -clock [get_clocks clk] [all_outputs]

set_load 0.05 [all_outputs]
set_drive 2.00 [get_ports {mul_a mul_b mul_en_in}]
