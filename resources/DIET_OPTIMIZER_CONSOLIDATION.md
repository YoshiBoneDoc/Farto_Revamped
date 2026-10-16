# Two-Day BARF Diet Optimizer — Legacy Audit and Consolidation

## Goal
Consolidate `TeresMimicDiet.ash` around **one production two-day optimizer**, the practical planner invoked via `teresBARF.ash diet-plan` (currently centered on `barfDietQuickPlan()`). Remove redundant legacy implementations **only after** auditing them for techniques worth adapting. Preserve legality, modeling accuracy, the complete fallback, and read-only planning behavior.

> **Approval gate:** Perform Phases 1–2 only, produce `docs/DIET_OPTIMIZER_AUDIT.md`, and STOP. Do not change or delete source code until I explicitly approve the plan.

## Phase 1 — Inventory and dependency audit (no edits)

Identify all three optimizer families and their actual entry points:
1. Original legacy organ/diet optimizer.
2. Experimental full-day beam search (`barfDietSearch()` and associated helpers).
3. Active practical two-day planner (`barfDietQuickPlan()` and associated helpers).

For each, map:
- CLI commands, entry points, callers, and call graph.
- Functions, records, globals, caches, settings, and preference keys.
- Functions shared by the active planner, executor, other scripts, and candidate-inspection commands.
- Search strategy, candidate ranking, deduplication, dominance, completion, and time limits.
- Yield, pricing, inventory/stash, cash, opportunity cost, tomorrow-value, and replay logic.
- Organ constraints, mandatory cold-fashioned, Cooler Yeti XP/doubling, Looking Cool, equipment capacity, Stooper, stillsuit, retained buffs, and rollover.

**Trace references across the project, not just by function names.** A helper originally written for the beam search may be essential to the practical planner. Do not remove shared code or externally called commands.

### Legacy techniques to evaluate for reuse

**Candidate breadth and frontier management**
- Can legacy methods preserve profitable alternatives lost to bounded partial-state selection?
- Assess diversity/feasibility-aware frontiers, conservative Pareto dominance, state deduplication, caching, and ranking. Do not assume a wider beam is better.

**Multi-step organ clearing**
- Examine Spice Melange, mojo filters, dog hair, distention, and other clear/refill sequences.
- Can legacy search evaluate a profitable *sequence* when intermediate steps are individually unattractive?
- Check daily limits, prices, ordering, and the feasibility of completing all organs exactly.

**Action ordering and timing**
- Compare food/booze sequencing, helper application, capacity swaps, training, cooling refreshes, farming intervals, retained effects, and multiple Tiny Stillsuit pours.
- Distinguish actual flexibility from actions that are merely present in code but unreachable.

**Completion feasibility**
- Experimental beam previously failed to finish a legal diet even at width 64 (~379 seconds). Diagnose whether failures arise from missing/unreachable transitions, premature pruning, incorrect state equivalence, or mandatory action ordering.
- A known complete practical schedule should be traceable through the beam's legal transitions before any beam-based idea is considered reliable.
- Do not implement a new full-day beam or refactor the quick planner into a general completion engine during cleanup.

**Profit and correctness**
- Identify any legacy features that are more accurate or comprehensive than the current practical planner; distinguish validated advantages from speculative ones.
- Evaluate time/memory costs and correctness risks before recommending integration.

## Phase 2 — Written audit and recommendations (no edits)

Create `docs/DIET_OPTIMIZER_AUDIT.md` with:

### A. Dependency inventory
For each relevant function/global/setting, categorize:
- **Essential:** actively required by production planning/execution.
- **Shared:** used by multiple active commands/scripts.
- **Potential improvement:** legacy technique worth adapting or benchmarking.
- **Obsolete:** proven unused, redundant, or superseded.

Include exact symbols, file locations, callers, and supporting evidence. Mark uncertain cases **needs verification**, not obsolete.

### B. Feature comparison
For every unique legacy capability, describe:
1. What it does and where it lives.
2. Whether the practical planner already provides it.
3. Which observed limitation it could address.
4. Expected profit/completeness/runtime benefit (label estimates as estimates).
5. Implementation complexity and correctness risks.
6. Recommendation: integrate separately later / preserve concept in report and Git / discard.

Prefer retaining useful **ideas** over keeping entire redundant implementations. Do not equate theoretical usefulness with measurable benefit.

### C. Proposed deletion plan
List exact functions, records, globals, settings, and command branches proposed for removal, with dependency checks and risks. Identify any settings that must remain for backward compatibility. Do not delete anything yet.

