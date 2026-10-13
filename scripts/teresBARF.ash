import TeresMimic.ash;
import TeresMimicDiet.ash;
import teresBarfSimulation.ash;

// Run after TeresMimic's free-kill phases. This entry point does not repeat them.
// CLI: teresBARF.ash plan | prep | diet | farm | all [optional paid-turn limit]
// Default: prep, adaptive diet, and all available farming turns. No automatic nightcap.
// Economy defaults: base Meat 250, projected horizon at least 400, max purchase 100000.
// Override with teresBarfBaseMeat / ExpectedTurns / AdventureValue / MaxItemPrice.
// Familiar goals: teresBarfChestXP=950 and teresBarfYetiXP=2000;
// Candidate additions: semicolon-separated teresBarfFoods / Drinks / SpleenItems.
// Diet optimizes the supported candidates at current prices; it is not an exhaustive mall search.
// CLI: teresBARF.ash sim [optional paid-turn limit] prints a read-only full-run preview.
void BARFprep(){
    if (!can_interact()) abort("BARF farming and mall-priced dieting require aftercore access.");
    if (!can_adventure($location[Barf Mountain]))
        abort("BARF Mountain is unavailable. Establish Dinseylandfill access first.");
    if (my_inebriety() > inebriety_limit()) abort("BARF cannot start while overdrunk.");
    barfKnuckleboneRests();
    barfKiosk(true);
    barfPostAdventure();
    barfGear();
    if (available_amount($item[SongBoom&trade; BoomBox]) > 0
        && get_property("boomBoxSong") != "Total Eclipse of Your Meat"
        && get_property("_boomBoxSongsLeft").to_int() > 0)
        cli_execute("boombox meat");
    if (available_amount($item[Clan VIP Lounge key]) > 0){
        setClan("VIP");
        while (get_property("_poolGames").to_int() < 3){
            int before = get_property("_poolGames").to_int();
            if (!cli_execute("pool 1") || get_property("_poolGames").to_int() <= before) break;
        }
        if (!get_property("_clanFortuneBuffUsed").to_boolean()) cli_execute("fortune buff meat");
        setClan("stash");
    }
    if (!get_property("concertVisited").to_boolean()
        && get_property("sidequestArenaCompleted") == "fratboy") cli_execute("concert 2");
    dailyBirdBuffs();
    if (available_amount($item[Mayam Calendar]) > 0 && get_property("_mayamSymbolsUsed") == "") useMayamRings();
    barfGear();
    barfDietStep(false);
    // Diet buffs first, then pay only for the missing coverage in other buffs.
    barfMaintainBuffs();
    barfGear();
}

void barfPreview(){
    print("BARF plan: " + barfHorizon() + " expected farming turns, base Meat " + barfBaseMeat()
        + ", adventure value " + barfAdventureValue() + " Meat.", "blue");
    print("Familiar priority: Jill while short weight buffs last; Chest Mimic to " + barfSetting("ChestXP",950) + " XP; Cooler Yeti to "
        + barfSetting("YetiXP",2000) + " XP; then Jill with ultraviolet LED candle. Skeleton: five free rests only.", "blue");
    barfDietPrint("food",barfOrganRoom("food"));
    barfDietPrint("booze",max(0,barfOrganRoom("booze")-(available_amount($item[tiny stillsuit]) > 0 ? 1 : 0)));
    barfDietPrint("spleen",barfOrganRoom("spleen"));
}

void barfBeginDay(){
    if (get_property("_teresBarfRunDay") == today_to_string()) return;
    set_property("_teresBarfRunDay", today_to_string());
    string early = "";
    string durations = "";
    foreach buff, turns in my_effects()
        if (turns <= 5 && numeric_modifier(buff, "Familiar Weight") > 0){
            if (early != "") early += "\t";
            early += buff;
            if (durations != "") durations += ",";
            durations += turns;
        }
    set_property("_teresBarfEarlyWeightBuffs", early);
    set_property("_teresBarfEarlyWeightDurations", durations);
    set_property("_teresBarfEarlyWeightStart", total_turns_played());
    foreach fruit in $items[antique watermelon, classic banana, quince]{
        set_property("_teresBarfFruit" + to_int(fruit), false);
        set_property("_teresBarfFruitBefore" + to_int(fruit), item_amount(fruit));
    }
}

