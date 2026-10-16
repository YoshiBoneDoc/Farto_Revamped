int nativeFullLimit;
int nativeLiverLimit;
barfTwoDayState nativeSobriePrediction;

void liveNativeBarfLocation(){
 location original=my_location();barfTwoDayStage[int] expected;
 try{
  foreach duration in $ints[0,1,100]{
   requireSame(cli_execute("dietnativefixture tourist-"+duration),"tourist starting duration");
   foreach destination in $locations[none,Shadow Rift (The Misspelled Cemetary),Barf Mountain]{
    set_location(destination);clear(barfDietEffectCache);clear(barfTwoDayInitialEffects);
    requireSame(barfDietEffect($effect[How to Scam Tourists]).meat==300&&my_location()==destination,"BARF effect context restored");
    barfTwoDayState s=barfDietInitialState();
    requireSame(!(s.effects contains to_int($effect[How to Scam Tourists]))&&s.uses["touristTurns"]==duration,"maintained effect excluded from expiry search");
    foreach trainer in $ints[0,128,256,64]{
     barfTwoDayStage stage=barfDietBuildStage(trainer==64?63:0,trainer==64,trainer==64?0:trainer);
     requireSame(stage.legal&&my_location()==destination,"BARF stage context restored, trainer "+trainer);
     if(duration==0&&destination==$location[none])expected[trainer]=stage;
     barfTwoDayStage reference=expected[trainer];
     requireSame(stage.nonfamiliarMeat==reference.nonfamiliarMeat&&stage.itemDrop==reference.itemDrop
      &&stage.weight==reference.weight&&stage.experience==reference.experience
      &&stage.fullness==reference.fullness&&stage.drunkenness==reference.drunkenness&&stage.spleen==reference.spleen,
      "location/active-tourist invariant stage: "+destination+", duration "+duration+", trainer "+trainer);
    }
   }
  }
  barfTwoDayState s=barfDietInitialState();s.uses["touristTurns"]=1;s.uses["allCool"]=0;
  s.yetiXP=3000;s.chestXP=1000;s.uses["yetiCharged"]=1;s.adventures=1000;s.minimumAdventures=1000;
  s.uses["stock:"+to_int($item[How to Avoid Scams])]=barfDietOwnedAmount($item[How to Avoid Scams]);
  barfDietResetSearchCaches();clear(barfTwoDayStages);
  barfTwoDayState whole=barfDietFarmState(s,41);
  barfTwoDayState split=barfDietFarmState(barfDietFarmState(barfDietFarmState(s,1),20),20);
  requireSame(whole.cost-s.cost==200&&whole.cash-s.cash==200&&whole.uses["touristGuides"]==2&&whole.uses["touristTurns"]==0,"guide quantities, replacement cost and depleted-stock cash");
  requireSame(whole.cost==split.cost&&whole.cash==split.cash&&whole.uses["touristGuides"]==split.uses["touristGuides"]&&whole.uses["touristTurns"]==split.uses["touristTurns"],"guide accounting independent of farm block partition");
  barfDietResetSearchCaches();s.uses["touristTurns"]=1000;float free=barfDietScore(s);s.uses["touristTurns"]=0;
  float cached=barfDietScore(s);barfDietMemoize=false;
  requireSame(cached==barfDietScore(s)&&free>cached,"remaining guide duration belongs in scoring cache key");
  requireSame(cli_execute("dietnativefixture tourist-0"),"live empty tourist buff");
  int stock=item_amount($item[How to Avoid Scams]);barfLiveTouristPrep();
  requireSame(have_effect($effect[How to Scam Tourists])==20&&item_amount($item[How to Avoid Scams])==stock-1,"live refresh uses owned guide");
  barfLiveTouristPrep();requireSame(item_amount($item[How to Avoid Scams])==stock-1,"live active buff skips guide use");
  requireSame(cli_execute("dietnativefixture tourist-1"),"live last buff turn");barfLiveTouristPrep();
  requireSame(have_effect($effect[How to Scam Tourists])==1&&item_amount($item[How to Avoid Scams])==stock-1,"live last active turn is sufficient");
  print("LIVE NATIVE BARF CHECKS OK: 36 location/duration/outfit forecasts, restored location, guide cost/stock/block accounting, scoring cache and live upkeep");
 }finally{set_location(original);barfDietResetSearchCaches();clear(barfTwoDayStages);clear(barfTwoDayInitialEffects);clear(barfDietEffectCache);}
}

