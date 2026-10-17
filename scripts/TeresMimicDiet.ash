import teresBarfSupport.ash;

// One practical planner remains. Legacy optimizer comments are preserved below;
// implementations are recoverable from checkpoint 6b679da and documented in docs/DIET_OPTIMIZER_AUDIT.md.

int[item] barfDietStashStock;
int barfDietOwnedAmount(item it){
    return item_amount(it)+closet_amount(it)+storage_amount(it)+barfDietStashStock[it];
}

boolean barfDietReadStash(){
    clear(barfDietStashStock);
    string original=get_clan_name();
    string stash=get_property("teresBarfStashClan");if(stash=="")stash="Soup Clan";
    if(original==""){print("Join a clan before planning with stash stock.","red");return false;}
    try{
        if(original!=stash&&!cli_execute("/whitelist "+stash))return false;
        if(get_clan_name()!=stash){print("Could not access diet stash clan: "+stash,"red");return false;}
        if(!refresh_stash()){print("Could not refresh diet stash stock.","red");return false;}
        foreach it,n in get_stash()barfDietStashStock[it]=n;
        print("Diet stock includes "+stash+" stash; no items withdrawn.","blue");
        return true;
    }finally{
        if(get_clan_name()!=original&&(!cli_execute("/whitelist "+original)||get_clan_name()!=original))
            abort("Could not restore your original clan: "+original);
    }
}

item[int] barfGreedCandies;

item[int] barfSynthesisCandies(){
    if (count(barfGreedCandies) == 0) barfGreedCandies = sweet_synthesis_pair($effect[Synthesis: Greed],8);
    return barfGreedCandies;
}


// Bounded knapsack by effect group: repeats never credit buff turns past the horizon.
// Foods with the same effect compete in one group, avoiding duplicate buff value.


void barfOde(int size){
    if (!have_skill($skill[The Ode to Booze])) return;
    while (have_effect($effect[Ode to Booze]) < size){
        int before = have_effect($effect[Ode to Booze]);
        if (my_mp() < mp_cost($skill[The Ode to Booze])) restore_mp(mp_cost($skill[The Ode to Booze]));
        if (!use_skill(1,$skill[The Ode to Booze]) || have_effect($effect[Ode to Booze]) <= before)
            abort("BARF could not acquire Ode before drinking.");
    }
}

// Compare organ-clearing meals with the diet they displace, including the refill.

// Prevent organ-changing Mayo automation from invalidating the planner.

// A short test run must not buy a full day's diet it will not use.
// Breakfast must precede every other food, including legendary pasta.


// Two-day planner inputs. This exports read-only runtime data; it never consumes.
string barfDietCell(string value){ return replace_string(replace_string(value,"\t"," "),"\n"," "); }

void barfDietSnapshot(){
    if(!barfDietReadStash())return;
    string[string] state;
    state["stash_clan"]=get_property("teresBarfStashClan")==""?"Soup Clan":get_property("teresBarfStashClan");
    state["day"] = today_to_string();
    state["adventures"] = my_adventures(); state["meat"] = my_meat();
    state["fullness"] = my_fullness(); state["drunkenness"] = my_inebriety(); state["spleen"] = my_spleen_use();
    state["fullness_limit"] = fullness_limit(); state["drunkenness_limit"] = inebriety_limit(); state["spleen_limit"] = spleen_limit();
    state["familiar"] = my_familiar(); state["familiar_weight"] = familiar_weight(my_familiar()) + weight_adjustment();
    state["meat_drop"] = numeric_modifier("Meat Drop"); state["item_drop"] = numeric_modifier("Item Drop");
    state["level"] = my_level(); state["hp"] = my_hp(); state["mp"] = my_mp();
    state["turns"] = total_turns_played(); state["path"] = my_path(); state["class"] = my_class();
    state["rollover_outfit"] = get_property("teresBarfRolloverOutfit");
    state["rollover_native_modifier"] = numeric_modifier("Adventures");
    foreach it in $items[devilbone corset,angelbone chopsticks,angelbone dice,devilbone rosary,angelbone totem,devilbone greaves]
        state["capacity."+to_int(it)]=numeric_modifier(it,"Stomach Capacity")+"\t"+numeric_modifier(it,"Liver Capacity")+"\t"+numeric_modifier(it,"Spleen Capacity");
    foreach pref in $strings[familiarSweat,sweat,_sweatOutSomeBoozeUsed,_milkOfMagnesiumUsed,milkOfMagnesiumActive,
        _fudgeSporkUsed,_saladForkUsed,_frostyMugUsed,miniKiwiAiolisUsed,whetstonesUsed,legendaryNoodlesStomach,
        _legendaryNoodlesSpleen,_mimeArmyShotglassUsed,_coolerYetiAdventures,coolerYetiMode,_monkeyPawWishesUsed,
        currentMojoFilters,_distentionPillUsed,_syntheticDogHairPillUsed,spiceMelangeUsed,_sweetToothUsed,_voraciTeaUsed,
        _sobrieTeaUsed,_aug16Cast,_augSkillsCast,_speakeasyDrinksDrunk,extraRolloverAdventures,ledCandleMode,
        ghostPepperTurnsLeft,getsYouDrunkTurnsLeft,beGregariousCharges,beGregariousFightsLeft,beGregariousMonster,
        _chocolatesUsed,_chocolateCigarsUsed,_vitachocCapsulesUsed,_chocolateSculpturesUsed,_essentialTofuUsed,_clocksUsed]
        state["pref."+pref] = get_property(pref);
    foreach farmer in $familiars[Jill-of-All-Trades,Stocking Mimic,Cooler Yeti,Chest Mimic,Stooper,Animated Macaroni Duck]{
        state["familiar."+to_int(farmer)] = have_familiar(farmer) + "\t" + farmer.experience;
    }
    foreach spot in $slots[hat,weapon,off-hand,back,shirt,pants,acc1,acc2,acc3,familiar]
        state["equipment."+spot] = to_int(equipped_item(spot));
    foreach buff, turns in my_effects()
        state["effect."+to_int(buff)] = turns + "\t" + numeric_modifier(buff,"Familiar Weight") + "\t" + numeric_modifier(buff,"Meat Drop");
    foreach sk in $skills[] if (have_skill(sk)) state["skill."+to_int(sk)] = sk.dailylimit;
    foreach it, quantity in get_campground() state["camp."+to_int(it)] = quantity;
    foreach it, quantity in get_chateau() state["chateau."+to_int(it)] = quantity;
    foreach name, quantity in get_clan_rumpus() state["clan."+name] = quantity;
    string[int] prices;
    string[int] inventory;
    string[int] consumables;
    foreach it in $items[]{
        int stock = barfDietOwnedAmount(it);
        if (stock > 0) inventory[to_int(it)] = stock;
        if (it.fullness <= 0 && it.inebriety <= 0 && it.spleen <= 0) continue;
        if (it.levelreq > my_level()) continue;
        effect buff = effect_modifier(it,"Effect");
        consumables[to_int(it)] = barfDietCell(it.to_string()) + "\t" + it.fullness + "\t" + it.inebriety + "\t" + it.spleen
            + "\t" + it.adventures + "\t" + it.dailyusesleft + "\t" + to_int(buff) + "\t"
            + numeric_modifier(it,"Effect Duration") + "\t" + numeric_modifier(buff,"Familiar Weight") + "\t"
            + numeric_modifier(buff,"Meat Drop") + "\t" + it.tradeable + "\t" + creatable_amount(it) + "\t" + barfDietCell(it.notes);
        prices[to_int(it)] = historical_price(it)+"\t"+historical_age(it);
    }
    foreach it in $items[chocolate seal-clubbing club,chocolate turtle totem,chocolate pasta spoon,chocolate saucepan,
        chocolate disco ball,chocolate stolen accordion,fancy chocolate,fancy but probably evil chocolate,fancy chocolate car,
        beet-flavored Mr. Mediocrebar,cabbage-flavored Mr. Mediocrebar,sweet-corn-flavored Mr. Mediocrebar,choco-Crimbot,
        chocolate cigar,vitachoconutriment capsule,fancy chocolate sculpture,essential tofu,clock]
        prices[to_int(it)]=historical_price(it)+"\t"+historical_age(it);
    if (!map_to_file(state,"teres-barf-diet-state.tsv") || !map_to_file(inventory,"teres-barf-diet-inventory.tsv")
        || !map_to_file(consumables,"teres-barf-diet-consumables.tsv") || !map_to_file(prices,"teres-barf-diet-prices.tsv"))
        abort("Could not export the BARF diet snapshot.");
    print("Read-only diet snapshot exported to KoLmafia/data/teres-barf-diet-*.tsv.","blue");
}

// Revised objective: today's net farming value plus distinct retained effects tomorrow.
// Search is bounded and read-only by default; historical prices/yields are not inputs.
record barfTwoDayItem {
    item target; int fullness; int drunkenness; int spleen;
    float minimum; float average; int price; effect buff; int duration;
    string dailyGroup; int dailyRemaining; string special; boolean crafted; int[item] ingredients;
    int delayedCombats; int delayedMinimum; float delayedAverage;
};
record barfTwoDayStage {
    boolean legal; int mask; boolean stooper; float nonfamiliarMeat; float weight;
    int fullness; int drunkenness; int spleen; string equipment; float itemIncome;
    familiar farmer; item familiarGear; float experience; boolean sweatpants;
    float weightPercent; float leprechaunWeight; float leprechaunEffectiveness;
    string error;
    float itemDrop; float smithMeatPerPoint;
};
record barfTwoDayState {
    int fullness; int drunkenness; int spleen; float adventures; float minimumAdventures;
    int mask; boolean stooper; int sweat; int pantsSweat; int yetiXP; boolean yetiDouble;
    int noodles; int milk; int spork; int aioli; int whet; int shotglass;
    int turns; float income; float cost; float cash; string schedule;
    int[int] effects; boolean[int] retained; int[string] uses; boolean finished;
    int chestXP; int earlyJillTurns; float liquidIncome;
    float trainingCost; float trainingOpportunity;
};
boolean barfDietRelaxedWallet;boolean barfDietTraceCash;float barfDietTraceExposure;
boolean barfDietFundingLegal(barfTwoDayState s){return barfDietRelaxedWallet||s.cash<=my_meat()+s.liquidIncome;}
barfTwoDayItem[int] barfTwoDayItems;
barfTwoDayItem[item] barfDietCandidateDetails;
string[item] barfDietCandidateStatus;
barfTwoDayStage[int] barfTwoDayStages;
int[effect] barfTwoDayInitialEffects;
item[int] barfTwoDayCapacityItems = {$item[devilbone corset],$item[angelbone chopsticks],
    $item[angelbone dice],$item[devilbone rosary],$item[angelbone totem],$item[devilbone greaves]};
int barfTwoDayRollover;  int barfTwoDayClanGain; string barfTwoDayRolloverGoal;
float barfTwoDayWeightCalibration = 0;
string barfTwoDayWarnings;
float barfTwoDayCopiedWeight;
barfTwoDayState[string] barfDietComparisons;
float[int] barfDietDropIncomeCache;


int barfDietTrainingGoal(barfTwoDayState s,boolean chest){
    int goal=s.uses["trainingOverride"]>0?s.uses[chest?"chestGoal":"yetiGoal"]:barfSetting(chest?"ChestXP":"YetiXP",chest?950:2000);
    if(!chest&&s.uses["yetiCharged"]>0)goal=barfSetting("YetiReserveXP",0);
    if(!chest&&s.uses["allCool"]>0)goal=max(goal,225*max(0,s.uses["coolSlots"]-s.uses["coolRefreshes"])+(s.uses["coldRequired"]>0?400:0)+barfSetting("YetiReserveXP",0));
    return goal;
}

boolean barfDietBit(int mask,int bit){return (mask/(2**bit).to_int())%2==1;}
barfTwoDayState barfDietClone(barfTwoDayState a){
    barfTwoDayState b = new barfTwoDayState(a.fullness,a.drunkenness,a.spleen,a.adventures,a.minimumAdventures,
        a.mask,a.stooper,a.sweat,a.pantsSweat,a.yetiXP,a.yetiDouble,a.noodles,a.milk,a.spork,a.aioli,a.whet,a.shotglass,
        a.turns,a.income,a.cost,a.cash,a.schedule);
    foreach key,value in a.effects if(value>0)b.effects[key]=value;
    foreach key,value in a.retained if(value)b.retained[key]=value;
    foreach key,value in a.uses if(value!=0)b.uses[key]=value;
    b.finished=a.finished;b.chestXP=a.chestXP;b.earlyJillTurns=a.earlyJillTurns;b.liquidIncome=a.liquidIncome;
    b.trainingCost=a.trainingCost;b.trainingOpportunity=a.trainingOpportunity;return b;
}
int barfDietStageKey(barfTwoDayState s){
    int key=s.mask+(s.stooper?64:0);
    if(s.mask==0&&!s.stooper&&s.turns>=s.earlyJillTurns){
        if(s.uses["allCool"]>0&&have_familiar($familiar[Cooler Yeti])&&s.yetiXP<barfDietTrainingGoal(s,false))key+=256;
        else if(have_familiar($familiar[Chest Mimic])&&s.chestXP<barfDietTrainingGoal(s,true))key+=128;
        else if(have_familiar($familiar[Cooler Yeti])&&s.yetiXP<barfDietTrainingGoal(s,false))key+=256;
    }
    return key;
}
int barfDietDuration(barfTwoDayState s,effect ef){return max(0,s.effects[to_int(ef)]);}

string[item] barfDietDailyGroups;
int[item] barfDietDailyLimits;
int[item] barfDietPrices;
boolean[item] barfDietBuyable;
boolean barfDietFastGear;


item[slot] barfDietSpecGear;
string barfDietBaseModes;


record barfDietEffectData {
    float meat;float weight;float weightPercent;float experience;float itemDrop;float smithsness;
};
barfDietEffectData[effect] barfDietEffectCache;
barfDietEffectData barfDietEffect(effect buff){
    if(!(barfDietEffectCache contains buff)){
        location previous=my_location();
        barfDietEffectData data;
        // Conditional native modifiers must describe the forecast destination,
        // even when the last real adventure was elsewhere.
        try{
            set_location($location[Barf Mountain]);
            data.meat=numeric_modifier(buff,"Meat Drop");data.weight=numeric_modifier(buff,"Familiar Weight");
            data.weightPercent=numeric_modifier(buff,"Familiar Weight Percent");data.experience=numeric_modifier(buff,"Familiar Experience");
            data.itemDrop=numeric_modifier(buff,"Item Drop");data.smithsness=numeric_modifier(buff,"Smithsness");
        }finally{set_location(previous);}
        barfDietEffectCache[buff]=data;
    }
    return barfDietEffectCache[buff];
}
barfDietEffectData barfDietEffectAt(effect buff,int duration){
    if(duration<=0)return new barfDietEffectData();
    barfDietEffectData cached=barfDietEffect(buff);
    if(!($effects[Blue Swayed,Cold Hearted,She Ate Too Much Candy,My Breakfast With Andrea,Sour Softshoe,Sweet Heart] contains buff)
        &&buff!=to_effect("Buy!  Sell!  Buy!  Sell!"))return cached;
    barfDietEffectData data=new barfDietEffectData(cached.meat,cached.weight,cached.weightPercent,cached.experience,cached.itemDrop,cached.smithsness);
    if(buff==$effect[Blue Swayed]){data.experience=ceil(min(duration,50)/5.0);data.weight=ceil(min(duration,50)/10.0);}
    else if(buff==$effect[Cold Hearted])data.weight=ceil(min(duration,20)/2.0);
    else if(buff==$effect[She Ate Too Much Candy])data.weight=min(duration,25);
    else if(buff==to_effect("Buy!  Sell!  Buy!  Sell!"))data.meat=max(0,202-2*duration);
    else if(buff==$effect[My Breakfast With Andrea])data.meat=min(80,2*duration);
    else if(buff==$effect[Sour Softshoe]){data.itemDrop=min(duration,50);data.meat=2*min(duration,50);}
    else if(buff==$effect[Sweet Heart])data.meat=2*min(duration,20);
    return data;
}
int barfDietVariableEffectCap(effect buff){
    if(buff==$effect[Blue Swayed]||buff==$effect[Sour Softshoe])return 50;
    if(buff==$effect[Cold Hearted]||buff==$effect[Sweet Heart])return 20;
    if(buff==$effect[She Ate Too Much Candy])return 25;
    if(buff==$effect[My Breakfast With Andrea])return 40;
    if(buff==to_effect("Buy!  Sell!  Buy!  Sell!"))return 101;
    return 0;
}
boolean barfDietRelevantEffect(effect buff){
    if(buff==$effect[none])return false;
    // Maintained deterministically below; never search or score its expiry.
    if(buff==$effect[How to Scam Tourists])return false;
    barfDietEffectData data=barfDietEffect(buff);
    return data.meat!=0||data.weight!=0||data.weightPercent!=0||data.experience!=0||data.itemDrop!=0
        ||data.smithsness!=0
        ||$effects[Song of the Glorious Lunch,Barrel of Laughs,Refined Palate,Gar-ish,Beer Barrel Polka,Salty Mouth,Looking Cool,Smart Drunk] contains buff;
}

int barfDietDailyUsed(string preference){
    if(preference=="")return 0;
    string value=get_property(preference);
    if(value=="true")return 1;
    if(value=="false"||value=="")return 0;
    return value.to_int();
}

int[item] barfDietRecipePrices;
boolean[item] barfDietPricingRecipe;
int[item] barfDietIngredients(item it){
    int[item] recipe=get_ingredients(it);
    // The Forge exchange is not in KoLmafia's normal crafting table.
    if(it==$item[shadow martini]){
        recipe[$item[shadow glass]]=1;recipe[$item[shadow ice]]=1;recipe[$item[shadow nectar]]=1;
    }
    return recipe;
}
boolean barfDietCanCraft(item it){
    return craft_type(it)=="Meatpasting"||(!it.tradeable&&craft_type(it)=="Cooking");
}
int barfDietCurrentPrice(item it);
int barfDietRecipePrice(item it){
    if(barfDietRecipePrices contains it)return barfDietRecipePrices[it];
    if(barfDietPricingRecipe[it])return -1;
    int[item] recipe=barfDietIngredients(it);if(count(recipe)==0)return -1;
    barfDietPricingRecipe[it]=true;int cost=0;
    foreach part,q in recipe{
        int price=barfDietCurrentPrice(part);
        if(price<0){cost=-1;break;}
        cost+=q*price;
    }
    barfDietPricingRecipe[it]=false;
    // Native recipes describe a batch; these untradeable batches produce multiple items.
    int yield=it==$item[mediocre lager]?6:it==$item[grubby woolball]?3:1;
    if(cost>=0)cost=ceil(cost/to_float(yield));
    barfDietRecipePrices[it]=cost;return cost;
}
int barfDietCurrentPrice(item it){
    if(it==$item[milk of magnesium])return 100;
    if(it==$item[Dreadsylvanian cold-fashioned]){barfDietBuyable[it]=true;return 100000;}
    if (it==$item[none]) return 0;
    if (barfDietPrices contains it) return barfDietPrices[it];
    int owned=barfDietOwnedAmount(it);
    int p=-1;
    if(it.tradeable){
        int market=mall_price(it);int npc=npc_price(it);
        if(market>0&&market<999999999){p=market;barfDietBuyable[it]=true;}
        if(npc>0){p=p>0?min(p,npc):npc;barfDietBuyable[it]=true;}
        if(p<0&&owned>0)p=autosell_price(it);
        if(p>=0)p=max(autosell_price(it),p);
    }else{
        p=barfDietRecipePrice(it);
        if(p<0&&count(barfDietIngredients(it))==0&&(craft_type(it)=="[cannot be created]"||craft_type(it)=="none")&&owned>0)p=0;
    }
    barfDietPrices[it]=p;return p;
}

string barfDietStageGoal(int mask,boolean stooper){
    string goal="meat drop, switch "+(stooper?"Stooper":"Jill-of-All-Trades")
        +", -equip PirateRealm eyepatch, -equip bat wings, -equip Kramco Sausage-o-Matic, -equip McHugeLarge left pole, -equip legendary seal-clubbing club";
    if (!stooper) goal+=", equip LED candle (ultraviolet)";
    foreach i,it in barfTwoDayCapacityItems goal+=", "+(barfDietBit(mask,i)?"equip ":"-equip ")+it;
    if(stooper){
        float liver=numeric_modifier("Liver Capacity")-numeric_modifier("Familiar:"+my_familiar(),"Liver Capacity")+1;
        foreach i,it in barfTwoDayCapacityItems
            liver+=(barfDietBit(mask,i)?1:0)*numeric_modifier(it,"Liver Capacity")-(have_equipped(it)?1:0)*numeric_modifier(it,"Liver Capacity");
        goal+=", 0 liver capacity, "+liver+" min";
    }
    if (my_path()==$path[Hat Trick]&&equipped_item($slot[hat])!=$item[none]) goal+=", equip "+equipped_item($slot[hat]);
    return goal;
}

item barfDietProjectedFamiliarGear(familiar farmer,int trainer){
    item gear=trainer>0?$item[tiny stillsuit]:barfFamiliarGear(farmer);
    if(available_amount(gear)>0)return gear;
    return available_amount($item[tiny stillsuit])>0?$item[tiny stillsuit]:$item[none];
}

boolean barfDietFixedGear(int mask,familiar farmer,int trainer){
    item[slot] gear=barfPlannedOutfit(mask,farmer,trainer);
    if(trainer==0)gear[$slot[familiar]]=barfDietProjectedFamiliarGear(farmer,0);
    int[item] required;
    string speculation="speculate quiet; familiar "+farmer+barfDietBaseModes;
    foreach spot,it in gear{
        if(it!=$item[none]&&++required[it]>available_amount(it))return false;
        speculation+="; "+(it==$item[none]?"unequip "+spot:"equip "+spot+" ¶"+to_int(it));
    }
    if(!cli_execute(speculation))return false;
    clear(barfDietSpecGear);foreach spot,it in gear barfDietSpecGear[spot]=it;
    return true;
}

int barfDietStockCash(barfTwoDayState s,item target,int quantity,int price){
    if(target==$item[none])return quantity*price;
    string key="stock:"+to_int(target);
    int owned=barfDietOwnedAmount(target);
    int bought=max(0,quantity-max(0,owned-s.uses[key]));
    s.uses[key]+=quantity;return bought*price;
}

// Consume owned finished items/intermediates first; only missing copies spend ingredients.
int barfDietCraftCash(barfTwoDayState s,item target,int quantity,boolean forceCraft,int depth){
    if(depth>20)return -1;
    if(!forceCraft){
        int owned=min(quantity,max(0,barfDietOwnedAmount(target)-s.uses["stock:"+to_int(target)]));
        s.uses["stock:"+to_int(target)]+=owned;quantity-=owned;
        if(quantity==0)return 0;
        if(target.tradeable){
            int price=barfDietCurrentPrice(target);if(price<0||!barfDietBuyable[target])return -1;
            return barfDietStockCash(s,target,quantity,price);
        }
    }
    if(!barfDietCanCraft(target))return -1;
    int[item] recipe=barfDietIngredients(target);if(count(recipe)==0)return -1;
    int cash=craft_type(target)=="Meatpasting"&&!knoll_available()?10*quantity:0;
    foreach part,q in recipe{
        int needed=barfDietCraftCash(s,part,q*quantity,false,depth+1);
        if(needed<0)return -1;cash+=needed;
    }
    if(!forceCraft)s.uses["stock:"+to_int(target)]+=quantity;
    return cash;
}

float barfDietDropIncome(float bonus){
    int key=round(bonus*1000);
    if(!(barfDietDropIncomeCache contains key)){
        float value=0;
        foreach mob,frequency in appearance_rates($location[Barf Mountain]) if(frequency>0)
            foreach drop,rate in item_drops(mob) if(rate>0&&drop.tradeable)
                value+=frequency/100*max(0.0,min(1.0,rate/100.0*(1+bonus/100)))*max(0,barfDietCurrentPrice(drop));
        barfDietDropIncomeCache[key]=value;
    }
    return barfDietDropIncomeCache[key];
}
barfTwoDayStage barfDietBuildStageAtBarf(int mask,boolean stooper,int trainer){
    barfTwoDayStage stage;
    stage.mask=mask;stage.stooper=stooper;
    foreach i,it in barfTwoDayCapacityItems if (barfDietBit(mask,i)&&available_amount(it)==0){stage.error="Missing capacity item: "+it+".";return stage;}
    familiar farmer=trainer==128?$familiar[Chest Mimic]:trainer==256?$familiar[Cooler Yeti]:stooper?$familiar[Stooper]:$familiar[Jill-of-All-Trades];
    if(!have_familiar(farmer)){stage.error="Familiar unavailable: "+farmer+".";return stage;}
    if(trainer==0&&!stooper&&available_amount($item[LED candle])==0){stage.error="Jill's LED candle is unavailable.";return stage;}
    string goal=barfDietStageGoal(mask,stooper);
    if(trainer>0){
        goal="familiar experience, switch "+(trainer==128?"Chest Mimic":"Cooler Yeti")+", -equip PirateRealm eyepatch";
        foreach spot,it in barfTrainingOutfit()goal+=", equip "+it;
        if(my_path()==$path[Hat Trick]&&equipped_item($slot[hat])!=$item[none])goal+=", equip "+equipped_item($slot[hat]);
    }
    if (!barfDietFixedGear(mask,farmer,trainer)){stage.error="Could not forecast the fixed BARF outfit and its required swaps. Check the equipped baseline and item ownership.";return stage;}
    item gear=barfDietFastGear?barfDietProjectedFamiliarGear(farmer,trainer):trainer>0?$item[tiny stillsuit]:stooper?barfFamiliarGear(farmer):$item[LED candle];
    stage.farmer=farmer;stage.familiarGear=gear;
    stage.fullness=fullness_limit()+round(numeric_modifier("Generated:_spec","Stomach Capacity")-numeric_modifier("Stomach Capacity"));
    stage.drunkenness=inebriety_limit()+round(numeric_modifier("Generated:_spec","Liver Capacity")-numeric_modifier("Liver Capacity"));
    stage.spleen=spleen_limit()+round(numeric_modifier("Generated:_spec","Spleen Capacity")-numeric_modifier("Spleen Capacity"));
    // The standalone familiar API omits modeable LED adjustments; use the native
    // leprechaun weight/effectiveness modifiers and the installed Mafia formula.
    stage.weight=familiar_weight(farmer)+numeric_modifier("Generated:_spec","Familiar Weight")+numeric_modifier("Generated:_spec","Hidden Familiar Weight")
        +(farmer.feasted?10:0)+farmer.soup_weight;
    stage.weightPercent=numeric_modifier("Generated:_spec","Familiar Weight Percent");
    stage.leprechaunWeight=max(1.0,numeric_modifier("Generated:_spec","Leprechaun"));
    stage.leprechaunEffectiveness=max(1.0,numeric_modifier("Generated:_spec","Leprechaun Effectiveness"));
    float adjusted=floor(stage.weight*(1+stage.weightPercent/100));
    float familiarMeat=farmer==$familiar[Jill-of-All-Trades]
        ? stage.leprechaunEffectiveness*((220*adjusted*stage.leprechaunWeight)**0.5+2*adjusted*stage.leprechaunWeight-6)
        : numeric_modifier(farmer,"Meat Drop",max(1,floor(adjusted-numeric_modifier(gear,"Familiar Weight")-numeric_modifier(gear,"Hidden Familiar Weight"))),gear);
    stage.nonfamiliarMeat=numeric_modifier("Generated:_spec","Meat Drop")-familiarMeat;
    // Include the guaranteed buff exactly once, whether currently active or not.
    stage.nonfamiliarMeat+=300-(have_effect($effect[How to Scam Tourists])>0?numeric_modifier($effect[How to Scam Tourists],"Meat Drop"):0);
    stage.smithMeatPerPoint=barfDietSpecGear[$slot[off-hand]]==$item[Half a Purse]?2:0;
    if(farmer==$familiar[Jill-of-All-Trades]&&gear==$item[LED candle])
        stage.leprechaunWeight=numeric_modifier("LedCandle:ultraviolet","Leprechaun");
    if(trainer==0&&!barfDietBit(mask,0))
        stage.nonfamiliarMeat+=numeric_modifier("JurassicParka:kachungasaur","Meat Drop")-numeric_modifier("JurassicParka:"+get_property("parkaMode"),"Meat Drop");
    stage.equipment=goal;stage.experience=1+numeric_modifier("Generated:_spec","Familiar Experience");
    stage.sweatpants=trainer>0;
    float itemdrop=numeric_modifier("Generated:_spec","Item Drop");
    stage.itemDrop=itemdrop;stage.itemIncome=barfDietDropIncome(itemdrop);
    stage.legal=true;return stage;
}