location barfNextAdventure(){
    set_property("_teresBarfMode", "");
    if (barfGoblinDue() || barfVhsDue()) return $location[Barf Mountain];
    if (have_familiar($familiar[Patriotic Eagle]) && get_property("screechCombats").to_int() == 0
        && barfDudesPresent()){
        set_property("_teresBarfMode", "screech");
        return $location[Barf Mountain];
    }
    if (have_familiar($familiar[Patriotic Eagle]) && have_skill($skill[Transcendent Olfaction])
        && $skill[Transcendent Olfaction].dailylimit != 0 && have_effect($effect[On the Trail]) == 0
        && get_property("olfactedMonster").to_monster() != $monster[garbage tourist]){
        if (get_property("spookyVHSTapeMonster") == ""
            && !barfAcquire($item[spooky VHS tape], barfSetting("MaxItemPrice",100000)))
            abort("Could not acquire the initial garbage-tourist VHS tape.");
        set_property("_teresBarfMode", "garbageSetup");
        return $location[Barf Mountain];
    }
    if (have_effect($effect[Everything Looks Yellow]) == 0
        && available_amount($item[blood cubic zirconia]) > 0
        && !get_property("_teresBarfBattlefieldUnavailable").to_boolean()){
        if (!have_outfit("War Hippy Fatigues")){
            print("BARF: War Hippy Fatigues are unavailable; battlefield detours skipped.", "red");
            set_property("_teresBarfBattlefieldUnavailable", true);
            return $location[Barf Mountain];
        }
        if (my_path().to_string() == "Hat Trick" && equipped_item($slot[hat]) != $item[none]
            && equipped_item($slot[hat]) != $item[reinforced beaded headband]){
            print("BARF: the locked Hat Trick hat cannot satisfy War Hippy Fatigues; battlefield detours skipped.", "red");
            set_property("_teresBarfBattlefieldUnavailable", true);
            return $location[Barf Mountain];
        }
        if (available_amount($item[Jurassic Parka]) == 0
            && !retrieve_item(1, $item[yellow rocket])) abort("Battlefield detour needs a yellow rocket.");
        set_property("_teresBarfMode", "battlefield");
        return $location[The Battlefield (Hippy Uniform)];
    }
    if (barfHeadReady() && !barfEarlyJill() && get_property("clubEmNextWeekMonster") == ""
        && can_adventure($location[The Goatlet])){
        if (!retrieve_item(15, $item[waffle])) abort("Goat reanimation needs waffles.");
        set_property("_teresBarfMode", "goat");
        return $location[The Goatlet];
    }
    if (barfEagleNeedsRecharge()
        && available_amount($item[spring shoes]) > 0 && have_effect($effect[Everything Looks Green]) == 0)
        set_property("_teresBarfMode", "eagleRun");
    if (get_property("spookyVHSTapeMonster") == ""
        && !barfAcquire($item[spooky VHS tape], barfSetting("MaxItemPrice",100000)))
        abort("Could not acquire a spooky VHS tape for familiar recharge.");
    return $location[Barf Mountain];
}

boolean barfSeedGoblin(){
    if (barfGoblinDue() || barfVhsDue() || get_property("_clubEmNextWeekUsed").to_int() >= 5
        || get_property("clubEmNextWeekMonster") != ""
        || item_amount($item[mimic egg]) == 0 || available_amount($item[legendary seal-clubbing club]) == 0) return false;
    set_property("_teresBarfMode", "goblinSeed");
    if (!retrieve_item(1, $item[facsimile dictionary])) abort("BARF goblins need a facsimile dictionary.");
    barfGear();
    int eggs = item_amount($item[mimic egg]);
    cli_execute("c2t_megg fight sausage goblin");
    int fights = 0;
    while (current_round() > 0 || in_multi_fight()){
        if (++fights > 20) abort("BARF goblin seed did not finish its chained fights.");
        run_combat();
    }
    if (item_amount($item[mimic egg]) >= eggs || get_property("clubEmNextWeekMonster").to_monster() != $monster[sausage goblin])
        abort("BARF could not seed its Club 'Em Into Next Week goblin chain.");
    barfPostAdventure();
    return true;
}

