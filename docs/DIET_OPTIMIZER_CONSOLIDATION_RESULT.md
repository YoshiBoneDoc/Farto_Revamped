# Diet optimizer consolidation — October 16, 2026

Cleanup only. The practical planner remains the sole production optimizer. No search heuristic, candidate policy, economic formula, gameplay assumption, budget, or live action sequence was changed. Investigation and any later optimization have separate approval gates.

## Recovery and scope

- `6b679da`: current production code, original optimizer implementations, audit and frozen fixtures before cleanup.
- `527d266`: reproducible environment manifest and pre-cleanup normal-preview/complete-search baselines.
- The cleanup commit containing this report removes only audited C1–C3 code. Unrelated working-tree changes remain untouched.
- Historical source locations in `DIET_OPTIMIZER_AUDIT.md` refer to the checkpoint; they are intentionally not rewritten to imply deleted functions still exist.

| Source | Before lines | After lines | Disposition |
|---|---:|---:|---|
| TeresMimicDiet.ash | 3053 | 2485 | 30 obsolete function definitions, two records and 11 exclusive globals removed |
| teresBARF.ash | 554 | 351 | Six unreachable legacy functions and unreachable main tail removed |
| teresBarfSimulation.ash | 194 | 7 | Five exclusive helpers removed; `barfSimulation()` forwards to practical preview |
| TeresMimicDietLive.ash | 396 | 396 | One reset of a removed write-only cache flag removed |

Exact removed symbols and surviving-function changes are in `resources/diet-snapshot/consolidation/cleanup-results.json`. Of 130 surviving diet function definitions, 126 are byte-identical. The four changes remove only exclusive legacy cache writes/resets. All 177 original comment tokens across these four files remain verbatim, including historical notes that no longer describe active routing. Newly added headers identify that distinction.

Shared item discovery, recipes, prices, stash valuation, Synthesis candy selection, Ode, caches, exact keys, conservative dominance, state transitions, completion, practical search, reporting, snapshot export, live execution and replanning remain. The old maximizer and mall-offer parser were uncalled and inconsistent with current explicit user assumptions; they were not migrated. No stored preferences were deleted.

## Compatibility

`diet-plan`, `diet-candidates`, and `diet-snapshot` keep their existing routing. Empty/default, `all`, `prep`, `diet`, `farm`, `plan`, and `sim` remain previews. `run [positive paid-turn limit]` remains the explicit live entry. Main dispatch through the invalid-command abort is preserved. No live `run` was executed.

The standalone simulator API is retained as a preview shim. Its old exclusive helper APIs and the old diet/search APIs are retired; there are no other project `.ash` callers, and a read-only scan of installed non-symlink scripts found no external consumers. Unknown interactive custom callers cannot be ruled out; the checkpoint provides recovery.

The offline benchmark defaults to the practical planner and retires beam-only `layers/full`, `--width`, and beam timeout modes. Historical beam results remain documented and the original runner is recoverable from the checkpoint. Functional tests and practical/cache profiling remain supported. The new runner accepts a saved old source for practical comparisons and does not use deleted declarations as source-splicing anchors.

## Frozen equivalence

Both sides use the October 13 saved snapshot, identical JAR/JDK, frozen prices/stock/resources/XP and explicit `benchCookingAccess=true` oven assumption. The actual preview core `barfDietPlan()` ran in an isolated headless native Mafia process; stash and external price reads were replaced with the same frozen data on both sides. Network/gameplay requests are not part of the harness. The omitted live modifiers make absolute income provisional; relative comparisons use the same economic model.

| Measurement | Before | After |
|---|---:|---:|
| Normal 90-second preview elapsed | 90.852 s | 90.876 s |
| Selected preview schedule export | frozen TSV | byte-identical TSV |
| Preview encounters / combined Meat | 673 / 2,773,699 rounded | identical |
| Complete practical search elapsed | 106.743 s | 107.397 s |
| Complete selected encounters | 673 | 673 |
| Complete combined Meat | 2,777,060.5652169692 | exactly identical |
| Completed trials replayed | 56 | 56 |
| Exact state/score/schedule records | 59 | 59 matching |
| Consumption evaluations / scores | 159,589 / 521,207 | identical |
| Farm blocks / rate cache misses | 6,663 / 1,352 | identical |

The complete comparison uses the same 300-second safety budget on both sides and exhausts all 56 comparisons before it; it is not a proposed higher production budget. The normal preview hit its 90-second wall-clock limit after 45 versus 44 attempts. This small clock-dependent difference affected an unsuccessful final alternative, not the selected plan, finances or schedule. Complete-search equivalence removes that timing ambiguity. The 0.6% complete-runtime difference is not a material regression or a claimed speedup.

The complete winner has income 3,025,811.8976, opportunity costs 390,639, cash purchases 69,914, today's net 2,635,172.8976, tomorrow value 141,887.6676; 673 covered and zero uncovered encounters; 35 Yeti trainer encounters, 34 songs, peak 2008 XP, final Yeti 658/Chest 955; seven cooling refreshes and one cold-fashioned double; three pours yielding 11+10+10, three liver; all six capacity items, Stooper, final Vintage, five adventures before Vintage and 200 projected tomorrow. Detailed ordered rows and exact final state are in the frozen baseline JSON.

## Regression results

- Native ASH parsing passes for TeresMimic, preadventure, postadventure, unlockerCCS, teresBARF, compatibility simulator and live driver.
- Semantic cache/prefix/expiry/rounding/quantity/helper-order checks pass.
- Conservative dominance, expensive future buff, duration/XP distinctions, joint menus and deferred clearer retry checks pass.
- Planner tests pass for milk, chocolates/tofu/clocks, finite-stock fills, marginal helpers and training food.
- All 15 Cookbookbat recipes, shadow martini, recursive ingredient costs and recording live acquisition adapters pass.
- Multiple-pour yields, daily resources, liver reservations, exact organ checks, complete replay/targets and low-organ melange retry pass.
- Mocked live full/limited execution passes, including 130 gear configurations, consumption dispatch, lost/free fights, resume, real-roll replanning, reserves, retained effects and final-nightcap gating.
- Native in-memory tests pass for physical capacity changes, Sobrie, final hook guards, tourist buff/location modeling and outfit fallbacks.
- Dry-run source call paths and actual preview core are preserved; no purchases, consumption, equipment changes, stash withdrawals or adventures occurred.

Reproduction:

```sh
python3 resources/diet-snapshot/benchmark/run.py --workload production --setting benchCookingAccess=true --setting teresBarfDietPlanSeconds=90
python3 resources/diet-snapshot/benchmark/run.py --workload practical --setting benchCookingAccess=true --setting teresBarfDietPlanSeconds=300 --setting benchValidateTrials=true --reference /path/to/pre-cleanup/output.log
```

The raw timing logs were kept under `/private/tmp/diet-consolidation`; portable exact baseline states/schedules, environment hashes and post-cleanup summaries are committed under `resources/diet-snapshot/consolidation`. Prior legacy techniques and risks remain in audit Section B; ranked follow-up experiments and measured capacity comparisons will be in `DIET_OPTIMIZER_IMPROVEMENT_PLAN.md`.
