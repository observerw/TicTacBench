# Signoff Margin

Use this when a candidate improves timing but final closure is not proven, or when the available timing result is only a proxy for the required objective.

## Objective

Avoid accepting candidates that look improved but lack enough physical margin for the final timing target.

## Procedure

1. Identify the final timing target: clock period, setup objective, flow stage, and required violation count.
2. Label each timing result as final evidence or proxy evidence.
3. Treat nominal pre-PnR/setup timing as the default gate: setup WNS should be non-negative and setup violations should be zero before final post-PnR/signoff effort, unless the task or saved flow evidence defines another policy.
4. For proxy evidence, calibrate margin from an explicit target, observed proxy-to-final deltas, or saved flow tolerance. If no calibration exists, require final evidence instead of accepting the proxy.
5. Compare candidates by both WNS and path-class elimination. A better WNS is not enough if the original path class still dominates.
6. If slack is marginal, validate with a tighter target or run the final flow before accepting.
7. Accept only when final evidence passes, or when a calibrated proxy result clears the requested objective by the stated margin.

## Practical Heuristics

- Negative slack is never closed, even if it is much less negative.
- Passing nominal pre-PnR/setup timing is a flow gate, not signoff. It only proves the candidate is worth final validation.
- Near-zero positive slack is fragile unless final evidence passes or a documented calibration says it is acceptable.
- A proxy run is useful for ranking candidates; it is not signoff unless the task says so.
- Large TNS or many violations often means the issue is broad, not a one-path cleanup.
- Hold issues should not justify loosening a setup target unless the task asks for hold closure too.

## Failure Signals

- Stopping after a nominal check with tiny or negative margin.
- Launching final post-PnR/signoff while nominal pre-PnR setup still violates constraints and no exception was stated.
- The candidate is accepted because it "should pass after optimization."
- The final flow is skipped even though it is available and required.
- The reported WNS improves, but the same path class remains the limiter.

## Acceptance Standard

Before signoff, record:

- final target and whether the result is final or proxy
- nominal pre-PnR/setup WNS/TNS/violation count
- WNS/TNS/violation count at the accepted point
- margin source: final evidence, observed proxy-to-final delta, explicit target, or saved flow tolerance
- whether the original path class was removed or no longer dominates
- any remaining risk if final evidence could not be run
