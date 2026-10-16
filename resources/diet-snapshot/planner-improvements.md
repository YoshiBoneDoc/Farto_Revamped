# Practical planner improvements

Measured October 15, 2026. The production planner remains a dry run. No live
consumption, purchases, equipment changes or adventures were used for validation.
PROJECT_HANDOFF.md was left alone as requested.

## Changes

- Secure the existing complete practical fill as a fallback. Then construct and
  compare several complete starting diets: marginal-value helpers, retained
  weight, balanced buffs/stillsuit, and optional non-organ adventure items.
  Keep the highest-scoring completed diet meeting the original requirements.
- Judge optional meal helpers by the forecast value of another adventure after
  the meal's yield, rather than the immediate farming rate under short buffs.
  Compare the net fork benefit against a competing spork. Keep the original
  helper strategy available as a separate complete-plan comparison.
- Keep multiple partial ordinary fills for a targeted comparison, deduplicated
  with exact state signatures. Automatically retry with two choices per amount
  if the one-choice/full-shortlist fill fails. This preserves stock/helper
  distinctions which one partial state per amount can lose. The global candidate
  pool and quality restrictions are unchanged; this is not full-day beam search.
- Replace the default 20-second improvement window with bounded useful work:
  up to two menu/helper/pour passes, stopping early after a pass with no gain.
  Cache identical full trials and skip proven unchanged helper policies.
  A default **90-second overall planning safety limit** prevents unbounded work.
  `teresBarfDietPlanSeconds` overrides it; explicitly configured values are honored.
  The complete fallback may finish even if that limit has elapsed. Price/stash
  setup and final validation are outside this planning timer.
- Add ordinary/class chocolates and the separate cigar/capsule/sculpture groups,
  essential tofu, and clocks. Check current daily counters, class-dependent and
  diminishing yields, inventory/stash availability, buyability and liquid cash.
  Charge opportunity cost once; add adventures to the simulated pool once.
  Tofu uses 4 minimum / 5 expected adventures. Shared chocolate uses are searched
  together so a cheap finite copy is not necessarily spent at the wrong position.
  Compare a complete diet with the selected extras against complete diets without
  them. Additional expensive copies can be skipped. The final choice remains
  heuristic; this does not exhaust every possible extra-item subset.
- Replay and report the new extra-item schedule rows. Export their prices and
  daily counters in future `diet-snapshot` exports.

## Fixed milk policy requested during implementation

Milk of magnesium is now a fixed preparation at the start, not a per-meal search
decision. Assume one daily offer at **100 Meat**, as explicitly requested. If milk
is already active, do not acquire it again; if already used, do not assume another
copy can be used. Its +5 adventure bonus applies to the first eligible food once.
Report one resource cost rather than counting it again as a meal helper. The
experimental beam also starts with this fixed preparation for consistency.

The benchmark preserves this production price override instead of replacing it
with the snapshot's historical 2,000-Meat price. For the final comparison, the
saved pre-change planner received **only the same fixed-milk policy**, leaving
its search algorithm unchanged. Thus the final profit difference does not give
the new planner an unfair 1,900-Meat milk discount or a forced-milk advantage.

## Same-input results

All runs use the saved October 13 reconstruction: 235 adventures, 3 drunkenness,
the same 171 organ candidates, prices/stock, outfits, income model, requested XP,
mandatory cold-fashioned double, full cooling coverage and rollover reserve.
Runs are sequential in fresh isolated native KoLmafia processes. The old snapshot
did not export extra-item daily counters; those counters default to unused in
these offline trials. Live planning reads the real counters. Other previously
documented snapshot gaps still make absolute income provisional.

| Final comparison, same fixed milk policy | Planning time | Paid encounters | Combined modeled value |
| --- | ---: | ---: | ---: |
| Original search, default 20-second improvement window | 23.576 s | 647 | 1,804,796.314 Meat |
| New search | 43.121 s | 660 | 1,810,325.158 Meat |

**Final gain: 5,528.844 Meat, about 0.31%.** Both selected plans pass ordered
replay and policy targets. This snapshot shows a modest final gain for additional
runtime, not a dramatic profitability improvement. Under fixed milk, its final
gain chiefly comes from choosing useful extras. The early selection changes and
helper strategy also address failure/quality cases tested separately.

The new planner secures its fallback in about 7 seconds (645 encounters,
1,760,551 combined Meat). By about **21 seconds**, the starting-plan comparisons
have already found the final winner: **49,774 Meat above that initial fallback**.
Later refinement finds no better diet here and terminates after one pass, before
the 90-second safety limit. The selected extras are two turtle-totem chocolates,
one tofu and one clock. It rejects the lower-return third chocolate and second
clock under its marginal-value screen.

