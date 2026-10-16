void requireSame(boolean ok,string label);
void ingredientPriceReset(){
 clear(barfDietRecipePrices);clear(barfDietPricingRecipe);
 foreach it in $items[Boris's bread,Pete's rich ricotta,roasted vegetable of Jarlsberg,plain calzone,baked veggie ricotta casserole,shadow martini]
  remove barfDietPrices[it];
 barfDietResetSearchCaches();
}

string ingredientChecks(barfTwoDayState initial){
 // Deliberately different raw prices expose the old zero-cost tie between these meals.
 barfDietPrices[$item[Yeast of Boris]]=7300;
 barfDietPrices[$item[Vegetable of Jarlsberg]]=1300;
 barfDietPrices[$item[St. Sneaky Pete's Whey]]=1300;
 barfDietPrices[$item[shadow glass]]=1000;barfDietPrices[$item[shadow ice]]=2000;barfDietPrices[$item[shadow nectar]]=3000;
 foreach it in $items[Yeast of Boris,Vegetable of Jarlsberg,St. Sneaky Pete's Whey,shadow glass,shadow ice,shadow nectar]barfDietBuyable[it]=true;
 barfDietStashStock[$item[plain calzone]]+=1;barfDietStashStock[$item[baked veggie ricotta casserole]]+=1;barfDietStashStock[$item[shadow martini]]+=1;
 ingredientPriceReset();
 requireSame(barfDietCurrentPrice($item[Boris's bread])==14600,"bread includes two yeast");
 requireSame(barfDietCurrentPrice($item[Pete's rich ricotta])==2600,"ricotta includes two whey");
 requireSame(barfDietCurrentPrice($item[plain calzone])==17200,"owned calzone includes nested yeast and whey");
 requireSame(barfDietCurrentPrice($item[baked veggie ricotta casserole])==5200,"owned casserole includes nested vegetables and whey");
 requireSame(barfDietCurrentPrice($item[shadow martini])==6000,"owned martini includes all three Forge ingredients");
 requireSame(!barfDietCanCraft($item[shadow martini]),"Forge is valued without assuming acquisition access");
 foreach it in $items[bowl of cottage cheese,flat dough,spices,magicalness-in-a-can,strawberry,wad of dough]{barfDietPrices[it]=100;barfDietBuyable[it]=true;}
 int[item] cookbookExpected={
  $item[Boris's beer]:7400,$item[honey bun of Boris]:7400,$item[ratatouille de Jarlsberg]:1400,
  $item[Jarlsberg's vegetable soup]:1400,$item[St. Pete's sneaky smoothie]:1400,$item[Pete's wiley whey bar]:1400,
  $item[Boris's bread]:14600,$item[roasted vegetable of Jarlsberg]:2600,$item[Pete's rich ricotta]:2600,
  $item[baked veggie ricotta casserole]:5200,$item[plain calzone]:17200,$item[roasted vegetable focaccia]:17200,
  $item[Deep Dish of Legend]:19800,$item[Calzone of Legend]:19800,$item[Pizza of Legend]:19800};
 clear(barfDietRecipePrices);foreach it in cookbookExpected remove barfDietPrices[it];
 foreach it,expected in cookbookExpected requireSame(barfDietCurrentPrice(it)==expected,"Cookbookbat recipe cost: "+it);
 barfDietBuildItems();
 barfTwoDayItem calzone=barfDietCandidateDetails[$item[plain calzone]];
 barfTwoDayItem casserole=barfDietCandidateDetails[$item[baked veggie ricotta casserole]];
 barfTwoDayItem martini=barfDietCandidateDetails[$item[shadow martini]];
 requireSame(calzone.price==17200&&casserole.price==5200&&martini.price==6000,"candidate ranking receives ingredient values");
 requireSame(calzone.crafted&&casserole.crafted,"basic COOK recipes can supply missing meals");
 requireSame(!(barfDietCandidateDetails contains $item[shadow hot dog])&&!(barfDietCandidateDetails contains $item[shadow pill]),"other Forge consumables stay excluded");
 foreach it in $items[Deep Dish of Legend,Calzone of Legend,Pizza of Legend]
  requireSame(barfDietCandidateStatus[it]=="No remaining daily uses or stock","used lifetime food stays unavailable: "+it);
 barfTwoDayState s=barfDietClone(initial);s.fullness=0;s.drunkenness=0;s.spleen=0;s.cost=0;s.cash=0;s.uses["allCool"]=0;
 barfTwoDayState a=barfDietConsumeState(s,calzone,false,0,true);
 barfTwoDayState b=barfDietConsumeState(s,casserole,false,0,true);
 requireSame(a.cash==0&&b.cash==0&&a.cost==17200&&b.cost==5200,"owned meals have opportunity cost but no purchase cost");
 requireSame(a.uses["stock:"+to_int($item[Yeast of Boris])]==0&&b.uses["stock:"+to_int($item[Vegetable of Jarlsberg])]==0,"owned meals do not also spend raw ingredients");
 // Exhaust finished meals/intermediates and raw stock to require actual cash purchases.
 foreach it in $items[plain calzone,baked veggie ricotta casserole,Boris's bread,Pete's rich ricotta,roasted vegetable of Jarlsberg,Yeast of Boris,Vegetable of Jarlsberg,St. Sneaky Pete's Whey]
  s.uses["stock:"+to_int(it)]=barfDietOwnedAmount(it);
 a=barfDietConsumeState(s,calzone,false,0,true);b=barfDietConsumeState(s,casserole,false,0,true);
 requireSame(a.cash==17200&&b.cash==5200&&a.cost==17200&&b.cost==5200,"missing meals buy nested raw ingredients exactly once");
 requireSame(a.uses["stock:"+to_int($item[Yeast of Boris])]==s.uses["stock:"+to_int($item[Yeast of Boris])]+2,"calzone spends two raw yeast");
 // A single owned ricotta cannot fund both a calzone and a casserole when whey is unavailable.
 barfDietBuyable[$item[St. Sneaky Pete's Whey]]=false;
 s.uses["stock:"+to_int($item[Pete's rich ricotta])]=barfDietOwnedAmount($item[Pete's rich ricotta])-1;
 a=barfDietConsumeState(s,calzone,false,0,true);
 requireSame(a.cash==14600,"owned intermediate avoids a second ingredient purchase");
 b=barfDietConsumeState(a,casserole,false,0,true);
 requireSame(b.cash<0,"shared intermediate stock cannot be spent twice");
 requireSame(s.uses["stock:"+to_int($item[Pete's rich ricotta])]==barfDietOwnedAmount($item[Pete's rich ricotta])-1,"candidate evaluation preserves parent stock");
 barfDietPrices[$item[Yeast of Boris]]=-1;ingredientPriceReset();
 requireSame(barfDietCurrentPrice($item[plain calzone])<0,"unknown recipe cost never becomes a free owned meal");
 liveIngredientChecks();
 print("INGREDIENT CHECKS OK: all 15 Cookbookbat recipes and lifetime limits, nested prices, owned meals, raw purchases, shared stock, parent-state isolation, unknown prices, martini valuation and real live acquisition routing with recording adapters.");
 return "OK";
}
