string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();initial.uses["marginalHelpers"]=1;initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=6;initial.uses["pourMidTurn"]=335;
 barfDietRankedPair[int] pairs=barfDietQuickPairMenus(initial,12);
 barfDietLateMenu[string] seen;barfDietLateMenu first;barfDietLateMenu second;boolean found=false;
 foreach n,pair in pairs{
  barfDietLateMenu menu=barfDietQuickPairMenu(pair);
  string key=menu.fullness+":"+menu.drunkenness+":"+menu.spleen;
  if(seen contains key){first=seen[key];second=menu;found=true;break;}seen[key]=menu;
 }
 requireSame(found,"two distinct retained menus reserve identical organs");
 initial.schedule="phase\tpreserve caller prefix\n";
 barfTwoDayState a=barfDietQuickPreparation(initial,first,true);
 requireSame(a.cash>=0,"first shared preparation completes");
 int hits=barfDietPreparationHits;
 barfTwoDayState b=barfDietQuickPreparation(initial,second,true);
 requireSame(barfDietPreparationHits==hits+1,"different items with identical reserved organs share preparation");
 sameState(a,b,"identity of unconsumed retained items cannot change preparation");
 barfTwoDayState reference=barfDietQuickPrepare(initial,second,true);
 sameState(b,reference,"cached prefix exactly matches independent original transitions");
 string prefix=initial.schedule;initial.schedule="phase\tnew caller prefix\n";
 barfTwoDayState rebased=barfDietQuickPreparation(initial,second,true);
 requireSame(rebased.schedule==initial.schedule+substring(reference.schedule,length(prefix)),"preparation rebases its complete action suffix");
 rebased.uses["cache-test-mutation"]=1;rebased.effects[to_int($effect[Looking Cool])]=999;
 barfTwoDayState isolated=barfDietQuickPreparation(initial,second,true);
 requireSame(barfDietExactStateKey(isolated)==barfDietExactStateKey(reference),"returned prefix cannot mutate its cached source");
 initial.yetiXP+=1;hits=barfDietPreparationHits;
 barfTwoDayState changed=barfDietQuickPreparation(initial,second,true);
 requireSame(barfDietPreparationHits==hits,"different starting XP must not reuse preparation");
 sameState(changed,barfDietQuickPrepare(initial,second,true),"changed XP uses its own native forecast");
 barfDietResetSearchCaches();requireSame(count(barfDietPreparationCache)==0&&barfDietPreparationHits==0,"reset on new snapshot");
 print("CHECKS PREPARATION CACHE OK: different retained menus, complete state/schedule equality, caller rebasing, XP separation and reset");return "OK";
}
