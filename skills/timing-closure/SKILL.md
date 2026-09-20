---
name: timing-closure
description: Practical conceptual guidance for closing RTL timing under STA or post-PnR setup violations. Use when debugging timing, choosing RTL changes, calibrating timing margin, or running an evidence-driven closure loop.
---

# Timing Closure Guidance

Make an RTL design meet timing, especially when post-PnR or signoff STA reports setup violations.

## Core Workflow

1. Preserve the contract first: functional behavior, allowed latency, reset behavior, interfaces, and any constraints.
2. Read the strongest timing evidence available. Prefer final post-PnR reports when available; otherwise use the closest proxy and mark it as proxy evidence.
3. Map each worst path to a specific RTL/netlist cone before editing.
4. Form one structural hypothesis: what logic, register boundary, control placement, or search/margin decision is keeping the path long?
5. Make the smallest RTL change that can plausibly shorten that exact path.
6. Validate equivalence or task tests before trusting timing.
7. Re-run pre-PnR/setup timing first when available.
8. Re-run final timing and compare the same path class, not only aggregate WNS.
9. Accept only with final-target timing evidence, or with a proxy margin calibrated from observed proxy-to-final deltas. Otherwise pivot or run the final flow.

`Path class` means the same endpoint family, RTL cone, dominant operation type, or stage boundary remains responsible for the worst path, even if synthesized net names change.

## Reference Routing

Load only the references needed for the current design scenario:

- Worst path names or endpoints are known, but the responsible RTL cone is unclear: read [path-localization.md](references/path-localization.md).
- The path is arithmetic/data-heavy and the current realization may preserve too much depth, width, fanout, or muxing: read [datapath-topology.md](references/datapath-topology.md).
- Timing depends on too much work in one cycle, or a register was added without reducing the violating path: read [pipeline-boundary.md](references/pipeline-boundary.md).
- Flags, state/decode, mux select, comparators, enables, or other control logic sit near the endpoint or after wide data movement: read [control-decode-placement.md](references/control-decode-placement.md).
- A candidate improves timing but has marginal slack, relies on a proxy run, or lacks final post-PnR evidence: read [signoff-margin.md](references/signoff-margin.md).
- Multiple attempts are possible, timing evidence is mixed, or the current edit family is not improving the path: read [evidence-driven-search.md](references/evidence-driven-search.md).

## Hard Rules

- Do not edit before naming the path's RTL/netlist cone and why that cone is timing-relevant.
- Do not treat cleaner RTL as a timing fix unless the hardware structure or timing boundary changes.
- Do not accept a candidate because WNS improved if the original path class remains negative or the margin is uncalibrated.
- Do not rely on post-PnR to rescue a candidate that still violates nominal pre-PnR setup constraints in a flow where pre-PnR pass is the defined gate. Passing pre-PnR is not signoff.
- Do not keep repeating variants from the same structural family after timing evidence shows the family is insufficient.
- Do not silently add large compatibility shims or unrelated fallback logic. If the contract blocks the needed timing move, report the blockage and offer explicit options.

## Completion Evidence

Before claiming timing closure, collect current evidence for:

- functional correctness or equivalence after the RTL change
- nominal pre-PnR/setup timing passes constraints when that check exists
- final-target timing result, preferably post-PnR/signoff
- worst-path comparison showing the targeted path class was removed, shortened, or no longer dominates
- final-target pass, or a stated proxy-to-final margin calibration
- a short rationale for why the final edit is structural rather than cosmetic
