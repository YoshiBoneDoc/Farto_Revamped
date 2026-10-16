# Two-Day BARF Diet Optimizer — Approved Consolidation and Optimization Investigation

## Goal
Consolidate `TeresMimicDiet.ash` around **one production two-day optimizer**, the practical planner invoked via `teresBARF.ash diet-plan` (currently centered on `barfDietQuickPlan()`). Remove redundant legacy implementations **only after** auditing them for techniques worth adapting. Preserve legality, modeling accuracy, the complete fallback, and read-only planning behavior.

> **Updated approval (October 16, 2026):** Phases 1–2 are complete and documented in `DIET_OPTIMIZER_AUDIT.md`. Proceed with a recoverable Phase 3 checkpoint, cleanup-only Phase 4, and Phase 6 regression testing, subject to the audit’s C1–C3 compatibility and comment-preservation safeguards. Then conduct a **read-only optimization investigation** and write `docs/DIET_OPTIMIZER_IMPROVEMENT_PLAN.md`. **Do not implement algorithmic changes without a second explicit approval.**

## Phase 1 — Inventory and dependency audit (completed; historical instructions)

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

## Phase 2 — Written audit and recommendations (completed; historical instructions)

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

**Historical approval gate satisfied:** The audit was produced and reviewed. Follow the updated approval at the top of this document; it supersedes this former stop instruction.

---

## Phase 3 — Freeze baseline (NOW APPROVED)

Create a Git checkpoint before edits. Record the exact commit, environment, preferences, prices, inventory/stash snapshot, familiar XP, organs, adventures, and time budget. If the environment cannot be frozen, explicitly document that strict numerical comparisons are not reproducible.

Capture a baseline run of `teresBARF.ash diet-plan` including:
- Full ordered schedule and replay result.
- Today's income, opportunity costs, cash purchases, net profit, tomorrow value, combined objective.
- Paid encounters, training and XP, cooling coverage, Yeti daily double.
- Organ use, clearing, capacity swaps, Stooper, nightcap, and rollover.
- Stillsuit pours and yields, retained effects.
- Number of attempted/completed comparisons, state-pruning counts, and runtime.

Use the same frozen snapshot for post-cleanup comparisons. **The cleanup-only build should match the original plan and financial outputs exactly**, except for explicitly justified nonsemantic log changes.

## Phase 4 — Consolidate safely (NOW APPROVED, CLEANUP ONLY)

- Keep the active practical two-day planner as the sole production optimizer.
- Remove only audited, unreferenced legacy search implementations and their exclusive records, globals, caches, configuration, and entry points.
- Retain shared utilities used by the active planner, execution/replanning, candidate inspection, or other project scripts.
- Preserve dynamic item discovery, pricing and ownership rules, recipe costs, exact organ fills, clearing, helper preparations, training, Looking Cool, Yeti double, capacity swaps, stillsuit pours, retained-buff modeling, final nightcap, rollover, and replay validation.
- Preserve the complete legal fallback and overall planning time budget. An incomplete candidate must never displace a valid complete plan.
- Preserve the `diet-plan` **dry-run contract**: no purchases, consumption, stash withdrawals, equipment changes, or adventures.
- Avoid changing profit formulas, pricing assumptions, search heuristics, execution semantics, or model constraints in a cleanup-only commit.
- Avoid compressing unrelated code into large functions solely to reduce line count.
- Keep useful but unintegrated legacy ideas documented with their original symbols and recoverable Git commit rather than retaining dead code.

## Phase 5 — Integrate improvements only as separate experiments (NOT YET APPROVED)

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

## Phase 7 — Consolidation deliverables

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


---

## Phase 8 — Optimization investigation and proposed roadmap (READ-ONLY; NOW APPROVED)

**Sequence:** Complete and validate Phases 3, 4, and 6 first. If cleanup causes unexplained schedule, economic, legality, compilation, or execution changes, stop and resolve them before investigating optimizations. Do not mix algorithm changes into cleanup commits. Use `DIET_OPTIMIZER_AUDIT.md` Sections B, D, and E as the starting evidence, not as proof that any proposed optimization will pay off.

### 8A. High priority: cross-stage capacity equipment and organ consumption

Investigate whether `barfDietQuickSchedule()` / `barfDietQuickFillStage()` actually compare alternative *complete* schedules that differ in the timing and grouping of capacity additions, consumption, and farming. The audit indicates capacity stages are scheduled largely deterministically and the next swap is chosen by immediate farming rate; verify the exact behavior in the consolidated source.

**Concrete regression case from a recent dry run:** The plan used six baked veggie ricotta casseroles and two Pete's rich ricottas, with the ricottas consumed in separate late capacity stages. Illustrative prices/yields: Pete's rich ricotta, 1 fullness, ~7 expected adventures, 1,800 Meat; baked veggie ricotta casserole, 2 fullness, ~15–17 expected adventures, 4,200 Meat. The effects of both foods are not useful to this user's objective. The observed schedule does **not** prove that replacing two ricottas with a casserole is better: it may force earlier capacity equipment and a worse farming outfit. Recalculate actual yields, helper availability, prices, stock, and costs from the frozen model, rather than hardcoding these illustrative values.

