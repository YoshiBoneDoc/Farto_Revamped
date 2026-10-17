# Diet optimizer implementation progress

User approved all six areas autonomously on October 16, 2026. Latest steering removes the normal wall-clock deadline. Preserve a complete fallback, all original comments and all gameplay/economic constraints. No live gameplay tests.

## Starting checkpoint

- Investigation: `3b73837`; cleanup: `5b90025`.
- Current preexisting change: whitespace-only cleanup in TeresMimicDiet.ash; preserve it separately.
- Old/fresh fixtures remain separate. Fresh export omits the inactive stillsuit; use explicit `benchInactiveStillsuit=true` in every matched fresh run. Absolute incomes remain provisional native reconstructions.
- Unrelated deleted archive, .DS_Store, IDE/settings files are outside scope.

## Sequence

1. Freeze current source; baseline both snapshots at 30/60/90 seconds with native RSS measurement.
2. Observability only; exact fixed-work equivalence.
3. General capacity grouping/defer comparisons, including old demonstrated gains and fresh unfavorable control.
4. Equal-budget allocation; late-stock reservation; event pour, clearing bundle and frontier/quantity experiments independently.
5. Keep only validated benefits, run complete regression suite, report matched economic/runtime/memory results.

## Verified work

Observability counters implemented; exact complete-schedule smoke equivalence passes. Counter/expiry fixture passes. Normal deadline removal and cookie valuation are the next independent commits. Prior frozen evidence is in the investigation plan and JSON files. Approval gates in that historical plan have been superseded by the user's latest instruction.

## Latest steering

The user subsequently removed the wall-clock constraint from normal planning and requested fewer repeated/unproductive computations instead. Retain benchmark-only limits for before/after comparisons. Model Affirmation Cookie as 9 base adventures for 1 fullness, one/day. Profit comparisons must distinguish that changed assumption from algorithm improvements.

- `cde436e`: observability only; identical ordered-schedule smoke, counter/expired-pair test and replay pass. Native child RSS measured with wait4. Original-model 30/60/90 matrix complete for both snapshots.
- Normal wall-clock cutoff removed; generous-budget behavior remains the same finite search. Benchmark-only injection retains matched limited runs. Complete-schedule smoke equivalence passes.

- `4081830`: removed production wall-clock deadline; limits exist only in generated offline benchmark copies. Finite comparison loops retained.
- Cookie exception: quality/shortlist inclusion and native yield both use nine base adventures; existing daily counter retained. Focused native checks pass (exact bare yield, second use rejected, already-used exclusion). This is an assumption change, not a search-quality gain.

## Current checkpoint (uncapped follow-up)

- Git commit of cookie fix was blocked by automatic approval review failing on an account usage limit; no action executed and no bypass attempted. Workspace edits remain available. Earlier observability and cutoff changes are committed.
- Economic control frozen at `/private/tmp/diet-roadmap-economic-control.ash` includes cookie=9 and no production cutoff. Old unlimited run completed all 56 comparisons in 115.891 seconds; combined 2,778,483.140999304; all 56 completed diets replay, 54 meet requested targets (two explicitly relaxed training comparisons). Peak RSS 528,285,696 bytes.
- Exact fill cache candidate: all state fields retained in key, successful fills only, schedule suffix rebased, at most 64 entries. Reset with snapshot caches. Native focused tests pass for equality, schedule rebasing, resource/policy/capacity separation and caller isolation. Full-run benefit still pending; do not claim a speedup yet.
- Cookie change invalidates older score/schedule references. Matched new-cookie schedule baseline and cache candidate are exactly equal (661 encounters, same complete state/schedule/score).
- User is editing TeresMimic.ash concurrently; leave those changes untouched.

- Second candidate: cache preparation through training/farming/equipment/pours before final retained-item consumption. Inspection confirms retained item indices are never read by this prefix; only menu fullness/liver/spleen totals and pour reservation are read. Key retains all starting state fields plus these totals and final-pour choice. Maximum 16 successful prefixes; per-snapshot reset. Awaiting full-state/native-schedule equivalence and independent benefit measurements.

- Exact fill cache old full-run validation passes: all 56 completed states/scores/schedules identical, 54 requested-target plans and two relaxed controls. Planning 115.891 → 83.530 seconds; 161,351 → 96,800 consume evaluations; 525,840 → 298,252 scores; 641 exact hits. Peak RSS 528,285,696 → 463,994,880 bytes. No search diversity reduced. Fresh run pending.

- Preparation cache focused native tests pass: different menu identities with identical reserved organs produce identical original/cached prefix states and schedules; rebasing, changed-XP isolation and snapshot reset verified. Independent full-run benchmark pending.

## Latest verified runtime checkpoint

- Commit issue resolved after the usage-reset time. `e629408` saves the cookie fix independently; `d3c1763` saves exact fill reuse independently.
- Combined preparation + fill caches pass exact full-run comparisons on both snapshots: same 56 attempted comparisons and every completed state/score/schedule. Old planning 115.891 → 80.888 seconds; fresh 133.729 → 96.027 seconds. Profit unchanged at 2,778,483.140999 / 2,472,752.076094 under matched new-cookie assumptions. Complete-trial production replay passes for 56 old / 49 fresh diets.
- Preparation reuse alone adds about 2.6 seconds improvement on each fixture and reduces farming blocks 6,663 → 5,538 / 9,032 → 8,521. The larger gain comes from fill reuse. Peak RSS 528.3 → 476.0 MB old; 542.2 → 555.3 MB fresh.
- Portable source/result hashes, counts, phase timings, memory and equality evidence saved in optimization/*cache-results.json and uncapped-control-results.json. Benchmark-only cache switches permit independent reproduction from current code.
- Focused cookie/fill/preparation tests, semantic checks, frontier, planner and pour suites pass. Final ingredient/live/production entry checks are running. No live actions.
- All six original optimization areas are NOT complete. Latest steering prioritizes uncapped runtime improvements; capacity grouping/deferral and the other profitability areas remain for continuation from this verified checkpoint. No partly installed algorithm changes.

- Final regression suite: all 11 cases pass (cookie, exact fill cache, preparation cache, semantics, frontier, planner, pours, ingredients, mocked live driver, native live compatibility, and actual read-only production entry). Production-entry fixture uses a one-second benchmark-only cap after securing its fallback; the full uncapped algorithm is separately validated on both snapshots. Portable regression-results.json records outputs and exit codes.

## Saved commits and next work

- `4081830`: uncapped production planning (earlier in this task).
- `e629408`: nine-adventure daily cookie model.
- `d3c1763`: exact fill reuse.
- `64025c2`: shared retained-menu preparation.
- Offline cache-disable controls also reproduce the uncached complete schedule exactly. Original comments preserved (all 135 in the new-cookie control remain). No additional gameplay calls introduced.
- See DIET_OPTIMIZER_RUNTIME_RESULT.md for matched measurements and limitations. Continue the approved profitability roadmap from capacity grouping/deferral; keep these exact runtime improvements as the new verified baseline.
