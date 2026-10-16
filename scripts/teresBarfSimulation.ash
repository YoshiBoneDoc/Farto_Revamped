import TeresMimicDiet.ash;

// Read-only preview: selectors and price lookups only, never gameplay requests.
string barfSimModifiers(effect buff){
    string result = "";
    foreach statName in $strings[Meat Drop,Item Drop,Familiar Weight]{
        float amount = numeric_modifier(buff,statName);
        if (amount == 0) continue;
        if (result != "") result += ", ";
        result += (amount > 0 ? "+" : "") + amount
            + (statName == "Familiar Weight" ? " lbs familiar" : "% " + statName);
    }
    return result == "" ? "no direct farming modifier" : result;
}

int barfSimStock(item target){
    return item_amount(target) + closet_amount(target) + (can_interact() ? storage_amount(target) : 0);
}

void barfSimPrep(){
    print("[SIM] Prep actions still available:","blue");
    if (!can_interact()) print("[SIM] Blocker: actual BARF prep requires aftercore/mall access.","red");
    if (!get_property("stenchAirportAlways").to_boolean() && !get_property("_stenchAirportToday").to_boolean())
        print("[SIM] Dinseylandfill access is not recorded; actual prep checks Barf Mountain access.","red");
    if (my_inebriety() > inebriety_limit()) print("[SIM] Blocker: currently overdrunk.","red");
    if (get_property("mayoInMouth") != "") print("[SIM] Blocker: queued Mayo must be handled before dieting.","red");
    int rests = have_familiar($familiar[Skeleton of Crimbo Past])
        ? max(0,min(5-get_property("_knuckleboneRests").to_int(),
            min(100-get_property("_knuckleboneDrops").to_int(),total_free_rests()-get_property("timesRested").to_int()))) : 0;
    if (rests > 0) print("[SIM] Rest free " + rests + " time(s) with Skeleton of Crimbo Past for knucklebones.");
    print("[SIM] Visit Dinsey kiosk: collect available wages; accept Track Maintenance if offered.");
    if (available_amount($item[SongBoom&trade; BoomBox]) > 0
        && get_property("boomBoxSong") != "Total Eclipse of Your Meat"
        && get_property("_boomBoxSongsLeft").to_int() > 0) print("[SIM] Switch BoomBox to Meat song.");
    if (available_amount($item[Clan VIP Lounge key]) > 0){
        if (get_property("_poolGames").to_int() < 3)
            print("[SIM] VIP pool 1: " + (3-get_property("_poolGames").to_int()) + " game(s).");
        if (!get_property("_clanFortuneBuffUsed").to_boolean()) print("[SIM] VIP fortune buff meat.");
    }
    if (!get_property("concertVisited").to_boolean() && get_property("sidequestArenaCompleted") == "fratboy")
        print("[SIM] Concert 2.");
    if (have_skill($skill[Aug. 16th: Roller Coaster Day!])
        && !get_property("_aug16Cast").to_boolean() && get_property("_augSkillsCast").to_int() < 5)
        print("[SIM] Reserve the remaining August cast for Aug. 16th: Roller Coaster Day! when fullness > 1 during dieting.");
    if (have_skill($skill[Visit your Favorite Bird]) && !get_property("_favoriteBirdVisited").to_boolean())
        print("[SIM] Visit your Favorite Bird once.");
    if (!get_property("_canSeekBirds").to_boolean() && available_amount($item[Bird-a-Day calendar]) > 0)
        print("[SIM] Read owned Bird-a-Day calendar to unlock today's bird.");
    if (have_skill($skill[Seek out a Bird]) || available_amount($item[Bird-a-Day calendar]) > 0)
        print("[SIM] Seek birds while daily count < 6 and next cost < 314 MP; currently "
            + get_property("_birdsSoughtToday") + " sought.");
    if (available_amount($item[Mayam Calendar]) > 0 && get_property("_mayamSymbolsUsed") == "")
        print("[SIM] Use configured Mayam rings.");
    print("[SIM] Post-adventure chores: available numberology 69; due train reset; Party Favor using only MP above 150.");
}

