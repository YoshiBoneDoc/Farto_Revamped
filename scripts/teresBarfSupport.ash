import iotm.ash;

// BARF-only policy. Shared hooks call these only when script=BARF.
int barfSetting(string name, int fallback){
    string value = get_property("teresBarf" + name);
    return value == "" ? fallback : max(0, value.to_int());
}

int barfBaseMeat(){ return barfSetting("BaseMeat", 250); }

int barfHorizon(){
    return max(0, get_property("_teresBarfTurnsRemaining").to_int());
}

float barfMeatPerWeight(float pounds){
    familiar farmer=$familiar[Jill-of-All-Trades];
    float weight=max(1.0,familiar_weight(farmer)+numeric_modifier("Familiar Weight")+numeric_modifier("Hidden Familiar Weight")
        +(farmer.feasted?10:0)+farmer.soup_weight);
    float factor=have_equipped($item[LED candle])&&get_property("ledCandleMode")=="ultraviolet"?1.5:1;
    float percent=numeric_modifier("Familiar Weight Percent");
    float before=floor(weight*(1+percent/100))*factor;float after=floor((weight+pounds)*(1+percent/100))*factor;
    // Installed Mafia: LED changes leprechaun weight, rather than multiplying the final payout.
    return barfBaseMeat()*((220*after)**0.5+2*after-(220*before)**0.5-2*before)/100;
}

float barfItemEffectRate(effect buff){
    float extra = numeric_modifier(buff,"Item Drop");
    if (extra == 0) return 0;
    float value = 0;
    float[monster] encounters = appearance_rates($location[Barf Mountain]);
    foreach mob, frequency in encounters {
        if (frequency <= 0) continue;
        foreach drop, rate in item_drops(mob){
            if (rate <= 0 || !drop.tradeable) continue;
            int price = max(autosell_price(drop),historical_price(drop));
            float before = min(100.0,rate*(1+numeric_modifier("Item Drop")/100));
            float after = min(100.0,rate*(1+(numeric_modifier("Item Drop")+extra)/100));
            value += frequency * price * (after-before)/10000;
        }
    }
    return value;
}

float barfEffectRate(effect buff){
    return barfBaseMeat() * numeric_modifier(buff, "Meat Drop") / 100
        + barfMeatPerWeight(numeric_modifier(buff, "Familiar Weight"))
        + barfItemEffectRate(buff);
}

int barfAdventureValue(){
    int configured = barfSetting("AdventureValue", 0);
    if (configured > 0) return configured;
    // Use actual equipped Meat Drop; item drops are deliberately not assumed.
    int configuredGeneral = get_property("valueOfAdventure").to_int();
    return max(configuredGeneral, max(1, round(barfBaseMeat() * (1 + numeric_modifier("Meat Drop") / 100))));
}

int barfPrice(item target){
    if (!target.tradeable) return item_amount(target) > 0 ? 0 : -1;
    int price = historical_price(target);
    if (price <= 0 || historical_age(target) > 1) price = mall_price(target);
    return max(autosell_price(target), price);
}

boolean barfAcquire(item target, int maximum){
    if (item_amount(target) > 0) return true;
    if (closet_amount(target) > 0 && take_closet(1, target)) return true;
    if (storage_amount(target) > 0 && can_interact() && take_storage(1, target)) return true;
    if (!target.tradeable || maximum <= 0) return false;
    return buy(1, target, min(maximum, barfSetting("MaxItemPrice", 100000))) == 1;
}

boolean barfWandererDue(string monsterPref, string turnPref){
    if (get_property(monsterPref) == "") return false;
    string counter = monsterPref == "spookyVHSTapeMonster" ? "Spooky VHS Tape Monster" : "Club 'Em Into Next Week Monster";
    return get_counters(counter,0,0) != "" || (get_property(turnPref).to_int() >= 0
        && total_turns_played() >= get_property(turnPref).to_int() + 8);
}

boolean barfGoblinDue(){
    return get_property("clubEmNextWeekMonster").to_monster() == $monster[sausage goblin]
        && barfWandererDue("clubEmNextWeekMonster", "clubEmNextWeekMonsterTurn");
}

boolean barfPlannedGoblinSwap(boolean stooper){
    return !stooper&&barfGoblinDue()&&have_familiar($familiar[Stocking Mimic]);
}

boolean barfVhsDue(){ return barfWandererDue("spookyVHSTapeMonster", "spookyVHSTapeMonsterTurn"); }

