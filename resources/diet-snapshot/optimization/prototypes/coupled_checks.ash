string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();clear(barfDietTrials);clear(barfDietComparisons);
 initial.uses["noExtras"]=1;barfDietLateMenu empty;
 barfDietSearchPhase="coupled-test";barfDietTrialStarted=now_to_int();
 barfDietRecordComparison=false;
 barfTwoDayState pending=barfDietQuickTrial(initial,empty,false,"pending grouped reference");
 requireSame(barfDietMeetsTargets(pending)&&barfDietReplay(initial,pending),"pending complete plan validates");
 requireSame(count(barfDietComparisons)==0,"pending alternative cannot contaminate reference comparison selection");
 barfDietRecordComparison=true;
 barfTwoDayState reference=barfDietQuickTrial(initial,empty,false,"same plan requested by reference");
 sameState(pending,reference,"cached pending plan has identical full state and schedule");
 requireSame(count(barfDietComparisons)==1&&barfDietComparisons contains "helpers allowed","reference can record an exact cache hit originally computed as pending");
 sameState(reference,barfDietComparisons["helpers allowed"],"comparison metadata describes its real winning schedule");
 requireSame(barfDietRecordComparison,"comparison recording restored");
 print("CHECKS COUPLED OK: complete replay, reference isolation, cached pending/reference identity and comparison bookkeeping");return "OK";
}
