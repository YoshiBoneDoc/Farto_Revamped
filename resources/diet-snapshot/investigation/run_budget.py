#!/usr/bin/env python3
"""Same frozen inputs and budget; temporary logging only, unchanged search order."""
from pathlib import Path
import re,subprocess,argparse,hashlib
p=argparse.ArgumentParser();p.add_argument('--budgets',type=int,nargs='+',default=[30,60,90]);p.add_argument('--output',type=Path,default=Path('/private/tmp/diet-budget-investigation'));a=p.parse_args()
root=Path(__file__).resolve().parents[3];s=(root/'scripts/TeresMimicDiet.ash').read_text();digest=hashlib.sha256(s.encode()).hexdigest()
def wrap(source,signature,newname,wrapper):
 start=source.index(signature+'{');m=re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',lambda x:' '*len(x[0]),source,flags=re.S);end=m.index('{',start)+1;depth=1
 while depth:depth+=(m[end]=='{')-(m[end]=='}');end+=1
 original=source[start:end];copy=original.replace(signature,newname,1)
 return source[:start]+copy+'\n'+wrapper+'\n'+source[end:]
s=s.replace('import teresBarfSupport.ash;', 'import teresBarfSupport.ash;\nint auditCompleted;int auditCached;int auditBegin;',1)
sig='barfTwoDayState barfDietQuickTrial(barfTwoDayState initial,barfDietLateMenu menu,boolean distill,string label)'
s=wrap(s,sig,sig.replace('barfDietQuickTrial','auditOriginalTrial'),sig+'''{
 int before=now_to_int();int countBefore=barfDietTrialCount;int generated=barfDietFillGenerated;int pruned=barfDietFillBeamPruned;
 boolean expired=barfDietQuickExpired();barfTwoDayState result=auditOriginalTrial(initial,menu,distill,label);
 if(result.cash>=0)auditCompleted+=1;if(barfDietTrialCount==countBefore)auditCached+=1;
 print("AUDIT TRIAL at="+(before-auditBegin)+" ms="+(now_to_int()-before)+" attempted="+(barfDietTrialCount-countBefore)
 +" expiredAtEntry="+expired+" legal="+(result.cash>=0)+" targets="+barfDietMeetsTargets(result)+" generated="+(barfDietFillGenerated-generated)
 +" pruned="+(barfDietFillBeamPruned-pruned)+" label="+label);return result;
}''')
sig='barfDietRankedPair[int] barfDietQuickPairMenus(barfTwoDayState initial,int maximum)'
s=wrap(s,sig,sig.replace('barfDietQuickPairMenus','auditOriginalPairs'),sig+'''{
 int before=now_to_int();boolean expired=barfDietQuickExpired();int generated=barfDietMenuPairsGenerated;
 barfDietRankedPair[int] result=auditOriginalPairs(initial,maximum);
 print("AUDIT PAIRS reached=true at="+(before-auditBegin)+" expiredAtEntry="+expired+" eligible="+(barfDietMenuPairsGenerated-generated)
 +" top="+count(result)+" ms="+(now_to_int()-before));return result;
}''')
s=s.replace('int started=now_to_int();barfDietTrialStarted=started;', 'int started=now_to_int();auditBegin=started;barfDietTrialStarted=started;',1)
for needle,label in [('    if(have_familiar($familiar[Cooler Yeti])){\n        initial.uses["allCool"]','estimate'),('    // Let a better ordinary fill seed','pours'),('    print("Starting diet selected from ','width'),('    barfDietQuickDeadline=deadline;\n    foreach policy','local'),('    foreach label,candidate in barfDietComparisons\n        if(barfDietMeetsTargets(candidate)&&barfDietScore(candidate)>barfDietScore(best))best=candidate;\n    barfDietRankedPair','training')]:
 assert needle in s,needle
 s=s.replace(needle,'    print("AUDIT PHASE '+label+' at="+(now_to_int()-auditBegin));\n'+needle,1)
a.output.mkdir(parents=True,exist_ok=True);src=a.output/'instrumented-source.ash';src.write_text(s);(a.output/'production.sha256').write_text(digest+'\n')
for seconds in a.budgets:
 subprocess.run(['python3',str(root/'resources/diet-snapshot/benchmark/run.py'),'--source',str(src),'--workload','probe','--probe',str(Path(__file__).parent/'budget_probe.ash'),'--setting','benchCookingAccess=true','--setting',f'teresBarfDietPlanSeconds={seconds}','--output',str(a.output/str(seconds))],check=True)
