#!/usr/bin/env python3
"""Evaluate explicitly listed clearing/exchange counterfactuals; no installed algorithm changes."""
from pathlib import Path
import re, subprocess, argparse, hashlib
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=Path('/private/tmp/diet-clearing-investigation'));p.add_argument('--bundles',default='');a=p.parse_args()
root=Path(__file__).resolve().parents[3];source=(root/'scripts/TeresMimicDiet.ash').read_text()
signature='barfTwoDayState barfDietQuickSchedule(barfTwoDayState initial,barfDietLateMenu menu,boolean distill)'
m=re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',lambda x:' '*len(x[0]),source,flags=re.S)
start=source.index(signature+'{');end=m.index('{',start)+1;depth=1
while depth:depth+=(m[end]=='{')-(m[end]=='}');end+=1
copy=source[start:end].replace('barfDietQuickSchedule(','auditSchedule(',1)
needle='    s=barfDietQuickResources(s,menu,distill);'
assert copy.count(needle)==1
copy=copy.replace(needle,'    s=auditForcedBundle(s,menu,distill);if(s.cash<0)return s;\n'+needle,1)
copy=copy.replace('barfDietQuickConsume(s,barfTwoDayItems[index],true)', 'auditLateConsume(s,barfTwoDayItems[index])')
copy='\n'.join(line.replace('if(s.cash<0)return s;', 'if(s.cash<0){print("AUDIT FAIL copy-line='+str(n)+' bundle="+auditBundle+" failure="+barfDietQuickFailure);return s;}') for n,line in enumerate(copy.splitlines(),1))
probe=(Path(__file__).parent/'clearing_probe.ash').read_text().replace('// AUDIT_SCHEDULE_COPY',copy)
a.output.mkdir(parents=True,exist_ok=True);f=a.output/'probe.ash';f.write_text(probe);(a.output/'production.sha256').write_text(hashlib.sha256(source.encode()).hexdigest()+'\n')
subprocess.run(['python3',str(root/'resources/diet-snapshot/benchmark/run.py'),'--workload','probe','--probe',str(f),'--setting','benchCookingAccess=true','--setting','benchAuditBundles='+a.bundles,'--output',str(a.output)],check=True)