string liveNativeSetup(barfTwoDayState initial){
 barfLivePolicy=barfDietClone(initial);barfLiveStarted=total_turns_played();barfLiveEarlyTurns=initial.earlyJillTurns;
 barfLiveHighWater=initial.yetiXP;barfLiveCharged=false;barfLiveCoolSlots=7;clear(barfLiveRetained);
 set_property("_teresBarfPlanDay","");set_property("_teresBarfPlanMask",initial.mask);set_property("_teresBarfPlanStooper",initial.stooper);
 return "OK";
}
string liveNativeWarm(){
 barfTwoDayState source=barfLiveObserveFresh();nativeFullLimit=barfDietFullLimit(source);
 requireSame(nativeFullLimit==fullness_limit(),"native starting capacity");return "OK";
}
string liveNativeCapacity(){
 requireSame(fullness_limit()==nativeFullLimit+1,"native capacity resource increased actual limit");
 barfTwoDayState stale=barfLiveObserve();
 requireSame(barfDietFullLimit(stale)==nativeFullLimit,"regression fixture contains the old cached stage");
 barfTwoDayItem e=checkItem($item[jumping horseradish]);
 requireSame(barfDietConsumeBare(stale,e,false,0).cash<0,"old cached stage rejects an actually legal meal");
 barfTwoDayState fresh=barfLiveObserveFresh();
 requireSame(fresh.uses["extraFullness"]==0&&barfDietFullLimit(fresh)==fullness_limit(),"real observer uses physical capacity without counting the resource twice");
 requireSame(barfDietConsumeBare(fresh,e,false,0).cash>=0,"new capacity accepts the next one-fullness meal");
 barfTwoDayStage poisoned=barfDietStage(fresh);poisoned.legal=false;barfTwoDayStages[barfDietStageKey(fresh)]=poisoned;
 fresh.effects[to_int($effect[Looking Cool])]=1;
 requireSame(barfLiveCanFarm(fresh),"physical adventure guard is independent of stale forecast gear");
 barfLiveObserveFresh();barfDietStage(fresh);
 nativeFullLimit=fullness_limit();return "OK";
}
string liveNativeSobrieBefore(){
 barfTwoDayState source=barfLiveObserveFresh();nativeLiverLimit=barfDietLiverLimit(source);
 barfDietPrices[$item[cuppa Sobrie tea]]=1000;
 nativeSobriePrediction=barfDietResourceState(source,"sobrie");
 requireSame(nativeSobriePrediction.cash>=0&&nativeSobriePrediction.drunkenness==6&&nativeSobriePrediction.uses["extraLiver"]==0,"Sobrie reduces drunkenness without capacity expansion");
 source.drunkenness=0;requireSame(barfDietResourceState(source,"sobrie").cash<0,"no Sobrie benefit at zero drunkenness");return "OK";
}
string liveNativeSobrieAfter(){
 barfTwoDayState actual=barfLiveObserveFresh();
 requireSame(actual.drunkenness==nativeSobriePrediction.drunkenness&&barfDietLiverLimit(actual)==nativeLiverLimit,"Sobrie predicted organs match actual in-memory results");return "OK";
}
string liveNativeFallback(){
 requireSame(available_amount($item[amulet coin])==0&&available_amount($item[tiny stillsuit])>0,"fallback fixture lacks amulet coin");
 item[slot] gear=barfPlannedOutfit(63,$familiar[Stooper],0);
 requireSame(gear[$slot[familiar]]==barfDietProjectedFamiliarGear($familiar[Stooper],0)&&gear[$slot[familiar]]==$item[tiny stillsuit],"runtime and forecast both use the available familiar equipment");return "OK";
}
string liveNativeNoodle(){
 barfTwoDayState source=barfLiveObserveFresh();source.milk=0;source.aioli=0;source.whet=0;source.spork=1;source.uses["noSpork"]=0;
 source.uses["stock:"+to_int($item[special seasoning])]=barfDietOwnedAmount($item[special seasoning]);
 set_property("_legendaryNoodlesSpleen",false);barfDietPrices[$item[Tubetto Gelatto]]=1000;barfDietBuyable[$item[Tubetto Gelatto]]=true;
 foreach it in $items[mini kiwi aioli,whet stone,fudge spork]barfDietPrices[it]=1;
 barfDietPrices[$item[Ol' Scratch's salad fork]]=1000000000;barfDietPrices[$item[special seasoning]]=1000000000;
 barfTwoDayState noodle=barfDietResourceState(source,"noodleSpleen");
 requireSame(noodle.cash>=0&&noodle.fullness==source.fullness&&noodle.spleen==source.spleen+1,"spleen noodle resource can actually be scheduled");
 requireSame(noodle.cost-source.cost==1003&&contains_text(noodle.schedule,"aioli;whet;spork;"),"spleen noodle keeps and prices its meal preparations");
 string[int] cells=split_string(replace_string(noodle.schedule,"\n",""),"\t");
 requireSame(count(cells)==7&&cells[0]=="noodleSpleen","spleen noodle retains the complete consumption row");
 requireSame(barfDietResourceState(noodle,"noodleSpleen").cash<0,"spleen noodle daily limit");
 source.fullness=barfDietFullLimit(source);requireSame(barfDietResourceState(source,"noodleSpleen").cash<0,"gross fullness must fit before the noodle refund");return "OK";
}
string liveNativeReservedNoodle(){
 barfTwoDayState source=barfLiveObserveFresh();source.mask=63;source.stooper=true;source.yetiDouble=false;source.yetiXP=0;source.uses["allCool"]=0;source.uses["coldRequired"]=0;
 foreach action in $strings[sweat,mojo]source.uses[action]=3;
 foreach action in $strings[aug16,melange,doghair,distention,sweettooth,voraci,sobrie]source.uses[action]=1;
 source.fullness=barfDietFullLimit(source)-2;source.drunkenness=barfDietLiverLimit(source);source.spleen=barfDietSpleenLimit(source)-1;
 barfDietLateMenu menu;menu.fullness=2;menu.spleen=1;
 barfTwoDayState result=barfDietQuickResources(source,menu,false);
 requireSame(result.cash>=0&&result.spleen==source.spleen&&result.schedule==source.schedule,"spleen noodle cannot consume the reserved late-menu slot");return "OK";
}