void barfFinishChainedCombats(){
    int fights = 0;
    while (current_round() > 0 || in_multi_fight()){
        if (++fights > 20) abort("BARF could not finish chained combat; resume manually.");
        run_combat();
    }
}

void barfFarm(int requestedTurns){
    if (have_skill($skill[Transcendent Olfaction]) && $skill[Transcendent Olfaction].dailylimit != 0
        && get_property("olfactedMonster").to_monster() != $monster[garbage tourist]
        && have_effect($effect[On the Trail]) > 0){
        if (!cli_execute("uneffect On the Trail") || have_effect($effect[On the Trail]) > 0)
            abort("BARF could not clear the previous trail before tracking garbage tourists.");
    }
    int start = total_turns_played();
    int iterations = 0;
    int emptyAttempts = 0;
    while (true){
        int spent = total_turns_played()-start;
        if (requestedTurns > 0 && spent >= requestedTurns) break;
        if (my_inebriety() > inebriety_limit()) abort("BARF stopped because you are overdrunk.");
        int limit = requestedTurns > 0 ? requestedTurns-spent : barfHorizon();
        set_property("_teresBarfTurnsRemaining",max(0,limit));
        if (barfSeedGoblin()) continue;
        location next = barfNextAdventure();
        barfGear();
        if (next == $location[The Battlefield (Hippy Uniform)] && !can_adventure(next)){
            print("BARF: battlefield detour unavailable with the required outfit/path/access; skipping this detour.", "red");
            set_property("_teresBarfBattlefieldUnavailable", true);
            set_property("_teresBarfMode", "");
            continue;
        }
        barfDietStep(false);
        if (my_adventures() <= barfSetting("ReserveAdventures",0)){
            if (!barfDietStep(true) || my_adventures() <= barfSetting("ReserveAdventures",0)) break;
        }
        // Refresh expired coverage after bonuses or new organ room extend the run.
        if (iterations % 20 == 0 || have_effect($effect[Polka of Plenty]) == 0)
            barfMaintainBuffs();
        int before = total_turns_played();
        string progressBefore = barfProgressKey();
        int adventuresBefore = my_adventures();
        if (!adv1(next,-1,"")) abort("BARF adventure failed; stopped.");
        barfFinishChainedCombats();
        if (handling_choice()) abort("BARF left an unresolved choice; stopped.");
        if (get_property("_lastCombatLost").to_boolean() || have_effect($effect[Beaten Up]) > 0)
            abort("BARF lost the last fight; stopped.");
        if (total_turns_played() == before && my_adventures() == adventuresBefore && progressBefore == barfProgressKey()) emptyAttempts += 1;
        else emptyAttempts = 0;
        if (emptyAttempts >= 5) abort("BARF made no adventure progress for five encounters.");
        iterations += 1;
        if (requestedTurns == 0) set_property("_teresBarfTurnsRemaining",max(my_adventures(),barfHorizon()-1));
    }
    print("BARF finished: " + (total_turns_played()-start) + " paid turns; "
        + my_adventures() + " adventures remaining.", "blue");
    dailyWorkshed();
}