barfTwoDayStage barfDietBuildStage(int mask,boolean stooper,int trainer){
    location previous=my_location();
    try{
        set_location($location[Barf Mountain]);
        return barfDietBuildStageAtBarf(mask,stooper,trainer);
    }finally{set_location(previous);}
}

barfTwoDayStage barfDietStage(barfTwoDayState s){
    int key=barfDietStageKey(s);
    if (!(barfTwoDayStages contains key)) barfTwoDayStages[key]=barfDietBuildStage(s.mask,s.stooper,key>=256?256:key>=128?128:0);
    return barfTwoDayStages[key];
}

barfTwoDayStage barfDietFarmingStage(barfTwoDayState s){
    int key=s.mask+(s.stooper?64:0);
    if(!(barfTwoDayStages contains key))barfTwoDayStages[key]=barfDietBuildStage(s.mask,s.stooper,0);
    return barfTwoDayStages[key];
}
float barfDietWeightValue(float pounds){
    float beyond=min(100,barfSetting("WeightBeyond40Percent",50))/100.0;
    return (min(40.0,pounds)+max(0,pounds-40)*beyond)*barfTwoDayWeightCalibration;
}
float barfDietTomorrowValue(barfTwoDayState s){
    float pounds=0;
    int before=barfSetting("TomorrowPaidTurnsBeforeFK",0);
    foreach id,keep in s.retained if (keep && s.effects[id]>=5 && s.effects[id]>before)
        pounds+=max(0,barfDietEffectAt(to_effect(id),s.effects[id]).weight);
    if (s.finished && before==0 && s.effects[to_int($effect[Smart Drunk])]>0
        && !(s.retained contains to_int($effect[Smart Drunk]))) pounds+=20;
    // Local calibration is supported around 660-700 lb, not at a 500-lb goblin.
    return barfDietWeightValue(pounds);
}

// Memoized projections belong to one frozen plan, never to live account state.
boolean barfDietMemoize;
item[int] barfDietExtraMenu;
boolean barfDietExtraMenuReady;
string barfDietExtraMenuKey;
boolean barfDietSkipBare;boolean barfDietShareFarmForecasts;

record barfDietFarmPrefix {barfTwoDayState state;int segment;int stage;};
barfDietFarmPrefix[int] barfDietFarmPrefixes;
string barfDietFarmParentKey;
float[string] barfDietRateCache;float[string] barfDietItemIncomeCache;
float[string] barfDietFutureCache;float[string] barfDietTomorrowCache;
record barfDietScoreKernel {float rate;float fraction;int[int] expiry;float[int] loss;};
barfDietScoreKernel[string] barfDietScoreKernels;
int barfDietScoreKernelHits;int barfDietScoreKernelMisses;
boolean[string,item] barfDietContinuationLive;int[item] barfDietContinuationOwned;
int[int] barfDietEffectCaps;
barfTwoDayState[string] barfDietFillCache;
int barfDietFillCacheHits;int barfDietFillCacheMisses;
barfTwoDayState[string] barfDietPreparationCache;
int barfDietPreparationHits;int barfDietPreparationMisses;
barfTwoDayState[string] barfDietCapacityStartCache;int[string] barfDietCapacityStartAges;
int barfDietCapacityStartClock;int barfDietCapacityStartHits;
void barfDietResetSearchCaches(){
    barfDietRelaxedWallet=false;barfDietTraceCash=false;barfDietTraceExposure=0;
    clear(barfDietExtraMenu);barfDietExtraMenuReady=false;barfDietExtraMenuKey="";
    clear(barfDietRateCache);clear(barfDietItemIncomeCache);
    clear(barfDietFutureCache);clear(barfDietTomorrowCache);clear(barfDietEffectCaps);
    clear(barfDietScoreKernels);barfDietScoreKernelHits=0;barfDietScoreKernelMisses=0;
    clear(barfDietContinuationLive);clear(barfDietContinuationOwned);
    clear(barfDietFarmPrefixes);barfDietFarmParentKey="";
    clear(barfDietFillCache);barfDietFillCacheHits=0;barfDietFillCacheMisses=0;
    clear(barfDietPreparationCache);barfDietPreparationHits=0;barfDietPreparationMisses=0;
    clear(barfDietCapacityStartCache);clear(barfDietCapacityStartAges);barfDietCapacityStartClock=0;barfDietCapacityStartHits=0;
    barfDietMemoize=true;barfDietSkipBare=true;barfDietShareFarmForecasts=true;
}
string barfDietEffectKey(barfTwoDayState s,boolean exact){
    string key="";
    foreach id,left in s.effects if(left>0){
        int value=left;
        if(!exact){
            if(!(barfDietEffectCaps contains id))barfDietEffectCaps[id]=barfDietVariableEffectCap(to_effect(id));
            value=barfDietEffectCaps[id]>0?min(left,barfDietEffectCaps[id]):1;
        }
        key+=":"+id+"="+value;
    }
    if(exact)foreach id,keep in s.retained key+=":r"+id+"="+keep;
    return key;
}
string barfDietRateKey(barfTwoDayState s,barfTwoDayStage stage){
    return stage.mask+":"+stage.stooper+":"+to_int(stage.farmer)+":"+to_int(stage.familiarGear)
        +":"+stage.nonfamiliarMeat+":"+stage.weight+":"+stage.weightPercent
        +":"+stage.leprechaunWeight+":"+stage.leprechaunEffectiveness+":"+stage.smithMeatPerPoint
        +":"+stage.itemIncome+":"+stage.itemDrop+barfDietEffectKey(s,false);
}

float barfDietItemIncomeUncached(barfTwoDayState s,barfTwoDayStage stage){
    float change=0;
    foreach ef,t in barfTwoDayInitialEffects if(t>0)change+=barfDietEffectAt(ef,barfDietDuration(s,ef)).itemDrop-barfDietEffectAt(ef,t).itemDrop;
    foreach id,t in s.effects if(t>0&&!(barfTwoDayInitialEffects contains to_effect(id)))change+=barfDietEffectAt(to_effect(id),t).itemDrop;
    return change==0?stage.itemIncome:barfDietDropIncome(stage.itemDrop+change);
}
float barfDietItemIncome(barfTwoDayState s,barfTwoDayStage stage){
    if(!barfDietMemoize)return barfDietItemIncomeUncached(s,stage);
    string key=barfDietRateKey(s,stage);
    if(barfDietItemIncomeCache contains key)return barfDietItemIncomeCache[key];
    float result=barfDietItemIncomeUncached(s,stage);barfDietItemIncomeCache[key]=result;return result;
}

float barfDietRateAtStageUncached(barfTwoDayState s,barfTwoDayStage stage){
    float meat=stage.nonfamiliarMeat; float weight=stage.weight;float percent=stage.weightPercent;
    foreach ef,turns in barfTwoDayInitialEffects if (turns>0){
        barfDietEffectData before=barfDietEffectAt(ef,turns);barfDietEffectData after=barfDietEffectAt(ef,barfDietDuration(s,ef));
        meat+=after.meat-before.meat+stage.smithMeatPerPoint*(after.smithsness-before.smithsness);
        weight+=after.weight-before.weight;percent+=after.weightPercent-before.weightPercent;
    }
    foreach id,turns in s.effects if (turns>0 && !(barfTwoDayInitialEffects contains to_effect(id))){
        barfDietEffectData data=barfDietEffectAt(to_effect(id),turns);meat+=data.meat+stage.smithMeatPerPoint*data.smithsness;weight+=data.weight;percent+=data.weightPercent;
    }
    familiar farmer=stage.farmer;
    item famGear=stage.familiarGear;
    float adjusted=max(1,floor(weight*(1+percent/100)));
    float multiplier=max(1.0,stage.leprechaunWeight);float effectiveness=max(1.0,stage.leprechaunEffectiveness);
    float familiarMeat=farmer==$familiar[Jill-of-All-Trades]
        ? effectiveness*((220*adjusted*multiplier)**0.5+2*adjusted*multiplier-6)
        : numeric_modifier(farmer,"Meat Drop",max(1,floor(adjusted-numeric_modifier(famGear,"Familiar Weight")-numeric_modifier(famGear,"Hidden Familiar Weight"))),famGear);
    float base=barfBaseMeat();
    if(get_property("boomBoxSong")=="Total Eclipse of Your Meat")base+=25;
    float combat=base*(1+(meat+familiarMeat)/100)+barfDietItemIncome(s,stage);
    // The NC ratio/payout are explicit estimates; do not assign combat Meat to NCs.
    float combats=barfSetting("CombatsBetweenNC",30);
    return (combats*combat+barfSetting("NoncombatMeat",1750))/(combats+1);
}
float barfDietRateAtStage(barfTwoDayState s,barfTwoDayStage stage){
    if(!barfDietMemoize)return barfDietRateAtStageUncached(s,stage);
    string key=barfDietRateKey(s,stage);
    if(barfDietRateCache contains key)return barfDietRateCache[key];
    float result=barfDietRateAtStageUncached(s,stage);barfDietRateCache[key]=result;return result;
}

float barfDietRate(barfTwoDayState s){return barfDietRateAtStage(s,barfDietStage(s));}
float barfDietLiquidRate(barfTwoDayState s,barfTwoDayStage stage){
    // Drop income is valued stock, not spendable Meat.
    return barfDietRateAtStage(s,stage)-barfDietItemIncome(s,stage)*barfSetting("CombatsBetweenNC",30)/(barfSetting("CombatsBetweenNC",30)+1.0);
}

int barfDietNightcapMinimum(){
    int result=40;
    if (have_skill($skill[The Ode to Booze])) result+=10;
    if (have_skill($skill[Rowdy Drinker])) result+=10;
    return result;
}
int barfDietProjectedStart(barfTwoDayState s,float remainingConsumption){
    return min(200,floor(s.minimumAdventures+remainingConsumption+(s.finished?0:barfDietNightcapMinimum())+barfTwoDayRollover));
}
boolean barfDietRetentionLegal(barfTwoDayState s,int paid){
    foreach id,keep in s.retained if (keep && s.effects[id]-paid<5) return false;
    return true;
}
boolean barfDietFarmLegal(barfTwoDayState s,int paid){
    barfTwoDayStage stage=barfDietStage(s);
    return !s.finished && stage.legal && s.fullness<=stage.fullness+s.uses["extraFullness"] && s.drunkenness<=stage.drunkenness+s.uses["extraLiver"]
        && s.spleen<=stage.spleen && barfDietRetentionLegal(s,paid)
        && (s.uses["forecastMode"]>0
            ? s.adventures-paid>=max(0,200-barfTwoDayRollover-barfDietNightcapMinimum())
                && s.minimumAdventures>=max(0,200-barfTwoDayRollover-barfDietNightcapMinimum())
            : s.minimumAdventures>=paid && barfDietProjectedStart(s,-paid)==200);
}
string barfDietDelayedAdventureKey(item it){return "delayedAdventure:"+to_int(it);}
string barfDietDelayedAdventureStateKey(barfTwoDayState s){
    string key="";
    foreach it in $items[ghost pepper,Gets-You-Drunk]{
        string itemKey=barfDietDelayedAdventureKey(it);
        key+=":"+s.uses[itemKey+":combats"]+":"+s.uses[itemKey+":minimum"]+":"+s.uses[itemKey+":averageHalf"];
    }
    return key;
}
int barfDietForecastCombats(int turns,int paid){
    float ratio=barfSetting("CombatsBetweenNC",30);
    return floor((turns+paid)*ratio/(ratio+1))-floor(turns*ratio/(ratio+1));
}
int barfDietTurnsToDelayedAdventure(barfTwoDayState s,item it){
    string key=barfDietDelayedAdventureKey(it);int pending=s.uses[key+":combats"];
    if(pending<=0)return 0;
    for turns from 1 to 200{
        if(barfDietForecastCombats(s.turns,turns)>=pending)return turns;
    }
    return 201;
}


// All state fields except schedule text. Forecasts rebase their suffix onto the
// caller's schedule; no organs, stock, XP, buffs, financial totals or policy flags
// are discarded. In particular, expected/minimum adventures are not rounded.
string barfDietExactStateKey(barfTwoDayState s){
    string key=s.fullness+":"+s.drunkenness+":"+s.spleen+":"+s.adventures+":"+s.minimumAdventures
        +":"+s.mask+":"+s.stooper+":"+s.sweat+":"+s.pantsSweat+":"+s.yetiXP+":"+s.yetiDouble
        +":"+s.noodles+":"+s.milk+":"+s.spork+":"+s.aioli+":"+s.whet+":"+s.shotglass
        +":"+s.turns+":"+s.income+":"+s.cost+":"+s.cash+":"+s.finished+":"+s.chestXP
        +":"+s.earlyJillTurns+":"+s.liquidIncome+":"+s.trainingCost+":"+s.trainingOpportunity
        +barfDietEffectKey(s,true);
    foreach name,used in s.uses if(used!=0)key+=":"+length(name)+":"+name+"="+used;
    return key;
}
string barfDietFillStateClass(barfTwoDayState s){
    barfTwoDayState normalized=barfDietClone(s);
    normalized.adventures=0;normalized.minimumAdventures=0;
    normalized.income=0;normalized.cost=0;normalized.cash=0;normalized.liquidIncome=0;
    return barfDietExactStateKey(normalized);
}
boolean barfDietFillDominates(barfTwoDayState a,barfTwoDayState b){
    // Buffs and their remaining durations, XP, gear and resource usage must
    // match before comparing finances. A future benefit cannot be priced away.
    if(barfDietFillStateClass(a)!=barfDietFillStateClass(b))return false;
    float netA=a.income-a.cost;float netB=b.income-b.cost;
    // cash is cumulative purchase spending, not the remaining wallet balance.
    return a.adventures>=b.adventures&&a.minimumAdventures>=b.minimumAdventures
        &&a.cash<=b.cash&&a.liquidIncome>=b.liquidIncome&&netA>=netB;
}

