# Incremental diet search results

October 17, 2026. Commits `7e047f5` (capacity decisions) and `d13fb72` (exact reuse). Production keeps the bounded capacity improvement and exact cache reuse. Earlier-menu, stock-reservation and coupled-menu experiments were rejected. Normal planning remains uncapped, read-only and heuristic.

## Kept: cross-stage capacity decisions

The scheduler can equip both pieces for an organ before filling it, opening space for larger consumables. It can prioritize gear that opens usable ordinary space and defer gear whose space is entirely reserved for the end. Organ grouping comes from native gear modifiers; there are no hardcoded foods or fixed equipment orders.

After the original search finishes, nine bounded complete continuations compete with its existing winner. Failed/inferior candidates cannot displace that winner. Each improvement must meet requested targets and pass production replay. Every existing capacity piece remains worn once added; the same farm guards enforce all three organ limits.

On the fixed historical profile, generic grouping finds +4,542.589 Meat, deferral +2,433.100, both +7,196.880, and all-organ grouping/deferral +7,521.428. These reproduce the investigation without encoding its food names or forced order. On the full current searches, the older selected profile gains 5,032.258 Meat and the fresh control remains unchanged.

## Kept: exact computation reuse

All work before the first capacity decision is shared. Eight successful exact prefixes are retained with LRU eviction, including nearby coverage-slot retries. Eviction triggers recomputation; it never prunes a diet. This storage bound is unrelated to beam width or candidate diversity.

Ordinary-fill caching additionally normalizes the later equipment-policy flag, which is not read by any pure-fill transition or score. It restores that flag on every returned state. Actual gear, organs, stock, XP, helpers, resource use, finances and buff durations remain exact. Only computation changes: all 65 old / 58 fresh complete capacity-control trials have identical states, scores and ordered schedules with the cache changes.

## Full matched results

| Snapshot | Before this round: combined Meat | Kept version: combined Meat | Change | Planning seconds before → after | Peak RSS before → after |
|---|---:|---:|---:|---:|---:|
| October 13 | 2,778,483.141 | 2,783,515.399 | +5,032.258 | 107.365 → 104.325 | 663.5 → 518.5 MB |
| October 16 | 2,472,752.076 | 2,472,752.076 | 0 | 130.770 → 136.820 | 533.8 → 542.5 MB |

These are single-run observations; CPU/JVM variation prevents a general whole-run speedup claim. The useful added capacity phase takes roughly 1–3 seconds. Compared with capacity-only code, the exact caches remove one additional repeated pre-capacity forecast per fixture, 2,824 / 247 consumption evaluations, 10,116 / 835 score evaluations, and 109 / 99 farm blocks. The overall runtime remains in the same range while the planner explores the new capacity alternatives.

All comparisons use identical frozen native inputs within each snapshot: cookie=9 once/day, milk=100, cold-fashioned=100k, unchanged economics, candidate pools 175 / 172, same XP/cooling/rollover constraints, no planning deadline. The fresh fixture explicitly reconstructs the inactive stillsuit and both fixtures assume cooking access. Missing exported modifiers mean absolute incomes remain provisional. No live gameplay occurred.

## Rejected experiments

| Experiment | Evidence | Decision |
|---|---|---|
| Reserve finite late-menu copies before ordinary filling | Recovers a forced three-mojo/body-spradium completion. Neither full-search winner improves; adds about 6 / 11 seconds and raises peak RSS. | Not installed. A completion fix alone does not establish a better default search under the current runtime/profit preference. Shared recipe ingredient reservations also remain unresolved. |
| Frontload four retained-organ footprints | Better older initial selection, same older final profit. Fresh final objective falls by 6,623.680 Meat. | Rejected. |
| Frontload one candidate per organ combination | Older initial plan reaches the previous final objective, but the final result does not improve. The fresh result again regresses by 6,623.680 Meat. | Rejected. Greedily replacing the starting winner can lose a better later branch. |
| Hold grouped-capacity/menu alternatives outside the reference path | Preserves every reference trial and adds 1,419.902 fresh Meat, zero older gain. Even after cache refinements, marginal cost is about 10 seconds on the fresh fixture. | Rejected as too little profit for the added runtime/complexity. |

The early-portfolio experiments demonstrate why a stronger initial complete plan is not proof of a better final search result. Pending/reference bookkeeping and cache isolation were tested; the rejected machinery is not left dormant in production.

Prototype patches, probes, source hashes and numeric evidence are under `resources/diet-snapshot/optimization/`. Rejected patches/probes are marked in its `prototypes/README.md`; apply them only to a temporary `7e047f5` source and use the isolated native harness. `stage-baseline-results.json`, `capacity-results.json` and `kept-results.json` identify the accepted path. Other named JSON files record the rejected experiments.

## Validation and continuation

All original 56 old / 49 fresh completed trials remain present exactly in the capacity expansion. Every complete capacity candidate passes native production replay, including stock/cash, XP, full Looking Cool coverage, mandatory doubled cold-fashioned, capacity legality, retained buffs, final Vintage and the 200-adventure reserve. Focused tests cover the documented gains, reserved-space deferral, exact cached/uncached outcomes, policy restoration, eviction, caller isolation and snapshot reset. Final regression status and commits are recorded in `DIET_OPTIMIZER_PROGRESS.md`.

No candidate pool or fill width was reduced, and no economic assumptions were weakened. This is a modest measured profitability gain, not evidence of global optimality. The original initial-plan selection remains in place because the tested replacements did not earn adoption. Event-based pours and general multi-step clearing remain outside this round; the investigation had not established a profitable complete missed clearing bundle.