// The revised diet is staged as a dry run; the legacy execution body is kept for reference.
void main(string command){
    if (command == "diet-snapshot"){ barfDietSnapshot(); return; }
    if (command == "diet-plan"){barfDietPlan();return;}
    string[int] args = split_string(command,"\\s+");
    string phase = command == "" ? "all" : args[0].to_lower_case();
    int turns = count(args) > 1 ? args[1].to_int() : 0;
    if ($strings[all,prep,diet,farm,plan,sim] contains phase){barfDietPlan();return;}
    if (!($strings[all, prep, diet, farm, plan, sim] contains phase))
        abort("Use teresBARF.ash diet-plan for the two-day dry run, or diet-snapshot to export live inputs. BARF execution remains disabled until the revised plan is reviewed.");
    if (command != "" && count(args) > 1 && turns <= 0)
        abort("An explicit BARF turn limit must be positive.");
    string[string] saved;
    foreach pref in $strings[script,subscript,inSpendAdv,autoSatisfyWithStash,autoSatisfyWithMall,
        autoSatisfyWithNPCs,autoSatisfyWithCoinmasters,autoBuyPriceLimit,autoFillMayoMinder,
        _teresBarfTurnsRemaining,_teresBarfGearKey,_teresBarfEquipment,_teresBarfLimitedRun,_teresBarfMode,_teresBarfBattlefieldUnavailable,choiceAdventure1073,
        unconditionalOverride,maxOverride,famOverride,hatOverride,mainOverride,weaponOverride,
        offOverride,backOverride,shirtOverride,pantsOverride,acc1Override,acc2Override,acc3Override,famEquipOverride]
        saved[pref] = get_property(pref);
    if (phase == "plan" || phase == "sim")
        foreach pref in $strings[_teresBarfBorisBread,_teresBarfYetiXPSpent] saved[pref] = get_property(pref);
    set_property("_teresBarfTurnsRemaining",turns > 0 ? turns : max(my_adventures(),barfSetting("ExpectedTurns",400)));
    set_property("_teresBarfLimitedRun",turns > 0);
    if (phase == "plan" || phase == "sim"){
        try {
            if (get_property("_teresBarfDietDay") != today_to_string()){
                set_property("_teresBarfBorisBread",0); set_property("_teresBarfYetiXPSpent",0);
            }
            if (phase == "sim") barfSimulation();
            else barfPreview();
        }
        finally { foreach pref,value in saved set_property(pref,value); }
        return;
    }
    boolean completed = false;
    beginFarmingReport();
    try {
        starter();
        set_property("script","BARF"); set_property("subscript",""); set_property("inSpendAdv",true);
        barfBeginDay();
        set_property("_teresBarfMode", "");
        set_property("_teresBarfBattlefieldUnavailable", false);
        set_property("_teresBarfGearKey","");
        set_property("choiceAdventure1073",1);
        set_property("autoSatisfyWithStash",false);
        set_property("autoSatisfyWithMall",true); set_property("autoSatisfyWithNPCs",true);
        set_property("autoSatisfyWithCoinmasters",false);
        set_property("autoBuyPriceLimit",barfSetting("MaxItemPrice",100000));
        foreach name in $strings[unconditional,max,fam,hat,main,weapon,off,back,shirt,pants,acc1,acc2,acc3,famEquip]
            set_property(name+"Override","");
        if (get_property("_teresBarfDietDay") != today_to_string()){
            set_property("_teresBarfDietDay",today_to_string());
            set_property("_teresBarfBorisBread",0); set_property("_teresBarfYetiXPSpent",0);
        }
        if (phase == "all" || phase == "prep") BARFprep();
        else { barfGear(); barfPostAdventure(); }
        if (phase == "diet") barfDietStep(false);
        if (phase == "all" || phase == "farm") barfFarm(turns);
        completed = true;
    } finally {
        try { finisher(); }
        finally {
            foreach pref,value in saved set_property(pref,value);
            finishFarmingReport(completed);
        }
    }
}
// MUST BANISH horrible tourist family AT START!!!!! COUNT AS 3 KILLS FOR THE NC ADVENTURE
// USE FLASKFULS SO WE CAN USE HALF-A-PURSE FOR MAX MEAT
// 7 adventures for trash island access, which includes the final giant giant crab fight
    // for roaches, make sure to keep trying chaining skill b/c sometimes it will miss (too distracted to use skill)