familiar barfVhsFamiliar(){
    boolean charged=get_property("_teresBarfPlannedExecution").to_boolean()&&get_property("_teresBarfPlanYetiCharged").to_boolean();
    if(have_familiar($familiar[Chest Mimic])&&$familiar[Chest Mimic].experience<barfSetting("ChestXP",950))
        return $familiar[Chest Mimic];
    if(!charged&&have_familiar($familiar[Cooler Yeti])&&$familiar[Cooler Yeti].experience<barfSetting("YetiXP",2000))
        return $familiar[Cooler Yeti];
    if(have_familiar($familiar[Stocking Mimic]))return $familiar[Stocking Mimic];
    return $familiar[Jill-of-All-Trades];
}

familiar barfTrainingFamiliar(){
    if (have_familiar($familiar[Chest Mimic])
        && $familiar[Chest Mimic].experience < barfSetting("ChestXP", 950)) return $familiar[Chest Mimic];
    if (have_familiar($familiar[Cooler Yeti])
        && $familiar[Cooler Yeti].experience < max(400,barfSetting("YetiXP", 2000)
            - get_property("_teresBarfYetiXPSpent").to_int())) return $familiar[Cooler Yeti];
    return $familiar[none];
}

boolean barfTraining(familiar farmer){ return $familiars[Chest Mimic, Cooler Yeti] contains farmer; }

boolean barfMobiusReady(){
    return available_amount($item[11942]) > 0
        && (!get_property("_mobiusRingPrimed").to_boolean() || turns_until_mobius_noncombat_available() == 0);
}

string barfProgressKey(){
    string result = "";
    foreach pref in $strings[_clubEmNextWeekUsed,clubEmNextWeekMonster,_chainedPurpleCandleMonster,
        spookyVHSTapeMonster,_mobiusStripEncounters,_bczRefractedGazeCasts,
        shrunkenHeadZombieHP,_sausageFights,lastEncounter]
        result += get_property(pref) + ":";
    foreach buff in $effects[Everything Looks Red,Everything Looks Yellow,Everything Looks Green,Everything Looks Purple]
        result += have_effect(buff) + ":";
    return result;
}

boolean barfEarlyJill(){
    string durations = get_property("_teresBarfEarlyWeightDurations");
    if (durations == "") return false;
    int elapsed = total_turns_played() - get_property("_teresBarfEarlyWeightStart").to_int();
    string[int] initial = split_string(durations, ",");
    int active = 0;
    foreach i, duration in initial if (duration.to_int() > elapsed) active += 1;
    return active * 2 > count(initial);
}

boolean barfHeadReady(){
    return available_amount($item[shrunken head]) > 0 && get_property("shrunkenHeadZombieHP").to_int() <= 0;
}

boolean barfNeedsFruit(){
    foreach fruit in $items[antique watermelon, classic banana, quince]
        if (!get_property("_teresBarfFruit" + to_int(fruit)).to_boolean()) return true;
    return false;
}

familiar barfChooseFamiliar(){
    string mode = get_property("_teresBarfMode");
    if (($strings[battlefield, goat] contains mode) && have_familiar($familiar[Patriotic Eagle]))
        return $familiar[Patriotic Eagle];
    if (barfVhsDue() && mode != "goblinSeed")return barfVhsFamiliar();
    if (mode == "goblinSeed" || (mode != "battlefield" && barfGoblinDue())) return $familiar[Stocking Mimic];
    if (barfEarlyJill() && have_familiar($familiar[Jill-of-All-Trades])) return $familiar[Jill-of-All-Trades];
    familiar trainee = barfTrainingFamiliar();
    if (trainee != $familiar[none]) return trainee;
    if (have_familiar($familiar[Jill-of-All-Trades])) return $familiar[Jill-of-All-Trades];
    abort("BARF requires Jill-of-All-Trades after the familiar training goals.");
    return $familiar[none];
}

void barfRecovery(){
    int combatMP = max(50, 3 * mp_cost($skill[Weapon of the Pastalord]));
    set_property("hpAutoRecovery", min(1.0, 750.0 / max(1, my_maxhp())));
    set_property("hpAutoRecoveryTarget", min(1.0, 1000.0 / max(1, my_maxhp())));
    set_property("mpAutoRecovery", min(1.0, to_float(combatMP) / max(1, my_maxmp())));
    set_property("mpAutoRecoveryTarget", min(1.0, to_float(max(150, combatMP)) / max(1, my_maxmp())));
}

item barfFamiliarGear(familiar farmer){
    if (farmer == $familiar[Jill-of-All-Trades] && available_amount($item[LED candle]) > 0)
        return $item[LED candle];
    if (($familiars[Chest Mimic, Cooler Yeti] contains farmer) && available_amount($item[tiny stillsuit]) > 0)
        return $item[tiny stillsuit];
    if (farmer == $familiar[Skeleton of Crimbo Past]
        && available_amount($item[small peppermint-flavored sugar walking crook]) > 0)
        return $item[small peppermint-flavored sugar walking crook];
    return $item[amulet coin];
}

