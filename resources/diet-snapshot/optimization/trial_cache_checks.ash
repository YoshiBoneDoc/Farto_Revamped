string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();clear(barfDietTrials);barfDietQuickDeadline=0;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["requiredChestXP"]=950;initial.uses["requiredYetiCharge"]=2000;
 initial.uses["pourStages"]=0;initial.uses["pourMidTurn"]=20;
 barfDietLateMenu menu;
 barfTwoDayState first=barfDietQuickTrial(initial,menu,false,"cache reference");
 requireSame(barfDietMeetsTargets(first)&&barfDietReplay(initial,first),"native trial reference validates");
 int attempts=barfDietTrialCount;string parent=barfDietExactStateKey(initial);
 initial.uses["pourMidTurn"]=80;
 barfTwoDayState second=barfDietQuickTrial(initial,menu,false,"inactive middle time");
 requireSame(barfDietTrialCount==attempts&&count(barfDietTrials)==1,"inactive middle target shares completed trial");
 requireSame(second.uses["pourMidTurn"]==80&&first.uses["pourMidTurn"]==20,"caller metadata and cached state remain independent");
 second.uses["pourMidTurn"]=20;sameState(first,second,"identical native schedule, stock, scores, training and cash");
 initial.uses["pourStages"]=4;
 second=barfDietQuickTrial(initial,menu,false,"active middle target");
 requireSame(barfDietTrialCount>attempts&&count(barfDietTrials)>1,"active middle time remains an economically distinct input");
 print("CHECKS TRIAL CACHE OK: inactive-only normalization, exact native winner and metadata isolation; active timing stays distinct");return "OK";
}
