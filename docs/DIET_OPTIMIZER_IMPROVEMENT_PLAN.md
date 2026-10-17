# Diet optimizer investigation and proposed improvements

October 16, 2026. **Investigation complete; algorithm changes are not approved or implemented.** Consolidation and regression results are in `DIET_OPTIMIZER_CONSOLIDATION_RESULT.md`. This document is the second approval gate required by `resources/DIET_OPTIMIZER_CONSOLIDATION_REVISED.md`.

## 1. Scope, recovery and evidence quality

- `6b679da` preserves the implementations before cleanup; `527d266` freezes the pre-cleanup environment and results; `5b90025` is the cleanup-only commit.
- Cleanup preserves all 56 completed practical trials exactly, including their states, scores and ordered schedules. All 177 original comment tokens remain. Native parsing, ingredient, semantic, clearing, pour and mocked live tests pass. No material runtime regression: 106.743 versus 107.397 seconds for identical complete search work.
- Every investigation changes only temporary offline copies or test fixtures. The production practical planner, live driver, discovery, search order, formulas and default budget remain unchanged. The practical planner remains the complete fallback.
- The October 13 export starts with 235 adventures, organs 0/15, 3/21, 0/15, sweat 275, Chest XP 955 and Yeti XP 1035. The complete-search baseline has 174 candidates and exhausts 56 trials under the same 300-second safety budget in about 107 seconds. This larger safety budget is solely for cleanup equivalence; the production default remains 90 seconds.
- The actual preview core rebuilds a 167-entry shortlist on this fixture. Its normal 90-second result is separately frozen and byte-identical after cleanup. **Do not compare the 174-candidate practical harness and 167-candidate preview as different algorithms' profits.** All capacity counterfactuals below use the same 174-entry inputs and policy. The 30/60/90 budget comparison also uses those same inputs.
- Frozen native prices, ingredients, combined owned/stash stock, skills, organs, effects, XP, resources and user assumptions are identical within each comparison. Milk costs 100; cold-fashioned costs 100k; tourist buff is maintained at the agreed guide cost; rollover is 145 total; no invented new Buzzed value is credited.
- Both exports omit some native state. Oven access is an explicit fixture assumption. Familiar soup/feast and other unexported modifiers mean **absolute income remains provisional**. No same-snapshot result is evidence of identical live profit. No gameplay requests, purchases, consumption, stash withdrawals, equipment changes or adventures occurred.
- The historical six-casserole/two-ricotta run's precise starting state is unavailable. The old frozen winner uses two early casseroles and two separate late ricottas; it reproduces the same problematic stage structure, not that historical run's exact counts.

Portable evidence and reproduction programs are under `resources/diet-snapshot/investigation/`. Capacity JSON includes complete ordered schedules, each farm interval's organ limits and exact worn gear; budget JSON includes every trial's elapsed time, deadline state and counts; clearing JSON preserves full schedules only for validated candidates.

## 2. Confirmed cross-stage capacity opportunity

### Current generation behavior