item[slot] barfBaselineOutfit(){
    item[slot] gear;
    gear[$slot[back]]=$item[carpe];
    gear[$slot[shirt]]=$item[Jurassic Parka];
    gear[$slot[weapon]]=$item[June cleaver];
    gear[$slot[off-hand]]=$item[Half a Purse];
    gear[$slot[pants]]=$item[Galapagosian Cuisses];
    gear[$slot[acc1]]=$item[mafia thumb ring];
    gear[$slot[acc2]]=$item[cheap sunglasses];
    gear[$slot[acc3]]=$item[yamtility belt];
    gear[$slot[familiar]]=$item[LED candle];
    return gear;
}

item[slot] barfFarmingOutfit(familiar farmer){
    item[slot] gear=barfBaselineOutfit();
    string mode=get_property("_teresBarfMode");
    boolean goblin=farmer==$familiar[Stocking Mimic];
    gear[$slot[familiar]]=barfFamiliarGear(farmer);
    if(goblin&&get_property("_clubEmNextWeekUsed").to_int()<5&&available_amount($item[legendary seal-clubbing club])>0)
        gear[$slot[weapon]]=$item[legendary seal-clubbing club];
    if(goblin&&have_effect($effect[Everything Looks Purple])==0&&available_amount($item[Roman Candelabra])>0)
        gear[$slot[off-hand]]=$item[Roman Candelabra];
    else if(barfHeadReady()&&(goblin||mode=="goat"))gear[$slot[off-hand]]=$item[shrunken head];
    if(mode!="battlefield"&&available_amount($item[designer sweatpants])>0&&get_property("sweat").to_int()<100)
        gear[$slot[pants]]=$item[designer sweatpants];
    if(mode=="battlefield"){
        // Frat uniform opens the side of the battlefield containing War Hippies;
        // this detour uses the Hippy Uniform side instead. Hat Trick keeps the hat.
        gear[$slot[pants]]=$item[bullet-proof corduroys];
        gear[$slot[acc2]]=$item[round purple sunglasses];
        gear[$slot[acc3]]=$item[blood cubic zirconia];
        if(available_amount(gear[$slot[familiar]])==0)
            gear[$slot[familiar]]=available_amount($item[tiny stillsuit])>0?$item[tiny stillsuit]:$item[none];
    }else{
        slot[int] slots;slots[0]=$slot[acc2];slots[1]=$slot[acc3];slots[2]=$slot[acc1];
        int n=0;
        if(!goblin&&have_effect($effect[Everything Looks Red])==0&&available_amount($item[everfull dart holster])>0)
            gear[slots[n++]]=$item[everfull dart holster];
        if(n<3&&barfNeedsFruit()&&available_amount($item[Portable Laughing Stock])>0)
            gear[slots[n++]]=$item[Portable Laughing Stock];
        if(n<3&&barfMobiusReady())gear[slots[n]]=$item[11942];
    }
    return gear;
}

    // Hats cannot be changed in Hat Trick.
    // Hat Trick equipment remains locked; the battlefield outfit is checked before adventuring.
string barfEquipmentKey(){
    string result = "";
    foreach spot in $slots[hat,weapon,off-hand,back,shirt,pants,acc1,acc2,acc3,familiar]
        result += to_int(equipped_item(spot)) + ":";
    return result;
}

