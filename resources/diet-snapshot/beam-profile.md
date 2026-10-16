# Initial diet beam: profiling investigation

Measured October 15, 2026 against the saved October 13 diet snapshot.

Current follow-up status: the validated caches and structural optimizations are
now integrated into the production dry-run planner. The full 160-layer beam
finished in 97.8 seconds but returned no complete legal diet. The active practical
planner remains in use. The final section records these newer results; the
initial profiling sections below preserve the earlier experiment.

The unprofiled 160-layer trial was stopped during layer 44, at approximately
1,052 seconds. It did not return a completed beam diet. Its earlier progress
must not be treated as a valid profitability comparison.

## Controlled inputs and comparison rules

- Snapshot: 235 adventures; organs 0/15 fullness, 3/21 liver, 0/15 spleen;
  275 stillsuit drams; 76 sweatpants sweat; Chest XP 955; Yeti XP 1,035;
  11,183,076 Meat. All exported skills, positive effects, aggregate stock,
  equipped slots, familiars and resource preferences are restored offline.
- Candidate pool: the same 171 filtered/pruned entries for each beam variant;
  width 16 in both. These include beam-supported mixed-organ/special handlers.
  The practical candidate audit's smaller count excludes those handlers.
- Prices: frozen consumable history plus the bundled mallprices file for other
  items, with native NPC replacement caps. Cold-fashioned opportunity cost is
  500,000 Meat; vintage smart drink is 137,000. Historical prices do not establish
  live listing availability. No live mall, stash or game requests were made.
- Same economic model: native fixed outfits, effect handling, item income,
  250 base Meat, NC assumptions, trainer songs, helper costs and tomorrow-weight
  calibration. No hand-entered live profit/weight total substitutes for that model.
- Same policy: 950 Chest XP, Yeti reaches 2,000 once, 225-XP cooling refreshes,
  mandatory 400-XP cold-fashioned double, full paid-encounter cooling coverage,
  zero terminal Yeti XP reserve, 145 total rollover and 200 tomorrow adventures.
  For these paired tests the starting cooling-slot budget is pinned to seven,
  matching the complete practical baseline. The earlier aborted beam's setup
  omitted that future slot budget; it is not used as a comparison result.
- Fresh isolated preferences are loaded for each measured process. The native
  profiling run, plain timing run, cached timing run and complete-schedule runs
  were sequential, avoiding CPU contention between measured algorithms.
- Snapshot limitations apply equally to both variants: soup/feast, custom latte
  modifiers, some equipment modes/base-stat details and some daily counters are
  not exported. Zero remaining Legend-food uses are restored from the consumable
  snapshot. Other unexported counters use defaults. Aggregate stock is treated
  as available inventory. Greed candies are fixed to PEEZ dispenser + Glo-Pop.
  Absolute income is provisional; these are comparisons within one reconstruction.

## 1. Actual expansions per layer

171 candidates × 16 parents = 2,736 only if each candidate has one variant.
The retained beam tries prepared and bare consumption, retained-effect variants,
Yeti cooling/doubling, and separate farming, resource and equipment transitions.
Nested handler calls are not counted as extra top-level offers in this table.

| Layer | Parents | Transition offers | Legal offers scored | Repeated keys | Wall time | Mean time per attempted transition |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1 | 574 | 460 | 108 | 1.069 s | 1.862 ms |
| 2 | 16 | 8,766 | 6,650 | 1,924 | 23.529 s | 2.684 ms |
| 3 | 16 | 8,153 | 4,124 | 1,897 | 33.008 s | 4.049 ms |

A rejected organ/cash/coverage transition is much cheaper than a legal farm
simulation. The means above include both kinds and are not per-item constants.
Scoring alone averages about 1.28 ms per legal offer in the two full layers.

## 2. Where the time goes

Non-overlapping coarse timings for layers 2–3 combined:

