// Uses unchanged production search order and model; logs are injected only in a temporary source copy.
string auditRun(barfTwoDayState initial){
 remove initial.uses["allCool"];remove initial.uses["coldRequired"];remove initial.uses["coolSlots"];
 int begin=now_to_int();barfTwoDayState plan=barfDietQuickPlan(initial);
 if(plan.cash<0||!barfDietMeetsTargets(plan)||!barfDietReplay(initial,plan))abort("Budget investigation failed complete replay/targets.");
 print("AUDIT BUDGET seconds="+get_property("teresBarfDietPlanSeconds")+" ms="+(now_to_int()-begin)+" trials="+barfDietTrialCount
  +" completedCalls="+auditCompleted+" reusedCalls="+auditCached+" generated="+barfDietFillGenerated+" dominated="+barfDietFillDominated
  +" pruned="+barfDietFillBeamPruned+" pairs="+barfDietMenuPairsGenerated+" encounters="+plan.turns+" combined="+barfDietScore(plan));return "OK";
}