int barfDietTrainingSongXP(){return 5;}
barfTwoDayState barfDietFarmState(barfTwoDayState source,int paid){
    barfTwoDayState s=barfDietClone(source);
    if (!barfDietFarmLegal(s,paid)){s.cash=-1;return s;}
    if(source.uses["allCool"]>0&&barfDietDuration(source,$effect[Looking Cool])<paid){s.cash=-1;return s;}
    int chargeTarget=s.uses["trainingOverride"]>0?s.uses["yetiGoal"]:barfSetting("YetiXP",2000);
    s.uses["yetiHighWater"]=max(s.uses["yetiHighWater"],s.yetiXP);
    if(s.yetiXP>=chargeTarget)s.uses["yetiCharged"]=1;
    int remaining=paid;int segment=0;int segmentStage=barfDietStageKey(s);
    if(barfDietShareFarmForecasts){
        string key=barfDietExactStateKey(source);
        if(key!=barfDietFarmParentKey){clear(barfDietFarmPrefixes);barfDietFarmParentKey=key;}
        int best=0;foreach n,prefix in barfDietFarmPrefixes if(n<=paid&&n>best)best=n;
        if(best>0){
            barfDietFarmPrefix prefix=barfDietFarmPrefixes[best];s=barfDietClone(prefix.state);
            s.schedule=source.schedule+s.schedule;remaining=paid-best;segment=prefix.segment;segmentStage=prefix.stage;
        }
    }
    while(remaining>0){
        int nextStage=barfDietStageKey(s);
        if(nextStage!=segmentStage){
            if(segment>0)s.schedule+="farm\t"+segment+"\t"+segmentStage+"\n";
            segment=0;segmentStage=nextStage;
        }
        barfTwoDayStage stage=barfDietStage(s);
        int block=1;
        if(stage.farmer!=$familiar[Chest Mimic]&&stage.farmer!=$familiar[Cooler Yeti]){
            block=remaining;
            foreach id,left in s.effects if(left>0){
                block=min(block,left);int cap=barfDietVariableEffectCap(to_effect(id));
                if(cap>0)block=min(block,left>cap?left-cap:1);
            }
            if(s.mask==0&&!s.stooper&&s.turns<s.earlyJillTurns)block=min(block,s.earlyJillTurns-s.turns);
        }
        // A truncated normal block cannot be reused for a longer horizon: doing so
        // changes floating-point addition grouping. Trainer turns and complete
        // effect-expiry blocks preserve the original arithmetic and row grouping.
        foreach it in $items[ghost pepper,Gets-You-Drunk]{
            int due=barfDietTurnsToDelayedAdventure(s,it);
            if(due>0&&due<=block)block=due;
        }
        boolean reusable=stage.farmer==$familiar[Chest Mimic]||stage.farmer==$familiar[Cooler Yeti]||block<remaining;
        int combats=barfDietForecastCombats(s.turns,block);
        boolean combat=combats>0;
        if(stage.farmer==$familiar[Chest Mimic]||stage.farmer==$familiar[Cooler Yeti]){
            float costBefore=s.cost;
            s.uses[stage.farmer==$familiar[Chest Mimic]?"chestTrainingTurns":"yetiTrainingTurns"]+=block;
            foreach it in $items[white candy heart,deviled candy egg,pulled blue taffy]{
                effect buff=effect_modifier(it,"Effect");
                int target=it==$item[pulled blue taffy]?51:1;
                while(barfDietDuration(s,buff)<target){
                    int price=barfDietCurrentPrice(it);if(price<0){s.cash=-1;return s;}
                    s.cost+=price;s.cash+=barfDietStockCash(s,it,1,price);s.effects[to_int(buff)]+=round(numeric_modifier(it,"Effect Duration"));
                    s.uses["trainer:"+to_int(it)]+=1;
                }
            }
            if(have_skill($skill[Curiosity of Br'er Tarrypin])&&barfDietDuration(s,$effect[Curiosity of Br'er Tarrypin])==0)
                s.effects[to_int($effect[Curiosity of Br'er Tarrypin])]=turns_per_cast($skill[Curiosity of Br'er Tarrypin]);
            if(combat){
                s.uses["trainingCombats"]+=combats;
                float xp=stage.experience+barfDietTrainingSongXP();
                foreach ef,t in barfTwoDayInitialEffects if(t>0)xp+=barfDietEffectAt(ef,barfDietDuration(s,ef)).experience-barfDietEffectAt(ef,t).experience;
                foreach id,t in s.effects if(t>0&&!(barfTwoDayInitialEffects contains to_effect(id)))xp+=barfDietEffectAt(to_effect(id),t).experience;
                if(stage.farmer==$familiar[Chest Mimic])s.chestXP+=max(1,floor(xp));else{
                    s.yetiXP+=max(1,floor(xp));s.uses["yetiHighWater"]=max(s.uses["yetiHighWater"],s.yetiXP);if(s.yetiXP>=chargeTarget)s.uses["yetiCharged"]=1;
                }
                // Explicit forecast input; actual song usage must be checked against the combat log.
                int songs=1;int price=barfDietCurrentPrice($item[love song of icy revenge]);
                if(price<0){s.cash=-1;return s;}s.cost+=songs*price;s.cash+=barfDietStockCash(s,$item[love song of icy revenge],songs,price);
                s.uses["trainingSongs"]+=songs;s.uses["trainingSongXP"]+=barfDietTrainingSongXP();s.pantsSweat=min(100,s.pantsSweat+1);
            }
            s.trainingCost+=s.cost-costBefore;
            s.trainingOpportunity+=block*(barfDietRateAtStage(s,barfDietFarmingStage(s))-barfDietRateAtStage(s,stage));
        }
        s.uses[barfDietDuration(s,$effect[Looking Cool])>0?"coolCovered":"coolUncovered"]+=block;
        float rate=barfDietRateAtStage(s,stage);s.income+=block*rate;
        s.liquidIncome+=block*barfDietLiquidRate(s,stage);
        foreach id,left in s.effects s.effects[id]=max(0,left-block);
        if(combat&&available_amount($item[tiny stillsuit])>0)s.sweat+=combats*(stage.familiarGear==$item[tiny stillsuit]?3:1);
        s.adventures-=block;
        s.minimumAdventures=s.uses["forecastMode"]>0
            ?max(max(0,200-barfTwoDayRollover-barfDietNightcapMinimum()),s.minimumAdventures-block):s.minimumAdventures-block;
        foreach it in $items[ghost pepper,Gets-You-Drunk]{
            string key=barfDietDelayedAdventureKey(it);int pending=s.uses[key+":combats"];
            if(pending<=0)continue;
            pending-=combats;
            if(pending<=0){
                s.adventures+=s.uses[key+":averageHalf"]/2.0;
                s.minimumAdventures+=s.uses[key+":minimum"];
                s.uses[key+":combats"]=0;s.uses[key+":averageHalf"]=0;s.uses[key+":minimum"]=0;
            }else s.uses[key+":combats"]=pending;
        }
        s.turns+=block;remaining-=block;segment+=block;
        if(barfDietShareFarmForecasts&&reusable&&!(barfDietFarmPrefixes contains (paid-remaining))){
            barfDietFarmPrefix prefix;prefix.state=barfDietClone(s);
            prefix.state.schedule=substring(s.schedule,length(source.schedule));prefix.segment=segment;prefix.stage=segmentStage;
            barfDietFarmPrefixes[paid-remaining]=prefix;
        }
    }
    if(segment>0)s.schedule+="farm\t"+segment+"\t"+segmentStage+"\n";
    // Quantity accounting only: refresh just before a paid encounter when empty.
    // Existing duration is free; each guide supplies 20 turns at the agreed 100 Meat.
    int guides=ceil(max(0,paid-source.uses["touristTurns"])/20.0);
    s.uses["touristTurns"]=max(0,source.uses["touristTurns"]+20*guides-paid);
    s.uses["touristGuides"]+=guides;s.cost+=100*guides;
    s.cash+=barfDietStockCash(s,$item[How to Avoid Scams],guides,100);
    return s;
}

boolean barfDietWineRingLegal(barfTwoDayState s,int liver){
    if(available_amount($item[mafia pinky ring])==0)return false;
    if(!barfDietBit(s.mask,1)||!barfDietBit(s.mask,2)||!barfDietBit(s.mask,3))return true;
    barfTwoDayStage stage=barfDietStage(s);
    return s.fullness<=stage.fullness+s.uses["extraFullness"]-1
        ||s.drunkenness+liver-(liver==1&&s.shotglass>0?1:0)<=stage.drunkenness+s.uses["extraLiver"]-1;
}
boolean barfDietTuxLegal(barfTwoDayState s){
    return available_amount($item[tuxedo shirt])>0
        &&(!barfDietBit(s.mask,0)||s.fullness<=barfDietStage(s).fullness+s.uses["extraFullness"]-1);
}

float barfDietYield(item it,int base,barfTwoDayState s){
    float result=base;
    if(it.adventures=="0"||it.adventures=="")return result;
    if (it.fullness>0){
        if (have_skill($skill[Gourmand])||have_skill($skill[Neurogourmet])) result+=it.fullness;
        if (barfDietDuration(s,$effect[Song of the Glorious Lunch])>=it.fullness||barfDietDuration(s,$effect[Barrel of Laughs])>=max(5,it.fullness)) result+=it.fullness;
        if(s.uses["munchies"]<get_property("munchiesPillsUsed").to_int())result+=max(1,(12-base)/3);
        if (contains_text(it.notes,"PIZZA")&&have_skill($skill[Pizza Lover])) result+=it.fullness;
        if (contains_text(it.notes,"SAUCY")&&have_skill($skill[Saucemaven])) result+=$classes[Pastamancer,Sauceror] contains my_class()?5:3;
        if (contains_text(it.notes,"LASAGNA") && barfDietDuration(s,$effect[Gar-ish])>0 && format_date_time("yyyyMMdd",today_to_string(),"EEE")!="Mon") result+=5;
        if (contains_text(it.notes,"BEANS")&&have_skill($skill[Beanweaver])) result+=2;
    } else if (it.inebriety>0){
        if (contains_text(it.notes,"WINE")){
            if (barfDietDuration(s,$effect[Refined Palate])>0) result=floor(result*1.25);
            if (barfDietWineRingLegal(s,it.inebriety)) result+=floor(result*0.125)+((result*0.125-floor(result*0.125)>0.5 || (result*0.125-floor(result*0.125)==0.5 && floor(result*0.125)%2==1))?1:0);
        }
        if (contains_text(it.notes,"MARTINI")&&barfDietTuxLegal(s)) result+=2;
        if (have_skill($skill[The Ode to Booze])) result+=it.inebriety;
        if (have_skill($skill[Rowdy Drinker])||barfDietDuration(s,$effect[Beer Barrel Polka])>=max(5,it.inebriety)) result+=it.inebriety;
    }
    return result;
}


boolean barfDietPrepReplaces(effect buff){
    // These are explicitly refreshed by FKPrep; retaining them does not add pounds.
    return $effects[Robot Friends,Healthy Green Glow,Chorale of Companionship,Human-Fish Hybrid,Whole Latte Love,
        Shortly Stacked,Thoughtful Empathy,Leash of Linguini,Blood Bond,Empathy,Black Tongue,Man's Worst Enemy,
        Kindly Resolve,Human-Machine Hybrid,Shrimpin' Ain't Easy,Over-Familiar With Dactyls,Loyal Tea,Warm Shoulders,
        One Foot Heavier,Work For Hours a Week,Panna Consideration,Loyal as a Rock,Candied Devil,Wildsun Boon,
        Only Dogs Love a Drunken Sailor,Best Pals,Heart of Green,Bestial Sympathy,Herder\, Bitter\, Fester\, Stranger,
        Party Soundtrack,Shortly Wired,Crocodile Tear,Spiced Out,Offhand Remarkable,Billiards Belligerence,
        A Girl Named Sue,Blue Swayed,Heart of White] contains buff;
}
boolean barfDietCanRetain(effect buff){
    return buff!=$effect[none]&&numeric_modifier(buff,"Familiar Weight")>0&&!barfDietPrepReplaces(buff)
        &&!boolean_modifier(buff,"Lasts Until Rollover")&&numeric_modifier(buff,"Thorns")==0
        &&numeric_modifier(buff,"Damage Aura")==0&&numeric_modifier(buff,"Sporadic Damage Aura")==0;
}
boolean barfDietHasDelayedAdventures(item it){
    return it==$item[ghost pepper]||it==$item[Gets-You-Drunk];
}
boolean barfDietLowQuality(item it){
    return (it.fullness>0||it.inebriety>0)&&$strings[crappy,decent,good] contains it.quality.to_lower_case();
}
boolean barfDietQualityAllowed(item it){
    return it==$item[Affirmation Cookie]||!barfDietLowQuality(it)||barfDietCanRetain(effect_modifier(it,"Effect"))||barfDietHasDelayedAdventures(it);
}

void barfDietBuildItems(){
    clear(barfTwoDayItems);clear(barfDietCandidateDetails);clear(barfDietCandidateStatus);
    foreach it in $items[]{
        if (it.fullness+it.inebriety+it.spleen<=0)continue;
        if(it==$item[Instant Karma]){barfDietCandidateStatus[it]="Excluded by preference";continue;}
        if(it.levelreq>my_level()){barfDietCandidateStatus[it]="Level requirement";continue;}
        if(!is_unrestricted(it)){barfDietCandidateStatus[it]="Restricted item";continue;}
        if($items[shadow hot dog,shadow pill] contains it){
            barfDietCandidateStatus[it]="Excluded Shadow Forge option; only shadow martini is modeled";continue;
        }
        if(!barfDietQualityAllowed(it)){
            barfDietCandidateStatus[it]="Good-or-lower quality without a useful retained weight effect";continue;
        }
        if (!it.tradeable&&barfDietOwnedAmount(it)==0&&!barfDietCanCraft(it)){
            barfDietCandidateStatus[it]="Untradeable and not owned/craftable";continue;
        }
        if (it==$item[vintage smart drink]){barfDietCandidateStatus[it]="Reserved final nightcap";continue;}
        if(it==$item[ghost pepper]&&(get_property("ghostPepperTurnsLeft").to_int()>0
            ||my_hp()<1500||numeric_modifier("Hot Resistance")<9)){
            barfDietCandidateStatus[it]="Ghost pepper already active or safety requirements unmet";continue;
        }
        if(it==$item[Gets-You-Drunk]&&(get_property("getsYouDrunkTurnsLeft").to_int()>0
            ||my_hp()<1500||numeric_modifier("Spooky Resistance")<9)){
            barfDietCandidateStatus[it]="Gets-You-Drunk already active or safety requirements unmet";continue;
        }
        // Other delayed/cancelling payouts and variable organ changes need separate verified handlers.
        if ($items[s'more,astral hot dog,astral pilsner] contains it){
            barfDietCandidateStatus[it]="Unsupported delayed/variable consumption";continue;
        }
        string notes=it.notes;
        if (contains_text(notes,"Vampyre")||contains_text(notes,"KOLHS")||contains_text(notes,"Zombie Slayer")){
            barfDietCandidateStatus[it]="Path-specific consumption";continue;
        }
        string[int] bounds=split_string(it.adventures,"-");
        if (it.adventures!=""&&!create_matcher("^[0-9]+(?:-[0-9]+)?$",it.adventures).find()){
            barfDietCandidateStatus[it]="Unsupported adventure formula";continue;
        }
        barfTwoDayItem entry;
        entry.target=it;entry.fullness=it.fullness;entry.drunkenness=it.inebriety;entry.spleen=it.spleen;
        int lo=it.adventures==""?0:bounds[0].to_int();int hi=count(bounds)>1?bounds[1].to_int():lo;
        // User's established cookie assumption: nine base adventures, once per day.
        if(it==$item[Affirmation Cookie]){lo=9;hi=9;}
        entry.minimum=lo;entry.average=(lo+hi)/2.0;
        if(barfDietHasDelayedAdventures(it)){
            entry.delayedCombats=4;entry.delayedMinimum=lo;entry.delayedAverage=(lo+hi)/2.0;
            entry.dailyRemaining=1;
        }
        entry.buff=effect_modifier(it,"Effect");entry.duration=round(numeric_modifier(it,"Effect Duration"));
        int cached=historical_price(it);
        // Broad scan, with cached dominance screening to avoid thousands of fruitless mall requests.
        if (it.tradeable&&cached<=0&&barfDietOwnedAmount(it)==0&&npc_price(it)<=0&&it!=$item[Hot Socks]&&it!=$item[Dreadsylvanian cold-fashioned]&&!barfDietCanCraft(it)){
            barfDietCandidateStatus[it]="No cached price and no owned supply";continue;
        }
        if (it!=$item[Dreadsylvanian cold-fashioned]&&cached>barfSetting("DietMaxItemPrice",500000)&&barfDietOwnedAmount(it)==0){
            barfDietCandidateStatus[it]="Above configured item-price cap";continue;
        }
        if (it!=$item[Dreadsylvanian cold-fashioned]&&cached>0&&(entry.average+entry.delayedAverage)*12000
            +max(0,numeric_modifier(entry.buff,"Familiar Weight"))*barfTwoDayWeightCalibration<cached
            &&numeric_modifier(entry.buff,"Meat Drop")<=0&&barfDietEffect(entry.buff).experience<=0){barfDietCandidateStatus[it]="Cached cost exceeds generous yield/buff screen";continue;}
        entry.price=it==$item[Hot Socks]?5000:barfDietCurrentPrice(it);
        if(barfDietCanCraft(it)){
            int[item] recipe=get_ingredients(it);int cost=0;boolean craft=count(recipe)>0;
            foreach part,q in recipe{int p=barfDietCurrentPrice(part);if(p<0||(!part.tradeable&&barfDietOwnedAmount(part)<q&&!barfDietCanCraft(part)))craft=false;cost+=max(0,p)*q;}
            int fee=craft_type(it)=="Meatpasting"&&!knoll_available()?10:0;
            if(craft&&(!it.tradeable||entry.price<0||cost+fee<entry.price)){
                entry.price=cost+fee;entry.crafted=true;foreach part,q in recipe entry.ingredients[part]=q;
            }
        }
        if (entry.price<0){barfDietCandidateStatus[it]="No usable current price or recipe";continue;}
        entry.dailyGroup=barfDietDailyGroups[it];
        int already=barfDietDailyUsed(entry.dailyGroup);
        entry.dailyRemaining=entry.dailyGroup==""?100:max(0,barfDietDailyLimits[it]-already);
        if ((!it.tradeable||!barfDietBuyable[it])&&!entry.crafted&&it!=$item[Hot Socks])entry.dailyRemaining=min(entry.dailyRemaining,barfDietOwnedAmount(it));
        if(barfDietHasDelayedAdventures(it))entry.dailyRemaining=min(entry.dailyRemaining,1);
        if (entry.dailyRemaining<=0){barfDietCandidateStatus[it]="No remaining daily uses or stock";continue;}
        if(it==$item[Dreadsylvanian cold-fashioned])entry.dailyRemaining=1;
        if (it==$item[spaghetti breakfast]&&my_fullness()>0){barfDietCandidateStatus[it]="Breakfast requires empty stomach";continue;}
        if (it==$item[extra-greasy slider])entry.special="slider";
        if (it==$item[jar of fermented pickle juice])entry.special="pickle";
        if (it==$item[Mr. Burnsger])entry.special="burnsger";
        if (it==$item[Doc Clock's thyme cocktail])entry.special="thyme";
        if ($items[Tubetto Gelatto,Gnocci Domani,Formica e Pepe] contains it)entry.special="noodles";
        if (it==$item[Extrovermectin&trade;])entry.special="extro";
        if (it==$item[body spradium]&&barfDietOwnedAmount(it)==0){barfDietCandidateStatus[it]="Body spradium requires owned supply";continue;}
        if (it==$item[Hot Socks]){
            if(creatable_amount(it)==0){barfDietCandidateStatus[it]="Speakeasy drink unavailable";continue;}
            entry.price=5000;entry.special="speakeasy";
        }
        if (entry.average==0&&numeric_modifier(entry.buff,"Meat Drop")<=0
            &&numeric_modifier(entry.buff,"Familiar Weight")<=0&&barfDietEffect(entry.buff).experience<=0&&entry.special==""){
            barfDietCandidateStatus[it]="No modeled adventure/Meat/weight/XP benefit";continue;
        }
        barfTwoDayItems[count(barfTwoDayItems)]=entry;
        barfDietCandidateDetails[it]=entry;barfDietCandidateStatus[it]="Regular-fill shortlist";
    }
    if(have_skill($skill[Sweet Synthesis])){
        item[int] pair=barfSynthesisCandies();int price=0;boolean valid=count(pair)==2;
        foreach i,it in pair{int p=barfDietCurrentPrice(it);if(p<0||it==$item[none])valid=false;price+=max(0,p);}
        if(valid){barfTwoDayItem e;foreach i,it in pair e.ingredients[it]+=1;e.spleen=1;e.price=price;e.dailyRemaining=100;e.special="synthesis";e.buff=$effect[Synthesis: Greed];e.duration=30;barfTwoDayItems[count(barfTwoDayItems)]=e;}
    }
    // Verified zero-turn COMBINE recipes compete with buying; other crafting methods are excluded.
    barfTwoDayWarnings+="Candidates: native level-eligible, unrestricted consumables; current prices refreshed for cached/owned survivors. Ghost pepper and Gets-You-Drunk include their second adventure payout after four modeled combats; other delayed payouts and unsupported variable consumables are excluded. Tradeable stock has an opportunity cost, with unlimited NPC prices capping replacement value; unavailable listings do not become free purchases. Untradeable recipe items, including owned meals and shadow martinis, carry ingredient opportunity costs. COMBINE and basic COOK recipes can supply missing copies; paid/fancy cooking and Forge acquisition are excluded.\n";
}

barfTwoDayState barfDietInitialState(){
    barfTwoDayState s;
    s.fullness=my_fullness();s.drunkenness=my_inebriety();s.spleen=my_spleen_use();
    s.adventures=my_adventures();s.minimumAdventures=my_adventures();s.sweat=get_property("familiarSweat").to_int();
    s.uses["touristTurns"]=have_effect($effect[How to Scam Tourists]);
    s.pantsSweat=get_property("sweat").to_int();s.yetiXP=$familiar[Cooler Yeti].experience;s.chestXP=$familiar[Chest Mimic].experience;
    s.earlyJillTurns=0;foreach ef,t in my_effects()if(t>0&&t<=5&&numeric_modifier(ef,"Familiar Weight")>0)s.earlyJillTurns=max(s.earlyJillTurns,t);
    s.yetiDouble=!get_property("_coolerYetiAdventures").to_boolean();s.uses["yetiHighWater"]=s.yetiXP;
    if(s.yetiXP>=barfSetting("YetiXP",2000))s.uses["yetiCharged"]=1;
    if(get_property("_teresBarfPlanDay")==today_to_string()){
        s.uses["yetiHighWater"]=max(s.yetiXP,get_property("_teresBarfPlanYetiHighWater").to_int());
        if(get_property("_teresBarfPlanYetiCharged").to_boolean())s.uses["yetiCharged"]=1;
        foreach i,id in split_string(get_property("_teresBarfPlanRetained"),",")if(id.to_int()>0)s.retained[id.to_int()]=true;
    }
    s.noodles=get_property("legendaryNoodlesStomach").to_int();s.milk=get_property("milkOfMagnesiumActive").to_boolean()?1:0;
    if(s.milk>0)s.uses["milk"]=1;
    s.spork=get_property("_fudgeSporkUsed").to_boolean()?0:1;s.aioli=get_property("miniKiwiAiolisUsed").to_int();
    s.whet=get_property("whetstonesUsed").to_int();s.shotglass=available_amount($item[mime army shotglass])>0&&!get_property("_mimeArmyShotglassUsed").to_boolean()?1:0;
    foreach ef,turns in my_effects()if(barfDietRelevantEffect(ef)){s.effects[to_int(ef)]=turns;barfTwoDayInitialEffects[ef]=turns;}
    foreach i,it in barfTwoDayCapacityItems if(have_equipped(it))s.mask+=(2**i).to_int();
    s.stooper=my_familiar()==$familiar[Stooper];s.uses["forecastMode"]=1;
    return s;
}

float barfDietScore(barfTwoDayState s);
float barfDietMarginalAdventure(barfTwoDayState source,float minimum,float average){
    barfTwoDayState s=barfDietClone(source);s.minimumAdventures+=minimum;s.adventures+=average;
    float before=barfDietScore(s);s.minimumAdventures+=1;s.adventures+=1;
    return max(0,barfDietScore(s)-before);
}
barfTwoDayState barfDietConsumeState(barfTwoDayState source,barfTwoDayItem entry,boolean retain,int yeti,boolean bare){
    barfTwoDayState rejected;rejected.cash=-1;
    barfTwoDayStage stage=barfDietStage(source);
    string key=entry.dailyGroup==""?(entry.special=="synthesis"?"synthesis":to_string(entry.target)):entry.dailyGroup;
    int used=source.uses[key];
    if (used>=entry.dailyRemaining||source.finished)return rejected;
    int liver=entry.drunkenness;
    boolean shot=liver==1&&source.shotglass>0;
    if (shot)liver=0;
    if (source.fullness+entry.fullness>stage.fullness+source.uses["extraFullness"]||source.drunkenness+liver>stage.drunkenness+source.uses["extraLiver"]||source.spleen+entry.spleen>stage.spleen)return rejected;
    if (entry.target==$item[spaghetti breakfast]&&source.fullness>0)return rejected;
    if ((entry.special=="slider"||entry.special=="pickle")&&source.spleen<5)return rejected;
    if (entry.special=="burnsger"&&source.drunkenness<2)return rejected;
    if (entry.special=="thyme"&&source.fullness<2)return rejected;
    if(entry.target.inebriety>0&&yeti>0&&(source.yetiXP<(yeti==2?400:225)||(!source.yetiDouble&&yeti==2)))return rejected;
    if(source.uses["coldRequired"]>0&&yeti==2&&entry.target!=$item[Dreadsylvanian cold-fashioned])return rejected;
    if(source.uses["allCool"]>0&&entry.target==$item[Dreadsylvanian cold-fashioned]&&yeti!=2)return rejected;
    barfTwoDayState s=barfDietClone(source);
    if (entry.special=="extro"){
        if(get_property("beGregariousCharges").to_int()>0||get_property("beGregariousFightsLeft").to_int()>0){s.cash=-1;return s;}
        float copied=get_property("teresBarfCopiedGoblinMeat").to_float();
        float weight=barfTwoDayCopiedWeight;
        foreach ef,t in barfTwoDayInitialEffects if(t>0&&barfDietDuration(s,ef)==0)weight-=numeric_modifier(ef,"Familiar Weight");
        foreach id,t in s.effects if(t>0&&!(barfTwoDayInitialEffects contains to_effect(id)))weight+=numeric_modifier(to_effect(id),"Familiar Weight");
        if (s.mask!=0||s.stooper||copied<=0||max(weight-get_property("teresBarfCopiedGoblinWeight").to_int(),get_property("teresBarfCopiedGoblinWeight").to_int()-weight)>=1){s.cash=-1;return s;}
        s.income+=3*copied;s.liquidIncome+=3*copied;s.sweat+=available_amount($item[tiny stillsuit])>0?3:0;
    }
    float minimum=0;float mean=0;
    string[int] bounds=split_string(entry.target.adventures,"-");
    int lo=entry.minimum.to_int();int hi=count(bounds)>1?bounds[1].to_int():lo;
    if(entry.target==$item[Affirmation Cookie]){lo=9;hi=9;}
    if (entry.target.inebriety>0&&yeti>0){
        if (s.yetiXP<(yeti==2?400:225)||(!s.yetiDouble&&yeti==2)){s.cash=-1;return s;}
        int xp=yeti==2?400:225;s.yetiXP-=xp;s.uses["yetiXPSpent"]+=xp;
        if(yeti==2&&entry.target==$item[Dreadsylvanian cold-fashioned])s.uses["coldRequired"]=0;
        if(yeti==2){s.yetiDouble=false;s.uses["yetiDoubles"]+=1;}
        else{
            s.effects[to_int($effect[Looking Cool])]+=100;
            int n=++s.uses["coolRefreshes"];
            s.uses["coolRefreshTurn:"+n]=s.turns;s.uses["coolRefreshDuration:"+n]=barfDietDuration(s,$effect[Looking Cool]);
        }
    }
    for raw from lo to hi{
        float gain=barfDietYield(entry.target,raw,s);
        if(yeti==2)gain+=raw;
        if(raw==lo)minimum=gain;
        mean+=gain/max(1,hi-lo+1);
    }
    string prep="";
    if(entry.drunkenness>0&&have_skill($skill[The Ode to Booze]))prep+="Ode;";
    if(entry.drunkenness>0&&contains_text(entry.target.notes,"WINE")&&barfDietWineRingLegal(source,entry.drunkenness))prep+="mafia pinky ring;";
    if(entry.drunkenness>0&&contains_text(entry.target.notes,"MARTINI")&&barfDietTuxLegal(source))prep+="tuxedo shirt;";
    float rate=0;
    // Only newly acquired helpers use this rate; bare mode cannot acquire any.
    if(!bare&&entry.average>0&&(entry.fullness>0||entry.drunkenness>0))
        rate=s.uses["marginalHelpers"]>0?barfDietMarginalAdventure(s,minimum,mean):barfDietRateAtStage(s,barfDietFarmingStage(s));
    if(!bare&&entry.average>0&&(entry.fullness>0||entry.drunkenness>0)){
        item helper=entry.fullness>0?$item[Ol' Scratch's salad fork]:$item[Frosty's frosty mug];
        string limit=entry.fullness>0?"_saladForkUsed":"_frostyMugUsed";
        float factor=contains_text(entry.target.notes,entry.fullness>0?"SALAD":"BEER")?1.5:1.3;
        float extraMean=0;float extraMinimum=0;
        for raw from lo to hi{
            float extra=floor(raw*(yeti==2?2:1)*factor)-raw*(yeti==2?2:1);
            extraMean+=extra/max(1,hi-lo+1);if(raw==lo)extraMinimum=extra;
        }
        int price=barfDietCurrentPrice(helper);
        float sporkValue=0;
        if(s.uses["marginalHelpers"]>0&&entry.fullness>0&&s.spork>0&&s.uses["noSpork"]==0){
            int p=barfDietCurrentPrice($item[fudge spork]);if(p>=0)sporkValue=max(0,3*rate-p);
        }
        if(!get_property(limit).to_boolean()&&s.uses[limit]==0&&price>=0&&extraMean*rate-price>sporkValue){
            minimum+=extraMinimum;mean+=extraMean;s.cost+=price;s.cash+=barfDietStockCash(s,helper,1,price);s.uses[limit]=1;
            prep+=entry.fullness>0?"fork;":"mug;";
        }
    }
    if(entry.fullness>0&&entry.average>0){
        if(s.uses["munchies"]<get_property("munchiesPillsUsed").to_int())s.uses["munchies"]+=1;
        if(s.milk>0){minimum+=5;mean+=5;s.milk=0;prep+="milk active;";}
        if(!bare&&s.aioli==0){int p=barfDietCurrentPrice($item[mini kiwi aioli]);if(p>=0&&p<entry.fullness*rate){s.cost+=p;s.cash+=barfDietStockCash(s,$item[mini kiwi aioli],1,p);s.aioli=1;prep+="aioli;";}}
        if(s.aioli>0){minimum+=entry.fullness;mean+=entry.fullness;s.aioli-=1;}
        if(!bare&&s.whet==0&&s.uses["noWhet"]==0){int p=barfDietCurrentPrice($item[whet stone]);if(p>=0&&p<rate){s.cost+=p;s.cash+=barfDietStockCash(s,$item[whet stone],1,p);s.whet=1;prep+="whet;";}}
        if(s.whet>0){minimum+=1;mean+=1;s.whet-=1;}
        if(!bare&&s.spork>0&&s.uses["noSpork"]==0&&!contains_text(prep,"fork;")){int p=barfDietCurrentPrice($item[fudge spork]);if(p>=0&&p<3*rate){s.cost+=p;s.cash+=barfDietStockCash(s,$item[fudge spork],1,p);minimum+=3;mean+=3;s.spork=0;prep+="spork;";}}
    }
    if(entry.fullness>0&&entry.average>0){
        item seasoning=$item[special seasoning];int price=barfDietCurrentPrice(seasoning);
        boolean stocked=barfDietOwnedAmount(seasoning)-s.uses["stock:"+to_int(seasoning)]>0;
        float gain=hi-lo<=1?1:0.5;
        if(price>=0&&(stocked||(!bare&&gain*rate>price))){
            minimum+=1;mean+=gain;s.cost+=price;s.cash+=barfDietStockCash(s,seasoning,1,price);prep+="seasoning;";
        }
    }
    if(entry.drunkenness>0&&contains_text(entry.target.notes,"BEER")&&barfDietDuration(s,$effect[Salty Mouth])>0){
        minimum+=4;mean+=5;s.effects[to_int($effect[Salty Mouth])]=0;
    }
    int duration=entry.duration;
    if(entry.fullness>0&&s.noodles>0){duration*=2;s.noodles-=1;}
    if(entry.special=="noodles")s.noodles+=3;
    if(entry.special=="slider"||entry.special=="pickle")s.spleen-=5;
    if(entry.special=="burnsger")s.drunkenness-=2;
    if(entry.special=="thyme")s.fullness-=2;
    s.fullness+=entry.fullness;s.drunkenness+=liver;s.spleen+=entry.spleen;
    if(shot)s.shotglass=0;
    if(barfDietRelevantEffect(entry.buff))s.effects[to_int(entry.buff)]+=duration;
    if(retain&&barfDietCanRetain(entry.buff))s.retained[to_int(entry.buff)]=true;
    s.adventures+=mean;s.minimumAdventures+=minimum;s.cost+=entry.price;s.uses[key]+=1;
    if(entry.delayedCombats>0){
        string delayedKey=barfDietDelayedAdventureKey(entry.target);
        s.uses[delayedKey+":combats"]=entry.delayedCombats;
        s.uses[delayedKey+":minimum"]=entry.delayedMinimum;
        s.uses[delayedKey+":averageHalf"]=round(entry.delayedAverage*2);
        s.uses["delayedAdventurePlan"]=1;
    }
    if(entry.crafted){
        int cash=barfDietCraftCash(s,entry.target,1,entry.target.tradeable,0);
        if(cash<0){s.cash=-1;return s;}s.cash+=cash;
    }else if(entry.special=="synthesis"){
        foreach part,q in entry.ingredients{
            if((!part.tradeable||((barfDietBuyable contains part)&&!barfDietBuyable[part]))&&s.uses["stock:"+to_int(part)]+q>barfDietOwnedAmount(part)){s.cash=-1;return s;}
            s.cash+=barfDietStockCash(s,part,q,barfDietCurrentPrice(part));
        }
    }else s.cash+=barfDietStockCash(s,entry.target,1,entry.price);
    s.schedule+="consume\t"+to_int(entry.target)+"\t"+(bare?"bare;":"")+prep+"\t"+yeti+"\t"+retain+"\t"+minimum+"\t"+mean+"\n";
    return s;
}

boolean barfDietBareMatches(barfTwoDayState source,barfTwoDayState prepared){
    // Bare mode only suppresses acquiring new helpers. Existing helper charges
    // and owned seasoning apply in both modes; the first offered schedule wins.
    if(prepared.cash<0)return false;
    foreach helper in $items[Ol' Scratch's salad fork,Frosty's frosty mug,milk of magnesium,mini kiwi aioli,whet stone,fudge spork,special seasoning]{
        string key="stock:"+to_int(helper);
        if(prepared.uses[key]<=source.uses[key])continue;
        if(helper==$item[special seasoning]&&barfDietOwnedAmount(helper)>source.uses[key])continue;
        return false;
    }
    return true;
}

barfTwoDayState barfDietConsumeState(barfTwoDayState source,barfTwoDayItem entry,boolean retain,int yeti){
    return barfDietConsumeState(source,entry,retain,yeti,false);
}
barfTwoDayState barfDietConsumeBare(barfTwoDayState source,barfTwoDayItem entry,boolean retain,int yeti){
    return barfDietConsumeState(source,entry,retain,yeti,true);
}

void barfDietDailyTable(){
    barfDietDailyLimits[to_item(8820)]=1;
    barfDietDailyLimits[to_item(8824)]=1;
    barfDietDailyLimits[to_item(8817)]=1;
    barfDietDailyLimits[to_item(9166)]=3;
    barfDietDailyLimits[to_item(3326)]=1;
    barfDietDailyLimits[to_item(7593)]=3;
    barfDietDailyLimits[to_item(7590)]=3;
    barfDietDailyLimits[to_item(8822)]=1;
    barfDietDailyLimits[to_item(7598)]=3;
    barfDietDailyLimits[to_item(3324)]=1;
    barfDietDailyLimits[to_item(3398)]=1;
    barfDietDailyLimits[to_item(7596)]=3;
    barfDietDailyLimits[to_item(7595)]=3;
    barfDietDailyLimits[to_item(7592)]=3;
    barfDietDailyLimits[to_item(8818)]=1;
    barfDietDailyLimits[to_item(7597)]=3;
    barfDietDailyLimits[to_item(7599)]=3;
    barfDietDailyLimits[to_item(7594)]=3;
    barfDietDailyLimits[to_item(8821)]=1;
    barfDietDailyLimits[to_item(10525)]=1;
    barfDietDailyLimits[to_item(9966)]=1;
    barfDietDailyLimits[to_item(7589)]=3;
    barfDietDailyLimits[to_item(10446)]=1;
    barfDietDailyLimits[to_item(3325)]=1;
    barfDietDailyLimits[to_item(7591)]=3;
    barfDietDailyLimits[to_item(10992)]=1;
    barfDietDailyLimits[to_item(11000)]=1;
    barfDietDailyLimits[to_item(8816)]=1;
    barfDietDailyLimits[to_item(8823)]=1;
    barfDietDailyLimits[to_item(3323)]=1;
    barfDietDailyLimits[to_item(10991)]=1;
    barfDietDailyLimits[to_item(8819)]=1;
    barfDietDailyLimits[to_item(10207)]=1;
    barfDietDailyLimits[to_item(9486)]=1;
    barfDietDailyLimits[to_item(10447)]=1;
    barfDietDailyLimits[to_item(10445)]=1;
    barfDietDailyLimits[to_item(10448)]=1;
    barfDietDailyLimits[to_item(3327)]=1;
    barfDietDailyLimits[to_item(5459)]=1;
    barfDietDailyLimits[to_item(10060)]=23;
    barfDietDailyLimits[to_item(10227)]=1;
    barfDietDailyLimits[to_item(6616)]=1;
    barfDietDailyLimits[to_item(3131)]=1;
    barfDietDailyGroups[to_item(8820)]="_authorsInkUsed";
    barfDietDailyGroups[to_item(8824)]="_inquisitorsUnidentifiableObjectUsed";
    barfDietDailyGroups[to_item(8817)]="_mansquitoSerumUsed";
    barfDietDailyGroups[to_item(9166)]="_turkeyBlastersUsed";
    barfDietDailyGroups[to_item(3326)]="_voodooSnuffUsed";
    barfDietDailyGroups[to_item(7593)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(7590)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(8822)]="_docClocksThymeCocktailDrunk";
    barfDietDailyGroups[to_item(7598)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(3324)]="_frostyMugUsed";
    barfDietDailyGroups[to_item(3398)]="_hodgmansBlanketDrunk";
    barfDietDailyGroups[to_item(7596)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(7595)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(7592)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(8818)]="_missGravesVermouthDrunk";
    barfDietDailyGroups[to_item(7597)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(7599)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(7594)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(8821)]="_madLiquorDrunk";
    barfDietDailyGroups[to_item(10525)]="_drippyPilsnerUsed";
    barfDietDailyGroups[to_item(9966)]="_everfullGlassUsed";
    barfDietDailyGroups[to_item(7589)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(10446)]="_drippyWineUsed";
    barfDietDailyGroups[to_item(3325)]="_pickleJuiceDrunk";
    barfDietDailyGroups[to_item(7591)]="_speakeasyDrinksDrunk";
    barfDietDailyGroups[to_item(10992)]="calzoneOfLegendEaten";
    barfDietDailyGroups[to_item(11000)]="deepDishOfLegendEaten";
    barfDietDailyGroups[to_item(8816)]="_kudzuSaladEaten";
    barfDietDailyGroups[to_item(8823)]="_mrBurnsgerEaten";
    barfDietDailyGroups[to_item(3323)]="_saladForkUsed";
    barfDietDailyGroups[to_item(10991)]="pizzaOfLegendEaten";
    barfDietDailyGroups[to_item(8819)]="_plumbersMushroomStewEaten";
    barfDietDailyGroups[to_item(9486)]="_affirmationCookieEaten";
    barfDietDailyGroups[to_item(10447)]="_drippyCaviarUsed";
    barfDietDailyGroups[to_item(10445)]="_drippyNuggetUsed";
    barfDietDailyGroups[to_item(10448)]="_drippyPlumUsed";
    barfDietDailyGroups[to_item(3327)]="_extraGreasySliderEaten";
    barfDietDailyGroups[to_item(5459)]="_fudgeSporkUsed";
    barfDietDailyGroups[to_item(10060)]="_sausagesEaten";
    barfDietDailyGroups[to_item(10227)]="_pirateForkUsed";
    barfDietDailyGroups[to_item(6616)]="_spaghettiBreakfastEaten";
    barfDietDailyGroups[to_item(3131)]="_mulliganStewEaten";
}


// Search operates on copies of runtime state; the revised entry points remain read-only.

int barfDietFullLimit(barfTwoDayState s){return barfDietStage(s).fullness+s.uses["extraFullness"];}
int barfDietLiverLimit(barfTwoDayState s){return barfDietStage(s).drunkenness+s.uses["extraLiver"];}
int barfDietSpleenLimit(barfTwoDayState s){return barfDietStage(s).spleen;}
float barfDietScore(barfTwoDayState s){
    if(s.cash<0)return -1000000000000.0;
    // Cache projected terms only; keep the original order of financial arithmetic.
    string key="";string effectKey="";
    if(barfDietMemoize){
        effectKey=barfDietEffectKey(s,true);
        key=s.mask+":"+s.stooper+":"+s.finished+":"+s.uses["forecastMode"]+":"+s.adventures+":"+s.minimumAdventures+":"+s.uses["touristTurns"]+effectKey
            +barfDietDelayedAdventureStateKey(s);
        if(barfDietFutureCache contains key)return (s.income-s.cost+barfDietTomorrowCache[key])+barfDietFutureCache[key];
    }
    float tomorrow=barfDietTomorrowValue(s);float score=s.income-s.cost+tomorrow;
    if(s.finished){
        if(barfDietMemoize){barfDietFutureCache[key]=0;barfDietTomorrowCache[key]=tomorrow;}
        return score;
    }
    float adventureBudget=max(0,(s.uses["forecastMode"]>0?s.adventures:s.minimumAdventures)
        -max(0,200-barfTwoDayRollover-barfDietNightcapMinimum()));
    float retentionBudget=1000000;
    foreach id,keep in s.retained if(keep)retentionBudget=min(retentionBudget,max(0,s.effects[id]-5));
    float budget=min(adventureBudget,retentionBudget);
    foreach it in $items[ghost pepper,Gets-You-Drunk]{
        int due=barfDietTurnsToDelayedAdventure(s,it);
        string delayedKey=barfDietDelayedAdventureKey(it);
        if(due>0&&due<=budget){
            float reward=s.uses["forecastMode"]>0?s.uses[delayedKey+":averageHalf"]/2.0:s.uses[delayedKey+":minimum"];
            budget=min(retentionBudget,budget+reward);
        }
    }
    // A projection's expiry losses depend on equipment and effects, not on the
    // adventure horizon. Reuse those coefficients without changing score arithmetic.
    string kernelKey=s.mask+":"+s.stooper+effectKey;
    barfDietScoreKernel kernel;
    if(barfDietMemoize&&(barfDietScoreKernels contains kernelKey)){
        kernel=barfDietScoreKernels[kernelKey];barfDietScoreKernelHits+=1;
    }else{
        barfDietScoreKernelMisses+=1;
        kernel.rate=barfDietRateAtStage(s,barfDietFarmingStage(s));
        float base=barfBaseMeat()+(get_property("boomBoxSong")=="Total Eclipse of Your Meat"?25:0);
        float combatFraction=barfSetting("CombatsBetweenNC",30)/(barfSetting("CombatsBetweenNC",30)+1.0);
        barfTwoDayStage stage=barfDietFarmingStage(s);float weight=stage.weight;float percent=stage.weightPercent;
        foreach ef,t in barfTwoDayInitialEffects if(t>0){
            barfDietEffectData before=barfDietEffectAt(ef,t);barfDietEffectData after=barfDietEffectAt(ef,barfDietDuration(s,ef));
            weight+=after.weight-before.weight;percent+=after.weightPercent-before.weightPercent;
        }
        foreach id,t in s.effects if(t>0&&!(barfTwoDayInitialEffects contains to_effect(id))){barfDietEffectData data=barfDietEffectAt(to_effect(id),t);weight+=data.weight;percent+=data.weightPercent;}
        float multiplier=max(1.0,stage.leprechaunWeight);float effective=max(1,floor(weight*(1+percent/100)))*multiplier;
        // Beam ranking approximates overlapping weight expiries; final income is replayed per turn.
        foreach id,left in s.effects if(left>0){
            effect buff=to_effect(id);barfDietEffectData data=barfDietEffectAt(buff,left);
            float loss=base*(data.meat+stage.smithMeatPerPoint*data.smithsness)/100;
            if(stage.farmer==$familiar[Jill-of-All-Trades]){
                float after=max(1,floor((weight-data.weight)*(1+(percent-data.weightPercent)/100)))*multiplier;
                loss+=base*max(1.0,stage.leprechaunEffectiveness)*((220*effective)**0.5+2*effective-(220*after)**0.5-2*after)/100;
            }
            int n=count(kernel.loss);kernel.expiry[n]=left;kernel.loss[n]=loss;
        }
        kernel.fraction=combatFraction;
        if(barfDietMemoize){
            if(count(barfDietScoreKernels)>=256)clear(barfDietScoreKernels);
            barfDietScoreKernels[kernelKey]=kernel;
        }
    }
    float future=budget*kernel.rate;
    future-=100*ceil(max(0,budget-s.uses["touristTurns"])/20.0);
    foreach n,loss in kernel.loss if(kernel.expiry[n]<budget)
        future-=(budget-kernel.expiry[n])*loss*kernel.fraction;
    if(barfDietMemoize){barfDietFutureCache[key]=future;barfDietTomorrowCache[key]=tomorrow;}
    return score+future;
}

barfTwoDayState barfDietDistillState(barfTwoDayState a,int checkpoint){
    barfTwoDayState s=barfDietClone(a);
    if(s.finished||s.sweat<10||s.drunkenness>=barfDietLiverLimit(s)||available_amount($item[tiny stillsuit])==0){s.cash=-1;return s;}
    int yield=round(s.sweat**0.4);int before=s.sweat;
    s.sweat=0;s.drunkenness+=1;s.adventures+=yield;s.minimumAdventures+=yield;
    s.uses["distillPours"]+=1;s.uses["distillAdventures"]+=yield;
    if(checkpoint>=0&&!barfDietBit(s.uses["pourDone"],checkpoint))s.uses["pourDone"]+=(2**checkpoint).to_int();
    // Variable distillate modifiers are not credited at an invented fixed strength.
    s.schedule+="distill\t"+before+"\t"+yield+"\t"+min(100,before/5)+(checkpoint>=0?"\t"+checkpoint:"")+"\n";
    return s;
}
barfTwoDayState barfDietDistillState(barfTwoDayState a){return barfDietDistillState(a,-1);}

boolean barfDietPourPending(barfTwoDayState s,int checkpoint){
    return barfDietBit(s.uses["pourStages"],checkpoint)&&!barfDietBit(s.uses["pourDone"],checkpoint);
}
barfTwoDayState barfDietSkipPour(barfTwoDayState source,int checkpoint){
    barfTwoDayState s=barfDietClone(source);
    if(!barfDietBit(s.uses["pourDone"],checkpoint))s.uses["pourDone"]+=(2**checkpoint).to_int();
    s.schedule+="pourSkip\t"+checkpoint+"\n";return s;
}
barfTwoDayState barfDietTimedPour(barfTwoDayState s,int checkpoint){
    if(!barfDietPourPending(s,checkpoint))return s;
    if(s.uses["pourSweat"+checkpoint]>s.sweat)return s;
    if(s.sweat<10||s.drunkenness>=barfDietLiverLimit(s))return barfDietSkipPour(s,checkpoint);
    return barfDietDistillState(s,checkpoint);
}
int barfDietPourSweatForYield(int adventures){
    int sweat=max(10,ceil((max(1,adventures)-0.5)**2.5));
    while(round(sweat**0.4)<adventures)sweat+=1;
    while(sweat>10&&round((sweat-1)**0.4)>=adventures)sweat-=1;
    return sweat;
}
int barfDietPourWait(barfTwoDayState s,int checkpoint){
    if(!barfDietPourPending(s,checkpoint))return -1;
    int target=s.uses["pourSweat"+checkpoint];
    if(target<=0)return checkpoint==2?max(0,s.uses["pourMidTurn"]-s.turns):-1;
    if(s.sweat>=target)return 0;
    if(barfSetting("CombatsBetweenNC",30)<=0)return -1;
    barfTwoDayStage stage=barfDietStage(s);
    // Recheck trainer transitions every turn; normal farming generates one
    // inactive-suit dram per combat, with the same noncombat pattern as farming.
    if(stage.farmer==$familiar[Chest Mimic]||stage.farmer==$familiar[Cooler Yeti])return 1;
    int need=target-s.sweat;int low=1;int high=need*2+2;
    while(low<high){
        int middle=(low+high)/2;
        if(barfDietForecastCombats(s.turns,middle)>=need)high=middle;else low=middle+1;
    }
    return low;
}
int barfDietPourReserve(barfTwoDayState s,boolean late){
    int slots=late?1:0;
    for checkpoint from 0 to 2 if(barfDietPourPending(s,checkpoint))slots+=1;
    return slots;
}
string barfDietPourSummary(barfTwoDayState s){
    string yields="";int pours=0;int adventures=0;
    foreach i,row in split_string(s.schedule,"\n"){
        string[int] c=split_string(row,"\t");if(count(c)<3||c[0]!="distill")continue;
        yields+=(pours>0?" + ":"")+c[2];pours+=1;adventures+=c[2].to_int();
    }
    return pours+" pour(s), "+(pours>0?yields+" = ":"")+adventures+" adventures, "+pours+" liver";
}

barfTwoDayState barfDietResourceState(barfTwoDayState a,string action){
    barfTwoDayState s=barfDietClone(a);item it=$item[none];int price=0;
    if(s.finished){s.cash=-1;return s;}
    if(contains_text(action,"wish:")){
        effect buff=to_effect(substring(action,5).to_int());
        if(available_amount($item[cursed monkey's paw])==0||get_property("_monkeyPawWishesUsed").to_int()+s.uses["wishes"]>=5
            ||buff==$effect[none]){s.cash=-1;return s;}
        s.effects[to_int(buff)]+=30;s.uses["wishes"]+=1;
    }else if(action=="milk"){
        if(s.milk>0)return s;
        if(get_property("_milkOfMagnesiumUsed").to_boolean()||s.uses["milk"]>0){s.cash=-1;return s;}
        it=$item[milk of magnesium];price=100;s.milk=1;
    }else if(action=="sweat"){
        if(!have_skill($skill[Sweat Out Some Booze])||s.pantsSweat<25||s.drunkenness<3
            ||get_property("_sweatOutSomeBoozeUsed").to_int()+s.uses[action]>=3){s.cash=-1;return s;}
        s.pantsSweat-=25;s.drunkenness-=3;
    }else if(action=="aug16"){
        if(!have_skill($skill[Aug. 16th: Roller Coaster Day!])||get_property("_aug16Cast").to_boolean()
            ||get_property("_augSkillsCast").to_int()+s.uses[action]>=5||s.uses[action]>0||s.fullness<2){s.cash=-1;return s;}
        s.fullness-=1;
    }else if(action=="noodleSpleen"){
        it=$item[Tubetto Gelatto];
        if(get_property("_legendaryNoodlesSpleen").to_boolean()||s.uses[action]>0
            ||s.fullness>=barfDietFullLimit(s)||s.spleen>=barfDietSpleenLimit(s)){s.cash=-1;return s;}
        // Separate choice: gross one fullness must fit; refund one and add one spleen.
        barfTwoDayItem entry;entry.target=it;entry.fullness=1;entry.minimum=split_string(it.adventures,"-")[0].to_int();entry.average=entry.minimum;entry.price=barfDietCurrentPrice(it);
        if(entry.price<0){s.cash=-1;return s;}
        entry.dailyRemaining=barfDietBuyable[it]?100:barfDietOwnedAmount(it);
        s=barfDietConsumeState(s,entry,false,0);
        if(s.cash<0)return s;
        s.fullness-=1;s.spleen+=1;
        // Replace the consume row: executor chooses spleen instead of effect-duration charges.
        int last=last_index_of(s.schedule,"consume\t");
        s.schedule=substring(s.schedule,0,last)+"noodleSpleen"+substring(s.schedule,last+length("consume"));
        it=$item[none];
    }else{
        string pref="";
        if(action=="mojo"){it=$item[mojo filter];pref="currentMojoFilters";if(s.spleen<1||get_property(pref).to_int()+s.uses[action]>=3){s.cash=-1;return s;}s.spleen-=1;}
        else if(action=="melange"){it=$item[spice melange];pref="spiceMelangeUsed";if(s.fullness<3||s.drunkenness<3){s.cash=-1;return s;}s.fullness-=3;s.drunkenness-=3;}
        else if(action=="doghair"){it=$item[synthetic dog hair pill];pref="_syntheticDogHairPillUsed";if(s.drunkenness<1){s.cash=-1;return s;}s.drunkenness-=1;}
        else if(action=="distention"){it=$item[distention pill];pref="_distentionPillUsed";s.uses["extraFullness"]+=1;}
        else if(action=="sweettooth"){it=$item[sweet tooth];pref="_sweetToothUsed";s.uses["extraFullness"]+=1;}
        else if(action=="voraci"){it=$item[cuppa Voraci tea];pref="_voraciTeaUsed";s.uses["extraFullness"]+=1;}
        else if(action=="sobrie"){it=$item[cuppa Sobrie tea];pref="_sobrieTeaUsed";if(s.drunkenness<1){s.cash=-1;return s;}s.drunkenness-=1;}
        else {s.cash=-1;return s;}
        if(action!="mojo"&&(get_property(pref).to_boolean()||s.uses[action]>0)){s.cash=-1;return s;}
        price=barfDietCurrentPrice(it);
        if(price<0||price>barfSetting("DietMaxItemPrice",500000)){s.cash=-1;return s;}
    }
    s.uses[action]+=1;s.cost+=price;if(it!=$item[none])s.cash+=barfDietStockCash(s,it,1,price);
    if(action!="noodleSpleen")s.schedule+="resource\t"+action+"\t"+to_int(it)+"\t"+price+"\n";
    return s;
}

barfTwoDayState barfDietCapacityState(barfTwoDayState a,int bit){
    barfTwoDayState s=barfDietClone(a);
    if(s.finished||s.stooper||barfDietStageKey(s)>=128
        ||(s.mask==0&&((have_familiar($familiar[Chest Mimic])&&s.chestXP<barfDietTrainingGoal(s,true))
        ||(have_familiar($familiar[Cooler Yeti])&&s.yetiXP<barfDietTrainingGoal(s,false))))||barfDietBit(s.mask,bit)){s.cash=-1;return s;}
    s.mask+=(2**bit).to_int();
    if(!barfDietStage(s).legal||s.fullness>barfDietFullLimit(s)||s.drunkenness>barfDietLiverLimit(s)||s.spleen>barfDietSpleenLimit(s)){s.cash=-1;return s;}
    s.schedule+="capacity\t"+bit+"\t"+s.mask+"\n";return s;
}
barfTwoDayState barfDietStooperState(barfTwoDayState a){
    barfTwoDayState s=barfDietClone(a);
    if(s.finished||s.stooper||s.mask!=63){s.cash=-1;return s;}
    s.stooper=true;if(!barfDietStage(s).legal){s.cash=-1;return s;}
    s.schedule+="stooper\n";return s;
}
barfTwoDayState barfDietFinishState(barfTwoDayState a){
    barfTwoDayState s=barfDietClone(a);
    if((s.uses["allCool"]>0&&s.uses["coolUncovered"]>0)||s.uses["coldRequired"]>0){s.cash=-1;return s;}
    if(s.finished||s.mask!=63||!s.stooper||s.fullness!=barfDietFullLimit(s)
        ||s.drunkenness!=barfDietLiverLimit(s)||s.spleen!=barfDietSpleenLimit(s)
        ||!barfDietRetentionLegal(s,0)){s.cash=-1;return s;}
    // Repeated consumptions extend duration, never the weight bonus of an effect.
    foreach id,turns in s.effects if(turns>=5&&barfDietCanRetain(to_effect(id))&&to_effect(id)!=$effect[Smart Drunk])s.retained[id]=true;
    int price=barfDietCurrentPrice($item[vintage smart drink]);
    if(price<0){s.cash=-1;return s;}
    int gain=barfDietNightcapMinimum();s.adventures+=gain;s.minimumAdventures+=gain;s.drunkenness+=10;
    s.effects[to_int($effect[Smart Drunk])]=1;remove s.retained[to_int($effect[Smart Drunk])];
    s.cost+=price;s.cash+=barfDietStockCash(s,$item[vintage smart drink],1,price);
    s.schedule+="phase\tStop farming; keep the stated reserve. Vintage smart drink with Ode is the final consumption, then your rollover outfit.\n";
    s.finished=true;s.schedule+="nightcap\t"+gain+"\t"+price+"\nrollover\n";
    if(barfDietProjectedStart(s,0)!=200)s.cash=-1;
    return s;
}

float barfDietCandidateRank(barfTwoDayItem e,barfTwoDayState s,float rate){
    int size=max(1,e.fullness+e.drunkenness+e.spleen);
    float buff=min(e.duration,max(0,s.minimumAdventures))*barfBaseMeat()*numeric_modifier(e.buff,"Meat Drop")/100;
    float tomorrow=!barfDietPrepReplaces(e.buff)?max(0,numeric_modifier(e.buff,"Familiar Weight"))*barfTwoDayWeightCalibration:0;
    return ((e.average+e.delayedAverage)*rate-e.price+buff+tomorrow)/size;
}

boolean barfDietLimitedCandidate(barfTwoDayItem e){
    return e.dailyRemaining<100||e.crafted||(e.target!=$item[none]&&!barfDietBuyable[e.target]);
}
void barfDietPruneItems(barfTwoDayState s){
    barfTwoDayItem[int] kept;float[int] ranks;
    float rate=barfDietRateAtStage(s,barfDietFarmingStage(s));
    foreach i,e in barfTwoDayItems ranks[i]=barfDietCandidateRank(e,s,rate);
    foreach i,e in barfTwoDayItems{
        int better=0;
        if(e.target!=$item[Dreadsylvanian cold-fashioned]&&e.special==""&&!barfDietLimitedCandidate(e))foreach j,f in barfTwoDayItems{
            if(i==j||f.fullness!=e.fullness||f.drunkenness!=e.drunkenness||f.spleen!=e.spleen||f.special!=e.special)continue;
            if(barfDietLimitedCandidate(f))continue;
            if(barfDietRelevantEffect(e.buff)&&(f.buff!=e.buff||f.duration!=e.duration))continue;
            if(ranks[j]>ranks[i]||(ranks[j]==ranks[i]&&j<i))better+=1;
            if(better>=4)break;
        }
        if(better<4)kept[count(kept)]=e;
        else if(e.target!=$item[none])barfDietCandidateStatus[e.target]="Outside regular-fill shortlist";
    }
    clear(barfTwoDayItems);foreach i,e in kept barfTwoDayItems[i]=e;
}


// Include effect expiry and each attainable stillsuit yield threshold.
// Introduce only one item per transition; Jill remains until all six are introduced.


// Installed Mafia's Adventures modifier already includes camp, passives, resolution,
// circadian rhythms, hare/gibberer and borrowed-time adjustments. Base forty is separate.


boolean barfDietRollover(){
    barfTwoDayClanGain=barfSetting("ClanRolloverGain",0);
    barfTwoDayRollover=barfSetting("RolloverGain",145)+barfTwoDayClanGain;
    barfTwoDayRolloverGoal=get_property("teresBarfRolloverOutfit");
    print("Rollover reserve uses "+barfTwoDayRollover+" total adventures, including base adventures. Default: your manually checked 145; change with set teresBarfRolloverGain=<total>. No rollover maximization.","blue");
    return true;
}

void barfDietEnsureFillers(){
    foreach it in $items[fortune cookie,ice-cold Willer,twinkly wad]{
        boolean found=false;foreach i,e in barfTwoDayItems if(e.target==it)found=true;
        if(found||it.levelreq>my_level()||!is_unrestricted(it)||!barfDietQualityAllowed(it))continue;
        int price=barfDietCurrentPrice(it);if(price<0)continue;
        barfTwoDayItem e;e.target=it;e.fullness=it.fullness;e.drunkenness=it.inebriety;e.spleen=it.spleen;e.price=price;e.dailyRemaining=100;
        if(!barfDietBuyable[it])e.dailyRemaining=min(e.dailyRemaining,barfDietOwnedAmount(it));
        if(e.dailyRemaining<=0)continue;
        string[int] bounds=split_string(it.adventures,"-");e.minimum=bounds[0].to_int();e.average=(e.minimum+(count(bounds)>1?bounds[1].to_int():e.minimum))/2.0;
        e.buff=effect_modifier(it,"Effect");e.duration=round(numeric_modifier(it,"Effect Duration"));barfTwoDayItems[count(barfTwoDayItems)]=e;
        barfDietCandidateDetails[it]=e;barfDietCandidateStatus[it]="Regular-fill shortlist";
    }
}

string barfDietQuickFailure;
int barfDietQuickDeadline;
float barfDietQuickBaseline;
int barfDietFillGenerated;
int barfDietFillDominated;
int barfDietFillBeamPruned;
record barfDietExtraData {string group;string preference;int limit;float minimum;float average;};
barfDietExtraData barfDietExtra(item it,barfTwoDayState s){
    barfDietExtraData e;
    item[class] classChocolate={
        $class[Seal Clubber]:$item[chocolate seal-clubbing club],$class[Turtle Tamer]:$item[chocolate turtle totem],
        $class[Pastamancer]:$item[chocolate pasta spoon],$class[Sauceror]:$item[chocolate saucepan],
        $class[Disco Bandit]:$item[chocolate disco ball],$class[Accordion Thief]:$item[chocolate stolen accordion]};
    if($items[chocolate seal-clubbing club,chocolate turtle totem,chocolate pasta spoon,chocolate saucepan,
        chocolate disco ball,chocolate stolen accordion,fancy chocolate,fancy but probably evil chocolate,fancy chocolate car,
        beet-flavored Mr. Mediocrebar,cabbage-flavored Mr. Mediocrebar,sweet-corn-flavored Mr. Mediocrebar,choco-Crimbot] contains it){
        e.group="chocolates";e.preference="_chocolatesUsed";e.limit=3;
        int used=barfDietDailyUsed(e.preference)+s.uses[e.group];
        e.minimum=it==$item[chocolate seal-clubbing club]||it==$item[chocolate turtle totem]||it==$item[chocolate pasta spoon]
            ||it==$item[chocolate saucepan]||it==$item[chocolate disco ball]||it==$item[chocolate stolen accordion]
            ?(it==classChocolate[my_class()]?3:2)-used:5-2*used;
    }else if(it==$item[chocolate cigar]||it==$item[vitachoconutriment capsule]||it==$item[fancy chocolate sculpture]){
        e.group=it==$item[chocolate cigar]?"cigars":it==$item[vitachoconutriment capsule]?"vitachoc":"sculptures";
        e.preference=it==$item[chocolate cigar]?"_chocolateCigarsUsed":it==$item[vitachoconutriment capsule]?"_vitachocCapsulesUsed":"_chocolateSculpturesUsed";
        e.limit=3;e.minimum=5-2*(barfDietDailyUsed(e.preference)+s.uses[e.group]);
    }else if(it==$item[essential tofu]){
        e.group="tofu";e.preference="_essentialTofuUsed";e.limit=1;e.minimum=4;e.average=5;
    }else if(it==$item[clock]){
        e.group="clocks";e.preference="_clocksUsed";e.limit=2;
        e.minimum=3-barfDietDailyUsed(e.preference)-s.uses[e.group];
    }
    if(e.average==0)e.average=e.minimum;
    return e;
}
barfTwoDayState barfDietExtraState(barfTwoDayState source,item it){
    barfTwoDayState rejected;rejected.cash=-1;
    barfDietExtraData e=barfDietExtra(it,source);
    if(e.group==""||e.minimum<=0||source.finished||it.levelreq>my_level()||!is_unrestricted(it)
        ||barfDietDailyUsed(e.preference)+source.uses[e.group]>=e.limit)return rejected;
    int price=barfDietCurrentPrice(it);
    if(price<0||(!barfDietBuyable[it]&&source.uses["stock:"+to_int(it)]>=barfDietOwnedAmount(it)))return rejected;
    barfTwoDayState s=barfDietClone(source);
    s.cost+=price;s.cash+=barfDietStockCash(s,it,1,price);
    if(!barfDietFundingLegal(s))return rejected;
    s.adventures+=e.average;s.minimumAdventures+=e.minimum;s.uses[e.group]+=1;
    s.schedule+="extra\t"+to_int(it)+"\t"+e.minimum+"\t"+e.average+"\n";
    return s;
}
record barfDietChocolateOption {item target;int price;int owned;boolean buyable;float[int] gains;};
record barfDietChocolateBasket {float adventures;float cost;float cash;string actions;};
barfDietChocolateBasket barfDietChocolateSearch(barfDietChocolateOption[int] options,int[int] used,
    barfDietChocolateBasket source,int depth,int limit,float rate,float wallet){
    barfDietChocolateBasket best=source;float score=source.adventures*rate-source.cost;
    if(depth>=limit)return best;
    foreach i,option in options{
        if(option.gains[depth]<=0||(!option.buyable&&used[i]>=option.owned))continue;
        barfDietChocolateBasket next;
        next.adventures=source.adventures+option.gains[depth];next.cost=source.cost+option.price;
        next.cash=source.cash+(used[i]>=option.owned?option.price:0);
        if(next.cash<0||(!barfDietRelaxedWallet&&next.cash>wallet)
            ||next.adventures*rate-next.cost<=source.adventures*rate-source.cost)continue;
        next.actions=source.actions+to_int(option.target)+",";
        used[i]+=1;
        next=barfDietChocolateSearch(options,used,next,depth+1,limit,rate,wallet);
        used[i]-=1;
        if(next.adventures*rate-next.cost>score){best=next;score=next.adventures*rate-next.cost;}
    }
    return best;
}
barfTwoDayState barfDietChocolatePlan(barfTwoDayState source,float rate){
    int limit=max(0,3-barfDietDailyUsed("_chocolatesUsed")-source.uses["chocolates"]);
    if(limit==0||source.finished)return source;
    // Explore the same ordered choices using only adventure/cost/cash scalars.
    // Materialize stock ledgers and the native action schedule for the winner only.
    barfDietChocolateOption[int] options;
    foreach it in $items[chocolate seal-clubbing club,chocolate turtle totem,chocolate pasta spoon,chocolate saucepan,
        chocolate disco ball,chocolate stolen accordion,fancy chocolate,fancy but probably evil chocolate,fancy chocolate car,
        beet-flavored Mr. Mediocrebar,cabbage-flavored Mr. Mediocrebar,sweet-corn-flavored Mr. Mediocrebar,choco-Crimbot]{
        int price=barfDietCurrentPrice(it);
        if(price<0||it.levelreq>my_level()||!is_unrestricted(it))continue;
        barfDietChocolateOption option;option.target=it;option.price=price;option.buyable=barfDietBuyable[it];
        option.owned=max(0,barfDietOwnedAmount(it)-source.uses["stock:"+to_int(it)]);
        for depth from 0 to limit-1{
            barfTwoDayState context=barfDietClone(source);context.uses["chocolates"]+=depth;
            option.gains[depth]=barfDietExtra(it,context).average;
        }
        options[count(options)]=option;
    }
    barfDietChocolateBasket start;start.adventures=source.adventures;start.cost=source.cost;start.cash=source.cash;
    int[int] used;
    barfDietChocolateBasket basket=barfDietChocolateSearch(options,used,start,0,limit,rate,my_meat()+source.liquidIncome);
    barfTwoDayState result=barfDietClone(source);
    foreach i,id in split_string(basket.actions,",")if(id!="")result=barfDietExtraState(result,to_item(id.to_int()));
    return result;
}
barfTwoDayState barfDietQuickExtras(barfTwoDayState source){
    if(source.uses["noExtras"]>0||get_property("teresBarfDietExtraAdventures")=="false")return source;
    // Adventure value, daily uses, stock and liquidity can differ between trials.
    // Reuse a menu only for the identical physical/economic starting state.
    string key=barfDietExactStateKey(source);
    if(!barfDietExtraMenuReady||barfDietExtraMenuKey!=key){
        clear(barfDietExtraMenu);
        float rate=barfDietMarginalAdventure(source,0,0);
        barfTwoDayState selected=barfDietChocolatePlan(source,rate);
        foreach it in $items[chocolate cigar,vitachoconutriment capsule,fancy chocolate sculpture,essential tofu,clock]{
            for n from 1 to 3{
                barfTwoDayState next=barfDietExtraState(selected,it);
                if(next.cash<0||next.adventures*rate-next.cost<=selected.adventures*rate-selected.cost)break;
                selected=next;
            }
        }
        foreach i,row in split_string(substring(selected.schedule,length(source.schedule)),"\n"){
            string[int] cells=split_string(row,"\t");if(count(cells)>1&&cells[0]=="extra")barfDietExtraMenu[count(barfDietExtraMenu)]=to_item(cells[1].to_int());
        }
        barfDietExtraMenuReady=true;barfDietExtraMenuKey=key;
    }
    barfTwoDayState s=barfDietClone(source);
    foreach i,it in barfDietExtraMenu {s=barfDietExtraState(s,it);if(s.cash<0)return s;}
    return s;
}
boolean barfDietQuickExpired(){return barfDietQuickDeadline>0&&now_to_int()>=barfDietQuickDeadline;}
int barfDietOrganUsed(barfTwoDayState s,string organ){return organ=="food"?s.fullness:organ=="booze"?s.drunkenness:s.spleen;}

int barfDietOrganSize(barfTwoDayItem e,string organ){
    if(organ=="food")return e.drunkenness==0&&e.spleen==0?e.fullness:0;
    if(organ=="booze")return e.fullness==0&&e.spleen==0?e.drunkenness:0;
    return e.fullness==0&&e.drunkenness==0?e.spleen:0;
}
boolean barfDietQuickItem(barfTwoDayItem e){return e.special==""||$strings[noodles,synthesis,speakeasy,extro] contains e.special;}
boolean barfDietRegularFillItem(barfTwoDayItem e){
    return barfDietQuickItem(e)&&(e.target==$item[Affirmation Cookie]||!barfDietLowQuality(e.target)||barfDietHasDelayedAdventures(e.target));
}
// Cash exposure certifies that every considered purchase was affordable, not just
// the selected actions. A cached decision trace is reused only with that headroom.
void barfDietTraceWallet(barfTwoDayState s){if(barfDietTraceCash&&s.cash>=0)barfDietTraceExposure=max(barfDietTraceExposure,s.cash-s.liquidIncome);}
barfTwoDayState barfDietQuickConsumeMode(barfTwoDayState source,barfTwoDayItem e,boolean retain,int yeti){
    barfTwoDayState best;best.cash=-1;float score=-1000000000000.0;
    boolean spleenOnly=barfDietSkipBare&&e.fullness==0&&e.drunkenness==0;
    barfTwoDayState prepared;
    if(!spleenOnly)prepared=barfDietConsumeState(source,e,retain,yeti,false);
    boolean same=!spleenOnly&&barfDietSkipBare&&barfDietBareMatches(source,prepared);
    foreach bare in $booleans[true,false]{
        if(!bare&&(spleenOnly||same))continue;
        barfTwoDayState next;
        if(bare&&!same)next=barfDietConsumeState(source,e,retain,yeti,true);
        else next=prepared;
        if(same){
            // Only the appended row differs. Preserve the original bare-first tie winner.
            int at=length(source.schedule)+length("consume\t"+to_int(e.target)+"\t");
            next.schedule=substring(next.schedule,0,at)+"bare;"+substring(next.schedule,at);
        }
        barfDietTraceWallet(next);
        if(next.cash<0||!barfDietFundingLegal(next))continue;
        float value=barfDietScore(next);
        if(value>score){best=next;score=value;}
    }
    return best;
}
barfTwoDayState barfDietQuickConsume(barfTwoDayState s,barfTwoDayItem e,boolean retain){
    // These guards rule out both nonzero Yeti modes, so there is only one comparison.
    if(e.drunkenness==0||s.uses["allCool"]>0||s.stooper||!have_familiar($familiar[Cooler Yeti])||s.yetiXP<225)
        return barfDietQuickConsumeMode(s,e,retain,0);
    barfTwoDayState best;best.cash=-1;float score=-1000000000000.0;
    for yeti from 0 to 2{
        if(yeti>0&&(e.drunkenness==0||s.stooper||!have_familiar($familiar[Cooler Yeti])||s.yetiXP<(yeti==2?400:225)))continue;
        if(yeti==1&&(barfDietDuration(s,$effect[Looking Cool])>=100||s.uses["allCool"]>0))continue;
        if(s.uses["allCool"]>0&&yeti==2)continue;
        if(yeti==2&&!s.yetiDouble)continue;
        barfTwoDayState next=barfDietQuickConsumeMode(s,e,retain,yeti);
        if(next.cash<0)continue;
        float value=barfDietScore(next);
        if(value>score){best=next;score=value;}
    }
    return best;
}
record barfDietFillChoices {int[int] indices;barfTwoDayState[int] first;};
barfDietFillChoices barfDietQuickChoices(barfTwoDayState source,string organ,int room,boolean broad){
    barfDietFillChoices choices;int[int] eligible;
    foreach i,e in barfTwoDayItems{
        int size=barfDietOrganSize(e,organ);
        if(size>0&&size<=room&&barfDietRegularFillItem(e))eligible[count(eligible)]=i;
    }
    if(broad||count(eligible)<=16){choices.indices=eligible;return choices;}
    float[int] ranks;barfTwoDayState[int] first;float base=barfDietScore(source);
    foreach n,i in eligible{
        if(barfDietQuickExpired())return choices;
        barfTwoDayState next=barfDietQuickConsume(source,barfTwoDayItems[i],false);
        if(next.cash<0)continue;
        first[i]=next;ranks[i]=(barfDietScore(next)-base)/barfDietOrganSize(barfTwoDayItems[i],organ);
    }
    foreach i,rank in ranks{
        barfTwoDayItem e=barfTwoDayItems[i];int better=0;
        if(!barfDietLimitedCandidate(e)&&e.special=="")foreach j,other in ranks{
            barfTwoDayItem f=barfTwoDayItems[j];
            if(i==j||barfDietOrganSize(f,organ)!=barfDietOrganSize(e,organ)||barfDietLimitedCandidate(f)||f.special!="")continue;
            if(barfDietRelevantEffect(e.buff)&&(f.buff!=e.buff||f.duration!=e.duration))continue;
            if(other>rank||(other==rank&&j<i))better+=1;
            if(better>=4)break;
        }
        if(better<4){choices.indices[count(choices.indices)]=i;choices.first[i]=first[i];}
    }
    return choices;
}
barfTwoDayState barfDietQuickFill(barfTwoDayState source,string organ,int target,boolean broad);
barfTwoDayState barfDietQuickFillUncached(barfTwoDayState source,string organ,int target,boolean broad){
    barfTwoDayState s=barfDietClone(source);
    target=max(target,barfDietOrganUsed(s,organ));
    if(organ=="booze"&&s.shotglass>0){
        barfTwoDayState best=s;float score=barfDietScore(s);
        foreach i,e in barfTwoDayItems if(barfDietOrganSize(e,organ)==1&&barfDietRegularFillItem(e)){
            barfTwoDayState next=barfDietQuickConsume(s,e,false);
            if(next.cash<0)continue;
            float value=barfDietScore(next);
            if(value>score){best=next;score=value;}
        }
        s=best;
    }
    int used=barfDietOrganUsed(s,organ);int room=target-used;
    if(room==0)return s;
    barfDietFillChoices choices=barfDietQuickChoices(s,organ,room,broad);
    int width=max(1,min(4,source.uses["fillWidth"]));
    barfTwoDayState[int,int] dp;float[int,int] scores;string[int,int] keys;
    dp[0,0]=s;
    for filled from 0 to room-1{
        if(barfDietQuickExpired()){barfTwoDayState stopped;stopped.cash=-1;return stopped;}
        if(!(dp contains filled))continue;
        foreach choice,parent in dp[filled] foreach n,i in choices.indices{
            barfTwoDayItem e=barfTwoDayItems[i];
            int size=barfDietOrganSize(e,organ);
            if(size<=0||size>room-filled||!barfDietRegularFillItem(e))continue;
            barfTwoDayState next=filled==0&&(choices.first contains i)?choices.first[i]:barfDietQuickConsume(parent,e,false);
            if(next.cash<0)continue;
            int at=barfDietOrganUsed(next,organ)-used;
            if(at<=filled||at>room)continue;
            barfDietFillGenerated+=1;
            string key=barfDietExactStateKey(next);boolean duplicate=false;
            foreach k,oldKey in keys[at] if(oldKey==key){duplicate=true;break;}
            if(duplicate){barfDietFillDominated+=1;continue;}
            if(width>1){
                boolean dominated=false;int[int] removeSlots;
                foreach k,old in dp[at]{
                    if(barfDietFillDominates(old,next)){dominated=true;break;}
                    if(barfDietFillDominates(next,old))removeSlots[count(removeSlots)]=k;
                }
                if(dominated){barfDietFillDominated+=1;continue;}
                foreach n,k in removeSlots{
                    remove dp[at,k];remove scores[at,k];remove keys[at,k];
                    barfDietFillDominated+=1;
                }
            }
            float score=barfDietScore(next);int worst=-1;float worstScore=1000000000000.0;
            foreach k,old in scores[at] if(old<worstScore){worst=k;worstScore=old;}
            if(count(dp[at])<width){
                worst=0;foreach k,old in dp[at] if(k>=worst)worst=k+1;
            }
            else if(score<=worstScore){barfDietFillBeamPruned+=1;continue;}
            dp[at,worst]=next;scores[at,worst]=score;
            keys[at,worst]=key;
        }
    }
    if(dp contains room){
        int best=-1;float bestScore=-1000000000000.0;
        foreach choice,score in scores[room] if(best<0||score>bestScore){best=choice;bestScore=score;}
        return dp[room,best];
    }
    if(!broad&&!barfDietQuickExpired())return barfDietQuickFill(source,organ,target,true);
    if(width==1&&!barfDietQuickExpired()){
        barfTwoDayState retry=barfDietClone(source);retry.uses["fillWidth"]=2;
        return barfDietQuickFill(retry,organ,target,true);
    }
    barfDietQuickFailure="Could not fill "+room+" remaining "+organ+" points within the current inventory, daily limits and cash budget.";
    barfTwoDayState failed;failed.cash=-1;return failed;
}
barfTwoDayState barfDietQuickFill(barfTwoDayState source,string organ,int target,boolean broad){
    // Wallet traces must observe rejected offers too; cached fills cannot
    // provide that exposure certificate. Ordinary planning keeps its exact cache.
    if(!barfDietMemoize||barfDietTraceCash||(target<=barfDietOrganUsed(source,organ)&&!(organ=="booze"&&source.shotglass>0)))
        return barfDietQuickFillUncached(source,organ,target,broad);
    // Exact inputs include every economic/resource field. Only schedule text is
    // rebased; fills append actions without inspecting the preceding actions.
    // Capacity policy affects later equipment decisions, never this pure organ fill.
    barfTwoDayState normalized=source;
    if(source.uses["capacityPolicy"]!=0){normalized=barfDietClone(source);normalized.uses["capacityPolicy"]=0;}
    string key=organ+":"+target+":"+broad+":"+barfDietExactStateKey(normalized);
    if(barfDietFillCache contains key){
        barfDietFillCacheHits+=1;
        barfTwoDayState cached=barfDietClone(barfDietFillCache[key]);
        cached.schedule=source.schedule+cached.schedule;cached.uses["capacityPolicy"]=source.uses["capacityPolicy"];return cached;
    }
    barfDietFillCacheMisses+=1;
    barfTwoDayState result=barfDietQuickFillUncached(normalized,organ,target,broad);
    if(result.cash>=0&&!barfDietQuickExpired()){
        // Bounded storage avoids retaining every frontier of an unrestricted run.
        if(count(barfDietFillCache)>=64)clear(barfDietFillCache);
        barfTwoDayState cached=barfDietClone(result);
        cached.schedule=substring(cached.schedule,length(source.schedule));
        barfDietFillCache[key]=cached;
    }
    if(result.cash>=0)result.uses["capacityPolicy"]=source.uses["capacityPolicy"];
    return result;
}
barfTwoDayState barfDietQuickFill(barfTwoDayState source,string organ,int target){
    return barfDietQuickFill(source,organ,target,false);
}
// Within the existing bare/prepared modes, retain distinct future resources
// instead of ranking partial diets away before the next capacity decision.
int barfDietQuantityExpanded;int barfDietQuantityDuplicates;int barfDietQuantityPermutations;
boolean barfDietQuantityNeutral(barfTwoDayState s,barfTwoDayItem e){
    if(e.target==$item[spaghetti breakfast]||e.special!=""||e.crafted||e.delayedCombats>0||barfDietRelevantEffect(e.buff)
        ||e.average*2!=round(e.average*2)||s.shotglass>0)return false;
    if(e.fullness>0&&(s.milk>0||s.aioli>0||s.whet>0||s.noodles>0
        ||s.uses["munchies"]<get_property("munchiesPillsUsed").to_int()
        ||barfDietOwnedAmount($item[special seasoning])>s.uses["stock:"+to_int($item[special seasoning])]))return false;
    if(e.drunkenness>0&&(contains_text(e.target.notes,"WINE")||contains_text(e.target.notes,"MARTINI")
        ||barfDietDuration(s,$effect[Salty Mouth])>0))return false;
    return true;
}
void barfDietQuantityVisit(barfTwoDayState s,string organ,int target,int last,boolean canonical,
    int[string] seen,barfTwoDayState[string] results){
    if(s.cash<0||!barfDietFundingLegal(s)||barfDietQuickExpired())return;
    int used=barfDietOrganUsed(s,organ);
    if(used==target){
        string key=barfDietExactStateKey(s);
        if(!(results contains key))results[key]=barfDietClone(s);
        else barfDietQuantityDuplicates+=1;
        return;
    }
    string key=barfDietExactStateKey(s);
    if((seen contains key)&&seen[key]<=last){barfDietQuantityDuplicates+=1;return;}seen[key]=last;
    foreach i,e in barfTwoDayItems{
        int size=barfDietOrganSize(e,organ);
        if(size<=0||!barfDietRegularFillItem(e)||size>target-used+(organ=="booze"&&s.shotglass>0?1:0))continue;
        boolean neutral=canonical&&barfDietQuantityNeutral(s,e);
        foreach bare in $booleans[true,false]{
            if(neutral&&bare&&last>i){barfDietQuantityPermutations+=1;continue;}
            barfTwoDayState next=barfDietConsumeState(s,e,false,0,bare);barfDietQuantityExpanded+=1;
            if(next.cash<0||barfDietOrganUsed(next,organ)>target)continue;
            if(!bare&&barfDietBareMatches(s,next))continue;
            // A prepared transition may spend a one-shot helper, so it resets ordering.
            // Bare transitions commute only under the conservative certificate above.
            barfDietQuantityVisit(next,organ,target,neutral&&bare?i:-1,canonical,seen,results);
        }
    }
}
barfTwoDayState[int] barfDietQuantityFills(barfTwoDayState source,string organ,int target,boolean canonical){
    barfTwoDayState[int] result;barfTwoDayState[string] unique;int[string] seen;
    target=max(target,barfDietOrganUsed(source,organ));
    barfDietQuantityVisit(source,organ,target,-1,canonical,seen,unique);
    foreach key,s in unique result[count(result)]=s;
    return result;
}

record barfDietLateMenu {int[int] indices;int fullness;int drunkenness;int spleen;};
void barfDietLiveIngredients(item target,boolean[item] live,int depth){
    if(target==$item[none]||depth>20||(live contains target))return;
    live[target]=true;
    if(barfDietCanCraft(target))foreach part,q in barfDietIngredients(target)barfDietLiveIngredients(part,live,depth+1);
}
barfTwoDayState barfDietContinuationState(barfTwoDayState source,barfDietLateMenu menu){
    barfTwoDayState s=barfDietClone(source);barfTwoDayState final=barfDietClone(s);final.mask=63;final.stooper=true;
    boolean[item] live;boolean[int] organs;
    organs[0]=barfDietFullLimit(final)>s.fullness+menu.fullness;
    organs[1]=barfDietLiverLimit(final)>s.drunkenness+menu.drunkenness;
    organs[2]=barfDietSpleenLimit(final)>s.spleen+menu.spleen;
    foreach action in $strings[melange,aug16,distention,sweettooth,voraci]if(s.uses["clearerDeferred:"+action]>0)organs[0]=true;
    foreach action in $strings[melange,sweat,doghair,sobrie]if(s.uses["clearerDeferred:"+action]>0)organs[1]=true;
    if(s.uses["clearerDeferred:mojo"]>0)organs[2]=true;
    string context=organs[0]+":"+organs[1]+":"+organs[2]+":"+(s.uses["clearerDeferred:noodleSpleen"]>0);
    foreach n,index in menu.indices context+=":"+index;
    if(!(barfDietContinuationLive contains context)){
        foreach n,index in menu.indices barfDietLiveIngredients(barfTwoDayItems[index].target,live,0);
        if(s.uses["clearerDeferred:noodleSpleen"]>0)barfDietLiveIngredients($item[Tubetto Gelatto],live,0);
        barfDietLiveIngredients($item[vintage smart drink],live,0);
        foreach it in $items[How to Avoid Scams,special seasoning,mini kiwi aioli,whet stone,fudge spork,Ol' Scratch's salad fork,Frosty's frosty mug,milk of magnesium,mojo filter,spice melange,synthetic dog hair pill,distention pill,sweet tooth,cuppa Voraci tea,cuppa Sobrie tea,Tubetto Gelatto]live[it]=true;
        foreach i,e in barfTwoDayItems if((e.fullness>0&&organs[0])||(e.drunkenness>0&&organs[1])||(e.spleen>0&&organs[2])){
            live[e.target]=true;
            foreach part,q in e.ingredients barfDietLiveIngredients(part,live,0);
        }
        // The sentinel also represents an empty dependency set.
        barfDietContinuationLive[context,$item[none]]=true;
        foreach target,needed in live barfDietContinuationLive[context,target]=true;
    }
    // Retire only stock that no remaining fill, retained meal, resource or recipe
    // can consume. Effects, helpers, organs and all remaining live stock stay exact.
    foreach i,e in barfTwoDayItems if(e.target!=$item[none]&&e.special==""&&e.dailyGroup==""&&!(barfDietContinuationLive[context] contains e.target)){
        s.uses[to_string(e.target)]=0;s.uses["stock:"+to_int(e.target)]=0;
    }
    foreach name,used in s.uses if(starts_with(name,"stock:")
        &&!(barfDietContinuationLive[context] contains to_item(substring(name,6).to_int())))s.uses[name]=0;
    // Upper bound on remaining ordinary copies: final free organs, all three
    // sweat clears (9), melange (6), three fullness increases, Aug16 (1),
    // two liver pills/teas, three mojo filters, shotglass and spleen noodles.
    // 32 exceeds their total 26; no current supported continuation exceeds it.
    int remaining=max(0,barfDietFullLimit(final)-s.fullness)+max(0,barfDietLiverLimit(final)-s.drunkenness)
        +max(0,barfDietSpleenLimit(final)-s.spleen)+32;
    foreach i,e in barfTwoDayItems if(e.target!=$item[none]&&e.special==""&&!e.crafted&&e.delayedCombats==0
        &&e.dailyGroup==""&&e.dailyRemaining==100&&e.target.tradeable&&barfDietBuyable[e.target]
        &&e.fullness+e.drunkenness+e.spleen>0&&100-s.uses[to_string(e.target)]>=remaining){
        string stock="stock:"+to_int(e.target);
        if(!(barfDietContinuationOwned contains e.target))barfDietContinuationOwned[e.target]=barfDietOwnedAmount(e.target);
        int owned=barfDietContinuationOwned[e.target];
        // Once personal/stash copies are exhausted, all further copies have the
        // same replacement cost, including copies used as recipe ingredients.
        if(s.uses[stock]>=owned){s.uses[stock]=owned;s.uses[to_string(e.target)]=0;}
    }
    s.income=0;s.cost=0;s.cash=0;s.liquidIncome=0;
    s.schedule="";return s;
}

record barfDietRankedPair {int first;int second;float estimate;};
int barfDietMenuPairsGenerated;
string barfDietSearchPhase;
int[string] barfDietSearchMetrics;
boolean barfDietPairReached;boolean barfDietPairExpiredAtEntry;int barfDietPairTop;
void barfDietSearchReport(){
    print("SEARCH trials: "+barfDietSearchMetrics["attempted"]+" attempted, "+barfDietSearchMetrics["complete"]+" completed, "+barfDietSearchMetrics["targets"]
        +" met targets, "+barfDietSearchMetrics["cached"]+" cached; pairs reached="+barfDietPairReached+", expired at entry="+barfDietPairExpiredAtEntry
        +", eligible="+barfDietMenuPairsGenerated+", top="+barfDietPairTop+".","blue");
    print("SEARCH exact fill cache: "+barfDietFillCacheHits+" hits, "+barfDietFillCacheMisses+" misses, "+count(barfDietFillCache)+" stored (maximum 64).","blue");
    print("SEARCH preparation cache: "+barfDietPreparationHits+" hits, "+barfDietPreparationMisses+" misses, "+count(barfDietPreparationCache)+" stored (maximum 16).","blue");
    print("SEARCH shared capacity starts: "+barfDietCapacityStartHits+" hits; "+count(barfDietCapacityStartCache)+" stored (maximum 8).","blue");
    print("SEARCH score coefficients: "+barfDietScoreKernelHits+" hits, "+barfDietScoreKernelMisses+" misses; "+count(barfDietScoreKernels)+" stored (maximum 256).","blue");
    if(!get_property("teresBarfDietDiagnostics").to_boolean())return;
    foreach phase in $strings[estimate,fallback,XP,starting,pours,width,local,training,pairs,capacity,events,bundles]{
        if(barfDietSearchMetrics[phase+":ms"]==0&&barfDietSearchMetrics[phase+":attempted"]==0)continue;
        print("SEARCH phase="+phase+" ms="+barfDietSearchMetrics[phase+":ms"]+" attempted="+barfDietSearchMetrics[phase+":attempted"]
            +" completed="+barfDietSearchMetrics[phase+":complete"]+" targets="+barfDietSearchMetrics[phase+":targets"]+" cached="+barfDietSearchMetrics[phase+":cached"],"blue");
    }
}

barfDietRankedPair[int] barfDietQuickPairMenus(barfTwoDayState initial,int maximum){
    barfDietPairReached=true;barfDietPairExpiredAtEntry=barfDietQuickExpired();barfDietPairTop=0;
    barfDietRankedPair[int] best;float smart=barfSetting("TomorrowPaidTurnsBeforeFK",0)==0?20:0;
    float rate=barfDietRateAtStage(initial,barfDietFarmingStage(initial));
    barfTwoDayState final=barfDietClone(initial);final.mask=63;final.stooper=true;
    foreach i,e in barfTwoDayItems{
        if(barfDietQuickExpired())return best;
        if(!barfDietQuickItem(e)||!barfDietCanRetain(e.buff)||e.duration<5)continue;
        foreach j,f in barfTwoDayItems{
            if(j<=i||!barfDietQuickItem(f)||!barfDietCanRetain(f.buff)||f.duration<5||e.buff==f.buff)continue;
            int fullness=e.fullness+f.fullness;int drunkenness=e.drunkenness+f.drunkenness;int spleen=e.spleen+f.spleen;
            if(fullness>3||drunkenness>3||spleen>3
                ||initial.fullness+fullness>barfDietFullLimit(final)
                ||initial.drunkenness+drunkenness>barfDietLiverLimit(final)
                ||initial.spleen+spleen>barfDietSpleenLimit(final))continue;
            barfDietMenuPairsGenerated+=1;
            float pounds=barfDietEffect(e.buff).weight+barfDietEffect(f.buff).weight;
            float displaced=max(0,e.average-max(0,e.duration-5))+max(0,f.average-max(0,f.duration-5));
            float estimate=barfDietWeightValue(smart+pounds)-barfDietWeightValue(smart)
                -e.price-f.price-displaced*rate;
            if(estimate<=0)continue;
            int candidateIndex=-1;float worst=1000000000000.0;
            foreach k,existing in best if(existing.estimate<worst){candidateIndex=k;worst=existing.estimate;}
            if(count(best)<maximum)candidateIndex=count(best);
            else if(candidateIndex<0||estimate<=worst)continue;
            barfDietRankedPair pair;pair.first=i;pair.second=j;pair.estimate=estimate;best[candidateIndex]=pair;barfDietPairTop=count(best);
        }
    }
    return best;
}
barfDietLateMenu barfDietQuickPairMenu(barfDietRankedPair pair){
    barfDietLateMenu menu;barfTwoDayItem first=barfTwoDayItems[pair.first];barfTwoDayItem second=barfTwoDayItems[pair.second];
    menu.indices[0]=pair.first;menu.indices[1]=pair.second;
    menu.fullness=first.fullness+second.fullness;menu.drunkenness=first.drunkenness+second.drunkenness;
    menu.spleen=first.spleen+second.spleen;return menu;
}
boolean barfDietNeedsTraining(barfTwoDayState s){
    return s.mask==0&&!s.stooper&&((have_familiar($familiar[Chest Mimic])&&s.chestXP<barfDietTrainingGoal(s,true))
        ||(have_familiar($familiar[Cooler Yeti])&&s.yetiXP<barfDietTrainingGoal(s,false)));
}

barfTwoDayState barfDietEarlyTrainingFood(barfTwoDayState source){
    if(source.uses["trainingFood"]==0||!barfDietNeedsTraining(source))return source;
    foreach i,e in barfTwoDayItems if(to_int(e.target)==source.uses["trainingFood"]){
        // This is a one-copy early comparison, not a reward for unused XP or stacking durations.
        if(barfDietDuration(source,e.buff)>0)return source;
        return barfDietQuickConsume(source,e,false);
    }
    barfTwoDayState failed;failed.cash=-1;return failed;
}

barfDietLateMenu barfDietQuickMenu(barfTwoDayState initial,int maximum){
    barfDietLateMenu menu;boolean[effect] picked;float weight=0;
    float rate=barfDietRateAtStage(initial,barfDietFarmingStage(initial));
    barfTwoDayState final=barfDietClone(initial);final.mask=63;final.stooper=true;
    for choice from 1 to maximum{
        int best=-1;float score=0;
        foreach i,e in barfTwoDayItems{
            if(!barfDietQuickItem(e)||!barfDietCanRetain(e.buff)||picked[e.buff]||e.duration<5)continue;
            if(menu.fullness+e.fullness>3||menu.drunkenness+e.drunkenness>3||menu.spleen+e.spleen>3)continue;
            if(initial.fullness+menu.fullness+e.fullness>barfDietFullLimit(final)
                ||initial.drunkenness+menu.drunkenness+e.drunkenness>barfDietLiverLimit(final)
                ||initial.spleen+menu.spleen+e.spleen>barfDietSpleenLimit(final))continue;
            float pounds=barfDietEffect(e.buff).weight;
            float smart=barfSetting("TomorrowPaidTurnsBeforeFK",0)==0?20:0;
            float value=barfDietWeightValue(smart+weight+pounds)-barfDietWeightValue(smart+weight)-e.price
                -max(0,e.average-max(0,e.duration-5))*rate;
            if(value>score){best=i;score=value;}
        }
        if(best<0)break;
        barfTwoDayItem e=barfTwoDayItems[best];menu.indices[count(menu.indices)]=best;
        menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;
        picked[e.buff]=true;weight+=barfDietEffect(e.buff).weight;
    }
    return menu;
}
barfTwoDayState barfDietQuickYetiDrink(barfTwoDayState source,boolean doubleDrink){
    barfTwoDayState best;best.cash=-1;float score=-1000000000000.0;
    foreach i,e in barfTwoDayItems{
        if(doubleDrink?e.target!=$item[Dreadsylvanian cold-fashioned]:barfDietOrganSize(e,"booze")!=1)continue;
        if(!barfDietRegularFillItem(e))continue;
        barfTwoDayState next=barfDietQuickConsumeMode(source,e,false,doubleDrink?2:1);
        if(next.cash<0)continue;
        float value=barfDietScore(next);
        if(value>score){best=next;score=value;}
    }
    if(best.cash<0)barfDietQuickFailure=doubleDrink?"Cannot reserve/consume one cold-fashioned with the 400-XP Yeti double.":
        "Looking Cool cannot cover the next paid encounter: need 225 Yeti XP and a legal one-drunkenness drink. Train before its current coverage expires.";
    return best;
}
barfTwoDayState barfDietQuickFarmTurns(barfTwoDayState source,int paid){
    barfTwoDayState s=barfDietClone(source);int remaining=paid;
    while(remaining>0){
        if(s.uses["allCool"]>0){
            if(barfDietDuration(s,$effect[Looking Cool])==0){s=barfDietQuickYetiDrink(s,false);if(s.cash<0)return s;}
            if(s.uses["coldRequired"]>0&&s.yetiXP>=400){s=barfDietQuickYetiDrink(s,true);if(s.cash<0)return s;}
        }
        int n=remaining;
        if(s.uses["allCool"]>0)n=min(n,barfDietDuration(s,$effect[Looking Cool]));
        s=barfDietFarmState(s,n);barfDietTraceWallet(s);if(s.cash<0)return s;remaining-=n;
    }
    return s;
}
int barfDietQuickFarmable(barfTwoDayState s){
    int reserve=max(0,200-barfTwoDayRollover-barfDietNightcapMinimum());
    int paid=max(0,floor(s.adventures)-reserve);
    if(s.uses["delayedAdventurePlan"]>0)paid=min(paid,max(0,floor(s.minimumAdventures)-reserve));
    foreach id,keep in s.retained if(keep)paid=min(paid,max(0,s.effects[id]-5));
    return paid;
}
int barfDietFillTarget(barfTwoDayState s,barfDietLateMenu menu,boolean distill,string organ){
    barfTwoDayState final=barfDietClone(s);final.mask=63;final.stooper=true;
    if(organ=="food")return min(barfDietFullLimit(s),barfDietFullLimit(final)-menu.fullness);
    if(organ=="spleen")return min(barfDietSpleenLimit(s),barfDietSpleenLimit(final)-menu.spleen);
    int reserve=s.uses["allCool"]>0?max(0,s.uses["coolSlots"]-s.uses["coolRefreshes"])+(s.uses["coldRequired"]>0?4:0):0;
    return min(barfDietLiverLimit(s),barfDietLiverLimit(final)-menu.drunkenness-(distill?1:0))-reserve-barfDietPourReserve(s,false);
}
int barfDietCapacityOrgan(int bit){
    item piece=barfTwoDayCapacityItems[bit];
    if(numeric_modifier(piece,"Stomach Capacity")>0)return 0;
    if(numeric_modifier(piece,"Liver Capacity")>0)return 1;
    if(numeric_modifier(piece,"Spleen Capacity")>0)return 2;
    return -1;
}
boolean barfDietCapacityUseful(barfTwoDayState before,barfTwoDayState after,barfDietLateMenu menu,boolean distill){
    foreach organ in $strings[food,booze,spleen]{
        int used=barfDietOrganUsed(before,organ);
        if(max(used,barfDietFillTarget(after,menu,distill,organ))>max(used,barfDietFillTarget(before,menu,distill,organ)))return true;
    }
    return false;
}
barfTwoDayState barfDietQuickFillStage(barfTwoDayState s,barfDietLateMenu menu,boolean distill){
    if(s.uses["allCool"]>0){
        if(barfDietDuration(s,$effect[Looking Cool])==0&&s.yetiXP>=225){s=barfDietQuickYetiDrink(s,false);if(s.cash<0)return s;}
        if(s.uses["coldRequired"]>0&&s.yetiXP>=400){s=barfDietQuickYetiDrink(s,true);if(s.cash<0)return s;}
    }
    s=barfDietQuickFill(s,"food",barfDietFillTarget(s,menu,distill,"food"));if(s.cash<0)return s;
    s=barfDietQuickFill(s,"booze",barfDietFillTarget(s,menu,distill,"booze"));if(s.cash<0)return s;
    return barfDietQuickFill(s,"spleen",barfDietFillTarget(s,menu,distill,"spleen"));
}
barfTwoDayState barfDietQuickResources(barfTwoDayState s,barfDietLateMenu menu,boolean distill,boolean deferredOnly);
barfTwoDayState barfDietQuickFarm(barfTwoDayState s,barfDietLateMenu menu,boolean distill){
    int paid=barfDietQuickFarmable(s);
    while(true){
        int checkpoint=-1;int beforePour=-1;
        foreach candidate in $ints[1,2]{
            int wait=barfDietPourWait(s,candidate);
            if(wait>=0&&(beforePour<0||wait<beforePour)){checkpoint=candidate;beforePour=wait;}
        }
        if(paid<=0&&beforePour!=0)break;
        if(checkpoint>=0){
            if(beforePour<=0){
                s=barfDietTimedPour(s,checkpoint);if(s.cash<0)return s;
                s=barfDietQuickFillStage(s,menu,distill);if(s.cash<0)return s;
                s=barfDietQuickResources(s,menu,distill,true);if(s.cash<0)return s;
                paid=barfDietQuickFarmable(s);
                continue;
            }
            paid=min(paid,beforePour);
        }
        s=barfDietQuickFarmTurns(s,paid);if(s.cash<0)return s;
        paid=barfDietQuickFarmable(s);
    }
    return s;
}
barfTwoDayState barfDietQuickFarm(barfTwoDayState s){barfDietLateMenu empty;return barfDietQuickFarm(s,empty,false);}
boolean barfDietClearerNeedsFilling(barfTwoDayState s,string action){
    if(action=="melange")return s.fullness<3||s.drunkenness<3;
    if(action=="sweat")return s.drunkenness<3||s.pantsSweat<25;
    if(action=="aug16")return s.fullness<2;
    if(action=="doghair"||action=="sobrie")return s.drunkenness<1;
    if(action=="mojo")return s.spleen<1;
    if(action=="noodleSpleen")return s.fullness>=barfDietFullLimit(s)||s.spleen>=barfDietSpleenLimit(s);
    return false;
}
barfTwoDayState barfDietQuickResources(barfTwoDayState s,barfDietLateMenu menu,boolean distill,boolean deferredOnly){
    s=barfDietClone(s);
    string[int] actions={"sweat","sweat","sweat","aug16","mojo","mojo","mojo","melange","doghair","distention","sweettooth","voraci","sobrie","noodleSpleen"};
    // Revisit earlier clearers only after an accepted clear/refill changes the state.
    for pass from 1 to count(actions){
        boolean changed=false;
        foreach i,action in actions{
            if(barfDietQuickExpired())return s;
            string pending="clearerDeferred:"+action;
            if(deferredOnly&&s.uses[pending]==0)continue;
            if(barfDietClearerNeedsFilling(s,action)){s.uses[pending]=1;continue;}
            s.uses[pending]=0;
            barfTwoDayState next=barfDietResourceState(s,action);barfDietTraceWallet(next);
            if(next.cash<0)continue;
            if(action=="noodleSpleen"){
                barfTwoDayState final=barfDietClone(next);final.mask=63;final.stooper=true;
                if(next.spleen+menu.spleen>barfDietSpleenLimit(final))continue;
            }
            next=barfDietQuickFillStage(next,menu,distill);
            if(next.cash>=0&&barfDietScore(next)>barfDietScore(s)){
                s=next;changed=true;if(deferredOnly)s.uses[pending]=1;
            }
        }
        if(!changed)break;
    }
    return s;
}
barfTwoDayState barfDietQuickResources(barfTwoDayState s,barfDietLateMenu menu,boolean distill){
    return barfDietQuickResources(s,menu,distill,false);
}
barfTwoDayState barfDietQuickFinish(barfTwoDayState source){
    barfTwoDayState raw=barfDietClone(source);
    barfTwoDayState best=barfDietFinishState(barfDietQuickFarm(raw));
    for cast from 1 to 5{
        if(barfDietQuickExpired())break;
        barfTwoDayState chosen;chosen.cash=-1;float score=best.cash>=0?barfDietScore(best):-1000000000000.0;
        foreach id in $ints[0,1701]{
            boolean[effect] wishes;
            if(id==1701)wishes[to_effect(1701)]=true;
            else foreach buff in $effects[Covetous Robbery,Down With Chow,Frosty]wishes[buff]=true;
            foreach buff in wishes{
                barfTwoDayState next=barfDietResourceState(raw,"wish:"+to_int(buff));if(next.cash<0)continue;
                if(barfDietCanRetain(buff))next.retained[to_int(buff)]=true;
                barfTwoDayState complete=barfDietFinishState(barfDietQuickFarm(next));
                if(complete.cash>=0&&barfDietScore(complete)>score){chosen=next;best=complete;score=barfDietScore(complete);}
            }
        }
        if(chosen.cash<0)break;raw=chosen;
    }
    return best;
}

barfTwoDayState barfDietQuickStart(barfTwoDayState initial,barfDietLateMenu menu,boolean distill){
    barfTwoDayState s=barfDietClone(initial);
    s.schedule+="phase\tStart: normal farming gear; eat/drink/chew the quantities below.\n";
    if(s.milk==0&&!get_property("_milkOfMagnesiumUsed").to_boolean()&&s.uses["milk"]==0){
        s=barfDietResourceState(s,"milk");if(s.cash<0)return s;
    }
    s=barfDietEarlyTrainingFood(s);if(s.cash<0)return s;
    s=barfDietTimedPour(s,0);if(s.cash<0)return s;
    s=barfDietQuickExtras(s);if(s.cash<0)return s;
    s=barfDietQuickFillStage(s,menu,distill);if(s.cash<0)return s;
    s=barfDietQuickResources(s,menu,distill);
    if(s.mask==0){
        if(s.turns<s.earlyJillTurns){int n=min(s.earlyJillTurns-s.turns,max(0,floor(s.adventures)-max(0,200-barfTwoDayRollover-barfDietNightcapMinimum())));if(n>0)s=barfDietQuickFarmTurns(s,n);}
        if(barfDietStageKey(s)>=128)s.schedule+="phase\tRecharge Chest Mimic / Cooler Yeti with the fixed XP outfit and stillsuit; return to Jill when targets are reached.\n";
        while(barfDietStageKey(s)>=128){
            if(barfDietQuickExpired()){s.cash=-1;return s;}
            int n=min(20,max(0,floor(s.adventures)-max(0,200-barfTwoDayRollover-barfDietNightcapMinimum())));
            if(n==0){s.cash=-1;return s;}
            s=barfDietQuickFarmTurns(s,n);if(s.cash<0)return s;
        }
        if(barfDietStageKey(s)>=128){s.cash=-1;return s;}
    }
    if(barfDietPourPending(s,1)){
        s=barfDietTimedPour(s,1);if(s.cash<0)return s;
        s=barfDietQuickFillStage(s,menu,distill);if(s.cash<0)return s;
    }
    s=barfDietQuickResources(s,menu,distill,true);if(s.cash<0)return s;
    s=barfDietQuickFarm(s,menu,distill);if(s.cash<0)return s;
    return s;
}
barfTwoDayState barfDietQuickCapacityStart(barfTwoDayState initial,barfDietLateMenu menu,boolean distill){
    // Capacity policies cannot affect the prefix before the first equipment decision.
    barfTwoDayState normalized=barfDietClone(initial);normalized.uses["capacityPolicy"]=0;
    string key=menu.fullness+":"+menu.drunkenness+":"+menu.spleen+":"+distill+":"+barfDietExactStateKey(normalized);
    barfTwoDayState s;
    if(barfDietMemoize&&(barfDietCapacityStartCache contains key)){
        barfDietCapacityStartHits+=1;barfDietCapacityStartAges[key]=++barfDietCapacityStartClock;
        s=barfDietClone(barfDietCapacityStartCache[key]);s.schedule=initial.schedule+s.schedule;
    }else{
        s=barfDietQuickStart(normalized,menu,distill);
        if(barfDietMemoize&&s.cash>=0&&!barfDietQuickExpired()){
            // Retain neighboring retry prefixes without pruning any search states.
            if(count(barfDietCapacityStartCache)>=8){
                string oldest="";
                foreach stored,age in barfDietCapacityStartAges if(oldest==""||age<barfDietCapacityStartAges[oldest])oldest=stored;
                remove barfDietCapacityStartCache[oldest];remove barfDietCapacityStartAges[oldest];
            }
            barfTwoDayState cached=barfDietClone(s);cached.schedule=substring(s.schedule,length(initial.schedule));
            barfDietCapacityStartCache[key]=cached;barfDietCapacityStartAges[key]=++barfDietCapacityStartClock;
        }
    }
    s.uses["capacityPolicy"]=initial.uses["capacityPolicy"];return s;
}
barfTwoDayState barfDietQuickPrepareTail(barfTwoDayState source,barfDietLateMenu menu,boolean distill){
    barfTwoDayState s=barfDietClone(source);
    while(s.mask!=63){
        if(barfDietQuickExpired()){s.cash=-1;return s;}
        int best=-1;float score=-1000000000000.0;boolean bestUseful=false;
        foreach bit in $ints[0,1,2,3,4,5] if(!barfDietBit(s.mask,bit)){
            barfTwoDayState next=barfDietCapacityState(s,bit);
            if(next.cash<0)continue;
            boolean useful=barfDietBit(s.uses["capacityPolicy"],3)&&barfDietCapacityUseful(s,next,menu,distill);
            float rate=barfDietRate(next);
            if(best<0||(useful&&!bestUseful)||(useful==bestUseful&&rate>score)){best=bit;score=rate;bestUseful=useful;}
        }
        if(best<0){s.cash=-1;return s;}
        s=barfDietCapacityState(s,best);if(s.cash<0)return s;
        int organ=barfDietCapacityOrgan(best);
        if(organ>=0&&barfDietBit(s.uses["capacityPolicy"],organ)){
            foreach bit in $ints[0,1,2,3,4,5] if(!barfDietBit(s.mask,bit)&&barfDietCapacityOrgan(bit)==organ){
                s=barfDietCapacityState(s,bit);if(s.cash<0)return s;
            }
        }
        s.schedule+="phase\tAdd "+barfTwoDayCapacityItems[best]+"; consume its extra capacity, then farm.\n";
        s=barfDietQuickFillStage(s,menu,distill);if(s.cash<0)return s;
        s=barfDietQuickResources(s,menu,distill,true);if(s.cash<0)return s;
        s=barfDietQuickFarm(s,menu,distill);if(s.cash<0)return s;
    }
    if(!s.stooper)s=barfDietStooperState(s);if(s.cash<0)return s;
    s.schedule+="phase\tStooper last: consume the remaining ordinary organ space, then finish that farming.\n";
    s=barfDietQuickFillStage(s,menu,distill);if(s.cash<0)return s;
    s=barfDietQuickResources(s,menu,distill,true);if(s.cash<0)return s;
    s=barfDietQuickFarm(s,menu,distill);if(s.cash<0)return s;
    // A short or interrupted day may never reach the middle checkpoint. Release
    // its reserved liver space instead of inventing sweat or leaving it empty.
    foreach checkpoint in $ints[1,2]if(barfDietPourPending(s,checkpoint))s=barfDietSkipPour(s,checkpoint);
    s.schedule+="phase\tFinal consumption: retained familiar-weight buffs and any reserved stillsuit pour.\n";
    if(distill){s=barfDietDistillState(s);if(s.cash<0)return s;}
    return s;
}
barfTwoDayState barfDietQuickPrepare(barfTwoDayState initial,barfDietLateMenu menu,boolean distill){
    barfTwoDayState s=barfDietQuickCapacityStart(initial,menu,distill);if(s.cash<0)return s;
    return barfDietQuickPrepareTail(s,menu,distill);
}
barfTwoDayState barfDietQuickPreparation(barfTwoDayState initial,barfDietLateMenu menu,boolean distill){
    if(!barfDietMemoize)return barfDietQuickPrepare(initial,menu,distill);
    // Before retained items are consumed, menu identity has no effect: only its
    // reserved organ totals and the final-pour reservation reach these transitions.
    string key=menu.fullness+":"+menu.drunkenness+":"+menu.spleen+":"+distill+":"+barfDietExactStateKey(initial);
    if(barfDietPreparationCache contains key){
        barfDietPreparationHits+=1;
        barfTwoDayState cached=barfDietClone(barfDietPreparationCache[key]);
        cached.schedule=initial.schedule+cached.schedule;return cached;
    }
    barfDietPreparationMisses+=1;
    barfTwoDayState result=barfDietQuickPrepare(initial,menu,distill);
    if(result.cash>=0&&!barfDietQuickExpired()){
        if(count(barfDietPreparationCache)>=16)clear(barfDietPreparationCache);
        barfTwoDayState cached=barfDietClone(result);
        cached.schedule=substring(cached.schedule,length(initial.schedule));
        barfDietPreparationCache[key]=cached;
    }
    return result;
}
barfTwoDayState barfDietQuickComplete(barfTwoDayState source,barfDietLateMenu menu){
    barfTwoDayState s=barfDietClone(source);
    foreach i,index in menu.indices{
        s=barfDietQuickConsume(s,barfTwoDayItems[index],true);if(s.cash<0)return s;
    }
    barfDietLateMenu empty;
    if(s.uses["allCool"]>0){s.uses["coolSlots"]=s.uses["coolRefreshes"];s.schedule+="coolReserveRelease\n";}
    s=barfDietQuickFillStage(s,empty,false);if(s.cash<0)return s;
    return barfDietQuickFinish(s);
}
barfTwoDayState barfDietQuickSchedule(barfTwoDayState initial,barfDietLateMenu menu,boolean distill){
    barfTwoDayState s=barfDietQuickPreparation(initial,menu,distill);if(s.cash<0)return s;
    return barfDietQuickComplete(s,menu);
}
boolean barfDietMeetsTargets(barfTwoDayState plan){
    return plan.finished&&plan.cash>=0&&plan.uses["coolUncovered"]==0&&plan.uses["coldRequired"]==0
        &&(!have_familiar($familiar[Chest Mimic])||plan.chestXP>=plan.uses["requiredChestXP"])
        &&plan.uses["yetiHighWater"]>=plan.uses["requiredYetiCharge"]&&plan.yetiXP>=barfSetting("YetiReserveXP",0);
}
barfTwoDayState[string] barfDietTrials;
int barfDietTrialStarted;int barfDietTrialCount;
void barfDietRememberComparison(barfTwoDayState next){
    if(next.cash<0||next.uses["trainingOverride"]>0||!barfDietMeetsTargets(next))return;
    string policy=next.uses["noWhet"]>0?(next.uses["noSpork"]>0?"no whet or spork purchases":"no whet purchases")
        :(next.uses["noSpork"]>0?"no spork purchases":"helpers allowed");
    if(!(barfDietComparisons contains policy)||barfDietScore(next)>barfDietScore(barfDietComparisons[policy]))barfDietComparisons[policy]=barfDietClone(next);
}
barfTwoDayState barfDietQuickTrial(barfTwoDayState initial,barfDietLateMenu menu,boolean distill,string label){
    // A middle-pour time cannot affect a schedule with no pending middle pour.
    // Normalize only the cache key; preserve the caller's policy metadata on return.
    barfTwoDayState keyed=initial;
    if(!barfDietPourPending(initial,2)&&initial.uses["pourMidTurn"]!=0){
        keyed=barfDietClone(initial);keyed.uses["pourMidTurn"]=0;
    }
    string key=barfDietExactStateKey(keyed)+":schedule="+length(initial.schedule)+":"+initial.schedule+":pour="+distill;
    foreach i,index in menu.indices key+=":late="+index;
    if(barfDietTrials contains key){
        barfDietSearchMetrics["cached"]+=1;barfDietSearchMetrics[barfDietSearchPhase+":cached"]+=1;
        barfTwoDayState cached=barfDietClone(barfDietTrials[key]);
        if(!barfDietPourPending(initial,2))cached.uses["pourMidTurn"]=initial.uses["pourMidTurn"];
        return cached;
    }
    barfTwoDayState failed;failed.cash=-1;if(barfDietQuickExpired())return failed;
    int trialStarted=now_to_int();barfDietSearchMetrics["attempted"]+=1;barfDietSearchMetrics[barfDietSearchPhase+":attempted"]+=1;
    print("Diet comparison "+(barfDietTrialCount+1)+": "+label+"; "+((now_to_int()-barfDietTrialStarted)/1000)+" seconds elapsed.","blue");
    barfTwoDayState next=barfDietQuickSchedule(initial,menu,distill);
    for retry from 1 to 2{
        if(next.cash>=0||barfDietQuickExpired()||initial.uses["allCool"]==0||initial.yetiXP<225)break;
        initial=barfDietClone(initial);initial.uses["coolSlots"]+=1;initial.uses["initialCoolSlots"]=initial.uses["coolSlots"];
        next=barfDietQuickSchedule(initial,menu,distill);
    }
    if(!barfDietQuickExpired())barfDietTrials[key]=barfDietClone(next);
    barfDietTrialCount+=1;
    barfDietSearchMetrics[barfDietSearchPhase+":ms"]+=now_to_int()-trialStarted;
    if(next.cash>=0){barfDietSearchMetrics["complete"]+=1;barfDietSearchMetrics[barfDietSearchPhase+":complete"]+=1;}
    if(barfDietMeetsTargets(next)){barfDietSearchMetrics["targets"]+=1;barfDietSearchMetrics[barfDietSearchPhase+":targets"]+=1;}
    barfDietRememberComparison(next);
    if(next.cash>=0)print("  Completed: "+next.turns+" encounters; combined "+round(barfDietScore(next))+" Meat; "+barfDietPourSummary(next)+"; requested targets "+(barfDietMeetsTargets(next)?"met":"relaxed comparison only")+".","blue");
    return next;
}
barfTwoDayState barfDietQuickProfile(barfTwoDayState initial,barfTwoDayState selected){
    barfTwoDayState s=barfDietClone(initial);
    foreach flag in $strings[noWhet,noSpork,noExtras,fillWidth,marginalHelpers,trainingFood,pourStages,pourMidTurn,pourSweat1,pourSweat2,capacityPolicy]s.uses[flag]=selected.uses[flag];
    return s;
}
boolean barfDietReplay(barfTwoDayState initial,barfTwoDayState plan);
barfTwoDayState barfDietReplayStart(barfTwoDayState initial,barfTwoDayState plan);
barfTwoDayState barfDietReplayAction(barfTwoDayState s,string row);
record barfDietJointForecast {barfTwoDayState start;barfTwoDayState end;float exposure;};
int barfDietJointForecastHits;
int barfDietJointBoundPruned;
float barfDietJointSkippedCeiling;
int barfDietProfitGap(){return barfSetting("DietProfitGap",2000);}
barfTwoDayState barfDietJointContinue(barfTwoDayState source,barfDietLateMenu menu,boolean distill,float threshold,barfDietJointForecast[string] cache){
    barfTwoDayState normalized=barfDietContinuationState(source,menu);
    string key=barfDietExactStateKey(normalized)+":pour="+distill;
    foreach n,index in menu.indices key+=":late="+index;
    if(!(cache contains key)){
        barfDietTraceCash=true;barfDietRelaxedWallet=true;barfDietTraceExposure=0;
        barfTwoDayState next;
        try{
            next=barfDietQuickResources(normalized,menu,distill,true);
            if(next.cash>=0)next=barfDietQuickFarm(next,menu,distill);
            if(next.cash>=0)next=barfDietQuickPrepareTail(next,menu,distill);
            if(next.cash>=0)next=barfDietQuickComplete(next,menu);
        }finally{barfDietTraceCash=false;barfDietRelaxedWallet=false;}
        if(barfDietMeetsTargets(next)){
            barfDietJointForecast saved;saved.start=normalized;saved.end=next;saved.exposure=barfDietTraceExposure;
            cache[key]=saved;
        }else {barfTwoDayState failed;failed.cash=-1;return failed;}
    }else barfDietJointForecastHits+=1;
    barfDietJointForecast saved=cache[key];
    if(saved.exposure<=my_meat()+source.liquidIncome-source.cash){
        // Exact continuation value in canonical financial coordinates. This is
        // a bound for this fixed continuation, not a global optimality bound.
        float value=barfDietScore(saved.end)+source.income-source.cost;
        if(value+0.01<=threshold+barfDietProfitGap()){
            barfDietJointSkippedCeiling=max(barfDietJointSkippedCeiling,value+0.01);
            barfDietJointBoundPruned+=1;barfTwoDayState skipped;skipped.cash=-1;return skipped;
        }
        barfTwoDayState result=barfDietClone(source);
        foreach n,row in split_string(saved.end.schedule,"\n")if(row!=""){
            result=barfDietReplayAction(result,row);
            if(result.cash<0||!barfDietFundingLegal(result))break;
        }
        if(barfDietMeetsTargets(result)&&barfDietFundingLegal(result))return result;
    }
    // A tight wallet must be searched with its real purchase constraints.
    barfTwoDayState result=barfDietQuickResources(source,menu,distill,true);
    if(result.cash>=0)result=barfDietQuickFarm(result,menu,distill);
    if(result.cash>=0)result=barfDietQuickPrepareTail(result,menu,distill);
    if(result.cash>=0)result=barfDietQuickComplete(result,menu);
    if(!barfDietFundingLegal(result))result.cash=-1;
    return result;
}
int barfDietJointCompleted;int barfDietJointValid;int barfDietJointDuplicates;int barfDietJointWindows;
barfTwoDayState barfDietJointCapacity(barfTwoDayState initial,barfTwoDayState incumbent){
    barfTwoDayState best=barfDietClone(incumbent);barfDietLateMenu menu;boolean distill=false;boolean finalPhase=false;
    foreach n,row in split_string(incumbent.schedule,"\n"){
        string[int] cells=split_string(row,"\t");
        if(cells[0]=="phase"&&contains_text(row,"Final consumption:"))finalPhase=true;
        if(cells[0]=="distill"&&finalPhase)distill=true;
        if(cells[0]=="consume"&&cells[4].to_boolean())foreach i,e in barfTwoDayItems if(to_int(e.target)==cells[1].to_int()){
            menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;break;
        }
    }
    barfDietJointCompleted=0;barfDietJointValid=0;barfDietJointDuplicates=0;barfDietJointWindows=0;barfDietJointForecastHits=0;barfDietJointBoundPruned=0;barfDietJointSkippedCeiling=0;
    barfDietQuantityExpanded=0;barfDietQuantityDuplicates=0;barfDietQuantityPermutations=0;
    boolean[string] completed;boolean[int] opened;barfDietJointForecast[string] forecasts;
    barfTwoDayState prefix=barfDietReplayStart(initial,incumbent);
    foreach n,row in split_string(incumbent.schedule,"\n"){
        if(barfDietQuickExpired())break;
        string[int] cells=split_string(row,"\t");
        if(cells[0]=="capacity"){
            int organ=barfDietCapacityOrgan(cells[1].to_int());string name=organ==0?"food":organ==1?"booze":"spleen";
            int[int] pieces;
            foreach bit in $ints[0,1,2,3,4,5] if(!barfDietBit(prefix.mask,bit)&&barfDietCapacityOrgan(bit)==organ)pieces[count(pieces)]=bit;
            // This neighborhood compares two capacity decisions for one organ.
            // Other events keep their existing production continuation and guards.
            if(organ>=0&&count(pieces)==2&&!(opened contains organ)){
                opened[organ]=true;barfDietJointWindows+=1;
                foreach order in $ints[0,1]{
                    barfTwoDayState first=barfDietCapacityState(prefix,pieces[order]);if(first.cash<0)continue;
                    int target=barfDietFillTarget(first,menu,distill,name);
                    if(target-barfDietOrganUsed(first,name)>2)continue;
                    barfTwoDayState[int] starts;
                    if(target>barfDietOrganUsed(first,name))starts=barfDietQuantityFills(first,name,target,true);
                    starts[count(starts)]=first;
                    foreach j,partial in starts{
                        partial=barfDietQuickFarm(partial,menu,distill);if(partial.cash<0)continue;
                        barfTwoDayState second=barfDietCapacityState(partial,pieces[1-order]);if(second.cash<0)continue;
                        target=barfDietFillTarget(second,menu,distill,name);
                        if(target-barfDietOrganUsed(second,name)>2)continue;
                        foreach k,filled in barfDietQuantityFills(second,name,target,true){
                            if(barfDietQuickExpired())break;
                            string key=barfDietExactStateKey(filled);
                            if(completed contains key){barfDietJointDuplicates+=1;continue;}completed[key]=true;
                            barfTwoDayState next=barfDietJointContinue(filled,menu,distill,barfDietScore(best),forecasts);
                            barfDietJointCompleted+=1;
                            if(!barfDietMeetsTargets(next))continue;
                            barfDietJointValid+=1;
                            if(barfDietScore(next)>barfDietScore(best)&&barfDietReplay(initial,next))best=next;
                        }
                    }
                }
            }
        }
        prefix=barfDietReplayAction(prefix,row);if(prefix.cash<0)break;
    }
    return best;
}

// Joint late equipment, consumption and farming events; no arbitrary beam width.
barfTwoDayState[string,int] barfDietEventLabels;
barfTwoDayState barfDietEventBest;barfTwoDayState barfDietEventInitial;barfDietLateMenu barfDietEventMenu;boolean barfDietEventDistill;
int barfDietEventVisited;int barfDietEventDominated;int barfDietEventComplete;int barfDietEventExpanded;
record barfDietEventNode {barfTwoDayState state;int id;};
barfDietEventNode[int,int] barfDietEventFrontier;
int[string,int] barfDietEventLabelIds;boolean[int] barfDietEventActive;
int barfDietEventLevel(barfTwoDayState s){
    int level=s.turns;foreach bit in $ints[0,1,2,3,4,5]if(barfDietBit(s.mask,bit))level+=1;
    foreach name,used in s.uses if(starts_with(name,"stock:"))level+=used;
    foreach action in $strings[sweat,aug16,mojo,melange,doghair,distention,sweettooth,voraci,sobrie,noodleSpleen]level+=s.uses[action];
    return level;
}
string barfDietEventKey(barfTwoDayState source){
    barfTwoDayState s=barfDietClone(source);s.income=0;s.cost=0;s.cash=0;s.liquidIncome=0;s.schedule="";
    return barfDietExactStateKey(s);
}
// Call only after the complete future-gameplay key matches. More spending
// is not an advantage: retain incomparable profit/available-cash pairs.
boolean barfDietEventDominates(barfTwoDayState a,barfTwoDayState b){
    return a.income-a.cost>=b.income-b.cost&&a.liquidIncome-a.cash>=b.liquidIncome-b.cash;
}
void barfDietEventOffer(barfTwoDayState s){
    if(s.cash<0||!barfDietFundingLegal(s))return;
    string key=barfDietEventKey(s);int[int] removeSlots;
    foreach i,old in barfDietEventLabels[key]{
        if(barfDietEventDominates(old,s)){barfDietEventDominated+=1;return;}
        if(barfDietEventDominates(s,old))removeSlots[count(removeSlots)]=i;
    }
    foreach n,i in removeSlots {barfDietEventActive[barfDietEventLabelIds[key,i]]=false;remove barfDietEventLabels[key,i];remove barfDietEventLabelIds[key,i];}
    int labelSlot=0;foreach i,old in barfDietEventLabels[key]labelSlot=max(labelSlot,i+1);
    barfDietEventLabels[key,labelSlot]=barfDietClone(s);barfDietEventVisited+=1;
    barfDietEventLabelIds[key,labelSlot]=barfDietEventVisited;barfDietEventActive[barfDietEventVisited]=true;
    barfDietEventNode node;node.state=s;node.id=barfDietEventVisited;barfDietEventFrontier[barfDietEventLevel(s),node.id]=node;
}
void barfDietEventExpand(barfTwoDayState s){
    string key=barfDietEventKey(s);barfDietEventExpanded+=1;
    if(s.mask==63){
        barfTwoDayState next=barfDietQuickPrepareTail(s,barfDietEventMenu,barfDietEventDistill);
        if(next.cash>=0)next=barfDietQuickComplete(next,barfDietEventMenu);
        if(barfDietMeetsTargets(next)){
            barfDietEventComplete+=1;
            if(barfDietScore(next)>barfDietScore(barfDietEventBest)&&barfDietReplay(barfDietEventInitial,next))barfDietEventBest=next;
        }
    }
    // Filling can be deferred across several late equipment changes. Farm legality
    // and all organ/resource transitions are still supplied by the production model.
    barfTwoDayState filled=barfDietQuickFillStage(s,barfDietEventMenu,barfDietEventDistill);
    if(filled.cash>=0)filled=barfDietQuickResources(filled,barfDietEventMenu,barfDietEventDistill,true);
    if(filled.cash>=0)filled=barfDietQuickFarm(filled,barfDietEventMenu,barfDietEventDistill);
    if(filled.cash>=0&&barfDietEventKey(filled)!=key)barfDietEventOffer(filled);
    foreach bit in $ints[0,1,2,3,4,5] if(!barfDietBit(s.mask,bit)){
        barfTwoDayState next=barfDietCapacityState(s,bit);
        if(next.cash>=0)barfDietEventOffer(next);
    }
}

void barfDietEventVisit(barfTwoDayState root){
    barfDietEventOffer(root);
    while(count(barfDietEventFrontier)>0){
        int nextLevel=0;foreach level in barfDietEventFrontier {nextLevel=level;break;}
        int nextId=0;foreach id in barfDietEventFrontier[nextLevel] {nextId=id;break;}
        barfDietEventNode node=barfDietEventFrontier[nextLevel,nextId];remove barfDietEventFrontier[nextLevel,nextId];
        if(count(barfDietEventFrontier[nextLevel])==0)remove barfDietEventFrontier[nextLevel];
        if(barfDietEventActive[node.id])barfDietEventExpand(node.state);
    }
}

barfTwoDayState barfDietEventPlan(barfTwoDayState initial,barfTwoDayState incumbent){
    clear(barfDietEventLabels);clear(barfDietEventLabelIds);clear(barfDietEventActive);clear(barfDietEventFrontier);
    barfDietEventVisited=0;barfDietEventDominated=0;barfDietEventComplete=0;barfDietEventExpanded=0;
    barfDietLateMenu menu;boolean distill=false;boolean finalPhase=false;
    foreach n,row in split_string(incumbent.schedule,"\n"){
        string[int] cells=split_string(row,"\t");
        if(cells[0]=="phase"&&contains_text(row,"Final consumption:"))finalPhase=true;
        if(cells[0]=="distill"&&finalPhase)distill=true;
        if(cells[0]=="consume"&&cells[4].to_boolean())foreach i,e in barfTwoDayItems if(to_int(e.target)==cells[1].to_int()){
            menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;break;
        }
    }
    barfTwoDayState prefix=barfDietReplayStart(initial,incumbent);
    foreach n,row in split_string(incumbent.schedule,"\n"){
        if(starts_with(row,"capacity\t"))break;
        if(row!="")prefix=barfDietReplayAction(prefix,row);
    }
    if(prefix.cash<0||prefix.finished||prefix.stooper||barfDietStageKey(prefix)>=128)return incumbent;
    barfDietEventInitial=initial;barfDietEventMenu=menu;barfDietEventDistill=distill;barfDietEventBest=barfDietClone(incumbent);
    int started=now_to_int();barfDietEventVisit(prefix);
    barfTwoDayState best=barfDietClone(barfDietEventBest);
    clear(barfDietEventLabels);clear(barfDietEventLabelIds);clear(barfDietEventActive);clear(barfDietEventFrontier);
    barfDietRememberComparison(best);
    print("Late capacity events: "+barfDietEventExpanded+" expanded / "+barfDietEventVisited+" queued states; "+barfDietEventDominated+" financially dominated arrivals skipped; "
        +barfDietEventComplete+" complete continuations; "+((now_to_int()-started)/1000.0)+" seconds; gain "
        +round(barfDietScore(best)-barfDietScore(incumbent))+" Meat. Capacity equipment stays after the main farming block.","blue");
    return best;
}

// Reuse the actual initial meals and training, then price later sweat events
// against ordinary drinks. No completed training block forces a pour here.
barfTwoDayState barfDietPourContinuation(barfTwoDayState s,barfDietLateMenu menu,boolean distill){
    s=barfDietTimedPour(s,1);if(s.cash<0)return s;
    s=barfDietQuickFillStage(s,menu,distill);if(s.cash<0)return s;
    // Action replay restores gameplay state, not rejected-resource bookkeeping.
    // Recheck clearers once so a deferred sweat/organ clear is not silently lost.
    s=barfDietQuickResources(s,menu,distill);if(s.cash<0)return s;
    s=barfDietQuickFarm(s,menu,distill);if(s.cash<0)return s;
    s=barfDietQuickPrepareTail(s,menu,distill);if(s.cash<0)return s;
    return barfDietQuickComplete(s,menu);
}
barfTwoDayState barfDietRetimePours(barfTwoDayState initial,barfTwoDayState incumbent){
    // Refine the training-coupled policy when selected. Repeating this on the
    // independent middle/final policies added work without gain in the controls.
    if(!barfDietBit(incumbent.uses["pourStages"],1)||incumbent.uses["pourSweat1"]>0)return incumbent;
    barfDietLateMenu menu;boolean distill=false;boolean finalPhase=false;
    foreach n,row in split_string(incumbent.schedule,"\n"){
        string[int] cells=split_string(row,"\t");
        if(cells[0]=="phase"&&contains_text(row,"Final consumption:"))finalPhase=true;
        if(cells[0]=="distill"&&finalPhase)distill=true;
        if(cells[0]=="consume"&&cells[4].to_boolean())foreach i,e in barfTwoDayItems if(to_int(e.target)==cells[1].to_int()){
            menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;break;
        }
    }
    barfTwoDayState prefix=barfDietReplayStart(initial,incumbent);boolean found=false;int remainingSweat=incumbent.sweat;
    foreach n,row in split_string(incumbent.schedule,"\n"){
        string[int] cells=split_string(row,"\t");
        if(!found&&prefix.mask==0&&!prefix.stooper&&barfDietStageKey(prefix)<128&&prefix.turns>=prefix.earlyJillTurns
            &&((cells[0]=="farm"&&cells[2].to_int()<128)||(cells[0]=="distill"&&count(cells)>4&&cells[4].to_int()>0)))found=true;
        if(found){if(cells[0]=="distill")remainingSweat+=cells[1].to_int();}
        else if(row!="")prefix=barfDietReplayAction(prefix,row);
    }
    if(!found||prefix.cash<0||(!barfDietPourPending(prefix,1)&&!barfDietPourPending(prefix,2)))return incumbent;
    foreach flag in $strings[noExtras,fillWidth]prefix.uses[flag]=incumbent.uses[flag];
    barfTwoDayState best=barfDietClone(incumbent);boolean bestDistill=distill;
    int started=now_to_int();int tested=0;int valid=0;
    foreach checkpoint in $ints[1,2]{
        if(!barfDietPourPending(prefix,checkpoint))continue;
        // Integer yields change only at these exact sweat thresholds. The range
        // comes from this complete diet's sweat, not an arbitrary elapsed turn.
        int maximum=round(remainingSweat**0.4);
        for choice from -1 to maximum{
            if(choice>0&&(barfDietPourSweatForYield(choice)<=prefix.sweat
                ||round(barfDietPourSweatForYield(choice)**0.4)!=choice))continue;
            if(choice==-1&&bestDistill)continue;
            barfTwoDayState trial=barfDietClone(prefix);
            trial.uses["pourStages"]=best.uses["pourStages"];
            foreach other in $ints[1,2]trial.uses["pourSweat"+other]=best.uses["pourSweat"+other];
            if(barfDietBit(trial.uses["pourStages"],checkpoint))trial.uses["pourStages"]-=(2**checkpoint).to_int();
            if(choice>0){trial.uses["pourStages"]+=(2**checkpoint).to_int();trial.uses["pourSweat"+checkpoint]=barfDietPourSweatForYield(choice);}
            boolean late=choice==-1?true:bestDistill;tested+=1;
            barfTwoDayState next=barfDietPourContinuation(trial,menu,late);
            if(!barfDietMeetsTargets(next))continue;valid+=1;
            if(barfDietScore(next)>barfDietScore(best)&&barfDietReplay(initial,next)){best=next;bestDistill=late;}
        }
    }
    barfDietRememberComparison(best);
    print("Later stillsuit opportunities: "+tested+" continuations, "+valid+" met targets; "+((now_to_int()-started)/1000.0)
        +" seconds; gain "+round(barfDietScore(best)-barfDietScore(incumbent))+" Meat; "+barfDietPourSummary(best)+". Initial meals/training reused; liver priced against ordinary drinks.","blue");
    return best;
}

barfTwoDayState barfDietQuickPlan(barfTwoDayState initial){
    int started=now_to_int();barfDietTrialStarted=started;barfDietTrialCount=0;
    barfDietFillGenerated=0;barfDietFillDominated=0;barfDietFillBeamPruned=0;
    barfDietMenuPairsGenerated=0;clear(barfDietSearchMetrics);barfDietPairReached=false;barfDietPairExpiredAtEntry=false;barfDietPairTop=0;
    clear(barfDietExtraMenu);barfDietExtraMenuReady=false;
    barfDietQuickDeadline=0;barfDietQuickFailure="";clear(barfDietComparisons);clear(barfDietTrials);
    initial.uses["requiredChestXP"]=barfSetting("ChestXP",950);initial.uses["requiredYetiCharge"]=barfSetting("YetiXP",2000);
    initial.uses["yetiHighWater"]=max(initial.uses["yetiHighWater"],initial.yetiXP);
    if(initial.yetiXP>=initial.uses["requiredYetiCharge"])initial.uses["yetiCharged"]=1;
    initial.uses["noExtras"]=1;
    barfDietLateMenu empty;barfDietLateMenu bestMenu=empty;boolean bestDistill=false;
    print("Building a complete fallback, then comparing starting diets; no full-day beam search.","blue");
    int estimateStarted=now_to_int();barfDietSearchPhase="estimate";
    barfTwoDayState estimate=barfDietQuickSchedule(initial,empty,false);
    barfDietSearchMetrics["estimate:ms"]=now_to_int()-estimateStarted;
    if(estimate.cash<0)return estimate;
    if(have_familiar($familiar[Cooler Yeti])){
        initial.uses["allCool"]=1;initial.uses["coldRequired"]=initial.yetiDouble?1:0;
        initial.uses["coolSlots"]=max(0,ceil((estimate.turns-barfDietDuration(initial,$effect[Looking Cool]))/100.0));
        initial.uses["initialColdRequired"]=initial.uses["coldRequired"];initial.uses["initialCoolSlots"]=initial.uses["coolSlots"];
    }
    barfDietSearchPhase="fallback";
    barfTwoDayState best=barfDietQuickTrial(initial,empty,false,"fallback");
    if(best.cash<0||!barfDietMeetsTargets(best)){print("Practical fallback failed: "+barfDietQuickFailure,"red");best.cash=-1;return best;}
    barfDietQuickBaseline=barfDietScore(best);
    print("Complete fallback ready in "+((now_to_int()-started)/1000)+" seconds: "+best.turns+" farming encounters, combined value "+round(barfDietScore(best))+".","blue");
    // Normal planning finishes its finite comparisons; elapsed time never rejects a diet.
    int deadline=0;
    barfDietQuickDeadline=deadline;
    // The cheap fill score omits training savings. Compare complete diets with
    // one early XP consumable instead of adding a guessed Meat value to each XP.
    barfDietSearchPhase="XP";
    if(barfDietNeedsTraining(initial))foreach i,e in barfTwoDayItems{
        if(barfDietQuickExpired())break;
        if(e.target==$item[none]||!barfDietRegularFillItem(e)||barfDietEffect(e.buff).experience<=0
            ||barfDietDuration(initial,e.buff)>0)continue;
        barfTwoDayState trial=barfDietClone(initial);trial.uses["trainingFood"]=to_int(e.target);
        barfTwoDayState next=barfDietQuickTrial(trial,empty,false,"early familiar XP: "+e.target);
        if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best))best=next;
    }
    // Give distinct consumable buffs a completed comparison before helper-only policies use the budget.
    barfDietLateMenu retained=barfDietQuickMenu(initial,4);
    barfDietSearchPhase="starting";
    for seed from 0 to 5{
        if(barfDietQuickExpired())break;
        if(seed==5&&get_property("teresBarfDietExtraAdventures")=="false")continue;
        boolean distill=seed>=2&&seed<=4;
        if(distill&&available_amount($item[tiny stillsuit])==0)continue;
        barfTwoDayState trial=barfDietClone(initial);trial.uses["trainingFood"]=best.uses["trainingFood"];
        barfDietLateMenu menu=seed==0?empty:seed==1?retained:barfDietQuickMenu(initial,2);
        if(seed==0||seed==2||seed==4)trial.uses["marginalHelpers"]=1;
        if(seed==3||seed==4)trial.uses["noSpork"]=1;
        if(seed==5){trial=barfDietQuickProfile(initial,best);trial.uses["noExtras"]=0;menu=bestMenu;distill=bestDistill;}
        barfTwoDayState next=barfDietQuickTrial(trial,menu,distill,seed==0?"marginal-value helper starting diet":seed==1?"retained-weight starting diet":seed==5?"starting diet with chocolates, tofu and clocks":"balanced late buffs/pour, helper strategy "+seed);
        if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best)){best=next;bestMenu=menu;bestDistill=distill;}
    }
    barfDietSearchPhase="pours";
    if(available_amount($item[tiny stillsuit])>0){
        int middle=initial.turns+max(1,(best.turns-initial.turns)/2);
        int[int] timings={1,2,4,1,2,4,5,6,3,7};
        foreach n,stages in timings{
            if(barfDietQuickExpired())break;
            barfTwoDayState trial=barfDietQuickProfile(initial,best);
            trial.uses["pourStages"]=stages;trial.uses["pourMidTurn"]=middle;
            boolean late=n>=3;string label="stillsuit allocation "+(n+1)+" versus ordinary drinks";
            barfTwoDayState next=barfDietQuickTrial(trial,bestMenu,late,label);
            if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best)){best=next;bestDistill=late;}
        }
        // Each sampled timing gets its actual accumulated sweat, not a fixed
        // adventure yield. Refine the best allocation without an all-turns grid.
        foreach percent in $ints[25,75]{
            if(barfDietQuickExpired())break;
            barfTwoDayState trial=barfDietQuickProfile(initial,best);
            if(!barfDietBit(trial.uses["pourStages"],2))continue;
            trial.uses["pourMidTurn"]=initial.turns+max(1,(best.turns-initial.turns)*percent/100);
            barfTwoDayState next=barfDietQuickTrial(trial,bestMenu,bestDistill,"stillsuit allocation, different sweat split");
            if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best))best=next;
        }
    }
    // Let a better ordinary fill seed the menu/helper refinements, rather than
    // discovering it only after those comparisons have already finished.
    barfDietSearchPhase="width";
    barfDietQuickDeadline=deadline>0?max(now_to_int(),deadline-5000):0;
    if(!barfDietQuickExpired()){
        barfTwoDayState trial=barfDietQuickProfile(initial,best);trial.uses["fillWidth"]=max(1,min(4,barfSetting("DietFillWidth",2)));
        barfTwoDayState next=barfDietQuickTrial(trial,bestMenu,bestDistill,"wider ordinary-fill starting diet ("+trial.uses["fillWidth"]+" partial choices per size)");
        if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best))best=next;
    }
    print("Starting diet selected from "+barfDietTrialCount+" complete/attempted comparisons: "+round(barfDietScore(best))+" combined Meat; improving useful alternatives next.","blue");
    // Reserve part of the same time budget for matched-menu training comparisons.
    int searchDeadline=deadline>0?max(now_to_int(),deadline-5000):0;barfDietQuickDeadline=searchDeadline;
    barfDietSearchPhase="local";
    for pass from 1 to 2{
        float before=barfDietScore(best);
        for number from 0 to 4{
            if(barfDietQuickExpired())break;
            barfDietLateMenu menu=barfDietQuickMenu(initial,number);
            foreach distill in $booleans[true,false]{
                if(barfDietQuickExpired())break;
                if(distill&&available_amount($item[tiny stillsuit])==0)continue;
                barfTwoDayState next=barfDietQuickTrial(barfDietQuickProfile(initial,best),menu,distill,"late menu with "+count(menu.indices)+" effects; pour="+distill);
                if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best)){best=next;bestMenu=menu;bestDistill=distill;}
            }
        }
        for policy from 0 to 3{
            if(barfDietQuickExpired())break;
            barfTwoDayState trial=barfDietQuickProfile(initial,best);trial.uses["noWhet"]=policy%2;trial.uses["noSpork"]=policy/2;
            boolean same=trial.uses["noWhet"]>=best.uses["noWhet"]&&trial.uses["noSpork"]>=best.uses["noSpork"]
                &&(trial.uses["noWhet"]==best.uses["noWhet"]||!contains_text(best.schedule,"whet;"))
                &&(trial.uses["noSpork"]==best.uses["noSpork"]||!contains_text(best.schedule,"spork;"));
            barfTwoDayState next;
            if(same){
                next=barfDietClone(best);next.uses["noWhet"]=trial.uses["noWhet"];next.uses["noSpork"]=trial.uses["noSpork"];
                barfDietRememberComparison(next);
            }else next=barfDietQuickTrial(trial,bestMenu,bestDistill,"helper policy "+policy);
            if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best))best=next;
        }
        foreach distill in $booleans[true,false]{
            if(barfDietQuickExpired())break;
            if(distill&&available_amount($item[tiny stillsuit])==0)continue;
            barfTwoDayState next=barfDietQuickTrial(barfDietQuickProfile(initial,best),bestMenu,distill,"late stillsuit pour="+distill);
            if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best)){best=next;bestDistill=distill;}
        }
        if(barfDietScore(best)<=before){print("Completed an improvement pass without a better diet; stopping that search.","blue");break;}
    }
    barfDietQuickDeadline=deadline;
    barfDietSearchPhase="training";
    foreach policy in $strings[reduced training,skip training]{
        if(barfDietQuickExpired())break;
        barfTwoDayState trial=barfDietQuickProfile(initial,best);trial.uses["trainingOverride"]=1;
        trial.uses["chestGoal"]=policy=="skip training"?0:initial.chestXP+max(0,barfSetting("ChestXP",950)-initial.chestXP)/2;
        trial.uses["yetiGoal"]=policy=="skip training"?0:initial.yetiXP+max(0,barfSetting("YetiXP",2000)-initial.yetiXP)/2;
        barfTwoDayState next=barfDietQuickTrial(trial,bestMenu,bestDistill,policy);
        if(next.cash>=0)barfDietComparisons[policy]=next;
    }
    foreach label,candidate in barfDietComparisons
        if(barfDietMeetsTargets(candidate)&&barfDietScore(candidate)>barfDietScore(best))best=candidate;
    barfDietSearchPhase="pairs";
    barfDietRankedPair[int] pairMenus=barfDietQuickPairMenus(initial,12);
    foreach n,pair in pairMenus{
        if(barfDietQuickExpired())break;
        barfDietLateMenu menu=barfDietQuickPairMenu(pair);
        barfTwoDayItem first=barfTwoDayItems[pair.first];barfTwoDayItem second=barfTwoDayItems[pair.second];
        foreach pour in $booleans[true,false]{
            if(barfDietQuickExpired())break;
            if(pour&&available_amount($item[tiny stillsuit])==0)continue;
            string label="joint retained buffs: "+first.target+" + "+second.target+"; pour="+pour;
            barfTwoDayState next=barfDietQuickTrial(barfDietQuickProfile(initial,best),menu,pour,label);
            if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best)){best=next;bestMenu=menu;bestDistill=pour;}
        }
    }
    foreach label,candidate in barfDietComparisons
        if(barfDietMeetsTargets(candidate)&&barfDietScore(candidate)>barfDietScore(best))best=candidate;
    // Compare bounded complete continuations, never all equipment permutations.
    barfDietSearchPhase="capacity";
    foreach policy in $ints[1,8,9,2,10,4,12,7,15]{
        if(barfDietQuickExpired())break;
        barfTwoDayState trial=barfDietQuickProfile(initial,best);trial.uses["capacityPolicy"]=policy;
        barfTwoDayState next=barfDietQuickTrial(trial,bestMenu,bestDistill,"capacity grouping/defer policy "+policy);
        if(barfDietMeetsTargets(next)&&barfDietScore(next)>barfDietScore(best)&&barfDietReplay(initial,next))best=next;
    }
    if(!barfDietQuickExpired()&&barfDietMeetsTargets(best)){
        int jointStarted=now_to_int();float before=barfDietScore(best);
        best=barfDietJointCapacity(initial,best);
        print("Joint capacity/quantity lookahead: "+barfDietJointWindows+" windows; "+barfDietJointCompleted+" continuations considered; "
            +barfDietJointForecastHits+" shared forecasts; "+barfDietJointBoundPruned+" inferior fixed continuations skipped; "
            +((now_to_int()-jointStarted)/1000.0)+" seconds; gain "+round(barfDietScore(best)-before)+" Meat. Global optimality is not established.","blue");
        print("Fixed-continuation gap allowance: "+barfDietProfitGap()+" Meat; skipped forecasts can exceed the selected plan by at most "
            +ceil(max(0,barfDietJointSkippedCeiling-barfDietScore(best)))+" Meat. This does not bound unexplored whole-day diets.","blue");
    }
    if(!barfDietQuickExpired()&&barfDietMeetsTargets(best))best=barfDietEventPlan(initial,best);
    if(!barfDietQuickExpired()&&barfDietMeetsTargets(best))best=barfDietRetimePours(initial,best);
    if(barfDietQuickExpired())print("Planning safety limit reached; keeping the best complete diet. Incomplete alternatives have no claimed profit.","blue");
    print("Diet planning finished in "+((now_to_int()-started)/1000)+" seconds after "+barfDietTrialCount+" comparisons; fill states "+barfDietFillGenerated+", dominated "+barfDietFillDominated+", width-pruned "+barfDietFillBeamPruned+", joint buff pairs "+barfDietMenuPairsGenerated+"; gain over fallback "+round(barfDietScore(best)-barfDietQuickBaseline)+" Meat.","blue");
    barfDietSearchReport();
    barfDietQuickDeadline=0;return best;
}

