void consumptionLoopChecks(barfTwoDayState initial){
 // Independent reference: explicitly simulate both variants in their original tie order.
 int[item] saved;foreach it in $items[Ol' Scratch's salad fork,Frosty's frosty mug,mini kiwi aioli,whet stone,fudge spork,special seasoning]saved[it]=barfDietPrices[it];
 int matched=0;int distinct=0;int rejected=0;int cases=0;
 for context from 0 to 6{
  barfTwoDayState s=barfDietClone(initial);s.fullness=0;s.drunkenness=0;s.spleen=0;s.yetiXP=3000;s.yetiDouble=true;
  remove s.uses["allCool"];remove s.uses["coldRequired"];
  s.schedule="phase\tkeep this earlier consumption prefix\n";
  foreach it,price in saved barfDietPrices[it]=context==1?0:1000000000;
  if(context==0){s.milk=1;s.aioli=1;s.whet=1;s.effects[to_int($effect[Salty Mouth])]=10;}
  if(context==2){s.mask=63;s.stooper=true;s.effects[to_int($effect[Looking Cool])]=0;s.retained[to_int($effect[Looking Cool])]=true;}
  if(context==3)s.fullness=barfDietFullLimit(s);
  if(context==4)s.cash=my_meat()+s.liquidIncome+1;
  if(context==5){s.uses["allCool"]=1;s.uses["coldRequired"]=1;}
  if(context==6)s.yetiXP=0;
  string sourceKey=barfDietExactStateKey(s);
  foreach i,e in barfTwoDayItems{
   barfTwoDayState overall;overall.cash=-1;float overallScore=-1000000000000.0;
   for yeti from 0 to 2{
   boolean retain=context==2;barfTwoDayState expected;expected.cash=-1;float score=-1000000000000.0;
   foreach bare in $booleans[true,false]{
    barfTwoDayState next=barfDietConsumeState(s,e,retain,yeti,bare);
    if(!bare){if(next.cash<0)rejected+=1;else if(barfDietBareMatches(s,next))matched+=1;else distinct+=1;}
    if(next.cash<0||next.cash>my_meat()+next.liquidIncome)continue;
    float value=barfDietScore(next);if(value>score){expected=next;score=value;}
   }
   barfTwoDayState actual=barfDietQuickConsumeMode(s,e,retain,yeti);
   sameState(expected,actual,"bare/prepared loop: context "+context+", item "+e.target+", Yeti "+yeti);
   requireSame(barfDietScore(expected)==barfDietScore(actual),"bare/prepared score");cases+=1;
   boolean legal=yeti==0||(e.drunkenness>0&&!s.stooper&&have_familiar($familiar[Cooler Yeti])&&s.yetiXP>=(yeti==2?400:225));
   if(yeti==1&&(barfDietDuration(s,$effect[Looking Cool])>=100||s.uses["allCool"]>0))legal=false;
   if(yeti==2&&(s.uses["allCool"]>0||!s.yetiDouble))legal=false;
   if(legal&&expected.cash>=0&&score>overallScore){overall=expected;overallScore=score;}
   }
   sameState(overall,barfDietQuickConsume(s,e,context==2),"Yeti mode guards and tie order");
  }
  requireSame(sourceKey==barfDietExactStateKey(s)&&s.schedule=="phase\tkeep this earlier consumption prefix\n","consumption leaves source unchanged");
 }
 foreach it,price in saved barfDietPrices[it]=price;
 requireSame(matched>0&&distinct>0&&rejected>0,"loop fixtures exercise equal, different and rejected helper outcomes");
 barfDietResetSearchCaches();print("CONSUMPTION LOOP CHECKS OK: "+cases+" exact states/schedules/scores, active helpers, purchases, stock, Yeti, capacity, rejection and cash");
}
void foodExperienceChecks(barfTwoDayState initial){
 boolean available=false;foreach i,e in barfTwoDayItems if(e.target==$item[roasted vegetable focaccia])available=true;
 if(!available){print("FOOD XP CHECKS SKIPPED: roasted vegetable focaccia is absent from the frozen no-cooking candidate fixture");return;}
 barfDietResetSearchCaches();
 barfTwoDayItem food=checkItem($item[roasted vegetable focaccia]);
 requireSame(food.buff==$effect[Feeling Fancy]&&food.duration==50&&barfDietEffect(food.buff).experience==10,"native focaccia XP and duration");
 barfTwoDayState s=barfDietClone(initial);s.mask=0;s.stooper=false;s.earlyJillTurns=0;
 s.fullness=0;s.noodles=0;s.adventures=1000;s.minimumAdventures=1000;s.yetiXP=0;clear(s.retained);
 s.uses["allCool"]=0;s.uses["trainingOverride"]=1;s.uses["chestGoal"]=s.chestXP;s.uses["yetiGoal"]=2000;s.uses["yetiCharged"]=0;
 s.effects[to_int(food.buff)]=0;s.uses["trainingFood"]=to_int(food.target);
 string parent=barfDietExactStateKey(s);
 barfTwoDayState meal=barfDietEarlyTrainingFood(s);
 requireSame(meal.cash>=0&&meal.fullness==food.fullness&&barfDietDuration(meal,food.buff)==50&&meal.cost>s.cost,"early XP meal consumes and prices its real organs/helpers/recipe");
 requireSame(barfDietExactStateKey(s)==parent,"XP meal leaves its source unchanged");
 barfTwoDayState plain=barfDietFarmState(s,100);barfTwoDayState fancy=barfDietFarmState(meal,100);
 requireSame(plain.cash>=0&&fancy.cash>=0&&fancy.uses["yetiTrainingTurns"]<plain.uses["yetiTrainingTurns"]
  &&fancy.uses["trainingSongs"]<plain.uses["trainingSongs"],"focaccia reduces actual simulated training encounters and songs");
 requireSame(barfDietDuration(fancy,food.buff)==0&&fancy.yetiXP>=2000,"effect expires and requested target is still reached");
 barfTwoDayState chest=barfDietClone(s);chest.chestXP=0;chest.uses["chestGoal"]=2000;chest.uses["yetiGoal"]=0;chest.uses["yetiCharged"]=1;
 plain=barfDietFarmState(chest,100);fancy=barfDietFarmState(barfDietEarlyTrainingFood(chest),100);
 requireSame(fancy.chestXP>=2000&&fancy.uses["chestTrainingTurns"]<plain.uses["chestTrainingTurns"]
  &&fancy.uses["trainingSongs"]<plain.uses["trainingSongs"],"food XP also reduces Chest Mimic training and song use");
 // Keep both runs in training past expiry to isolate the exact XP granted.
 s.uses["yetiGoal"]=100000;meal=barfDietEarlyTrainingFood(s);
 plain=barfDietFarmState(s,60);fancy=barfDietFarmState(meal,60);
 int fights=floor(50.0*barfSetting("CombatsBetweenNC",30)/(barfSetting("CombatsBetweenNC",30)+1));
 requireSame(barfDietTrainingSongXP()==5&&plain.uses["trainingSongXP"]-s.uses["trainingSongXP"]
  ==5*(plain.uses["trainingSongs"]-s.uses["trainingSongs"]),"icy revenge grants exactly five extra familiar XP per training combat");
 requireSame(fancy.yetiXP-plain.yetiXP==10*fights,"XP is granted only for combats inside the 50-turn effect, not noncombats or later turns");
 requireSame(barfDietExactStateKey(barfDietEarlyTrainingFood(meal))==barfDietExactStateKey(meal),"do not buy another copy of an already active training effect");
 s.yetiXP=100000;s.uses["yetiCharged"]=1;
 requireSame(!barfDietNeedsTraining(s)&&barfDietExactStateKey(barfDietEarlyTrainingFood(s))==barfDietExactStateKey(s),"unused XP has no value once both training goals are met");
 int savedCold=barfDietPrices[$item[Dreadsylvanian cold-fashioned]];
 barfDietPrices[$item[Dreadsylvanian cold-fashioned]]=500000;
 requireSame(barfDietCurrentPrice($item[Dreadsylvanian cold-fashioned])==100000
  &&checkItem($item[Dreadsylvanian cold-fashioned]).price==100000,"cold-fashioned fixed price overrides cached and candidate values");
 barfDietPrices[$item[Dreadsylvanian cold-fashioned]]=savedCold;barfDietResetSearchCaches();
 print("FOOD XP CHECKS OK: real meal/recipe costs, fewer trainer encounters/songs, exact combat-only XP through expiry, completed goals, parent-state isolation and fixed 100k cold-fashioned");
}

string plannerChecks(barfTwoDayState initial){
 partialFrontierChecks(initial);
 foodExperienceChecks(initial);
 barfDietResetSearchCaches();
 consumptionLoopChecks(initial);
 barfTwoDayState s=barfDietClone(initial);
 set_property("_clocksUsed","0");set_property("_chocolatesUsed","0");set_property("_essentialTofuUsed","false");
 barfTwoDayState one=barfDietExtraState(s,$item[clock]);barfTwoDayState two=barfDietExtraState(one,$item[clock]);
 requireSame(one.cash>=0&&two.cash>=0&&one.adventures==s.adventures+3&&two.adventures==s.adventures+5,"clock 3/2 yields");
 requireSame(barfDietExtraState(two,$item[clock]).cash<0,"clock daily limit");
 requireSame(two.cost==s.cost+2*barfDietCurrentPrice($item[clock])&&two.uses["stock:"+to_int($item[clock])]==2,"clock costs and stock counted once");
 set_property("_clocksUsed","1");one=barfDietExtraState(s,$item[clock]);
 requireSame(one.cash>=0&&one.adventures==s.adventures+2&&barfDietExtraState(one,$item[clock]).cash<0,"partly used clock counter");
 set_property("_clocksUsed","0");
 one=barfDietExtraState(s,$item[essential tofu]);
 requireSame(one.adventures==s.adventures+5&&one.minimumAdventures==s.minimumAdventures+4,"tofu expected/minimum separated");
 requireSame(one.fullness==s.fullness&&one.drunkenness==s.drunkenness&&one.spleen==s.spleen,"extras use no organs");
 requireSame(barfDietExtraState(one,$item[essential tofu]).cash<0,"tofu daily limit");
 set_property("_essentialTofuUsed","true");requireSame(barfDietExtraState(s,$item[essential tofu]).cash<0,"already used tofu");
 set_property("_essentialTofuUsed","false");
 one=barfDietExtraState(s,$item[chocolate turtle totem]);two=barfDietExtraState(one,$item[chocolate turtle totem]);
 barfTwoDayState three=barfDietExtraState(two,$item[chocolate turtle totem]);
 requireSame(three.cash>=0&&three.adventures==s.adventures+6&&barfDietExtraState(three,$item[chocolate turtle totem]).cash<0,"class chocolates 3/2/1 and shared limit");
 barfDietPrices[$item[chocolate seal-clubbing club]]=100;barfDietBuyable[$item[chocolate seal-clubbing club]]=true;
 two=barfDietExtraState(one,$item[chocolate seal-clubbing club]);
 requireSame(two.cash>=0&&two.adventures==one.adventures+1,"off-class chocolate shares the counter");
 set_property("_chocolatesUsed","3");requireSame(barfDietExtraState(s,$item[chocolate turtle totem]).cash<0,"already used chocolate counter");
 requireSame(barfDietExtraState(s,$item[clock]).cash>=0,"clock counter independent of chocolates");set_property("_chocolatesUsed","0");
 barfTwoDayState ended=barfDietClone(s);ended.finished=true;
 requireSame(barfDietExtraState(ended,$item[clock]).cash<0,"no extras after nightcap");
 barfTwoDayState poor=barfDietClone(s);poor.cash=my_meat()+1;
 requireSame(barfDietExtraState(poor,$item[clock]).cash<0,"extras respect liquid cash");
 boolean buyable=barfDietBuyable[$item[clock]];barfDietBuyable[$item[clock]]=false;
 poor=barfDietClone(s);poor.uses["stock:"+to_int($item[clock])]=barfDietOwnedAmount($item[clock]);
 requireSame(barfDietExtraState(poor,$item[clock]).cash<0,"finite extra stock cannot become free purchases");barfDietBuyable[$item[clock]]=buyable;

 // Active short buffs can make a poor helper bundle look attractive at today's immediate rate.
 s.spork=1;s.milk=0;s.aioli=0;s.whet=0;s.uses["milk"]=0;
 float beforeMilk=s.cost;s=barfDietResourceState(s,"milk");
 requireSame(s.cash>=0&&s.cost==beforeMilk+100&&s.milk==1&&s.uses["milk"]==1,"fixed milk at start costs 100");
 barfTwoDayState active=barfDietResourceState(s,"milk");
 requireSame(active.cost==s.cost&&active.schedule==s.schedule,"active milk is not purchased twice");
 barfTwoDayState used=barfDietClone(initial);set_property("_milkOfMagnesiumUsed","true");
 requireSame(barfDietResourceState(used,"milk").cash<0,"already-used milk is not purchased again");set_property("_milkOfMagnesiumUsed","false");
 barfDietPrices[$item[milk of magnesium]]=2000;barfDietPrices[$item[mini kiwi aioli]]=10000;
 barfDietPrices[$item[whet stone]]=5000;barfDietPrices[$item[fudge spork]]=16944;
 barfDietPrices[$item[Ol' Scratch's salad fork]]=1000000000;barfDietPrices[$item[special seasoning]]=1000000000;
 s.uses["stock:"+to_int($item[special seasoning])]=barfDietOwnedAmount($item[special seasoning]);
 boolean calzoneAvailable=false;barfTwoDayItem food;
 foreach i,e in barfTwoDayItems if(e.target==$item[plain calzone]){food=e;calzoneAvailable=true;break;}
 if(calzoneAvailable){
  barfTwoDayState old=barfDietConsumeState(s,food,false,0);s.uses["marginalHelpers"]=1;
  barfTwoDayState marginal=barfDietConsumeState(s,food,false,0);
  requireSame(old.cash>=0&&marginal.cash>=0&&marginal.uses["milk"]==1,"fixed milk survives helper strategy comparisons");
  requireSame(old.milk==0&&marginal.milk==0&&barfDietResourceState(marginal,"milk").cash<0,"milk bonus consumed once");
  requireSame(marginal.cost<old.cost&&barfDietScore(marginal)>barfDietScore(old),"marginal helper bundle improves projected net");
 }else print("MARGINAL HELPER CHECKS SKIPPED: plain calzone is absent from the frozen candidate fixture");

 // One best state per filled amount can lose every exact fill when stock is finite.
 clear(barfTwoDayItems);clear(s.effects);clear(s.retained);clear(s.uses);
 s.fullness=0;s.cost=0;s.cash=0;s.spork=0;s.milk=0;s.aioli=0;s.whet=0;s.uses["milk"]=1;s.uses["forecastMode"]=1;
 s.uses["stock:"+to_int($item[special seasoning])]=barfDietOwnedAmount($item[special seasoning]);
 foreach helper in $items[milk of magnesium,mini kiwi aioli,whet stone,fudge spork,Ol' Scratch's salad fork,special seasoning]barfDietPrices[helper]=1000000000;
 item[int] targets={$item[bag of QWOP],$item[shadow bread],$item[rum-soaked fruitcake]};
 int[int] sizes={1,3,5};int[int] values={11,13,27};int[int] limits={2,2,1};
 foreach i,it in targets{
  barfTwoDayItem e;e.target=it;e.fullness=sizes[i];e.minimum=values[i];e.average=values[i];e.dailyRemaining=limits[i];
  barfDietPrices[it]=0;barfDietBuyable[it]=true;barfTwoDayItems[i]=e;
 }
 barfDietQuickDeadline=0;barfDietResetSearchCaches();barfTwoDayState fill=barfDietQuickFill(s,"food",11,true);
 requireSame(fill.cash>=0&&fill.fullness==11&&fill.adventures==s.adventures+53,"finite-stock exact fill recovered");
 requireSame(fill.uses["fillWidth"]==2&&fill.uses[to_string($item[shadow bread])]==2&&fill.uses[to_string($item[rum-soaked fruitcake])]==1,"retry retains stock-distinct partial fills");
 print("PLANNER CHECKS OK: fixed milk, extra yields/counters/cash/stock, fixture-gated marginal helpers, finite-stock fill recovery");return "OK";
}
