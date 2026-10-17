string auditRun(barfTwoDayState initial){
 initial.uses["noWhet"]=0;
 initial.uses["noSpork"]=0;
 initial.uses["noExtras"]=0;
 initial.uses["fillWidth"]=0;
 initial.uses["marginalHelpers"]=1;
 initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=5;
 initial.uses["pourMidTurn"]=502;
 initial.uses["capacityPolicy"]=15;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["coolSlots"]=7;initial.uses["initialCoolSlots"]=7;
 initial.uses["yetiHighWater"]=max(initial.uses["yetiHighWater"],initial.yetiXP);
 barfDietLateMenu referenceMenu;
 foreach id in $ints[8715,10052]foreach i,e in barfTwoDayItems if(to_int(e.target)==id){referenceMenu.indices[count(referenceMenu.indices)]=i;referenceMenu.fullness+=e.fullness;referenceMenu.drunkenness+=e.drunkenness;referenceMenu.spleen+=e.spleen;}
 barfTwoDayState reference=barfDietQuickSchedule(initial,referenceMenu,true);
 requireSame(barfDietMeetsTargets(reference)&&barfDietReplay(initial,reference),"reconstructed reference validates");
 print("AUDIT RESULT reconstructed=old combined="+barfDietScore(reference)+" expected=2783515.399223725");
 requireSame(max(barfDietScore(reference)-2783515.399223725,2783515.399223725-barfDietScore(reference))<0.01,"same exact reference objective before alternative menu comparisons");
 barfTwoDayState source=barfDietReplayStart(initial,reference);
 foreach n,row in split_string(reference.schedule,"\n"){
  if(row=="stooper")break;
  if(row!="")source=barfDietReplayAction(source,row);
 }
 requireSame(source.mask==63&&!source.stooper&&source.cash>=0,"native source immediately before Stooper");
 barfDietJointForecast[string] cache;
 barfTwoDayState result=barfDietJointContinue(source,referenceMenu,true,-1000000000000.0,cache);
 requireSame(barfDietMeetsTargets(result)&&barfDietReplay(initial,result),"canonical forecast rebased onto real prefix validates");
 barfTwoDayState variant=barfDietClone(source);variant.cost+=100;variant.cash+=100;
 variant.schedule+="phase\tcache caller prefix\n";
 variant.uses[to_string($item[plain calzone])]+=1;variant.uses["stock:"+to_int($item[plain calzone])]+=1;
 int hits=barfDietJointForecastHits;
 barfTwoDayState reused=barfDietJointContinue(variant,referenceMenu,true,-1000000000000.0,cache);
 requireSame(barfDietJointForecastHits==hits+1,"retired meal ledgers and financial offsets reuse a forecast");
 barfTwoDayState expected=barfDietQuickResources(variant,referenceMenu,true,true);
 expected=barfDietQuickFarm(expected,referenceMenu,true);expected=barfDietQuickPrepareTail(expected,referenceMenu,true);expected=barfDietQuickComplete(expected,referenceMenu);
 sameState(expected,reused,"cached and uncached native suffix states and schedules match exactly");
 requireSame(!barfDietRelaxedWallet&&!barfDietTraceCash,"speculative funding overrides restored");
 string base=barfDietExactStateKey(barfDietContinuationState(source,referenceMenu));
 barfDietLateMenu recipe;foreach i,e in barfTwoDayItems if(e.target==$item[plain calzone]){recipe.indices[0]=i;recipe.fullness=e.fullness;}
 requireSame(count(recipe.indices)==1,"shared ingredient test recipe exists");
 variant=barfDietClone(source);variant.uses["stock:"+to_int($item[Yeast of Boris])]+=1;
 requireSame(barfDietExactStateKey(barfDietContinuationState(source,recipe))!=barfDietExactStateKey(barfDietContinuationState(variant,recipe)),"retained recipe protects its raw ingredient stock");
 variant=barfDietClone(source);variant.fullness-=1;
 barfTwoDayState other=barfDietClone(variant);other.uses[to_string($item[plain calzone])]+=1;
 requireSame(barfDietExactStateKey(barfDietContinuationState(variant,referenceMenu))!=barfDietExactStateKey(barfDietContinuationState(other,referenceMenu)),"remaining ordinary space keeps scarce/crafted meals live");
 item wine=$item[Sacramento wine];
 variant=barfDietClone(source);variant.uses["stock:"+to_int(wine)]=barfDietOwnedAmount(wine);variant.uses[to_string(wine)]=0;
 other=barfDietClone(variant);other.uses["stock:"+to_int(wine)]+=1;other.uses[to_string(wine)]+=1;
 requireSame(barfDietExactStateKey(barfDietContinuationState(variant,referenceMenu))==barfDietExactStateKey(barfDietContinuationState(other,referenceMenu)),"exhausted replaceable stock shares the same future when daily headroom is proven");
 other.uses[to_string(wine)]=99;
 requireSame(barfDietExactStateKey(barfDietContinuationState(variant,referenceMenu))!=barfDietExactStateKey(barfDietContinuationState(other,referenceMenu)),"near-exhausted daily limits stay distinct");
 variant=barfDietClone(source);variant.cash=my_meat()+variant.liquidIncome-50;
 barfTwoDayState tight=barfDietJointContinue(variant,referenceMenu,true,-1000000000000.0,cache);
 requireSame(tight.cash<0||!barfDietFundingLegal(tight)||!barfDietMeetsTargets(tight),"cached rich-wallet trace cannot bypass actual liquidity");
 requireSame(!barfDietRelaxedWallet&&!barfDietTraceCash,"funding restored after a tight-wallet failure");
 int pruned=barfDietJointBoundPruned;
 barfTwoDayState omitted=barfDietJointContinue(source,referenceMenu,true,barfDietScore(result)+1,cache);
 requireSame(omitted.cash<0&&barfDietJointBoundPruned==pruned+1,"exact fixed-continuation value skips an inferior branch");
 barfDietResetSearchCaches();requireSame(count(barfDietContinuationLive)==0&&count(barfDietContinuationOwned)==0,"dependency and stock caches reset with snapshot");
 print("CHECKS JOINT CACHE OK: native suffix equivalence, retired stock, shared ingredients, daily headroom, liquidity, fixed-continuation bound and reset");return "OK";
}