| Phase | Time | Fraction |
| --- | ---: | ---: |
| State generation / simulation | 41.722 s | 73.796% |
| Scoring | 13.798 s | 24.405% |
| Key construction + deduplication + frontier admission | 0.884 s | 1.564% |
| Finish eligibility checks | 0.002 s | 0.004% |
| Loop, instrumentation and other overhead | 0.131 s | 0.232% |

These are instrumented wall-clock measurements, not CPU samples. Generation
counts its nested helpers once; offer time is split into score time and the
remaining key/dedup/frontier work. Timers are millisecond-resolution. Full
ordered validation ran zero times inside this incomplete beam search: the tiny
validation entry is early finish-eligibility checking, not full schedule replay.

The cost also changes by layer: generation is 61.5% in layer 2 and 82.5% in layer
3, as farming trials simulate more training. Scoring is 36.0% and 16.2%.

## 3. Expensive work inside expansions

- Layer 2 made 8,004 consumption-handler calls and copied 7,042 states. Consumption
  recalculates item yields and helper economics using the current farming rate;
  each legal offer then computes another score. It does not simulate an entire
  future day for every consumable.
- Layer 2 attempted 344 farming transitions (102 legal), simulating 4,218 blocks,
  including 2,100 trainer blocks; farming generation alone cost 9.274 seconds.
- Layer 3 attempted 370 farming transitions (257 legal), simulating 10,635 blocks,
  including 5,295 trainer blocks; farming generation alone cost 24.070 seconds.
- Farming targets include 1/5/25/100/maximum turns, effect expiry boundaries and
  a stillsuit threshold. These restart from the same parent and repeatedly replay
  overlapping prefixes, including familiar XP, song costs, sweat and effects.
- The plain runs called the rate calculation 25,536 times in layer 2 and 39,547
  times in layer 3. Rate calculation and item income each rescan initial/current
  effects, and score calculation performs further effect/expiration arithmetic.
- Native ASH function profiling of the first two layers found 7,752,649 calls to
  `barfDietEffectAt`, costing 9.556 seconds inclusive. `barfDietRateAtStage` cost
  17.007 seconds inclusive within a 26.178-second search. These nested times
  overlap and must not be added. State cloning cost 0.661 seconds inclusive;
  it matters, but repeated modifier arithmetic is the larger measured problem.
- Gear stages and native effect data are already cached. The repeated work is
  scanning/combining those values and replaying forecast turns, not maximization
  or network latency. Initial candidate pruning is separate from per-layer cost.

Relevant implementation locations in `scripts/TeresMimicDiet.ash`: income rate
899; farm simulation 957; score 1402; state key 1553; admission 1565; beam loop
1576; practical organ DP 1740.

## 4. Equivalent diets / order permutations

Equivalent sequences are generated separately, then often merged too late:
state generation → score → key construction → duplicate rejection. The seen
map is cleared every layer; it does not reuse expensive evaluations across layers.
The key already records item-use quantities, so the beam does not retain every
permutation independently. This is bounded-width work, not an unbounded factorial
frontier, but order permutations still incur generation and scoring costs.

Layer 2 had 1,924 repeated legal keys (28.9% of legal offers). Of these, 1,846
were schedules differing only in the redundant `bare;` marker; another 78 were
other same-key sequences. In layer 3, 1,897/4,124 legal offers repeated keys
(46.0%), including 1,650 bare-only duplicates and 247 other sequences.
An observed example swapped bare deluxe layer cake and a prepared, cooling-enhanced
green drunki-bear, producing the same state key. Another swapped ordinary Skull
Punch/hacked gibson while assigning the cooling enhancement to the other drink.

The 1.56% dedup fraction does NOT mean duplicates are cheap: their wasted
construction/scoring is charged to the other phases. The existing key also
includes reporting/history counters while flooring minimum adventures and omitting
expected adventures; it is not a verified general equivalence relation. A new
quantity/state merger must include every future-relevant value and cash/resource
constraint rather than blindly reusing that key.

## 5. Quantity-based ordinary filling

