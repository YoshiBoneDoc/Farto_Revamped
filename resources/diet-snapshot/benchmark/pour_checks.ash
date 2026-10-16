void requireSame(boolean ok,string label);
string pourChecks(barfTwoDayState initial){
 barfDietResetSearchCaches();barfDietQuickDeadline=0;
 barfTwoDayState s=barfDietClone(initial);s.mask=63;s.stooper=true;
 s.adventures=1000;s.minimumAdventures=1000;s.drunkenness=0;s.sweat=275;
 s.uses["allCool"]=0;s.uses["coldRequired"]=0;s.earlyJillTurns=0;clear(s.retained);
 string parent=barfDietExactStateKey(s);
 barfTwoDayState first=barfDietDistillState(s,0);
 requireSame(first.cash>=0&&first.sweat==0&&first.drunkenness==1
  &&first.adventures==s.adventures+round(275**0.4),"pour consumes all sweat and one real liver");
 requireSame(barfDietExactStateKey(s)==parent&&barfDietDistillState(first).cash<0,"source isolated; same sweat cannot fund another pour");
 barfTwoDayState farmed=barfDietFarmState(first,100);
 int combats=barfDietForecastCombats(first.turns,100);
 requireSame(farmed.cash>=0&&farmed.sweat==combats,"only intervening modeled combats replenish inactive-suit sweat");
 barfTwoDayState second=barfDietDistillState(farmed,2);
 requireSame(second.cash>=0&&second.drunkenness==2&&second.sweat==0
  &&second.adventures==farmed.adventures+round(combats**0.4),"second yield uses newly accumulated sweat, not initial sweat");
 requireSame(second.uses["distillPours"]==s.uses["distillPours"]+2
  &&second.uses["distillAdventures"]==round(275**0.4)+round(combats**0.4),"pour quantities and distinct yields tracked");
 barfTwoDayState full=barfDietClone(s);full.drunkenness=barfDietLiverLimit(full);
 requireSame(barfDietDistillState(full).cash<0,"pours cannot borrow nonexistent liver capacity");
 s.uses["pourStages"]=7;s.uses["pourDone"]=0;
 requireSame(barfDietPourReserve(s,true)==4,"three pending pours plus final pour reserve four liver");
 s.sweat=0;barfTwoDayState skipped=barfDietTimedPour(s,0);
 requireSame(skipped.cash>=0&&skipped.drunkenness==s.drunkenness&&barfDietPourReserve(skipped,true)==3
  &&!barfDietPourPending(skipped,0),"unfunded pour releases its slot without inventing sweat or consuming liver");

 // Production schedules must agree with an independent ordered action replay.
 // Different counts and splits compete against the same full candidate menu.
 barfDietLateMenu empty;int[int] masks={0,1,6,7};
 foreach i,mask in masks{
  barfTwoDayState trial=barfDietClone(initial);trial.uses["pourStages"]=mask;
  trial.uses["pourMidTurn"]=initial.turns+250;
  barfTwoDayState plan=barfDietQuickSchedule(trial,empty,i>1);
  requireSame(plan.cash>=0&&barfDietMeetsTargets(plan)&&barfDietReplay(trial,plan),"complete matched schedule/replay for allocation "+mask);
  if(mask==0)requireSame(plan.uses["distillPours"]==0,"ordinary-drink control has no hidden pour");
  if(mask==6)requireSame(plan.uses["distillPours"]>=2,"complete diet actually uses multiple pours");
  int turns=0;boolean sawSplit=false;
  foreach n,row in split_string(plan.schedule,"\n"){
   string[int] c=split_string(row,"\t");
   if(c[0]=="farm")turns+=c[1].to_int();
   if(c[0]=="distill"&&count(c)>4&&c[4]=="2")sawSplit=turns==250;
  }
  if(mask==6)requireSame(sawSplit,"farming block splits at the requested sweat checkpoint");
 }

 // Low current organs do not spend or permanently reject a once-daily clearer.
 set_property("spiceMelangeUsed","false");
 int savedPrice=barfDietPrices[$item[spice melange]];boolean savedBuyable=barfDietBuyable[$item[spice melange]];
 barfDietPrices[$item[spice melange]]=0;barfDietBuyable[$item[spice melange]]=true;
 barfTwoDayState low=barfDietClone(initial);low.fullness=1;low.drunkenness=1;low.spleen=0;
 requireSame(barfDietResourceState(low,"melange").cash<0&&low.uses["melange"]==0,"melange unavailable at 1/1 leaves original resource unused");
 barfTwoDayState filled=barfDietQuickFillStage(low,empty,false);
 requireSame(filled.cash>=0&&filled.fullness>=3&&filled.drunkenness>=3,"real priced consumption fills organs before clearing evaluation");
 barfTwoDayState cleared=barfDietResourceState(filled,"melange");
 requireSame(cleared.cash>=0&&cleared.fullness==filled.fullness-3&&cleared.drunkenness==filled.drunkenness-3
  &&cleared.uses["melange"]==1&&barfDietResourceState(cleared,"melange").cash<0,"full 3/3 benefit and once-daily limit");
 low.uses["clearerDeferred:melange"]=1;filled=barfDietQuickFillStage(low,empty,false);
 barfTwoDayState retried=barfDietQuickResources(filled,empty,false,true);
 requireSame(retried.cash>=0&&retried.uses["melange"]==1&&retried.fullness==filled.fullness
  &&retried.drunkenness==filled.drunkenness,"deferred melange gets a real clear/refill comparison when organs become ready");
 barfDietPrices[$item[spice melange]]=savedPrice;barfDietBuyable[$item[spice melange]]=savedBuyable;
 print("CHECKS POURS OK: actual sweat/yields, multiple pours/liver, skipped reservations, checkpoint splits, complete replay/targets, low-organ melange retry and once-only clearing; no game actions.");
 return "OK";
}