void liveNativeTouristBanishes(){
 location saved=my_location();
 try{
  set_location($location[Barf Mountain]);set_property("_teresBarfMode","");
  foreach target in $monsters[angry tourist,horrible tourist family]
   requireSame(contains_text(target.attributes,"NOBANISH"),"native tourist immunity: "+target);
  requireSame(cli_execute("dietnativefixture barf-ban-check"),"native banish rejection fixture");
  requireSame(!is_banished($monster[angry tourist])&&!is_banished($monster[horrible tourist family]),"native Mafia rejects both tourist banish sources");
  set_property("spookyVHSTapeMonster","garbage tourist");set_property("spookyVHSTapeMonsterTurn",total_turns_played()-8);
  set_property("screechCombats",100);set_property("_teresBarfPlanYetiCharged",false);
  requireSame(cli_execute("dietnativefixture barf-yeti-low"),"Yeti shortfall");
  foreach planned in $booleans[false,true]{
   set_property("_teresBarfPlannedExecution",planned);
   requireSame(barfVhsDue()&&barfChooseFamiliar()==$familiar[Cooler Yeti],"VHS trains Yeti instead of recharging eagle");
  }
  requireSame(cli_execute("dietnativefixture barf-yeti-high"),"Yeti charged");
  requireSame(barfChooseFamiliar()==$familiar[Stocking Mimic],"VHS uses Stocking Mimic after Yeti goal");
  requireSame(cli_execute("dietnativefixture barf-yeti-low"),"spent Yeti XP after charging");set_property("_teresBarfPlanYetiCharged",true);
  requireSame(barfVhsFamiliar()==$familiar[Stocking Mimic],"do not repeatedly refill already charged Yeti");
  print("LIVE NATIVE TOURIST CHECKS OK: both tourists reject Sea *dent/Spring Kick; Yeti/Stocking VHS priority replaces eagle recharge");
 }finally{set_location(saved);}
}
string liveNativeChecks(barfTwoDayState initial){
 liveNativeBarfLocation();
 liveNativeSetup(initial);requireSame(cli_execute("dietnativefixture reset-capacity"),"reset physical capacity flags");liveNativeWarm();
 foreach pref in $strings[_distentionPillUsed,_sweetToothUsed,_voraciTeaUsed]{
  requireSame(cli_execute("dietnativefixture "+pref),"simulate physical capacity use");liveNativeCapacity();
 }
 requireSame(cli_execute("dietnativefixture sobrie-before"),"Sobrie starting state");liveNativeSobrieBefore();
 requireSame(cli_execute("dietnativefixture sobrie-after"),"Sobrie physical result");liveNativeSobrieAfter();
 liveNativeNoodle();
 liveNativeReservedNoodle();
 set_property("_teresBarfPlannedExecution",true);set_property("_teresBarfPlanMinimumAdventures",5);
 foreach condition in $strings[guard-ready,guard-at-reserve,guard-expired-cool,guard-last-retained,guard-ready-retained]{
  requireSame(cli_execute("dietnativefixture "+condition),"physical hook guard setup");
  requireSame(barfPlannedAdventureAllowed()==(condition=="guard-ready"||condition=="guard-ready-retained"),"last-minute adventure hook guard: "+condition);
 }
 set_property("_teresBarfPlannedExecution",false);
 requireSame(cli_execute("dietnativefixture loss-state"),"resolved loss fixture");
 requireSame(barfLiveCompletedLoss(true,"same",19),"consecutive losses sharing Mafia's second-resolution timestamp");
 requireSame(barfLiveCompletedLoss(false,"same",20)&&barfLiveCompletedLoss(true,"older",20),"newly completed free lost fight needs no paid progress");
 requireSame(!barfLiveCompletedLoss(true,"same",20),"unchanged old loss is not a new fight");
 requireSame(cli_execute("dietnativefixture loss-noncombat"),"stale loss during a noncombat");
 requireSame(!barfLiveCompletedLoss(true,"same",19),"old loss flag does not hide a noncombat failure");
 string mood=get_property("currentMood");barfLiveMood("offline audit 7");barfLiveMood("apathetic");barfLiveMood("offline audit 7");
 requireSame(get_property("currentMood")=="offline audit 7","native mood restoration without execution");barfLiveMood(mood);
 requireSame(cli_execute("dietnativefixture no-coin"),"remove optional familiar gear");liveNativeFallback();
 liveNativeTouristBanishes();
 print("LIVE NATIVE CHECKS OK: real observer/cache invalidation after three capacity changes, Sobrie organ result, missing-coin fallback, last-minute hook reserves/cooling/retention, consecutive/free losses and mood restoration; no game requests.");return "OK";
}
