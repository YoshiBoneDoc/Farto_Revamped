import TeresMimic.ash;
import TeresMimicDiet.ash;
import TeresMimicDietLive.ash;

// Only the revised preview and explicit run paths remain. Older routing comments
// are retained verbatim as historical notes; see docs/DIET_OPTIMIZER_AUDIT.md.

// Run after TeresMimic's free-kill phases. This entry point does not repeat them.
// CLI: teresBARF.ash plan | prep | diet | farm | all [optional paid-turn limit]
// Default: prep, adaptive diet, and all available farming turns. No automatic nightcap.
// Economy defaults: base Meat 250, projected horizon at least 400, max purchase 100000.
// Override with teresBarfBaseMeat / ExpectedTurns / AdventureValue / MaxItemPrice.
// Familiar goals: teresBarfChestXP=950 and teresBarfYetiXP=2000;
// Candidate additions: semicolon-separated teresBarfFoods / Drinks / SpleenItems.
// Diet optimizes the supported candidates at current prices; it is not an exhaustive mall search.
// CLI: teresBARF.ash sim [optional paid-turn limit] prints a read-only full-run preview.
// Diet buffs first, then pay only for the missing coverage in other buffs.




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

void barfOneTimePrep(){
    if(!can_interact()||!can_adventure($location[Barf Mountain])||my_inebriety()>inebriety_limit())
        abort("BARF prep needs aftercore, Barf Mountain access, and a character who is not overdrunk.");
    if(handling_choice()||current_round()>0||in_multi_fight())
        abort("Resolve the pending choice or combat before BARF prep.");
    int before=total_turns_played();
    barfKnuckleboneRests();
    barfKiosk(true);
    barfDinseyGarbage();
    barfPostAdventure();
    if(available_amount($item[SongBoom&trade; BoomBox])>0
        &&get_property("boomBoxSong")!="Total Eclipse of Your Meat"
        &&get_property("_boomBoxSongsLeft").to_int()>0
        &&!cli_execute("boombox meat"))print("BARF could not set the Meat boombox song.","red");
    if(available_amount($item[Clan VIP Lounge key])>0){
        string original=get_clan_name();
        try{
            setClan("VIP");
            if(get_clan_name()=="Bonus Adventures from Hell"){
                while(get_property("_poolGames").to_int()<3){
                    int played=get_property("_poolGames").to_int();
                    if(!cli_execute("pool 1")||get_property("_poolGames").to_int()<=played)break;
                }
                if(!get_property("_clanFortuneBuffUsed").to_boolean())cli_execute("fortune buff meat");
            }else print("BARF could not access the VIP lounge for pool and fortune buffs.","red");
        }finally{
            if(get_clan_name()!=original&&(!cli_execute("/whitelist "+original)||get_clan_name()!=original))
                abort("BARF could not restore clan "+original+" after VIP prep.");
        }
    }
    if(!get_property("concertVisited").to_boolean()
        &&get_property("sidequestArenaCompleted")=="fratboy")cli_execute("concert 2");
    dailyBirdBuffs();
    familiar originalFarmer=my_familiar();
    try{
        if(available_amount($item[Mayam Calendar])>0&&get_property("_mayamSymbolsUsed")=="")useMayamRings();
    }finally{if(my_familiar()!=originalFarmer&&!use_familiar(originalFarmer))abort("BARF could not restore the familiar after Mayam prep.");}
    if(total_turns_played()!=before)print("BARF prep used a turn; the diet will plan from the updated state.","red");
}







// Refresh expired coverage after bonuses or new organ room extend the run.


void barfRunPlanned(int turns,boolean prompted){
    if(get_property("mayoInMouth")!="")abort("Handle queued Mayo before executing an exact diet.");
    barfLiveRequireOdeSlot();
    barfOneTimePrep();
    barfLivePreparePolka();
    barfBeginDay();
    barfDietPlan();if(!barfDietPlanReady)abort("No complete validated diet is available to execute.");
    string[string] saved;
    foreach pref in $strings[script,subscript,inSpendAdv,autoSatisfyWithStash,autoSatisfyWithMall,autoSatisfyWithNPCs,
        autoSatisfyWithCoinmasters,autoBuyPriceLimit,autoFillMayoMinder,autoTuxedo,autoPinkyRing,autoGarish,_teresBarfPlannedExecution,_teresBarfPlanMask,
        _teresBarfPlanStooper,_teresBarfPlanTrainer,_teresBarfPlanSweatpants,_teresBarfPlanMinimumAdventures,_teresBarfMode,_teresBarfVhsEncounter,_teresBarfTurnsRemaining,_teresBarfEquipment,
        unconditionalOverride,maxOverride,famOverride,hatOverride,mainOverride,weaponOverride,offOverride,backOverride,
        shirtOverride,pantsOverride,acc1Override,acc2Override,acc3Override,famEquipOverride]saved[pref]=get_property(pref);
    string savedMood=get_property("currentMood");boolean completed=false;beginFarmingReport();
    try{
        barfLiveMood("default");
        starter();set_property("script","BARF");set_property("subscript","");set_property("inSpendAdv",true);
        set_property("_teresBarfPlannedExecution",true);set_property("_teresBarfMode","");
        set_property("autoSatisfyWithStash",false);set_property("autoSatisfyWithMall",false);
        set_property("autoSatisfyWithNPCs",false);set_property("autoSatisfyWithCoinmasters",false);
        set_property("autoBuyPriceLimit",barfSetting("DietMaxItemPrice",500000));set_property("autoFillMayoMinder",false);
        set_property("autoTuxedo",false);set_property("autoPinkyRing",false);set_property("autoGarish",false);
        set_property("_teresBarfTurnsRemaining",turns>0?turns:barfDietPlanned.turns);
        foreach name in $strings[unconditional,max,fam,hat,main,weapon,off,back,shirt,pants,acc1,acc2,acc3,famEquip]set_property(name+"Override","");
        print("LIVE BARF: executing the printed diet"+(prompted?" with test pauses":"")+". A turn limit caps farming, not the diet purchases/consumption. Limited runs stop before end-of-day buffs and nightcap.","blue");
        barfDietExecute(turns,prompted);completed=true;
    }finally{
        try{finisher();}finally{
            try{barfLiveMood(savedMood);}finally{foreach pref,value in saved set_property(pref,value);finishFarmingReport(completed);}
        }
    }
}

// The revised diet is staged as a dry run; the legacy execution body is kept for reference.
// Explicit 'run' executes the revised plan; 'run-test' prompts between blocks.
// The old phase aliases remain previews.
void main(string command){
    if (command == "diet-snapshot"){ barfDietSnapshot(); return; }
    if (command == "diet-plan"){barfDietPlan();return;}
    if (command == "diet-candidates"){barfDietPlan(true);return;}
    string[int] args = split_string(command,"\\s+");
    string phase = command == "" ? "all" : args[0].to_lower_case();
    int turns = count(args) > 1 ? args[1].to_int() : 0;
    if(phase=="run"||phase=="run-test"){
        if(count(args)>2||(count(args)>1&&(!create_matcher("^[0-9]+$",args[1]).find()||turns<=0)))abort("Use teresBARF.ash "+phase+" [positive paid-turn limit].");
        barfRunPlanned(turns,phase=="run-test");return;
    }
    if ($strings[all,prep,diet,farm,plan,sim] contains phase){barfDietPlan();return;}
    if (!($strings[all, prep, diet, farm, plan, sim] contains phase))
        abort("Use teresBARF.ash diet-plan for a preview, run [paid-turn limit] to execute, run-test [paid-turn limit] to pause between blocks, or diet-snapshot to export inputs.");

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