A separate pre-milk experiment increased the old improvement window from 20 to
120 seconds. It finished its available alternatives in 43.018 seconds and chose
exactly the same 1,798,728.994-Meat plan as the 24.389-second/default run. More time
alone did not improve that search on this fixture. Those figures used the older
milk policy and must not be mixed with the final table.

## Validation

- All **17 completed starting/refinement trials** in the final run passed ordered
  replay, including alternatives that lost. The selected diet meets the XP,
  cold-fashioned, cooling and rollover requirements.
- The actual production entry with fixed milk also passed its reported-comparison
  replays and dry-run checks, finishing in 43.228 seconds with the same winner.
- New native checks cover clock/class-chocolate diminishing returns and shared
  counters, tofu minimum/expected yields, already-used resources, finite stock,
  liquid cash and refusing further consumption after the nightcap.
- Milk checks cover fixed 100-Meat cost, an already-active copy, already-used
  milk and applying its bonus once across helper strategies.
- A native helper fixture verifies that a cheaper partial helper bundle improves
  projected net under short starting buffs.
- A finite-stock exact-fill fixture uses capacity 11 and item
  `(size, adventure value, limit)` values `(1,11,2)`, `(3,13,2)`, `(5,27,1)`.
  One partial choice per amount loses the exact fill. The two-choice retry
  recovers two size-3 items plus one size-5 item, yielding 53 adventures.
- Existing cache, prefix/rebasing, expiry, training, cash/stock and helper-order
  checks pass. Native Diet, BARF and Mimic import compilation passes.
- A deliberately one-second planning window returns the complete fallback,
  rather than an incomplete or invented-profit result. This check preceded the
  final fixed-milk change; the fallback/deadline mechanism is unchanged.
- All 105 original source comment texts from the task's starting source were
  preserved. Frozen snapshot input files were not edited.

## Reproduction

```sh
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload practical --setting benchValidateTrials=true
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload production
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload planner-checks
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload checks
```

Use `--setting teresBarfDietExtraAdventures=false` to isolate the planner without
extra-item consumption, or `--setting teresBarfDietPlanSeconds=120` to override
the safety limit in an isolated process. `--source PATH` loads another saved
planner source for controlled comparisons. Generated ASH/classes, fake account
homes and output logs stay in the chosen temporary output directory.

Task evidence is under `/private/tmp/diet-planner-improvement/`: `before.ash` is
the original source used for computation, `before-fixed-milk.ash` is the reference
with the shared new milk policy, and the matching runs are `before-fixed-milk/`
and `fixed-milk-final/`. `fixed-milk-checks/` and `fixed-milk-cache-checks/` contain
native semantic results. Temporary references are for benchmarks, not custom IDE
review displays; review production edits in the IDE's changed-files diff.

Production source SHA-256 at completion of the initial planner changes:
`4ac414ecd2312a086bab3e47676d9165bff533badf09dc03004d973192bc48ec`

## Subsequent redundant-loop audit (October 15)

The source above was frozen before this audit. Every paired run used the same
October 13 snapshot, 171 candidates, economic assumptions and helper policy.
The practical reference checks compare the exact selected state and schedule,
every completed trial's exact state/score/schedule, and replay results. A
300-second safety setting prevented timing from cutting either comparison short;
both exhausted the same useful comparisons well before the ordinary 90-second limit.

| Cumulative change | Planning time | Consumption simulations | Score calls |
| --- | ---: | ---: | ---: |
| Frozen starting source | 45.371 s | 76,397 | 271,288 |
| Reuse proven identical bare/prepared consumption; score each variant once | 32.332 s | 50,120 | 197,631 |
| Also skip redundant one-slot duplicate checks and unused initial DP entries | 31.607 s | 50,120 | 197,366 |
| Also skip unused bare helper rates; terminate decided rankings | 32.821 s | 50,120 | 191,108 |
| Also bypass the Yeti comparison loop when only mode zero is legal | 31.244 s | 50,120 | 151,658 |

These are individual sequential measurements, with normal runtime variation:
small differences between adjacent rows are not established speedups. The final
practical run used **31% less time** than the reference. The actual production
entry independently completed in **32.004 seconds** with the same winner and
passed reported-comparison replay and dry-run checks.

Why the removed work is unnecessary:

- A prepared consumption can stand in for bare consumption only after the existing
  stock-counter proof confirms that it acquired no helper unique to prepared mode.
  The appended row is changed to preserve the original bare-first tie winner;
  when the proof fails, both variants are still simulated.
- Bare consumption's helper-buying rate is unused: every decision depending on
  that rate is guarded by `!bare`. Active charges and owned seasoning still apply.
