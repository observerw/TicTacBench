# Datapath Topology

Use this when the critical path is data-heavy and the current hardware realization may preserve excessive depth, width, fanout, or muxing.

## Objective

Choose an RTL structure that changes at least one measured property of the localized datapath cone: logic depth, operation width, mux/computation order, fanout/load, register boundary, or worst-path class. Do not prescribe a named topology from memory; derive the required property from the current path.

## Procedure

1. Describe the path in structural terms: dependency chain length, operation width, fanout, mux position, reduction shape, replicated work, or serial dependency.
2. Decide which physical property must change: fewer dependent levels, narrower operation, earlier selection, less fanout, more balanced work, or fewer operations before the endpoint.
3. Generate at most two candidate RTL structures that change that property in different ways.
4. Reject candidates that only rewrite syntax around the same dependency graph.
5. Validate function first, then run timing and compare the targeted path class.
6. Keep the candidate only if timing evidence shows the intended property changed.

## Practical Heuristics

- Prefer changes that alter dependency depth or boundary placement over changes that merely make expressions look more explicit.
- Treat generic operators as implementation requests, not guarantees. Inspect whether synthesis realizes the structure needed for the target path.
- When muxing and computation both appear in the path, reason about their order explicitly.
- When width is part of the problem, prove the narrower form is valid from the contract before relying on it.
- When fanout is part of the problem, check whether the edit reduces the load or only renames the driver.

## Task-Agnostic RTL Sketches

These sketches show structural questions to ask. They are not recipes. Use one
only when the current timing path and contract justify the same structural move.

### Serial dependency vs balanced dependency

If a path contains several associative operations in series, check whether the
RTL forces unnecessary dependency depth.

```systemverilog
// Deeper chain: every operation depends on the previous result.
assign y = (((a + b) + c) + d);

// Shorter dependency shape when the operation and widths permit it.
logic [W:0] s0, s1;
assign s0 = a + b;
assign s1 = c + d;
assign y  = s0 + s1;
```

This is useful only if the operation is safely regroupable under the design's
bit-width, signedness, overflow, and rounding semantics.

### Select-before-compute vs compute-before-select

When both selection and computation are on the path, compare the dependency
created by their order.

```systemverilog
// Selection feeds a wide computation.
assign y = (sel ? a0 : a1) + (sel ? b0 : b1);

// Computation is local to each branch; the final select chooses a result.
logic [W:0] y0, y1;
assign y0 = a0 + b0;
assign y1 = a1 + b1;
assign y  = sel ? y0 : y1;
```

The second form is not automatically faster; it can duplicate logic and add
area. It is worth testing when the reported path serializes muxing and
computation in the same cycle.

## Failure Signals

- The new RTL has more lines but the same dependency graph.
- The edit changes a coding idiom without changing operation order, width, depth, or fanout.
- The candidate improves a non-critical cone while the original path class remains dominant.
- Choosing a familiar hardware structure without proving why its structural property matches the current path.

## Acceptance Standard

A datapath edit is credible only if the before/after rationale names:

- the original structural bottleneck
- the changed measured property
- why the contract permits the change
- timing evidence that the path class improved or disappeared
