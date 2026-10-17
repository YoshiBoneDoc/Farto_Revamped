string auditRun(barfTwoDayState initial){
 initial.uses["noWhet"]=0;
 initial.uses["noSpork"]=0;
 initial.uses["noExtras"]=0;
 initial.uses["fillWidth"]=0;
 initial.uses["marginalHelpers"]=1;
 initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=5;
 initial.uses["pourMidTurn"]=502;
 initial.uses["capacityPolicy"]=15;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["coolSlots"]=7;initial.uses["initialCoolSlots"]=7;
 initial.uses["yetiHighWater"]=max(initial.uses["yetiHighWater"],initial.yetiXP);
 barfDietLateMenu referenceMenu;
 foreach id in $ints[8715,10052]foreach i,e in barfTwoDayItems if(to_int(e.target)==id){referenceMenu.indices[count(referenceMenu.indices)]=i;referenceMenu.fullness+=e.fullness;referenceMenu.drunkenness+=e.drunkenness;referenceMenu.spleen+=e.spleen;}
 barfTwoDayState reference=barfDietQuickSchedule(initial,referenceMenu,true);
 requireSame(barfDietMeetsTargets(reference)&&barfDietReplay(initial,reference),"reconstructed reference validates");
 print("AUDIT RESULT reconstructed=old combined="+barfDietScore(reference)+" expected=2783515.399223725");
 requireSame(max(barfDietScore(reference)-2783515.399223725,2783515.399223725-barfDietScore(reference))<0.01,"same exact reference objective before alternative menu comparisons");
 barfDietRankedPair[int] pairs=barfDietQuickPairMenus(initial,12);barfDietRankedPair[string] seeds;
 foreach n,pair in pairs{
  barfDietLateMenu m=barfDietQuickPairMenu(pair);string shape=(m.fullness>0?"F":"")+(m.drunkenness>0?"D":"")+(m.spleen>0?"S":"");
  if(!(seeds contains shape)||pair.estimate>seeds[shape].estimate)seeds[shape]=pair;
 }
 float best=barfDietScore(reference);int start=now_to_int();
 foreach shape,pair in seeds{
  barfDietLateMenu m=barfDietQuickPairMenu(pair);barfTwoDayState trial=barfDietQuickProfile(initial,reference);trial.uses["capacityPolicy"]=15;
  foreach distill in $booleans[true,false]{
   barfTwoDayState result=barfDietQuickSchedule(trial,m,distill);
   boolean valid=barfDietMeetsTargets(result)&&barfDietReplay(initial,result);
   if(valid)best=max(best,barfDietScore(result));
   print("AUDIT RESULT menu-shape="+shape+" pour="+distill+" valid="+valid+" combined="+(valid?barfDietScore(result):0));
  }
 }
 print("AUDIT RESULT coupled-portfolio gain="+(best-barfDietScore(reference))+" ms="+(now_to_int()-start));return "OK";
}