barfTwoDayState barfDietReplayStart(barfTwoDayState initial,barfTwoDayState plan){
    barfTwoDayState s=barfDietClone(initial);
    foreach flag in $strings[noWhet,noSpork,trainingOverride,chestGoal,yetiGoal,allCool,coldRequired,coolSlots,marginalHelpers,trainingFood,pourStages,pourMidTurn,pourSweat1,pourSweat2,capacityPolicy]s.uses[flag]=plan.uses[flag];
    s.uses["coldRequired"]=plan.uses["initialColdRequired"];s.uses["coolSlots"]=plan.uses["initialCoolSlots"];
    return s;
}
barfTwoDayState barfDietReplayAction(barfTwoDayState source,string row){
    barfTwoDayState s=barfDietClone(source);
    string[int] cells=split_string(row,"\t");string action=cells[0];
    if(s.finished&&action!="rollover"){s.cash=-1;return s;}
    if(action=="phase"&&!contains_text(cells[1],"Vintage smart drink with Ode is the final consumption"))s.schedule+=row+"\n";
    else if(action=="phase")return s;
    else if(action=="farm")s=barfDietFarmState(s,cells[1].to_int());
    else if(action=="capacity")s=barfDietCapacityState(s,cells[1].to_int());
    else if(action=="stooper")s=barfDietStooperState(s);
    else if(action=="coolReserveRelease"){s.uses["coolSlots"]=s.uses["coolRefreshes"];s.schedule+=row+"\n";}
    else if(action=="distill")s=barfDietDistillState(s,count(cells)>4?cells[4].to_int():-1);
    else if(action=="pourSkip")s=barfDietSkipPour(s,cells[1].to_int());
    else if(action=="extra")s=barfDietExtraState(s,to_item(cells[1].to_int()));
    else if(action=="resource")s=barfDietResourceState(s,cells[1]);
    else if(action=="noodleSpleen")s=barfDietResourceState(s,"noodleSpleen");
    else if(action=="consume"){
        boolean found=false;
        foreach j,e in barfTwoDayItems if(to_int(e.target)==cells[1].to_int()){
            s=contains_text(cells[2],"bare;")?barfDietConsumeBare(s,e,cells[4].to_boolean(),cells[3].to_int()):barfDietConsumeState(s,e,cells[4].to_boolean(),cells[3].to_int());found=true;break;
        }
        if(!found){s.cash=-1;return s;}
    }else if(action=="nightcap")s=barfDietFinishState(s);
    else if(action!="rollover"){s.cash=-1;return s;}
    return s;
}
boolean barfDietReplay(barfTwoDayState initial,barfTwoDayState plan){
    barfTwoDayState s=barfDietReplayStart(initial,plan);
    foreach i,row in split_string(plan.schedule,"\n"){
        if(row=="")continue;
        s=barfDietReplayAction(s,row);
        if(s.cash<0||!barfDietFundingLegal(s))return false;
    }
    return s.finished&&barfDietProjectedStart(s,0)==200&&barfDietRetentionLegal(s,0)
        &&s.schedule==plan.schedule&&max(s.cost-plan.cost,plan.cost-s.cost)<0.01&&max(s.income-plan.income,plan.income-s.income)<0.01;
}

