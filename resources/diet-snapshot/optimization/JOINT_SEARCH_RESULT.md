# Joint quantity/capacity search — verified result

October 17, 2026. First implementation stage complete. Normal `teresBARF.ash diet-plan` now runs joint lookahead after completing the unchanged practical search. The existing winner remains available throughout; every promoted candidate meets requested targets and passes production ordered replay. No purchases, consumption, equipment changes or adventures were executed.

| Frozen snapshot | Previous combined Meat | New combined Meat | Gain | Added lookahead | Observed whole planning before → after |
|---|---:|---:|---:|---:|---:|
| October 13 | 2,783,515.399 | 2,784,531.528 | +1,016.129 | 17.943 s | 103.345 → 114.475 s |
| October 16 | 2,472,752.076 | 2,487,043.748 | +14,291.672 | 1.129 s | 136.151 → 96.256 s |

Whole-run timings vary substantially with the JVM and machine load. The fresh decrease is not attributed to an algorithmic speedup: the new search adds work. Peak RSS observations are 504.4 → 527.3 MB old and 656.5 → 525.1 MB fresh. The newer fixture demonstrates a useful profit gain for little added work; the older fixture gains little and has noticeably higher overhead. No hour-long production search was introduced.

The older winner uses the same consumable quantities, but farms seven encounters after adding the rosary and before adding the next liver accessory. The newer winner replaces one handful of Smithereens with Synthesis: Greed; complete simulation values its remaining Meat coverage above the displaced adventures. Neither item nor equipment order is hardcoded in the search.

## Search behavior

- Quantity enumeration retains all distinct outcomes from the current shortlist under the existing bare/automatic-prepared modes. It does not use the ordinary fill's 1–4-state width limit inside these windows.
- Safe bare consumptions use canonical item order. Helpers, relevant effects, crafting, delayed payouts, breakfast prerequisites, shotglass and conditional wine/martini preparations retain explicit ordering. Exact duplicate states can share work.
- Each same-organ pair of remaining capacity pieces competes in both orders. The search compares filling/farming between pieces with waiting for combined capacity, then evaluates completed production continuations. The current bounded windows cover at most two ordinary organ points per fill; other gameplay events retain their production continuation.
- Equivalent future forecasts share computation. Only dead stock, or exhausted tradeable replacement stock whose daily limit cannot bind within a conservative remaining-consumption bound, is normalized. Live stock, shared recipe ingredients, helper charges, organs, buffs, XP and resource interactions remain explicit.
- Forecasts use canonical financial coordinates. Every considered purchase contributes to a wallet-exposure certificate. A tight wallet uses the real constrained continuation instead. Fill-decision caching is bypassed while tracing exposure, so rejected offers cannot disappear from that certificate.
- An exact value for a fixed continuation can skip its inferior replay. This is not a bound on every unexplored global diet, and no global optimality gap is claimed.

## Verification

All original 65 old / 58 fresh completed practical trials retain identical states, scores and schedules. Both new full-search winners pass production replay. Matched inputs retain cookie=9 once/day, fixed milk=100, cold-fashioned=100k, identical prices/stock and the same 175 / 172 candidates. Cooking access and the fresh inactive stillsuit are explicitly reconstructed. Absolute incomes remain provisional because snapshot exports omit some native modifiers. Normal planning remains uncapped and read-only.

Small exhaustive fills match the canonical outcome sets, including daily limits, existing helpers, effects and zero-organ shotglass use. Reused native suffixes match uncached full states and schedules. Tests protect live ingredients, scarce meals, near-exhausted daily limits, actual liquidity, caller isolation and cache reset. Uncached/unpruned controls select the same objective; all 1,160 old and 51 fresh unpruned generated candidates replay successfully. The old all-candidate validation phase took about 167 seconds; that is offline verification cost, not the daily lookahead runtime.

All 16 final regression cases pass on the frozen optimizer-only version: cookie, fill/preparation/prefix caches, memoization scope, capacity controls, quantities, continuation cache, semantics, frontier, planner, pours, ingredients, mocked live execution, native live compatibility and actual read-only production entry. The entry smoke fixture uses a benchmark-only limit; the full runs above are uncapped. Existing comments and unrelated user edits/deletions are preserved.

## Scope still open

This is a verified first stage toward a broader search, not a proven globally optimal diet. Earlier initial fills, shortlisted items, arbitrary helper combinations, broader cross-organ/event sequences, clearing bundles and pour timing remain restricted by the original planner. A safe upper bound over all remaining schedules and full branch coverage are still required for a genuine optimality certificate. Do not present the fixed-continuation pruning count as a global proof.

Evidence: `joint-search-results.json`, `joint-control-results.json`, `joint-regression-results.json`; targeted reproduction uses `joint-old-probe.ash`, `joint-fresh-probe.ash`, `quantity_checks.ash`, and `joint_cache_checks.ash` through the isolated native `benchmark/run.py` harness. Offline ablations: `benchJointSearch=false`, `benchJointForecastCache=false`, `benchJointBound=false`, and `benchValidateJoint=true`. These switches are injected only into generated benchmark copies.

Concurrent working-file changes to yield/passive calculations and location handling are preserved outside these commits. The matched figures above use the frozen model, and do not establish before/after profit under those newer assumptions. The combined working file gets a separate quantity/compilation smoke check.
