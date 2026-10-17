boolean[string] quantityKeys(barfTwoDayState[int] states){boolean[string] keys;foreach i,s in states keys[barfDietExactStateKey(s)]=true;return keys;}
void quantityEquality(barfTwoDayState source,string organ,int target,string label){
 barfDietQuantityExpanded=0;barfDietQuantityDuplicates=0;barfDietQuantityPermutations=0;
 int started=now_to_int();barfTwoDayState[int] exhaustive=barfDietQuantityFills(source,organ,target,false);
 int before=barfDietQuantityExpanded;int beforeMs=now_to_int()-started;
 barfDietQuantityExpanded=0;barfDietQuantityDuplicates=0;barfDietQuantityPermutations=0;
 started=now_to_int();barfTwoDayState[int] canonical=barfDietQuantityFills(source,organ,target,true);
 boolean[string] expected=quantityKeys(exhaustive);boolean[string] actual=quantityKeys(canonical);
 requireSame(count(expected)>0&&count(expected)==count(actual),label+" exact outcome count");
 foreach key,value in expected requireSame(actual contains key,label+" every exhaustive outcome retained");
 print("QUANTITY CASE "+label+" outcomes="+count(actual)+" expanded="+before+" -> "+barfDietQuantityExpanded+" skipped="+barfDietQuantityPermutations+" ms="+beforeMs+" -> "+(now_to_int()-started));
}
string auditRun(barfTwoDayState initial){
 barfTwoDayItem[int] saved;foreach i,e in barfTwoDayItems saved[i]=e;
 barfTwoDayItem a=checkItem($item[jumping horseradish]);barfTwoDayItem b=checkItem($item[Affirmation Cookie]);
 // Controlled native items keep the real yield/stock/consumption paths, with a tiny finite menu.
 clear(barfTwoDayItems);a.dailyRemaining=4;a.buff=$effect[none];b.dailyRemaining=1;barfTwoDayItems[0]=a;barfTwoDayItems[1]=b;
 barfTwoDayState source=barfDietClone(initial);source.fullness=0;source.milk=0;source.aioli=0;source.whet=0;source.noodles=0;source.shotglass=0;
 source.uses["noWhet"]=1;source.uses["noSpork"]=1;source.spork=0;source.uses["munchies"]=get_property("munchiesPillsUsed").to_int();
 source.uses["stock:"+to_int($item[special seasoning])]=barfDietOwnedAmount($item[special seasoning]);
 barfTwoDayState original=barfDietClone(source);
 int[item] helperPrices;
 foreach it in $items[special seasoning,mini kiwi aioli,whet stone,fudge spork,Ol' Scratch's salad fork]{helperPrices[it]=barfDietPrices[it];barfDietPrices[it]=-1;}
 quantityEquality(source,"food",4,"neutral quantities with daily stock");
 foreach it,price in helperPrices barfDietPrices[it]=price;
 requireSame(barfDietQuantityPermutations>0,"neutral order permutations skipped before simulation");
 sameState(source,original,"frontier leaves its caller unchanged");
 barfTwoDayItem breakfast;breakfast.target=$item[spaghetti breakfast];breakfast.fullness=1;
 requireSame(!barfDietQuantityNeutral(original,breakfast),"empty-stomach breakfast cannot be reordered");
 source.milk=1;source.aioli=1;source.whet=1;source.noodles=1;source.spork=1;source.uses["noSpork"]=0;
 quantityEquality(source,"food",3,"existing one-shot helpers retain order-sensitive outcomes");
 source=barfDietClone(original);barfTwoDayItems[0].buff=$effect[Down With Chow];barfTwoDayItems[0].duration=10;
 quantityEquality(source,"food",3,"retained-relevant effects remain explicit");
 clear(barfTwoDayItems);foreach i,e in saved barfTwoDayItems[i]=e;
 barfTwoDayItem drink=checkItem($item[Sacramento wine]);clear(barfTwoDayItems);barfTwoDayItems[0]=drink;
 source=barfDietClone(original);source.drunkenness=0;source.shotglass=1;
 quantityEquality(source,"booze",2,"shotglass zero-organ transition");
 foreach i,s in barfDietQuantityFills(source,"booze",2,true)requireSame(s.shotglass==0&&s.uses[to_string(drink.target)]==3,"shotglass counts three drinks into two liver");
 clear(barfTwoDayItems);foreach i,e in saved barfTwoDayItems[i]=e;
 print("CHECKS QUANTITY OK: exhaustive outcome equivalence, canonical neutral quantities, daily stock, helpers/effects, shotglass and caller isolation");return "OK";
}
