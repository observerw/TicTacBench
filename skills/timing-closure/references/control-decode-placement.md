# Control And Decode Placement

Use this when control, flags, state/decode, mux selects, enables, comparisons, or reductions sit near the critical endpoint or after wide data movement.

## Objective

Place control and decode work so it does not serialize a timing-critical datapath. The key question is not whether the logic is correct, but where it physically sits relative to wide or deep logic.

## Procedure

1. Locate control-like logic on the path: selection, decode, flag generation, state-dependent cases, comparisons, enables, or reductions.
2. Determine whether it occurs before, inside, or after the wide/deep datapath operation.
3. Ask whether an equivalent value can be computed earlier, locally, or in a narrower form.
4. Move only the logic whose placement affects the critical cone. Avoid global FSM rewrites unless the report shows decode is the bottleneck.
5. Preserve priority, default behavior, reset semantics, and unknown/invalid cases explicitly.
6. Validate function and verify that the control/decode path is no longer in series with the critical datapath.

## Practical Heuristics

- If a one-bit result is derived from a wide result, consider whether the one-bit result can be carried alongside the data instead.
- If a select signal feeds several deep choices, check whether selection can be moved to a less timing-critical boundary.
- If state decoding dominates the path, consider whether the chosen encoding or decode placement creates unnecessary levels for the current contract.
- If a comparator is timing-critical, prove whether full-width comparison is required at that point in the cycle.

## Task-Agnostic RTL Sketches

These sketches show placement patterns for control-like logic. They do not say
which pattern is right; the current timing path must decide that.

### Flag after wide result vs flag carried with branch result

```systemverilog
always_comb begin
  unique case (mode)
    2'd0: next_y = a + b;
    2'd1: next_y = a ^ b;
    default: next_y = '0;
  endcase

  next_flag = (next_y == '0);
end
```

The flag computation above is necessarily after the result selection. Use the
pattern below only if STA shows that wide result selection plus flag computation
serializes the path.

```systemverilog
always_comb begin
  unique case (mode)
    2'd0: begin
      logic [W:0] local_y;
      local_y     = a + b;
      branch_y    = local_y;
      branch_flag = (local_y == '0);
    end
    2'd1: begin
      logic [W:0] local_y;
      local_y     = a ^ b;
      branch_y    = local_y;
      branch_flag = (local_y == '0);
    end
    default: begin
      branch_y    = '0;
      branch_flag = 1'b1;
    end
  endcase

  next_y    = branch_y;
  next_flag = branch_flag;
end
```

The important property is not branch-local code by itself. The measurable
change is removing a wide post-select flag computation from the critical series
path while preserving default and priority semantics.

## Failure Signals

- The edit changes state naming or case formatting but leaves decode depth in the same place.
- A flag or enable remains computed after the wide data expression it could have avoided.
- The change duplicates control logic without removing it from the critical series path.
- Functional corner cases are lost while trying to move control earlier.

## Acceptance Standard

A control/decode edit is acceptable only when it shows:

- which control-like operation was on the critical path
- where it moved relative to the datapath
- why the movement is functionally equivalent
- timing evidence that the path no longer serializes the same control and data work
