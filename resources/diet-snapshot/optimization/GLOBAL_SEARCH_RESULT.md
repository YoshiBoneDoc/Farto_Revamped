# Diet optimizer results — October 17, 2026

The accepted changes improve the existing production heuristic. They do **not** implement a whole-day global optimizer or prove a 2,000-Meat global optimality gap. Capacity equipment still starts at the incumbent's first late capacity change, after its main farming/training block. `diet-plan` remains a dry run; all tests used isolated native KoLmafia state, with no account/game requests.

## Accepted changes and independent commits

| Commit | Change | Evidence |
| --- | --- | --- |
| `56719a7` | Correct icy-revenge song bonus from 8 to **5** familiar XP. | Explicit song/combat accounting; XP food reduces simulated Yeti/Chest trainer combats and songs, respects expiration, and has no unused-XP sale value. |
| `3d6fa7b` | Enumerate chocolate choices using lightweight financial states; materialize the winner with the native simulator. | Six exact state/schedule reference matches; 148 → 29 ms in final isolated checks. Ordered diminishing returns, daily counters, stock and liquidity preserved. |
| `b59c70b` | Scope non-organ extra menus to their exact starting state. | Fixes a correctness issue: a menu selected with a rich wallet could incorrectly reject a feasible poor starting state. Rich→poor matches an independently evaluated poor state. |
| `11cc269` | Cache exact buff-expiry scoring coefficients across scoring horizons. | 906 exact native scores. Four alternating complete schedules: 11,938 → 8,067 ms, identical states/schedules. An earlier paired run measured 18,592 → 11,256 ms. Original floating-point subtraction order, including zero-loss terms, is preserved. |
| `ffb39e9` | Reuse a complete trial when only an **unused** middle-pour time differs. | Native exact winner/stock/XP/cost/schedule match, original caller metadata restored; active pour times remain distinct. |
| `7694468` | Default fixed-continuation allowance of 2,000 Meat. | A certified +1,000 continuation may be skipped, +3,000 remains eligible; setting `teresBarfDietProfitGap=0` retains +1,000. Certificates require the same future physical state and sufficient liquidity. This is not a bound on other whole-day diets. |
| `e3af81b` | Search joint late equipment, consumption and farming events without beam-width pruning. | Native complete replay before accepting winners; independent depth-first reference agrees on the controlled graph. Profit/liquidity Pareto pruning requires identical buffs, durations, organs, XP, stock and resources. |

The late event search can equip multiple remaining capacity pieces before consuming, consume/farm between changes, and compare cross-organ equipment orders. Its queue processes progress levels and suppresses stale dominated arrivals, reducing repeat expansion. On snapshot 3 it expands 253 states, queues 461, rejects 329 financially dominated arrivals, and validates 9 completed continuations in 6.389 seconds. It improves the complete incumbent by 3,048.6195 Meat. Native ordinary-fill/helper selection is still heuristic; this graph does not exhaust every possible meal quantity.

## Equal-input complete-plan comparisons

Both sides use **+5 song XP**, identical snapshot prices, stock, resources, native simulator, initial state and economics. Native reconstruction is provisional because the exports omit some live modifiers. Do not compare these totals directly with the attached live log's 4,077,136 Meat.

Results and source hashes are recorded in `global-search-results.json`. The original unchanged planner was frozen before optimization; the five pre-existing user location/yield function edits were included equally in both evaluated sources and preserved in the working tree.

| Snapshot | Before combined Meat | After combined Meat | Gain | Native planning seconds, before → after | Peak RSS MB, before → after |
| --- | ---: | ---: | ---: | ---: | ---: |
| old | 2,777,336.738 | 2,777,336.738 | +0.000 | 128.854 → 128.275 | 529.9 → 521.8 |
| fresh | 2,485,140.014 | 2,490,946.465 | +5,806.452 | 137.492 → 138.366 | 518.4 → 598.6 |
| third | 2,871,397.071 | 2,874,445.690 | +3,048.620 | 196.468 → 184.113 | 631.4 → 500.0 |

All selected schedules replay and meet their targets. Per-run completed trials validated: 65 on old, 58 on fresh, 61 on third, on both sides.

