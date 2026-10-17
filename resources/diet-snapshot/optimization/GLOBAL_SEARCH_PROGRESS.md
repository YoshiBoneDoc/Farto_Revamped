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