Yes, within a fixed gear/effect stage, order-insensitive zero-turn food/drink/
spleen consumption can be represented by item quantities. A bounded knapsack/DP
can optimize organ space, finite stock, cash, helper assignments and daily limits,
then construct and validate an ordered schedule only for selected bundles.
The practical planner already has an organ-capacity DP, but still constructs and
scores full states on its transitions and shortlists its local menu.

Keep genuinely ordered events explicit: Yeti XP spending and cooling refresh
boundaries, first-drink shotglass use, one-shot helpers, yield-changing effects,
noodles, organ-clearing resources, mixed/special handlers, capacity swaps,
training, retained late buffs, stillsuit timing and final nightcap. Ordinary
quantity optimization should operate between those events. Plain additive fills
can be O(items × organ capacity); helper/resource state adds bounded dimensions.
Do not simply sort every consumption sequence and assume it is equivalent.

## 6. Exact cache experiment

A scratch variant memoizes rate/item income by static stage and effective modifier
signature, and memoizes the score's future/tomorrow terms by exact adventure and
effect/retention state. Cash, accumulated income and opportunity cost remain on
each state. Timed variable modifiers are included; floating-point arithmetic
ordering is preserved. All transitions, simulations, candidate ordering, legal
checks, deduplication and width are otherwise unchanged. No production code was
replaced. Cache validity is limited to one frozen planning context.

| Same workload | Original | Cached | Speedup | Quality / correctness check |
| --- | ---: | ---: | ---: | --- |
| First 3 beam layers, 33 expanded parents | 57.606 s | 13.842 s | 4.16× | All 16 frontier states, scores, cash, costs and schedules match exactly |
| One complete fixed practical baseline schedule | 16.242 s | 3.457 s | 4.70× | Identical ordered schedule; replay and policy targets pass |

The cached layer-2 run reduced full rate recalculations from 25,536 to 188
(plus 21,134 cheap rate-cache hits; score hits avoid some rate calls entirely).
The same farming/training blocks and the same offers are still evaluated.

The complete-schedule result is identical for both implementations:

- 649 paid encounters, all covered; same XP/retention/reserve policy.
- Income 2,388,646.214 Meat; opportunity cost 743,814 Meat.
- Today's net 1,644,832.214 Meat; combined value 1,744,988.215 Meat.
- Cash requirement 70,268 Meat; ordered replay and all targets pass.

The 16.24/3.46-second measurements cover one fixed schedule, not the entire
practical planner's initial estimate plus its 20-second alternatives budget.
These are single paired offline measurements, not guarantees of live runtime.

## Reconciling the earlier 628 and ~756 encounter reports

The previously reported 628 is the selected late-buff alternative on this saved
reconstruction. Its fixed baseline was 649. It sacrifices some farming to improve
tomorrow's weight value (combined 1,756,711 versus baseline 1,744,988). That earlier
full practical run included setup/estimate/baseline/alternatives and took ~57 s.
It is not the workload timed as one fixed schedule in the table above.

The earlier pasted live report has 227 starting adventures, 2 liver used and
385 drams, versus 235, 3 and 275 in the snapshot. Its cold-fashioned price was
314,000 instead of the snapshot's 500,000, and stock/resources differ. Neither
628 nor 649 is comparable to that live run as evidence of algorithm quality.
No completed beam profit exists to compare against either one.

## Decision and next optimization target

Keep the practical planner as baseline and leave the long beam stopped. Exact
caching is a demonstrated ~4× local improvement with matching results, but a
three-layer benchmark is not evidence that a full beam can finish in 30–120 s
or return a better complete diet. Do not resume the long search to prove that.

Next target: quantity bundles for ordinary fills, shared farming/training prefixes
for a parent's alternative farm horizons, and exact cached economic projections.
Compare complete plans under identical frozen inputs, with ordered replay,
coverage, XP, cash, stock and reserve validation before any replacement.

## Evidence and reproducibility

The isolated harnesses and raw logs are currently under
`/private/tmp/diet-beam-snapshot/`; temporary files are not guaranteed to survive
cleanup. `profile_build.py` instruments the frozen source built by `build.py`;
`cache_build.py` adds the exact memoization experiment. `SnapshotProfile` and
`SnapshotCached` restore the same snapshot. `profile.log`, `profile-native.log`,
`cached.log`, `schedule-original.log` and `schedule-cached.log` contain the raw
measurements. JAR 29366 and Temurin 25.0.4.1 were used with headless Java and a
fake user.home. No live account state was loaded.