/*
    use 40 scams
    off hand latte for fam xp  -> otherwise purse + flaskful
    stillsuit when farming xp
    april 16th -1 full
    rest -1 full
    jukebox meat


*/




// Original BARF notes and template, preserved for reference.
/**
 *          ~ teresBARF.ash ~
 * Turn-burning script for BARF Mountain.
 * Hat Path has no Sea access, so remaining turns are spent at BARF.
 *
 * - Currently designed for Hat Path aftercore
 * - Run after bulkFKD1() in TeresMimic.ash
 */

// import TeresMimic.ash;

//  ---- HELPER FUNCTIONS ----

// Template
// void dailyMoodAndNightcap(){
/*        TEMPLATE
    cli_execute("mood apathetic; uneffect cletus");
    if (get_property("lawOfAveragesAvailable") == true)
        use($item[law of averages]);
    use_familiar($familiar[Stooper]);
    equip($item[devilbone rosary]);
    equip($item[angelbone dice]);
    cli_execute("CONSUME NIGHTCAP");
    */
// }

// Template
// void BARFprep(){

/*
        -vip clan
        // bird a day
        // collect dinsey wages + quest
        // psillocyber mushroom used today

        3. get 2002 stuff
        4. favorite bird
        5. war concert
        6. summon chamber
        7. bcz flush
        8. VIP clan buffs
        9. august lighthouse
        10. calc universe
        11. buffs (trivialskills, others)
        12. mayan calender


        for roaming cockroach at barf (be gregarious from spleening extro)
            ccs:
                if monstername cockroach && hasskill Be Gregarious
                    skill be gregarious
                endif
                skill bowl straight up
                attack with weapon






                TEMPLATE
    cli_execute("mood apathetic; uneffect cletus");
    if (get_property("lawOfAveragesAvailable") == true)
        use($item[law of averages]);
    use_familiar($familiar[Stooper]);
    equip($item[devilbone rosary]);
    equip($item[angelbone dice]);
    cli_execute("CONSUME NIGHTCAP");
    */
// }



// ---- MAIN EXPORT FUNCTION ----
// export function garboDiet() {

