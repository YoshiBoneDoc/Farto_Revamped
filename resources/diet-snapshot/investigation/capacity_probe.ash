// Read-only counterfactual schedules. No optimizer or live action is installed.
boolean auditCapacityGroup;
int auditOrderPolicy;
void auditRequire(boolean ok,string message){if(!ok)abort("AUDIT FAILED: "+message);}
barfDietLateMenu auditMenu(){
 barfDietLateMenu m;
 foreach it in $items[body spradium,abstraction: joy]foreach i,e in barfTwoDayItems if(e.target==it){
  m.indices[count(m.indices)]=i;m.fullness+=e.fullness;m.drunkenness+=e.drunkenness;m.spleen+=e.spleen;
 }
 auditRequire(count(m.indices)==2,"both retained items discovered");return m;
}
// AUDIT_RATE_COPY
// AUDIT_SCHEDULE_COPY
void auditResult(string label,barfTwoDayState initial,barfTwoDayState s,int elapsed){
 auditRequire(s.cash>=0&&barfDietMeetsTargets(s)&&barfDietReplay(initial,s),label+" complete replay and requested targets");
 print("AUDIT RESULT "+label+" ms="+elapsed+" encounters="+s.turns+" income="+s.income+" cost="+s.cost+" cash="+s.cash
  +" net="+(s.income-s.cost)+" tomorrow="+barfDietTomorrowValue(s)+" combined="+barfDietScore(s)+" yeti="+s.yetiXP+" chest="+s.chestXP
  +" covered="+s.uses["coolCovered"]+" uncovered="+s.uses["coolUncovered"]+" doubles="+s.uses["yetiDoubles"]+" training="+s.uses["yetiTrainingTurns"]
  +" reserve="+barfDietProjectedStart(s,0)+" pours="+barfDietPourSummary(s));
 string[int] rows=split_string(s.schedule,"\n");foreach i,row in rows print("AUDIT ROW "+label+" "+i+" "+row);
 // Walk every row with the same production transitions; check each organ at each farming interval.
 barfTwoDayState walk=barfDietClone(initial);
 foreach i,row in rows{
  string[int] c=split_string(row,"\t");string action=c[0];
  if(action=="farm"){
   auditRequire(barfDietFarmLegal(walk,c[1].to_int()),"all three organ capacities before farm row "+i);
   print("AUDIT FARM "+label+" row="+i+" turns="+walk.turns+" paid="+c[1]+" mask="+walk.mask+" stooper="+walk.stooper
    +" organs="+walk.fullness+"/"+barfDietFullLimit(walk)+","+walk.drunkenness+"/"+barfDietLiverLimit(walk)+","+walk.spleen+"/"+barfDietSpleenLimit(walk)
    +" rate="+barfDietRate(walk)+" "+auditRateDetails(walk,barfDietStage(walk))+" effects="+barfDietEffectKey(walk,true));
   int stageKey=barfDietStageKey(walk);int trainer=stageKey>=256?256:stageKey>=128?128:0;
   foreach bit in $ints[0,1,2,3,4,5] if(barfDietBit(walk.mask,bit)){
    barfTwoDayState missing=barfDietClone(walk);missing.mask-=(2**bit).to_int();
    if(missing.fullness>barfDietFullLimit(missing)||missing.drunkenness>barfDietLiverLimit(missing)||missing.spleen>barfDietSpleenLimit(missing))
     auditRequire(!barfDietFarmLegal(missing,c[1].to_int()),"removing needed capacity gear must reject farming");
   }
   foreach spot,it in barfPlannedOutfit(walk.mask,barfDietStage(walk).farmer,trainer)
    if($slots[shirt,acc1,acc2,acc3,pants,weapon,off-hand] contains spot)print("AUDIT GEAR "+label+" row="+i+" "+spot+"="+it);
   walk=barfDietFarmState(walk,c[1].to_int());
  }else if(action=="capacity")walk=barfDietCapacityState(walk,c[1].to_int());
  else if(action=="stooper")walk=barfDietStooperState(walk);
  else if(action=="coolReserveRelease")walk.uses["coolSlots"]=walk.uses["coolRefreshes"];
  else if(action=="distill")walk=barfDietDistillState(walk,count(c)>4?c[4].to_int():-1);
  else if(action=="pourSkip")walk=barfDietSkipPour(walk,c[1].to_int());
  else if(action=="extra")walk=barfDietExtraState(walk,to_item(c[1].to_int()));
  else if(action=="resource")walk=barfDietResourceState(walk,c[1]);
  else if(action=="noodleSpleen")walk=barfDietResourceState(walk,"noodleSpleen");
  else if(action=="consume")foreach j,e in barfTwoDayItems if(to_int(e.target)==c[1].to_int()){
   walk=contains_text(c[2],"bare;")?barfDietConsumeBare(walk,e,c[4].to_boolean(),c[3].to_int()):barfDietConsumeState(walk,e,c[4].to_boolean(),c[3].to_int());break;
  }
  else if(action=="nightcap")walk=barfDietFinishState(walk);
  auditRequire(walk.cash>=0&&walk.cash<=my_meat()+walk.liquidIncome,"cash/legality at row "+i);
 }
}
string auditRun(barfTwoDayState initial){
 barfDietQuickDeadline=0;initial.uses["marginalHelpers"]=1;initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=6;initial.uses["pourMidTurn"]=335;
 foreach it in $items[Pete's rich ricotta,baked veggie ricotta casserole]{
  barfTwoDayItem e=checkItem(it);string recipe="";foreach ingredient,n in e.ingredients recipe+=n+" "+ingredient+" @ "+barfDietCurrentPrice(ingredient)+";";
  print("AUDIT FOOD "+it+" size="+e.fullness+" min="+e.minimum+" mean="+e.average+" price="+barfDietCurrentPrice(it)+" stock="+barfDietOwnedAmount(it)+" recipe="+recipe);
 }
 barfDietLateMenu m=auditMenu();boolean latePour=true;float selectedScore=0;
 if(get_property("benchAuditSelectProfile").to_boolean()){
  barfTwoDayState fresh=barfDietClone(initial);
  remove fresh.uses["allCool"];remove fresh.uses["coldRequired"];remove fresh.uses["coolSlots"];
  remove fresh.uses["trainingFood"];remove fresh.uses["marginalHelpers"];remove fresh.uses["pourStages"];remove fresh.uses["pourMidTurn"];
  barfTwoDayState chosen=barfDietQuickPlan(fresh);
  auditRequire(barfDietMeetsTargets(chosen)&&barfDietReplay(fresh,chosen),"fresh practical plan replay and targets: "+barfDietQuickFailure+"; cash="+chosen.cash);
  selectedScore=barfDietScore(chosen);initial=barfDietQuickProfile(fresh,chosen);
  initial.uses["allCool"]=chosen.uses["allCool"];initial.uses["coldRequired"]=chosen.uses["initialColdRequired"];
  initial.uses["initialColdRequired"]=chosen.uses["initialColdRequired"];initial.uses["coolSlots"]=chosen.uses["initialCoolSlots"];initial.uses["initialCoolSlots"]=chosen.uses["initialCoolSlots"];
  barfDietLateMenu actualMenu;m=actualMenu;latePour=false;
  foreach n,row in split_string(chosen.schedule,"\n"){
   string[int] c=split_string(row,"\t");
   if(c[0]=="distill"&&count(c)==4)latePour=true;
   if(c[0]=="consume"&&c[4].to_boolean())foreach i,e in barfTwoDayItems if(to_int(e.target)==c[1].to_int()){
    m.indices[count(m.indices)]=i;m.fullness+=e.fullness;m.drunkenness+=e.drunkenness;m.spleen+=e.spleen;break;
   }
  }
  print("AUDIT PROFILE fresh-practical score="+selectedScore+" latePour="+latePour+" lateItems="+count(m.indices)+" coolSlots="+initial.uses["coolSlots"]);
 }
 barfDietQuickDeadline=0;int started=now_to_int();
 auditCapacityGroup=false;barfTwoDayState incremental=auditSchedule(initial,m,latePour);
 if(selectedScore>0)auditRequire(max(selectedScore-barfDietScore(incremental),barfDietScore(incremental)-selectedScore)<0.01,"fresh policy reconstruction matches selected complete objective");
 auditResult("incremental",initial,incremental,now_to_int()-started);
 started=now_to_int();auditCapacityGroup=true;barfTwoDayState combined=auditSchedule(initial,m,latePour);
 auditResult("combined",initial,combined,now_to_int()-started);
 print("AUDIT DELTA combined-minus-incremental="+(barfDietScore(combined)-barfDietScore(incremental)));
 auditOrderPolicy=1;
 foreach grouped in $booleans[false,true]{
  auditCapacityGroup=grouped;started=now_to_int();barfTwoDayState deferred=auditSchedule(initial,m,latePour);
  auditResult(grouped?"deferred-combined":"deferred-incremental",initial,deferred,now_to_int()-started);
  print("AUDIT DELTA "+(grouped?"deferred-combined":"deferred-incremental")+"-minus-incremental="+(barfDietScore(deferred)-barfDietScore(incremental)));
 }return "OK";
}