SHA-256 of unchanged production planner at measurement:

`f3d1590bd9bdad43d16cdab036c99932d1eeca88b12dd23f025a227f80216a51`

SHA-256 of snapshot inputs used by every paired run:

```text
fa915c262dc08dc8df203b48370169127182fcded07a37ebe37afd661ae6de3b  resources/diet-snapshot/mallprices.txt
84242d1c6d5217012c1d6bb2101b1250ba962d424948a0f5409b7a599d19cb5a  resources/diet-snapshot/teres-barf-diet-consumables.tsv
0a60a100654e0b0a3db836c53163fc6a57badc2f6426b69040e3395a7b489c22  resources/diet-snapshot/teres-barf-diet-inventory.tsv
542f94626c82a71178c4e228dd066429a811dcf810a2f73150d664426f35e120  resources/diet-snapshot/teres-barf-diet-prices.tsv
806ebacc47c326bc3daefe638f034983c93376977abc5d0d28409722e4717deb  resources/diet-snapshot/teres-barf-diet-state.tsv
```

## Production port and structural optimization follow-up

The following changes are now in `scripts/TeresMimicDiet.ash` and enabled by
`barfDietPlan()` through `barfDietResetSearchCaches()`. Run `teresBARF.ash diet-plan`
as before. The active algorithm remains practical planning, and execution remains
dry-run. No live game actions were used for these tests.

- Exact caches for income rate, item income, and score projection terms; accumulated
  financial totals are still combined in the original arithmetic order. Caches
  clear for every new plan. Stage modifiers are included in rate signatures.
- Retained-effect signatures include expired flags and explicit key presence,
  including Smart Drunk's special `contains` behavior. The earlier experimental
  signature needed this hardening before being suitable for production.
- Provably equivalent bare/prepared transitions are omitted before constructing
  the second state. This proof checks helper acquisition, including owned
  seasoning. Ordinary pure-spleen variants receive the same shortcut in the
  practical planner. The original first-winning schedule is preserved.
- Other exact duplicate states can be rejected before scoring, using every state
  dimension, exact expected/minimum adventures, stock/resource counters, XP,
  buffs, gear, cash and financial totals. Schedule text is intentionally excluded:
  a duplicate would already lose the original tie. No approximate signatures
  or rounded adventure buckets are used for this early check.
- Farming alternatives reuse completed training turns and natural effect-expiry
  prefixes from the same exact starting state. Cache records retain the open farm
  row's stage/count, and rebase suffixes onto the caller's original schedule.
  Partially truncated normal blocks are not reused for larger horizons because
  doing so changes floating-point addition grouping. Returned/cached maps are
  cloned; the cache retains only the current parent rather than an unbounded
  collection of full-day forecasts.
- The retained beam uses the current ordinary-quality restriction and 225/400-XP
  Yeti rules, matching the previously profiled experiment and the active planner.

### Independent benchmarks

All modes use the same frozen inputs, 171 candidates and width 16. Each
optimization was independently enabled against the cached implementation;
no new candidate pruning or economic-model relaxation was introduced.

| Three-layer workload | Time | Check |
| --- | ---: | --- |
| Uncached baseline | 52.958 s | Identical 16 retained states, scores and schedules |
| Exact projection caches | 12.335 s | Identical 16 retained states, scores and schedules |
| Caches + early duplicate checks | 12.107 s | Identical 16 retained states, scores and schedules |
| Caches + shared farm/training prefixes | 7.036 s | Identical 16 retained states, scores and schedules |
| All optimizations | 6.451 s | Identical 16 retained states, scores and schedules |

