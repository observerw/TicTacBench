# Pipeline Boundary

Use this when too much combinational work remains in one cycle, or when a register was added but the violating path did not shorten.

## Objective

Move or add timing boundaries where they split the localized critical cone, while preserving the allowed latency and functional contract.

## Procedure

1. Confirm whether the task allows latency changes. If not, treat retiming as constrained to equivalent cycle behavior.
2. Mark the start and end registers of the violating path.
3. List the ordered work between them. Identify the longest dependency segment, not merely the largest source-code block.
4. Propose a boundary that cuts that segment or precomputes a value before the critical cycle.
5. Update valid/enable/reset behavior together with the data path. A register move is incomplete if control alignment is unclear.
6. Re-run tests/equivalence, then timing. Verify that the old stage no longer contains the same amount of work.

## Practical Heuristics

- A useful register changes which logic sits between two clock edges.
- A pass-through register does not help if the same expensive cone still feeds the endpoint in one cycle.
- Precomputing an intermediate value helps only when that value is available before the critical cycle and is stable under the contract.
- Balanced stages are usually better than moving all delay from one endpoint to another.

## Task-Agnostic RTL Sketches

These sketches show how to reason about register placement. They are valid only
if the task permits the resulting latency and control alignment.

### Pass-through register that does not cut the cone

```systemverilog
always_ff @(posedge clk) begin
  a_q <= a;
  b_q <= b;
  c_q <= c;
  d_q <= d;
  y_q <= ((a_q + b_q) ^ c_q) + d_q;
end
```

The register movement above may still leave the full expression between two
clock edges. If the reported endpoint is `y_q`, this may not shorten the
violating stage.

### Boundary that stores an intermediate value

```systemverilog
always_ff @(posedge clk) begin
  mid_q <= (a + b) ^ c;
  y_q   <= mid_q + d_q;
  d_q   <= d;
end
```

This kind of change is credible only when `mid_q` and the delayed companion
signals are aligned with the same transaction. Validate latency, enables, and
reset behavior before trusting the timing improvement.

## Failure Signals

- A register is added after the expensive computation.
- The design gains latency accidentally, without updating the contract or control alignment.
- Valid/ready/enables are not delayed with the data they qualify.
- Timing improves in one stage but creates an equivalent violation in the next.

## Acceptance Standard

Before accepting a pipeline edit, show:

- allowed latency and cycle contract
- before/after stage work
- control and reset alignment
- functional/equivalence evidence
- timing evidence that the targeted stage was actually split or shortened
