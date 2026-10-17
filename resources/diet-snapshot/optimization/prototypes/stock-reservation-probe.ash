string auditRun(barfTwoDayState initial){
 initial.uses["marginalHelpers"]=1;initial.uses["trainingFood"]=10990;initial.uses["pourStages"]=6;initial.uses["pourMidTurn"]=335;
 barfDietLateMenu menu;
 foreach it in $items[body spradium,abstraction: joy]foreach i,e in barfTwoDayItems if(e.target==it){menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;}
 barfTwoDayState s=barfDietClone(initial);
 if(get_property("benchReserveProbe")=="true")s=barfDietReserveMenu(s,menu);
 s=barfDietResourceState(s,"milk");s=barfDietEarlyTrainingFood(s);s=barfDietQuickExtras(s);s=barfDietQuickFillStage(s,menu,true);
 for n from 1 to 3{s=barfDietResourceState(s,"mojo");requireSame(s.cash>=0,"three legal mojo actions before refill");}
 s=barfDietQuickFillStage(s,menu,true);requireSame(s.cash>=0,"forced resource refill completes");s.uses["noExtras"]=1;
 print("AUDIT RESULT forced-refill bodyUsed="+s.uses["body spradium"]+" reserved="+s.uses["lateReserve:body spradium"]);
 barfTwoDayState result=barfDietQuickSchedule(s,menu,true);
 boolean valid=barfDietMeetsTargets(result)&&barfDietReplay(initial,result);
 print("AUDIT RESULT stock-reserve="+get_property("benchReserveProbe")+" valid="+valid+" combined="+(valid?barfDietScore(result):0)+" encounters="+result.turns+" failure="+barfDietQuickFailure);
 if(get_property("benchReserveProbe")=="true")requireSame(valid,"stock reservation recovers a complete production-replayed diet");
 return "OK";
}