void barfDietComparisonReport(barfTwoDayState selected){
    print("Policy comparisons: paid encounters / today's net / combined / Chest XP / Yeti XP / Looking Cool coverage / Yeti doubles:","blue");
    foreach label in $strings[helpers allowed,no whet purchases,no spork purchases,no whet or spork purchases,reduced training,skip training]{
        if(!(barfDietComparisons contains label)){print("  "+label+": no complete legal comparison.","orange");continue;}
        barfTwoDayState trial=barfDietComparisons[label];
        print("  "+label+": "+trial.turns+" / "+round(trial.income-trial.cost)+" / "+round(barfDietScore(trial))+" / "+trial.chestXP+" / "+trial.yetiXP+" / "+trial.uses["coolCovered"]+" / "+trial.uses["yetiDoubles"]+(barfDietMeetsTargets(trial)?"":" (comparison only: relaxes a requested XP target)"),"blue");
        if(label=="reduced training"||label=="skip training")
            print("    Extra future reward value needed to justify full training: "+max(0,round(barfDietScore(trial)-barfDietScore(selected)))+" Meat; XP-funded eggs tomorrow before other XP gains: full "+min(11,selected.chestXP/100)+", alternative "+min(11,trial.chestXP/100)+" (100 XP each, daily cap 11).","blue");
    }
    if(barfDietComparisons contains "helpers allowed")foreach label in $strings[no whet purchases,no spork purchases,no whet or spork purchases]if(barfDietComparisons contains label)
        print("  "+label+" combined-profit change versus helpers allowed: "+round(barfDietScore(barfDietComparisons[label])-barfDietScore(barfDietComparisons["helpers allowed"]))+" Meat.","blue");
    print("Helper policies use the same finite candidate/late-menu comparisons without a wall-clock cutoff; training alternatives re-fill/reprice the selected late-menu/pour with half the initial XP shortfall or no training. The best complete candidate meeting the requested targets is selected. Yeti charging reaches its target once, then reserves only XP for remaining cooling plus teresBarfYetiReserveXP (default 0). Relaxed-target comparisons are labeled and cannot silently change your requested target. Future egg rewards and unused XP/sweat have no invented sale value; tomorrow's whole-block weight credit already includes its expected fights.","orange");
}

