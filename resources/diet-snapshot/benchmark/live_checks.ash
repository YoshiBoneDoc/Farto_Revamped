string liveChecks(barfTwoDayState initial){
 barfDietResetSearchCaches();barfDietQuickDeadline=0;
 // Shared gear must agree for every capacity mask and trainer, including Stooper.
 for mask from 0 to 63{
  foreach farmer in $familiars[Jill-of-All-Trades,Stooper]{
   requireSame(barfDietFixedGear(mask,farmer,0),"fixed capacity outfit available");
   foreach spot,it in barfPlannedOutfit(mask,farmer,0)requireSame(it==barfDietSpecGear[spot],"live/forecast gear match");
  }
 }
 foreach trainer in $ints[128,256]{
  familiar farmer=trainer==128?$familiar[Chest Mimic]:$familiar[Cooler Yeti];
  requireSame(barfDietFixedGear(0,farmer,trainer),"training outfit available");
  foreach spot,it in barfPlannedOutfit(0,farmer,trainer)requireSame(it==barfDietSpecGear[spot],"trainer gear match");
 }
 barfTwoDayState poor=barfDietClone(initial);poor.minimumAdventures=poor.adventures=0;
 poor.effects[to_int($effect[Looking Cool])]=100;
 requireSame(!barfLiveCanFarm(poor),"real reserve prevents adventure");
 poor.adventures=poor.minimumAdventures=100;poor.effects[to_int($effect[Looking Cool])]=0;
 requireSame(!barfLiveCanFarm(poor),"no uncovered adventure");
 poor.effects[to_int($effect[Looking Cool])]=100;poor.effects[to_int($effect[Down With Chow])]=5;poor.retained[to_int($effect[Down With Chow])]=true;
 requireSame(!barfLiveCanFarm(poor),"retained five-turn buff is protected");
 // Same-day resume remembers charging once; yesterday's state must not leak.
 set_property("_teresBarfPlanDay",today_to_string());set_property("_teresBarfPlanYetiCharged",true);set_property("_teresBarfPlanYetiHighWater",2500);
 barfTwoDayState resumed=barfDietInitialState();requireSame(resumed.uses["yetiCharged"]==1&&resumed.uses["yetiHighWater"]==2500,"same-day charge resume");
 set_property("_teresBarfPlanDay","yesterday");resumed=barfDietInitialState();requireSame(resumed.uses["yetiCharged"]==0,"new day resets charge history");
 // Real preparation/consumption dispatcher, with recording adapters replacing item use.
 benchLiveActual=barfDietClone(initial);barfLivePolicy=barfDietClone(initial);barfLiveEarlyTurns=initial.earlyJillTurns;
 benchLiveTrace="";
 barfLiveConsume(split_string("consume\t"+to_int($item[plain calzone])+"\taioli;whet;spork;seasoning;\t0\tfalse\t24\t25","\t"));
 requireSame(contains_text(benchLiveTrace,"use:mini kiwi aioli;")&&contains_text(benchLiveTrace,"use:whet stone;")
  &&contains_text(benchLiveTrace,"eat:fudge spork;")&&contains_text(benchLiveTrace,"eat:plain calzone;")
  &&index_of(benchLiveTrace,"eat:fudge spork;")<index_of(benchLiveTrace,"eat:plain calzone;"),"food helpers precede food");
 benchLiveTrace="";
 barfLiveConsume(split_string("consume\t"+to_int($item[iced plum wine])+"\tOde;mafia pinky ring;mug;\t1\tfalse\t7\t7.5","\t"));
 requireSame(contains_text(benchLiveTrace,"ode:1;")&&contains_text(benchLiveTrace,"drink:Frosty's frosty mug;")
  &&contains_text(benchLiveTrace,"yeti:1;")&&contains_text(benchLiveTrace,"drink:iced plum wine;")&&contains_text(benchLiveTrace,"mafia pinky ring"),"Ode, mug, ring and Yeti dispatch");
 int synth=-1;foreach i,e in barfTwoDayItems if(e.special=="synthesis")synth=i;
 requireSame(synth>=0,"synthesis available");barfTwoDayItem saved=barfTwoDayItems[synth];barfTwoDayItem paired=saved;
 int[item] ingredients;foreach part,q in saved.ingredients ingredients[part]=q;
 clear(paired.ingredients);paired.ingredients[$item[PEEZ dispenser]]=2;barfTwoDayItems[synth]=paired;
 benchLiveTrace="";barfLiveConsume(split_string("consume\t0\tbare;\t0\tfalse\t0\t0","\t"));
 requireSame(contains_text(benchLiveTrace,"acquire:PEEZ dispenser:2:")&&contains_text(benchLiveTrace,"synthesis:PEEZ dispenser:PEEZ dispenser;"),"two identical candies acquired together");
 clear(saved.ingredients);foreach part,q in ingredients saved.ingredients[part]=q;barfTwoDayItems[synth]=saved;
 benchLiveTrace="";set_property("_legendaryNoodlesSpleen",false);
 barfLiveConsume(split_string("noodleSpleen\t"+to_int($item[Tubetto Gelatto])+"\taioli;whet;spork;\t0\tfalse\t10\t11","\t"));
 requireSame(contains_text(benchLiveTrace,"noodleChoice:1;")&&contains_text(benchLiveTrace,"use:mini kiwi aioli;")
  &&contains_text(benchLiveTrace,"eat:fudge spork;"),"spleen noodle executes helpers and the correct choice");set_property("_legendaryNoodlesSpleen",false);
 initial.uses["noExtras"]=1;initial.uses["marginalHelpers"]=1;
 barfDietLateMenu menu=barfDietQuickMenu(initial,2);
 barfTwoDayState plan=barfDietQuickSchedule(initial,menu,false);
 requireSame(plan.cash>=0&&barfDietReplay(initial,plan)&&barfDietMeetsTargets(plan),"complete executable starting diet");
 barfTwoDayState pourInitial=barfDietClone(initial);pourInitial.uses["pourStages"]=6;pourInitial.uses["pourMidTurn"]=250;
 barfTwoDayState pourPlan=barfDietQuickSchedule(pourInitial,menu,true);
 requireSame(pourPlan.cash>=0&&barfDietReplay(pourInitial,pourPlan),"multiple-pour live fixture is a complete replayed schedule");
 for scenario from 0 to 3{
  barfTwoDayState scenarioInitial=barfDietClone(initial);barfTwoDayState scenarioPlan=barfDietClone(plan);
  if(scenario==3){
   scenarioInitial=barfDietClone(pourInitial);scenarioPlan=barfDietClone(pourPlan);
  }
  benchLiveActual=barfDietClone(scenarioInitial);benchLiveActual.minimumAdventures=benchLiveActual.adventures;
  benchLiveNightcaps=0;benchLiveActions=0;benchLiveLost=false;benchLiveFree=false;
  barfDietPlannedInitial=barfDietClone(scenarioInitial);barfDietPlanned=barfDietClone(scenarioPlan);barfDietPlanReady=true;
  set_property("_teresBarfPlanDay","yesterday");
  barfDietExecute(scenario==0?5:scenario==2?10000:0);
  if(scenario==0)requireSame(benchLiveActual.turns==5&&benchLiveNightcaps==0&&!benchLiveActual.finished,"paid-turn cap skips final buffs and nightcap, free encounter does not count");
  else if(scenario==1)requireSame(benchLiveActual.finished&&benchLiveNightcaps==1&&benchLiveLost,"low rolls and a lost training fight still finish after checkpoint replanning");
  else if(scenario==2)requireSame(!benchLiveActual.finished&&benchLiveNightcaps==0&&count(barfLiveRetained)==0,"even a large explicit turn limit stops before final consumption");
  else requireSame(benchLiveActual.finished&&benchLiveNightcaps==1&&benchLiveActual.uses["distillPours"]==3
   &&barfLivePourDone==6&&!barfLiveDistill,"low-roll checkpoint replanning preserves three pours and executes each exactly once");
  requireSame(benchLiveActions>0&&benchLiveFree,"driver performed diet actions and handled a free encounter");
 }
 print("LIVE CHECKS OK: 130 shared gear configurations; recorded real consumption dispatch (helpers, Ode, ring, Yeti, identical candy pair); actual reserves/cooling/retention; resume/day reset; simulated full/limited runs, low rolls, free encounter, lost training fight, checkpoint replanning and final-nightcap gating. No game actions.");
 return "OK";
}
