# Uncapped planning and exact reuse

October 17, 2026. This follow-up implements the user's request to remove production planning time limits, avoid repeated work, and treat Affirmation Cookie as nine base adventures for one fullness, once per day. The broader six-area profitability roadmap remains unfinished; capacity grouping/deferral, reserved late stock, event pours and clearing/frontier changes have not been installed in this follow-up.

## Changes

- Normal planning sets its deadline to zero. It finishes the existing finite comparisons; the existing no-improvement pass break remains. Benchmark limits are injected only into isolated generated source. The old `teresBarfDietPlanSeconds` setting no longer limits normal planning.
- Affirmation Cookie is explicitly eligible despite the ordinary quality filter. Both candidate valuation and simulated minimum/expected base yield use nine. The existing `_affirmationCookieEaten` daily group enforces one/day. Ordinary meal bonuses still apply once.
- Exact organ-fill reuse: key includes the entire starting simulation state, organ, target and broad-menu flag. Only a successful result is stored. Schedule prefixes are excluded from the key and the cached action suffix is appended to the caller's prefix. Storage is bounded to 64 results.
- Shared preparation: before retained-item consumption, the scheduler reads the late menu's reserved fullness, drunkenness and spleen, plus final-pour choice; it does not read the identities of those items. Cache that common preparation, including training, farming, capacity equipment and pours, using those totals and the entire starting state. Then consume, price, score and validate each actual menu separately. At most 16 successful preparations are stored.
- Both caches clone returned records and reset with the frozen planning environment. They retain buffs/durations, XP, stock, finances, resources, equipment and policy flags. Failed or interrupted results are not reused. No search branches, candidate pool entries or fill widths were removed for speed.

## Matched full-search measurements

All rows below use the same cookie=9 assumption, no deadline, frozen native inputs, JAR and economic formulas. The October 13 pool contains 175 candidates; October 16 contains 172. These revised counts must not be confused with the earlier cookie=5 fixtures. Runtime means native planning through the result; complete-trial replays run afterward. Peak RSS covers the native child including validation. Measurements are single runs, so small incremental timing differences should not be treated as precise guarantees.

| Snapshot | Uncached planning | Fill cache alone | Both caches | Combined two-day objective, identical in all three |
|---|---:|---:|---:|---:|
| October 13 | 115.891 s | 83.530 s | 80.888 s | 2,778,483.140999 Meat |
| October 16 | 133.729 s | 98.658 s | 96.027 s | 2,472,752.076094 Meat |

Both caches reduce measured planning time by 30.2% / 28.2%. Fill reuse provides most of the gain; preparation reuse additionally removes 1,125 / 511 simulated farming blocks and saves about 2.6 seconds on each fixture.

| Snapshot | Consume evaluations before → after | Score calls before → after | Farm blocks before → after | Peak RSS before → after |
|---|---:|---:|---:|---:|
| October 13 | 161,351 → 93,282 | 525,840 → 285,575 | 6,663 → 5,538 | 528.3 → 476.0 MB |
| October 16 | 239,961 → 193,900 | 792,380 → 629,865 | 9,032 → 8,521 | 542.2 → 555.3 MB |

The fresh fixture's RSS increases 2.4%; storage is bounded. The old fixture's RSS falls 9.9%. These are peak process measurements, not retained-heap estimates.

Each version attempts all 56 policy comparisons. Every completed trial's full state, exact score and ordered schedule matches the uncached control byte-for-byte after sorting the result records. All 56 old / 49 fresh complete trials pass production replay. Respectively 54 / 47 meet the requested targets; the remaining two are explicitly relaxed training comparisons and cannot replace the requested-target winner. The fresh fixture's seven incomplete alternatives remain incomplete in all versions. Winners retain 674 / 595 fully covered encounters, mandatory cold-fashioned doubling, legal capacity gear, training/XP, final Vintage and 200 projected tomorrow adventures.

Absolute modeled incomes remain provisional because the exports omit some native state. Both fresh runs use the same explicit inactive-stillsuit reconstruction and oven assumption, as in the investigation. No live actions occurred. These are correctness/performance improvements: the caches do not claim a higher-profit search result. Do not credit the changed cookie assumption or a longer run as an algorithmic profit improvement.

## Evidence and reproduction

Portable result files, including source hashes, candidate counts, complete-result hashes, counters and RSS, are under `resources/diet-snapshot/optimization/`: `uncapped-control-results.json`, `fill-cache-results.json`, and `combined-cache-results.json`.

The offline harness accepts benchmark-only switches:

```
python3 resources/diet-snapshot/optimization/benchmark.py --source scripts/TeresMimicDiet.ash --output /private/tmp/diet-uncached --budgets 0 --setting benchFillCache=false --setting benchPreparationCache=false --setting teresBarfDietDiagnostics=true
python3 resources/diet-snapshot/optimization/benchmark.py --source scripts/TeresMimicDiet.ash --output /private/tmp/diet-fill --budgets 0 --setting benchPreparationCache=false --setting teresBarfDietDiagnostics=true --reference /private/tmp/diet-uncached
python3 resources/diet-snapshot/optimization/benchmark.py --source scripts/TeresMimicDiet.ash --output /private/tmp/diet-both --budgets 0 --setting teresBarfDietDiagnostics=true --reference /private/tmp/diet-uncached
```

The old 30/60/90 matrix remains in `original-budget-results.json` as historical, cookie=5 evidence. It is not an equal-assumption comparison to the new results. The latest instruction supersedes the 90-second production objective; no new deadline was substituted.

## Scope and remaining work

Do not remove a policy merely because it did poorly on these two fixtures. Wider fills still cost roughly seven to nine seconds with no gain here, but that is not proof they are redundant for other inventory/effect combinations. Failed preparation reuse may offer another benefit, but needs exact failure/diagnostic preservation tests. Quantity grouping must preserve all order-sensitive helpers, effects, resources and stock. Cross-stage capacity comparisons remain the highest demonstrated profitability opportunity in the approved investigation; no gain from that area is claimed by this follow-up.

All 11 final regression cases pass: cookie, fill cache, preparation cache, semantics, frontier, planner, pours, ingredients, mocked live execution, native live compatibility and actual read-only production entry. The entry fixture uses a benchmark-only cap after securing its fallback; uncapped full searches are validated separately above. Cache-disable controls also reproduce the uncached schedule exactly. All 135 comments from the revised economic control remain.

Commits: `4081830` removes the production deadline; `e629408` adjusts the cookie; `d3c1763` adds exact fill reuse; `64025c2` adds shared preparation. Detailed status is in `DIET_OPTIMIZER_PROGRESS.md`.