- When the fill retains one state, an economically identical state already loses
  the equal-score tie. Wider fills keep exact duplicate checks. The initial DP
  score/key cannot be read because transitions strictly increase filled capacity.
- Ranking only asks whether four better candidates exist. Further counting cannot
  change rejection. Protected candidates previously continued through the entire
  comparison loop without doing work, so that guard now skips the loop itself.
- Food, all-cooling-policy states, Stooper, no Yeti, and insufficient Yeti XP
  each rule out both nonzero Yeti modes. Those cases need only mode zero.

All **17 completed trial diets** matched exactly and passed replay; the selected
diet remained 660 encounters and 1,810,325.1576032322 combined modeled Meat.
Another **3,591 consumption cases** compared against explicit original-order
simulation, covering purchased/active helpers, stock, retention, cash, capacity,
Yeti modes and rejections. Existing semantic and finite-stock fill checks pass;
Diet, BARF and Mimic import compilation passes. All 105 original comment texts
were preserved. Three experimental beam layers also retained all 16 states,
scores and schedules exactly; their 6.532/7.149-second measurements do not show
a beam speed improvement. Gear, farming/training, cooling and joint menu/pour
comparisons remain in place.

Evidence: `/private/tmp/diet-loop-audit/`, with `before.ash`, `consumption.ash`
and `fill.ash` as computational references and corresponding run directories.
The final practical run is `final-single-mode/`; production is `production/`.
Use `--reference PATH/TO/output.log --workload practical` for exact trial
comparisons, with `--setting benchValidateTrials=true` on both runs. Optional
`--profile` adds inclusive native timers only to the generated offline harness;
these nested timings must not be added together as separate shares of runtime.

Source SHA-256 after this audit:
`47db32fd095aae9c4979360bd451b2e89861132e8f8ee6f01830ef68e429d481`

## Live integration (October 15)

`teresBARF.ash diet-plan` and the existing preview aliases remain read-only.
`teresBARF.ash run` now prints a fresh validated plan and executes the revised
diet through `TeresMimicDietLive.ash`. It does not enter the older diet/farm loop
or repeat free-kill phases.

```text
teresBARF.ash diet-plan
teresBARF.ash run 5
set teresBarfRolloverOutfit=YOUR_SAVED_OUTFIT_NAME
teresBARF.ash run
```

The optional positive turn limit caps paid farming, **not purchases or initial
diet consumption**. Every limited run stops before final retained buffs and
Vintage, even when its turn limit exceeds the available farming. A full run
requires the saved rollover outfit up front, completes the late diet, drinks
Vintage last, and equips that outfit. Hat Trick's locked hat is preserved.

The executor follows the selected ordered preparations, including fixed milk,
helpers, temporary wine/martini gear, Yeti modes, synthesis pairs, free COMBINE
crafting, extras, organ resources, capacity changes, stillsuit and free paw wishes.
Explicit acquisitions use personal stock/closet/storage/stash before purchases
and enforce quoted prices plus the configured item cap. Native automatic
Mayo/consumption gear/Garish purchases are disabled and restored with the other
run settings. Queued meal helpers are cleared without consuming them.

Before each paid adventure, actual adventures, capacity, Looking Cool and retained
effects must allow it. Training follows actual XP; reaching the initial Yeti target
is remembered across spending and same-day restarts. It reserves XP for remaining
cooling. A lost fight continues; an exhausted training song supply falls through
to normal combat. At farming checkpoints, the executor rebuilds and validates the
remaining schedule with the selected policy and late items. It does not rerun the
full starting-plan search. Actual daily counters and stock prevent repeating used
resources. Failure/exit saves progress and restores hooks and settings.

Extrovermectin copied-fight forecasts remain preview-only: a live plan selecting
one is rejected before actions because its copied-fight sequence is not implemented.
Set `teresBarfCopiedGoblinMeat=0` to exclude that optional forecast when executing.
Required-item/price/organ/choice failures stop with a diagnostic rather than making
unpriced substitutions.

Validation is offline, with no real purchases, consumption, equipment changes or
adventures. All 17 completed planner trial states, schedules and scores still match
the pre-integration reference. The actual plan-only entry and its replays pass.
`--workload live-checks` uses recorded item adapters to exercise the real
consumption dispatcher, and simulated game adapters around the production driver
to test full and limited runs, low rolls, a free encounter, a lost training fight,
checkpoint replanning, day/resume state and nightcap gating. These tests do not
claim a live server run. Shared gear is checked across 128 capacity/familiar
configurations and both trainers. Native compilation of the executor, entry,
planner, Mimic, CCS and adventure hooks passes; existing semantic/planner checks
pass. Evidence is in `/private/tmp/diet-live-integration/`.

