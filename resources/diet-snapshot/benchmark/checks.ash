void requireSame(boolean ok,string label){if(!ok)abort("CHECK FAILED: "+label);}
barfTwoDayItem checkItem(item it){foreach i,e in barfTwoDayItems if(e.target==it)return e;abort("Missing fixture item: "+it);return new barfTwoDayItem();}
void sameState(barfTwoDayState a,barfTwoDayState b,string label){
 requireSame(barfDietExactStateKey(a)==barfDietExactStateKey(b)&&a.schedule==b.schedule,label);
}
void forecastCase(barfTwoDayState source,string label){
 int[int] horizons={1,5,25,100,9,19,29,80,6,100};barfTwoDayState[int] reference;
 barfDietShareFarmForecasts=false;
 foreach i,n in horizons reference[i]=barfDietFarmState(source,n);
 clear(barfDietFarmPrefixes);barfDietFarmParentKey="";barfDietShareFarmForecasts=true;
 foreach i,n in horizons sameState(reference[i],barfDietFarmState(source,n),label+" horizon "+n);
 barfTwoDayState mutated=barfDietFarmState(source,25);mutated.effects[to_int($effect[Looking Cool])]=0;
 mutated.uses["trainingSongs"]=99999;mutated.pantsSweat=0;
 sameState(reference[2],barfDietFarmState(source,25),label+" cache immutability");
}
void delayedAdventureChecks(barfTwoDayState initial){
 requireSame(barfDietHasDelayedAdventures($item[ghost pepper])
     &&barfDietHasDelayedAdventures($item[Gets-You-Drunk])
     &&barfDietQualityAllowed($item[ghost pepper])&&barfDietQualityAllowed($item[Gets-You-Drunk]),
  "delayed-adventure foods pass the candidate quality gate");
 int oldRollover=barfTwoDayRollover;
 int[item] oldPrices;boolean[item] oldBuyable;
 barfTwoDayRollover=150;
 foreach it in $items[ghost pepper,Gets-You-Drunk]{
  oldPrices[it]=barfDietPrices[it];oldBuyable[it]=barfDietBuyable[it];
  barfDietPrices[it]=0;barfDietBuyable[it]=true;
  string[int] bounds=split_string(it.adventures,"-");
  int lo=bounds[0].to_int();int hi=count(bounds)>1?bounds[1].to_int():lo;
  barfTwoDayItem entry;entry.target=it;entry.fullness=it.fullness;entry.drunkenness=it.inebriety;
  entry.minimum=lo;entry.average=(lo+hi)/2.0;entry.delayedCombats=4;
  entry.delayedMinimum=lo;entry.delayedAverage=(lo+hi)/2.0;entry.dailyRemaining=1;entry.price=0;
  if(it==$item[Gets-You-Drunk])
   requireSame(entry.drunkenness==2&&entry.minimum+entry.delayedMinimum==16
       &&entry.average+entry.delayedAverage==18&&entry.delayedAverage==9,
    "Gets-You-Drunk models 2 drunkenness and 16-20 total adventures (8-10 immediate, 8-10 delayed)");
  barfTwoDayState source=barfDietClone(initial);source.mask=0;source.stooper=false;
  source.fullness=0;source.drunkenness=0;source.spleen=0;source.turns=0;
  source.adventures=100;source.minimumAdventures=100;source.income=0;source.cost=0;source.cash=1000000;
  source.yetiXP=5000;source.chestXP=2000;source.uses["yetiCharged"]=1;
  source.uses["trainingOverride"]=1;source.uses["chestGoal"]=0;source.uses["yetiGoal"]=0;
  source.uses["forecastMode"]=1;source.uses["allCool"]=0;clear(source.retained);
  barfTwoDayState consumed=barfDietConsumeBare(source,entry,false,0);
  string key=barfDietDelayedAdventureKey(it);
  requireSame(consumed.cash>=0&&consumed.uses[key+":combats"]==4
      &&consumed.adventures>=source.adventures+entry.average
      &&consumed.minimumAdventures>=source.minimumAdventures+entry.minimum,
   it+" records its immediate roll and queues a second roll");
  int due=barfDietTurnsToDelayedAdventure(consumed,it);
  requireSame(due>0&&barfDietForecastCombats(consumed.turns,due-1)<4
      &&barfDietForecastCombats(consumed.turns,due)>=4,
   it+" payout is tied to the fourth modeled combat");
  barfDietResetSearchCaches();
  barfTwoDayState before=barfDietFarmState(consumed,due-1);
  requireSame(before.cash>=0&&before.uses[key+":combats"]>0,
   it+" second roll is not credited before the fourth combat (cash="+before.cash
       +", pending="+before.uses[key+":combats"]+")");
  barfTwoDayState paid=barfDietFarmState(before,1);
  requireSame(paid.cash>=0&&paid.uses[key+":combats"]==0
      &&paid.adventures==before.adventures-1+entry.delayedAverage
      &&paid.minimumAdventures==before.minimumAdventures-1+entry.delayedMinimum,
   it+" credits the delayed 8-10 roll only when the fourth combat occurs");
 }
 foreach it in $items[ghost pepper,Gets-You-Drunk]{
  barfDietPrices[it]=oldPrices[it];barfDietBuyable[it]=oldBuyable[it];
 }
 barfTwoDayRollover=oldRollover;barfDietResetSearchCaches();
 print("DELAYED ADVENTURE CHECKS OK: ghost pepper and Gets-You-Drunk yield their second roll after four modeled combats");
}
string semanticChecks(barfTwoDayState initial){
 barfDietResetSearchCaches();initial.effects[to_int($effect[Looking Cool])]=1000;
 forecastCase(initial,"training and effect boundaries");
 barfTwoDayState normal=barfDietClone(initial);normal.yetiXP=3000;normal.chestXP=1000;normal.uses["yetiCharged"]=1;
 forecastCase(normal,"ordinary block arithmetic");
 barfTwoDayState end=barfDietClone(normal);end.mask=63;end.stooper=true;
 forecastCase(end,"capacity gear and Stooper");
 barfTwoDayState money=barfDietClone(initial);money.cost=0.1234;money.income=1.2345;money.cash=0.2345;
 money.adventures+=0.25;money.minimumAdventures+=0.5;money.sweat+=1;
 money.uses["stock:"+to_int($item[love song of icy revenge])]=barfDietOwnedAmount($item[love song of icy revenge]);
 forecastCase(money,"financial/stock/expected adventures signature");
 barfTwoDayState prefix=barfDietClone(initial);prefix.schedule="phase\tother order\n";
 forecastCase(prefix,"rebased schedule prefix");
 clear(barfDietFarmPrefixes);barfDietFarmParentKey="";barfDietShareFarmForecasts=true;
 barfTwoDayState cachedParent=barfDietFarmState(initial,100);
 barfTwoDayState rebased=barfDietFarmState(prefix,25);barfDietShareFarmForecasts=false;
 sameState(rebased,barfDietFarmState(prefix,25),"reuse across different schedule prefixes");
 barfDietShareFarmForecasts=true;
 // Retention still limits the farming budget even when its effect has expired.
 barfTwoDayState expired=barfDietClone(normal);int id=to_int($effect[Down With Chow]);expired.effects[id]=0;
 expired.retained[id]=false;barfDietResetSearchCaches();float unretained=barfDietScore(expired);
 expired.retained[id]=true;float cached=barfDietScore(expired);barfDietMemoize=false;float uncached=barfDietScore(expired);
 requireSame(cached==uncached&&cached!=unretained,"expired retained flag score cache");
 barfDietResetSearchCaches();barfTwoDayState smart=barfDietClone(normal);smart.finished=true;
 smart.effects[to_int($effect[Smart Drunk])]=1;float absent=barfDietScore(smart);
 smart.retained[to_int($effect[Smart Drunk])]=false;cached=barfDietScore(smart);barfDietMemoize=false;uncached=barfDietScore(smart);
 requireSame(cached==uncached&&cached!=absent,"Smart Drunk retained-key presence");
 barfDietResetSearchCaches();requireSame(count(barfDietFutureCache)==0&&count(barfDietRateCache)==0&&count(barfDietFarmPrefixes)==0,"context reset");
 // Quantity equivalence is valid only after helper/resource assignments are fixed.
 barfTwoDayState q=barfDietClone(normal);q.spork=0;q.aioli=100;q.whet=100;q.milk=0;q.uses["milk"]=1;
 barfTwoDayItem food=checkItem($item[plain calzone]);barfTwoDayItem drink=checkItem($item[iced plum wine]);
 barfTwoDayState a=barfDietConsumeBare(barfDietConsumeBare(q,food,false,0),drink,false,0);
 barfTwoDayState b=barfDietConsumeBare(barfDietConsumeBare(q,drink,false,0),food,false,0);
 requireSame(a.cash>=0&&b.cash>=0&&barfDietExactStateKey(a)==barfDietExactStateKey(b),"quantity-equivalent ordinary fills");
 // Force a one-shot percentage helper to exercise an order-sensitive assignment.
 int oldPrice=barfDietPrices[$item[Ol' Scratch's salad fork]];barfDietPrices[$item[Ol' Scratch's salad fork]]=0;
 q.uses["_saladForkUsed"]=0;barfTwoDayItem other=checkItem($item[jumping horseradish]);
 a=barfDietConsumeState(barfDietConsumeState(q,food,false,0),other,false,0);
 b=barfDietConsumeState(barfDietConsumeState(q,other,false,0),food,false,0);
 requireSame(a.cash>=0&&b.cash>=0&&a.adventures!=b.adventures,"quantity solver must assign one-shot helpers");
 barfDietPrices[$item[Ol' Scratch's salad fork]]=oldPrice;barfDietResetSearchCaches();
 print("CHECKS OK: prefix/expiry/training/rounding, exact keys, stock/cash, cache mutation/reset, quantity equivalence and helper-order counterexample");return "OK";
}
