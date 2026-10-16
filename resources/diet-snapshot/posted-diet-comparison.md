# Audit of the two pasted diet reports

October 15, 2026. This audits the user's CONSUME and BARF outputs starting with
227 adventures. It is separate from the October 13 snapshot benchmarks, whose
235 adventures, 3 drunkenness and prices do not match these pasted outputs.
No live purchases, consumption, adventures, or account writes were performed.
The production planner and installed CONSUME sources are unchanged.

## What the quoted profits actually measure

CONSUME's profit increase for including existing adventures is
3,778,117 - 2,302,617 = 1,475,500 = 227 × 6,500 Meat. Thus its pasted report values
each adventure at a flat 6,500 Meat. BARF instead forecasts stage/effect/training
income: 3,690,649 / 687 = about 5,372.12 Meat per paid encounter on this report.
Comparing CONSUME's 3,778,117 directly to BARF's 3,138,462 today or 3,272,003 combined
does not compare the diets under the same income assumptions.

## Native reproduction of a CONSUME reporting bug

Read the installed CONSUME.ash and CONSUME/{RECORDS,HELPERS,INFO,CONSTANTS}.ash.
An isolated copy of those sources was loaded through KoLmafia 29366's native ASH
runtime in `/private/tmp/diet-posted-comparison/`, using a fake user.home. The
probe builds the quoted quantities: 27 low tide martinis with Ode/tuxedo, 10
casseroles with 10 aioli and the first spork/Universal Seasoning, 18 patches,
essential tofu, milk, three Turtle Tamer chocolates and two clocks. Prices were
zeroed **only inside that scratch probe** to isolate gross adventure valuation;
no new price estimate is inferred from it. Unchanged installed sources were not
executed against the account. Acquisition/clearing actions that generate no
adventures are irrelevant to this particular yield/reporting check, and this
probe is not a legality or whole-day income simulation.

Native output:

```text
AUDIT range=386-534 average=460.0 adventures-valued-in-profit=449.0 chocolate=6 clocks=5
AUDIT OK; native ASH, no game requests, all prices zeroed solely to isolate gross adventure valuation.
```

`RECORDS.ash total_adventures()` adds the chocolate and clock rewards separately;
`total_profit()` sums only each action's basic value and does not add those
rewards. Consequently the printed profit omits 11 adventures that its yield
line includes. Correcting this reporting omission at the implied 6,500 rate adds
71,500 Meat: (227 + 460) × 6,500 - 615,883 = **3,849,617 Meat**.
This correction does not verify every underlying consumable/helper mechanic.

## A limited comparison using one flat adventure value

Keep each report's quoted cost and reported yield/encounters, replace only the
income valuation with 6,500 Meat per paid encounter:

| Plan | Paid encounters assumed | Quoted cost | Net at flat 6,500 |
| --- | ---: | ---: | ---: |
| CONSUME, all 227 + 460 adventures farmed | 687 | 615,883 | 3,849,617 |
| BARF, reported farming schedule | 687 | 552,187 | 3,913,313 |

BARF is **63,696 Meat ahead in this limited calculation**, exactly the quoted
cost difference. Neither the 135,196 gap against CONSUME's uncorrected output
nor this corrected 63,696 is a fully normalized algorithm-profit result.

The saved read-only `KoLmafia/data/teres-barf-diet-plan.tsv` matches the pasted
BARF schedule. Its consumption rows sum to 465 expected adventures before the
50-adventure Vintage nightcap: 227 + 465 - 687 = 5 left before Vintage. CONSUME's
calculation farms all 227 + 460 adventures and has no corresponding nightcap or
rollover reserve. The apparent equality of 687 paid encounters does not mean
that both plans end in the same state.

## Why a fully matched comparison is still pending

- The CONSUME command list contains no Yeti refresh/double instructions or
  required cold-fashioned, no synthesis, no trainer schedule, and no Vintage
  nightcap/retained-weight/rollover schedule. Its flat rate does not establish
  those bonuses are actually supplied. BARF explicitly schedules them.
- Prices and opportunity-cost conventions differ. Installed CONSUME prices
  distention/dog-hair pills using `2 * ADV_VALUE + half a transponder price`;
  BARF's posted report values the owned untradeable pills at zero. Casserole
  ingredient/crafting costs and stock availability also need a shared policy.
- CONSUME includes useful non-organ adventure items (chocolates, tofu, clocks)
  outside BARF's organ-consumable scan. They are candidates for a separate
  production improvement, not evidence that either current algorithm wins.
- With the pasted start, one shotglass use, and the listed clearers, the 27
  martinis end at 2 + 27 - 1 - 3 - 1 - 9 = 15 drunkenness. That leaves room
  relative to BARF's initial 21-liver limit. The original CONSUME command/organ
  settings and exact starting resources are needed to explain its chosen fill.
- The only full exported state located is the older October 13 fixture. Replaying
  either pasted diet on that state would change adventures, organs, stock,
  resource availability, modifiers and prices. No such replay is presented as
  a same-state comparison. The user was asked whether a matching export exists.

A decisive test needs one matching state export and one common price/crafting
policy. Evaluate the fixed CONSUME quantities plus an explicitly labeled version
adapted to BARF's required policies, using the same full-day income simulator and
replay checks as the practical plan. Preserve the practical planner and all
required constraints until that comparison completes.

Installed CONSUME source SHA-256 values used in this audit:

```text
8718400a7e8185a3891a08dd4567f7904608596798748f7bd4ae723e97f838ee CONSUME.ash
8429775f76d2ed429016a0f22659bb7c774e49e12910ea62dba5db5a3168f5c1 CONSUME/RECORDS.ash
ebcb248d8aa97eff891fe17f5cd2cd7f2d419311a7c3f055bb6a006723b73bf1 CONSUME/HELPERS.ash
```