```sh
python3 resources/diet-snapshot/benchmark/run.py --workload live-checks
python3 resources/diet-snapshot/benchmark/run.py --workload production
```

## Follow-up live-path audit (October 15)

The integration's original model-based driver tests missed physical-state boundaries.
The audit added `live-native-checks`: Java callbacks update only the isolated
KoLmafia character while one ASH invocation keeps its real observer and caches.
No server actions or authenticated game session are used.

Fixed and checked:

- Live action prediction now refreshes the physical snapshot and invalidates
  forecast caches. A used distention pill, sweet tooth or Voraci tea is already
  included in Mafia's real capacity; an older cached stage must not reject the
  next meal. Tests explicitly reproduce that rejection before refreshing.
- Sobrie tea reduces drunkenness by one; it does not increase liver capacity.
- Stooper's actual outfit now uses the same available familiar-equipment fallback
  as the forecast when the amulet coin is absent.
- The adventure hook checks actual reserves, organs, Looking Cool, pending Yeti
  mode and retained durations immediately before adventuring. Live runs suspend
  the user's mood and restore it without executing its actions. Daily fruit
  tracking is initialized and its before-combat inventory counts are maintained.
- Completed free losses and consecutive paid losses sharing Mafia's second-resolution
  combat timestamp are recognized; an unchanged old loss flag is not enough to
  hide a failed noncombat. The runtime cooling reservation is released at its
  scheduled marker, and nightcap preparation rechecks retained buffs/reserves.
- The spleen-noodle resource had an uninitialized zero meal limit and could never
  be scheduled. It now preserves its full helper/adventure row, executes those
  preparations and choice 1, and reports them. A follow-up driver regression
  caught the newly legal noodle taking a reserved late-menu spleen slot; that
  infeasible successor is rejected without discarding the complete remaining diet.
- Unsupported Extrovermectin copied-fight plans are rejected after checkpoint
  replanning as well as at initial startup.

The full/limited simulated driver runs, recorded consumption dispatch, native
capacity/hook/loss/mood cases, existing semantic/planner checks and compilation of
all seven affected entry/import/hook scripts pass. All 17 complete practical
trial states, scores and ordered schedules still match the pre-audit reference
exactly on the frozen snapshot (171 candidates; selected 660 encounters and
1,810,325.1576032322 combined modeled Meat). These are offline results, not live
HTTP validation. Evidence: `/private/tmp/diet-live-audit/` (`native/`,
`driver-final/`, `practical-final/`, `semantic/`, `planner-checks/`, `dry-entry/`).

```sh
python3 resources/diet-snapshot/benchmark/run.py --workload live-native-checks
python3 resources/diet-snapshot/benchmark/run.py --workload live-checks
```

## Starting-diet search order (October 16)

Move the existing wider ordinary-fill comparison into the starting-diet phase,
before menu/helper/pour refinements. Previously it ran after those refinements;
an improved fill therefore could not guide them. This reuses the existing trial,
candidate pool, configured fill width and overall deadline. The complete fallback
is still secured first, and the five-second training-comparison reservation remains.
No live execution behavior or consumption mechanics changed.

On the same October 13 reconstruction, the before/after runs both completed all
17 trials with 50,120 consumption simulations and 151,658 score calls. The exact
selected state/schedule and every completed trial matched (20 reference rows),
with ordered replay and policy targets passing. Planning took 28.000 / 27.847
seconds; this small timing difference is not evidence of a speedup. Both chose
660 encounters and 1,810,325.1576032322 combined modeled Meat. There is no measured
profit increase on this snapshot; the change lets a better fill participate in
later refinements when a different starting state makes that comparison useful.

Four additional experiments were kept out of production:

- Grouped organ-clearing prefixes: the new completed trial scored about 1,212
  Meat below the existing winner; total planning rose to 30.578 seconds.
- All five other organ-fill orders: none beat the existing winner; total planning
  rose to 43.042 seconds.
- Choosing non-organ extras after initial consumption/training: the selected diet
  lost about 66 Meat, despite a more informed local marginal-rate estimate.
- Ranking retained foods/drinks with estimated ordinary-fill opportunity costs:
  the alternative completed diet lost about 26,485 Meat. Its approximate ranking
  did not outperform the existing full-plan comparisons.

All experiments used the same 171 candidates, stock, historical prices and
economic assumptions. These historical reconstructed inputs are regression
fixtures, not a user-selected diet or today's account state; absolute income
remains provisional. No game requests or live actions were used. Evidence and
computational source variants are under `/private/tmp/diet-start-quality/`.