Normal production planning has no wall-clock cutoff; these runs finish the finite comparison set. Previous 30/60/90-second controls are historical results in this directory, not new measurements of this batch. They were not reintroduced after the user's subsequent instruction to remove time constraints.

The paired one-JVM scoring tests provide stronger evidence for that specific speed improvement than single whole-planner elapsed times. Whole-run timings and peak process RSS vary with JVM warmup, garbage collection and other host activity. Peak RSS includes the native runtime, not only optimizer data structures.

## Investigated and rejected

- Carrying scored-offer records removed repeated score calls but improved paired small fills by only about 2%, with noisy/slower whole runs. Removed.
- Broader starting-seed/capacity comparison lost 3,607.85 Meat in the original +8-song experiment. Rejected; gear remained late in both alternatives.
- Event-based sweat thresholds added only 681.54 / 1,363.07 Meat in the original +8-song experiment, at roughly 2.9 / 2.7 seconds. Not promoted. These are historical exploratory results, not +5 comparisons.
- Changing initial spleen ranking to value a longer horizon looked beneficial with +8 XP, but the corrected +5 complete continuation **lost 4,598.14 Meat**. Rejected.
- Reopening all eight earlier pour masks with the selected late menu took about 27 seconds and found no gain on corrected snapshot 3. Rejected.
- Buffer-based state-key construction gave only about 3% in paired key tests. Not adopted.

## Verification and reproducibility

`global-regression-results.json` records 22 native cases: cookie, fill/preparation/prefix caches, capacity, memoization scope, quantity equivalence, certified continuation/liquidity, chocolates, extras cache, score kernels, complete-trial cache, late events, frontier/planner/pour/ingredient checks, recorded live dispatch, native execution guards, actual production entry/dry-run gate, and paired complete-score schedules.

One old native fixture initially failed because it required restoring the previous location; current user code intentionally maintains Barf Mountain. The assertion now accepts either the preserved original context or Barf Mountain, while requiring invariant Barf modifiers across 36 location/duration/outfit forecasts. The corrected native suite passes with both the working source and the independently staged source. The original failed assertion and successful follow-up are retained in the result JSON.

All 166 original source comments remain. Python harness compilation and `git diff --check` pass. No production time limit, candidate-price shortcut, recipe-cost discount, buff discount or live gameplay was introduced to obtain these improvements. Mandatory cold-fashioned doubling, training goals, full Looking Cool coverage, stock/cash, stillsuit state, retained buffs, final Vintage and 200-adventure rollover continue to use the production simulator.

Individual reproduction examples, from the project root:

```sh
python3 resources/diet-snapshot/benchmark/run.py --workload planner-checks --setting benchCookingAccess=true --output /private/tmp/diet-food-xp
python3 resources/diet-snapshot/benchmark/run.py --workload probe --probe resources/diet-snapshot/optimization/late_event_checks.ash --setting benchCookingAccess=true --output /private/tmp/diet-late-events
python3 resources/diet-snapshot/optimization/benchmark.py --source scripts/TeresMimicDiet.ash --snapshots old fresh --budgets 0 --output /private/tmp/diet-controls
python3 resources/diet-snapshot/benchmark/run.py --snapshot 'resources/diet-snapshot 3' --workload practical --memory --setting benchCookingAccess=true --setting benchInactiveStillsuit=true --setting benchValidateTrials=true --output /private/tmp/diet-third
```

## Remaining opportunities

The largest unfinished work is broader **initial** quantity/event optimization, followed by a useful optimistic whole-day bound. A quantity/constraint solver could propose meal allocations between order-sensitive events and submit each complete proposal to native validation; it must price recipes, training, stock, helpers, cooling, liquidity, sweat, final buffs and equipment capacity consistently. No such solver is installed by this batch.

The 2,000 setting currently skips only certified fixed-continuation evaluations. It cannot stop the entire optimizer with a near-global guarantee. Earlier-diet search, retained-menu combinations and sampled stillsuit timing still leave unexplored alternatives. Full planning remains about two to three minutes on these fixtures; this batch does not achieve a 30–120-second whole-day near-global solver.
