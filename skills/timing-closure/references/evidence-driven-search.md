# Evidence-Driven Search

Use this when the next edit is uncertain, repeated attempts are not improving timing, or several RTL candidates are plausible.

## Objective

Run timing closure as a measured search over candidate RTL changes. Reject weak candidates and pivot when WNS/TNS, violation count, or worst-path evidence shows the current edit family is not changing the limiter.

## Procedure

1. Write down the current hypothesis before editing.
2. Define what evidence would confirm or reject it: path class disappears, dependency depth shortens, margin crosses a stated threshold, or a stage is split.
3. Limit each candidate to one main structural idea when possible.
4. Run functional checks before timing comparisons.
5. Compare candidates in a small table: structural change, WNS/TNS, violation count, worst path class, and contract risk.
6. If two attempts from the same family fail to move the path class, pivot to a different structural hypothesis.
7. Preserve the best known working candidate while exploring alternatives.

## Practical Heuristics

- Search breadth should come from different structural hypotheses, not many syntactic variants of the same hypothesis.
- A regression is useful evidence if it explains which property did not help.
- If timing evidence and the RTL rationale disagree, trust the evidence and revisit localization.
- Do not stack unrelated edits to force progress. Isolate the mechanism unless the contract requires coupled changes.

## Failure Signals

- Trying one plausible fix, seeing insufficient timing, and stopping.
- Repeating the same edit family with different syntax.
- Timing data is collected but not used to change the next hypothesis.
- The final design contains many accumulated edits whose individual effects are unknown.

## Acceptance Standard

A closure search is disciplined when it leaves behind:

- tested hypotheses
- measured timing and correctness results
- reason for rejecting weaker candidates
- reason for the final pivot or final acceptance
- final evidence tied to the original critical path class
