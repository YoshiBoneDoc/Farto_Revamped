void partialFrontierChecks(barfTwoDayState initial){
 delayedAdventureChecks(initial);
 barfTwoDayState dominated=barfDietClone(initial);barfTwoDayState superior=barfDietClone(initial);
 dominated.adventures=10;dominated.minimumAdventures=8;dominated.income=50;dominated.cost=48;dominated.cash=5;dominated.liquidIncome=15;
 superior.adventures=20;superior.minimumAdventures=18;superior.income=100;superior.cost=90;superior.cash=4;superior.liquidIncome=20;
 requireSame(barfDietFillDominates(superior,dominated)&&!barfDietFillDominates(dominated,superior),
 "partial-fill dominance requires no-worse adventures, guaranteed adventures, cash, liquidity and net value");
 barfTwoDayState cashHungry=barfDietClone(superior);cashHungry.cash=10;
 requireSame(!barfDietFillDominates(cashHungry,dominated),"more purchase spending cannot dominate a lower-cash fill");
 barfTwoDayState strategic=barfDietClone(dominated);strategic.uses["stock:123456"]=1;
 requireSame(!barfDietFillDominates(superior,strategic),"different remaining stock state is not dominated");
 // An initially more expensive buff can pay for itself over subsequent farming.
 barfTwoDayState cheap=barfDietClone(initial);cheap.adventures=500;cheap.minimumAdventures=500;
 cheap.earlyJillTurns=0;cheap.uses["allCool"]=0;cheap.uses["coldRequired"]=0;
 cheap.uses["trainingOverride"]=1;cheap.uses["chestGoal"]=cheap.chestXP;
 cheap.uses["yetiGoal"]=cheap.yetiXP;cheap.uses["yetiCharged"]=1;clear(cheap.retained);
 cheap.effects[to_int($effect[Polka of Plenty])]=0;
 barfTwoDayState investment=barfDietClone(cheap);investment.cost+=1000;investment.cash+=1000;
 requireSame(barfDietFillDominates(cheap,investment),"identical future benefits can be compared by their financial requirements");
 investment.effects[to_int($effect[Polka of Plenty])]=50;
 requireSame(!barfDietFillDominates(cheap,investment),"cheaper current cost cannot dominate an additional future Meat buff");
 barfTwoDayState cheapFarm=barfDietFarmState(cheap,50);barfTwoDayState investmentFarm=barfDietFarmState(investment,50);
 requireSame(cheapFarm.cash>=0&&investmentFarm.cash>=0
  &&investmentFarm.income-investmentFarm.cost>cheapFarm.income-cheapFarm.cost,
  "initially expensive buff becomes more profitable after real farming and expiry simulation");
 barfTwoDayState longer=barfDietClone(investment);longer.effects[to_int($effect[Polka of Plenty])]=100;
 requireSame(!barfDietFillDominates(investment,longer),"same buff with longer remaining duration is a distinct future opportunity");
 barfTwoDayState trainingMeal=barfDietClone(cheap);trainingMeal.cost+=1000;trainingMeal.cash+=1000;
 trainingMeal.effects[to_int($effect[Feeling Fancy])]=50;
 requireSame(!barfDietFillDominates(cheap,trainingMeal),"cheaper fill cannot dominate an XP buff with possible future training savings");
 print("FUTURE BENEFIT CHECKS OK: expensive Meat buff repays its cost; buff duration and training XP differences prevent financial dominance");
 print("PARTIAL FRONTIER CHECKS OK: safe resource-equivalent dominance; stock-distinct states preserved");
 barfDietMenuPairsGenerated=0;barfDietRankedPair[int] pairs=barfDietQuickPairMenus(initial,8);
 boolean legal=true;boolean[string] seen;
 foreach i,pair in pairs{
  barfTwoDayItem first=barfTwoDayItems[pair.first];barfTwoDayItem second=barfTwoDayItems[pair.second];
  string key=pair.first+":"+pair.second;
  if(first.buff==second.buff||first.fullness+second.fullness>3||first.drunkenness+second.drunkenness>3
      ||first.spleen+second.spleen>3||(seen contains key))legal=false;
  seen[key]=true;
 }
 requireSame(count(pairs)>0&&barfDietMenuPairsGenerated>0&&legal,"joint retained-buff candidates are distinct-effect, organ-legal combinations");
 print("JOINT BUFF CHECKS OK: "+barfDietMenuPairsGenerated+" legal combinations ranked; "+count(pairs)+" retained for complete-plan comparison");
 string oldDoghair=get_property("_syntheticDogHairPillUsed");string oldMelange=get_property("spiceMelangeUsed");
 int savedDoghair=barfDietPrices[$item[synthetic dog hair pill]];boolean savedDoghairBuyable=barfDietBuyable[$item[synthetic dog hair pill]];
 int savedMelange=barfDietPrices[$item[spice melange]];boolean savedMelangeBuyable=barfDietBuyable[$item[spice melange]];
 int[item] savedPrices;boolean[item] savedBuyable;
 foreach i,e in barfTwoDayItems{
  savedPrices[e.target]=barfDietPrices[e.target];savedBuyable[e.target]=barfDietBuyable[e.target];
  barfDietPrices[e.target]=0;barfDietBuyable[e.target]=true;
 }
 barfDietPrices[$item[synthetic dog hair pill]]=0;barfDietBuyable[$item[synthetic dog hair pill]]=true;
 barfDietPrices[$item[spice melange]]=0;barfDietBuyable[$item[spice melange]]=true;
 set_property("_syntheticDogHairPillUsed","false");set_property("spiceMelangeUsed","false");
 barfTwoDayState partial=barfDietClone(initial);partial.fullness=1;partial.drunkenness=1;partial.spleen=0;
 partial.pantsSweat=0;partial.adventures=0;partial.minimumAdventures=0;partial.income=0;partial.cost=0;partial.cash=0;
 partial.uses["aug16"]=1;barfDietLateMenu empty;barfDietQuickDeadline=0;
 barfTwoDayState reconsidered=barfDietQuickResources(partial,empty,false);
 int doghairAt=index_of(reconsidered.schedule,"resource\tdoghair");int melangeAt=index_of(reconsidered.schedule,"resource\tmelange");
 requireSame(doghairAt>=0&&melangeAt>doghairAt&&reconsidered.uses["melange"]==1,
  "initially unavailable Melange is reconsidered after doghair clears and refill changes organ usage");
 foreach i,e in barfTwoDayItems{barfDietPrices[e.target]=savedPrices[e.target];barfDietBuyable[e.target]=savedBuyable[e.target];}
 barfDietPrices[$item[synthetic dog hair pill]]=savedDoghair;barfDietBuyable[$item[synthetic dog hair pill]]=savedDoghairBuyable;
 barfDietPrices[$item[spice melange]]=savedMelange;barfDietBuyable[$item[spice melange]]=savedMelangeBuyable;
 set_property("_syntheticDogHairPillUsed",oldDoghair);set_property("spiceMelangeUsed",oldMelange);
 barfDietResetSearchCaches();print("CLEARING RETRY CHECKS OK: rejected Melange becomes usable after an intervening clear/refill");
}
