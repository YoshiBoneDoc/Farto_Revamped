string auditRun(barfTwoDayState initial){
 initial.uses["noWhet"]=0;
 initial.uses["noSpork"]=0;
 initial.uses["noExtras"]=0;
 initial.uses["fillWidth"]=0;
 initial.uses["marginalHelpers"]=1;
 initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=5;
 initial.uses["pourMidTurn"]=449;
 initial.uses["capacityPolicy"]=0;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["coolSlots"]=6;initial.uses["initialCoolSlots"]=6;
 initial.uses["yetiHighWater"]=max(initial.uses["yetiHighWater"],initial.yetiXP);
 barfDietLateMenu referenceMenu;
 foreach id in $ints[12209,8715,7799]foreach i,e in barfTwoDayItems if(to_int(e.target)==id){referenceMenu.indices[count(referenceMenu.indices)]=i;referenceMenu.fullness+=e.fullness;referenceMenu.drunkenness+=e.drunkenness;referenceMenu.spleen+=e.spleen;}
 barfTwoDayState reference=barfDietQuickSchedule(initial,referenceMenu,false);
 requireSame(barfDietMeetsTargets(reference)&&barfDietReplay(initial,reference),"reconstructed reference validates");
 print("AUDIT RESULT reconstructed=fresh combined="+barfDietScore(reference)+" expected=2472752.07609358");
 requireSame(max(barfDietScore(reference)-2472752.07609358,2472752.07609358-barfDietScore(reference))<0.01,"same exact reference objective before alternative menu comparisons");
 int start=now_to_int();
 barfTwoDayState best=barfDietJointCapacity(initial,reference);
 requireSame(barfDietScore(best)>=barfDietScore(reference)&&barfDietMeetsTargets(best)&&barfDietReplay(initial,best),"joint search preserves fallback and returns legal complete winner");
 print("AUDIT RESULT joint gain="+(barfDietScore(best)-barfDietScore(reference))+" combined="+barfDietScore(best)+" ms="+(now_to_int()-start)+" windows="+barfDietJointWindows+" completed="+barfDietJointCompleted+" valid="+barfDietJointValid+" duplicates="+barfDietJointDuplicates+" expansions="+barfDietQuantityExpanded+" bounded="+barfDietJointBoundPruned+" forecasts="+barfDietJointForecastHits+" permutations="+barfDietQuantityPermutations);
 int[int] oldCounts;int[int] newCounts;
 foreach n,row in split_string(reference.schedule,"\n"){string[int] c=split_string(row,"\t");if(c[0]=="consume")oldCounts[c[1].to_int()]+=1;}
 foreach n,row in split_string(best.schedule,"\n"){string[int] c=split_string(row,"\t");if(c[0]=="consume")newCounts[c[1].to_int()]+=1;}
 foreach id,q in oldCounts if(newCounts[id]!=q)print("AUDIT DELTA "+to_item(id)+" "+q+" -> "+newCounts[id]);
 foreach id,q in newCounts if(!(oldCounts contains id))print("AUDIT DELTA "+to_item(id)+" 0 -> "+q);
 return "OK";
}
