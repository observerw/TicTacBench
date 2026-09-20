# Critical Path Localization

Use this when timing reports show violations but the actionable RTL/netlist cone is not yet clear.

## Objective

Convert startpoint, endpoint, and timing arc evidence into a concrete structure in the current design that can be changed. Timing closure starts only after this mapping exists.

## Procedure

1. Extract for each top setup path: WNS, startpoint, endpoint, launch/capture clock, hierarchy, endpoint type, major combinational cells/operators, logic depth, and any fanout/load hints.
2. Trace endpoint and nearby internal names back to RTL signals, generated nets, module hierarchy, or synthesized operators.
3. Write a before-edit path note: `startpoint -> major operators/cells -> endpoint`, suspected RTL assignments, and why those assignments create the delay.
4. Classify the cone by timing behavior, not by code location: data movement, arithmetic, comparison, reduction, muxing, decode/control, fanout, or a register-boundary issue.
5. Choose an edit only if it directly attacks that cone.
6. After editing, check whether the same path class still appears in the worst paths.

## Useful Checks

- If a report endpoint is opaque, search nearby net names in synthesized output and correlate them with RTL assignments.
- If the path crosses several operations, separate unavoidable function from placement choice. The edit should target the placement choice.
- If a path appears different after synthesis, compare path classes rather than exact net names: endpoint family, RTL cone, dominant operation type, or stage boundary.

## Examples

### Arithmetic cone: multiplier plus adder

01signal shows a Vivado critical path for:

```verilog
calc <= x * y + z;
result <= calc;
```

The reported path starts at `x_reg[1]__0_replica_2/C` and ends at `calc_reg[23]/D`; the useful RTL cone is not the whole module, but the expression feeding `calc`. The before-edit note should look like:

```text
x_reg/y_reg/z_reg -> multiplier partial products -> adder/carry logic -> calc_reg[23]/D
class: arithmetic
suspect assignment: calc <= x * y + z
```

Good next edits are structural: infer or enable the intended multiplier resource, split multiply/add across a register boundary if latency is allowed, or reduce operand width if the contract proves unused bits. Editing `result <= calc`, renaming `calc`, or moving unrelated control logic does not attack this path.

### Control pin endpoint: enable logic is the path

AMD UG949 gives an example where the critical path ends at the enable pin of `dout_reg[0]`: the enable pin has two logic levels while the data pin has zero. Localize this as a control/enable cone, not as a datapath cone.

```text
control flops/conditions -> enable decode -> dout_reg[0]/CE
class: decode/control or register-boundary issue
suspect RTL: if (enable_condition) dout <= next_dout;
```

Useful edits include simplifying the enable condition, moving the condition into the data input when the tool or attribute supports it, or creating a local registered enable if the contract allows the extra boundary. Pipelining `next_dout` is the wrong first fix when the violating endpoint is `CE`.

### High fanout or long route: driver/load cone

Vivado `report_design_analysis` reports path properties such as logic levels, high fanout, average fanout, and clock-region distance. When the worst path has modest logic depth but high fanout or long physical distance, localize the cone around the driver and its loads:

```text
shared condition/counter bit -> high-fanout net or long route -> many endpoints
class: fanout or register-boundary issue
suspect RTL: one registered control/data bit reused across distant logic
```

Useful edits are local copies of the driver, a registered local condition near each consumer group, or moving the register boundary so the long route is not in the same cycle. Do not replace arithmetic or mux expressions just because the same module contains them; the path property says the limiter is load/route.

### Opaque synthesized names: report more fields, then map back

For OpenSTA/OpenROAD, generate a full path with pins, nets, slew, capacitance, and fanout:

```tcl
report_checks -path_delay max \
  -format full_clock_expanded \
  -fields {slew cap input_pins nets fanout} \
  -endpoint_count 10 \
  -unique_paths_to_endpoint
```

Use the endpoint first, then search the synthesized netlist for nearby register, net, and instance names. If the report names `_302_` or `$auto$...`, do not edit from that name alone; map it to the RTL assignment or generated operator family before choosing an edit.

## Failure Signals

- The edit targets a module or operation because it "seems slow" but is not on the reported path.
- The rationale names WNS/TNS but not the responsible logic cone.
- The new worst path is the same class as the old one, only with renamed nets.
- Changing state, formatting, helper functions, or assignment style without explaining how the critical cone becomes shorter.

## Acceptance Standard

Proceed only when the proposed edit can be described as:

- current timing boundary
- concrete cone between the boundaries
- reason the cone is long
- RTL change that shortens, moves, or removes that cone
- evidence to verify the path class changed