### D. Prioritized follow-up experiments
Rank by likely value and cost, particularly:
- Multi-step organ-clearing sequences.
- Better diversity/feasibility of partial-state selection.
- Flexible action ordering and stillsuit timing.
- Efficient complete-schedule comparison and search-budget allocation.
- Joint retained-buff pairs: determine why the latest run reported `joint buff pairs 0` before allocating effort to them.

**STOP HERE AND REQUEST APPROVAL.** Do not edit `.ash` files or begin Phase 3 without permission.

---

## Phase 3 — Freeze baseline (after approval)

Create a Git checkpoint before edits. Record the exact commit, environment, preferences, prices, inventory/stash snapshot, familiar XP, organs, adventures, and time budget. If the environment cannot be frozen, explicitly document that strict numerical comparisons are not reproducible.

Capture a baseline run of `teresBARF.ash diet-plan` including:
- Full ordered schedule and replay result.
- Today's income, opportunity costs, cash purchases, net profit, tomorrow value, combined objective.
- Paid encounters, training and XP, cooling coverage, Yeti daily double.
- Organ use, clearing, capacity swaps, Stooper, nightcap, and rollover.
- Stillsuit pours and yields, retained effects.
- Number of attempted/completed comparisons, state-pruning counts, and runtime.

Use the same frozen snapshot for post-cleanup comparisons. **The cleanup-only build should match the original plan and financial outputs exactly**, except for explicitly justified nonsemantic log changes.

## Phase 4 — Consolidate safely (after approval)

- Keep the active practical two-day planner as the sole production optimizer.
- Remove only audited, unreferenced legacy search implementations and their exclusive records, globals, caches, configuration, and entry points.
- Retain shared utilities used by the active planner, execution/replanning, candidate inspection, or other project scripts.
- Preserve dynamic item discovery, pricing and ownership rules, recipe costs, exact organ fills, clearing, helper preparations, training, Looking Cool, Yeti double, capacity swaps, stillsuit pours, retained-buff modeling, final nightcap, rollover, and replay validation.
- Preserve the complete legal fallback and overall planning time budget. An incomplete candidate must never displace a valid complete plan.
- Preserve the `diet-plan` **dry-run contract**: no purchases, consumption, stash withdrawals, equipment changes, or adventures.
- Avoid changing profit formulas, pricing assumptions, search heuristics, execution semantics, or model constraints in a cleanup-only commit.
- Avoid compressing unrelated code into large functions solely to reduce line count.
- Keep useful but unintegrated legacy ideas documented with their original symbols and recoverable Git commit rather than retaining dead code.

## Phase 5 — Integrate improvements only as separate experiments

Do **not** combine cleanup and algorithm redesign in the same change. For each approved improvement:
1. State a falsifiable hypothesis and affected cases.
2. Implement a small, isolated change.
3. Compare against the frozen baseline and several representative snapshots.
4. Validate complete legal schedules and actual modeled objectives, not only partial-state scores.
5. Report runtime, memory, and quality tradeoffs; revert if benefits are not demonstrated.

No claims of global optimality: the practical planner remains heuristic.

## Phase 6 — Regression checks

Verify after cleanup:
- ASH parses; supported CLI commands and other project scripts still work.
- Same complete ordered schedule, costs, objectives, and projected encounters on the frozen snapshot.
- Exact organ constraints, daily limits, and capacity equipment transitions.
- Mandatory cold-fashioned with the Yeti daily double.
- Required XP and 100% Looking Cool coverage.
- Multiple Tiny Stillsuit pours and correctly accounted adventures/liver.
- Retained-effect duration and tomorrow valuation.
- Nightcap and 200-adventure rollover requirement.
- Replay validity, cash feasibility, and dry-run safety.
- No material runtime regression.

If output changes unexpectedly, stop and diagnose before proceeding. Do not describe cleanup-induced differences as optimizer improvements.

## Phase 7 — Final deliverables

Report:
1. Before/after lines, removed functions/globals/records, and surviving commands.
2. Preserved shared functionality and any compatibility decisions.
3. Legacy features evaluated, with exact source locations and recommendations.
4. Frozen benchmark before/after: profit, schedule, legality, runtime, and comparisons.
5. Ranked future experiments with estimated benefit, implementation effort, and risk.
6. Git commits/checkpoints sufficient to recover deleted legacy code.

## Non-negotiable principles

- **Audit first; request approval before deletion.**
- **One reliable production planner, not three overlapping frameworks.**
- **Preserve validated behavior and useful ideas, not dead code for its own sake.**
- **Keep cleanup separate from optimization experiments.**
- **Never sacrifice completeness, legality, or dry-run safety for fewer lines.**
