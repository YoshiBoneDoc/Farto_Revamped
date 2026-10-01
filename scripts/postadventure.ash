import iotm.ash;
import preconsume.ash;

// ─── postadventure.ash ───────────────────────────────────────────────────────
// afterAdventureScript for the farto / free-kill environment.
//   main()     -- every turn: postAdv() always, then spendAdv() once when
//                 adventures remain and no free-kill run already owns the turn.
//   postAdv()  -- per-turn upkeep and safety aborts.
//   spendAdv() -- burns the turn on whatever quest / delay task is next.
// The per-quest helpers below are also called by name from farto.ash and
// StockingMimic.ash, so their names and signatures are frozen.

// Zone mafia last adventured in; compared against adventureAbortMessages.
string lastAdv = get_property("lastAdventure");

// "stuck" last-adventure zones -> postAdv() aborts with the mapped message.
string [string] adventureAbortMessages = {
    "Poisoned Spleen": "Spleen Poisoned",
    "Bloated and Nauseous": "Overfull",
    "Drunken Stupor": "Overdrunk"
};

// Equip the sword of s words and sniff its target (monster id 307) so the sword drop lines up.
void swordPrep(){
    set_property("famOverride","sword of s words");
    use_familiar($familiar[sword of s words]);
    int loopCount = 0;
    while (get_property("swordOfSWordsMonster") != "1085"){
        if (loopCount++ > 20)
            abort("swordPrep: looped over 20 times with no progress -- probably out of grizzled survivor reminisces");
        set_property("killThisGuy","1085");
        set_property("swordSniff","true");
        cli_execute("reminisce grizzled survivor");
    }
    set_property("killThisGuy","");
    set_property("swordSniff","false");
}

// Pick the accessory to burn a delay turn on: club-em wanderer > "I Voted!" > spring shoes.
void delayPrep(){
    if (get_property("clubEmNextWeekMonster") != "" && total_turns_played() >= get_property("clubEmNextWeekMonsterTurn").to_int() + 8)
        set_property("mainOverride",", equip legendary seal-clubbing club");
    else if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0 && total_turns_played()%11 == 1 && get_property("_voteFreeFights").to_int() < 3)
        set_property("acc3Override",", equip I voted");
    else if (have_effect($effect[everything looks green]) == 0)
        set_property("acc3Override",", equip spring shoes");
}

// Clear whichever of the two common non-combat debuffs are currently up.
void uneffectDebuffs(){
    if (have_effect($effect[Coated in Slime]) > 0)
        camo();
    if (have_effect($effect[chilled to the bone]) > 0)
        use($item[hot Dreadsylvanian cocoa]);
}

