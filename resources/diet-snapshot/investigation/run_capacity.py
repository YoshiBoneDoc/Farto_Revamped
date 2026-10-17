#!/usr/bin/env python3
"""Generate a forced complete-schedule counterfactual in /tmp; never edits production."""
from pathlib import Path
import re, subprocess, argparse, hashlib
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=Path('/private/tmp/diet-capacity-investigation'));p.add_argument('--snapshot',type=Path);p.add_argument('--inactive-stillsuit',action='store_true',help='Explicitly restore one suit omitted with inactive familiar equipment.');a=p.parse_args()
root=Path(__file__).resolve().parents[3];source=(root/'scripts/TeresMimicDiet.ash').read_text()
signature='barfTwoDayState barfDietQuickSchedule(barfTwoDayState initial,barfDietLateMenu menu,boolean distill)'
masked=re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',lambda m:' '*len(m[0]),source,flags=re.S)
start=source.index(signature+'{');end=masked.index('{',start)+1;depth=1
while depth:depth+=(masked[end]=='{')-(masked[end]=='}');end+=1
copy=source[start:end].replace('barfDietQuickSchedule(','auditSchedule(',1)
needle='        s=barfDietCapacityState(s,best);'
assert copy.count(needle)==1
copy=copy.replace(needle,needle+'''
        // Forced alternative: when the normal sequence first adds fullness,
        // also equip the second fullness piece before filling or farming.
        if(auditCapacityGroup&&(best==0||best==1)&&!barfDietBit(s.mask,best==0?1:0)){
            s=barfDietCapacityState(s,best==0?1:0);if(s.cash<0)return s;
        }''',1)
needle='        if(best<0){s.cash=-1;return s;}'
assert copy.count(needle)==1
copy=copy.replace(needle,'''        // Fixed counterfactual order, not an installed search policy.
        if(auditOrderPolicy==1){
            int[int] order={3,0,1,2,5,4};
            foreach n,bit in order if(!barfDietBit(s.mask,bit)){best=bit;break;}
        }
'''+needle,1)
rate_sig='float barfDietRateAtStageUncached(barfTwoDayState s,barfTwoDayStage stage)'
a_rate=source.index(rate_sig+'{');b_rate=masked.index('{',a_rate)+1;depth=1
while depth:depth+=(masked[b_rate]=='{')-(masked[b_rate]=='}');b_rate+=1
rate=source[a_rate:b_rate].replace(rate_sig,'string auditRateDetails(barfTwoDayState s,barfTwoDayStage stage)',1)
rate=rate.replace('float percent=stage.weightPercent;', 'float percent=stage.weightPercent;float items=stage.itemDrop;',1)
rate=rate.replace('percent+=after.weightPercent-before.weightPercent;', 'percent+=after.weightPercent-before.weightPercent;items+=after.itemDrop-before.itemDrop;',1)
rate=rate.replace('percent+=data.weightPercent;', 'percent+=data.weightPercent;items+=data.itemDrop;',1)
rate=rate.replace('return (combats*combat+barfSetting("NoncombatMeat",1750))/(combats+1);', 'return "meatPercent="+(meat+familiarMeat)+" nonfamiliarMeat="+meat+" itemPercent="+items+" familiarWeight="+weight+" weightPercent="+percent+" famGear="+famGear;')
probe=(Path(__file__).parent/'capacity_probe.ash').read_text().replace('// AUDIT_SCHEDULE_COPY',copy).replace('// AUDIT_RATE_COPY',rate)
a.output.mkdir(parents=True,exist_ok=True);f=a.output/'probe.ash';f.write_text(probe)
(a.output/'source.sha256').write_text(hashlib.sha256(source.encode()).hexdigest()+'\n')
command=['python3',str(root/'resources/diet-snapshot/benchmark/run.py'),'--workload','probe','--probe',str(f),'--setting','benchCookingAccess=true','--output',str(a.output)]
if a.snapshot:command+=['--snapshot',str(a.snapshot),'--setting','benchAuditSelectProfile=true','--setting','teresBarfDietPlanSeconds=90']
if a.inactive_stillsuit:command+=['--setting','benchInactiveStillsuit=true']
subprocess.run(command,check=True)
