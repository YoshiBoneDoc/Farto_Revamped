# Read-only investigation fixtures

These programs generate temporary ASH copies and run the existing production simulator inside an isolated, headless native KoLmafia process. They do not install an optimizer, execute `run`, or make gameplay requests. Production heuristics are unchanged at cleanup commit `5b90025`.

```sh
python3 resources/diet-snapshot/investigation/run_capacity.py
python3 resources/diet-snapshot/investigation/run_budget.py
python3 resources/diet-snapshot/investigation/run_clearing.py
python3 resources/diet-snapshot/investigation/run_capacity.py --snapshot resources/diet-snapshot2 --inactive-stillsuit
```

The capacity probe compares four explicitly forced full schedules, not a new search algorithm: unchanged practical order; same order with both fullness items equipped before filling; fixed order `rosary,corset,chopsticks,dice,greaves,totem`; and that fixed order with grouped fullness. Every accepted schedule must pass production replay, targets, cash, every farm interval's organ limits and removal-of-required-capacity negative checks. The optional fresh case first selects a practical policy under the same 90-second production budget, reconstructs its menu/pours/helper policy and verifies its unchanged score before comparing counterfactuals. The original October 13 case exactly reproduces the 56-trial complete-search winner's objective before interventions.

The budget probe adds logging only to a temporary source copy and runs the unchanged planner at 30/60/90 seconds sequentially. `AUDIT PHASE`, `AUDIT TRIAL` and `AUDIT PAIRS` distinguish deadlines, cached returns, attempted and completed trials. In the saved first traces, summary `completed` means legal returned calls, including cached results (49 at 90 seconds); the derived `completed_attempts` excludes cached calls (44). Future output labels this `completedCalls` to avoid ambiguity. Phase markers are cumulative wall times. Trial-category totals are exclusive across trial invocations, not low-level profiler percentages.

The clearing probe forces listed resources/exchanges before the initial resource pass, then refills with production logic and completes with the existing policy. It includes the production trial's two extra cooling-slot retries. Every valid result is replayed; incomplete plans have no objective or profit claim. `--bundles 'mojo,mojo,mojo;sweat,eat:3325'` selects diagnostic cases without changing the default list. `AUDIT BLOCKED` identifies gross organ, daily-use and cash state when a reserved late meal cannot be consumed.

Portable JSON files keep complete capacity schedules, every farming outfit/capacity interval, completed clearing schedules, budget traces and result summaries. Raw Java logs/generated copies remain under the chosen `/private/tmp` output directories. `collect_capacity.py OUTPUT_DIRECTORY RESULT.json` exports a successful four-schedule comparison.

The old saved export omits kitchen access; all matched tests explicitly assume oven access. Both snapshots omit some native modifiers, familiar soup/feast state and equipment on inactive familiars; absolute income is provisional. Snapshot stock aggregates personal and stash supplies, preserving total availability but not live withdrawal logistics. Default runner pricing preserves the same native recursive recipes and current user assumptions (100-Meat milk, 100k cold-fashioned, maintained tourist buff, fixed rollover). Never compare these raw totals with a different snapshot or a live planner's differently reconstructed income.

Fresh October 16 tests use an explicit `benchInactiveStillsuit=true` reconstruction: one suit on inactive Cooler Yeti, omitted by the export. The unmodified export fails trainer gear availability without it. This ownership assumption was disclosed and confirmation requested; raw snapshot files are unchanged. Fresh policy selection uses 90 seconds and verifies its matched baseline before all four counterfactuals. It produces no grouping gain and a loss from the older fixed order, so that order is not a general optimization.