item[slot] barfTrainingOutfit(){
    item[slot] outfit;
    outfit[$slot[back]] = $item[carpe];
    outfit[$slot[shirt]] = $item[Unkillable Skeleton's breastplate];
    outfit[$slot[weapon]] = $item[yule hatchet];
    outfit[$slot[off-hand]] = $item[latte lovers member's mug];
    outfit[$slot[pants]] = $item[designer sweatpants];
    outfit[$slot[acc1]] = $item[teacher's pen];
    outfit[$slot[acc2]] = $item[teacher's pen];
    outfit[$slot[acc3]] = $item[mafia thumb ring];
    outfit[$slot[familiar]] = $item[tiny stillsuit];
    if (have_effect($effect[Everything Looks Red]) == 0 && available_amount($item[everfull dart holster]) > 0)
        outfit[$slot[acc3]] = $item[everfull dart holster];
    if (barfMobiusReady()) outfit[$slot[acc2]] = $item[11942];
    if (barfNeedsFruit() && available_amount($item[Portable Laughing Stock]) > 0)
        outfit[$slot[acc1]] = $item[Portable Laughing Stock];
    return outfit;
}

boolean barfTrainingBuff(effect buff){
    return $effects[Heart of White, Candied Devil, Blue Swayed, Curiosity of Br'er Tarrypin] contains buff;
}

// Shared by the forecast and the live path; hooks must preserve capacity swaps.
item[slot] barfPlannedOutfit(int mask,familiar farmer,int trainer,boolean chargePants){
    item[slot] gear=trainer>0?barfTrainingOutfit():barfBaselineOutfit();
    if(trainer==0){
        if(chargePants&&available_amount($item[designer sweatpants])>0)gear[$slot[pants]]=$item[designer sweatpants];
        if(mask%2==1)gear[$slot[shirt]]=$item[devilbone corset];
        if((mask/2)%2==1)gear[$slot[acc3]]=$item[angelbone chopsticks];
        if((mask/4)%2==1)gear[$slot[acc2]]=$item[angelbone dice];
        if((mask/8)%2==1)gear[$slot[acc1]]=$item[devilbone rosary];
        if((mask/16)%2==1){
            slot spot=have_skill($skill[Double-Fisted Skull Smashing])&&weapon_hands(gear[$slot[weapon]])==1?$slot[off-hand]:$slot[weapon];
            gear[spot]=$item[angelbone totem];
        }
        if((mask/32)%2==1)gear[$slot[pants]]=$item[devilbone greaves];
        gear[$slot[familiar]]=barfFamiliarGear(farmer);
        if(available_amount(gear[$slot[familiar]])==0)gear[$slot[familiar]]=available_amount($item[tiny stillsuit])>0?$item[tiny stillsuit]:$item[none];
    }
    return gear;
}
item[slot] barfPlannedOutfit(int mask,familiar farmer,int trainer){return barfPlannedOutfit(mask,farmer,trainer,false);}

slot barfLiveOpenAccessory(item[slot] gear,int mask){
    foreach spot in $slots[acc2,acc3,acc1]{
        if(spot==$slot[acc2]&&(mask/4)%2==1
            ||spot==$slot[acc3]&&(mask/2)%2==1
            ||spot==$slot[acc1]&&(mask/8)%2==1)continue;
        if($items[11942,blood cubic zirconia,everfull dart holster] contains gear[spot])continue;
        return spot;
    }
    return $slot[none];
}

item[slot] barfLiveMobiusOutfit(item[slot] gear,int mask){
    if(!barfMobiusReady())return gear;
    slot spot=barfLiveOpenAccessory(gear,mask);
    if(spot!=$slot[none])gear[spot]=$item[11942];
    return gear;
}

item[slot] barfLiveDartOutfit(item[slot] gear,int mask){
    // Temporary live swap: never put this in the fixed outfit forecast, and
    // never displace a capacity accessory after its organ room is occupied.
    if(have_effect($effect[Everything Looks Red])==0
        &&get_property("_dartsLeft").to_int()>0
        &&available_amount($item[everfull dart holster])>0){
        slot spot=barfLiveOpenAccessory(gear,mask);
        if(spot!=$slot[none])gear[spot]=$item[everfull dart holster];
    }
    return gear;
}

item[slot] barfLiveFruitOutfit(item[slot] gear,int mask){
    if(barfNeedsFruit()&&available_amount($item[Portable Laughing Stock])>0){
        slot spot=barfLiveOpenAccessory(gear,mask);
        if(spot!=$slot[none])gear[spot]=$item[Portable Laughing Stock];
    }
    return gear;
}

item[slot] barfLiveGoblinOutfit(item[slot] gear,int mask){
    if((mask/16)%2==0&&get_property("_clubEmNextWeekUsed").to_int()<5
        &&available_amount($item[legendary seal-clubbing club])>0)
        gear[$slot[weapon]]=$item[legendary seal-clubbing club];
    if((mask/16)%2==0){
        if(have_effect($effect[Everything Looks Purple])==0&&available_amount($item[Roman Candelabra])>0)
            gear[$slot[off-hand]]=$item[Roman Candelabra];
        else if(barfHeadReady())gear[$slot[off-hand]]=$item[shrunken head];
    }
    return gear;
}

item[slot] barfLiveYellowOutfit(item[slot] gear,int mask){
    // Once capacity gear is occupied, use a spare accessory at BARF rather than
    // removing a capacity piece for a battlefield detour.
    if(mask==0||have_effect($effect[Everything Looks Yellow])>0
        ||available_amount($item[blood cubic zirconia])==0
        ||(!have_skill($skill[Spit Jurassic Acid])||$skill[Spit Jurassic Acid].dailylimit==0)
            &&item_amount($item[yellow rocket])==0)return gear;
    slot spot=barfLiveOpenAccessory(gear,mask);
    if(spot!=$slot[none])gear[spot]=$item[blood cubic zirconia];
    return gear;
}

void barfTrainingBuffs(){
    foreach potion in $items[white candy heart, deviled candy egg]{
        effect buff = effect_modifier(potion, "Effect");
        if (have_effect(buff) == 0
            && (!barfAcquire(potion, barfSetting("MaxItemPrice",100000)) || !use(1,potion)))
            abort("BARF training could not acquire " + buff + ".");
    }
    while (have_effect($effect[Blue Swayed]) <= 50){
        int before = have_effect($effect[Blue Swayed]);
        if (!barfAcquire($item[pulled blue taffy], barfSetting("MaxItemPrice",100000))
            || !use(1,$item[pulled blue taffy]) || have_effect($effect[Blue Swayed]) <= before)
            abort("BARF training could not increase Blue Swayed.");
    }
    if (have_skill($skill[Curiosity of Br'er Tarrypin]) && have_effect($effect[Curiosity of Br'er Tarrypin]) == 0){
        if (my_mp() < mp_cost($skill[Curiosity of Br'er Tarrypin])) restore_mp(mp_cost($skill[Curiosity of Br'er Tarrypin]));
        if (!use_skill(1,$skill[Curiosity of Br'er Tarrypin])) abort("BARF training could not cast Curiosity.");
    }
}

void barfTrainingLatteRefill(){
    if(get_property("latteIngredients")!="cajun,vitamins,rawhide"
        &&get_property("_latteRefillsUsed").to_int()<3
        &&contains_text(get_property("latteUnlocks"),"cajun")
        &&contains_text(get_property("latteUnlocks"),"vitamins")
        &&contains_text(get_property("latteUnlocks"),"rawhide")
        &&!cli_execute("latte refill cajun vitamins rawhide"))
        print("BARF training latte refill failed; continuing with the available XP gear.","orange");
}

void barfTrainingGear(){
    item[slot] outfit = barfTrainingOutfit();
    foreach spot, target in outfit
        if (equipped_item(spot) != target && !equip(spot,target))
            abort("BARF training could not equip " + target + " in " + spot + ".");
    barfTrainingLatteRefill();
    barfTrainingBuffs();
    if (!retrieve_item(10,$item[love song of icy revenge]))
        abort("BARF training needs love songs of icy revenge.");
    set_property("_teresBarfGearKey", "training:" + my_familiar());
}

void barfGear(){
    set_property("_teresBarfVhsEncounter",barfVhsDue());
    if(get_property("_teresBarfPlannedExecution").to_boolean()){
        int trainer=get_property("_teresBarfPlanTrainer").to_int();
        if(trainer>0&&get_property("_teresBarfPlanMask").to_int()>0)
            abort("BARF cannot swap out occupied capacity equipment for the training outfit.");
        familiar farmer=trainer==128?$familiar[Chest Mimic]:trainer==256?$familiar[Cooler Yeti]
            :get_property("_teresBarfPlanStooper").to_boolean()?$familiar[Stooper]:$familiar[Jill-of-All-Trades];
        // A due goblin needs Stocking Mimic even during a planned training block.
        // Keep Stooper once its liver space is occupied.
        if(barfPlannedGoblinSwap(get_property("_teresBarfPlanStooper").to_boolean())){
            farmer=$familiar[Stocking Mimic];trainer=0;
            set_property("_teresBarfPlanTrainer",0);
        }
        // Free copies train an eligible Mimic/Yeti before returning to Stocking Mimic.
        // Keep Stooper/capacity equipment once its extra organ space is occupied.
        else if(barfVhsDue()&&get_property("_teresBarfPlanMask").to_int()==0&&!get_property("_teresBarfPlanStooper").to_boolean()){
            farmer=barfVhsFamiliar();
            trainer=farmer==$familiar[Chest Mimic]?128:farmer==$familiar[Cooler Yeti]?256:0;
            set_property("_teresBarfPlanTrainer",trainer);
        }
        boolean battlefield=get_property("_teresBarfMode")=="battlefield";
        if(!use_familiar(farmer))abort("Planned BARF could not select "+farmer+".");
        item[slot] desired=battlefield?barfFarmingOutfit(farmer)
            :barfPlannedOutfit(get_property("_teresBarfPlanMask").to_int(),farmer,trainer,
                get_property("_teresBarfPlanSweatpants").to_boolean());
        if(!battlefield&&trainer==0){
            int mask=get_property("_teresBarfPlanMask").to_int();
            if(farmer==$familiar[Stocking Mimic]&&barfGoblinDue())desired=barfLiveGoblinOutfit(desired,mask);
            desired=barfLiveMobiusOutfit(desired,mask);
            desired=barfLiveYellowOutfit(desired,mask);
            desired=barfLiveDartOutfit(desired,mask);
            desired=barfLiveFruitOutfit(desired,mask);
        }
        foreach spot,it in desired
            if(equipped_item(spot)!=it&&!equip(spot,it))abort("Planned BARF could not equip "+it+" in "+spot+".");
        string parkaMode=battlefield?"dilophosaur":"kachungasaur";
        if(have_equipped($item[Jurassic Parka])&&get_property("parkaMode")!=parkaMode&&!cli_execute("parka "+parkaMode))abort("Could not set farming parka mode.");
        if(farmer==$familiar[Jill-of-All-Trades]&&get_property("ledCandleMode")!="ultraviolet"&&!cli_execute("ledcandle ultraviolet"))abort("Could not set farming candle mode.");
        foreach fruit in $items[antique watermelon,classic banana,quince]set_property("_teresBarfFruitBefore"+to_int(fruit),item_amount(fruit));
        set_property("_teresBarfEquipment",barfEquipmentKey());barfRecovery();return;
    }
    familiar farmer = barfChooseFamiliar();
    if (!use_familiar(farmer)) abort("BARF could not select " + farmer + ".");
    if (barfFamiliarGear(farmer) == $item[LED candle] && get_property("ledCandleMode") != "ultraviolet")
        cli_execute("ledcandle ultraviolet");
    if (farmer == $familiar[Stocking Mimic] && have_effect($effect[Shortly Wired]) == 0){
        if (!barfAcquire($item[short white], barfSetting("MaxItemPrice",100000)) || !use(1,$item[short white]))
            abort("BARF goblin stalling needs Shortly Wired.");
    }
    if (barfTraining(farmer)) barfTrainingGear();
    else{
        item[slot] gear=barfFarmingOutfit(farmer);
        foreach spot in $slots[weapon,off-hand,back,shirt,pants,acc1,acc2,acc3,familiar]
            if(equipped_item(spot)!=gear[spot]&&!equip(spot,gear[spot]))
                abort("BARF could not equip "+gear[spot]+" in "+spot+".");
        string mode=get_property("_teresBarfMode")=="battlefield"?"dilophosaur":"kachungasaur";
        if(get_property("parkaMode")!=mode&&!cli_execute("parka "+mode))abort("BARF could not set the parka mode.");
        set_property("_teresBarfGearKey","fixed:"+farmer);
    }
    set_property("_teresBarfEquipment", barfEquipmentKey());
    if (have_equipped($item[PirateRealm eyepatch])) abort("BARF outfit must not cap stats with the eyepatch.");
    foreach fruit in $items[antique watermelon, classic banana, quince]
        set_property("_teresBarfFruitBefore" + to_int(fruit), item_amount(fruit));
    barfRecovery();
}

boolean barfPlannedAdventureAllowed(){
    if(!get_property("_teresBarfPlannedExecution").to_boolean())return true;
    int reserve=max(barfSetting("ReserveAdventures",0),get_property("_teresBarfPlanMinimumAdventures").to_int());
    if(my_adventures()<=reserve||my_fullness()>fullness_limit()||my_inebriety()>inebriety_limit()||my_spleen_use()>spleen_limit()
        ||have_effect($effect[Looking Cool])<1||get_property("coolerYetiMode")!="")return false;
    foreach i,id in split_string(get_property("_teresBarfPlanRetained"),",")
        if(id.to_int()>0&&have_effect(to_effect(id.to_int()))<6)return false;
    return true;
}

void barfKnuckleboneRests(){
    if (!have_familiar($familiar[Skeleton of Crimbo Past])
        || get_property("_knuckleboneDrops").to_int() >= 100) return;
    familiar saved = my_familiar();
    try {
        use_familiar($familiar[Skeleton of Crimbo Past]);
        while (get_property("_knuckleboneRests").to_int() < 5
            && get_property("_knuckleboneDrops").to_int() < 100
            && get_property("timesRested").to_int() < total_free_rests()){
            int bones = get_property("_knuckleboneRests").to_int();
            int turns = total_turns_played();
            if (!cli_execute("camp rest free")) break;
            if (total_turns_played() != turns) abort("BARF rest unexpectedly used an adventure.");
            if (get_property("_knuckleboneRests").to_int() <= bones) break;
        }
    } finally { use_familiar(saved); }
}

boolean barfAccordionSong(effect buff){
    // KoLmafia's skill.song flag is false for the classic AT buffs. The
    // installed classskills table places songs at 6000-6028 and 6045-6046;
    // later class expressions at 6036, 6042 and 6044 are deliberately excluded.
    skill source=to_skill(buff);int id=source.id;
    return ((id>=6000&&id<=6028)||(id==6045||id==6046))&&to_effect(source)==buff;
}

int barfSkillBuffCasts(skill source, int turns, int coverage, int manaAvailable){
    if (!have_skill(source)) return 0;
    effect buff = to_effect(source);
    if (buff == $effect[none] || coverage >= turns) return 0;
    int duration = turns_per_cast(source);
    if (duration <= 0) return 0;
    int casts = to_int(ceil(to_float(turns - coverage) / duration));
    int availableCasts = source.dailylimit.to_int();
    if (availableCasts >= 0) casts = min(casts,availableCasts);
    if (casts <= 0) return 0;
    if (barfAccordionSong(to_effect(source)) && coverage == 0){
        int songs = 0;
        foreach active in my_effects() if (barfAccordionSong(active)) songs += 1;
        int capacity = 3 + (boolean_modifier("Four Songs") ? 1 : 0)
            + (have_skill($skill[Mariachi Memory]) ? 1 : 0);
        if (songs >= capacity) return 0;
    }
    int mana = casts * mp_cost(source);
    float value = (turns - coverage) * barfEffectRate(buff);
    // Galaktik is the fallback ceiling: 85 Meat buys roughly 10 MP.
    if (mana * 8.5 >= value && mana > manaAvailable) return 0;
    return casts;
}

void barfSkillBuff(skill source, int turns){
    int casts = barfSkillBuffCasts(source,turns,have_effect(to_effect(source)),my_mp());
    if (casts <= 0) return;
    effect buff = to_effect(source);
    int mana = casts * mp_cost(source);
    if (mana > my_mp() && !restore_mp(mana)) abort("BARF could not fund " + source + ".");
    int before = have_effect(buff);
    if (!use_skill(casts, source) || have_effect(buff) <= before)
        abort("BARF could not acquire " + buff + ".");
}

item[effect] barfPotionChoices(int turns, int[effect] coverage){
    // Scan KoLmafia's ordinary potions; no pocket wishes or costly default commands.
    item[effect] best;
    float[effect] costs;
    foreach target in $items[]{
        if (item_type(target) != "potion" || !target.tradeable) continue;
        effect buff = effect_modifier(target, "Effect");
        int duration = numeric_modifier(target, "Effect Duration").to_int();
        if (buff == $effect[none] || barfTrainingBuff(buff) || duration <= 0 || barfEffectRate(buff) <= 0
            || coverage[buff] >= turns) continue;
        int cached = historical_price(target);
        if (cached <= 0 || cached > barfSetting("MaxItemPrice", 100000)) continue;
        int useful = min(duration, turns - coverage[buff]);
        if (cached >= useful * barfEffectRate(buff)) continue;
        float unitCost = to_float(cached) / duration;
        if (!(best contains buff) || unitCost < costs[buff]){
            best[buff] = target;
            costs[buff] = unitCost;
        }
    }
    return best;
}

void barfPotionBuffs(int turns){
    int[effect] coverage;
    foreach buff in $effects[] coverage[buff] = have_effect(buff);
    item[effect] best = barfPotionChoices(turns,coverage);
    foreach buff, target in best {
        int duration = numeric_modifier(target, "Effect Duration").to_int();
        int price = barfPrice(target);
        int count = 0;
        while (have_effect(buff) < turns && count < 200){
            int useful = min(duration, turns - have_effect(buff));
            if (price <= 0 || price >= useful * barfEffectRate(buff)) break;
            int before = have_effect(buff);
            if (!barfAcquire(target, floor(useful * barfEffectRate(buff)))) break;
            if (!use(1, target) || have_effect(buff) <= before)
                abort("BARF potion failed: " + target);
            count += 1;
        }
    }
}

void barfMaintainBuffs(){
    int turns = barfHorizon();
    foreach source in $skills[]{
        if (have_skill(source) && source.buff && !source.combat
            && !source.walk && !source.expression && !source.shanty
            && !barfTrainingBuff(to_effect(source)) && barfEffectRate(to_effect(source)) > 0) barfSkillBuff(source, turns);
    }
    barfPotionBuffs(turns);
}

int barfKioskAssignment(string page){
    matcher job = create_matcher("(?is)<b>Track Maintenance</b>(?:(?!</td>).)*?name=['\"]?option['\"]?\\s+value=['\"]?([12])",page);
    return job.find() ? job.group(1).to_int() : 0;
}

void barfKiosk(boolean acceptJob){
    string saved = get_property("choiceAdventureScript");
    try {
        set_property("choiceAdventureScript","");
        string page = visit_url("place.php?whichplace=airport_stench&action=airport3_kiosk");
        if (!handling_choice() || last_choice() != 1066) return;
        string[int] choices = available_choice_options();
        foreach option, label in choices if (contains_text(label,"Collect Wages")){
            page = run_choice(option);
            break;
        }
        if (acceptJob && handling_choice() && last_choice() == 1066){
            int option = barfKioskAssignment(page);
            if (option > 0) run_choice(option);
        }
        if (handling_choice() && last_choice() == 1066) run_choice(6);
    } finally { set_property("choiceAdventureScript",saved); }
}

void barfDinseyGarbage(){
    if(get_property("_dinseyGarbageDisposed").to_boolean())return;
    string saved=get_property("choiceAdventureScript");string savedChoice=get_property("choiceAdventure1067");int turn=total_turns_played();
    try{
        set_property("choiceAdventureScript","");set_property("choiceAdventure1067",0);
        visit_url("place.php?whichplace=airport_stench&action=airport3_tunnels");
        if(get_property("_dinseyGarbageDisposed").to_boolean())return;
        if(!handling_choice()||last_choice()!=1067){
            print("BARF: Maintenance Tunnels did not offer waste disposal today.","red");return;
        }
        string[int] choices=available_choice_options();
        if(!(choices contains 6)){
            print("BARF: Waste Disposal option 6 was unavailable; leaving the tunnel choice.","red");
            boolean left=false;
            foreach option,label in choices if(contains_text(to_lower_case(label),"leave")){run_choice(option);left=true;break;}
            if(!left||handling_choice())abort("BARF could not leave Maintenance Tunnels cleanly.");
            return;
        }
        run_choice(6);
        if(handling_choice())abort("BARF waste disposal left an unresolved choice.");
        if(total_turns_played()!=turn)abort("BARF waste disposal unexpectedly spent an adventure.");
        if(!get_property("_dinseyGarbageDisposed").to_boolean())
            print("BARF: waste disposal did not register; continuing without the FunFunds.","red");
    }finally{set_property("choiceAdventureScript",saved);set_property("choiceAdventure1067",savedChoice);}
}

void barfRefreshResin(){
    if (have_effect($effect[resined]) == 0
        && (!use($item[distilled resin]) || have_effect($effect[resined]) == 0))
        print("BARF could not refresh Get Resined after combat; distilled resin use failed.", "red");
}

void barfPostAdventure(){
    barfRefreshResin();
    if(my_adventures()<100&&get_property("_lawOfAveragesUsed")=="0"
        &&have_item($item[law of averages])&&!use(1,$item[law of averages]))
        print("BARF could not use the available Law of Averages; continuing.","orange");
    if (have_equipped($item[Portable Laughing Stock]))
        foreach fruit in $items[antique watermelon, classic banana, quince]
            if (item_amount(fruit) > get_property("_teresBarfFruitBefore" + to_int(fruit)).to_int())
                set_property("_teresBarfFruit" + to_int(fruit), true);
    if (get_property("_lastCombatLost").to_boolean() || have_effect($effect[Beaten Up]) > 0)
        print("Warning: BARF lost a fight; recovering and continuing.", "red");
    if (have_effect($effect[Beaten Up]) > 0)
        cli_execute("cast tongue of the walrus");
    if (get_property("questEStSuperLuber") == "step1") barfKiosk(false);
    if (have_skill($skill[Calculate the Universe])
        && get_property("_universeCalculated").to_int() < get_property("skillLevel144").to_int()
        && reverse_numberology() contains 69)
        cli_execute("numberology 69");
    if (get_property("trainsetPosition").to_int() >= get_property("lastTrainsetConfiguration").to_int() + 42
        && get_workshed() == $item[model train set]){
        visit_url("campground.php?action=workshed");
        trainset();
    }
    // Keep the active farmer equipped; put the stillsuit on an inactive familiar.
    if (!($familiars[Chest Mimic, Cooler Yeti] contains my_familiar())
        && have_familiar($familiar[Animated Macaroni Duck]) && available_amount($item[tiny stillsuit]) > 0
        && familiar_equipped_equipment($familiar[Animated Macaroni Duck]) != $item[tiny stillsuit]){
        familiar saved = my_familiar();
        try {
            use_familiar($familiar[Animated Macaroni Duck]);
            equip($slot[familiar], $item[tiny stillsuit]);
        } finally { use_familiar(saved); }
    }
    // Summon only with surplus MP, never funding a Libram refill.
    while (have_skill($skill[Summon Party Favor])
        && my_mp() >= 150 + mp_cost($skill[Summon Party Favor]))
        if (!use_skill(1, $skill[Summon Party Favor])) break;
    sendAutumnatonToShadowRift();
}
