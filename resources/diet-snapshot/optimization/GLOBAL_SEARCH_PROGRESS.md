# Diet optimizer checkpoint — October 17, 2026

Verified implementation and complete evidence: `GLOBAL_SEARCH_RESULT.md`, `global-search-results.json`, `global-regression-results.json` in this directory. Production code is `scripts/TeresMimicDiet.ash`.

## Completed

Seven independent implementation commits: `56719a7` (+5 song XP), `3d6fa7b` (lightweight chocolate search), `b59c70b` (state-scoped extra menus), `11cc269` (exact scoring kernels), `ffb39e9` (inactive-only pour trial reuse), `7694468` (certified fixed-continuation 2,000-Meat allowance), `e3af81b` (joint late capacity/consumption/farming events).

Native complete comparisons, +5 song XP and identical economics on BOTH sides, uncapped:

- Old/October 13: 2,777,336.738 → 2,777,336.738 Meat; 128.854 → 128.275 seconds.
- Fresh/October 16: 2,485,140.014 → 2,490,946.465 (+5,806.452); 137.492 → 138.366 seconds.
- Third (`resources/diet-snapshot 3`, space): 2,871,397.071 → 2,874,445.690 (+3,048.620); 196.468 → 184.113 seconds.
- All winners replay/meet targets; 65/58/61 completed native trial validations respectively on both sides.
- All 22 regression cases pass after correcting an old test assertion that required restoring the prior location. Test now allows either the original location or Barf Mountain, while requiring invariant Barf modifiers. Its original failure and successful follow-up remain in the evidence.
- 906 exact score comparisons; four paired native schedules 11.938 → 8.067 seconds with identical states/schedules. Six chocolate reference comparisons 148 → 29 ms. All 166 original source comments retained.

User steering remains binding: capacity gear stays near the end. New event search begins at the incumbent's first late capacity row; no earlier meals, main farming or training are moved. All promoted continuations use native production replay, stock/cash, cooling, organ/equipment legality, required double, training, sweat, retained buffs, final Vintage and rollover checks. No game actions, production time limit or smaller candidate pool introduced.

## Scope limits and next useful work

This is NOT the whole-day quantity/constraint solver. A useful global upper bound and whole-day near-optimality certificate remain unimplemented. `teresBarfDietProfitGap=2000` applies only to exact/certified fixed continuations; output explicitly says it does not bound unexplored whole-day diets. Existing early diet filling and menu/pour comparisons are still heuristic. Do not claim all five architectural recommendations are complete.

The next larger opportunity is initial meal quantity allocation between order-sensitive events, with native complete-plan validation. Build a reproducible favorable complete diet before adding another expensive search. Do not repeat rejected spleen-horizon changes: one looked good with +8 song XP and lost 4,598 Meat under corrected +5 complete economics. Reopening eight prior pour masks cost 27 seconds with zero corrected-fixture gain. Other rejected experiments and their limitations are in the result report.

## Repository and reproduction cautions

Unrelated user edits/deletions are preserved. Five existing working-source function changes (effect/location, relevant effects, stage location, nightcap yield, food/drink yield) were included equally in both evaluated sources but deliberately excluded from implementation commits. Documentation deletions staged by the user must remain staged; do not recreate their deleted `docs/` files. `TeresMimic.ash` edits are unrelated. No `PROJECT_HANDOFF.md` update was requested. No subagents used.

Native snapshot income is provisional because exports omit modifiers. Never compare these native totals to the attached live 4,077,136 Meat as if all economics match. Earlier +8-song results are historical only.

Full raw outputs remain under `/private/tmp/diet-v2-corrected-baseline3`, `diet-v2-final3`, `diet-v2-controls-baseline`, `diet-v2-controls-final`, and `diet-v2-regressions`. Test/report reproduction commands are in `GLOBAL_SEARCH_RESULT.md`. No benchmark or test process remains running.

## October 17 follow-up: pour timing and martini valuation

Commit `48d23e1` repairs the training-coupled stillsuit policy. When a selected complete plan pours shortly after training, the optimizer now compares actual later sweat-yield events and the liver-space alternative through complete native continuations. It keeps the original validated diet unless a later pour wins. On the saved third snapshot, a reproduced weak two-pour schedule improved from 2,832,206.004 to 2,859,204.457 modeled two-day Meat (+26,998.453), changing 10+6 adventure pours to 10+13 while preserving the initial meals and 21 trainer encounters. This is a candidate-level correction, not a gain over the full planner's already better 2,874,445.690 winner, which still selected 10+10+9 pours. The full winner and its 61 completed trial validations were unchanged, and the native 12-case regression suite passed. Evidence: `distill_timing_checks.ash`, `/private/tmp/diet-pour-regressions/results.json`, `/private/tmp/diet-pour-full-third/output.log`.

The martini audit found that drink simulation already used +2 *expected* adventures for an eligible tuxedo shirt, but had also assigned +2 to the conservative minimum. The actual 1–3 bonus has a +1 minimum. Sacramento wine's pinky ring is rounded on each base adventure roll: 5→6 and 6→7, so its mean is 6.5 before Ode. On the third snapshot, Eye and a Twist and low tide martini had been removed by an initial shortlist based on their unmodified adventure strings. The revised initial shortlist retains its original candidates and adds martinis competitive after native temporary gear bonuses; the complete simulator still scores the real item effects and organ constraints. The tuxedo shirt also requires native `can_equip` eligibility.

An experimental union of original and gear-aware ranks kept 189 candidates and took 192.520 versus 174.071 seconds for the same 2,874,445.690 third-snapshot winner. It failed the older fixture's low-roll live replan when a newly chosen Eye and a Twist mix exhausted the Yeti cooling reserve near the end. That union was rejected. The narrower initial-only martini addition and established live-replanning shortlist passed the older fixture's 130 gear configurations, low-roll/lost-fight replan, and nightcap checks; all 12 native regression cases passed. On the identical third snapshot, this final variant kept the 2,874,445.690 winner, 615 encounters and 61 validated complete trials; 184 candidates took 192.921 versus the baseline 176 candidates and 174.071 seconds. Observed peak RSS was 525,058,048 versus 570,982,400 bytes, a single JVM sample rather than a stable memory estimate. The extra initial martinis improved search completeness without improving this frozen winner, at an observed 18.850-second cost. The fixed test `martini_checks.ash` verifies shortlist inclusion, native gear instructions, mean and minimum rolls. Evidence: `/private/tmp/diet-drink-full-before/output.log`, `/private/tmp/diet-drink-narrow-full/output.log`, `/private/tmp/diet-martini-live-safe/output.log`, `/private/tmp/diet-martini-final-check/output.log`, `/private/tmp/diet-pour-regressions/results.json`.