void barfDietReport(barfTwoDayState s,float baseline){
    print("BARF two-day diet: dry run. No purchases, consumption, equipment changes, or adventures.","blue");
    if(s.cash<0){print("The practical diet could not fill an organ or obtain required gear with the available candidates/resources. Check the diagnostic above; no longer retrying a long beam search.","red");}
    else{
        int[item] quantities;string[item] preparations;
        print("Farming forecast: Barf Mountain native location modifiers; How to Scam Tourists maintained (+300% Meat). Upkeep: "+s.uses["touristGuides"]+" How to Avoid Scams at 100 Meat each, included in costs; refresh only when expired.","blue");
        foreach i,row in split_string(s.schedule,"\n"){
            string[int] c=split_string(row,"\t");if(count(c)==0)continue;
            if(c[0]=="consume"){item it=to_item(c[1].to_int());quantities[it]+=1;preparations[it]+=replace_string(c[2],"bare;","")+(c[3]=="0"?"":"Yeti mode "+c[3]+";");}
            if(c[0]=="nightcap")quantities[$item[vintage smart drink]]+=1;
            if(c[0]=="extra")quantities[to_item(c[1].to_int())]+=1;
            if(c[0]=="resource"&&to_item(c[2].to_int())!=$item[none])quantities[to_item(c[2].to_int())]+=1;
            if(c[0]=="noodleSpleen")quantities[$item[Tubetto Gelatto]]+=1;
            if(c[0]=="consume"||c[0]=="noodleSpleen")foreach j,prep in split_string(c[2],";"){
                item it=prep=="milk"?$item[milk of magnesium]:prep=="aioli"?$item[mini kiwi aioli]:prep=="whet"?$item[whet stone]:prep=="spork"?$item[fudge spork]:prep=="fork"?$item[Ol' Scratch's salad fork]:prep=="mug"?$item[Frosty's frosty mug]:prep=="seasoning"?$item[special seasoning]:$item[none];
                if(it!=$item[none])quantities[it]+=1;
            }
        }
        foreach it,n in quantities{
            int price=-1;string label=it==$item[none]?"Synthesis: Greed":to_string(it);
            foreach i,e in barfTwoDayItems if(e.target==it){price=e.price;break;}
            if(price<0)price=barfDietCurrentPrice(it);
            print("  "+n+" x "+label+": "+n*price+" Meat ("+price+" ea); "+preparations[it],"blue");
            if(!it.tradeable&&count(barfDietIngredients(it))>0){
                string basis="";foreach part,q in barfDietIngredients(it)basis+=q+" "+part+"; ";
                print("    Ingredient opportunity cost included, even for owned copies: "+basis,"blue");
            }
            if(barfDietStashStock[it]>0){
                int personal=barfDietOwnedAmount(it)-barfDietStashStock[it];
                print("    Owned supply: "+personal+" personal + "+barfDietStashStock[it]+" in stash; "+min(barfDietStashStock[it],max(0,n-personal))+" of these planned copies can come from stash.","blue");
            }
        }
        foreach it in $items[white candy heart,deviled candy egg,pulled blue taffy]{
            int q=s.uses["trainer:"+to_int(it)];if(q>0)print("Trainer prep: "+q+" x "+it+", "+q*barfDietCurrentPrice(it)+" Meat opportunity cost.","blue");
        }
        if(s.uses["trainingFood"]>0){
            item food=to_item(s.uses["trainingFood"]);effect buff=effect_modifier(food,"Effect");
            print("Early training choice: "+food+" for "+buff+" (+"+barfDietEffect(buff).experience+" familiar XP per combat). Its cost, organ space and effect duration are included in the complete schedule comparison.","blue");
        }
        if(s.uses["trainingSongs"]>0)print("Training songs: 1 per training combat; "+s.uses["trainingSongs"]+" total x "+barfDietCurrentPrice($item[love song of icy revenge])+" Meat each = "+s.uses["trainingSongs"]*barfDietCurrentPrice($item[love song of icy revenge])+" Meat across the whole run. Song bonus: +"+barfDietTrainingSongXP()+" familiar XP per combat, "+s.uses["trainingSongXP"]+" total, in addition to normal combat XP.","blue");
        print("Yeti charging: target "+s.uses["requiredYetiCharge"]+" reached once; projected peak "+s.uses["yetiHighWater"]+" XP. No repeated refill to that target after spending XP. Required end reserve: "+barfSetting("YetiReserveXP",0)+" XP.","blue");
        print("Trainer ending XP: Chest "+s.chestXP+", Yeti "+s.yetiXP+"; songs budgeted "+s.uses["trainingSongs"]+". Trainer buff opportunity costs are included.","blue");
        print("Training: "+s.uses["chestTrainingTurns"]+" Chest + "+s.uses["yetiTrainingTurns"]+" Yeti paid encounters; supplies "+round(s.trainingCost)+" Meat; farming income foregone versus Jill in those same encounters "+round(s.trainingOpportunity)+". Both are already reflected in net profit, not added again.","blue");
        print("Looking Cool policy: cover every paid BARF encounter, including noncombats and trainer fights; reserve one-liver refresh drinks and train the Yeti while coverage remains. A plan with any uncovered encounter is rejected.","blue");
        print("Yeti XP spent: "+s.uses["yetiXPSpent"]+" total (225 per Looking Cool refresh; 400 for the daily double).","blue");
        if(s.uses["initialColdRequired"]>0){
            print("Required drink: one Dreadsylvanian cold-fashioned, 4 drunkenness, with the 400-XP daily double. Ode/additive bonuses apply once; base adventures are doubled.","blue");
            print("Cold-fashioned exception: fixed 100000-Meat planning value, including owned copies; at most one planned. Live purchases are capped at that price.","blue");
        }else print("Yeti's once-daily adventure double is already used; no second double or mandatory four-liver drink is assumed.","blue");
        print("Looking Cool: starts at "+barfTwoDayInitialEffects[$effect[Looking Cool]]+" turns; "+s.uses["coolRefreshes"]+" refreshes; "+s.uses["coolCovered"]+" covered / "+s.uses["coolUncovered"]+" uncovered paid encounters; ends at "+barfDietDuration(s,$effect[Looking Cool])+" turns. Its +100% Meat and Item bonuses are removed for uncovered encounters.","blue");
        if(s.uses["coolRefreshes"]>0)for n from 1 to s.uses["coolRefreshes"]
            print("  Looking Cool +100 after "+s.uses["coolRefreshTurn:"+n]+" paid encounters; duration then "+s.uses["coolRefreshDuration:"+n]+" turns.","blue");
        barfDietComparisonReport(s);
        print("Stillsuit: "+barfDietPourSummary(s)+". Each pour uses all sweat available then; ordinary drinks compete for the same liver in complete-plan comparisons. New Buzzed bonuses receive no value.","blue");
        print("Ordered schedule:","blue");
        foreach i,row in split_string(s.schedule,"\n"){
            if(row=="")continue;string[int] c=split_string(row,"\t");
            if(c[0]=="consume"){
                foreach j,e in barfTwoDayItems if(to_int(e.target)==c[1].to_int()&&(e.crafted||e.special=="synthesis")){
                    string recipe="";foreach part,q in e.ingredients recipe+=q+" "+part+"; ";
                    print(e.special=="synthesis"?"  synthesis candy pair: "+recipe+" (cost included above)":e.target.tradeable?"  craft NEW "+e.target+" using "+recipe+" (owned meal copies remain untouched)":"  use owned "+e.target+" first; craft missing copies using "+recipe,"blue");
                }
                item consumed=to_item(c[1].to_int());string delayed="";
                if(barfDietCandidateDetails contains consumed&&barfDietCandidateDetails[consumed].delayedCombats>0)
                    delayed="; plus "+barfDietCandidateDetails[consumed].delayedMinimum+" minimum / "
                        +barfDietCandidateDetails[consumed].delayedAverage+" expected adventures after four modeled combats";
                print("  "+(consumed==$item[none]?"cast Sweet Synthesis for Greed":"consume 1 "+consumed)+"; preparations="+(replace_string(c[2],"bare;","").to_string()==""?"none":replace_string(c[2],"bare;",""))+"; "+(c[3]=="0"?"":c[3]=="1"?"Yeti: Looking Cool; ":"Yeti: double adventures; ")+"adventures="+c[5]+" minimum / "+c[6]+" expected"+delayed,"blue");}
            else if(c[0]=="capacity")print("  equip "+barfTwoDayCapacityItems[c[1].to_int()]+"; mask="+c[2],"blue");
            else if(c[0]=="noodleSpleen")print("  eat 1 Tubetto Gelatto; choose spleen; preparations="+c[2]+"; adventures="+c[5]+" minimum / "+c[6]+" expected","blue");
            else if(c[0]=="extra")print("  use 1 "+to_item(c[1].to_int())+"; no organ space; adventures="+c[2]+" minimum / "+c[3]+" expected","blue");
            else if(c[0]=="resource"&&index_of(c[1],"wish:")==0)print("  use a remaining free monkey-paw wish for "+to_effect(substring(c[1],5).to_int()),"blue");
            else if(c[0]=="resource")print("  "+(c[1]=="sweat"?"cast Sweat Out Some Booze":c[1]=="aug16"?"cast Aug. 16th: Roller Coaster Day!":"use 1 "+to_item(c[2].to_int()))+"; opportunity cost="+c[3],"blue");
            else if(c[0]=="phase")print("  "+c[1],"green");
            else if(c[0]=="farm")print("  farm "+c[1]+" paid encounters in capacity stage "+c[2]+" (stage income recalculated per encounter)","blue");
            else if(c[0]=="distill")print("  pour ALL "+c[1]+" drams, gain "+c[2]+" adventures; Buzzed duration "+c[3],"blue");
            else if(c[0]=="pourSkip")continue;
            else print("  "+replace_string(row,"\t"," / "),"blue");
        }
        print("Cash purchases budget: "+round(s.cash)+"; estimated liquid farming income "+round(s.liquidIncome)+". Item values do not fund purchases unless sold.","blue");
        print("Farming: "+s.turns+" expected paid encounters (adaptive, replan from each actual roll); estimated income "+round(s.income)+" Meat. Opportunity costs "+round(s.cost)+"; today's net "+round(s.income-s.cost)+"; tomorrow's distinct-effect value "+round(barfDietTomorrowValue(s))+"; combined "+round(barfDietScore(s))+".","blue");
        if(baseline>=0)print("Gain over the complete fallback diet: "+round(barfDietScore(s)-baseline)+" Meat under this model.","blue");
        foreach id,keep in s.retained if(keep)print("Retain "+to_effect(id)+": +"+barfDietEffectAt(to_effect(id),s.effects[id]).weight+" lb, "+s.effects[id]+" turns.","blue");
        print("Retain Smart Drunk: +20 lb, ONE turn. Vintage is the final consumption; farming cannot follow it.","blue");
        barfTwoDayState withoutSmart=barfDietClone(s);withoutSmart.effects[to_int($effect[Smart Drunk])]=0;
        print("Smart Drunk credit: "+round(barfDietTomorrowValue(s)-barfDietTomorrowValue(withoutSmart))+" Meat, assuming "+barfSetting("TomorrowPaidTurnsBeforeFK",0)+" paid turns before tomorrow's Mimic free fights. Any paid adventure first removes this one-turn buff; set teresBarfTomorrowPaidTurnsBeforeFK if one is planned. FK prep/pledge/reminisce are intended to be free; failures or external hooks can invalidate that assumption.","orange");
        print("Rollover outfit: "+(barfTwoDayRolloverGoal==""?"your manually verified outfit":barfTwoDayRolloverGoal),"blue");
        print("Minimum adventures to leave BEFORE Vintage: "+max(0,200-barfTwoDayRollover-barfDietNightcapMinimum())+". Vintage yield "+barfDietNightcapMinimum()+"; conservative TOTAL rollover "+barfTwoDayRollover+" (base included, not added again); conservative remaining adventures "+floor(s.minimumAdventures)+"; projected tomorrow "+barfDietProjectedStart(s,0)+".","blue");
        string[int] schedule;foreach i,row in split_string(s.schedule,"\n")schedule[i]=row;
        map_to_file(schedule,"teres-barf-diet-plan.tsv");
    }
    if(get_property("teresBarfCopiedGoblinMeat")==""||get_property("teresBarfCopiedGoblinWeight")=="")
        print("Extrovermectin is evaluated only with a supplied measured copied-goblin payout and its matching weight (teresBarfCopiedGoblinMeat / CopiedGoblinWeight); 660-lb daily-block averages are not rescaled to 500 lb. No casing adventures are counted.","orange");
    print("Empirical calibration: "+round(barfTwoDayWeightCalibration)+" Meat per additional lb for the whole tomorrow block; ATM-only, excludes non-Mimic fights. Local proportional estimate around 660-700 lb; first 40 incremental lb at full credit, further pounds at "+min(100,barfSetting("WeightBeyond40Percent",50))+"% credit (teresBarfWeightBeyond40Percent). This taper is a conservative assumption, not measured diminishing returns. Today uses native familiar/gear modifiers separately.","blue");
    foreach i,line in split_string(barfTwoDayWarnings,"\n")if(line!="")print(line,"orange");
    print("Practical planner: exact-size organ fills with conservative Pareto checks, a small candidate menu, fixed baseline gear and explicit capacity swaps, including bounded same-organ grouping and reserved-gear deferral comparisons. It compares complete starting diets, early familiar-XP food, greedy late-menu prefixes and the top 12 estimated joint buff pairs; accepted clear/refill state changes trigger another bounded clearer pass. Stillsuit allocations compare zero to four pours at sampled sweat splits against ordinary drinks using complete schedules; yields come from actual forecast sweat, not fixed amounts. Clearers are reconsidered after training and capacity refills as well as accepted clear/refill changes. Up to two improvement passes stop early when a pass finds no gain; normal planning has no wall-clock cutoff and finishes the finite comparisons. The complete fallback is secured first; no incomplete alternative can replace it. This remains a heuristic, not a claim of global optimality. Delayed payout/variable consumables, paid or unsupported recipes, random wine effects, paid wishes and future free-fight detours are excluded. Remaining free paw wishes compete under one shared daily budget. Training forecasts use actual starting XP, fixed trainer gear, active-stillsuit sweat, and your observed one-song kill per training combat, with +5 song XP added once to normal familiar XP; free VHS training can reduce paid training below this forecast. Fork/mug projections use the conservative base-only floor model (30%, or 50% for salad/beer); primary planners disagree on rounding/scope, so combined Yeti/helper expected yields remain an approximation. Expected farming uses mean yields; the reserve uses minimum yields. Farming counts and sweat forecasts are conditional: stop at the actual reserve and replan after every real action.","orange");
}

void barfDietCandidateReport(boolean details){
    int active=0;int food=0;int booze=0;int spleen=0;int synthetic=0;
    foreach i,e in barfTwoDayItems{
        if(e.target==$item[none])synthetic+=1;
        boolean ordinary=barfDietRegularFillItem(e)&&(barfDietOrganSize(e,"food")>0||barfDietOrganSize(e,"booze")>0||barfDietOrganSize(e,"spleen")>0);
        if(ordinary){
            active+=1;
            if(barfDietOrganSize(e,"food")>0)food+=1;
            if(barfDietOrganSize(e,"booze")>0)booze+=1;
            if(barfDietOrganSize(e,"spleen")>0)spleen+=1;
            if(e.target!=$item[none])barfDietCandidateStatus[e.target]="Regular-fill shortlist";
        }else if(e.target!=$item[none]){
            if(barfDietLowQuality(e.target))barfDietCandidateStatus[e.target]="Late retained-weight candidate only";
            else if(!barfDietQuickItem(e))barfDietCandidateStatus[e.target]="Special handler exists; not scheduled by practical search";
            else barfDietCandidateStatus[e.target]=barfDietCanRetain(e.buff)
                ?"Late mixed-organ weight candidate only":"Mixed-organ item not scheduled by practical search";
        }
    }
    int[string] counts;string[string] examples;
    foreach it,status in barfDietCandidateStatus{
        counts[status]+=1;
        if(counts[status]<=3)examples[status]+=(examples[status]==""?"":", ")+it;
    }
    print("Candidate audit: scanned "+count(barfDietCandidateStatus)+" native organ consumables; "+count(barfDietCandidateDetails)
        +" have usable prices and modeled yields. Shortlist: "+food+" foods, "+booze+" drinks, "+spleen+" spleen options ("
        +active+" total, including "+synthetic+" synthesis option(s)). This is a filtered shortlist, not a fixed item catalog.","blue");
    foreach status,n in counts if(status!="Regular-fill shortlist")
        print("  "+n+" — "+status+". Examples: "+examples[status]+".","orange");
    print("Limited-stock/crafted options, distinct relevant effects and ordinary unlimited-stock backups are retained separately. Each organ fill ranks its current legal candidates, then explores a smaller menu; if that cannot fill exactly, it retries the full shortlist.","blue");
    print("Nightcap, organ-clearing resources, meal helpers and non-organ adventure items (chocolates, tofu, clocks) are evaluated separately. Unsupported special/mixed-organ items are not silently counted as ordinary fill options.","blue");
    print("Quality filter: skip crappy/decent/good food and drink except useful retained familiar-weight effects, modeled delayed adventures and Affirmation Cookie (9 base adventures, one/day). Spleen items and unrated/unknown food/drink stay eligible.","blue");
    if(!details){print("Use teresBARF.ash diet-candidates to list the priced candidates, costs, stock, effects and shortlist status without running the optimizer.","blue");return;}
    barfTwoDayItem[int] rows;foreach it,e in barfDietCandidateDetails rows[count(rows)]=e;
    sort rows by to_string(value.target);
    string html="<table border='1' cellpadding='4'><tr><th>Consumable</th><th>Quality</th><th>Full/liver/spleen</th><th>Base min/mean adv</th><th>Meat each</th><th>Owned incl. stash / plan limit</th><th>Supply</th><th>Effect / turns</th><th>Status</th></tr>";
    foreach i,e in rows{
        html+="<tr><td>"+entity_encode(to_string(e.target))+"</td><td>"+entity_encode(e.target.quality)+"</td><td>"+e.fullness+" / "+e.drunkenness+" / "+e.spleen
            +"</td><td>"+e.minimum+" / "+e.average+"</td><td>"+e.price+"</td><td>"+barfDietOwnedAmount(e.target)+" / "+e.dailyRemaining
            +"</td><td>"+(e.crafted?craft_type(e.target)+" recipe":barfDietBuyable[e.target]?"Buyable":"Owned stock only")
            +"</td><td>"+entity_encode(to_string(e.buff))+" / "+e.duration+"</td><td>"+barfDietCandidateStatus[e.target]+"</td></tr>";
    }
    print_html(html+"</table>");
}

barfTwoDayState barfDietPlannedInitial;
barfTwoDayState barfDietPlanned;
boolean barfDietPlanReady;
void barfDietPlan(boolean candidatesOnly){
    barfDietPlanReady=false;
    clear(barfDietRecipePrices);clear(barfDietPricingRecipe);
    barfDietResetSearchCaches();
    clear(barfTwoDayInitialEffects);clear(barfTwoDayStages);clear(barfDietDropIncomeCache);clear(barfDietPrices);clear(barfDietBuyable);clear(barfDietEffectCache);clear(barfDietSpecGear);barfDietBaseModes="";barfDietFastGear=true;barfTwoDayWarnings="";
    if(get_property("autoFillMayoMinder").to_boolean())barfTwoDayWarnings+="This plan assumes Mayo automation is disabled for execution. Queued Mayo is rejected; optional Mayo preparations are not evaluated.\n";
    if(!can_interact()){print("The two-day diet needs aftercore access.","red");return;}
    if(my_inebriety()>inebriety_limit()){print("Already overdrunk; no further farming/normal diet can be planned today.","red");return;}
    if(get_property("mayoInMouth")!=""){print("Handle the queued Mayo before planning an exact diet.","red");return;}
    if(!barfDietReadStash())return;
    // Two independently logged ATM-only sessions; no pygmy/lobster or end-of-fight Meat.
    float todayPerLb=13006.6/660.0;float previousPerLb=14040.76/692.5;
    barfTwoDayWeightCalibration=(todayPerLb+previousPerLb)/2*barfSetting("TomorrowMimicFights",167);
    if(!barfDietRollover()){print("Could not calculate prospective rollover modifiers.","red");return;}
    int stomach=0;int liver=0;int spleen=0;
    foreach i,it in barfTwoDayCapacityItems{stomach+=round(numeric_modifier(it,"Stomach Capacity"));liver+=round(numeric_modifier(it,"Liver Capacity"));spleen+=round(numeric_modifier(it,"Spleen Capacity"));}
    print("Capacity equipment verified from Mafia modifiers: +"+stomach+" fullness, +"+liver+" liver, +"+spleen+" spleen; Stooper adds the final +1 liver.","blue");
    print("Normal farming gear: your hardcoded BARF baseline, kachungasaur parka, Jill and her LED candle. Hat stays unchanged. Training and capacity swaps are forecast explicitly; no gear maximization.","blue");
    print("Milk of magnesium: fixed preparation at the start, unless already used or active; assume one 100-Meat daily offer.","blue");
    if(stomach!=2||liver!=2||spleen!=2){print("Capacity modifiers differ from the expected +2/+2/+2. Update the capacity item list before planning.","red");return;}
    // Current all-items prices are fetched once, then individual candidate costs use Mafia's price cache.
    if(!get_property("teresBarfDietSkipPriceRefresh").to_boolean())mall_prices("allitems");
    if(!have_familiar($familiar[Cooler Yeti])){print("Looking Cool policy requires your Cooler Yeti; no plan generated.","red");return;}
    if(get_property("coolerYetiMode")!=""){print("Consume or clear the Yeti's currently pending drink enhancement, then replan so it is not overwritten or charged twice.","red");return;}
    barfDietDailyTable();barfTwoDayState initial=barfDietInitialState();
    barfTwoDayCopiedWeight=0;
    barfTwoDayStage normal=barfDietBuildStage(0,false,0);
    if(normal.legal&&initial.fullness<=normal.fullness&&initial.drunkenness<=normal.drunkenness&&initial.spleen<=normal.spleen){initial.mask=0;initial.stooper=false;}
    barfTwoDayStage initialGear=barfDietStage(initial);
    if(!initialGear.legal){print("Could not plan the initial farming gear. "+initialGear.error,"red");return;}
    if(get_property("teresBarfCopiedGoblinMeat").to_float()>0&&have_familiar($familiar[Stocking Mimic])
        &&barfDietFixedGear(0,$familiar[Stocking Mimic],0))
        barfTwoDayCopiedWeight=familiar_weight($familiar[Stocking Mimic])+numeric_modifier("Generated:_spec","Familiar Weight")+numeric_modifier("Generated:_spec","Hidden Familiar Weight")
            +($familiar[Stocking Mimic].feasted?10:0)+$familiar[Stocking Mimic].soup_weight;
    barfDietBuildItems();barfDietPruneItems(initial);barfDietEnsureFillers();
    barfDietCandidateReport(candidatesOnly);if(candidatesOnly)return;
    print("Searching the current-price shortlist with actual organs "+initial.fullness+"/"+barfDietFullLimit(initial)+", "+initial.drunkenness+"/"+barfDietLiverLimit(initial)+", "+initial.spleen+"/"+barfDietSpleenLimit(initial)+"; "+initial.adventures+" adventures; "+initial.sweat+" drams.","blue");
    barfTwoDayState plan=barfDietQuickPlan(initial);
    if(plan.cash>=0&&!barfDietReplay(initial,plan))abort("Diet schedule failed ordered replay; no actions are enabled.");
    foreach label,alternative in barfDietComparisons if(!barfDietReplay(initial,alternative))abort("Diet comparison failed ordered replay: "+label+"; no actions are enabled.");
    if(plan.cash>=0&&barfDietMeetsTargets(plan)){
        barfDietPlannedInitial=barfDietClone(initial);barfDietPlanned=barfDietClone(plan);barfDietPlanReady=true;
    }
    barfDietReport(plan,plan.cash<0?-1:barfDietQuickBaseline);
}
void barfDietPlan(){barfDietPlan(false);}

// Original diet notes and template, preserved for reference.
/** ~ Custom Dieting Script for farming with Mimic ~
 * to be used with the TeresMimic.ash script
 */

//  ---- HELPER FUNCTIONS ----

//retrieve and use a usable item
// function downUse(consumable: string, amount: number): void {
//     let consume: Item = Item.get(consumable);
//     if (itemAmount(consume) < 1) retrieveItem(consume, 1);
//     use(consume, amount); //  +1 full cap 60k
// }

//retrieve and drink something
// function downDrink(consumable: string, amount: number): void {
//     let consume: Item = Item.get(consumable);
//     if (itemAmount(consume) < 1) retrieveItem(consume, 1);
//     drink(consume, amount); //  +1 full cap 60k
// }

//retrieve and eat something
// function downFood(consumable: string, amount: number): void {
//     let consume: Item = Item.get(consumable);
//     if (itemAmount(consume) < 1) retrieveItem(consume, 1);
//     eat(consume, amount); //  +1 full cap 60k
// }

//retrieve and chew something
// function downSpleen(consumable: string, amount: number): void {
//     let consume: Item = Item.get(consumable);
//     if (itemAmount(consume) < 1) retrieveItem(consume, 1);
//     chew(consume, amount); //  +1 full cap 60k
// }

// ---- DIET PLANS ----
// function eodDiet(){
    //save spleen for extros
/*      TOTALS - Drunk:1  Fullness: 7  Spleen:
 */
/*
        PLAN:
            Feliz Navidad - 1 drunk
            Strix stix - 2 full
            rat pizza - 2 full
            Apron Meal Kit - 3 full - (sometimes) ****

 */

//     foreach dr in $items[Feliz Navidad]{
//         if (valueOfFamPot(dr) > valueOfOrgan("liver"))
//             drink(dr);
//     }
//     foreach fo in $effects[Sugar-Frosted Pet Guts, ratabunga\, dude!, Beefy Heart]{
//         if (my_fullness() >= fullness_limit())
//             break;
//         if (have_effect(fo) > 0)
//             continue;
//         if (effect_to_item(fo) == $item[Black and White Apron Meal Kit]){
//             if (valueOfFamPot($item[Black and White Apron Meal Kit]) < valueOfOrgan("liver"))
//             continue;
//             if (my_class() == $class[seal clubber]){
//                 retrieve_item($item[cranberries]);
//                 visit_url("inv_use.php?which=3&whichitem=11472");
//                 visit_url("choice.php?whichchoice=1518&option=1&meal=0&ingredients0%5B%5D=672");
//             } else if (my_class() == $class[pastamancer]){
//                 retrieve_item($item[philosopher's scone]);
//                 visit_url("inv_use.php?which=3&whichitem=11472");
//                 visit_url("choice.php?whichchoice=1518&option=1&meal=1&ingredients1%5B%5D=4956");
//             }else
//                 abort();
//         } else if (valueOfFamPot(effect_to_item(fo)) > valueOfOrgan("stomach")){
//             eat(effect_to_item(fo));
//         }
//     }

// }


// ---- MAIN EXPORT FUNCTION ----
// export function garboDiet() {

/*  old diet plan from hobo
	 ----   DIET PLAN ----
	> hobopolis adv drinks 5d 5f 0s
	> Dread cold-fashioned  9d 5f 0s
	> blood-drive sticker/voodoo snuff/antimatter wad  9d 5f 15s
	> fermented pickle juice  14d 5f 10s
	> Slider   14d 10f 5s
	> Mr. Burnsger 12d 14f 5s
	> Doc Clock 16d 13f 5s
	> tin cup 16d 15f 5s
	> Hodge blanket 18d 15f 5s
	> melange 15d 12f 5s
	> 3x mojo filter 15d 12f 2s
	> dog hair/distention pill 14d 11f 2s
	> cuppa Voraci/sweet tooth tea 13d 10f 2s
	> Gets-you-drunk 15d 10f 2s
	> Dread dank and stormy 19d 10f 2s
	> ghost pepper 19d 12f 2s
	> cookie 19d 13f 2s
 */




// }