**Non-negotiable game constraint:** When consumed fullness, drunkenness, or spleen exceeds capacity without the necessary capacity equipment, adventuring wastes a turn rather than producing a normal farming encounter. Consequently, capacity equipment supporting overfilled organs **must remain equipped throughout every affected farming interval**. Do not model swapping back to the baseline outfit while organ use remains above its limits. Check each organ independently and account for temporary gear swaps needed for consumption.

Compare at least these legal sequences under identical initial conditions:

- **Incremental:** equip capacity piece A; consume a 1-fullness item; farm its adventures with all required capacity gear maintained; equip piece B; consume another 1-fullness item; farm with the now-required gear.
- **Combined:** equip pieces A and B; consume a 2-fullness item; farm its adventures with both capacity pieces maintained.

For both, evaluate the **entire two-day objective**, including all adventures, cash and opportunity costs, helper/recipe constraints, actual farming Meat/item modifiers for every stage, encounters spent with each capacity outfit, effects and expiration, Yeti training, Looking Cool, organ clearing, stillsuit/liver competition, nightcap, rollover and tomorrow's retained buffs. Include effects on the rest of the schedule, not merely the immediate 14–17 adventures. Confirm each alternative is fully legal and replayable. If either schedule cannot be constructed, identify the exact reason. Identify the specific generation, stage-ordering, pruning, or ranking limitation **only if** the superior legal schedule is missed.

### 8B. Multi-step organ clearing and exchange items

Determine whether individually unprofitable resource actions prevent profitable two- or three-step sequences from being considered. Test Spice Melange, mojo filters, dog hair, distention, Sobrie and other supported resources, plus the special exchange meals flagged in the audit (slider, pickle juice, Burnsger, thyme cocktail). Account for prerequisites, gross organ room, daily limits, prices, limited stock, refill order, cooling/drink reserves, and cash feasibility. Do not assume the old code already solves these chains. Propose bounded bundle/lookahead comparisons only after demonstrating a concrete missed complete schedule.

### 8C. Search-budget allocation and observability

Investigate the observed 90-second run with 22 comparisons, 117,844 generated fill states, 88,487 width-pruned states, and `joint buff pairs 0`. The audit showed that an expired deadline **can** produce zero eligible-pair counts; it did not prove the cause of that particular historical run. Distinguish pair-generator reached, deadline expired, eligible generated, top estimated, attempted, and completed comparisons. Evaluate whether structurally distinct trials (cross-stage capacity, clearing bundles, retained buffs, pour timing) should receive bounded budget *before* repetitive local refinements. Benchmark at identical 30/60/90-second limits without simply increasing the budget.

### 8D. Partial-state diversity and action ordering

Examine whether narrow fill frontiers discard states with valuable later capacity, effect duration, XP, helper, stock, or cash opportunities. Assess quantity-based grouping, conservative Pareto dominance, event-boundary comparisons, noodle/helper/wish ordering, and event-based stillsuit timing. Avoid coarse state merging, unjustified dominance, arbitrary permutations, or reviving the full-day beam. Maintain a complete fallback and validate every candidate with the production replay and target checks.

### 8E. Improvement proposal — STOP before coding

Create `docs/DIET_OPTIMIZER_IMPROVEMENT_PLAN.md` with:

1. Root-cause investigation of the ricotta/casserole example, including two fully costed complete schedules **if legal** and exact outfit/organ-capacity timelines.
2. Evidence of any missed profitable organ-clearing sequence (or an explicit statement that none was established).
3. Search-budget breakdown and interpretation of the joint-pair counter.
4. Partial-state pruning findings and identified counterexamples.
5. Ranked proposed improvements with falsifiable hypothesis, affected functions, expected value **labeled as an estimate**, runtime/complexity, legality risks, and regression fixtures.
6. A minimal bounded cross-stage lookahead proposal, if warranted, that compares complete schedules without creating another full-day optimizer.
7. A separate incremental implementation/benchmark plan, with distinct commits for unrelated algorithm changes.

**Second approval gate:** Do not change active planner heuristics, search order, profit formulas, candidate policy, gameplay assumptions, live execution, or code structure for these experiments until the user reviews and approves this improvement plan. No purchases, consumption, equipment changes, stash withdrawals, or adventures may occur during `diet-plan` or investigation. Do not execute the live `run` command as a test.

## Updated execution order and final stop

1. Phase 3: checkpoint and freeze reproducible baseline, respecting existing dirty/untracked files.
2. Phase 4: approved C1–C3 cleanup only; resolve legacy simulator, benchmark, external-call compatibility, and comment-preservation decisions conservatively. Stop and ask if a safe disposition is unclear.
3. Phase 6: prove compilation, command compatibility, dry-run safety, legality, and baseline equivalence.
4. Phase 7: report consolidation diff, tests, performance and recoverable Git commits.
5. Phase 8: investigate potential optimizations **without modifying production source**; deliver the improvement-plan Markdown.
6. **STOP and request explicit approval before implementing Phase 5 algorithm changes.**