void barfSimDiet(int[effect] coverage){
    print("[SIM] Diet baseline for current organ room (recomputed during the real run):","blue");
    if (get_property("_teresBarfLimitedRun").to_boolean()
        && my_adventures() >= barfHorizon()+barfSetting("ReserveAdventures",0)){
        print("[SIM] Skip initial diet: existing adventures cover this limited run.");
        return;
    }
    int[item] supplies;
    int[item] prices;
    int marketValue = 0;
    float adventures = 0;
    float profit = 0;
    foreach organ in $strings[spleen,food,booze]{
        int room = max(0,barfOrganRoom(organ)-(organ == "booze" && available_amount($item[tiny stillsuit]) > 0 ? 1 : 0));
        print("[SIM] " + organ + ": " + room + " usable capacity"
            + (organ == "booze" && available_amount($item[tiny stillsuit]) > 0 ? " (1 liver reserved for stillsuit)" : "") + ".");
        if (room == 0) continue;
        barfDietEntry[int] candidates = barfDietCandidates(organ);
        barfDietResult plan = barfOptimizeDiet(candidates,room,barfHorizon(),barfAdventureValue());
        adventures += plan.adventures; profit += plan.profit;
        foreach index, entry in candidates{
            int quantity = plan.quantities[entry.food];
            if (quantity <= 0) continue;
            int duration = (quantity+(entry.kind == "food" ? plan.boosted[entry.food] : 0))*entry.duration;
            marketValue += quantity*entry.price;
            print("[SIM] " + quantity + " x " + (entry.kind == "synthesis" ? "Synthesis: Greed" : entry.food.to_string())
                + ": " + round(quantity*entry.adventures*100)/100.0 + " expected adventures; "
                + quantity*entry.price + " Meat value (" + entry.price + " each)."
                + (entry.buff == $effect[none] ? "" : " " + entry.buff + ": " + barfSimModifiers(entry.buff)
                    + ", +" + duration + " turns."));
            if (entry.buff != $effect[none]) coverage[entry.buff] += duration;
            if (entry.kind == "synthesis"){
                foreach index, candy in barfSynthesisCandies(){ supplies[candy] += quantity; prices[candy] = barfPrice(candy); }
            } else { supplies[entry.food] += quantity; prices[entry.food] = entry.price; }
        }
    }
    int purchases = 0;
    foreach target, quantity in supplies{
        int missing = max(0,quantity-barfSimStock(target));
        purchases += missing*prices[target];
        print("[SIM] Supply " + target + ": need " + quantity + "; owned " + barfSimStock(target)
            + "; buy " + missing + " for ~" + missing*prices[target] + " Meat.");
    }
    print("[SIM] Baseline diet: ~" + round(adventures*100)/100.0 + " adventures; " + marketValue
        + " Meat item value; ~" + purchases + " Meat purchases; ~" + round(profit) + " estimated net value.","blue");
    print("[SIM] Adaptive decisions, outside this baseline: milk if 5 adventures exceed its price; legendary pasta if extra food-buff charges profit; Ode before drinks; pinky ring for wine; Yeti drink buffs while preserving 400 XP.");
    print("[SIM] Recheck Salty Mouth wishes, organ-clearing meals/pills, melange and mojo filters for profit; use available Sweat Out Some Booze for liver room and Aug. 16th for fullness room. These can change the final diet and total cost.");
    if (available_amount($item[tiny stillsuit]) > 0){
        print("[SIM] Keep stillsuit on inactive Macaroni Duck when owned; currently "
            + get_property("familiarSweat") + " drams. Drink profitable distillate when ready (default minimum "
            + barfSetting("DistillAdventures",12) + " adventures); release liver reserve at the end.");
    }
}

void barfSimBuffs(int[effect] coverage){
    print("[SIM] Additional buff candidates after baseline diet:","blue");
    int mana = my_mp();
    int totalMP = 0;
    int songs = 0;
    foreach active in my_effects() if (to_skill(active).song) songs += 1;
    int capacity = 3+(boolean_modifier("Four Songs") ? 1 : 0)+(have_skill($skill[Mariachi Memory]) ? 1 : 0);
    foreach source in $skills[]{
        if (!have_skill(source) || !source.buff || source.combat || source.walk || source.expression || source.shanty) continue;
        effect buff = to_effect(source);
        if (barfTrainingBuff(buff) || barfEffectRate(buff) <= 0) continue;
        int casts = barfSkillBuffCasts(source,barfHorizon(),coverage[buff],mana);
        if (casts <= 0 || (source.song && coverage[buff] == 0 && songs >= capacity)) continue;
        if (source.song && coverage[buff] == 0) songs += 1;
        int cost = casts*mp_cost(source);
        totalMP += cost; mana = max(0,mana-cost);
        coverage[buff] += casts*turns_per_cast(source);
        print("[SIM] Cast " + source + " x " + casts + ": " + cost + " MP; " + buff
            + " (" + barfSimModifiers(buff) + "); projected coverage " + coverage[buff] + " turns.");
    }
    int marketValue = 0;
    int purchases = 0;
    item[effect] potions = barfPotionChoices(barfHorizon(),coverage);
    foreach buff, target in potions{
        int price = barfPrice(target);
        int duration = numeric_modifier(target,"Effect Duration").to_int();
        int quantity = 0;
        while (coverage[buff] < barfHorizon() && quantity < 200){
            int useful = min(duration,barfHorizon()-coverage[buff]);
            if (price <= 0 || price >= useful*barfEffectRate(buff)) break;
            quantity += 1; coverage[buff] += duration;
        }
        if (quantity == 0) continue;
        int missing = max(0,quantity-barfSimStock(target));
        marketValue += quantity*price; purchases += missing*price;
        print("[SIM] Use " + target + " x " + quantity + ": " + buff + " (" + barfSimModifiers(buff)
            + "); " + quantity*price + " Meat value (" + price + " each); buy " + missing
            + " for ~" + missing*price + "; projected coverage " + coverage[buff] + " turns.");
    }
    print("[SIM] Buff candidates: " + totalMP + " MP; " + marketValue + " Meat potion value; ~"
        + purchases + " Meat potion purchases. MP shortfall vs current MP: " + max(0,totalMP-my_mp())
        + " (~" + ceil(max(0,totalMP-my_mp())*8.5) + " Meat at Galaktik fallback prices).","blue");
    print("[SIM] Bird/diet/combat MP and prep rewards are outside these totals; real buff selection rechecks after prep, gear and consumption.");
}

