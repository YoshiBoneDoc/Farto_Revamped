import iotm.ash;

// ─── postadventure.ash ───────────────────────────────────────────────────────
// FreeKill bookkeeping, construct banishing, and shared post-adventure upkeep.
// Adventure routing belongs to TeresMimic and the other calling scripts.

// Zone mafia last adventured in; compared against adventureAbortMessages.
string lastAdv = get_property("lastAdventure");

// "stuck" last-adventure zones -> postAdv() aborts with the mapped message.
string [string] adventureAbortMessages = {
    "Poisoned Spleen": "Spleen Poisoned",
    "Bloated and Nauseous": "Overfull",
    "Drunken Stupor": "Overdrunk"
};

// Burn the day's Law of Averages while under 100 adventures: unconditional on day
// 1, day 2 only once Steely-Eyed Squint is up so the copy is worthwhile.
void lawOfAverages(){
    if (my_adventures() < 100 && get_property("_lawOfAveragesUsed") == "0" && dayType() == 1 && have_item($item[law of averages]))
        use($item[law of averages]);
}

// Spend built-up sweat to clear inebriety.
void sweatpants(){
    if (get_property("sweat").to_int() <= 75)
        return;
    if (get_property("_sweatOutSomeBoozeUsed").to_int() < 3 && my_inebriety() > 3)
        use_skill($skill[sweat out some booze]);
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

// Banish constructs in Madness Bakery using Eagle, then free-run with spring shoes.
// Bakery overrides are temporary; the caller sets up the cyberzone outfit afterward.
void constructBanish(){
    if (get_property("_cyberFreeFights").to_int() >= 10)
        return;
    if (contains_text(get_property("banishedPhyla"), "construct"))
        return;
    if (get_property("screechCombats").to_int() > 0){
        print("[DEBUG] Eagle Screech isn't ready.", "red");
        return;
    }
    string[string] saved;
    foreach pref in $strings[subscript, famOverride, maxOverride, acc3Override]
        saved[pref] = get_property(pref);
    int savedAutoAttack = get_auto_attack();
    try {
        if (!use_familiar($familiar[patriotic eagle])){
            print("[DEBUG] Could not equip Patriotic Eagle for the construct banish.", "red");
            return;
        }
        set_property("subscript","screech");
        set_auto_attack(0);
        while (get_property("screechCombats").to_int() == 0 && !contains_text(get_property("banishedPhyla"),"construct")){
            set_property("famOverride","patriotic eagle");
            set_property("maxOverride","ml, -10 familiar weight, equip spring shoes");
            set_property("acc3Override",",equip spring shoes");
            if (!adv1($location[Madness Bakery],0,"")){
                print("[DEBUG] Madness Bakery adventure failed during the construct banish.", "red");
                break;
            }
        }
        if (!contains_text(get_property("banishedPhyla"), "construct"))
            print("[DEBUG] Constructs were not banished; continuing without the Screech banish.", "red");
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
        set_auto_attack(savedAutoAttack);
    }
}

// Stop on spent turns during FreeKill testing.
void freeKillTurnGuard(){
    if (get_property("script") != "FreeKill")
        return;
    int turnsNow = total_turns_played();
    string previousTurn = get_property("LastFKTurn");
    int turnsSpent = turnsNow - previousTurn.to_int();
    set_property("LastFKTurn", turnsNow);
    // The Hidden Temple is an existing exception for intentional paid adventures.
    // Abort while testing individual phases; switch to a red warning once dailyFKs is verified.
    // The final Rift phase intentionally pays for combats that arm NC forces.
    if (previousTurn != "" && turnsSpent > 0 && my_location() != $location[the hidden temple]
        && get_property("subscript") != "shadowForcers")
        abort("FreeKill unexpectedly spent " + turnsSpent + " turn(s) at "
            + my_location() + " against " + last_monster() + ".");
}

// Avoid buying MP before every Lucky! encounter just to burn it on a Libram.
void spendSpareLibramMP(){
    if (!have_skill($skill[Summon Party Favor]))
        return;
    if (get_property("script") != "embezzler"){
        if (my_mp() >= mp_cost($skill[Summon Party Favor]))
            cli_execute("cast * Summon Party Favor");
        return;
    }
    int reserveMP = max(300, 10 * mp_cost($skill[Weapon of the Pastalord]));
    while (my_mp() >= reserveMP + mp_cost($skill[Summon Party Favor])){
        if (!use_skill(1, $skill[Summon Party Favor]))
            break;
    }
}

// Per-turn upkeep: safety aborts, script-specific bookkeeping, then the daily
// resource chores (Law of Averages, autumn-aton, resin, trainset, universe skill,
// sweat, consumable top-ups, distill).
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
    if (item_amount($item[tiny stillsuit]) > 0 && have_familiar($familiar[Animated Macaroni Duck]) && familiar_equipped_equipment($familiar[Animated Macaroni Duck]) != $item[tiny stillsuit]){
        use_familiar($familiar[Animated Macaroni Duck]);
        equip($item[tiny stillsuit]);
    }
    if (get_property("script") == "FreeKill"){
        if (dayType() == 1){
            if (get_property("_eldritchTentaclesFoughtToday").to_int() == 11 && have_effect($effect[eldritch attunement]) > 0)
                cli_execute("uneffect eldritch attunement");
        }
        if (get_property("freeMeat").to_int() != my_meat( )){
            print("FK meat profit of " + to_string(my_meat() - get_property("freeMeat").to_int(), "%,d") + " from this fight", "blue");
            set_property("freeMeat",my_meat());
        }
    }
    freeKillTurnGuard();
    cleanupGingerbreadAdventure();
    // Claim once the uninterrupted toss/catch streak reaches the daily reward.
    if (get_property("_waterBalloonTossStreak").to_int() >= 111
        && !get_property("_waterBalloonBuffGranted").to_boolean()){
        visit_url("council.php");
        if (get_property("_waterBalloonBuffGranted").to_boolean())
            print("Water Balloon Champion claimed; balloon stalling is done for today.", "blue");
        else
            print("Could not claim Water Balloon Champion from the Council.", "red");
    }
    lawOfAverages();
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
    int stillsuitDrams = get_property("familiarSweat").to_int();
    int distillateAdventures = round(stillsuitDrams ** 0.4);
    if (distillateAdventures >= 12 && my_inebriety() <= inebriety_limit() - 2){
        print("Stillsuit: distilling " + stillsuitDrams + " drams for " + distillateAdventures + " base adventures.", "blue");
        visit_url("inventory.php?"+my_hash()+"&action=distill");
        if (handling_choice() && last_choice() == 1476)
            run_choice(1);
    }
    spendSpareLibramMP();
}

// Adventure routing stays with the calling script; this hook only runs upkeep.
void main(){
    string boof = get_property("betweenBattleScript");
    try {
        postAdv();
    } finally {
        set_property("betweenBattleScript",boof);
        set_property("afterAdventureScript","postadventure.ash");
    }
}