A bare-only shortcut trial took 10.592 seconds; broader full-signature detection
added little on its own. The large additional gain comes from forecast reuse,
not from assuming every duplicate can be identified cheaply. The full-key check
was retained with the combined configuration, which passed all equality checks.
Single-run timings vary; the fresh isolated harness repeated the combined case
in approximately 6.4–6.7 seconds. Later checks compared all state fields/maps,
not just the older rounded beam key, plus scores and complete schedule text.

Shared prefixes reduced simulated blocks in the two measured full layers from
4,218 → 558 and 10,635 → 1,395 while preserving outcomes. The candidate catalog
and genuinely distinct helper/Yeti variants remain available.

All five configurations also produced exactly the same fixed complete practical
baseline: 649 encounters, 743,814 opportunity cost, 2,388,646.214 income and
1,744,988.215 combined value, with matching ordered schedules, replay and targets.
Timing was 15.860 seconds uncached and 3.437 seconds combined. This is one fixed
schedule, not the entire budgeted improvement search.

### Practical planner in production

Both complete practical runs received the same 20-second improvement budget,
after first building their complete baseline:

| Practical run | Planning time | Selected encounters | Modeled combined value | Validation |
| --- | ---: | ---: | ---: | --- |
| Uncached | 56.664 s | 628 | 1,756,711.283 Meat | Replay and policy targets pass |
| Optimized | 24.539 s | 648 | 1,798,728.994 Meat | Replay and policy targets pass |

The optimized run completed more alternatives within that same improvement
budget and selected a better complete diet: +42,017.711 Meat modeled combined
value. This differs from the deterministic equality checks intentionally: the
same search can finish more comparisons when its evaluations are faster.
Absolute values retain the shared snapshot reconstruction limitations above.

The actual production `barfDietPlan()` entry point was also executed offline with
only external price/stash acquisition replaced by frozen inputs. It completed in
25.929 seconds, selected the same ~1,798,729-Meat value, and passed the entry
point's ordered replay of every completed comparison. The native aftercore flag
is explicitly initialized in the permanent harness; fresh-home checks match the
original reference states and fixed complete schedule exactly.

### Complete beam trial and decision

All 160 layers completed in 97.804 seconds, without timeout or candidate/width
reduction. The returned plan remained invalid (`cash=-1`, `finished=false`): no
complete legal diet was found, so there is no beam profitability to report.
The final frontier still required the cold-fashioned double and remaining gear
stages. One representative had 127 farm rows/actions but only two capacity swaps,
with four swaps and Stooper still pending. It had already filled most liver
capacity while the required four-liver drink remained outstanding.

This exposes search-selection/feasibility and action-granularity issues, not a
reason to replace the validated practical planner. Do not relabel frontier
lookahead scores as completed profits or silently weaken cooling, drink, XP or
reserve requirements to obtain a result.

### Quantity exploration and remaining work

An ordinary calzone/wine quantity fixture produces identical economic states
under reordered bare consumption when helper assignments are fixed. A one-shot
percentage-helper fixture with the same quantities produces different yields
when the helper goes to a different food. General quantity bundling therefore
needs explicit helper assignments and boundaries for Yeti, resources, training,
gear and retained buffs. A full quantity optimizer has not been installed; only
proved duplicate transitions are removed. Investigate staged/targeted fill
search separately rather than changing retained states under an "exact" claim.

### Checks and reproduction

Semantic checks cover training/expiry boundaries, partial-block arithmetic,
capacity gear and Stooper, cash/stock/expected-adventure differences, cache
mutation/reset, reuse across differing schedule prefixes, expired retention,
Smart Drunk retained-key presence, quantity commutation and helper-order
counterexamples. Native compilation of Diet, BARF and Mimic imports passed.
All original source comments and frozen snapshot files were preserved.

A permanent offline harness is under `resources/diet-snapshot/benchmark/`:

```sh
python3 resources/diet-snapshot/benchmark/run.py --mode baseline --workload layers --output /private/tmp/diet-base
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload layers --reference /private/tmp/diet-base/output.log --output /private/tmp/diet-fast
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload checks
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload production
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload full
```