void barfSimulation(){
    print("[SIM] BARF dry run: no purchases, casts, consumption, equipment changes, rests or adventures.","blue");
    print("[SIM] Horizon " + barfHorizon() + " turns; base Meat " + barfBaseMeat()
        + "; adventure value " + barfAdventureValue() + "; item purchase cap " + barfSetting("MaxItemPrice",100000) + " Meat.");
    print("[SIM] Current: " + my_adventures() + " adventures; " + my_meat() + " Meat; HP " + my_hp()
        + "/" + my_maxhp() + "; MP " + my_mp() + "/" + my_maxmp() + "; Meat Drop "
        + numeric_modifier("Meat Drop") + "%; Item Drop " + numeric_modifier("Item Drop")
        + "%; familiar weight " + (familiar_weight(my_familiar())+weight_adjustment()) + " lbs.");
    print("[SIM] Recovery: HP " + min(750,my_maxhp()) + " -> " + min(1000,my_maxhp())
        + "; MP " + min(my_maxmp(),max(50,3*mp_cost($skill[Weapon of the Pastalord]))) + " -> "
        + min(my_maxmp(),max(150,3*mp_cost($skill[Weapon of the Pastalord]))) + " (absolute amounts, recomputed after gear).");
    barfSimPrep();
    print("[SIM] Familiar priority: Jill while short weight buffs last; Chest Mimic to " + barfSetting("ChestXP",950) + " XP; Cooler Yeti to "
        + max(400,barfSetting("YetiXP",2000)-get_property("_teresBarfYetiXPSpent").to_int())
        + " XP after Jill's short buffs expire; then Jill-of-All-Trades. Skeleton gets only five free rests.","blue");
    foreach farmer in $familiars[Chest Mimic,Cooler Yeti,Skeleton of Crimbo Past,Jill-of-All-Trades]
        if (have_familiar(farmer)) print("[SIM] " + farmer + ": " + farmer.experience + " XP."
            + (farmer == $familiar[Skeleton of Crimbo Past] ? " Knucklebones today: " + get_property("_knuckleboneDrops") + "." : ""));
    familiar next = barfChooseFamiliar();
    print("[SIM] Next farmer before prep rewards: " + next + "; familiar item: "
        + (available_amount(barfFamiliarGear(next)) > 0 ? barfFamiliarGear(next).to_string() : "maximize available familiar gear") + ".");
    if (barfFamiliarGear(next) == $item[LED candle]) print("[SIM] Set LED candle ultraviolet.");
    if (barfTraining(next)){
        item[slot] outfit = barfTrainingOutfit();
        foreach spot, target in outfit print("[SIM] Training outfit " + spot + ": " + target + ".");
    } else foreach spot,target in barfFarmingOutfit(next) print("[SIM] Fixed BARF outfit " + spot + ": " + target + ".");
    print("[SIM] Training only: one white candy heart/deviled candy egg when their buffs expire; Blue Swayed > 50 turns; Curiosity when expired; hardcoded XP outfit with stillsuit and sweatpants, with accessories swapped for timers.");
    print("[SIM] Recurring actions: reserved goblin egg / Next Week and purple chains; VHS copies train the Yeti to its charge goal, then use Stocking Mimic. BARF tourists are marked unbanishable, so skip Eagle recharge and tourist banish attempts. Bullseye when red expires; BCZ + yellow-ray battlefield detours; Mobius, reanimation, sweat to 100, and three unique Laughing Stock fruits.");
    print("[SIM] Before each XP-training fight, retrieve enough love songs of icy revenge to hold at least 10.");
    print("[SIM] Exact future outfit/stats are not maximized in this preview. Values below use current gear and cached/fetched prices.");
    int[effect] coverage;
    foreach buff in $effects[] coverage[buff] = have_effect(buff);
    barfSimDiet(coverage);
    barfSimBuffs(coverage);
    print("[SIM] Adventure at Barf Mountain; reassess familiar, gear and diet before encounters; refresh profitable buffs periodically.","blue");
    print("[SIM] Combat: preserve goblin chaining and special timer actions; Chest Mimic/Yeti throw love songs of icy revenge until the fight ends, without shards, stalling, Extract or Bowl; other farming fights use the existing Pastalord flow.");
    print("[SIM] Lubrication choice: temporarily wear available lubrishoes, choose option 1, restore shoes. Warn and recover after losses; stop on unresolved choices.");
    print("[SIM] Finish when paid-turn limit is reached or adventures/profitable diet run out; preserve adventure reserve; run daily workshed and profit summary; no automatic nightcap.","blue");
}
