// Paired benchmark source injects the unchanged scoring implementation.
string auditRun(barfTwoDayState initial){
 barfDietLateMenu menu;initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["noExtras"]=0;initial.uses["marginalHelpers"]=1;
 int beforeMs=0;int afterMs=0;barfTwoDayState expected;
 foreach mode in $ints[1,0,0,1]{
  barfDietResetSearchCaches();benchOriginalScores=mode==1;int start=now_to_int();
  barfTwoDayState result=barfDietQuickSchedule(initial,menu,false);
  int elapsed=now_to_int()-start;
  requireSame(barfDietMeetsTargets(result)&&barfDietReplay(initial,result),"paired full schedule validates");
  if(mode==1)beforeMs+=elapsed;else afterMs+=elapsed;
  if(expected.finished)sameState(expected,result,"complete native schedules preserve scores/stock/XP/cash/order");else expected=result;
 }
 print("CHECKS SCORE SCHEDULE OK: four alternating native schedules exact; reference_ms="+beforeMs+" kernel_ms="+afterMs);return "OK";
}