// Run one Rufus / Shadow Rift turn, equipping the gaze / bat-wings / entity gear the quest needs.
void shadowRealm(){
    set_property("maxOverride","item drop");
    if (to_int(get_property("_bczRefractedGazeCasts")) < 9)
        set_property("acc2Override",", equip blood cubic zirconia");
    if (to_int(get_property("_batWingsSwoopUsed")) < 11)
        set_property("backOverride",", equip bat wings");
    else
        set_property("backOverride","");
    if (get_property("questRufus") == "unstarted" && get_property("_shadowAffinityToday") == "true" && dayType() == 1)
        use($item[closed-circuit pay phone]);
    if (get_property("rufusQuestType") == "items"){
        retrieve_item(3,to_item(get_property("rufusQuestTarget")));
    } else if (get_property("questRufus") == "started"){
        if(get_property("_seadentWaveZone") == "Shadow Rift")
            set_property("mainOverride",", equip monodent");
        if (get_property("encountersUntilSRChoice").to_int() == 0 && get_property("rufusQuestTarget") == "shadow scythe")
            abort();
        if (get_property("encountersUntilSRChoice").to_int() == 0 && get_property("rufusQuestTarget") == "shadow spire")
            set_property("maxOverride","spell damage percent");
        if (have_item($item[petrified wood wizard's pouch]))
            set_property("acc3Override",",equip petrified wood wizard's pouch");
        else
            set_property("acc3Override",",equip congressional medal of insanity");
        if ($monster[shadow slab].elemental_resistance > 85){
            if (have_item($item[petrified wood wizard's pouch]))
                set_property("acc3Override",",equip petrified wood wizard's pouch");
            else
                set_property("acc3Override",",equip congressional medal of insanity");
        }
        adv1($location[Shadow Rift (The Nearby Plains)]);
        set_property("acc3Override","");
    }
    if (get_property("questRufus") == "step1" && get_property("_shadowAffinityToday") == "true") {
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Nearby Plains)]);
    }
    set_property("maxOverride","");
    set_property("mainOverride","");
    set_property("acc3Override","");
}

// Fight the cookbookbat quest monster. Route depends on which free banish is up
// (spring shoes / june cleaver / peridot bander); the CCS is always restored on exit.
void cookbookbat(){
    if (get_property("_cookbookbatQuestMonster") != ""){
        set_property("famOverride","cookbookbat");
        location CBBLoc = to_location(get_property("_cookbookbatQuestLastLocation"));
        if (get_property("_cookbookbatQuestLastLocation").to_location().zone == "Memories")
            return;
        monster CBBMon = to_monster(get_property("_cookbookbatQuestMonster"));
        if (have_effect($effect[everything looks green]) == 0 && have_effect($effect[Everything looks Beige]) == 0 && have_item($item[Crepe paper parachute cape])){
            set_property("acc1Override","equip spring shoes");
            equip($slot[acc2],$item[spring shoes]);
            set_property("battleAction", "skill spring away");
            visit_url("adventure.php?snarfblat=" + to_int(CBBLoc));
            if (get_property("lastEncounter") == get_property("_cookbookbatQuestMonster")){
                set_property("battleAction", "skill saucegeyser");
                run_combat();
            } else {
                run_combat();
                set_property("battleAction", "attack with weapon");
                visit_url("inventory.php?action=parachute");
                visit_url("choice.php?option=1&whichchoice=1543&monid=" + to_int(CBBMon));
                run_combat();
                set_property("battleAction", "custom combat script");
            }
        } else if (get_property("_juneCleaverFightsLeft") == 0 && have_effect($effect[Everything looks Beige]) == 0 && have_item($item[Crepe paper parachute cape])){
            set_property("mainOverride","equip june cleaver");
            adv1(CBBLoc);
            visit_url("inventory.php?action=parachute");
            visit_url("choice.php?option=1&whichchoice=1543&monid=" + to_int(CBBMon));
            run_combat();
            set_property("battleAction", "custom combat script");
        } else if (!contains_text(get_property("_perilLocations"), to_string(to_int(CBBLoc))) && CBBLoc!= $location[the primordial soup]){
            set_property("acc1Override",", equip peridot of peril");
            set_property("choiceAdventure1557","1&bandersnatch=" + to_int(CBBMon));
            adv1(CBBLoc,0,"");
        }
    }
    set_property("battleAction", "custom combat script");
    set_property("mainOverride","");
    set_property("famOverride","");
    set_property("acc1Override","");
}

// One Black Forest turn toward the blackbird. On the 4th NC turn, equip the CCS
// cane and pause for a manual check that the sword NC fired.
void blackForest(){
    set_property("maxOverride","combat");
    cli_execute("acquire blackberry galoshes");
    set_property("acc3Override",", equip blackberry galoshes");
    if (item_amount($item[reassembled blackbird]) == 0)
        set_property("famOverride","reassembled blackbird");
    else
        swordPrep();
    if (item_amount($item[sunken eyes]) == 1 && item_amount($item[broken wings]) == 1)
        cli_execute("acquire reassembled blackbird");
    if ((item_amount($item[sunken eyes]) == 1 && item_amount($item[broken wings]) == 0) || (item_amount($item[sunken eyes]) == 0 && item_amount($item[broken wings]) == 1))
        set_property("acc2Override",", equip peridot of peril");
    if ($location[the black forest].last_noncombat_turns_spent == 4)
        set_property("mainOverride",", equip candy cane sword cane");
    adv1($location[the black forest]);

    set_property("maxOverride","");
    set_property("mainOverride","");
    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("famOverride","");
}

// Finish the Guild muscle challenge (Cobb's Knob outskirts). No-op once finished.
void outskirts() {
    if (get_property("questG09Muscle") == "finished" && get_property("questL05Goblin") != "started")
        return;
    if (get_property("_banderRunaways").to_int() < (my_familiar().familiar_weight() + weight_adjustment( ))/5)
        altFam($familiar[Pair of Stomping Boots]);
    else
        swordPrep();
    if (get_property("famOverride") != "sword of s words")
        set_property("unconditionalOverride","familiar weight");
    else
        set_property("unconditionalOverride","");
    if (get_property("questG09Muscle") == "unstarted")
        visit_url("guild.php?place=challenge");
    if (get_property("questG09Muscle") == "started")
        adv1($location[The Outskirts of Cobb's Knob]);
    else if (get_property("questL05Goblin") == "started"){
        if (available_amount($item[Knob Goblin Encryption Key]) > 0)
            use ($item[Cobb's Knob map]);
        adv1($location[The Outskirts of Cobb's Knob]);
    }
    visit_url("guild.php?place=challenge");
    set_property("unconditionalOverride","");
    set_property("famOverride","");
}

// Drive the Hidden Temple unlock: the choiceAdventure props select tree-holed
// coin -> temple map -> sapling -> plant, then adventure the Spooky Forest.
void findHiddenTemple(){
    print("Farto: findHiddenTemple");
    if (get_property("questM16Temple") == "finished")
        return;
    uneffectDebuffs();
    if (get_property("_banderRunaways").to_int() < (my_familiar().familiar_weight() + weight_adjustment( ))/5)
        altFam($familiar[Pair of Stomping Boots]);
    else
        swordPrep();
    set_property("maxOverride","-combat");
    if (item_amount($item[Spooky-Gro fertilizer]) == 0)
        cli_execute("acquire Spooky-Gro fertilizer");
    if (item_amount($item[tree-holed coin]) == 0 && item_amount($item[Spooky Temple map]) == 0){
        set_property("choiceAdventure502","2");
        set_property("choiceAdventure505","2");
    } else if (item_amount($item[Spooky Temple map]) == 0){
        set_property("choiceAdventure502","3");
        set_property("choiceAdventure506","3");
        set_property("choiceAdventure507","1");
    } else if (item_amount($item[spooky sapling]) == 0){
        set_property("choiceAdventure502","1");
        set_property("choiceAdventure503","3");
        set_property("choiceAdventure504","3");
    } else if (item_amount($item[Spooky Temple map]) > 0 && item_amount($item[spooky sapling]) > 0){
        use($item[Spooky Temple map]);
    }
    adv1($location[the spooky forest]);
    set_property("maxOverride","");
}

// One Friars turn toward the next missing infernal item (dodecagram / candles / butterknife).
void friars(){
    if (item_amount($item[dodecagram]) == 0){
        adv1($location[the dark neck of the woods],0,"");
    } else if (item_amount($item[box of birthday candles]) == 0){
        adv1($location[the dark heart of the woods],0,"");
    } else if (item_amount($item[eldritch butterknife]) == 0)
        adv1($location[the dark elbow of the woods],0,"");
}

// Burn the day's Law of Averages while under 100 adventures: unconditional on day
// 1, day 2 only once Steely-Eyed Squint is up so the copy is worthwhile.
void lawOfAverages(){
    if (my_adventures() < 100 && get_property("_lawOfAveragesUsed") == "0" && dayType() == 1 && have_item($item[law of averages]))
        use($item[law of averages]);
}

// Spend built-up sweat: booze first (also clears inebriety), otherwise Sweat-Ade
// once pantsgiving is maxed and it is worth the turn.
void sweatpants(){
    if (get_property("sweat").to_int() <= 75)
        return;
    if (get_property("_sweatOutSomeBoozeUsed").to_int() < 3 && my_inebriety() > 3)
        use_skill($skill[sweat out some booze]);
    else if (to_int(get_property("_pantsgivingCount")) >= 500 && ((dayType() == 0 && my_adventures() > 100) || dayType() == 1))
        use_skill($skill[Make Sweat-Ade]);
}

// Spend a Book of Facts wish by adventuring a class-specific zone with a peridot
// bandersnatch onto the mapped monster id; the patriotic eagle carries an RWB
// wish when Everything Looks Red White and Blue is down.
void BoFaWish(){
    int [string] wish_map;
    if (my_class() == $class[accordion thief]){
        wish_map = {
            "280":	1160,
            "242":	981,
            "441":	1751,
            "389":	375,
            "243":	977
        };
    } else if (my_class() == $class[pastamancer]){
        wish_map = {
            "33":	48,
            "58":	185,
            "264":	185
        };
    } else if (my_class() == $class[seal clubber]){
        wish_map = {
            "260":	1063,
            "441":	1754,
            "384":	1529
        };
    } else {
        abort();
    }
    foreach loc in wish_map{
        if ((!contains_text(get_property("_perilLocations"),loc) || get_property("rwbLocation") == to_location(to_int(loc))) && can_adventure(to_location(to_int(loc)))){
            set_property("acc1Override",", equip peridot of peril");
            set_property("choiceAdventureScript","");
            set_property("choiceAdventure1557","1&bandersnatch=" + wish_map[loc]);
            try{
                adv1(to_location(to_int(loc)));
            } finally {
                set_property("famOverride","");
                set_property("acc1Override","");
                set_property("choiceAdventureScript","generalChoice.ash");
                set_property("BoFaWishRWB","false");
            }
            return;
        }
    }
}

// Send the autumn-aton to the next zone that still grants an upgrade (parsing the
// use page for the option ids), preferring anything but the Shadow Rift, then the
// Shadow Rift, then noob cave as a fallback.
void upgradeAutumnaton(){
    use($item[autumn-aton]);
    string [string] upgradeLocation = {
        "mid indoor":"rightleg1",
        "low underground":"leftleg1",
        "mid outdoor":"rightarm1",
        "low indoor":"leftarm1",
        "high underground":"collectionprow1"
    };

    string autumnOptions = visit_url("inv_use.php?" + my_hash() + "&which=3&whichitem=10954");

    int [int] locations;

    matcher m = create_matcher(
        "<option\\s+value=\"([0-9]+)\">\\s*([^<]+?)\\s*</option>",
        autumnOptions
    );

    int n;
    while (m.find()) {
        int id = to_int(m.group(1));
        string name = m.group(2);

        locations[n] = id;
        n += 1;
    }

    foreach key in locations {
        string type = (to_location(locations[key]).difficulty_level + " " + to_location(locations[key]).environment);
        if (!contains_text(get_property("autumnatonUpgrades"),upgradeLocation[type]) && upgradeLocation[type] != ""){
            if (contains_text(to_location(locations[key]).to_string(),"Shadow Rift"))
                continue;
            cli_execute("autumnaton send " + to_location(locations[key]));
            return;
        }
    }
    foreach key in locations {
        if (locations[key] == to_int($location[Shadow Rift (The Misspelled Cemetary)])){
            cli_execute("autumnaton send Shadow Rift");
            return;
        }
    }
    cli_execute("autumnaton send noob cave");
}

// Grind Zeppelin Protesters up to step2: mood sleaze, keep Lucky! going while
// under 80 protesters, and abort if sleaze damage can't one-shot them.
void unlock_zeppelin(){
    string ron = get_property("questL11Ron");
    if (ron == "step2" || ron == "step3" || ron == "step4" || ron == "finished"
        || !can_adventure($location[A Mob of Zeppelin Protesters]))
        return;
    set_property("maxOverride","sleaze damage, sleaze spell damage");
    set_property("mainOverride",", equip candy cane sword cane");
    foreach ef in $effects[Bendin' Hell,Belch the Rainbow&trade;,Amorous,Blood-Gorged,Sleazy Hands,Benetton's Medley of Diversity,Greasy Peasy,Takin' It Greasy,Cuts Like a Lightly-Buttered Knife,Colorful Gratitude,Sleazy Weapon,Stained,Crud&eacute;,Why So Serious?,Improprie Tea,Boschface,All Glory To the Toad,Herder\, Bitter\, Fester\, Stranger,Yoloswagyoloswag]{
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    while(get_property("questL11Ron") != "step2"){
        cli_execute("maximize sleaze damage, sleaze spell damage, equip candy cane sword cane");
        set_property("unconditionalOverride","sleaze damage, sleaze spell damage, equip candy cane sword cane");
        if ((numeric_modifier("sleaze damage")+numeric_modifier("sleaze spell damage")) < 1596 && to_int(get_property("zeppelinProtestors")) < 80)
            abort("not enough sleaze damage");
        if (to_int(get_property("zeppelinProtestors")) < 80 && have_effect($effect[lucky!]) == 0)
            getLucky();
        adv1($location[A Mob of Zeppelin Protesters]);
    }
    set_property("unconditionalOverride","");
}

// Banish all three pygmy types out of the Hidden Bowling Alley (11 drunk-pygmy
// banishes), swapping in the middle-finger ring / spring shoes as each is needed.
void drunkPygmy(){
    if (get_property("questL11Spare") == "unstarted")
        adv1($location[An Overgrown Shrine (Southeast)]);
    cli_execute("acquire 11 bowl of scorpions");
    if (to_int(get_property("_drunkPygmyBanishes")) < 11){
        set_property("maxOverride","familiar exp");
        if (get_property("famOverride") != "chest mimic"){
            if (get_property("screechCombats").to_int() > 0)
                set_property("famOverride","patriotic eagle");
            else
                set_property("famOverride","stocking mimic");
        }
        if (!contains_text(get_property("banishedMonsters"),"pygmy bowler")){
            set_property("acc3Override",", equip mafia middle finger ring");
        } else {
            set_property("acc3Override","");
        }
        if (!contains_text(get_property("banishedMonsters"),"pygmy orderlies")){
            set_property("acc2Override",", equip spring shoes");
        } else {
            set_property("acc2Override","");
        }
        if (!contains_text(get_property("banishedMonsters"),"pygmy janitor")){
            set_property("offOverride",", equip latte lovers member's mug");
        } else {
            set_property("offOverride","");
        }
        cli_execute("closet put * bowling ball");
        adv1($location[The Hidden Bowling Alley]);
    }
    set_property("maxOverride","");
    set_property("famOverride","");
}

// Clear the ziggurat lianas with a candy-cane-sword machete, then pop the shrine NC.
void lianas(){
    if (get_property("zigguratLianas") == 0){
        cli_execute("acquire antique machete;equip weapon antique machete");
        foreach loc in $locations[An Overgrown Shrine (Northeast),An Overgrown Shrine (Southwest),An Overgrown Shrine (Southeast),An Overgrown Shrine (Northwest),A Massive Ziggurat]{
            int n;
            while (loc.turns_spent < 3 && n < 3) {
                set_property("maxOverride","familiar exp, -weapon");
                set_property("mainOverride"," ");
                if (get_property("famOverride") != "chest mimic"){
                    if (get_property("screechCombats").to_int() > 0)
                        set_property("famOverride","patriotic eagle");
                    else{
                        set_property("famOverride","comma chameleon");
                        return;
                    }
                }
                n += 1;
                adv1(loc);
            }
        }
        adv1($location[A Massive Ziggurat]);
    }
    if (get_property("_candyCaneSwordOvergrownShrine") == false){
        cli_execute("equip candy cane sword cane");
        visit_url("adventure.php?snarfblat=348");
        run_choice(-1);
    }
    set_property("maxOverride","");
    set_property("famOverride","");
    set_property("mainOverride","");
}

// Spend down any leftover patriotic-eagle screech combats (drunk pygmies first,
// then lianas) so the eagle is charged for the next phylum banish.
void screechRefresh(){
    if (!can_adventure($location[An Overgrown Shrine (Northeast)]))
        return;
    // Hang guard: drunkPygmy() / lianas() can both become no-ops (e.g. lianas
    // already cleared) while screechCombats is still > 0, which would spin this
    // loop forever without spending a turn. Bail after 3 iterations that neither
    // burn a screech combat nor a turn.
    int stuckLoops = 0;
    while (get_property("screechCombats").to_int() > 0){
        int screechBefore = get_property("screechCombats").to_int();
        int turnsBefore = total_turns_played();
        set_auto_attack(0);
        if (to_int(get_property("_drunkPygmyBanishes")) < 11)
            drunkPygmy();
        else
            lianas();
        if (get_property("screechCombats").to_int() < screechBefore || total_turns_played() > turnsBefore){
            stuckLoops = 0;
        } else {
            stuckLoops += 1;
            if (stuckLoops > 2)
                abort("screechRefresh: stuck with " + screechBefore + " screech combats left and no turns being spent");
        }
    }
}

// Banish the construct phylum out of the cyberzones via Madness Bakery screeches;
// clears the overrides once all 10 cyber free fights are gone.
void constructBanish(){
    if (get_property("_cyberFreeFights").to_int() >= 10)
        return;
    if (dayType() == 0)
        return;
    if (get_property("screechCombats").to_int() > 0 && !contains_text(get_property("banishedPhyla"),"construct")){
        screechRefresh();
    }
    set_property("subscript","screech");
    use_familiar($familiar[patriotic eagle]);
    set_auto_attack("0");
    while (get_property("screechCombats") == "0" && !contains_text(get_property("banishedPhyla"),"construct")){
        set_property("famOverride","patriotic eagle");
        set_property("maxOverride","ml, -10 familiar weight, -equip drunkula's wineglass,-equip backup camera");
        set_property("acc3Override",",equip spring shoes");
        adv1($location[Madness Bakery],0,"");
    }
    set_property("subscript","");
    if (get_property("_cyberFreeFights").to_int() == 10){
        set_property("famOverride","");
        set_property("maxOverride","");
        set_property("acc2Override","");
        set_property("acc3Override","");
    }
}

// Screech-banish the beast phylum in the Bat Hole; assumes the eagle is already charged.
void banishBeast(){
    if (contains_text(get_property("banishedPhyla"),"beast"))
        return;
    if (patrioticDelays() < 11 && dayType() == 1)
        abort("Script out alternate banishing for gingerbread");
    screechRefresh();
    set_property("subscript","screech");
    set_auto_attack(0);
    if (get_property("screechCombats").to_int() == 0){
        set_property("maxOverride","ml, -10 familiar weight, -equip drunkula's wineglass,-equip backup camera");
        set_property("famOverride","patriotic eagle");
        retrieve_item($item[peppermint parasol]);
        adv1($location[The Bat Hole Entrance]);
    } else
        abort("Need to recharge patroitic eagle");
    set_property("subscript","");
    // The screech fight above wanted the CCS (auto-attack off); re-arm the
    // player's combat macro (combatMacroID pref) for the rest of the run.
    set_auto_attack(get_property("combatMacroID").to_int());
}

// Screech-banish the fish phylum in the Briniest Deepests; assumes the eagle is already charged.
void banishFish(){
    if (contains_text(get_property("banishedPhyla"),"fish"))
        return;
    screechRefresh();
    set_property("subscript","screech");
    set_auto_attack(0);
    if (get_property("screechCombats").to_int() == 0){
        set_property("maxOverride","ml, -10 familiar weight, -equip drunkula's wineglass,-equip backup camera");
        set_property("famOverride","patriotic eagle");
        if (have_effect($effect[Wet Willied]) == 0){
            set_property("famEquipOverride",", equip little bitty bathysphere");
        }
        if (have_effect($effect[fishy]) == 0)
            use($item[fishy pipe]);
        if (have_effect($effect[driving waterproofly]) == 0)
            set_property("pantsOverride",", equip really nice swimming trunk");
        retrieve_item($item[peppermint parasol]);
        adv1($location[The briniest deepests]);
    } else
        abort("Need to recharge patroitic eagle");
    set_property("subscript","");
    set_property("famEquipOverride","");
    set_property("pantsOverride","");
    // The screech fight above wanted the CCS (auto-attack off); re-arm the
    // player's combat macro (combatMacroID pref) for the rest of the run.
    set_auto_attack(get_property("combatMacroID").to_int());
}

// FreeKill-run bookkeeping run every turn: assert the last fight cost no real
// turn, keep the comma chameleon in the bag of many confections, and top up
// fishy in the Hidden Bowling Alley.
void freeKillTurnGuard(){
    if (get_property("script") != "FreeKill" || my_location() == $location[the hidden temple])
        return;
    if (get_property("LastFKTurn").to_int() + 50 < total_turns_played()){
        set_property("LastFKTurn",total_turns_played());
    } else if (get_property("LastFKTurn") != total_turns_played()){
        set_property("LastFKTurn",total_turns_played());
        abort("accidental turn spent during free kill");
    }
}

// Out of adventures: abort for a manual nightcap where needed, otherwise walk the
// bone-gear / stooper checklist one equip per turn ("refresh all; CONSUME ALL"
// re-enters this each pass) before the final CONSUME NIGHTCAP.
void endOfDayHandling(){
    if (my_adventures() != 0)
        return;
    if (have_equipped($item[drunkula's wineglass]))
        abort("Done for the day");
    if ($strings[solobop, 6-kiss, coat, stick,TTT] contains get_property("script")){
        if (!have_equipped($item[angelbone chopsticks])){
            equip($slot[acc3],$item[angelbone chopsticks]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (!have_equipped($item[devilbone greaves])){
            equip($item[devilbone greaves]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (!have_equipped($item[devilbone corset])){
            equip($item[devilbone corset]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (my_familiar() != $familiar[stooper]){
            use_familiar($familiar[stooper]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (!have_equipped($item[devilbone rosary]) && get_property("subscript") != "forest"){
            equip($slot[acc2],$item[devilbone rosary]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (!have_equipped($item[angelbone totem]) && get_property("subscript") != "village" && get_property("subscript") != "castle"){
            equip($item[angelbone totem]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (!have_equipped($item[angelbone dice])){
            equip($slot[acc1],$item[angelbone dice]);
            cli_execute("refresh all; CONSUME ALL");
            return;
        } else if (my_inebriety() == inebriety_limit() && dayType() == 1) {
            cli_execute("CONSUME NIGHTCAP");
            cli_execute("equip drunkula's wineglass; unequip devilbone rosary; unequip angelbone dice; familiar cookbookbat");
            return;
        }
    }
}

int pantsgivingAvailable(){
    if (dayType() == 0)
        return -1;
    if (get_property("_pantsgivingCount").to_int() >= 5){
        if (get_property("_pantsgivingCount").to_int() >= 50){
            if (get_property("_pantsgivingCount").to_int() >= 500){
                return 3;
            }
            return 2;
        }
        return 1;
    }
    return -1;
}

// Per-turn upkeep: safety aborts, script-specific bookkeeping, then the daily
// resource chores (Law of Averages, autumn-aton, resin, trainset, universe skill,
// sweat, leprecondo, consumable top-ups, yeti, distill), then end-of-day.
void postAdv(){
    if (contains_text(visit_url("main.php"),"You're fighting"))
        run_combat();
    // Bail loudly on a lost fight or a "stuck" last-adventure zone before doing anything else.
    set_property("NCtoC","false");
    if (get_property("_lastCombatLost") == "true" && get_property("noncombatForcerActive") != "true" && LastAdvTxt().contains_text("Round 1") && my_location() != $location[the outer compound] && last_monster() != $monster[flaming monstera] && last_monster() != $monster[leaviathan] && last_monster() != $monster[flaming leaflet]){
        cli_execute("cast tongue;cast cannel");
        abort("It appears you lost the last combat, look into that");
    }
    if (have_effect($effect[beaten up]) > 0 )
        cli_execute("cast tongue of the walrus");
    foreach adv in adventureAbortMessages {
        if (lastAdv == adv)
            abort(adventureAbortMessages[adv]);
    }
    foreach ef in $effects[juiced,majorly poisoned]{
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }
    if (item_amount($item[tiny stillsuit]) > 0 && have_familiar($familiar[tickle-me emilio]) && familiar_equipped_equipment($familiar[tickle-me emilio]) != $item[tiny stillsuit]){
        use_familiar($familiar[tickle-me emilio]);
        equip($item[tiny stillsuit]);
    }
    // Mer-kin Elementary: remember the choice ids seen so the queue stays a 6-wide FIFO.
    if (my_location() == $location[mer-kin elementary school] && to_monster(get_property("lastEncounter")) == $monster[none] && $ints[396, 397, 398, 399, 400, 401] contains last_choice()){
        buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
        append(elementaryQueue, ", " + last_choice());
        delete(elementaryQueue,0,5);
        set_property("elementaryQueue",to_string(elementaryQueue));
    }
    if (get_property("script") == "unblemishedPearl"){
        if (my_buffedstat($stat[moxie]) < 405)
            cli_execute("gain 405 moxie");
        if (have_effect($effect[fishy]) == 0)
            abort("Out of fishy");
    }
    if (get_property("script") == "FreeKill"){
        if (dayType() == 1){
            if (get_property("_eldritchTentaclesFoughtToday").to_int() == 11 && have_effect($effect[eldritch attunement]) > 0)
                cli_execute("uneffect eldritch attunement");
        }
        if (get_property("freeMeat").to_int() != my_meat( )){
            print ("FK meat profit of " + (my_meat( ) - get_property("freeMeat").to_int()));
            set_property("freeMeat",my_meat());
        }
    }
    freeKillTurnGuard();
    lawOfAverages();
    if (is_online("OnlyFax"))
        clanFortune();
    if (get_property("autumnatonQuestLocation") == "" && item_amount($item[autumn-aton]) > 0){
        upgradeAutumnaton();
    }
    if (have_effect($effect[resined]) == 0)
        use($item[distilled resin]);
    if (get_property("trainsetPosition").to_int() >= get_property("lastTrainsetConfiguration").to_int() + 42 && get_workshed() == $item[model train set]){
        visit_url("campground.php?action=workshed");
        trainset();
    }
    if (get_property("_universeCalculated").to_int() < get_property("skillLevel144").to_int() && uniAdv <= my_adventures())
        if (universe() == my_adventures()){
            visit_url("runskillz.php?action=Skillz&whichskill=144&targetplayer=0&quantity=1");
            visit_url("choice.php?whichchoice=1103&option=1&num="+uniInt);
        }
    if (get_property("_aug16Cast") == "false" && my_fullness() > 0)
        use_skill($skill[Aug. 16th: Roller Coaster Day!]);
    sweatpants();
    if (get_property("leprecondoInstalled") != "19,9,13,18" && to_int(get_property("_leprecondoRearrangements")) < 3){
        leprecondo("19,9,13,18,25");
    }
    if (have_equipped($item[drunkula's wineglass]) && dayType() == 0)
        abort("Done for the day");
    if ($familiar[cooler yeti].experience >= 400 && get_property("_coolerYetiAdventures") == "false" && my_inebriety() <= (inebriety_limit() - 4) && my_fullness() >= 2 && get_property("script") != "FreeKill"){
        cli_execute ("familiar cooler yeti");
        visit_url("main.php?talktoyeti=1", false);
        run_choice(2);
        cli_execute("drink doc clock's t");
    }
    if (my_inebriety() < inebriety_limit() && dayType() != 0 && my_adventures() < 60){
        visit_url("inventory.php?"+my_hash()+"&action=distill");
        run_choice(1);
    }
    if (pantsgivingAvailable() >= get_property("_pantsgivingFullness").to_int()){
        if (my_fullness() == fullness_limit()-1){
            cli_execute("CONSUME ORGANS 1 0 0");
        }
    }
    endOfDayHandling();
}

// Force-noncombat branch of spendAdv(): clear slime, spend free rests / tuba /
// clara bell, then push whichever NC-eligible quest (friars / temple / shadow) applies.
void forceNoncombats(){
    if (get_property("noncombatForcerActive") != "true" || get_property("script") == "solobop")
        return;
    uneffectDebuffs();
    NCforce(true);
    if (get_property("questM16Temple") != "finished" && get_property("seaAftercore") == "true"){
        while (get_property("noncombatForcerActive") == "true" && get_property("questM16Temple") != "finished")
            findHiddenTemple();
    } else if ((get_property("questL06Friar") == "started" || get_property("questL06Friar") == "step1") && dayType() == 0 && get_property("seaAftercore") == "true"){
        if (get_property("questL06Friar") == "started")
            visit_url("friars.php?action=friars");
        while (get_property("noncombatForcerActive") == "true" && (get_property("questL06Friar") == "started" || get_property("questL06Friar") == "step1")){
            friars();
        }
    } else {
        if (dayType() == 1)
            cli_execute("ash import farto;shadowRealmNCForce()");
        else
            abort("Have NCForces that should have been spent. This is a bug. Let FS know");
    }
}

// Day-1 sea-aftercore push for Azazel's unicorn: collect the three friar items,
// grind observational glasses at the Laugh Floor, farm backstage items, then run
// the Pandamonium / Sven band-member gift sequence. Normally gated on 5 spikolodon
// spikes on a day-1 sea-aftercore turn, but forced unconditionally once under 30
// adventures so a missed spike / dayType window still gets cleaned up before the day ends.
void azazelUnicornQuest(){
    int backstage1 = item_amount($item[gin-soaked blotter paper]) + item_amount($item[beer-scented teddy bear]) + item_amount($item[giant marshmallow]);
    int backstage2 = item_amount($item[booze-soaked cherry]) + item_amount($item[comfy pillow]) + item_amount($item[sponge cake]);
    if (get_property("questM10Azazel") != "finished" && (my_adventures() < 65 || delay())){
        uneffectDebuffs();
        if (get_property("questL06Friar") == "started")
            visit_url("friars.php?action=friars");
        location [item] friarItemLocations = {
            $item[dodecagram]: $location[the dark neck of the woods],
            $item[box of birthday candles]: $location[the dark heart of the woods],
            $item[eldritch butterknife]: $location[the dark elbow of the woods]
        };
        foreach friarItem in friarItemLocations {
            while (item_amount(friarItem) == 0 && get_property("questL06Friar") == "step1"){
                set_property("maxOverride","-combat");
                swordPrep();
                adv1(friarItemLocations[friarItem],0,"");
                if (get_property("questL05Goblin") == "started" && get_property("noncombatForcerActive") == false && get_property("_spikolodonSpikeUses").to_int() < 5) {
                    outskirts();
                } else {
                    set_property("maxOverride","-combat");
                    swordPrep();
                    adv1(friarItemLocations[friarItem],0,"");
                }
        }
        if (get_property("questL06Friar") == "step2")
            visit_url("friars.php?action=ritual");
        if (get_property("questL06Friar") == "finished"){
            //BC of the combat buffs, which is unusual, doing all at once
            while (item_amount($item[observational glasses]) == 0){
                set_property("maxOverride","combat");
                swordPrep();
                if (numeric_modifier("combat rate") < 35)
                    cli_execute("gain 35 combat rate 100 spendperturn");
                if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                    cli_execute("aprilband effect c");
                adv1($location[The Laugh Floor],0,"");
            }
            if ((backstage1 < 2 || backstage2 < 2) && item_amount($item[Azazel's unicorn]) == 0){
                if (have_effect($effect[Patent Aggression]) == 0){
                    set_property("maxOverride","-combat");
                    swordPrep();
                    adv1($location[Infernal Rackets Backstage],0,"");
                }
            }
        }
    }
    if (backstage1 > 1 && backstage2 > 1 && item_amount($item[observational glasses]) > 0){
        cli_execute("equip acc3 observational glasses; acquire 5 bus pass; acquire 5 imp air");
        visit_url("pandamonium.php?action=moan");
        visit_url("pandamonium.php?action=moan");
        visit_url("pandamonium.php?action=mourn");
        visit_url("pandamonium.php?action=mourn&preaction=observe");
        visit_url("pandamonium.php?action=sven");

        string [string] svenBandmembers = {
            "giant marshmallow": "Bognort",
            "beer-scented teddy bear": "Stinkface",
            "booze-soaked cherry": "Flargwurm",
            "comfy pillow": "Jim"
        };
        int [string] presentGiftIds = {
            "giant marshmallow": 4673,
            "beer-scented teddy bear": 4670,
            "booze-soaked cherry": 4671,
            "comfy pillow": 4672
        };
        int [string] absentGiftIds = {
            "giant marshmallow": 4675,
            "beer-scented teddy bear": 4675,
            "booze-soaked cherry": 4674,
            "comfy pillow": 4674
        };

        foreach gift in $strings[giant marshmallow, beer-scented teddy bear, booze-soaked cherry, comfy pillow] {
            visit_url("pandamonium.php?action=sven");
            int giveId = item_amount(to_item(gift)) > 0 ? presentGiftIds[gift] : absentGiftIds[gift];
            visit_url("pandamonium.php?action=sven&bandmember=" + svenBandmembers[gift] + "&togive=" + to_string(giveId) + "&preaction=try");
        }
        visit_url("pandamonium.php?action=temp");
        if (item_amount($item[steel margarita]) > 0)
            drink($item[steel margarita]);
    }
}

void chargeFams(){
    if (!can_adventure($location[An Overgrown Shrine (Southeast)]))
        return;
    adv1($location[An Overgrown Shrine (Southeast)]);
    use_familiar($familiar[mini kiwi]);
    equip($item[antique machete]);
    visit_url("inventory.php?action=parachute");
    visit_url("choice.php?option=1&whichchoice=1543&monid=1426");
}

void level11Sprint(){
    if ((have_effect($effect[everything looks red]) > 3 && have_effect($effect[everything looks yellow]) > 3 && have_effect($effect[everything looks green]) > 3) || my_adventures() < 60){
        if (get_property("questM16Temple") != "finished")
            return;
        if (get_property("questL11Black") == "step2"){
            retrieve_item($item[forged identification documents]);
            if (item_amount($item[bitchin' meatcar]) == 0)
                retrieve_item($item[bitchin' meatcar]);
            adv1($location[The Shore, Inc. Travel Agency]);
        } else if (get_property("questL11Worship") == "step1" || get_property("questL11Worship") == "step2"){
            if (item_amount($item[the Nostril of the Serpent]) == 0){
                use($item[stone wool]);
                set_property("choiceAdventure582","1");
                set_property("choiceAdventure579","2");
                while (have_effect($effect[Stone-Faced]) > 0)
                    adv1($location[the hidden temple]);
            } else {
                use($item[stone wool]);
                set_property("choiceAdventure582","2");
                while (have_effect($effect[Stone-Faced]) > 0){
                    adv1($location[the hidden temple]);
                    visit_url("main.php");
                    run_choice(-1);
                }
            }
        }
        unlock_zeppelin();
        if (get_property("questL11Worship") == "step3" && get_property("screechCombats").to_int() > 0 && get_property("questL11Spare") == "unstarted"){
            while(get_property("questL11Spare") == "unstarted"){
                cli_execute("acquire antique machete;equip weapon antique machete");
                set_property("maxOverride","familiar exp, -weapon");
                set_property("mainOverride"," ");
                adv1($location[An Overgrown Shrine (Southeast)]);
            }
            set_property("maxOverride","");
            set_property("mainOverride","");
        }
    }
}

void ELKPrep(){
    if (have_effect($effect[everything looks yellow]) == 0)
        set_property("shirtOverride",",equip parka (dilophosaur)");
    else if (have_effect($effect[everything looks red]) == 0)
        set_property("acc1Override",", equip everfull dart holster");
}

// Burn the turn on the next task in priority order: forced NCs, spooky-forest
// delay, the Azazel push, Black Forest / Guild loops, spikolodon temple, in-run
// free kills, Shadow Rift, cookbookbat, Book of Facts wishes, then level 11.
void spendAdv(){
    set_property("inSpendAdv","true");
    forceNoncombats();
    if (dayType() == 0){
        if (delay() && get_property("seaAftercore") == "true"){
            delayPrep();
            if (get_property("questM16Temple") != "finished")
                findHiddenTemple();
            else if (get_property("questM10Azazel") != "finished")
                azazelUnicornQuest();
            else if ((get_property("questG09Muscle") != "finished" && my_class() == $class[seal clubber]) || get_property("questL05Goblin") == "started")
                outskirts();

            set_property("mainOverride","");
            set_property("acc3Override","");
        }
        if (free_Kill()){
            if (get_property("script") != "6-kiss" && get_property("script") != "TTT" && get_property("script") != "slime" && dayType() == 1)
                return;
            ELKPrep();

            if (to_int(get_property("blackForestProgress")) < 5)
                blackForest();
            else if ((get_property("questG09Muscle") != "finished" && my_class() == $class[seal clubber]) || get_property("questL05Goblin") == "started")
                outskirts();
            else if (get_property("questM16Temple") != "finished")
                findHiddenTemple();
            else if (get_property("questM10Azazel") != "finished")
                azazelUnicornQuest();

            set_property("shirtOverride","");
            set_property("acc1Override","");
        }
        if (my_adventures() < 65){
            while (get_property("questM16Temple") != "finished")
                findHiddenTemple();
            while (get_property("questM10Azazel") != "finished" && have_effect($effect[Patent Aggression]) == 0)
                azazelUnicornQuest();
            if (get_property("questM10Azazel") != "finished"){
                print(numeric_modifier("combat rate"));
            }
            while (to_int(get_property("blackForestProgress")) < 5)
                blackForest();
            while (my_adventures() < 30 && ((get_property("questG09Muscle") != "finished" && my_class() == $class[seal clubber]) || get_property("questL05Goblin") == "started"))
                outskirts();
        }
    }
    if (have_effect($effect[everything looks beige]) == 0 && (my_adventures() > 50 || dayType() == 1))
        chargeFams();

    location CBBLoc = to_location(get_property("_cookbookbatQuestLastLocation"));
    if (!contains_text(get_property("_perilLocations"), to_string(to_int(CBBLoc))) && CBBLoc!= $location[the primordial soup]
        && get_property("_cookbookbatQuestIngredient") == "Yeast of Boris"
        && have_effect($effect[everything looks beige]) > 30 && my_adventures() > 50){
        cookbookbat();
    }
    if (free_run() && my_inebriety() <= inebriety_limit()){
        set_property("maxOverride","combat");
        set_property("famOverride", "cookbookbat");
        set_property("mainOverride",", equip june cleaver");
        set_property("pantsOverride", ", equip designer sweatpants");
        adv1($location[cobb's knob treasury]);
        set_property("maxOverride","");
        set_property("famOverride", "");
        set_property("mainOverride","");
        set_property("pantsOverride", "");
    }
    if (my_adventures() < 60 && to_int(get_property("_bookOfFactsWishes")) < 3)
        BoFaWish();
    if (dayType() == 0 &&  my_adventures() < 10){
        banishFish();
        set_property("famOverride","");
    }
    level11Sprint();
}

void main(){
    string boof = get_property("betweenBattleScript");
    if (get_property("script") != "FreeKill"){
        set_property("hpAutoRecovery",0.75);
        set_property("hpAutoRecoveryTarget",0.95);
        set_property("mpAutoRecovery",0.45);
        set_property("mpAutoRecoveryTarget",0.6);
    }
    try {
        postAdv();
        // This is to prevent an infinite postadventure loop
        if (my_adventures() != 0 && get_property("inSpendAdv") != "true"
            && !($strings[6-kiss,coat,stick,slime] contains get_property("script"))){
            try{
                spendAdv();
            } finally {
                set_property("inSpendAdv","false");
            }
        }
    } finally {
        set_property("betweenBattleScript",boof);
        set_property("afterAdventureScript","postadventure.ash");
    }
}
