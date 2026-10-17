#!/usr/bin/env python3
"""Sequential, equal-input native planner matrix. No account/network/game actions."""
from pathlib import Path
import argparse,subprocess,json,re,hashlib
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--budgets',type=int,nargs='+',default=[30,60,90]);p.add_argument('--snapshots',nargs='+',default=['old','fresh']);p.add_argument('--setting',action='append',default=[]);p.add_argument('--reference',type=Path,help='Require identical completed states/schedules to this matrix directory.');a=p.parse_args()
root=Path(__file__).resolve().parents[3];a.output.mkdir(parents=True,exist_ok=True)
source=a.output/'source.ash';source.write_bytes(a.source.read_bytes())
manifest={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source':str(source),'settings':a.setting,'snapshots':a.snapshots,'budgets':a.budgets,'cases':[]}
for snapshot in a.snapshots:
 for budget in a.budgets:
  out=a.output/f'{snapshot}-{budget}'
  cmd=['python3',str(root/'resources/diet-snapshot/benchmark/run.py'),'--source',str(source),'--memory','--workload','practical','--setting','benchCookingAccess=true','--setting','benchValidateTrials=true','--setting',f'teresBarfDietPlanSeconds={budget}','--output',str(out)]
  if a.reference:cmd+=['--reference',str(a.reference/f'{snapshot}-{budget}'/'output.log')]
  if snapshot=='fresh':cmd+=['--snapshot',str(root/'resources/diet-snapshot2'),'--setting','benchInactiveStillsuit=true']
  for setting in a.setting:cmd+=['--setting',setting]
  subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL)
  log=(out/'output.log').read_text();lines=log.splitlines();summary=next(x for x in lines if x.startswith('PRACTICAL ms='))
  rss=re.search(r'NATIVE PEAK_RSS bytes=(\d+)',log,re.M)
  case={'snapshot':snapshot,'budget':budget,'summary':summary,'rss_bytes':int(rss[1]) if rss else None,'validated_trials':next(x for x in lines if x.startswith('VALIDATED COMPLETE TRIALS ')),'results':[re.sub('<[^>]*>','',x) for x in lines if ('Farming: ' in x or 'planning finished in ' in x or 'SEARCH ' in x)],'counters':[x for x in lines if x.startswith('PRACTICAL COUNT ')]}
  for k,v in re.findall(r'(\w+)=([\w.]+)',summary):case[k]=float(v) if k in ('combined','ms','encounters') else v
  manifest['cases'].append(case);(a.output/'results.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(case),flush=True)
