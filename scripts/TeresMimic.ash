// StockingMimic.ash -- FKPrep + bulkFK and their helper trees, being lifted out of farto.ash.

import iotm.ash;
import preadventure.ash;
import farmingProfit.ash;
import TeresMimicDiet.ash;

string highStat = "";
string lowStat = "";
int [string] chibiStats;

record choicePair {
    int first;
    int second;
};

// Progress tracker -- prints "SM: phase: XXX" (mirrors UnderTheSea's step()) so an
// abort partway through a run is easy to place.
void step(string msg){
    print("SM: " + msg, "blue");
}

// ─── helpers used by FKPrep ──────────────────────────────────────────────────

void setClan(string clanType){
    if (clanType == "VIP") {
        if (get_clan_name() != "Bonus Adventures from Hell")
            cli_execute("/whitelist Bonus Adventures from Hell");
    }
    else if (clanType == "stash") {
        if (get_clan_name() != "Soup Clan")
            cli_execute("/whitelist Soup Clan");
    }
    return;
}
void monkeyPaw(string buffType){
    if (buffType == "custom"){
        foreach ef in $effects[covetous robbery, \[1701\]Hip to the Jive, Down With Chow, Frosty]{
            if (to_int(get_property("_monkeyPawWishesUsed")) >= 4)
                return;
            if (have_effect(ef) == 0)
                cli_execute("monkeypaw effect " + ef);
        }
    } else if (buffType == "meat"){
        foreach ef in $effects[Braaaaaains, Frosty, Let's Go Shopping!, covetous robbery, Low on the Hog, Leisurely Amblin']{
            if (to_int(get_property("_monkeyPawWishesUsed")) == 5)
                return;
            if (have_effect(ef) == 0)
                cli_execute("monkeypaw effect " + ef);
        }
    } else if (buffType == "familiar weight"){
        foreach ef in $effects[covetous robbery, \[1701\]Hip to the Jive, Down With Chow, Frosty, Chow Downed, squirming like a toad, heavy petting, cute vision, meat puppet, Braaaaaains,sinuses for miles]{
            if (to_int(get_property("_monkeyPawWishesUsed")) == 5)
                return;
            if (have_effect(ef) == 0)
                cli_execute("monkeypaw effect " + ef);
        }
    }
}
void chibiBuddy(){
    highStat = "";
    lowStat = "";

    foreach cstat in chibiStats {
        if (highStat == "" || chibiStats[cstat] > chibiStats[highStat])
            highStat = cstat;

        if (lowStat == "" || chibiStats[cstat] < chibiStats[lowStat])
            lowStat = cstat;
    }

    choicePair [string] raiseLow = {
        "chibiAlignment":     new choicePair(4,1),
        "chibiFitness":       new choicePair(1,1),
        "chibiIntelligence":  new choicePair(2,1),
        "chibiSocialization": new choicePair(3,1)
    };

    if (chibiStats[highStat] <= 5) {
   #     set_property("chibiChoice1", raiseLow[lowStat].first);
    #    set_property("chibiChoice2", raiseLow[lowStat].second);
        return;
    }

    choicePair [string] lowerHigh = {
        "chibiAlignment":     new choicePair(3,2),
        "chibiFitness":       new choicePair(4,2),
        "chibiIntelligence":  new choicePair(1,2),
        "chibiSocialization": new choicePair(2,2)
    };

    if (chibiStats[lowStat] >= 5) {
   #     set_property("chibiChoice1", lowerHigh[highStat].first);
   #     set_property("chibiChoice2", lowerHigh[highStat].second);
        return;
    }

    // -------------------------------
    // Transfer from highest to lowest
    // -------------------------------

    choicePair [string] transfer = {
        "chibiAlignment|chibiFitness": new choicePair(2,4),
        "chibiAlignment|chibiIntelligence": new choicePair(3,5),
        "chibiAlignment|chibiSocialization": new choicePair(1,5),

        "chibiFitness|chibiAlignment": new choicePair(3,4),
        "chibiFitness|chibiIntelligence": new choicePair(4,3),
        "chibiFitness|chibiSocialization": new choicePair(2,3),

        "chibiIntelligence|chibiAlignment": new choicePair(1,4),
        "chibiIntelligence|chibiFitness": new choicePair(3,3),
        "chibiIntelligence|chibiSocialization": new choicePair(4,5),

        "chibiSocialization|chibiAlignment": new choicePair(2,5),
        "chibiSocialization|chibiFitness": new choicePair(4,4),
        "chibiSocialization|chibiIntelligence": new choicePair(1,3)
    };

    string key = highStat + "|" + lowStat;

    if (transfer contains key) {
        set_property("chibiChoice1", transfer[key].first);
        set_property("chibiChoice2", transfer[key].second);
    }
}
void chibiHandling(){
    chibiStats["chibiAlignment"] = to_int(get_property("chibiAlignment"));
    chibiStats["chibiFitness"] = to_int(get_property("chibiFitness"));
    chibiStats["chibiIntelligence"] = to_int(get_property("chibiIntelligence"));
    chibiStats["chibiSocialization"] = to_int(get_property("chibiSocialization"));
    boolean balanced = true;
    foreach cstat in chibiStats
        balanced &= chibiStats[cstat] >= 4 && chibiStats[cstat] <= 6;

    // seed highStat / lowStat so the loop condition below is valid on the first check
    highStat = "";
    lowStat = "";
    foreach cstat in chibiStats {
        if (highStat == "" || chibiStats[cstat] > chibiStats[highStat])
            highStat = cstat;
        if (lowStat == "" || chibiStats[cstat] < chibiStats[lowStat])
            lowStat = cstat;
    }

    while (!balanced && chibiStats[highStat] > 5 && chibiStats[lowStat] < 5){
        chibiStats["chibiAlignment"] = to_int(get_property("chibiAlignment"));
        chibiStats["chibiFitness"] = to_int(get_property("chibiFitness"));
        chibiStats["chibiIntelligence"] = to_int(get_property("chibiIntelligence"));
        chibiStats["chibiSocialization"] = to_int(get_property("chibiSocialization"));
        balanced = true;
        foreach cstat in chibiStats
            balanced &= chibiStats[cstat] >= 4 && chibiStats[cstat] <= 6;

        if (balanced)
            break;
        chibiBuddy();
        use($item[ChibiBuddy&trade; (on)]);
        set_property("chibiChoice1","0");
        set_property("chibiChoice2","0");
    }
}
void dailyBirdBuffs(){
    if (have_skill($skill[Visit your Favorite Bird])
        && !get_property("_favoriteBirdVisited").to_boolean()){
        if (!use_skill(1, $skill[Visit your Favorite Bird]))
            print("Could not visit your favorite bird.", "red");
    }

    // Read the owned calendar to unlock today's bird; don't buy another calendar.
    if (!get_property("_canSeekBirds").to_boolean()){
        if (available_amount($item[Bird-a-Day calendar]) == 0)
            return;
        if (!retrieve_item(1, $item[Bird-a-Day calendar])
            || !use(1, $item[Bird-a-Day calendar]))
            return;
    }
    if (!have_skill($skill[Seek out a Bird]))
        return;

    // Six casts cost 5, 10, 20, 40, 80, 160 MP before adjustments.
    // Stop before the 320-MP cast, even if MP discounts make it cheaper.
    while (get_property("_birdsSoughtToday").to_int() < 6
        && mp_cost($skill[Seek out a Bird]) < 314){
        int soughtBefore = get_property("_birdsSoughtToday").to_int();
        if (!use_skill(1, $skill[Seek out a Bird]))
            break;
        if (get_property("_birdsSoughtToday").to_int() <= soughtBefore){
            print("Bird seeking stopped: the daily cast counter did not advance.", "red");
            break;
        }
    }
}

void prepBuffs(){
    // Yam battery
	if (item_amount($item[yam battery]) > 0 && !get_property("_yamBatteryUsed").to_boolean())
		use(1, $item[yam battery]);
	// Golden dice random effects
	if (get_property("_glennGoldenDiceUsed") == "false" && have_item($item[Glenn's golden dice]))
		use($item[Glenn's golden dice]);
    // Universal Seasoning
    if (get_property("_universalSeasoningsUsed") == 0 && have_item($item[Universal Seasoning]))
        use($item[universal seasoning]);
    // Daily BCZ casts
    int castsRemaining = max(0, 9 - get_property("_bczSweatEquityCasts").to_int());
    if (castsRemaining > 0)
        cli_execute("cast " + castsRemaining + " bcz: Sweat Equity");
    castsRemaining = max(0, 6 - get_property("_bczSpinalTapasCasts").to_int());
    if (castsRemaining > 0)
        cli_execute("cast " + castsRemaining + " BCZ: Prepare Spinal Tapas");
    castsRemaining = max(0, 6 - get_property("_bczBloodThinnerCasts").to_int());
    if (castsRemaining > 0)
        cli_execute("cast " + castsRemaining + " BCZ: Create Blood Thinner");
    castsRemaining = max(0, 6 - get_property("_bczPheromoneCocktailCasts").to_int());
    if (castsRemaining > 0)
        cli_execute("cast " + castsRemaining + " BCZ: Craft a Pheromone Cocktail");

    setClan("stash");
    // effects that interfere with other buffs we need
    string [int] songEffects = {"Ode to Booze", "The Moxious Madrigal", "The Magical Mojomuscular Melody", "Cletus's Canticle of Celerity", "Power Ballad of the Arrowsmith", "Jackasses' Symphony of Destruction", "Brawnee's Anthem of Absorption", "Psalm of Pointiness", "Stevedave's Shanty of Superiority", "Aloysius' Antiphon of Aptitude", "The Sonata of Sneakiness", "Carlweather's Cantata of Confrontation", "Ur-Kel's Aria of Annoyance", "Dirge of Dreadfulness", "Benetton's Medley of Diversity", "Elron's Explosive Etude", "Prelude of Precision", "Donho's Bubbly Ballad", "Cringle's Curative Carol", "Inigo's Incantation of Inspiration"};
    foreach i, effectName in songEffects {
        effect ef = to_effect(effectName);
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }
    // Remove effects that cause thorns, damage every round, or sporadic damage.
    foreach ef in my_effects(){
        if (numeric_modifier(ef, "Thorns") != 0
            || numeric_modifier(ef, "Damage Aura") != 0
            || numeric_modifier(ef, "Sporadic Damage Aura") != 0) {
            print("Removing passive-damage effect: " + ef, "blue");
            cli_execute("uneffect " + ef);
        }
    }

    // Adobe Ayam Subscription' buff
    while (have_effect($effect[Adobe Ayam Subscription]) < 800) {
        visit_url("inventory.php?pwd=" + my_hash() + "&itemid=11515&action=adobesubscribe", false);
    }
    // boxing daycare buff
    if (to_boolean(get_property("daycareOpen")) || to_boolean(get_property("_daycareToday"))) {
        if (to_int(get_property("_daycareGymScavenges")) == 0)
            cli_execute("daycare scavenge free");
        if (to_int(get_property("_daycareRecruits")) == 0 && my_meat() >= 100) {
            visit_url("place.php?whichplace=town_wrong&action=townwrong_boxingdaycare");
            run_choice(3);
            if (to_int(get_property("_daycareRecruits")) == 0)
                run_choice(1);
            run_choice(5);
            run_choice(4);
        }
        if (!to_boolean(get_property("_daycareSpa")))
            cli_execute("daycare mysticality");
    }
    // Heartstone Pals
    int palsCastsRemaining = max(0, 5 - to_int(get_property("_heartstonePalsUsed")));
    if (palsCastsRemaining > 0)
        cli_execute("cast " + palsCastsRemaining + " Heartstone: %pals");

    // fam weight
    string [int] famWeightEffects = {"Robot Friends", "Healthy Green Glow", "Chorale of Companionship", "Human-Fish Hybrid", "Whole Latte Love", "Shortly Stacked", "Thoughtful Empathy", "Leash of Linguini", "blood bond", "Empathy", "Black Tongue", "Man's Worst Enemy", "Kindly Resolve", "Human-Machine Hybrid", "Shrimpin' Ain't Easy", "Over-Familiar With Dactyls", "Loyal Tea", "Warm Shoulders", "One Foot Heavier", "Work For Hours a Week", "Panna Consideration", "Loyal as a Rock", "Candied Devil", "Wildsun Boon", "Only Dogs Love a Drunken Sailor", "Best Pals", "Heart of Green", "Bestial Sympathy", "Herder, Bitter, Fester, Stranger", "Party Soundtrack", "Shortly Wired", "Crocodile Tear", "Spiced Out", "offhand remarkable", "Billiards Belligerence", "A Girl Named Sue"};
    foreach i, effectName in famWeightEffects {
        effect ef = to_effect(effectName);
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]) && ef.attributes != "nohookah")
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (ef == to_effect("Billiards Belligerence") || ef == to_effect("A Girl Named Sue"))
            setClan("VIP");
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    setClan("stash");
    if (have_effect($effect[Happy Salamander]) == 0){
        visit_url("clan_rumpus.php?action=click&spot=4&furni=1");
    }
    while (have_effect($effect[blue swayed]) < 60){
        use($item[pulled blue taffy]);
    }
    while (have_effect($effect[She Ate Too Much Candy]) < 30){
        use($item[Prunets]);
    }
    while (have_effect($effect[Cold Hearted]) < 30){
        use($item[love song of icy revenge]);
    }

    // meat drop
    while (have_effect($effect[Merry Smithsness]) < 800){
        if (item_amount($item[Flaskfull of Hollow]) == 0 && !retrieve_item(1, $item[Flaskfull of Hollow]))
            abort("Could not buy Flaskfull of Hollow.");
        if (!use(1, $item[Flaskfull of Hollow]))
            abort("Could not use Flaskfull of Hollow.");
    }
    while (have_effect($effect[How to Scam Tourists]) < 900){
        retrieve_item(1, $item[How to Avoid Scams]);
        use(1, $item[How to Avoid Scams]);
    }
    if (have_effect($effect[Winklered]) == 0)
        cli_execute("concert Winklered");
    string [int] meatDropEffects = {"Incredibly Well Lit", "Loded", "Tubes of Universal Meat", "Holiday Bliss", "So You Can Work More...", "Legendary Pasta Eyeball", "Polka of Plenty", "Meet the Meat", };
    foreach i, effectName in meatDropEffects {
        effect ef = to_effect(effectName);
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
            continue;
        if (ef == $effect[Meet the Meat]){
            if (get_property("_clanFortuneBuffUsed") == "true")
                continue;
            else
                setClan("VIP");
        }
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    setClan("stash");
    // Additional farming buffs, acquired only when missing.
    foreach ef in $effects[Flapper Dancin', Polka Face,
        The Ballad of Richie Thingfinder, Earning Interest, Bet Your Autumn Dollar,
        Sweat Equity, Heart of Pink, Disco Leer]{
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    if(item_amount($item[pair of candy glasses]) < 1)
        cli_execute("make pair of candy glasses");
    //item drop
    string [int] itemDropEffects = {"Steely-Eyed Squint", "Spookyravin'", "Unbarking Dogs", "One Very Clear Eye", "Materiel Intel", "Spitting Rhymes", "Joyful Resolve", "Lubricating Sauce", "Cybercrime Eyes", "Crunching Leaves", "Ocelot Eyes", "Heart of Lavender", "Fortunate Resolve", "Perceptive Pressure", "Sucrose-Colored Glasses", "Eagle Eyes", "Singer's Faithful Ocelot", "Car-Charged", "Lantern-Charged"};
    foreach i, effectName in itemDropEffects {
        effect ef = to_effect(effectName);
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
        continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)) && ef != to_effect("Steely-Eyed Squint"))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    string [int] otherItemDropEffects = {"Bow-Legged Swagger", "null afternoon"};
    foreach i, effectName in otherItemDropEffects {
        effect ef = to_effect(effectName);
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)) && to_skill(ef) != $skill[Bow-Legged Swagger])
        continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }

    // other random buffs to help with combat
    setClan("stash");
    cli_execute("use imported taffy; use 4 autumn years wisdom; cast 2 Carol of the Hells; use tobiko marble soda;");

    setClan("VIP");
    step("phase: FKPrep limited daily clan/other buffs");
    // Photo booth x3 effect +10-30 mp regen
    while (get_property("_photoBoothEffects").to_int() < 3) {
        int photosBefore = get_property("_photoBoothEffects").to_int();
        cli_execute("photobooth effect space");
    }
    cli_execute("swim laps"); // Lapdog: +20 ML
    cli_execute("pool 3"); // +10% item
    while (get_property("_poolGames").to_int() < 3)  // Play Pool
        cli_execute("pool 1"); // +5 familiar lb
    if (get_property("friarsBlessingReceived") == "false")
        cli_execute("friars blessing 2");
    if (get_property("_portableSteamUnitUsed") == "false")
        cli_execute("use portable steam unit");
    setClan("stash");
}