The [practical scheduler](../scripts/TeresMimicDiet.ash#L1898) fills the current stage, handles resources/training/pours, then farms all available adventures at that stage. For the next capacity addition, it tests each unused bit with `barfDietCapacityState()` and chooses the highest **immediate farming rate**. It equips that one piece, calls [QuickFillStage](../scripts/TeresMimicDiet.ash#L1805), retries deferred resources, farms, then repeats. It does not compare complete continuations for alternate capacity orders or two additions before the next fill.

`QuickFillStage()` limits each organ to current capacity while reserving final organ room for retained meals, pours, mandatory cold-fashioned and cooling drinks. Consequently, a one-fullness addition can only offer one-fullness ordinary food. A two-fullness casserole is never offered across the two separate one-point stages. Increasing the fill width cannot generate that missing two-piece event.

There is a related ordering loss: a capacity piece can be selected even when its newly opened space is wholly reserved for final consumption. It supplies no immediate food or adventures but its weaker farming outfit remains worn in later stages. This is legal; it needlessly pays the outfit penalty early in the demonstrated fixture.

### Actual prices, quantities and helpers

| Item | Fullness | Minimum / expected adventures | Ingredient opportunity cost | Owned stock |
|---|---:|---:|---:|---:|
| Pete's rich ricotta | 1 | 6 / 7 | 2 whey × 997 = 1,994 | 13 |
| Baked veggie ricotta casserole | 2 | 15 / 16 | 1 roasted vegetable × 2,498 + 1 ricotta × 1,994 = 4,492 | 4 |

The nested roasted vegetable is priced from its real raw recipe. Ingredient value is charged even for owned untradeable meals. Two ricottas cost 3,988, so the casserole costs **504 more**, not less. Late rows use `bare;` with no new helper purchases or remaining milk/aioli charges. Their stat/regen effects have no additional Meat/item/weight/XP value under this model. Earlier consumption/helpers remain unchanged. The third casserole fits the frozen stock; no free recipe, extra daily allowance or cash subsidy is invented.

### Two complete legal schedules, plus two fixed-order controls

These are forced counterfactuals evaluated by the existing production transitions; no alternate optimizer was installed. The unchanged counterfactual exactly reproduces the exhaustive practical winner's objective before interventions.

| Complete schedule | Encounters | Income | Opportunity cost | Purchase cash | Today's net | Tomorrow value | Combined objective | Delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Current incremental order | 673 | 3,025,811.898 | 390,639 | 69,914 | 2,635,172.898 | 141,887.668 | 2,777,060.565 | — |
| Same order, grouped fullness | 675 | 3,030,858.487 | 391,143 | 69,914 | 2,639,715.487 | 141,887.668 | 2,781,603.154 | **+4,542.589** |
| Defer unused spleen gear; incremental fullness | 673 | 3,028,244.997 | 390,639 | 69,914 | 2,637,605.997 | 141,887.668 | 2,779,493.665 | **+2,433.100** |
| Defer unused spleen gear; grouped fullness | 675 | 3,033,512.777 | 391,143 | 69,914 | 2,642,369.777 | 141,887.668 | 2,784,257.445 | **+7,196.880** |

All four pass production replay, targets and cash checks. They keep Chest XP 955, ending Yeti XP 658, peak Yeti 2008, 35 Yeti training encounters/34 songs, seven cooling refreshes, zero uncovered encounters, one cold-fashioned daily double, three pours yielding 11+10+10, the same final retained effects, final Vintage, and 200 projected tomorrow adventures. Their respective 673/675 paid encounters are fully covered. The full objective includes all earlier farming, training supply/foregone-income costs, clearers, helper costs, item income, effect expiration, stillsuit/liver competition, late effects and rollover.

This is a **small demonstrated gain**, about 0.26% for the best forced case. It is not a claim that this fixed order is generally optimal. The controls take roughly 1.4 seconds each after shared caches are warm; the first complete schedule takes about 3.9 seconds. These are observational same-process costs, not independent cold-start performance guarantees.

### Exact capacity and outfit timeline

Bits: corset `1`, chopsticks `2`, dice `4`, rosary `8`, totem `16`, greaves `32`; Stooper is tracked separately. Extra fullness from the already used distention pill makes baseline food capacity 16. Training finishes before any capacity addition.

The first **634** encounters are identical across all four schedules. At that point organs are 16/16 fullness, 21/21 liver, 15/15 spleen. Equip rosary, consume one wine and farm seven more encounters at mask 8, with organs 16/16, 22/22, 15/15. The remaining two comparison branches diverge at encounter 641:

| Branch / interval | Worn capacity mask | Consumption and farm encounters | Organ use / actual capacity during farming |
|---|---:|---|---|
| Incremental A | 41: rosary + greaves + corset | ricotta; 7 encounters, starting 641 | 17/17, 22/22, 15/16 |
| Incremental A+B | 43: add chopsticks | ricotta; 7, starting 648 | 18/18, 22/22, 15/16 |
| Incremental next liver | 47: add dice | wine; 8, starting 655 | 18/18, 23/23, 15/16 |
| Incremental final | 63 + Stooper | final pour/retained spleen meals/wish; 10, starting 663 | 18/18, 24/24, 17/17 |
| Grouped A+B | 43: both fullness pieces, rosary and greaves | casserole; 16, starting 641 | 18/18, 22/22, 15/16 |
| Grouped next liver | 47 | wine; 8, starting 657 | 18/18, 23/23, 15/16 |
| Grouped final | 63 + Stooper | final pour/retained spleen meals/wish; 10, starting 665 | 18/18, 24/24, 17/17 |

At mask 41 the shirt is devilbone corset, pants devilbone greaves, acc1 devilbone rosary, acc2 cheap sunglasses, acc3 yamtility belt, weapon June cleaver and off-hand Half a Purse. Mask 43 replaces acc3 with chopsticks; mask 47 replaces acc2 with dice; mask 63 replaces the off-hand with totem. Jill and her LED candle remain until the final Stooper stage. Normal hat/back choices remain those of the fixed baseline.

The old fixture's recorded interval-start modifiers include: mask 41, +1003.143% total modeled Meat and +591.960% Item; mask 43, +948.143% Meat and +591.960% Item; mask 47, +888.143% Meat and +591.960% Item; final Stooper, +700% Meat and +250% Item. The detailed JSON records modifiers, effects/durations, weight and familiar gear for every farm interval. These are provisional native reconstructed modifiers, not the user's live buffed totals. The production farm simulator splits intervals at effect/training boundaries and recalculates income as effects expire.

The two fixed-order controls use `rosary → corset → chopsticks → dice → greaves → totem`. They keep Galapagosian Cuisses during the food and extra-wine farming, then equip greaves before consuming the final spleen items. Thus the affected food masks are 9/11 or grouped 11, and the wine mask is 15; final mask is still 63 plus Stooper. Their full interval records and gear maps are in the same JSON.

For the original-order comparison, the seven A-only encounters earn 3,122.084846 Meat per encounter under the complete model; A+B earns 2,989.020330. Wearing chopsticks earlier really costs **931.451613** over those seven encounters. The casserole's two extra encounters earn **5,978.040660**, so income rises 5,046.589048 and net rises 4,542.589048 after its extra 504 cost. All remaining costs, guide count, training, pour yields and tomorrow values were recomputed and are unchanged in this case. This decomposition explains the result; it does not replace full replay.

### Required equipment never disappears

[FarmLegal](../scripts/TeresMimicDiet.ash#L611) checks fullness, liver and spleen independently against the current stage. [CapacityState](../scripts/TeresMimicDiet.ash#L1357) adds bits monotonically and validates the resulting organs/outfit; [shared planned outfits](../scripts/teresBarfSupport.ash#L253) retain the pieces for every later affected interval. The investigation walks each complete schedule and additionally verifies that removing any piece whose capacity is currently needed causes the farm guard to reject adventuring.

The live path restores the planned outfit and checks real organ limits in [LiveGear](../scripts/TeresMimicDietLive.ash#L85). Temporary pinky-ring/tuxedo swaps have their own room checks, verify the incoming food/drink against all three physical limits, then restore capacity gear in `finally` ([consumption dispatcher](../scripts/TeresMimicDietLive.ash#L149)). Ring/tuxedo forecast checks also respect the displaced capacity. No branch models farming in the baseline outfit while over its capacity.

## 3. Fresh October 16 validation

The user supplied `resources/diet-snapshot2` during the investigation. It starts at **168 adventures**, organs 0/15, 3/21, 0/15, sweat **331**, Chest XP **1003** and Yeti XP **1779**. Native frozen prices now give ricotta **1,800** and casserole **4,200**, consistent with the illustrative example. The candidate pool is **171**, shared by all fresh alternatives. These figures must not be mixed with the old fixture's 174-candidate results.

The fresh export records amulet coin on the active Stocking Mimic and no inventory copy of tiny stillsuit. Its snapshot routine does not export equipment on inactive familiars. The first unamended offline run therefore failed the **trainer outfit availability check**, before a complete estimate existed. That failure has no diet-profit interpretation. The old export explicitly records the stillsuit equipped on the active familiar.

A second, explicitly labeled **conditional fixture restores one owned tiny stillsuit on the inactive Cooler Yeti in memory**, plus the same oven assumption. This relies on continued ownership from the prior export; confirmation of its current location was requested. Neither the raw snapshot nor production/game state is changed. Both fresh alternatives use exactly that reconstruction. This assumption must be confirmed before treating this as a fully verified current-state forecast; unexported soup/feast/stats still limit absolute income accuracy.

First run the unchanged practical planner at 90 seconds, then reconstruct its exact selected helper/XP-food/late-menu/pour/cooling profile and require the unchanged complete objective to match before comparing capacity alternatives. This run attempted 42 comparisons; its selected plan uses a 15-adventure middle pour, six cooling refreshes, one cold-fashioned double, 21 Yeti trainer encounters, Chest XP 1003 / final Yeti XP 914, complete Looking Cool coverage and 200 projected tomorrow adventures.

| Fresh matched complete schedule | Encounters | Income | Opportunity cost | Cash purchases | Tomorrow value | Combined | Delta |
|---|---:|---:|---:|---:|---:|---:|---:|
| Selected practical policy / current order | 596 | 2,681,572.866 | 373,466 | 73,403 | 166,926.668 | 2,475,033.533 | — |
| Same policy, grouped fullness | 596 | 2,681,572.866 | 373,466 | 73,403 | 166,926.668 | 2,475,033.533 | **0** |
| Fixed defer-greaves order, incremental fullness | 596 | 2,680,638.994 | 373,466 | 73,403 | 166,926.668 | 2,474,099.662 | **−933.872** |
| Same fixed order, grouped fullness | 596 | 2,680,638.994 | 373,466 | 73,403 | 166,926.668 | 2,474,099.662 | **−933.872** |

All four pass production replay, cash, organ/timeline and requested-target checks. The selected late menu is **rat pizza + abstraction: joy + Amnesiac Ale**. The pizza reserves both extra food spaces, so there are no late ordinary ricottas for grouping to replace. The grouped branch gains nothing. Forcing the old fixture's fixed order applies food gear before this fresh policy needs it and loses income; it must not replace the current schedule.

Exact fresh tail: baseline farming through turn 567; rosary/wine at mask 8 for 7 encounters; totem/spleen fill at mask 24 for 2; then greaves, corset, chopsticks and dice with no intervening ordinary-food farming; Stooper and final retained meals yield 20 encounters at mask 63, organs 18/18, 24/24, 17/17. Full starting gear, every farm interval and complete action rows are in `fresh-capacity-results.json`.

This provides the required **no-gain/unfavorable control**: enable complete-schedule comparisons, not a universal casserole preference or a hardcoded capacity order. The old gain remains genuine under its own frozen assumptions; it is not demonstrated for today's selected policy.

## 4. Clearing and exchange investigation

The [resource pass](../scripts/TeresMimicDiet.ash#L1846) tests one resource followed by real refilling and accepts it only if the current partial score strictly improves. It repeats earlier actions after an accepted state change and retries deferred threshold-dependent clearers after training/capacity/pour events. This correctly avoids dismissing melange merely because the *initial* organs are below 3/3. Existing low-organ retry tests pass.

It still cannot generally traverse an equal-score or negative-score prerequisite just because a later action might make the whole chain worthwhile. The original organ planner's flat marginal estimates do not solve that limitation; the removed beam could offer individual actions but had neither a reliable completion guarantee nor evidence it retained such a useful chain. Its width-64 completion failure is documented in audit B1.

The frozen initial-fill event has organs 15,13,15 before the normal clearer pass. Single resource + refill deltas are:

| Resource | Modeled local change | Interpretation |
|---|---:|---|
| Sweat cast | +70,143.62 | Already worth accepting; three-cast daily/sweat limits apply |
| Aug. 16 / distention | +26,421.35 each | Already accepted when legal; distinct daily resources |
| Mojo | +16,603.19 | Already worth accepting, maximum three filters |
| Dog hair | +23,414.54 | Already worth accepting; one daily use |
| Melange | −97,720.32 | Costs 245k even though one is owned; requires full 3/3 cleansing |
| Sweet tooth / Voraci | −42,578.65 / −46,576.65 | Extra capacity does not automatically pay for the resource |
| Sobrie | −46,584.46 | Costs 69,999; clears one liver, not a permanent capacity increase |
| Spleen noodle choice | Unavailable here | Needs gross one-food room and spleen room before its refund |

These are **partial-score observations**, not final profit claims. Complete forced tests use the same initial policy as the capacity baseline and the same native resource, fill, training, cooling and finish functions. They include the production trial's two extra cooling-slot retries. Thirteen explicitly listed bundles were checked, including resources alone, both melange/Sobrie orders, repeated sweat/mojo, dog hair + distention, and all four exchange meals.

| Complete validated continuation | Encounters | Combined change vs matched baseline |
|---|---:|---:|
| Force Sobrie | 680 | −47,193.79 |
| Force melange + Sobrie, either order | 725 | −143,586.90 |
| Force two sweat casts before refill | 673 | 0 |
| Force dog hair + distention before refill | 673 | 0 |
| Melange + Aug.16 + Burnsger, then refill | 737 | −247,209.87 |

**No missed profitable complete clearing bundle was established.** Other listed probes failed to produce a valid continuation under that fixed policy. Melange alone, pickle juice or thyme cocktail can exhaust the tested cooling/liver continuation; this is a reason to reject those incomplete comparisons, not proof that no legal game sequence exists. Tests preserve gross-space checks: slider/pickle require five spleen already used and room for the whole five-fullness/five-liver item; Burnsger requires two liver used and four gross fullness room; thyme requires two fullness used and four gross liver room. Refunding another organ does not bypass gross room, stock, daily limits or available cash. All four special items cost 190k in the fixture; owned copies retain opportunity cost.

A separate completion limitation was demonstrated: after a forced three-mojo or pickle/slider sequence, ordinary filling can consume the sole body spradium before its reserved late use. The late consume then fails with `uses=1`, remaining-use limit `1`, despite two reserved spleen spaces still being open and ample cash. This is **finite stock**, not necessarily a once-per-day restriction: `BuildItems` caps the untradeable entry to its one owned copy. Current menu reservation protects organ space but does not explicitly reserve that item's stock/use count. The diagnostic trace names the consumed entry and exact organs. No invalid candidate displaces the fallback, and no positive completed objective has yet been demonstrated by fixing this reservation. Study that prerequisite before pursuing a general bundle optimizer.

## 5. Budget measurements and joint-pair counter

The unchanged planner ran sequentially under identical 30/60/90-second limits. Instrumentation exists only in temporary source copies; wall-clock effects still make boundary trial counts slightly variable. All three selected plans pass production replay and targets.

| Budget | Actual planning ms | Attempts | Completed attempts | Generated / width-pruned fill states | Encounters | Combined value |
|---|---:|---:|---:|---:|---:|---:|
| 30 s | 30,153 | 11 | 10 | 27,243 / 20,127 | 670 | 2,759,613.194 |
| 60 s | 60,070 | 27 | 25 | 63,363 / 46,681 | 671 | 2,771,815.316 |
| 90 s | 90,069 | 45 | 44 | 105,234 / 77,222 | 673 | 2,773,699.144 |

The 90-second trace also has five cached trial returns. Its original summary's `completed=49` counts legal calls including those returns; the table counts **44 newly completed attempts**. Future diagnostic output names the former `completedCalls`. Neither cache hits nor relaxed-target comparisons are additional better valid diets.

| Trial category, 90-second run | Measured time | Share of ~90 seconds | New attempts |
|---|---:|---:|---:|
| Preliminary schedule + non-trial overhead | ~4.85 s | ~5.4% | separate estimate |
| Complete fallback trial | 3.64 s | 4.0% | 1 |
| Early familiar-XP meals | 8.94 s | 9.9% | 3 |
| Starting menu/helper/extras policies | 13.25 s | 14.7% | 6 |
| Sampled stillsuit allocations/splits | 20.70 s | 23.0% | 12 |
| Wider fill trial | 8.42 s | 9.4% | 1 |
| Local menu/helper/pour refinements | 9.92 s | 11.0% | 7 |
| Reduced/skip training comparisons | 2.65 s | 2.9% | 2 |
| Joint retained pairs | 17.70 s | 19.7% | 13, including interrupted final attempt |

These disjoint trial categories are wall-clock measurements, **not** percentages for state generation/scoring/deduplication internals. Inclusive low-level timing must not be added to them. The wider-fill trial did not improve this fixture's completed winner. This does not prove it is useless generally; it protects different stock/feasibility cases.

| Pair observability | 30 s | 60 s | 90 s |
|---|---:|---:|---:|
| Generator reached | yes | yes | yes |
| Time reached | 30.086 s | 57.787 s | 72.290 s |
| Deadline already expired | yes | no | no |
| Eligible pairs generated | 0 | 172 | 172 |
| Top estimates retained | 0 | 12 | 12 |
| Complete-schedule pair attempts | 0 | 2 | 13 |
| Completed pair attempts | 0 | 1 | 12 |

At 30 seconds the first pour trial consumes the remaining deadline; all later phases are reached with no usable time. At 60 seconds, pours finish at 51.197 seconds and the width trial uses the pre-training subdeadline at 55.043; no ordinary local refinements finish before training/pairs. At 90 seconds pours finish at 51.299, width at 59.714, local refinement at 69.643 and training at 72.290.

The historical 90-second screenshot's 22 comparisons / 117,844 states / 88,487 pruned / zero pairs is **not reproduced**. Its exact code/input/performance state is unavailable. The new traces prove that expiration can cause zero pairs, not that it caused that historical value. The production counter counts eligible pairs considered, not completed pair diets, and does not currently distinguish generator reachability from expiry. The original exhaustive run reaches all 12 estimated menus and both pour choices, producing a complete winner worth only ~3,361 more than the 90-second winner. More time alone has diminishing returns on this fixture.

## 6. Partial states, quantities, helpers and timing

- [QuickFill](../scripts/TeresMimicDiet.ash#L1621) keeps one partial choice per size unless a wider profile is selected; it broadens/retries width two if exact filling fails. Approximately 73% of generated states are width-pruned in these runs. That percentage is not a measure of lost profit: it includes many weak alternatives, and no known global optimum supplies a denominator.
- Exact-state keys include precise adventures/minimums, organs, mask, Stooper, XP, sweat, buffs/durations, retained effects, helpers, stock/resource use and finances; schedule text is excluded. Exact duplicates are safe to merge. Differently ordered consumptions can therefore converge, but they are still generated/simulated before deduplication in an ordinary fill.
- [FillDominates](../scripts/TeresMimicDiet.ash#L662) first requires matching future-relevant state class. Only then does it compare guaranteed/expected adventures, cumulative purchase spending, liquidity and net value. Expensive food with an additional Meat/XP buff or longer duration is a distinct state and is not financially dominated by a cheaper unbuffed meal. Existing tests demonstrate a costly Meat buff repaying itself over actual subsequent farming.
- Width pruning is different from dominance. A narrow frontier can discard a valuable future investment or stock allocation even though it was not dominated. The finite-stock synthetic counterexample uses sizes 1/3/5 with limits 2/2/1 and target 11; retaining only a locally best prefix can lose exact feasibility, whereas the production retry recovers `3+3+5` with 53 modeled adventures. This is already mitigated for that fixture, not a newly proven missed real-profit diet.
- The confirmed casserole gain is caused by **missing cross-stage generation**, not demonstrated bad Pareto pruning. No complete native missed winner was traced specifically to width pruning in this investigation. Do not reduce candidate diversity, weaken dominance or inflate width solely because the pruned count is large.
- Quantity-based ordinary fills are reasonable only within an event segment where commutativity is proven. Helpers, milk's first food, seasoning, noodles' duration charges, empty-stomach foods, wish-enhanced beer, gross organ refunds, expiry/training and pours are order-sensitive boundaries. The existing quantity-equivalence and helper-order counterexample tests pass. Canonically merging across those events would be unsafe.
- Current early XP-food comparisons evaluate complete training consequences; do not replace them with a guessed permanent Meat value per familiar XP. The selected old winner uses focaccia. The planner already avoids arbitrary Looking Cool timing searches on its completed-plan path; the user explicitly chose to leave the preliminary generic Yeti-mode estimate unchanged.
- Pours consume all sweat, use one liver, and grow from actual forecast combat sweat; ordinary drinks compete in complete schedules. Current search samples up to four pours with training/mid/final checkpoints and 25/50/75% splits. The 12-trial time allocation is material, but no superior complete untested pour timing was demonstrated here. Future next-yield/training/cooling/expiry boundaries are better hypotheses than an all-turn grid. Continue to ignore newly generated Buzzed value as requested.

## 7. Ranked proposals requiring approval

| Priority | Proposal and falsifiable hypothesis | Functions affected if approved | Value / runtime estimate | Principal risks and acceptance fixtures |
|---|---|---|---|---|
| 1 | Bounded capacity grouping and defer-unused-capacity comparison: at least the four demonstrated schedules are reachable; choose by full validated objective | QuickSchedule, QuickFillStage, trial profile/key handling; shared transitions remain authoritative | **Measured old opportunity +4,543 to +7,197 Meat**. Estimate 2–10 seconds for a few extra warm complete continuations, not a guarantee | Never remove required gear; include temporary swaps, exact organs, training, stock, cooling, payouts, nightcap and reserve. Both snapshots, high outfit-loss cases, no-gain cases, unavailable pieces, low cash, reserved food/spleen, ongoing pours |
| 2 | Add budget/counter observability, then compare bounded phase allocation under the same limit: structurally distinct capacity trials get time before repeated local work | QuickPlan, QuickTrial, QuickPairMenus, report counters | Observability has no direct profit claim. Estimated small logging overhead; allocation gain unmeasured | Separate logging-only commit with exact regressions before changing search order. Match 30/60/90 inputs; always secure fallback; distinguish eligible/top/attempted/completed/cache/expiry |
| 3 | Investigate reserving late-menu copies/use counts, not just organ room; prove it produces a better complete candidate before enabling | QuickFillStage/QuickChoices/QuickConsume menu context, trial keys, live remaining menu reconstruction | Completion failure demonstrated for one-copy body spradium; **profit gain unknown**. Estimate bounded checks, low CPU cost | Avoid subtracting stock twice; owned/crafted/shared recipe stock, same-item repeats, daily groups, partial live consumption. Failures remain failures until full replay succeeds |
| 4 | Event-based stillsuit timing shortlist can equal/improve sampled splits with fewer complete trials | QuickPlan timing generation, PourReserve/TimedPour; FarmState unchanged | Existing pours already add value; incremental gain **unmeasured**. Aim to fit within current ~21-second allocation | Sweat active/inactive suit rates, trainers/NCs, pending liver, skipped checkpoint, min reserve; no invented Buzzed credit. Retain sampled fallback if events lose quality |
| 5 | Only after a positive complete counterexample, test bounded two/three-action clearer/exchange bundles | QuickResources, existing ResourceState/ConsumeState, completion boundary | **No profitable missed bundle established**; benefit unknown. A full action Cartesian product is too expensive | Strict gross room and 3/3 melange; shared use limits, exact refills, early-cooling/XP, finite late stock, cash. A negative intermediate may be traversed only inside a bounded candidate that later completes |
| 6 | Investigate diversity/feasibility buckets or commutative quantity segments only where a complete missed winner is reproduced | QuickFill, state classification/admission, QuickChoices | Gain **unmeasured**; width-two trial cost ~8.4 seconds for no gain here | Do not merge different effects/durations, XP, stock, cash requirements or pending pours; exact existing counterexamples and new complete winner required. No full-day beam revival |

## 8. Minimal bounded lookahead design for review

This is a design, not implemented production code:

1. Secure the current complete fallback and select a promising practical profile using the existing model.
2. At a capacity event, retain the unchanged one-piece branch. Add at most a small explicit set of alternatives: introduce the second piece for the same organ before filling; defer a piece whose new space is entirely reserved until the event that actually needs it. The old fixture's concrete two-food grouping and delayed-greaves controls are mandatory cases. Do not enumerate all six-piece permutations or every consumption order.
3. Reuse the same ordinary-fill choices, resource legality, training/cooling/pour policy and native simulator. Keep required mask bits for every later farm interval. Compare entire completed suffixes with the identical prefix and full two-day objective. A partial score may order trials, never certify a winner.
4. Limit these comparisons to a few candidates on the selected profile, **not** on each of the 56 full policies. Reuse the unaltered continuation rather than introducing a general full-day completion/search engine. Any shared helper extraction needed later is a separate reviewed change; none was performed in cleanup.
5. Require replay, requested targets, cash, all organ limits, helpers/recipes, stock, clearers, retained durations and rollover. If a branch fails or the deadline interrupts it, keep the previous complete plan and report no profit for it.
6. Benchmark a capped set of roughly three same-organ grouping opportunities plus one defer-unused control against the unchanged baseline. This cap is a proposed runtime limit to test, not a claim that four comparisons suffice in every state. Keep all discovered candidate items and existing fill width.
7. Schedule the bounded experiment within the existing 30/60/90 budgets after approval. Determine which lower-yield refinement to postpone from measured gains; do not silently add another unlimited budget or remove existing candidate diversity.

## 9. Incremental implementation and benchmark sequence

All following commits require the second approval; none exists yet:

1. **Observability only:** phase deadlines/reachability, attempted/completed/cached trial counts, pair-generator counters and per-category time. Require unchanged completed work/objectives with a generous fixed-work budget; normal deadline differences must be explained.
2. **Capacity opportunity only:** smallest shared continuation hook necessary, grouped same-organ additions, then a separately measured defer-unused variant. Keep baseline reachable. Prove the old +4,542.589/+7,196.880 counterfactuals, check the fresh fixture, and validate unfavorable examples. Benchmark runtime/memory and whole schedules at equal budgets.
3. **Budget allocation only:** reserve a measured bounded share for structural comparisons; independently compare old versus new order at 30/60/90. No changes to economic scoring or candidates in this commit.
4. **Late stock reservation investigation:** first demonstrate a completed legal alternative and compare full value; only then implement the smallest proven reservation change, including live-replanning tests.
5. **Pour events, clearer bundles, then frontier/quantity work:** separate hypotheses/commits; require a real complete counterexample and native replay before accepting each. Stop at useful measured returns; do not launch full-day beam runs.

Acceptance on every approved change: same inputs/assumptions; at least one proven intended gain or equivalent quality with meaningful speed benefit; no illegal/incomplete candidate admitted; exact organs and maintained equipment; full Looking Cool; required double and XP; actual sweat/liver; retained effects; final Vintage and 200 tomorrow; finite stock and liquidity; dry-run safety; unchanged unrelated live behavior. Track worst-case runtime and abort to the complete fallback at the existing limit. Keep cleanup separately reversible.

**STOP: request approval to implement the bounded capacity comparisons and observational counters first.** No authority is inferred to implement the other proposals or change production assumptions from this investigation.
