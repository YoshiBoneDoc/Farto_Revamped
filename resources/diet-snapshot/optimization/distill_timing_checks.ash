// Frozen October 17 snapshot: native sweat events and a short post-training pour.
string auditRun(barfTwoDayState initial){
 requireSame(initial.sweat==309&&initial.adventures==221,"use snapshot 3 for the short-pour regression");
 for yield from 3 to 20{
  int sweat=barfDietPourSweatForYield(yield);
  requireSame(sweat>=10&&round(sweat**0.4)>=yield
   &&(sweat==10||round((sweat-1)**0.4)<yield),"minimal integer sweat for yield "+yield);
 }
 barfTwoDayState s=barfDietClone(initial);s.mask=0;s.stooper=false;s.earlyJillTurns=0;
 s.uses["allCool"]=0;s.uses["coldRequired"]=0;s.uses["trainingOverride"]=1;
 s.uses["chestGoal"]=0;s.uses["yetiGoal"]=0;s.uses["yetiCharged"]=1;
 s.chestXP=100000;s.yetiXP=100000;clear(s.retained);
 s.fullness=barfDietFullLimit(s);s.drunkenness=barfDietLiverLimit(s)-1;s.spleen=barfDietSpleenLimit(s);
 s.adventures=1000;s.minimumAdventures=1000;s.sweat=64;
 s.uses["pourStages"]=2;s.uses["pourDone"]=0;s.uses["pourSweat1"]=barfDietPourSweatForYield(9);
 string parent=barfDietExactStateKey(s);
 requireSame(barfDietExactStateKey(barfDietTimedPour(s,1))==parent&&barfDietPourReserve(s,false)==1,
  "training completion leaves a future pour and its liver reservation pending");
 barfTwoDayState small=barfDietDistillState(s,1);
 barfTwoDayState wine=barfDietConsumeBare(barfDietSkipPour(s,1),checkItem($item[Sacramento wine]),false,0);
 requireSame(small.cash>=0&&wine.cash>=0&&small.uses["distillAdventures"]==5
  &&barfDietScore(wine)>barfDietScore(small),"ordinary booze can beat an early five-adventure pour after its real purchase cost");
 int wait=barfDietPourWait(s,1);
 barfTwoDayState before=barfDietFarmState(s,wait-1);barfTwoDayState ready=barfDietFarmState(s,wait);
 requireSame(before.cash>=0&&ready.cash>=0&&before.sweat<s.uses["pourSweat1"]&&ready.sweat>=s.uses["pourSweat1"],
  "event occurs at the first actual combat reaching its sweat threshold");
 requireSame(ready.sweat==s.sweat+barfDietForecastCombats(s.turns,wait),"noncombats grant no inactive-suit sweat");
 barfTwoDayState poured=barfDietTimedPour(ready,1);
 requireSame(poured.cash>=0&&poured.sweat==0&&poured.drunkenness==s.drunkenness+1
  &&poured.adventures-ready.adventures==9&&!barfDietPourPending(poured,1),"actual delayed pour consumes all sweat and one liver");
 barfTwoDayState farmed=barfDietQuickFarm(s);
 requireSame(farmed.cash>=0&&farmed.uses["distillPours"]==1&&farmed.uses["distillAdventures"]==9,
  "production farming splits at the sweat event");
 s.uses["pourSweat1"]=1000000;s.adventures=15;s.minimumAdventures=15;
 barfTwoDayState short=barfDietQuickFarm(s);
 requireSame(short.cash>=0&&short.uses["distillPours"]==0&&barfDietPourPending(short,1),"an unreachable event never invents sweat");
 barfDietLateMenu empty;
 barfTwoDayState released=barfDietQuickPrepareTail(short,empty,false);
 requireSame(released.cash>=0&&!barfDietPourPending(released,1)&&contains_text(released.schedule,"pourSkip\t1\n"),
  "tail releases an unreachable pour reservation");
 barfTwoDayState policy=barfDietClone(initial);policy.uses["pourSweat1"]=211;policy.uses["pourSweat2"]=358;
 requireSame(barfDietQuickProfile(initial,policy).uses["pourSweat2"]==358
  &&barfDietReplayStart(initial,policy).uses["pourSweat1"]==211,"policy and replay preserve sweat thresholds");
 requireSame(barfDietExactStateKey(barfDietTimedPour(ready,1))==barfDietExactStateKey(poured),"source state remains isolated");

 barfDietResetSearchCaches();
 initial.uses["trainingFood"]=to_int($item[roasted vegetable focaccia]);initial.uses["marginalHelpers"]=1;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["coolSlots"]=7;initial.uses["initialCoolSlots"]=7;initial.uses["pourStages"]=3;
 barfDietLateMenu menu;
 foreach it in $items[Amnesiac Ale,abstraction: joy]foreach i,e in barfTwoDayItems if(e.target==it){
  menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;
 }
 barfTwoDayState plan=barfDietQuickSchedule(initial,menu,false);
 requireSame(barfDietMeetsTargets(plan)&&barfDietReplay(initial,plan),"short-pour complete reference validates");
 requireSame(plan.uses["distillPours"]==2&&plan.uses["distillAdventures"]==16&&plan.sweat>500,
  "reference reproduces a small early second pour and unused later sweat");
 parent=barfDietExactStateKey(plan);string meals=substring(plan.schedule,0,index_of(plan.schedule,"farm\t"));
 int start=now_to_int();barfTwoDayState best=barfDietRetimePours(initial,plan);int elapsed=now_to_int()-start;
 requireSame(barfDietMeetsTargets(best)&&barfDietReplay(initial,best),"complete retimed winner satisfies native gameplay constraints");
 requireSame(best.uses["distillPours"]==2&&best.uses["distillAdventures"]==23
  &&barfDietScore(best)>barfDietScore(plan)+2000,"later two-pour plan is substantially more profitable");
 requireSame(starts_with(best.schedule,meals)&&best.uses["chestTrainingTurns"]==plan.uses["chestTrainingTurns"]
  &&best.uses["yetiTrainingTurns"]==plan.uses["yetiTrainingTurns"],"initial meals and trainer encounters are preserved");
 requireSame(best.uses["sweat"]==plan.uses["sweat"],"replayed prefix does not lose its deferred Sweat Out Some Booze");
 requireSame(barfDietExactStateKey(plan)==parent,"refinement leaves its complete fallback unchanged");
 requireSame(barfDietExactStateKey(barfDietRetimePours(initial,best))==barfDietExactStateKey(best),
  "an already independent sweat policy does not repeat the training-coupled refinement");
 print("CHECKS DISTILL TIMING OK: exact thresholds, combat-only sweat, delayed execution/reservation/release, policy/replay, source isolation, preserved training/clearers and complete profitability; before="
  +barfDietScore(plan)+" after="+barfDietScore(best)+" gain="+(barfDietScore(best)-barfDietScore(plan))+" ms="+elapsed+" "+barfDietPourSummary(best));
 return "OK";
}