/*
    FK phase:
    - cup of 13s twice = 2 drunk
    - cheapest legendary noodles disk -> convert to spleen = 1 spleen
    - cheapest legendary noodles disk -> 2x buff on next 3 dishes = 1 full
    - mini kiwi aioli
    - cyburger = 2 full
    -



    start at: 3/0/0 - drunk/stomach/spleen
    sweatpants x3 0/0/0



    cast 5 pals

    _______ Working Blueprint ________
    1. daily chores - BARFprep()

        - buff keep
        - DRINKS:
            - stillsuit (calculations below)
            - 5 beers + 5 paws + Yetis ("TRIO cup of beer" looks like best option): 11.5/drunk ~ 6-7 (TRIO) + 4-6 (Salty Mouth)
                cli:    - monkeypaw effect Salty Mouth
                        - yeti cool
            - Gets-You-Drunk: 8/drunk ~ 2 booze for 16-20 adv (8-10 plus another 8-10 after 4 combats)
        - mall check
        - burn bcz
        - bird a day
        - blue rocket or candle shit
        - sweatpants
        - maybe gets-you-drunk
        - pasta
        - 5 knucklebones from rests

    - possibly some dieting at end of free kills
    - save room to drink while adventuring with sweatsuit + paw wishes for beer + yeti
            ..cast shit ton of ode
            1. cli_execute("monkeypaw effect salty mouth;")
            2. code for yeti:
                Looking Cool effect = cli_execute("ash visit_url("main.php?talktoyeti=1",false,true).buffer_to_file("_yeti_talk2.html"); run_choice(3); run_choice(1);");
                Double Booze = cli_execute("ash visit_url("main.php?talktoyeti=1",false,true).buffer_to_file("_yeti_talk2.html"); run_choice(2); run_choice(1);");
            3. cli_execute("drink party beer bomb;")    <-- TRIO cup optimal but not sure if worth 17k for avg 1 extra adventure over (500 meat) party beer bomb (6-7 vs 5-6 adv)
            4. -- yeti 2x boose
            5. -- frosty mug + dread cold-fash
            ..use shit ton of kiwi aioli
            tubetto With my Spleen
                //calc if roasted veg of F better (8adv/full):(15-17/2full) but no buff (only +10 fam xp) --OR-- ghost pepper (17.5adv/full):(16-19/2full)
                //gotta also account for advs lost from tubetto


            - yeti + fermented pickle J to remove spleen
            - swwet synthesis
            - aug 16th for -1 full
            - cup of 13s (maybe? should be depleted)
                - 3x sponge pants gives 80x3=240 turns of +100% meat but 3 adv
            - consider spleening extrovermectin for killing roaming roaches (be gregarious - 3 killed per pill)

    // WHORLED PEAS -> MIMIC STALL AND FREE RUNS



    - burn pvp adventures before next step
    - at the end use extra diet from ascension rewards for +LB buffs (possibly, unless we are way over rollover adventures
    - use up batwing flaps mp
    - shrunken head (see preAdv)
    - 1 zap with wand maybe
    - free mining
    - law of averages?
    -  use Jerks' Health™ Magazine for pvp fights
    - spelunky?


    stillsuit calculations:
        Adv/Drunk: Avg turns needed to produce - [range in calculation shown]
        10: 152.5 - (279+357/2)/3
        11: 197   - (358+448/2)/3
        12: 241.8 - (449+553/2)/3


 ========= old run plan backbone ========-

    //cli_execute("garbo quick");

    // bulk of main stuff
    cli_execute("familiar Cooler Yeti");
    cli_execute("equip amulet coin");
    cli_execute("outfit capacity");
    cli_execute("use clockwork maid");
    cli_execute("/whitelist Bonus Adventures from Hell");
    cli_execute("acquire carpe");
    cli_execute("equip carpe");

    //buffs for fam exp
    cli_execute("/whitelist soup clan");
    cli_execute("use 10 white candy heart");
    cli_execute("use 10 pulled blue taffy");
    cli_execute("use 10 deviled");
    cli_execute("use 50 scams");
    cli_execute("use 6 flapper fly");
    cli_execute("use 3 savings bond");
    cli_execute("use 3 autumn dollar");
    cli_execute("use 4 pork elf mouthwash");
    cli_execute("use 5 be wealthier");

    //partial diet for yeti charge
    cli_execute("use 2 mini kiwi aioli");
    cli_execute("eat roasted vegetable focaccia");
    cli_execute("synthesize Synthesis: Greed");
    cli_execute("synthesize Synthesis: Greed");

    //adventure a few to get xp on cooler Yeti
    cli_execute("adventure 15 Barf Mountain");

    //use the yeti for looking cool
    cli_execute("cast ode");

    //drink 1
    visit_url("main.php?talktoyeti=1, false");
    run_choice(3);
    run_choice(3);
    cli_execute("/drink Ambitious Turkey");

    //drink 2
    visit_url("main.php?talktoyeti=1, false");
    run_choice(3);
    run_choice(3);
    cli_execute("/drink Ambitious Turkey");

    // top off and adventure
    cli_execute("CONSUME ALL");
    cli_execute("adventure * Barf Mountain");
    dailyWorkshed();

    // Stooper
    cli_execute("familiar Stooper");
    cli_execute("equip amulet coin");
    cli_execute("cast ode");
    cli_execute("/drink Ambitious Turkey");

//DRINK NIGHTCAP MANUALLY SO U CAN USE UR YETI
    //cli_execute("CONSUME NIGHTCAP");

    cli_execute("PVP_MAB");
    cli_execute("Hobo.js breakfast");

    //cli_execute("wear burning cape");
    //cli_execute("make snow belt");
    cli_execute("maximize adv, -equip legendary seal-clubbing club");
    cli_execute("wear ratskin pants");

    someHelperFunction();
*/

// }