// ─── FREE-KILL PREP ──────────────────────────────────────────────────────────

void doSpleen(){
    setClan("stash");
    string [int] spleenItems = {"medicinal gruel", "psilocyber mushroom", "gleaming oyster egg", "Party-in-a-Can&trade;", "body spradium", "Crimbeau de toilette"};
    foreach i, itemName in spleenItems {
        item spl = to_item(itemName);
        if (my_spleen_use() >= 3)
            return;
        if (spl == $item[body spradium] && item_amount($item[body spradium]) == 0)
            continue;
        if (mall_price(spl) > 10000)
            continue;
        chew(spl);
    }
}
item cheapestPasta(){
    setClan("stash");
    int [item] pasta_prices;
    string [int] pastaItems = {"Gnocci Domani", "Formica e Pepe", "Tubetto Gelatto"};
    foreach i, itemName in pastaItems {
        item it = to_item(itemName);
        pasta_prices[it] = mall_price(it);
    }
    item cheap_pasta;
    int lowest_value = 999999999;
    foreach it, value in pasta_prices {
        if (value < lowest_value) {
            lowest_value = value;
            cheap_pasta = it;
        }
    }
    return cheap_pasta;
}

// cap - current for a preference that's either a plain daily counter or a "true"/"false"
// one-shot flag (to_int() chokes on the latter, so those are special-cased to 0/cap).
int prefFreeKillsLeft(string pref, int cap){
    string val = get_property(pref);
    if (val == "true")
        return 0;
    if (val == "false")
        return cap;
    return max(0, cap - to_int(val));
}

// Daily cap for every free kill source that's a simple "preference counts up to a cap"
// deal (looseFK()/weakMonsters() sources included). Keyed by the preference itself.
int [string] freeKillCap = {
    "_cyberFreeFights": 10,
    "_bczSweatBulletsCasts": 11,
    "_gingerbreadMobHitUsed": 1,
    "_shatteringPunchUsed": 3,
    "_firedJokestersGun": 1,
    "_assertYourAuthorityCast": 3,
    "_clubEmTimeUsed": 5,
    "_interestingCoinHeads": 1,
    "_aprilBandTomUses": 3,
    "_shadowBricksUsed": 13,
    "_gingerbreadCityTurns": 30,
    "_leafMonstersFought": 5,
    "_tiedUpFlamingLeafletFought": 1,
    "_brickoFights": 10,
    "_lynyrdSnareUses": 3,
    "_archSpadeDigs": 11,
    "_photocopyUsed": 1,
    "_molehillMountainUsed": 1,
    "_neverendingPartyFreeTurns": 10
};

// Preliminary estimate of remaining free kills for the given leg ("leg1", "leg2", or "both"),
// read straight off the daily-cap preferences bulkFK/FKPrep already track. Cobb's Knob Treasury
// adventures (embezzler/bander runaways), Black Crayon Flower (chained relativity/Pocket
// Professor), and The Deep Machine Tunnels (machine elf) are real fights, not free kills, so
// they're deliberately left out of the tally.
// --- function modified for hat path aftercore, no longer accepts string param for leg
int freeKillCount(){
    int n;
    foreach pref, cap in freeKillCap {
        n += prefFreeKillsLeft(pref, cap);
    }
    if (have_skill($skill[just the facts]))
        n += ((3 - to_int(get_property("_monsterHabitatsRecalled"))) * 5)
            + to_int(get_property("_monsterHabitatsFightsLeft"));
    // Gregarious sausage-goblin copies are free fights.
    if (get_property("beGregariousMonster").to_monster() == $monster[sausage goblin])
        n += get_property("beGregariousFightsLeft").to_int();
    if (have_item(to_item("combat lover's locket")))
        n += max(0, 3 - get_property("_locketMonstersFought").split_string(",").count());
    if (get_property("_shadowAffinityToday") == false){
        n += 11;
    } else if (get_property("_shadowAffinityToday") == true)
        n += have_effect($effect[shadow affinity]);
    if (have_item($item[Everfull Dart Holster]) && have_effect($effect[everything looks red]) == 0)
        n += 1;
    if (have_item($item[jurassic parka]) && have_effect($effect[everything looks yellow]) == 0)
        n += 1;
    if (contains_text(get_property("_trickOrTreatBlock"), "D"))
        n += 1;
    if (can_adventure($location[The Red Zeppelin]))
        n += max(0, 5 - to_int(get_property("_glarkCableUses")));
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"
        && mall_price($item[tied-up flaming monstera]) < 15000)
        n += 1;
    if (get_property("_tiedUpLeaviathanFought") == "false"
        && mall_price($item[tied-up leaviathan]) < 15000)
        n += 1;
    if (get_property("questPAGhost") == "started"
        || (get_property("questPAGhost") == "unstarted"
            && total_turns_played() >= to_int(get_property("nextParanormalActivity"))
            && item_amount($item[almost-dead walkie-talkie]) > 0))
        n += 1;
    if (get_property("_eldritchTentacleFought") == "false"
        && to_int(get_property("eldritchTentaclesFought")) < 11)
        n += 1;
    if (item_amount($item[envyfish egg]) > 0)
        n += 1;
    if (item_amount($item[shaking 4-D camera]) > 0)
        n += 1;
    n += item_amount($item[mimic egg]);
    return n;
}

// Effect extenders on day 1 of ascensions, some nohookah food on day 2
void dieting(){
//      dayType is 1 on a farming/aftercore day, 0 mid-ascension.
//      This replaced the old get_property("ascensionsToday") checks
//      and is the INVERSE polarity: where
//      those read "0" this reads 1, where they read "1" this reads 0.

    // Mid-Ascension DayType (0) Logic
    if (dayType() == 0){
        if (have_item($item[Bowl of Infinite Jelly]))
        put_closet($item[Bowl of Infinite Jelly]);
        foreach ef in my_effects(){
            if ($effects[Shadow Affinity, On the Trail, Lucky!, Apriling Band Battle Cadence,
                    Everything Looks Red, Everything Looks Yellow, Everything Looks Green,
            Apriling Band Patrol Beat] contains ef)
            continue;
            cli_execute("uneffect " + ef);
        }
		if (have_effect($effect[Shadow Affinity]) == 0)
			if (!user_confirm("dieting: Shadow Affinity fell off before the rollover-day binge. Continue?"))
                abort();
        if (have_item($item[law of averages]) && my_adventures()<200)
            use($item[law of averages]);
        if (have_item($item[Mayo Minder&trade;]) && get_property("mayoMinderSetting") != "Mayodiol")
            use($item[Mayo Minder&trade;]);
        if (closet_amount($item[Bowl of Infinite Jelly]) > 0 && my_fullness() == fullness_limit()-1)
            take_closet($item[Bowl of Infinite Jelly]);
        while (my_fullness() < fullness_limit()){
            if (get_property("legendaryNoodlesStomach") == 0 && fullness_limit()-my_fullness() > 1){
                eat (cheapestPasta());
            }
            if (have_effect($effect[jelly-coated insides]) > 0)
                abort("uneffect jelly-coated insides");
            if (get_property("spiceMelangeUsed") == "false" && my_fullness() > 3 && my_inebriety() > 3)
                use ($item[spice melange]);
            if (have_skill($skill[Sweat Out Some Booze]))
                use_skill($skill[Sweat Out Some Booze]);
        }
        if (get_property("_mimeArmyShotglassUsed") == "false")
            drink($item[Temps Tempranillo]);
        drink(inebriety_limit() - my_inebriety(), $item[Temps Tempranillo]);

        //implement when I get PANTSGIVING
/*        if (my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 1){
            if (item_amount($item[pantsgiving]) == 0)
                stashgrab($item[pantsgiving]);
            equip($item[pantsgiving]);
            use_familiar($familiar[patriotic eagle]);
            retrieve_item($item[dish of clarified butter]);
            visit_url("inv_use.php?which=3&whichitem=9908");
            run_combat();
            run_choice(-1);
            if (my_fullness() < fullness_limit())
                eat(1,$item[thyme jelly donut]);
        }
 */
        setClan("stash");
        if ((get_property("spiceMelangeUsed") == "false") && my_fullness() > 3 && my_inebriety() > 3)
            use ($item[spice melange]);
	    eat(fullness_limit() - my_fullness(), $item[thyme jelly donut]);
	    drink(inebriety_limit() - my_inebriety(), $item[Temps Tempranillo]);
        doSpleen();

    // Farming DayType (1) Logic
	} else {
        if (get_property("_cupOf13sJewels") == 13){
            // alternatives: tombstone-shaped Crimboween cookie (40 turns) --> mach 1 airplane (80 turns)
            cli_execute("acquire papier Mach 1 airplane; acquire clockwork pirate skull");
            cli_execute("acquire 4 Affirmation Cookie");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=11890&whichitem2=1363&whichitem3=9486");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=9486&whichitem2=9486&whichitem3=9486");
        }
/*
        } else {
            if (item_amount($item[asbestos meat stack]) < 4)
                cli_execute("make 4 asbestos meat stack");
            cli_execute("acquire 4 asbestos meat stack");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=376&whichitem2=376&whichitem3=376");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=376&whichitem2=2200&whichitem3=1708");
        }
*/
        // END OF DAY DIET BUFFING SHOULD GO HERE - eodDiet();
	}
}

// Spend the day's three Mayam Calendar resonance rings. Guarded on _mayamSymbolsUsed being empty, so a second call is a no-op.
void useMayamRings(){
	if (get_property("_mayamSymbolsUsed") != "" || !have_item($item[Mayam Calendar]))
		return;
	use_familiar($familiar[chest mimic]);
    cli_execute("mayam rings yam Meat Eyepatch Yam;" // yamtility belt
        + " mayam rings vessel yam cheese explosion;" // yam stinkbomb
        + " mayam rings fur Lightning yam clock");
}

void goodies() {
    setClan("VIP");
    retrieve_item(1, $item[carpe]);
    // Photo Booth allows three props per day. Check before each request.
    foreach prop in $items[Sheriff pistol, Sheriff badge, Sheriff moustache] {
        if (available_amount(prop) == 0 && get_property("_photoBoothEquipment").to_int() < 3)
            create(prop);
    }
    // Only request a missing instrument while a daily selection remains.
    if (available_amount($item[Apriling band quad tom]) == 0
        && get_property("_aprilBandInstruments").to_int() < 2
        && (item_amount($item[Apriling band helmet]) > 0 || have_equipped($item[Apriling band helmet])))
        cli_execute("aprilband item quad tom");
//    cli_execute("aprilband item sax");    -- moved this to inside embezzler(), now done with getLucky()
    setClan("stash");
    if((item_amount($item[Brutal brogues]) == 0)){
        retrieve_item($item[bastille battalion control rig loaner voucher]);
        cli_execute("bastille Brutalist Lava Gesture");
    }
    // Amulet coin
    if (available_amount($item[amulet coin]) == 0) {
        use_familiar($familiar[Cornbeefadon]);
        retrieve_item($item[box of Familiar Jacks]);
        use($item[box of Familiar Jacks]);
        use_familiar($familiar[Stocking Mimic]);
    }
    // Forsee peril
    while (get_property("_perilsForeseen") < 3){
        cli_execute("throw peridot of peril at Torturebot");
    }

    // Collect today's catalog credits before spending the remaining picks on VHS tapes.
    item catalog = item_amount($item[2002 Mr. Store Catalog]) + closet_amount($item[2002 Mr. Store Catalog]) > 0
        ? $item[2002 Mr. Store Catalog] : $item[Replica 2002 Mr. Store Catalog];
    if (item_amount(catalog) == 0 && closet_amount(catalog) > 0 && !take_closet(1, catalog))
        abort("Could not retrieve the 2002 Mr. Store Catalog from the closet.");
    if (item_amount(catalog) > 0 && !get_property("_2002MrStoreCreditsCollected").to_boolean()){
        if (!use(1, catalog))
            abort("Could not collect today's 2002 Mr. Store credits.");
    }
    if (get_property("_2002MrStoreCreditsCollected").to_boolean()){
        visit_url("shop.php?whichshop=mrstore2002");
        int credits = get_property("availableMrStore2002Credits").to_int();
        if (credits > 0){
            int tapes = item_amount($item[Spooky VHS Tape]);
            if (!buy($coinmaster[Mr. Store 2002], credits, $item[Spooky VHS Tape])
                || item_amount($item[Spooky VHS Tape]) - tapes != credits)
                abort("Could not spend the remaining 2002 Mr. Store credits on Spooky VHS Tapes.");
        }
    }

}

// Workshed rotation: harvest TakerSpace before the morning train installation;
// after BARF farming, more than 400 session adventures counts as end of day.
void craftTakerSpaceItem(item target){
    int quantity = creatable_amount(target);
    if (quantity > 0){
        print("TakerSpace: crafting " + quantity + " " + target + ".", "blue");
        if (!create(quantity, target))
            abort("TakerSpace: could not craft " + target + "; leaving the workshed installed.");
    }
}

void harvestTakerSpace(boolean bombsOnly){
    if (get_workshed() != $item[TakerSpace letter of Marque])
        return;
    string savedChoiceScript = get_property("choiceAdventureScript");
    try {
        set_property("choiceAdventureScript", "");
        // Visiting collects today's delivery and refreshes the resource counts.
        visit_url("campground.php?action=workshed");
        craftTakerSpaceItem($item[anchor bomb]);
        if (bombsOnly)
            return;
        craftTakerSpaceItem($item[tankard of spiced Goldschlepper]);
        craftTakerSpaceItem($item[tankard of spiced rum]);

        // Spend remaining supplies on saleable items, highest mall price first.
        // The four untradeable TakerSpace crafts are deliberately omitted.
        int[item] prices;
        while (true){
            item best = $item[none];
            int bestPrice = -1;
            foreach target in $items[sleeping profane parrot, pirrrate's currrse,
                packaged luxury garment, harpoon, chili powder cutlass,
                cursed Aztec tamale, jolly roger tattoo kit, golden pet rock,
                groggles, silky pirate drawers, spices]{
                if (creatable_amount(target) == 0)
                    continue;
                if (!(prices contains target))
                    prices[target] = max(autosell_price(target), mall_price(target));
                if (prices[target] > bestPrice){
                    best = target;
                    bestPrice = prices[target];
                }
            }
            if (best == $item[none])
                break;
            craftTakerSpaceItem(best);
        }
    } finally {
        set_property("choiceAdventureScript", savedChoiceScript);
        if (handling_choice() && last_choice() == 1537)
            run_choice(2);
    }
}

void installDailyWorkshed(item target){
    if (get_workshed() == target)
        return;
    if (get_property("_workshedItemUsed").to_boolean())
        abort("Workshed: today's switch has already been used; cannot install " + target + ".");
    if (available_amount(target) == 0 || !retrieve_item(1, target)
        || !use(1, target) || get_workshed() != target)
        abort("Workshed: could not install the owned " + target + ".");
}