Modes `cache`, `early`, `bare`, `farm` and `combinedBare` isolate optimizations;
`baseline` disables them. `schedule` benchmarks one fixed complete schedule,
`practical` includes the alternatives budget, and `production` validates the real
entry path. `--reference` compares every state field, score and ordered schedule
for layer runs, or the full schedule/totals/validation for fixed-schedule runs.
The full-search workload defaults to a 120-second trial deadline and reports whether
it timed out. `--width` defaults to 16; `--timeout-seconds` controls that deadline,
checked between parent expansions. JAR/JDK paths are configurable with `--jar` and `--java-home`.
Generated source, classes, fake Mafia home and logs stay in the output directory.
The harness reads no live account state, performs no network acquisition, and
fails if the frozen candidate count changes from 171.

Production planner SHA-256 after the port:

`06a1a6e84e44be4eceaebbe5a198edf583cdc52742a1f9d65b8dc18aba7b671e`

## Beam width comparison: 8, 16, 32 and 64

Measured October 15, 2026. Width 16 was an initial experimental runtime choice;
the earlier equality benchmarks did not establish it as the best width. This
follow-up changes only the retained width, using the same production search,
all optimizations enabled, the same 171 candidates, frozen October 13 inputs,
economic reconstruction, seven cooling slots and required drink/training rules.
Each search receives 160 layers and the same 600-second safety deadline. Runs
are sequential in fresh isolated native processes, without concurrent benchmarks
or live game actions. Timings below are the harness's planning timers, excluding
JVM startup, compilation and snapshot setup. Each width was measured once.

| Width | Planning time | Layers completed | Transition offers | Complete legal diet |
| ---: | ---: | ---: | ---: | --- |
| 8 | 49.058 s | 160 | 676,749 | None |
| 16 | 95.160 s | 160 | 1,349,567 | None |
| 32 | 190.371 s | 160 | 2,704,085 | None |
| 64 | 379.252 s | 160 | 5,437,164 | None |

No run hit its deadline. Every search returned `cash=-1`, `finished=false`:
there is no completed beam profit to compare, and no completed beam schedule
to replay. The new width-16 run exactly reproduces all 16 frontier scores,
financial totals, keys and ordered schedules from the earlier full trial.

Across **all 120 final retained states** from these four runs, each schedule has
127 farm rows, only two capacity swaps (`mask=12`), no Stooper, liver usage 23,
and the mandatory cold-fashioned still pending (`coldRequired=1`, Yeti double
unused). Widening the beam preserves more versions of that same unfinished
pattern. Time and expansion counts grow approximately linearly without solving
the completion problem. This does not prove every possible larger width fails;
it shows that widening from 8 through 64 is ineffective on this fixture.

The active practical planner was rerun under the same frozen reconstruction and
requested economic/policy assumptions. Its own unchanged setup derives the same
seven cooling slots; beam width does not apply to this planner. With its usual
20-second alternatives budget it finished planning in **24.503 seconds**, selected
**648 paid encounters** and **1,798,728.994 Meat combined modeled value**, and
passed ordered replay and policy targets. This matches the previous optimized
practical result. Absolute income remains provisional for the snapshot limitations
documented above; these are not live profit estimates.

Keep the practical planner active. A useful next beam experiment would address
action granularity and completion-aware selection, including reserving space for
required consumption and reaching remaining gear stages. That would be a search
behavior change and needs its own same-input validation; this comparison introduces
none of those changes and selects no new production beam width.

Reproduce one width (repeat sequentially for 8, 16, 32 and 64):

```sh
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload full --width 32 --timeout-seconds 600 --output /private/tmp/diet-width-comparison/w32
python3 resources/diet-snapshot/benchmark/run.py --mode combined --workload practical --output /private/tmp/diet-width-comparison/practical
```

Raw logs and generated harnesses for this measurement are under
`/private/tmp/diet-width-comparison/w8`, `w16`, `w32`, `w64` and `practical`;
`summary.json` records per-width counters and final-state diagnostics. Temporary
artifacts can be regenerated with the permanent harness. The production source
and all five frozen input hashes above are unchanged.