void dailyWorkshed(){
    if (my_session_adv() > 400){
        if (get_workshed() == $item[model train set]){
            if (get_property("_workshedItemUsed").to_boolean()){
                print("Workshed: keeping the train tonight; today's switch was already used.", "blue");
                return;
            }
            installDailyWorkshed($item[TakerSpace letter of Marque]);
        }
        harvestTakerSpace(true);
        return;
    }
    if (get_workshed() == $item[model train set])
        return;
    // Check before harvesting so an unavailable switch leaves tomorrow's supplies intact.
    if (get_property("_workshedItemUsed").to_boolean()
        || available_amount($item[model train set]) == 0)
        abort("Workshed: cannot switch to the model train set before adventuring.");
    harvestTakerSpace(false);
    installDailyWorkshed($item[model train set]);
    visit_url("campground.php?action=workshed");
    trainset();
}

void FKPrep(){
    // TO DO: Implement differet dieting plans (at eod, beginning, etc)

	step("phase: FKPrep start");
    set_property("autoSatisfyWithStash", "true");
	starter();
	dailyWorkshed();
    if (to_int(get_property("_leprecondoRearrangements")) < 3){
        // Fixed aftercore layout: bed, laptop, treadmill, retro console.
        // The helper skips rearranging when these four are already installed.
        leprecondo("27,12,9,24");
    }
    // monolith
    visit_url("campground.php?action=monolith");

	// Combat runs off the player's saved combat macro (id in the combatMacroID
	// pref) as the native KoL auto-attack -- round 0 only works when the macro is
	// set natively, not embedded in a mafia CCS. starter() just cleared the

    // Get daily goodies (Sheriff gear, Marching Band stuff)
    step("phase: FKPrep getting sheriff and band goodies");
    goodies();
    if (get_property("_clanFortuneConsultUses").to_int() < 3 && is_online("OnlyFax"))
        clanFortune();

    // VYKEA furniture
    if (get_property("_VYKEACompanionLevel").to_int() == 0)
        cli_execute("create level 5 lightning couch");

	step("phase: FKPrep dieting");
	if (my_inebriety() < inebriety_limit()){
		dieting();
	}

	set_property("script", "FreeKill");
    retrieve_item($item[burning paper crane]);
    step("phase: 9 special buffs");
    foreach ef in $effects[Robot Friends,Healthy Green Glow,Shortly Stacked,Shortly Wired,steely-eyed squint,Human-Fish Hybrid,Black Tongue,Human-Machine Hybrid,Warm Shoulders]{
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    step("phase: FKPrep buffs");
	useMayamRings();  // keep before prepBuffs(), otherwise we wont get daily yam battery
    step("phase: FKPrep hidden temple");
	if (my_ascensions() != get_property("lastTempleAdventures").to_int()
		&& get_property("questM16Temple") == "finished"){
		use($item[stone wool]);
		set_property("choiceAdventure582", "1");
		set_property("choiceAdventure579", "3");
		adv1($location[The Hidden Temple]);
		useMayamRings();
	}
	// just use beret willy-nilly since we're in hat path
    while (get_property("_beretBuskingUses").to_int() < 5)
        use_skill($skill[Beret Busking]);

	prepBuffs();      // must stay after beret buffs to clear any passive/aura damage effects

	// legendary beat
    if (!get_property("_legendaryBeat").to_boolean())
        use($item[The Legendary Beat]);  // useful for sandworms later
    // bird-a-day
    dailyBirdBuffs();
    // monkey paw wishes
    monkeypaw("custom");
	// ChibiBuddy
	step("phase: FKPrep ChibiBuddy");
	if (get_property("_chibiChanged") == "false"){
		if (item_amount($item[ChibiBuddy&trade; (off)]) > 0)
			use($item[ChibiBuddy&trade; (off)]);
		cli_execute("chibi chat");
		chibiHandling();
	}
    // beach comb
	if (have_effect($effect[Do I Know You From Somewhere?]) == 0){
		if (item_amount($item[driftwood beach comb]) == 0)
			use($item[piece of driftwood]);
		cli_execute("beach head 10");
		cli_execute("combo 10");
	}
    use_familiar($familiar[stocking mimic]);

	step("phase: FKPrep stash pops");
	// Stash-borrowed one-a-day item pops.
    setClan("stash");
	refresh_stash();
	foreach it in $items[defective Game Grid token, BittyCar MeatCar, Platinum Yendorian Express Card]{
		if (stash_amount(it) > 0 && take_stash(1, it)){
			try {
				use(1, it);
			} finally {
				put_stash(1, it);
			}
		}
	}

    if (get_property("questPAGhost") == "unstarted" && !have_item($item[protonic accelerator pack])
        && total_turns_played() >= get_property("nextParanormalActivity").to_int()){
        use($item[almost-dead walkie-talkie]);
    }
	step("phase: FKPrep codpiece");
	codpiece("none");
    retrieve_item(2, $item[massive gemstone]);
	codpiece("peridot of peril,blood cubic zirconia,baseball diamond,massive gemstone,massive gemstone");
    //monster level
    // Initial ML belongs to prep; safeToFK can request more for a specific fight.
    cli_execute("gain 400 ml");
}

// ─── bulkFK and helpers (verbatim from farto.ash, not yet refactored) ────────

// Standard farming stance: stocking mimic (or skeleton fallback), maximize for
// familiar weight. Callers request required equipment through extraMax or overrides.
void equipStockingMimic(){
    if (have_familiar($familiar[stocking mimic]))
        set_property("famOverride","stocking mimic");
    else
        set_property("famOverride","Skeleton of Crimbo Past");
}

void mimicPrep(string extraMax){
    equipStockingMimic();
    set_property("maxOverride","familiar weight" + extraMax);
}
void mimicPrep(){
    mimicPrep("");
}

// Coldform belongs to combat phases, never FKPrep's buff cleanup.
void prepareDailyShardCombat(){
    if (have_effect($effect[Coldform]) == 0) {
        int savedClan = get_clan_id();
        try {
            if (item_amount($item[phial of coldness]) == 0 && storage_amount($item[phial of coldness]) > 0)
                take_storage(1, $item[phial of coldness]);
            if (item_amount($item[phial of coldness]) == 0) {
                setClan("stash");
                if (get_clan_name() != "Soup Clan")
                    abort("Could not check Soup Clan for Coldform supplies.");
                if (stash_amount($item[phial of coldness]) > 0)
                    take_stash(1, $item[phial of coldness]);
            }
            if (item_amount($item[phial of coldness]) == 0) {
                if (item_amount($item[cold cluster]) == 0 && storage_amount($item[cold cluster]) > 0)
                    take_storage(1, $item[cold cluster]);
                if (item_amount($item[cold cluster]) == 0 && stash_amount($item[cold cluster]) > 0)
                    take_stash(1, $item[cold cluster]);
                if (item_amount($item[cold cluster]) == 0) {
                    item cheapest = $item[none];
                    int cheapestPrice = 2147483647;
                    foreach source in $items[cold cluster, BOOtonniere, drafty drawers, old ball and chain, remorseless knife, snowstick] {
                        int price = mall_price(source);
                        if (price > 0 && price < cheapestPrice) {
                            cheapest = source;
                            cheapestPrice = price;
                        }
                    }
                    if (cheapest == $item[none] || buy(1, cheapest, cheapestPrice) != 1)
                        abort("Could not buy a cold cluster source.");
                    if (cheapest != $item[cold cluster])
                        cli_execute("pulverize 1 " + cheapest);
                }
                if (item_amount($item[scrumdiddlyumptious solution]) == 0 && stash_amount($item[scrumdiddlyumptious solution]) > 0)
                    take_stash(1, $item[scrumdiddlyumptious solution]);
                if (item_amount($item[cold cluster]) == 0
                    || !retrieve_item(1, $item[scrumdiddlyumptious solution])
                    || !create(1, $item[phial of coldness]))
                    abort("Could not craft a phial of coldness.");
            }
            if (!use(1, $item[phial of coldness]) || have_effect($effect[Coldform]) == 0)
                abort("Could not obtain Coldform for shard combat.");
        } finally {
            if (get_clan_id() != savedClan)
                cli_execute("/whitelist " + savedClan);
        }
    }
    if (!retrieve_item(1, $item[shard of double-ice]) || !retrieve_item(1, $item[dry noodles]))
        abort("Shard combat requires a shard of double-ice and dry noodles.");
}

// The caller owns script, autoattack, and day-level setup; CCS owns combat.
void eaglePledge(location pledgeLocation){
    // Reading the effect description updates _citizenZone and _citizenZoneMods.
    if (have_effect($effect[Citizen of a Zone]) > 0)
        visit_url("desc_effect.php?whicheffect=" + $effect[Citizen of a Zone].descid);
    if (have_effect($effect[Citizen of a Zone]) > 0
        && get_property("_citizenZone") == to_string(pledgeLocation)){
        print("Already pledged allegiance to " + to_string(pledgeLocation) + ".", "blue");
        return;
    }
    prepareDailyShardCombat();
    familiar savedFamiliar = my_familiar();
    string[string] saved;
    foreach pref in $strings[subscript, famOverride]
        saved[pref] = get_property(pref);
    try {
        set_property("subscript", "eaglePledge");
        // Keep preadventure from replacing the eagle with a farming familiar.
        set_property("famOverride", "patriotic eagle");
        if (!use_familiar($familiar[patriotic eagle]))
            abort("Could not equip the Patriotic Eagle.");

        if (!adv1(pledgeLocation))
            abort("Eagle pledge adventure failed.");
        if (have_effect($effect[Citizen of a Zone]) > 0)
            visit_url("desc_effect.php?whicheffect=" + $effect[Citizen of a Zone].descid);
        if (have_effect($effect[Citizen of a Zone]) == 0
            || get_property("_citizenZone") != to_string(pledgeLocation))
            abort("Did not acquire the pledge for " + to_string(pledgeLocation)
                + "; inspect the encounter before retrying.");
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
        if (current_round() == 0)
            use_familiar(savedFamiliar);
    }
}
// Prepare sausage-goblin copies; keep the candle goal through automatic preadventure.
void purpleCandlePrep(){
    prepareDailyShardCombat();
    mimicPrep(", -equip eternity codpiece");
    if (get_property("famOverride").to_familiar() == $familiar[stocking mimic]
        && have_effect($effect[everything looks purple]) == 0)
        set_property("maxOverride", get_property("maxOverride") + ", equip roman candelabra");
    if (available_amount($item[legendary seal-clubbing club]) > 0
        && get_property("script") != "FreeKill" && clubNextWeekReady())
        set_property("maxOverride", get_property("maxOverride") + ", equip legendary seal-clubbing club");
    else
        set_property("maxOverride", get_property("maxOverride") + ", -equip legendary seal-clubbing club");
    main@preadventure();
}

// Use the sausage goblin as the copy source, then finish the two black-crayon locket fights.
void reminisce() {
    if (locketAvailable() <= 0)
        return;
    string savedSubscript = get_property("subscript");
    int savedAutoAttack = get_auto_attack();
    string savedBetweenBattleScript = get_property("betweenBattleScript");
    string[string] savedGear;
    foreach pref in $strings[famOverride, maxOverride, pantsOverride]
        savedGear[pref] = get_property(pref);
    try {
        prepareDailyShardCombat();
        // Let the consult script copy the goblin before any automatic killing action.
        set_auto_attack(0);
        // Preparation is explicit here; the locket's automatic hook would repeat it.
        set_property("betweenBattleScript", "");
        foreach mon in $monsters[sausage goblin, black crayon flower, black crayon spiraling shape]{
            if (locketAvailable() == 0)
                break;
            if (mon == $monster[sausage goblin]){
                set_property("subscript", "locketCopySource");
                if (have_familiar($familiar[chest mimic])
                    && get_property("_mimicEggsObtained").to_int() < 10
                    && $familiar[chest mimic].experience > 100){
                    set_property("famOverride", "chest mimic");
                    set_property("maxOverride", "familiar experience, equip eternity codpiece");
                    if (available_amount($item[legendary seal-clubbing club]) > 0
                        && get_property("script") != "FreeKill" && clubNextWeekReady())
                        set_property("maxOverride", get_property("maxOverride") + ", equip legendary seal-clubbing club");
                    else
                        set_property("maxOverride", get_property("maxOverride") + ", -equip legendary seal-clubbing club");
                    main@preadventure( );
                } else {
                    purpleCandlePrep();
                }
            } else {
                set_property("subscript", "locketFight");
                mimicPrep();
                // Each locket fight consumes a shard; run preparation for each one.
                set_property("pantsOverride", mon == $monster[black crayon flower]
                    ? ", equip tearaway pants" : savedGear["pantsOverride"]);
                main@preadventure();
            }
            if (!cli_execute("reminisce " + mon))
                abort("Could not reminisce " + mon);
            main@postadventure();
        }
    } finally {
        foreach pref, value in savedGear
            set_property(pref, value);
        set_property("betweenBattleScript", savedBetweenBattleScript);
        set_property("subscript", savedSubscript);
        set_auto_attack(savedAutoAttack);
    }
}
// Protect forces one maximum-damage hit; repeated hits do not build the blessing.
int shieldMaidenHitEstimate(){
    int goblinAttack = monster_attack($monster[sausage goblin]);
    float damage = max(0, goblinAttack - my_buffedstat($stat[moxie]))
        + 0.25 * goblinAttack - damage_reduction();
    damage *= 1.0 - damage_absorption_percent() / 100.0;
    damage *= 1.0 - elemental_resistance($element[sleaze]) / 100.0;
    return max(1, floor(damage));
}

void shieldMaidenMeatBuff(){
    if (get_property("_blessingShieldSleazeReceived").to_boolean())
        return;
    if (item_amount($item[mimic egg]) == 0){
        print("Shield Maiden: no mimic egg available for the meat blessing.", "red");
        return;
    }

    familiar previousFamiliar = my_familiar();
    string [string] savedProperties;
    foreach prop in $strings[script,subscript,betweenBattleScript,afterAdventureScript]
        savedProperties[prop] = get_property(prop);
    cli_execute("checkpoint");
    try {
        // This one fight uses its own outfit and handler, without farming hooks.
        set_property("script", "FreeKill");
        set_property("subscript", "shieldMaiden");
        set_property("betweenBattleScript", "");
        set_property("afterAdventureScript", "");
        use_familiar($familiar[Meat Shield Maiden]);
        if (!maximize("moxie, -1000 DA, -1000 DR, -10000 sleaze resistance, -equip The Eternity Codpiece, -equip bat wings, -equip legendary seal-clubbing club, equip can of shield tenderizer", false)){
            print("Shield Maiden: could not prepare the blessing outfit; keeping the egg.", "red");
            return;
        }
        int hitEstimate = shieldMaidenHitEstimate();
        int damageTarget = have_equipped($item[can of shield tenderizer]) ? 576 : 729;
        print("Shield Maiden: estimated Protect hit " + hitEstimate + "; meat cap needs " + damageTarget + ".", "blue");
        if (hitEstimate < damageTarget + 10)
            print("Shield Maiden: this target is not optimal; estimated hit is too low to cap the meat buff. Continuing with whatever blessing we get.", "red");
        restore_hp(my_maxhp());
        restore_mp(100);
        if (my_hp() <= hitEstimate + 100){
            print("Shield Maiden: not enough HP for Protect; keeping the egg.", "red");
            return;
        }
        if (!cli_execute("c2t_megg fight sausage goblin")){
            print("Shield Maiden: could not start the sausage-goblin egg fight.", "red");
            return;
        }
        if (current_round() > 0)
            run_combat();
        if (get_property("_blessingShieldSleazeReceived").to_boolean()
            && get_property("blessingShieldSleazeTier").to_int() >= 10)
            print("Shield Maiden: maximum +50% meat blessing acquired.", "blue");
        else if (get_property("_blessingShieldSleazeReceived").to_boolean())
            print("Shield Maiden: meat blessing acquired at tier "
                + get_property("blessingShieldSleazeTier") + "/10; continuing with this buff.", "blue");
        else
            print("Shield Maiden: meat blessing was not acquired; check the combat log.", "red");
    } finally {
        foreach prop, value in savedProperties
            set_property(prop, value);
        use_familiar(previousFamiliar);
        cli_execute("outfit checkpoint");
    }
}

void shadowBoss(){
    set_property("maxOverride","familiar weight, -equip PirateRealm eyepatch, equip congressional medal of insanity");
    cli_execute("cast Carol of the Hells");
    cli_execute("use scroll of drastic healing");
    // 1st round atks for 90% of max hp
    if (get_property("rufusQuestTarget") == "shadow scythe") {
        use($item[scroll of drastic healing]);
        set_property("hpAutoRecovery", 1.0);
        set_property("hpAutoRecoveryTarget", 1.0);
        retrieve_item(60,$item[love song of smoldering passion]);
    }
    // reflects spells, has more elemental resist
    else if (get_property("rufusQuestTarget") == "shadow orrery"){
        set_property("shirtOverride",", equip ultracolor");
        set_property("mainOverride",", equip june cleaver");
    } else if (get_property("rufusQuestTarget") == "shadow spire"){
        set_property("hpAutoRecovery",0.36);
        set_property("hpAutoRecoveryTarget",0.36);
        cli_execute("recover hp");
    }
}

    // SHADOW REALM REWORK -----------------------
// Turn in completed quests, redeem lodestones, and optionally start an entity quest.
void settleRufusRewards(boolean startQuest) {
    location rift = $location[Shadow Rift (The Misspelled Cemetary)];
    item phone = $item[closed-circuit pay phone];
    item lodestone = $item[Rufus's shadow lodestone];
    string[string] saved;
    foreach pref in $strings[choiceAdventureScript, choiceAdventure1497, choiceAdventure1498, choiceAdventure1500]
        saved[pref] = get_property(pref);

    try {
        // Handle phone choices explicitly instead of using generalChoice's policy.
        set_property("choiceAdventureScript", "");
        set_property("choiceAdventure1497", "0");
        set_property("choiceAdventure1498", "0");

        string questType = get_property("rufusQuestType");
        if (get_property("questRufus") != "unstarted"
            && $strings[items, artifact] contains questType) {
            item wanted = get_property("rufusQuestTarget").to_item();
            if (wanted == $item[none])
                abort("Rufus: could not identify the current quest item.");
            if (questType == "items" || get_property("questRufus") == "step1"
                || available_amount(wanted) > 0) {
                if (!retrieve_item(questType == "items" ? 3 : 1, wanted))
                    abort("Rufus: could not retrieve the current quest items: " + wanted);
                if (get_property("questRufus") != "step1")
                    visit_url("questlog.php?which=1");
            }
        }

        if (get_property("questRufus") == "step1") {
            visit_url("inv_use.php?whichitem=" + to_int(phone) + "&pwd=" + my_hash());
            if (!handling_choice() || last_choice() != 1498)
                abort("Rufus: expected the quest turn-in choice.");
            run_choice(1);
            if (get_property("questRufus") != "unstarted")
                abort("Rufus: quest turn-in did not finish.");
        }

        // Inventory matters even when yesterday's quest was already turned in.
        int rewardRetries = 0;
        while (item_amount(lodestone) > 0) {
            int stonesBefore = item_amount(lodestone);
            int turnsBefore = total_turns_played();
            // 3 = forest items once per day; 2 = Shadow Waters afterward.
            set_property("choiceAdventure1500",
                (get_property("_shadowForestLooted").to_boolean() || get_property("_teresRufusWatersOnly").to_boolean()) ? "2" : "3");
            if (!adv1(rift))
                abort("Rufus: could not redeem the lodestone.");
            if (total_turns_played() != turnsBefore && get_property("subscript") != "shadowForcers")
                abort("Rufus: lodestone redemption unexpectedly spent a turn.");
            // A different free encounter can interrupt reward redemption.
            // Keep trying while the lodestone is still in inventory.
            if (item_amount(lodestone) < stonesBefore)
                rewardRetries = 0;
            else if (++rewardRetries >= 20)
                abort("Rufus: lodestone still unredeemed after 20 attempts; inspect the encounter.");
        }

        if (startQuest && get_property("questRufus") == "unstarted") {
            visit_url("inv_use.php?whichitem=" + to_int(phone) + "&pwd=" + my_hash());
            if (!handling_choice() || last_choice() != 1497)
                abort("Rufus: expected the quest selection choice.");
            run_choice(1); // Entity quest.
            if (get_property("questRufus") != "started" || get_property("rufusQuestType") != "entity")
                abort("Rufus: entity quest was not accepted.");
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

// Use an existing force first, then tuba, bell, and cinch/free rests.
boolean forceShadowRiftNC() {
    if (get_property("noncombatForcerActive").to_boolean())
        return true;
    if (item_amount($item[Apriling band tuba]) > 0 && available_amount($item[Apriling band helmet]) > 0 && get_property("_aprilBandTubaUses").to_int() < 3) {
        cli_execute("aprilband play tuba");
    } else if (item_amount($item[Clara's bell]) > 0 && !get_property("_claraBellUsed").to_boolean()) {
        use($item[Clara's bell]);
    } else if (available_amount($item[Cincho de Mayo]) > 0) {
        if (get_property("_cinchUsed").to_int() > 40 && available_amount($item[Apriling band helmet]) > 0)
            equip($slot[hat], $item[Apriling band helmet]);
        while (get_property("_cinchUsed").to_int() > 40 && get_property("timesRested").to_int() < total_free_rests()) {
            int restsBefore = get_property("timesRested").to_int();
            if (!cli_execute("camp rest free") || get_property("timesRested").to_int() <= restsBefore)
                abort("Could not recharge cinch with a free rest.");
        }
        if (get_property("_cinchUsed").to_int() <= 40) {
            if (!equip($slot[acc3], $item[Cincho de Mayo]))
                abort("Could not equip Cincho de Mayo.");
            use_skill($skill[Cincho: Fiesta Exit]);
        }
    }
    return get_property("noncombatForcerActive").to_boolean();
}

// Claim the daily membership eyepatch only when a shard phase needs it.
void prepareShardStatLimiter() {
    if (available_amount($item[PirateRealm eyepatch]) == 0)
        visit_url("place.php?whichplace=realm_pirate&action=pr_port");
    if (available_amount($item[PirateRealm eyepatch]) == 0)
        abort("Could not obtain the daily PirateRealm eyepatch.");
    set_property("acc3Override", ", equip PirateRealm eyepatch");
}

// Naturally free fights use the weakling finisher, without spending an FK source.
void prepareShieldStallFight(boolean limitStats){
    foreach pref in $strings[unconditionalOverride, shirtOverride, backOverride, mainOverride, weaponOverride, offOverride, pantsOverride, acc1Override, acc2Override, acc3Override, famEquipOverride]
        set_property(pref, "");
    set_property("script", "FreeKill");
    set_property("inSpendAdv", true);
    set_property("subscript", "weakling");
    mimicPrep();
    if (limitStats)
        prepareShardStatLimiter();
    if (have_effect($effect[Coldform]) == 0
        && (!retrieve_item($item[phial of coldness]) || !use($item[phial of coldness])
            || have_effect($effect[Coldform]) == 0))
        abort("Shield stalling requires Coldform.");
    if (!retrieve_item($item[April Shower Thoughts shield]))
        abort("Shield stalling requires the April Shower Thoughts shield.");
    set_property("offOverride", ", equip April Shower Thoughts shield");
    if (!retrieve_item(1, $item[shard of double-ice]) || !retrieve_item(1, $item[dry noodles]))
        abort("Shield stalling requires a shard of double-ice and dry noodles.");
}

void scientistTentacleFight(){
    if (get_property("_eldritchTentacleFought").to_boolean()
        || get_property("_eldritchTentaclesFoughtToday").to_int() >= 11)
        return;
    string[string] saved;
    foreach pref in $strings[script, subscript, inSpendAdv, maxOverride, famOverride, unconditionalOverride, shirtOverride, backOverride, mainOverride, weaponOverride, offOverride, pantsOverride, acc1Override, acc2Override, acc3Override, famEquipOverride, hpAutoRecovery, hpAutoRecoveryTarget, mpAutoRecovery, mpAutoRecoveryTarget, choiceAdventureScript]
        saved[pref] = get_property(pref);
    int savedAutoAttack = get_auto_attack();
    try {
        set_auto_attack(0);
        set_property("choiceAdventureScript", "");
        prepareShieldStallFight(true);
        main@preadventure();
        if (!have_equipped($item[April Shower Thoughts shield]) || !have_equipped($item[PirateRealm eyepatch]))
            abort("Scientist tentacle: shield and eyepatch must be equipped before combat.");
        int turnsBefore = total_turns_played();
        visit_url("place.php?whichplace=forestvillage&action=fv_scientist");
        if (!handling_choice() || !(available_choice_options() contains 1))
            abort("Scientist tentacle: expected the fight choice.");
        run_choice(1);
        if (current_round() > 0)
            run_combat();
        if (!get_property("_eldritchTentacleFought").to_boolean() || current_round() > 0)
            abort("Scientist tentacle fight did not finish.");
        if (total_turns_played() != turnsBefore)
            abort("Scientist tentacle unexpectedly spent a turn.");
        main@postadventure();
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
        set_auto_attack(savedAutoAttack);
    }
}

// Use one daily candy map, then clear its free block without refreshing it.
void trickOrTreatFreeFights(){
    string block = get_property("_trickOrTreatBlock");
    boolean mapUsed = get_property("_mapToACandyRichBlockUsed").to_boolean();
    if (mapUsed && !contains_text(block, "L") && !contains_text(block, "S") && !contains_text(block, "D"))
        return;
    string[string] saved;
    foreach pref in $strings[script, subscript, inSpendAdv, maxOverride, famOverride, unconditionalOverride, shirtOverride, backOverride, mainOverride, weaponOverride, offOverride, pantsOverride, acc1Override, acc2Override, acc3Override, famEquipOverride, hpAutoRecovery, hpAutoRecoveryTarget, mpAutoRecovery, mpAutoRecoveryTarget, choiceAdventureScript, choiceAdventure804]
        saved[pref] = get_property(pref);
    int savedAutoAttack = get_auto_attack();
    location savedLocation = my_location();
    try {
        set_auto_attack(0);
        set_property("choiceAdventureScript", "");
        set_property("choiceAdventure804", "0");
        // Item/choice fights must not inherit the previous zone's gear hooks.
        set_location($location[none]);
        if (!mapUsed){
            int turnsBefore = total_turns_played();
            // The map opens choice 804. Exit it before preparing either costume.
            set_property("choiceAdventure804", "2");
            if (!retrieve_item(1, $item[map to a candy-rich block])
                || !use(1, $item[map to a candy-rich block]))
                abort("Could not use today's map to a candy-rich block.");
            set_property("choiceAdventure804", "0");
            block = get_property("_trickOrTreatBlock");
            if (!get_property("_mapToACandyRichBlockUsed").to_boolean() || block == "")
                abort("The candy map did not open today's free Trick-or-Treat block.");
            if (total_turns_played() != turnsBefore)
                abort("Opening the daily Trick-or-Treat block unexpectedly spent a turn.");
        }
        if (contains_text(block, "L") || contains_text(block, "S")){
            if (!have_outfit("Ceramic Suit") || !outfit("Ceramic Suit"))
                abort("Trick-or-Treat light houses require the Ceramic Suit outfit.");
            while (contains_text(get_property("_trickOrTreatBlock"), "L")
                || contains_text(get_property("_trickOrTreatBlock"), "S")){
                string before = get_property("_trickOrTreatBlock");
                int turnsBefore = total_turns_played();
                int house = contains_text(before, "S") ? index_of(before, "S") : index_of(before, "L");
                visit_url("place.php?whichplace=town&action=town_trickortreat");
                if (!handling_choice() || last_choice() != 804)
                    abort("Could not open the current Trick-or-Treat block.");
                visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + house);
                if (handling_choice() && last_choice() == 806)
                    run_choice(2); // Take the huge bowl of candy at the star house.
                if (total_turns_played() != turnsBefore)
                    abort("Trick-or-Treat light house unexpectedly spent a turn.");
                if (get_property("_trickOrTreatBlock") == before)
                    abort("Trick-or-Treat light house did not advance the block.");
            }
            if (handling_choice() && last_choice() == 804)
                run_choice(2);
        }
        if (contains_text(get_property("_trickOrTreatBlock"), "D")){
            prepareShieldStallFight(true);
            if (!have_equipped($item[eldritch hat]))
                abort("Trick-or-Treat fights require your fixed eldritch hat for Eldritch Equipage.");
            if (!retrieve_item($item[eldritch pants]))
                abort("Could not obtain the eldritch pants for the Trick-or-Treat costume.");
            set_property("pantsOverride", ", equip eldritch pants");
            while (contains_text(get_property("_trickOrTreatBlock"), "D")){
                string before = get_property("_trickOrTreatBlock");
                int turnsBefore = total_turns_played();
                main@preadventure();
                if (!is_wearing_outfit("Eldritch Equipage"))
                    abort("Trick-or-Treat fights require the Eldritch Equipage costume.");
                candy("fight");
                if (current_round() > 0)
                    abort("Trick-or-Treat combat did not finish.");
                main@postadventure();
                if (total_turns_played() != turnsBefore)
                    abort("Trick-or-Treat dark house unexpectedly spent a turn.");
                if (get_property("_trickOrTreatBlock") == before)
                    abort("Trick-or-Treat fight did not advance the block.");
            }
        }
    } finally {
        if (handling_choice() && last_choice() == 804)
            run_choice(2);
        foreach pref, value in saved
            set_property(pref, value);
        set_location(savedLocation);
        set_auto_attack(savedAutoAttack);
    }
}

// Accept the daily quest, then turn the Party pause NC into a random free combat.
void neverendingPartyFreeFights(){
    if (get_property("_neverendingPartyFreeTurns").to_int() >= 10)
        return;
    location party = $location[The Neverending Party];
    if (!can_adventure(party))
        abort("The Neverending Party is not available.");
    string[string] saved;
    foreach pref in $strings[script, subscript, inSpendAdv, maxOverride, famOverride, unconditionalOverride, shirtOverride, backOverride, mainOverride, weaponOverride, offOverride, pantsOverride, acc1Override, acc2Override, acc3Override, famEquipOverride, hpAutoRecovery, hpAutoRecoveryTarget, mpAutoRecovery, mpAutoRecoveryTarget, choiceAdventureScript, choiceAdventure1322, choiceAdventure1323, choiceAdventure1324]
        saved[pref] = get_property(pref);
    int savedAutoAttack = get_auto_attack();
    try {
        set_auto_attack(0);
        set_property("choiceAdventureScript", "");
        set_property("choiceAdventure1322", 1); // Accept quest.
        set_property("choiceAdventure1323", 1); // Collect an already completed quest reward.
        set_property("choiceAdventure1324", 5); // Fight a random partier.
        prepareShieldStallFight(false);
        if (!retrieve_item($item[PARTY HARD T-shirt]))
            abort("Neverending Party hard quests require the PARTY HARD T-shirt.");
        set_property("shirtOverride", ", equip PARTY HARD T-shirt");
        set_property("maxOverride", get_property("maxOverride") + ", -equip PirateRealm eyepatch");
        int freeInterruptions = 0;
        while (get_property("_neverendingPartyFreeTurns").to_int() < 10){
            int fightsBefore = get_property("_neverendingPartyFreeTurns").to_int();
            int turnsBefore = total_turns_played();
            if (!adv1(party))
                abort("Neverending Party encounter failed.");
            if (total_turns_played() != turnsBefore)
                abort("Neverending Party unexpectedly spent a turn.");
            if (get_property("_neverendingPartyFreeTurns").to_int() > fightsBefore)
                freeInterruptions = 0;
            else if (++freeInterruptions >= 20)
                abort("Neverending Party: 20 encounters without advancing the free-fight counter.");
        }
        print("Neverending Party: all 10 daily free fights are finished.", "blue");
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
        set_auto_attack(savedAutoAttack);
    }
}

// Prepare the shard phases, paid combat-forcer gear, or a due boss's stance.
void prepareShadowRift(string phase, string freeKillMax, boolean bossDue) {
    if (bossDue)
        set_property("subscript","shadowBoss");
    // Keep any offhand override supplied by the selected FK method in its goal.
    if (phase == "freeKills" && !bossDue && get_property("offOverride") != "")
        freeKillMax += get_property("offOverride");
    foreach pref in $strings[shirtOverride, backOverride, mainOverride, offOverride, acc3Override]
        set_property(pref, "");
    mimicPrep();
    if (phase == "freeKills" && !bossDue)
        set_property("maxOverride", freeKillMax);

    if (phase != "forcers") {
        if (!bossDue && have_effect($effect[Coldform]) == 0) {
            if (!retrieve_item($item[phial of coldness]) || !use($item[phial of coldness])
                || have_effect($effect[Coldform]) == 0)
                abort("Shadow Rift: could not obtain Coldform for shard stalling.");
        }
        if (!bossDue) {
            // Keep buffed stats down for the opening burst, as in weakMonsters().
            // Authority needs both Sheriff accessories; leave the third slot for the eyepatch.
            if (phase == "freeKills" && contains_text(freeKillMax, "equip sheriff pistol"))
                set_property("maxOverride", get_property("maxOverride") + ", -equip eternity codpiece");
            else if (!contains_text(get_property("maxOverride"), "eternity codpiece"))
                set_property("maxOverride", get_property("maxOverride") + ", equip eternity codpiece");
            prepareShardStatLimiter();
            if (get_property("_batWingsSwoopUsed").to_int() < 11
                && available_amount($item[bat wings]) > 0)
                set_property("backOverride", ", equip bat wings");
            boolean reservedOffhand = phase == "freeKills" && shadowRiftOffhandReserved(freeKillMax);
            if (!reservedOffhand && shadowRiftNeedsSlash()) {
                if (!retrieve_item($item[McHugeLarge left pole]))
                    abort("Shadow Rift tracking requires the McHugeLarge left pole.");
                if (!retrieve_item(15, $item[waffle]) || item_amount($item[waffle]) < 15)
                    abort("Shadow Rift tracking requires at least 15 waffles.");
                set_property("offOverride", ", equip McHugeLarge left pole");
            } else if (!reservedOffhand) {
                if (!retrieve_item($item[April Shower Thoughts shield]))
                    abort("Shadow Rift Shieldbutt stalling requires the April Shower Thoughts shield.");
                set_property("offOverride", ", equip April Shower Thoughts shield");
            } else if (get_property("teresCombatDebug").to_boolean()) {
                print("Shadow Rift: preserving required FK offhand/weapon gear; shield and Slash tracking are deferred.", "darkorange");
            }
            if (item_amount($item[shard of double-ice]) == 0
                && !retrieve_item($item[shard of double-ice]))
                abort("Shadow Rift: could not acquire a shard of double-ice.");
            if (item_amount($item[waffle]) == 0
                && !retrieve_item(1, $item[waffle]))
                print("Shadow Rift: could not acquire a waffle; Shadow Guys will keep their original loot.", "red");
        }
    } else {
        // This paid phase uses whatever Coldform remains; never renew it here.
        if ($monster[shadow slab].elemental_resistance > 85)
            set_property("acc3Override", ", equip congressional medal of insanity");
        if (!bossDue && !get_property("noncombatForcerActive").to_boolean()){
            skill forcer = shadowRiftCombatForcer();
            if (forcer == $skill[McHugeLarge Avalanche])
                set_property("maxOverride", get_property("maxOverride") + ", equip McHugeLarge left ski");
            else if (forcer == $skill[Launch spikolodon spikes]){
                set_property("maxOverride", get_property("maxOverride") + ", equip Jurassic Parka (spikolodon)");
                set_property("shirtOverride", ", equip Jurassic Parka (spikolodon)");
            }
        }
        if (!bossDue && have_effect($effect[Coldform]) > 0){
            if (!retrieve_item(1, $item[shard of double-ice]))
                abort("Shadow Rift: could not acquire a shard of double-ice.");
            prepareShardStatLimiter();
            if (!shadowRiftOffhandReserved(get_property("maxOverride"))){
                if (!retrieve_item(1, $item[April Shower Thoughts shield]))
                    abort("Shadow Rift Shieldbutt stalling requires the April shield.");
                set_property("offOverride", ", equip April Shower Thoughts shield");
            }
        } else if (!bossDue && !retrieve_item(1, $item[facsimile dictionary])) {
            abort("Shadow Rift: dictionary stalling requires a facsimile dictionary.");
        }
    }

    if (bossDue){
        shadowBoss();
        if (!retrieve_item($item[congressional medal of insanity]))
            abort("Shadow Rift boss requires the congressional medal of insanity.");
        // Require both accessories in the goal; slot overrides can otherwise
        // lose to retained farming accessories such as the devilbone rosary.
        // Bosses now require the medal and exclude the eyepatch; the other two
        // accessories come from ordinary familiar-weight maximization.
        foreach pref in $strings[acc1Override,acc2Override,acc3Override]
            set_property(pref, "");
    }
}

// One encounter, shared by Affinity, free-kill exhaustion, and final NC forces.
// Returns false when Affinity or the final NC forces have run out.
boolean shadowRiftVisit(string phase) {
    location rift = $location[Shadow Rift (The Misspelled Cemetary)];
    string freeKillMax = get_property("maxOverride"); // looseFK() selected resource gear.
    int savedAutoAttack = get_auto_attack();
    string[string] saved;
    foreach pref in $strings[script, subscript, inSpendAdv, maxOverride, famOverride, shirtOverride, backOverride, mainOverride, offOverride, acc1Override, acc2Override, acc3Override, hpAutoRecovery, hpAutoRecoveryTarget, choiceAdventureScript, choiceAdventure1499, shadowLabyrinthGoal]
        saved[pref] = get_property(pref);

    try {
        set_auto_attack(0);
        set_property("script", "FreeKill");
        set_property("inSpendAdv", "true");
        set_property("subscript", phase == "freeKills" ? "looseFK" : phase == "affinity" ? "shadowAffinity" : "shadowForcers");
        set_property("choiceAdventureScript", "");
        set_property("choiceAdventure1499", 1);
        if (get_property("shadowLabyrinthGoal") == "browser" || get_property("shadowLabyrinthGoal") == "")
            set_property("shadowLabyrinthGoal", "effects");
        settleRufusRewards(false);

        if (phase == "affinity") {
            if (have_effect($effect[Shadow Affinity]) == 0
                && !get_property("_shadowAffinityToday").to_boolean()) {
                if (get_property("questRufus") != "unstarted") {
                    print("Rufus: continuing the unfinished " + get_property("rufusQuestTarget")
                        + " quest with free kills; today's Affinity will be claimed after turn-in.", "blue");
                    return false;
                }
                settleRufusRewards(true);
                if (have_effect($effect[Shadow Affinity]) == 0)
                    abort("Rufus: today's quest did not grant Shadow Affinity.");
            }
            if (have_effect($effect[Shadow Affinity]) == 0)
                return false;
        } else {
            if (phase == "forcers" && get_property("questRufus") == "started"
                && get_property("rufusQuestType") != "entity")
                abort("Shadow Rift: free-kill and NC-forcer phases expect an entity quest.");
            if (phase == "forcers" && get_property("encountersUntilSRChoice").to_int() != 0
                && !forceShadowRiftNC() && shadowRiftCombatForcer() == $skill[none])
                return false;
            settleRufusRewards(true);
        }

        // Never spend an FK resource while Affinity can pay for this encounter.
        if (phase == "freeKills" && have_effect($effect[Shadow Affinity]) > 0) {
            phase = "affinity";
            set_property("subscript", "shadowAffinity");
        }
        boolean bossDue = get_property("questRufus") == "started"
            && get_property("rufusQuestType") == "entity"
            && (get_property("encountersUntilSRChoice").to_int() == 0
                || get_property("noncombatForcerActive").to_boolean());
        prepareShadowRift(phase, freeKillMax, bossDue);

        int turnsBefore = total_turns_played();
        boolean adventureSucceeded=adv1(rift);
        boolean fallbackPaidTurn=get_property("_teresFreeKillFallbackTurn")==to_string(turnsBefore)
            &&total_turns_played()==turnsBefore+1&&current_round()==0&&!handling_choice()&&!in_multi_fight();
        if (!adventureSucceeded&&!(fallbackPaidTurn&&get_property("_lastCombatLost").to_boolean()))
            abort("Shadow Rift " + phase + " encounter failed.");
        if (phase != "forcers" && total_turns_played() != turnsBefore){
            if(fallbackPaidTurn)
                print("Shadow Rift: fallback finisher spent one adventure; continuing free kills.","red");
            else
                abort("Shadow Rift " + phase + " unexpectedly spent a turn.");
        }
        settleRufusRewards(false);
        return true;
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
        set_auto_attack(savedAutoAttack);
    }
}

// Consume Affinity before selecting any free-kill resources.
void shadowRiftAffinity() {
    int freeInterruptions = 0;
    while (true) {
        int affinityBefore = have_effect($effect[Shadow Affinity]);
        boolean acquiringAffinity = !get_property("_shadowAffinityToday").to_boolean();
        if (!shadowRiftVisit("affinity")) {
            if (!get_property("_shadowAffinityToday").to_boolean()
                && get_property("questRufus") != "unstarted")
                return;
            break;
        }
        if (acquiringAffinity || have_effect($effect[Shadow Affinity]) < affinityBefore)
            freeInterruptions = 0;
        else if (++freeInterruptions >= 20)
            abort("Affinity Rift: 20 encounters without consuming Affinity; inspect the encounter.");
    }
    print("Shadow Affinity has run out. Moving on.", "green");
}
void augustGolem(){
    if (to_int(get_property("_augSkillsCast")) >= 5
        || get_property("_aug22Cast").to_boolean())
        return;

    string [string] saved;
    foreach pref in $strings[subscript, famOverride, maxOverride, famEquipOverride, unconditionalOverride]
        saved[pref] = get_property(pref);
    try {
        prepareDailyShardCombat();
        // Use the normal Stocking Mimic stance, even after a different farming phase.
        set_property("subscript", "");
        set_property("famEquipOverride", "");
        set_property("unconditionalOverride", "");
        mimicPrep();
        if(my_familiar() != $familiar[stocking mimic])
            use_familiar($familiar[stocking mimic]);
        main@preadventure();
        cli_execute("cast Aug. 22");
        main@postadventure();
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

// Aftercore Bowling Alley farming: banish bowlers/orderlies and finish the daily free fights.
void restOfHiddenCity(){
    if (get_property("_drunkPygmyBanishes").to_int() >= 11)
        return;
    if (!can_adventure($location[The Hidden Bowling Alley]))
        abort("The Hidden Bowling Alley is not available.");
    int bowlsNeeded = max(0, 11 - get_property("_drunkPygmyBanishes").to_int());
    if (bowlsNeeded > 0 && !retrieve_item(bowlsNeeded, $item[bowl of scorpions]))
        abort("Could not acquire " + bowlsNeeded + " bowls of scorpions.");

    // Prefer these ingredients, but only banish readiness is required.
    string latteIngredients = "cajun,vitamins,rawhide";   // +40% meat, +3 fam xp, +5 fam lb
    string unlocks = get_property("latteUnlocks");
    string lockedIngredients = "";
    foreach ingredient in $strings[cajun, vitamins, rawhide] {
        if (!contains_text("," + unlocks + ",", "," + ingredient + ","))
            lockedIngredients += (lockedIngredients == "" ? "" : ", ") + ingredient;
    }
    if (lockedIngredients != "")
        print("Bowling Alley: you should UNLOCK these LATTE INGREDIENTS if possible: " + lockedIngredients + ".", "red");
    if ((get_property("latteIngredients") != latteIngredients
        || get_property("_latteBanishUsed").to_boolean())
        && get_property("_latteRefillsUsed").to_int() < 3) {
        // Cinnamon, pumpkin and vanilla are always unlocked; retain any available preferred ingredients.
        string refillIngredients = (contains_text(unlocks, "cajun") ? "cajun" : "cinnamon")
            + " " + (contains_text(unlocks, "vitamins") ? "vitamins" : "pumpkin")
            + " " + (contains_text(unlocks, "rawhide") ? "rawhide" : "vanilla");
        // Spend a refill for the preferred mix or to recharge a used banish.
        if (refillIngredients == "cajun vitamins rawhide" || get_property("_latteBanishUsed").to_boolean()) {
            if (!cli_execute("latte refill " + refillIngredients))
                print("Bowling Alley: latte refill failed.", "red");
        }
    }
    if (lockedIngredients == "" && get_property("latteIngredients") != latteIngredients)
        print("Bowling Alley: Could not get the right LATTE INGREDIENTS for some reason... Whatever.", "red");

    // preadventure applies familiar experience buffs and checks the equipped banish.

    string [string] saved;
    foreach pref in $strings[subscript, maxOverride, famOverride, famEquipOverride, unconditionalOverride]
        saved[pref] = get_property(pref);
    try {
        set_property("subscript", "drunkPygmy");
        set_property("famOverride", "");
        set_property("famEquipOverride", "");
        set_property("unconditionalOverride", "");
        while (get_property("_drunkPygmyBanishes").to_int() < 11){
            if (!contains_text(get_property("banishedMonsters"), "pygmy bowler")
                && !retrieve_item(1, $item[stuffed yam stinkbomb]))
                abort("Could not acquire a stuffed yam stinkbomb for the pygmy bowler.");
            string bowlingMaximize = "familiar experience, equip latte lovers member's mug, -equip bat wings";
            if (!contains_text(get_property("banishedMonsters"), "pygmy orderlies")
                && get_property("_latteBanishUsed").to_boolean()) {
                item ring = $item[mafia middle finger ring];
                if (get_property("_mafiaMiddleFingerRingUsed").to_boolean()
                    || available_amount(ring) == 0 || !retrieve_item(1, ring))
                    abort("Bowling Alley: neither the latte nor an unused mafia middle finger ring banish is available.");
                bowlingMaximize += ", equip mafia middle finger ring";
            }
            set_property("maxOverride", bowlingMaximize);
            if (item_amount($item[bowling ball]) > 0
                && !put_closet(item_amount($item[bowling ball]), $item[bowling ball]))
                abort("Could not closet bowling balls.");
            // Banishes and wanderers do not count toward the 11 drunk-pygmy fights.
            if (!adv1($location[The Hidden Bowling Alley]))
                abort("Bowling Alley adventure failed before reaching 11 drunk-pygmy fights.");
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

// Strictly for fam XP as familiar actions are blocks - similar to hidden city instant free fights
void godLobsterFights(){
    if (get_property("_godLobsterFights").to_int() >= 3)
        return;
    string [string] saved;
    foreach pref in $strings[subscript, maxOverride, famOverride, famEquipOverride, unconditionalOverride]
        saved[pref] = get_property(pref);
    try {
        setClan("stash");
        set_property("subscript", "godLobster");
        set_property("famOverride", "");
        set_property("famEquipOverride", "");
        set_property("unconditionalOverride", "");
        // Let the maximizer value the latte's current ingredients along with other XP gear.
        set_property("maxOverride", "familiar experience");
        while (get_property("_godLobsterFights").to_int() < 3){
            // Using a combat item runs preadventure, including familiar selection and gear.
            if (!use($item[dish of clarified butter]))
                abort("Could not complete a God Lobster fight.");
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

int valueOfOrgan(string organ){
    if (organ == "stomach"){
        //based off of baked veggie ricotta casserole
//not sure this is correct
        return (8*get_property("valueOfAdventure").to_int()) - mall_price($item[baked veggie ricotta casserole]);
    } else if (organ == "liver"){
        //based off of  Sacramento wine
        return (5.5*get_property("valueOfAdventure").to_int()) - mall_price($item[Sacramento wine]);
    } else if (organ == "spleen"){
        //based off of synthesis greed
        return 30*300*3 - (mall_price($item[Crimbo candied pecan])*2);
    } else {
        abort("invalid organ");
    }
    return 0;
}

int valueOfFamPot(item it) {
    int n;
    if (it == $item[Black and White Apron Meal Kit]){
        n = (10*27*freeKillCount() + (12 * get_property("valueOfAdventure").to_int()))/3 - mall_price(it);
    } else {
        n = (numeric_modifier(itemEffectNotes(it).ef,"familiar weight")*27*freeKillCount() + (averageAdventures(it) * get_property("valueOfAdventure").to_int()))/organSpace(it) - mall_price(it);
    }
    return n;
}

void cyberzone() {
    // Return to Stocking Mimic and replace the Bakery runaway shoes with farming gear.
    mimicPrep(", -equip spring shoes");
    while (to_int(get_property("_cyberFreeFights")) < 10) {
        location [monster] hackerZone = {
            to_monster(get_property("_cyberZone1Hacker")): $location[cyberzone 1],
            to_monster(get_property("_cyberZone2Hacker")): $location[cyberzone 2],
            to_monster(get_property("_cyberZone3Hacker")): $location[cyberzone 3]
        };
        if (!contains_text(get_property("banishedPhyla"), "construct")) {
            set_property("hpAutoRecoveryTarget","0.25");
            cli_execute("recover hp");
            foreach mon in $monsters[greyhat hacker,greenhat hacker,redhat hacker,purplehat hacker,bluehat hacker] {
                if (hackerZone contains mon && hackerZone[mon] != $location[cyberzone 1]) {
                    adv1(hackerZone[mon], 0, "");
                    break;
                }
            }
            continue;
        }
        // Adventure in whichever zone has the target hacker
        foreach mon in $monsters[greyhat hacker,greenhat hacker,redhat hacker,purplehat hacker] {
            if (hackerZone contains mon) {
                if (contains_text(get_property("banishedMonsters"), mon + ":Sea *dent") && get_property("_cyberFreeFights").to_int() < 10){
                    set_property("mainOverride",", equip monodent");
                    set_property("battleAction","skill sea *dent: throw a lightning bolt");
                    adv1($location[The spooky forest]);
                    return;
                } else {
                    set_property("mainOverride","");
                    set_property("battleAction","custom combat script");
                }
                adv1(hackerZone[mon], 0, "");
                break;
            }
        }
    }
}

// Final phase: use the remaining NC forces for boss quests; leave Coldform as-is.
int shadowWatersExpectedTurns(){
    int manual=get_property("teresBarfExpectedAdventures").to_int();
    if(manual>0){print("Shadow Waters: using manually configured "+manual+" BARF turns.","blue");return manual;}
    int projected=barfDietProjectedPaidTurns();
    if(projected>0){print("Shadow Waters: first complete diet projects "+projected+" paid BARF encounters.","blue");return projected;}
    // If the exact schedule cannot be completed at this point, bank against a
    // conservative current-state estimate so the remaining free kills continue.
    int reserve=max(0,200-barfDietNightcapMinimum()-barfSetting("RolloverGain",145)-barfSetting("ClanRolloverGain",0));
    int estimate=max(0,my_adventures()-reserve)
        +max(0,17-my_fullness())*18+max(0,21-my_inebriety())*7+max(0,17-my_spleen_use())*3+100;
    print("Shadow Waters: no complete diet projection; using a conservative "+estimate+"-turn current-state estimate. Set teresBarfExpectedAdventures to override it.","red");
    return estimate;
}
void bankShadowWaters(){
    int expected = shadowWatersExpectedTurns();
    int target = expected + 30;
    string[string] saved;
    foreach pref in $strings[choiceAdventureScript, choiceAdventure1497, choiceAdventure1498, _teresRufusWatersOnly]
        saved[pref] = get_property(pref);
    try {
        set_property("choiceAdventureScript", "");
        set_property("choiceAdventure1497", 0);
        set_property("choiceAdventure1498", 0);
        set_property("_teresRufusWatersOnly", true);
        settleRufusRewards(false);
        if (get_property("questRufus") != "unstarted")
            abort("Shadow Waters: finish the existing Rufus quest before banking item quests.");
        while (have_effect($effect[Shadow Waters]) < target){
            visit_url("inv_use.php?whichitem=" + to_int($item[closed-circuit pay phone]) + "&pwd=" + my_hash());
            if (!handling_choice() || last_choice() != 1497) abort("Shadow Waters: expected Calling Rufus.");
            item wanted = get_property("rufusDesiredItems").to_item();
            if (wanted == $item[none]) abort("Shadow Waters: Rufus's requested items were not identified.");
            run_choice(3);
            if (!retrieve_item(3, wanted)) abort("Shadow Waters: could not acquire three " + wanted + ".");
            if (get_property("questRufus") != "step1"){
                visit_url("questlog.php?which=1");
                if (get_property("questRufus") != "step1") abort("Shadow Waters: item quest is not ready to turn in.");
            }
            int before = have_effect($effect[Shadow Waters]);
            settleRufusRewards(false);
            if (have_effect($effect[Shadow Waters]) <= before) abort("Shadow Waters reward did not increase coverage.");
        }
        if (get_property("questRufus") != "unstarted") abort("Shadow Waters ended with an unfinished quest.");
        print("Shadow Waters banked: " + have_effect($effect[Shadow Waters])
            + " turns for " + expected + " projected adventures plus one extra reward.", "blue");
    } finally { foreach pref, value in saved set_property(pref, value); }
}

void shadowRiftForcers() {
    if (have_effect($effect[Shadow Affinity]) > 0)
        abort("Use shadowRiftAffinity() to finish Affinity before spending NC forces.");
    string[string] savedGear;
    foreach pref in $strings[_teresForcerGearCacheActive,_teresForcerParkaMode,_teresGearBaselineKey,_teresGearBaselineOutfit]
        savedGear[pref]=get_property(pref);
    try {
        clearPreAdvGearCache();
        set_property("_teresForcerGearCacheActive",true);
        int interruptions = 0;
        while (true){
            int combatsBefore = get_property("_shadowRiftCombats").to_int();
            int avalancheBefore = get_property("_mcHugeLargeAvalancheUses").to_int();
            int spikesBefore = get_property("_spikolodonSpikeUses").to_int();
            int clockBefore = get_property("encountersUntilSRChoice").to_int();
            boolean forceBefore = get_property("noncombatForcerActive").to_boolean();
            string questBefore = get_property("questRufus");
            if (!shadowRiftVisit("forcers"))
                break;
            if (get_property("_shadowRiftCombats").to_int() != combatsBefore
                || get_property("_mcHugeLargeAvalancheUses").to_int() != avalancheBefore
                || get_property("_spikolodonSpikeUses").to_int() != spikesBefore
                || get_property("encountersUntilSRChoice").to_int() != clockBefore
                || get_property("noncombatForcerActive").to_boolean() != forceBefore
                || get_property("questRufus") != questBefore)
                interruptions = 0;
            else if (++interruptions >= 20)
                abort("Shadow Rift forcers: 20 encounters without progress; inspect the encounter.");
        }
        bankShadowWaters();
    } finally {
        foreach pref,value in savedGear set_property(pref,value);
    }
}

void sandworm(){
    if (!have_familiar($familiar[Jumpsuited Hound Dog]))
        abort("Sandworm fights require the Jumpsuited Hound Dog.");
    string [string] saved;
    foreach pref in $strings[famOverride, famEquipOverride, maxOverride]
        saved[pref] = get_property(pref);
    try {
        mimicPrep();
        // Use fairy drops for spice melange, with the coin's extra familiar weight.
        set_property("famOverride", "Jumpsuited Hound Dog");
        set_property("famEquipOverride", ", equip amulet coin");
        while (get_property("_aprilBandTomUses").to_int() < 3
            && available_amount($item[Apriling band quad tom]) > 0){
            main@preadventure( );
            cli_execute("aprilband play quad tom");
            run_combat();
            main@postadventure( );
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

void archaeologist(){
    if (have_item($item[Archaeologist's Spade]) && to_int(get_property("_archSpadeDigs")) < 11 && can_adventure($location[The Red Zeppelin])){
        if (my_location() != $location[the red zeppelin]){
            set_property("mainOverride","");
            if (to_int(get_property("_glarkCableUses")) < 5) {
                if (!retrieve_item(5 - get_property("_glarkCableUses").to_int(), $item[glark cable]))
                    abort("Could not acquire glark cables before entering the Red Zeppelin.");
                adv1($location[the red zeppelin]);
            } else
                abort("Ran out of glarks to charge spade");
        }
        main@preadventure( );
        use($item[Archaeologist's Spade]);
        main@postadventure( );
    }
}

void MobiusMaybe(){
    if (get_property("_timeCopsFoughtToday").to_int() < 10)
        set_property("acc2Override",", equip mobius ring");
}
// Retained for possible future use; monster safety checks do not strip stat buffs.
/*
void uneffectBuff(){
    stat st = $stat[muscle];
    foreach sta in $stats[mysticality, moxie]
        if (my_buffedstat(sta) > my_buffedstat(st))
            st = sta;

    float effectiveBase = my_basestat(st);
    float statLimit = numeric_modifier(to_string(st) + " Limit");
    if (statLimit > 0)
        effectiveBase = min(effectiveBase, statLimit);

    effect toRemove = $effect[none];
    float statBuff = 0;
    foreach ef in my_effects(){
        // Preserve farming, familiar-weight and pickpocket buffs.
        if (numeric_modifier(ef, "Item Drop") != 0
                || numeric_modifier(ef, "Meat Drop") != 0
                || numeric_modifier(ef, "Familiar Weight") != 0
                || numeric_modifier(ef, "Pickpocket Chance") != 0)
            continue;
        float contribution = numeric_modifier(ef, to_string(st))
            + numeric_modifier(ef, to_string(st) + " Percent") * effectiveBase / 100;
        if (contribution > statBuff){
            statBuff = contribution;
            toRemove = ef;
        }
    }
    if (toRemove != $effect[none])
        cli_execute("uneffect " + toRemove);
}
*/

boolean looseFK(){
    set_property("maxOverride","familiar weight, equip eternity codpiece");
    // Prefer Sweat Bullets when affordable; flag an early stop before 9 casts.
    if (sweatBulletsReady(714025)){
        print ("FK is sweat");
        return true;
    }
    if (get_property("_gingerbreadMobHitUsed") == "false"){
        print ("FK is gingerbread");
        return true;
    }
    if (get_property("_shatteringPunchUsed").to_int() < 3){
        print ("FK is shattering");
        return true;
    }
    if (have_effect($effect[everything looks red]) == 0){
        set_property("maxOverride","familiar weight, equip everfull dart holster");
        print ("FK is bullseye");
        return true;
    }
    if (have_effect($effect[everything looks yellow]) == 0){
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip jurassic parka (dilophosaur)");
        print ("FK is jurassic acid");
        return true;
    }
    if (get_property("_firedJokestersGun") == false){
        print ("FK is jokester's gun");
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip jokester's gun");
        return true;
    }
    if (get_property("_assertYourAuthorityCast").to_int() < 3){
        print ("FK is assert");
        set_property("maxOverride","familiar weight, equip sheriff pistol, equip sheriff moustache, equip sheriff badge");
        return true;
    }
    if (get_property("_clubEmTimeUsed").to_int() < 5){
        print ("FK is club em back in time");
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip legendary seal-clubbing");
        return true;
    }
    if (item_amount($item[interesting coin]) > 0 && get_property("_interestingCoinHeads") == "false"){
        print("fk is interesting coin");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        return true;
    }
    if (get_property("_shadowBricksUsed").to_int() < 13){
        print ("FK is shadow brick");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        int n = 13 - get_property("_shadowBricksUsed").to_int();
        retrieve_item(n,$item[shadow brick]);
        return true;
    }
    // eventually add partial tombstone
    return false;
}


// Run the shared shard setup after weak monsters: Affinity first, then FK resources.
void shadowRiftFreeKills() {
    string savedSubscript = get_property("subscript");
    int interruptions = 0;
    boolean explainedPendingQuest = false;
    string baseballTeamAttempted = "not a lineup";
    try {
        while (true) {
            set_property("subscript", have_effect($effect[Shadow Affinity]) > 0 ? "shadowAffinity" : "looseFK");
            settleRufusRewards(false);
            if (have_effect($effect[Shadow Affinity]) > 0
                || (!get_property("_shadowAffinityToday").to_boolean()
                    && get_property("questRufus") == "unstarted")) {
                shadowRiftAffinity();
                continue;
            }

            boolean pendingQuest = get_property("questRufus") == "started";
            if (pendingQuest && !($strings[entity, artifact] contains get_property("rufusQuestType")))
                abort("Rufus: the current quest could not be completed; inspect its requested items.");
            if (pendingQuest && !get_property("_shadowAffinityToday").to_boolean() && !explainedPendingQuest) {
                print("Rufus: finishing the existing " + get_property("rufusQuestTarget")
                    + " quest before claiming today's Affinity; "
                    + get_property("encountersUntilSRChoice") + " combats until its quest encounter.", "blue");
                explainedPendingQuest = true;
            }

            // Due bosses and artifact choices do not need another free-kill source.
            boolean questEncounterDue = pendingQuest
                && (get_property("encountersUntilSRChoice").to_int() == 0
                    || get_property("noncombatForcerActive").to_boolean());
            if (!questEncounterDue && !looseFK()) {
                if (pendingQuest && !get_property("_shadowAffinityToday").to_boolean())
                    print("Rufus: no free-kill sources remain to finish this quest. Leaving it pending without spending adventures.", "red");
                break;
            }
            if (!questEncounterDue && baseballPlayers() == 9 && get_property("_curveballFightsLeft").to_int() == 0
                && get_property("_baseballInnings").to_int() < 3
                && get_property("baseballTeam") != baseballTeamAttempted) {
                baseballTeamAttempted = get_property("baseballTeam");
                baseballD();
                // Baseball can consume the last FK or change its required outfit.
                continue;
            }
            if (questEncounterDue)
                set_property("maxOverride", "familiar weight, equip eternity codpiece");
            int combatsBefore = get_property("_shadowRiftCombats").to_int();
            int clockBefore = get_property("encountersUntilSRChoice").to_int();
            string questBefore = get_property("questRufus");
            set_property("subscript", "looseFK");
            shadowRiftVisit("freeKills");
            if (get_property("_shadowRiftCombats").to_int() != combatsBefore
                || get_property("encountersUntilSRChoice").to_int() != clockBefore
                || get_property("questRufus") != questBefore)
                interruptions = 0;
            else if (++interruptions >= 20)
                abort("Shadow Rift free kills: 20 encounters without quest/combat progress; inspect the encounter.");
        }
    } finally {
        set_property("subscript", savedSubscript);
    }
}

void resCheck(string str){
    if (numeric_modifier(pearls[str].ele_res) < 18)
        cli_execute("gain 18 " + pearls[str].ele_res);
    if (numeric_modifier(pearls[str].ele_res) < 18)
        abort(pearls[str].ele_res + " is below 18");
}

void underwaterBaseball(){
    mimicPrep(", equip eternity codpiece");
    resCheck("bar");
    if (get_property("_curveballFightsLeft").to_int() == 0 && looseFK()){
        set_property("subscript","looseFK");
        adv1($location[The Dive Bar]);
        baseballD();
    } else if (get_property("_curveballFightsLeft").to_int() > 0){
        set_property("acc1Override",", equip congressional medal of insanity");
        adv1($location[The Dive Bar]);
        set_property("acc1Override","");
    }
}

void gingerbread(){
    if (get_property("gingerbreadCityAvailable") == "false"){
        if (get_property("_gingerbreadCityToday") == "false")
            use($item[counterfeit city]);
    }
    // Shared preadventure preparation covers every Gingerbread City zone.
    if (get_property("_gingerbreadCityTurns").to_int() < 30){
        mimicPrep();
        // Resume a pending midnight visit if an earlier run was interrupted.
        adv1(get_property("_teresGingerbreadMidnightPending").to_boolean()
            ? $location[Gingerbread Civic Center] : $location[Gingerbread Upscale Retail District]);
        set_property("_teresGingerbreadMidnightPending", contains_text(LastAdvTxt(), "almost midnight"));
    }
    if (get_property("_gingerbreadCityTurns").to_int() < 30
        && get_property("_teresGingerbreadMidnightPending").to_boolean()){
        adv1($location[Gingerbread Civic Center]);
        set_property("_teresGingerbreadMidnightPending", false);
    }
    if (get_property("_gingerbreadCityTurns").to_int() >= 30)
        set_property("_teresGingerbreadMidnightPending", false);
    cleanupGingerbreadAdventure();
}

// NEED TO FIX THIS
void habitatRecall(){
    if (!have_skill($skill[Recall Facts: Monster Habitats])) return;
    if (get_property("_monsterHabitatsRecalled").to_int() >= 3
        && get_property("_monsterHabitatsFightsLeft").to_int() == 0) return;
    if (get_property("_monsterHabitatsFightsLeft").to_int() > 0
        && get_property("_monsterHabitatsMonster").to_monster() != $monster[sausage goblin])
        abort("Habitat Recall is already active for another monster; finish that chain first.");
    string[string] saved;
    foreach pref in $strings[subscript, famOverride, maxOverride, acc3Override, offOverride, mainOverride, famEquipOverride]
        saved[pref] = get_property(pref);
    try {
        prepareDailyShardCombat();
        if (!is_banished($monster[fluffy bunny])){
            if (!retrieve_item(1, $item[stuffed yam stinkbomb])) abort("Habitat chain needs a bunny banish.");
            set_property("subscript", "habitatBunny");
            set_property("famOverride", "Patriotic Eagle");
            set_property("maxOverride", "familiar weight, -equip legendary seal-clubbing club");
            int attempts = 0;
            while (!is_banished($monster[fluffy bunny])){
                if (++attempts > 20) abort("Dire Warren bunny banish was interrupted 20 times; inspect the encounter.");
                if (!adv1($location[The Dire Warren])) abort("Could not banish the Dire Warren bunny.");
            }
        }
        set_property("subscript", "habitatRecall");
        mimicPrep(", -equip legendary seal-clubbing club");
        prepareShardStatLimiter();
        set_property("offOverride", ", equip April Shower Thoughts shield");
        if (!retrieve_item(1, $item[April Shower Thoughts shield])) abort("Habitat chain needs the April shield.");
        if (get_property("_monsterHabitatsFightsLeft").to_int() == 0){
            main@preadventure();
            if (item_amount($item[mimic egg]) > 1) cli_execute("c2t_megg fight sausage goblin");
            else if (locketAvailable() > 0) cli_execute("reminisce sausage goblin");
            else abort("Habitat chain needs a goblin seed; the last mimic egg is reserved for BARF.");
            int chained = 0;
            while (current_round() > 0 || in_multi_fight()){
                if (++chained > 20) abort("Habitat seed did not finish its chained fights.");
                run_combat();
            }
            main@postadventure();
            if (get_property("_monsterHabitatsFightsLeft").to_int() == 0)
                abort("Habitat Recall did not seed the goblin chain.");
        }
        int interruptions = 0;
        while (get_property("_monsterHabitatsFightsLeft").to_int() > 0){
            prepareDailyShardCombat();
            int before = get_property("_monsterHabitatsFightsLeft").to_int();
            int casts = get_property("_monsterHabitatsRecalled").to_int();
            if (!adv1($location[The Dire Warren])) abort("Habitat chain adventure failed.");
            if (before == get_property("_monsterHabitatsFightsLeft").to_int()
                && casts == get_property("_monsterHabitatsRecalled").to_int()){
                if (++interruptions >= 20) abort("Habitat chain made no progress for 20 encounters; inspect the encounter.");
            } else interruptions = 0;
        }
    } finally { foreach pref, value in saved set_property(pref, value); }
}

/* Previous Habitat implementation, retained for reference.
void habitatRecall(){
    while (to_int(get_property("_monsterHabitatsRecalled")) < 3 || to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
        if (to_int(get_property("_monsterHabitatsFightsLeft")) == 0 && to_int(get_property("_monsterHabitatsRecalled")) < 3){
            mimicPrep();
            main@preadventure();
            cli_execute("reminisce sausage goblin");
            main@postadventure();
        }
        while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
            mimicPrep();
            MobiusMaybe();
            if (get_auto_attack() == 0)
                aa("facsimile");
        }
        set_property("offOverride","");
        set_property("acc2Override","");
    }
}

*/

void mimicEgg(){
    int reserve = have_skill($skill[Recall Facts: Monster Habitats])
        && get_property("_monsterHabitatsRecalled").to_int() < 3
        && get_property("_monsterHabitatsFightsLeft").to_int() == 0 ? 2 : 1;
    while (item_amount($item[mimic egg]) > reserve){
        int eggsBefore = item_amount($item[mimic egg]);
        purpleCandlePrep();
        cli_execute("c2t_megg fight sausage goblin");
        if (current_round() > 0)
            run_combat();
        if (item_amount($item[mimic egg]) >= eggsBefore){
            print("Could not consume a sausage-goblin mimic egg; stopping the egg loop.", "red");
            return;
        }
        cli_execute("postadventure");
    }
}
boolean faxing(){
    if (get_property("_photocopyUsed") == false){
        setClan("VIP");
        visit_url("clan_viplounge.php?action=faxmachine&whichfloor=2");
        visit_url("clan_viplounge.php?preaction=receivefax&whichfloor=2");
        setClan("stash");
        if (item_amount($item[photocopied monster]) > 0 && get_property("photocopyMonster").to_monster() == $monster[sausage goblin]){
            purpleCandlePrep();
            use($item[photocopied monster]);
            return true;
        }
    }
    return false;
}
// Use all available sausage-goblin copies, then continue the daily routine.
void copyMonsters(){
    if (item_amount($item[mimic egg]) > 0){
        step("phase: copied monsters - mimic eggs");
        mimicEgg();
    }
    if (!get_property("_photocopyUsed").to_boolean()){
        step("phase: copied monster - fax");
        faxing();
    }
    if (item_amount($item[shaking 4-D camera]) > 0 && get_property("cameraMonster").to_monster() == $monster[sausage goblin]){
        purpleCandlePrep();
        use($item[shaking 4-D camera]);
    }
    if (item_amount($item[envyfish egg]) > 0 && get_property("envyfishMonster").to_monster() == $monster[sausage goblin]){
        purpleCandlePrep();
        use($item[envyfish egg]);
    }
}

// += 1 for every active effect that deals automatic per-round damage (mafia's
// "Damage Aura" / "Sporadic Damage Aura" modifiers -- Cowrruption, Boxing Day
// Glow, Spiky Hair, Simmering, Frostbeard, and so on). fightPicker() adds this
// to the double-ice estimate so chip damage doesn't kill a weak monster before
// the free kill lands.
int passiveDamage(){
    return icedChipDamage();
}

// -- HP-headroom math for fightPicker() ----------------------------------------
// The double-ice build chips every monster each round (coldform proc plus the
// passive-damage auras counted by passiveDamage()). If that chip damage kills a
// weakling before the free kill lands, the free kill is wasted -- so fightPicker()
// only hands back a monster whose HP clears the relevant target below, buffing
// Monster Level to pad the monster's HP when it doesn't.

int estimatedIceDamage(monster m){
    return estimatedShardOpeningDamage(m);
}
// lowHPTarget: chip damage across a fast (~9-round) free kill.
// highHPTarget: HP threshold for longer Shieldbutt farming with the April shield.
int lowHPTarget(monster m) {    return (9 * passiveDamage()) + estimatedIceDamage(m);
}
int highHPTarget(monster m) {
    return (23 * passiveDamage()) + estimatedIceDamage(m);
}

boolean buffML(monster m){
    setClan("stash");
    int currentML = numeric_modifier("Monster level");
    int targetML = currentML + (lowHPTarget(m)-m.base_hp);
    //Monster level. Needs reconsidering to work with weakMonsters()
    // Lapdog is handled during FKPrep in the VIP clan; do not retry the pool here.
    string [int] mlEffects = {"Ur-Kel's Aria of Annoyance", "Pride of the Puffin", "Bloodbathed", "Misplaced Rage", "Manbait", "Sweetbreads Flamb&eacute;", "Red Lettered", "Spangled Star", "Tortious", "Litterbug", "Not Sharing", "Para-lyzed Jaw", "Contemptible Emanations", "Ashen Burps", "Gelded", "Mysteriously Handsome", "Eau D'enmity", "Mediocri Tea", "Patent Sallowness", "Yoloswagyoloswag"};
    foreach i, effectName in mlEffects {
        effect ef = to_effect(effectName);
        targetML = currentML + (lowHPTarget(m)-m.base_hp) + 100; //padding this with extra ML cause im slaughtering too hard
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (numeric_modifier("Monster level") >= targetML)
            break;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    if (numeric_modifier("Monster level") < targetML)
        change_mcd(10);
    if (numeric_modifier("Monster level") >= targetML)
        return true;
    else
        return false;
}
// Can monster m be free-killed right now without chip damage killing it first?
// Selects the April shield for Shieldbutt effect farming when the monster has
// HP to spare, and buffs ML to pad it when it's too fragile;
// returns false only when even a maxed ML can't make it safe -- the caller then
// skips the fight. A $monster[none] (name lookup missed) is skipped.
boolean safeToFK(monster m){
    print(m + " HP will be " + m.base_hp);
    print("Icicle damage is " + estimatedIceDamage(m));
    print ("Monster HP must be above " + lowHPTarget(m));
    print ("Shieldbutt farming is preferred above " + highHPTarget(m) + " monster HP");
    set_property("offOverride","");
    if (m == $monster[none])
        return false;
    if (m.base_hp <= lowHPTarget(m))
        buffML(m);
    // Recheck after ML changes; safety checks never strip stat buffs.
    if (m.base_hp > highHPTarget(m))
        set_property("offOverride",", equip april shower thoughts shield");
    return m.base_hp > lowHPTarget(m);
}

// The single protonic ghost that haunts each almost-dead walkie-talkie zone, so
// the ghost fight can be run through safeToFK() like the rest. Ordered as on the
// Protonic accelerator pack wiki page; $monster[none] for an unrecognised zone.
monster ghostFor(location loc){
    monster [location] ghost = {
        $location[The Spooky Forest]:         $monster[The Headless Horseman],
        $location[The Haunted Kitchen]:       $monster[The Icewoman],
        $location[Cobb's Knob Treasury]:      $monster[The ghost of Ebenoozer Screege],
        $location[The Haunted Conservatory]:  $monster[The ghost of Lord Montague Spookyraven],
        $location[The Old Landfill]:          to_monster("the ghost of Vanillica \"Trashblossom\" Gorton"),
        $location[The Smut Orc Logging Camp]: $monster[The ghost of Richard Cockingham],
        $location[The Haunted Gallery]:       $monster[The ghost of Waldo the Carpathian],
        $location[The Haunted Wine Cellar]:   $monster[The ghost of Jim Unfortunato],
        $location[The Overgrown Lot]:         $monster[the ghost of Oily McBindle],
        $location[The Skeleton Store]:        $monster[boneless blobghost],
        $location[Madness Bakery]:            $monster[the ghost of Monsieur Baguelle],
        $location[Inside the Palindome]:      to_monster("Emily Koops, a spooky lime"),
        $location[The Icy Peak]:              $monster[the ghost of Sam McGee]
    };
    if (ghost contains loc)
        return ghost[loc];
    return $monster[none];
}

// Make sure a walkie-talkie ghost report is live (forcing one with the item if
// the pack's own timer is up but nothing's pending yet) and return its zone.
// $location[none] if we can't get a report. Guarded on questPAGhost so the item
// is only ever burned once per report.
location walkieGhost(){
    if (get_property("questPAGhost") == "unstarted" && !have_item($item[protonic accelerator pack])){
        retrieve_item($item[almost-dead walkie-talkie]);
        use($item[almost-dead walkie-talkie]);
    }
    if (get_property("ghostLocation") != "")
        return to_location(get_property("ghostLocation"));
    return $location[none];
}

// Ordered weakling candidates. Returns the first still-outstanding fight, or "done".
// checkHP applies safeToFK() -- available AND chip-safe (buffML'ing when it can),
// skipping any that can't be made safe. checkHP == false is the "delay is used
// up" pass: availability only, HP be damned, just finish the free kills. The
// item-summon fights look their representative monster up by name -- fix the
// strings if a lookup misses.
string pickWeakling(boolean checkHP){
    if (!checkHP)
        set_property("offOverride","");
    if (to_int(get_property("_lynyrdSnareUses")) < 3
        && (!checkHP || safeToFK(to_monster("Lynyrd"))))
        return "lynyrd";
    if (to_int(get_property("_brickoFights")) < 10
        && (!checkHP || safeToFK($monster[BRICKO ooze])))
        return "BRICKO";
    if ((get_property("questPAGhost") == "started" || (get_property("questPAGhost") == "unstarted"
        && total_turns_played() >= to_int(get_property("nextParanormalActivity")) && get_property("ghostLocation") != ""))
        && (!checkHP || safeToFK(ghostFor(walkieGhost()))))
        return "ghost";
    if (get_property("_tiedUpFlamingLeafletFought") == "false"
        && (!checkHP || safeToFK($monster[flaming leaflet])))
        return "leaflet";
    if (to_int(get_property("_leafMonstersFought")) < 5
        && (!checkHP || safeToFK($monster[flaming monstera])))
        return "monstera";
    // Last normal pick; Gingerbread remains fightPicker()'s fallback.
    if ((to_int(get_property("_glarkCableUses")) < 5
            || (have_item($item[Archaeologist's Spade]) && to_int(get_property("_archSpadeDigs")) < 11))
        && can_adventure($location[The Red Zeppelin])
        && (!checkHP || safeToFK(to_monster("Red Snapper"))))
        return "zeppelin";
    return "done";
}

// Three-tier pick:
//  1. the ordered weaklings, full criteria (available + chip-safe, buffML if needed)
//  2. nothing safe -> burn delay turns on gingerbread, then pearl P1, and hope the
//     passive-damage / ML picture shifts before we come back around
//  3. delay used up -> take the ordered weaklings again with the HP criteria off,
//     just finishing whatever free kills are still outstanding
string fightPicker(){
    string pick = pickWeakling(true);
    if (pick != "done")
        return pick;
    if (to_int(get_property("_gingerbreadCityTurns")) < 30)
        return "gingerbread";
    pick = pickWeakling(false);
    if (pick != "done")
        print("[DEBUG] Weak monsters: retrying " + pick + " without the safeToFK HP check.", "red");
    return pick;
}


// Put the standard mimic free-kill combat gear on NOW -- run the same maximize
// preadventure.ash does before a fight -- so my_buffedstat() / ML read what the
// fight will actually use. Without this, fightPicker() decides on pre-maximize
// stats and safeToFK()'s HP math is wrong the moment preadventure swaps gear.
// (This settles the surface stance only; underwater picks still shift once you
// dive, and the per-pick overrides -- shield, weapon, hat -- are applied later.)
void settleStance(){
    set_property("offOverride","");
    mimicPrep();
    main@preadventure( );
}

// Complete the picker and special leaf fights, then finish with sandworms.
void weakMonsters(){
    set_auto_attack(0); // unlockerCCS owns the ice-shard opener and all stalling.
    setClan("stash");
    step("phase: weakMonsters start");
    prepareShardStatLimiter();
    set_property("subscript","weakling");
    retrieve_item($item[shard of double-ice]);
    if (!equip($slot[acc3],$item[PirateRealm eyepatch]))
        abort("Weak monsters: could not equip the daily PirateRealm eyepatch.");
    // fightPicker() returns one key per call, in strict priority order; run that
    // fight, then re-ask. It also sets offOverride and buffs ML as needed.
    // settleStance() before every fightPicker() so the pick is made with the real
    // combat gear on, not whatever the last dispatch left equipped.
    settleStance();
    string pick = fightPicker();

    boolean monsteraRemaining = get_property("_tiedUpFlamingMonsteraFought") == "false";
    boolean leaviathanRemaining = get_property("_tiedUpLeaviathanFought") == "false";
    boolean sandwormRemaining = get_property("_aprilBandTomUses").to_int() < 3
        && available_amount($item[Apriling band quad tom]) > 0;
    if ((pick != "done" || monsteraRemaining || leaviathanRemaining || sandwormRemaining)
        && have_effect($effect[coldform]) == 0){
        retrieve_item($item[phial of coldness]);
        use($item[phial of coldness]);
        if (have_effect($effect[coldform]) == 0)
            abort("Weak monsters require Coldform for ice-shard stalling.");
    }

    while (pick != "done"){
        // pearloP1() leaves subscript on "looseFK" -- re-assert it each pass.
        set_property("subscript","weakling");

        if (pick == "gingerbread"){
            step("phase: weakMonsters gingerbread");
            gingerbread();
        }
//unreachable code - also no sea access in hat path
//        else if (pick == "pearloP1"){
//            step("phase: weakMonsters pearl P1");
//            pearloP1();
//        }
        else if (pick == "leaflet"){
            step("phase: weakMonsters tied-up flaming leaflet");
            mimicPrep();
            main@preadventure( );
            use($item[tied-up flaming leaflet]);
            main@postadventure( );
        } else if (pick == "monstera"){
            step("phase: weakMonsters leaf-burning flaming monstera");
            mimicPrep();
            main@preadventure( );
            if (!retrieve_item(111, $item[inflammable leaf]))
                abort("Could not acquire 111 inflammable leaves for a flaming monstera.");
            if (!retrieve_item(2, $item[lit leaf lasso]))
                abort("Flaming monstera requires two lit leaf lassos before combat.");
            int leafFightsBefore = get_property("_leafMonstersFought").to_int();
            visit_url("campground.php?preaction=leaves");
            visit_url("choice.php?"+my_hash()+"&whichchoice=1510&option=1&leaves=111");
            run_combat();
            main@postadventure( );
            if (get_property("_leafMonstersFought").to_int() <= leafFightsBefore)
                abort("Leaf-burning flaming monstera did not advance the daily fight counter.");
        } else if (pick == "BRICKO"){
            step("phase: weakMonsters BRICKO ooze");
            mimicPrep();
            main@preadventure( );
            use($item[bricko ooze]);
            main@postadventure( );
        } else if (pick == "lynyrd"){
            step("phase: weakMonsters lynyrd snare");
            mimicPrep();
            main@preadventure( );
            use($item[lynyrd snare]);
            main@postadventure( );
        } else if (pick == "zeppelin"){
            step("phase: weakMonsters red zeppelin / archaeologist");
            if (have_item($item[Archaeologist's Spade]) && to_int(get_property("_archSpadeDigs")) < 11) {
                set_property("archSkeleton","true");
                mimicPrep();
                archaeologist();
                set_property("archSkeleton","false");
            } else if (to_int(get_property("_glarkCableUses")) < 5 && can_adventure($location[The Red Zeppelin])){
                set_property("mainOverride","");
                mimicPrep();
                MobiusMaybe();
                if (!retrieve_item(5 - get_property("_glarkCableUses").to_int(), $item[glark cable]))
                    abort("Could not acquire glark cables before entering the Red Zeppelin.");
                adv1($location[the red zeppelin]);
                set_property("acc2Override","");
            }
            set_property("mainOverride","");
        } else if (pick == "ghost"){
            step("phase: weakMonsters paranormal ghost (walkie-talkie)");
            mimicPrep();
            MobiusMaybe();
            location ghostLoc = walkieGhost();
            if (ghostLoc != $location[none])
                adv1(ghostLoc);
        }

        settleStance();
        pick = fightPicker();
    }
    if (monsteraRemaining || leaviathanRemaining){
        step("phase: special leaf monsters");
        cli_execute("acquire 4 lit leaf lasso");
    }
    if (monsteraRemaining){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up flaming monstera]);
        main@postadventure( );
    }
    if (leaviathanRemaining){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up leaviathan]);
        main@postadventure( );
    }

    // Sandworms run last so earlier Shieldbutts can build farming buffs first.
    if (get_property("_aprilBandTomUses").to_int() < 3
        && available_amount($item[Apriling band quad tom]) > 0){
        set_property("subscript", "weakling");
        settleStance();
        if (!safeToFK($monster[giant sandworm]))
            print("[DEBUG] Weak monsters: finishing sandworms without the safeToFK HP check.", "red");
        step("phase: weakMonsters giant sandworm (quad tom)");
        sandworm();
        // Preserve the old exhaustion handling if the instrument disappears.
        if (available_amount($item[Apriling band quad tom]) == 0)
            set_property("_aprilBandTomUses", "3");
    }

    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("mainOverride","");
    set_property("offOverride","");
    set_property("hatOverride","");
    set_property("subscript","");
    cleanupGingerbreadAdventure();
}

// True while weakMonsters() still has something to do -- gates the call in
// bulkFK(). Mirrors fightPicker()'s availability checks (minus the HP math).
boolean weakMonstersLeft(){
    if (to_int(get_property("_gingerbreadCityTurns")) < 30) return true;
    if (to_int(get_property("_leafMonstersFought")) < 5) return true;
    if (get_property("_tiedUpFlamingLeafletFought") == "false") return true;
    if (to_int(get_property("_brickoFights")) < 10) return true;
    if (to_int(get_property("_lynyrdSnareUses")) < 3) return true;
    if ((to_int(get_property("_glarkCableUses")) < 5
            || (have_item($item[Archaeologist's Spade]) && to_int(get_property("_archSpadeDigs")) < 11))
        && can_adventure($location[The Red Zeppelin])) return true;  //last
    if (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0) return true;
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"
        && mall_price($item[tied-up flaming monstera]) < 15000) return true;
    if (get_property("_tiedUpLeaviathanFought") == "false"
        && mall_price($item[tied-up leaviathan ]) < 15000) return true;
    if (get_property("questPAGhost") == "started"
        || (get_property("questPAGhost") == "unstarted"
            && total_turns_played() >= to_int(get_property("nextParanormalActivity"))
            && item_amount($item[almost-dead walkie-talkie]) > 0)) return true;
    return false;
}

// Scope the embezzler outfit and recovery settings so later phases start cleanly.
void luckyEmbezzlers(){
    string[string] saved;
    foreach pref in $strings[script, subscript, maxOverride, famOverride, backOverride, hpAutoRecovery, hpAutoRecoveryTarget, mpAutoRecovery, mpAutoRecoveryTarget, _teresEmbezzlerOutfit]
        saved[pref] = get_property(pref);
    try {
        set_property("_teresEmbezzlerOutfit", "");
        set_property("script", "embezzler");
        set_property("subscript", "");
        set_property("maxOverride", "meat drop");
        altFam($familiar[Jill-of-All-Trades]);
        codpiece("none");
        // Set the actual Meat outfit before evaluating profitable Lucky! sources.
        set_property("backOverride", get_property("_batWingsFreeFights").to_int() < 5
            ? ", equip bat wings" : "");
        setupEmbezzler();
        while (getLucky()){
            if (!adv1($location[Cobb's Knob Treasury]))
                abort("Lucky! Treasury encounter failed.");
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

// Test the full Lucky! embezzler phase.
void debug() {
    // use NC forces at end so we dont waste effect turns meant for FKs when getting reward
    step("phase: dailyFKs NC force in Shadow Rift");
    shadowRiftForcers();
    if (!contains_text(get_property("thoth19_event_list"),"postFKD2"))
        cli_execute("ptrack add postFKD2");

}

// Burn any leftover monkey paw wishes on Salty mouth + drinking a party beer bomb
void dailyFKPawBeers(){
    item beer=$item[party beer bomb];
    int remaining=max(0,5-get_property("_monkeyPawWishesUsed").to_int());
    if(remaining==0||available_amount($item[cursed monkey's paw])==0)return;
    if(!have_skill($skill[The Ode to Booze])){
        print("Skipping Salty Mouth wishes: The Ode to Booze is unavailable.","red");
        return;
    }
    while(get_property("_monkeyPawWishesUsed").to_int()<5){
        if(available_amount(beer)==0){
            print("Stopping Salty Mouth wishes: no Party Beer Bomb remains to clear the effect.","red");
            return;
        }
        if(my_inebriety()+beer.inebriety>inebriety_limit()){
            print("Stopping Salty Mouth wishes: drinking a Party Beer Bomb would exceed liver capacity.","red");
            return;
        }
        barfOde(beer.inebriety);
        if(have_effect($effect[Salty Mouth])>0){
            int existingBeer=available_amount(beer);
            if(!drink(1,beer))abort("Could not drink Party Beer Bomb after acquiring Ode.");
            if(available_amount(beer)>=existingBeer||my_inebriety()>inebriety_limit()
                ||have_effect($effect[Salty Mouth])>0)
                abort("Could not safely clear the existing Salty Mouth effect with Party Beer Bomb.");
            continue;
        }
        int wishesBefore=get_property("_monkeyPawWishesUsed").to_int();
        cli_execute("monkeypaw effect Salty Mouth");
        if(get_property("_monkeyPawWishesUsed").to_int()!=wishesBefore+1
            ||have_effect($effect[Salty Mouth])==0)
            abort("Monkey Paw failed to grant Salty Mouth; stopping before drinking.");
        barfOde(beer.inebriety);
        int beerBefore=available_amount(beer);
        if(!drink(1,beer))abort("Could not drink Party Beer Bomb after acquiring Ode.");
        if(available_amount(beer)>=beerBefore||my_inebriety()>inebriety_limit())
            abort("Party Beer Bomb was not consumed safely after acquiring Ode.");
        if(have_effect($effect[Salty Mouth])>0)
            abort("Party Beer Bomb did not clear Salty Mouth; stopping before another wish.");
    }
    print("Used remaining Monkey Paw wishes on Salty Mouth, clearing each with a Party Beer Bomb under Ode.","blue");
}

// Essentially main function for Hat Path aftercore - this is the old bulkFKD2 function
void dailyFKs() {
    step("phase: dailyFKs start");
    // Keep preadventure from running extra post-adventure upkeep for an NC force.
    set_property("inSpendAdv","true");
    set_property("LastFKTurn", total_turns_played());
    set_property("script","FreeKill");
    // starter() to set the consult script to unlockerCCS.ash
    starter();
    set_property("subscript", "");
    set_auto_attack(0);

    // Renew Coldform only for pending shard fights; a resumed run may have only bosses/forcers left.
    step("Pledging allegiance to BARF Mountain for +50% meat . . .");
    if (!can_adventure($location[barf mountain])){
        retrieve_item($item[one-day ticket to Dinseylandfill]);
        use($item[one-day ticket to Dinseylandfill]);
    }
    eaglePledge($location[barf mountain]);
    use_familiar($familiar[stocking mimic]);
//    step("phase: dailyFKs - Spending spleen on Extrovermectin");
//    extrovermectinPrep();
    step("phase: dailyFKs reminisce");
    reminisce();
    step("phase: dailyFKs Shield Maiden meat blessing");
    shieldMaidenMeatBuff();    //------ NEED A BETTER TARGET OR WAY TO GET HIT HARDER

    //  scaling fights - tooth golem, moleman
    step("phase: August Golem");
    augustGolem();
    if (!get_property("_molehillMountainUsed").to_boolean()){
        prepareDailyShardCombat();
        mimicPrep();
        main@preadventure();
        use($item[molehill mountain]);
    }

// FIGHTS SPECIFICALLY FOR FAMILIAR EXP
    step ("phase: Hidden City - charging Chest Mimic/Yeti from drunk pygmy fights");
    restOfHiddenCity();   // fights end immediately (drunk pygmy) - only for charging mimic/yeti
    step("phase: dailyFKs god lobster");
    godLobsterFights();


    // Cyber constructs retain their dedicated handler; hackers use shard combat.
    //make sure only the hackers use ice-shard logic, constructs should stick to logic we currently have
    step("phase: dailyFKs cyberzone");
    while (get_property("_cyberFreeFights").to_int() < 10){
        prepareDailyShardCombat();
        cli_execute("use digital honeypot");
        constructBanish();
        mimicPrep();
        cyberzone();
    }

    if (weakMonstersLeft())
        weakMonsters();
    step("phase: dailyFKs scientist tentacle");
    scientistTentacleFight();
    step("phase: dailyFKs copied monsters");
    copyMonsters();
    step("phase: dailyFKs Dire Warren Habitat recalls");
    habitatRecall();
    step("phase: dailyFKs Trick-or-Treat houses");
    trickOrTreatFreeFights();
    step("phase: dailyFKs shadow rift - Affinity then free kills");
    shadowRiftFreeKills();

    step("phase: dailyFKs Neverending Party");
    neverendingPartyFreeFights();

    // uncomment code in iotm.ash file to start using 11-leaf clovers again
    // only using free Lucky sources for now
    step("phase: dailyFKs set fire to embezzlers with ~ Lucky! ~ sources");
    luckyEmbezzlers();

    step("phase: dailyFKs ... Using remaining wishes for Salty Mouth + party beer bombs");
    dailyFKPawBeers();
    // use NC forces at end so we dont waste effect turns meant for FKs when getting reward
    step("phase: dailyFKs NC force in Shadow Rift");
    shadowRiftForcers();
    if (!contains_text(get_property("thoth19_event_list"),"postFKD2"))
        cli_execute("ptrack add postFKD2");


    // Habitat recall chaining remains disabled until its Hat Trick implementation is ready.
    // Wanderer turn counters do not decrease during free fights.
//    habitatRecall();

    print("We made it through all the Free Kill sources for the day! YAY!", "blue");

/*
 string confirmedFK = "";
 TODO:
  - Refract + YR uses
  - add PVP somewhere
  - Burn mana on Libram between adventures
  - use legendary beat and other temporary +item on sandworms

    //vhs tape sausage goblins
    //envyfish egg on sausage goblin in a flooded zone? - and uncomment envyfish egg under

    // alternate spinning wheel + model trainset for extra MPA
    // test if embering hulk is free fight
    // fix adobe subscription stuff
    // maybe think about adding fun-guy spore shit
    // --burning mana on divine favors in post combat
    // shrunken head functionality
    // sweat pants rechargeing  - probably for BARF part
    // --trick or treating
    // snowman hat fights
    // vhs tape free fight + effect extender familiar

    // bulk items to buy: gingerbread cigarette (<1k)
    // law of averages
    // affirmation cookies for diet

    // BARF STUFF:
        Buffs:
            - cranberry cordial
            - blackberry polite
            - baggie of powdered sugar
            - flapper fly
            - polka of plenty
            Use if we have?:
                - polka pop
                - savings bond
                - autumn dollar
                - pork elf mouthwash
            + any other calculated to be profitable buff
        - hobo.js breakfast
        - implement everything looks.... combat stuff
        - day shortener
        - shrunken zombie head stuff
*/

     // TODO: Choose Monster Habitats and Be Gregarious targets, then re-enable chainRoamingMonster() in unlockerCCS.ash.
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

// Full free-kill run: FKPrep (skipped once the Yendorian express card is spent)
// then bulkFK. Individual phases are still reachable as `call StockingMimic.ash
// FKPrep` / `bulkFK`. Wrapped in try/finally so finisher() restores the account's
// mafia hooks / CCS / auto-recovery even if a phase aborts partway.
    // TODO: PVP at end of day but before rollover diet!!!!
    //main order: FKprep -> dailyFKs -> BARF


void main(string phase) {
    boolean completed = false;
    beginFarmingReport();
    try {
        setClan("stash");
        starter();
        set_property("script", "FreeKill");
        set_property("subscript", "");
        set_property("inSpendAdv", "true");
        set_property("LastFKTurn", total_turns_played());
        mimicPrep();

        switch (phase) {
            case "weak":
                weakMonsters();
                break;
            case "debug":
                debug();
                break;



            case "dailyFK":
                dailyFKs();
                // TODO: Run teresBARF.ash after free kills; finish BARF farming with dailyWorkshed().
                break;
            case "prep":
                FKPrep();
                break;

            case "golem":
                augustGolem();
                break;

            case "forcers":
                shadowRiftForcers();
                break;

            default:
                abort("Unknown phase: " + phase);
        }
        completed = true;
    } finally {
        try {
            finisher();
        } finally {
            finishFarmingReport(completed);
        }
    }
}
