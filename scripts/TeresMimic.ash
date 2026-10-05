// StockingMimic.ash -- FKPrep + bulkFK and their helper trees, being lifted out of farto.ash.

import iotm.ash;
import preadventure.ash;

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

// ─── helpers used by FKPrep (verbatim from farto.ash) ────────────────────────

void monkeyPaw(string buffType){
    if (buffType == "meat"){
        foreach ef in $effects[Braaaaaains, Frosty, Let's Go Shopping!, covetous robbery, Low on the Hog, Leisurely Amblin']{
            if (to_int(get_property("_monkeyPawWishesUsed")) == 5)
                return;
            if (have_effect(ef) == 0)
                cli_execute("monkeypaw effect " + ef);
        }
    } else if (buffType == "familiar weight"){
        foreach ef in $effects[covetous robbery, \[1701\]Hip to the Jive, Down With Chow,Chow Downed, squirming like a toad, heavy petting, cute vision, meat puppet, Braaaaaains, frosty,sinuses for miles]{
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
void prepBuffs(){
    setClan("stash");
    use($item[yam battery]);
    // effects that interfere with other buffs we need
    string [int] songEffects = {"Ode to Booze", "The Moxious Madrigal", "The Magical Mojomuscular Melody", "Cletus's Canticle of Celerity", "Power Ballad of the Arrowsmith", "Jackasses' Symphony of Destruction", "Brawnee's Anthem of Absorption", "Psalm of Pointiness", "Stevedave's Shanty of Superiority", "Aloysius' Antiphon of Aptitude", "The Sonata of Sneakiness", "Carlweather's Cantata of Confrontation", "Ur-Kel's Aria of Annoyance", "Dirge of Dreadfulness", "Benetton's Medley of Diversity", "Elron's Explosive Etude", "Prelude of Precision", "Donho's Bubbly Ballad", "Cringle's Curative Carol", "Inigo's Incantation of Inspiration"};
    foreach i, effectName in songEffects {
        effect ef = to_effect(effectName);
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }
    // get rid of all thorns and other passive damage
    foreach ef in my_effects(){
        if (numeric_modifier(ef, "Thorns") != 0 || numeric_modifier(ef, "Sporadic Damage Aura") != 0)
            cli_execute("uneffect " + ef);
    }
    //fam weight
    // cli_execute("hatter reinforced beaded headband");   <-- this is not working in hatpath
    //also buffs only for sea: Greased-Up Familiar
    //'Adobe Ayam Subscription' buff only for hat path
    string [int] famWeightEffects = {"Adobe Ayam Subscription", "Adobe Adze Subscription", "Robot Friends", "Healthy Green Glow", "Chorale of Companionship", "Human-Fish Hybrid", "Whole Latte Love", "Shortly Stacked", "Thoughtful Empathy", "Leash of Linguini", "blood bond", "Empathy", "Black Tongue", "Man's Worst Enemy", "Kindly Resolve", "Human-Machine Hybrid", "Shrimpin' Ain't Easy", "Over-Familiar With Dactyls", "Loyal Tea", "Warm Shoulders", "One Foot Heavier", "Work For Hours a Week", "Panna Consideration", "Loyal as a Rock", "Candied Devil", "Wildsun Boon", "Only Dogs Love a Drunken Sailor", "Best Pals", "Heart of Green", "Bestial Sympathy", "Herder, Bitter, Fester, Stranger", "Party Soundtrack", "Shortly Wired", "Crocodile Tear", "Spiced Out", "offhand remarkable", "Billiards Belligerence", "A Girl Named Sue"};
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
    while (have_effect($effect[Cold Hearted]) < 25){
        use($item[love song of icy revenge]);
    }
    // meat drop
    string [int] meatDropEffects = {"Incredibly Well Lit", "Loded", "Tubes of Universal Meat", "Holiday Bliss", "So You Can Work More...", "Legendary Pasta Eyeball", "Polka of Plenty", "Meet the Meat"};
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
    //item drop
    string [int] itemDropEffects = {"Steely-Eyed Squint", "Spookyravin'", "Unbarking Dogs", "One Very Clear Eye", "Materiel Intel", "Spitting Rhymes", "Joyful Resolve", "Lubricating Sauce"};
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
    "_backUpUses": 11,
    "_cyberFreeFights": 10,
    "_sealsSummoned": 10,
    "_bczSweatBulletsCasts": 13,
    "_gingerbreadMobHitUsed": 1,
    "_shatteringPunchUsed": 3,
    "_firedJokestersGun": 1,
    "_assertYourAuthorityCast": 3,
    "_clubEmTimeUsed": 5,
    "_interestingCoinHeads": 1,
    "_aprilBandTomUses": 3,
    "_glitchMonsterFights": 1,
    "_shadowBricksUsed": 13,
    "_gingerbreadCityTurns": 30,
    "_leafMonstersFought": 5,
    "_tiedUpFlamingLeafletFought": 1,
    "_brickoFights": 10,
    "_speakeasyFreeFights": 3,
    "_cargoPocketEmptied": 1,
    "_lynyrdSnareUses": 3,
    "_archSpadeDigs": 11,
    "_photocopyUsed": 1,
    "_molehillMountainUsed": 1
    //add NEP
};
// Possession/class gate for the entries above that need one -- anything missing here is
// treated as always available (matches how weakMonstersLeft() doesn't gate those either).
boolean [string] freeKillGate = {
    "_backUpUses": have_item($item[backup camera]),
    "_cyberFreeFights": have_item($item[server room key]),
    "_sealsSummoned": my_class() == $class[seal clubber],
    "_bczSweatBulletsCasts": have_skill($skill[BCZ: Sweat Bullets]),
    "_gingerbreadMobHitUsed": have_skill($skill[Gingerbread Mob Hit]),
    "_shatteringPunchUsed": have_skill($skill[Shattering Punch]),
    "_firedJokestersGun": have_item(to_item("The Jokester's gun")),
    "_assertYourAuthorityCast": have_skill($skill[Assert Your Authority]),
    "_clubEmTimeUsed": have_item($item[legendary seal-clubbing club]),
    "_interestingCoinHeads": have_item($item[interesting coin]),
    "_aprilBandTomUses": have_item($item[Apriling band quad tom]),
    "_glitchMonsterFights": have_item($item[\[glitch season reward name\]]),
    "_cargoPocketEmptied": have_item($item[Cargo Cultist Shorts]),
    "_speakeasyFreeFights": have_item(to_item("deed to Oliver's Place"))
    //add NEP
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
        if (freeKillGate contains pref && !freeKillGate[pref])
            continue;
        n += prefFreeKillsLeft(pref, cap);
    }
    if (have_skill($skill[just the facts]))
        n += ((3 - to_int(get_property("_monsterHabitatsRecalled"))) * 5)
            + to_int(get_property("_monsterHabitatsFightsLeft"));
    n += to_int(get_property("beGregariousFightsLeft"));
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
    if (can_adventure($location[A Mob of Zeppelin Protesters]))
        n += max(0, 5 - to_int(get_property("_glarkCableUses")));
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"
        && mall_price($item[tied-up flaming monstera]) < 15000)
        n += 1;
    if (get_property("_tiedUpLeaviathanFought") == "false"
        && mall_price($item[tied-up leaviathan]) < 15000)
        n += 1;
    if (get_property("_aug8Cast") == "false")
        n += max(0, 4 - to_int(get_property("_augSkillsCast")));
    if (get_property("questPAGhost") == "started"
        || (get_property("questPAGhost") == "unstarted"
            && total_turns_played() >= to_int(get_property("nextParanormalActivity"))
            && item_amount($item[almost-dead walkie-talkie]) > 0))
        n += 1;
    if (get_property("_eldritchTentacleFought") == "false"
        && to_int(get_property("eldritchTentaclesFought")) < 11)
        n += 1;
   // if (item_amount($item[envyfish egg]) > 0)
   //     n += 1;
    if (item_amount($item[shaking 4-D camera]) > 0)
        n += 1;
    n += item_amount($item[mimic egg]);
    return n;
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
            cli_execute("acquire tombstone-shaped Crimboween cookie; acquire grease gun");
            if (mall_price($item[Affirmation Cookie]) < 6000){
                cli_execute("acquire 4 Affirmation Cookie");
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=9486&whichitem2=2200&whichitem3=1708");
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=9486&whichitem2=9486&whichitem3=9486");
            } else {
                if (item_amount($item[asbestos meat stack]) < 4)
                    cli_execute("make 4 asbestos meat stack");
                cli_execute("acquire 4 asbestos meat stack");
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=376&whichitem2=376&whichitem3=376");
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=376&whichitem2=2200&whichitem3=1708");
            }
        }
        // END OF DAY DIET BUFFING SHOULD GO HERE - eodDiet();
	}
}

// Spend the day's three Mayam Calendar resonance rings. Guarded on _mayamSymbolsUsed being empty, so a second call is a no-op.
void useMayamRings(){
	if (get_property("_mayamSymbolsUsed") != "" || !have_item($item[Mayam Calendar]))
		return;
	use_familiar($familiar[chest mimic]);
	cli_execute("mayam rings vessel yam cheese explosion;"
		+ " mayam rings fur lightning eyepatch yam;"
		+ " mayam rings eye meat yam clock");
}

float optimalCandy(){
    float perCandyPrice = 100.0;
    float perPound = 27.0 * freeKillCount();
    int pounds = floor(perPound / (2.0 * perCandyPrice)) - 5;
    return pounds * pounds;
}

item candyPick(){
    foreach it in $items[]{
        if (it.candy == true && mall_price(it) < 200 && item_amount(it) > 0){
            return it;
        }
    }
    foreach it in $items[]{
        if (it.candy == true && mall_price(it) <= 100){
            buy(it,(optimalCandy() - get_property("mimicCandiesFed").to_int()),100);
            return it;
        }
    }
    abort("Lmao you ran out of cheap candy");
    return $item[none];
}

void feedCandy(){
    while (get_property("mimicCandiesFed").to_int() < optimalCandy()){
//        int numFed = min(item_amount(candyPick()),(optimalCandy() - get_property("mimicCandiesFed").to_int()));
        if (contains_text(visit_url("inventory.php?pwd=" + my_hash() + "&action=candy&which=1&whichitem=" + candyPick().to_int()).to_string(),"quickly consumes")){
            if (get_property("lastStockingMimicReset").to_int() != my_ascensions( )){
                set_property("lastStockingMimicReset",my_ascensions( ));
                set_property("mimicCandiesFed","1");
            } else {
                set_property("mimicCandiesFed",get_property("mimicCandiesFed").to_int() + 1);
            }
        } else {
            cli_execute("refresh all");
        }
    }
}

void goodies() {
    setClan("VIP");
    create($item[Sheriff pistol]);
    create($item[Sheriff badge]);
    create($item[Sheriff moustache]);

    cli_execute("aprilband item quad tom");
//    cli_execute("aprilband item sax");    -- moved this to inside embezzler(), now done with getLucky()
    setClan("stash");
}

void FKPrep(){
    // TO DO: Implement differet dieting plans (at eod, beginning, etc)

	step("phase: FKPrep start");
    set_property("autoSatisfyWithStash", "true");
	starter();
	// Combat runs off the player's saved combat macro (id in the combatMacroID
	// pref) as the native KoL auto-attack -- round 0 only works when the macro is
	// set natively, not embedded in a mafia CCS. starter() just cleared the
	// auto-attack, so re-arm it here.
    if (dayType() == 0 && have_effect($effect[shadow affinity]) == 0){
        int peevp = pvp_attacks_left();
        if (peevp > 0 && count(current_pvp_stances( )) > 0) {
            cli_execute("PVP_MAB; unequip pants");
        }
    }
    if (get_auto_attack() == 0)
        aa("facsimile");
//	if (get_property("_shadowAffinityToday") == "false")
//		use($item[closed-circuit pay phone]);

    // Get daily goodies (Sheriff gear, Marching Band stuff)
    step("phase: FKPrep getting sheriff and band goodies");
    goodies();

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
	useMayamRings();
    step("phase: FKPrep hidden temple");
	if (my_ascensions() != get_property("lastTempleAdventures").to_int()
		&& get_property("questM16Temple") == "finished"){
		use($item[stone wool]);
		set_property("choiceAdventure582", "1");
		set_property("choiceAdventure579", "3");
		adv1($location[The Hidden Temple]);
		useMayamRings();
	}
/* uncomment this code when writing script for others paths outside of hatpath
    if (have_effect($effect[Hammertime]) == 0)
        use($item[too legit potion]);
    effect[int] beretBuffs;
    if (dayType() == 0){
        beretBuffs[0] = $effect[joy];
        beretBuffs[1] = $effect[Whole Latte Love];
        beretBuffs[2] = $effect[Bureaucratized];
        beretBuffs[3] = $effect[Christmessy];
        beretBuffs[4] = $effect[Sweet Incentive];
    } else if (dayType() == 1){
        beretBuffs[0] = $effect[Optimist Primal];
        beretBuffs[1] = $effect[Beastly Flavor];
        beretBuffs[2] = $effect[Toothy Grin];
        beretBuffs[3] = $effect[Phairly Pheromonal];
        beretBuffs[4] = $effect[Souper Vengeful];
    }

    while (get_property("_beretBuskingUses").to_int() < 5){
        beretBusking("familiar weight,meat drop",beretBuffs[get_property("_beretBuskingUses").to_int()].to_string());
    }
 */
    //replace with above commented code for paths outside of hat path
    while (get_property("_beretBuskingUses").to_int() < 5){
        use_skill($skill[Beret Busking]);
    }

	prepBuffs();
	monkeypaw("familiar weight");

	step("phase: FKPrep ChibiBuddy");
	// ChibiBuddy: wake it, chat once, then hand off to farto's chibiHandling.
	if (get_property("_chibiChanged") == "false"){
		if (item_amount($item[ChibiBuddy&trade; (off)]) > 0)
			use($item[ChibiBuddy&trade; (off)]);
		cli_execute("chibi chat");
		chibiHandling();
	}

	step("phase: FKPrep daily items");
	if (get_property("_glennGoldenDiceUsed") == "false" && have_item($item[Glenn's golden dice]))
		use($item[Glenn's golden dice]);
    setClan("VIP");
    while (get_property("_poolGames").to_int() < 3)
		cli_execute("pool 1");
	if (get_property("friarsBlessingReceived") == "false")
		cli_execute("friars blessing 2");
	if (get_property("_portableSteamUnitUsed") == "false")
		cli_execute("use portable steam unit");
//	if (get_property("_madTeaParty") == "false")
//		cli_execute("hatter filthy knitted dread sack");

    setClan("stash");
	foreach ef in $effects[Flapper Dancin', Polka Face, Polka of Plenty,
		The Ballad of Richie Thingfinder, Earning Interest, Bet Your Autumn Dollar,
		Sweat Equity, Legendary Pasta Eyeball, Heart of Pink, Tingling Feeling,
		Disco Leer]{
		if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
			continue;
		if (have_effect(ef) == 0)
			cli_execute(ef.default);
	}

	if (have_effect($effect[Do I Know You From Somewhere?]) == 0){
		if (item_amount($item[driftwood beach comb]) == 0)
			use($item[piece of driftwood]);
		cli_execute("beach head 10");
		cli_execute("combo 10");
	}
/*
    if (my_name().to_lower_case() == "fart scauce"){
        foreach ef in $effects[familiar.enq]{
            if (have_effect(ef) > 0)
                continue;
            if (numeric_modifier(ef,"familiar weight") * 27 * freeKillCount() > mall_price($item[pocket wish])){
                cli_execute("genie effect " + ef);
            }
        }
        altFam($familiar[stocking mimic]);
        feedCandy();
    }
 */

	step("phase: FKPrep stash pops");
	// Stash-borrowed one-a-day item pops.
    setClan("stash");
	foreach it in $items[defective Game Grid token, BittyCar MeatCar, Platinum Yendorian Express Card]{
		stashgrab(it);
		if (have_item(it))
			use(it);
		stashreturn(it);
	}

    if (get_property("questPAGhost") == "unstarted" && !have_item($item[protonic accelerator pack])
        && total_turns_played() >= get_property("nextParanormalActivity").to_int()){
        use($item[almost-dead walkie-talkie]);
    }
	step("phase: FKPrep codpiece");
	codpiece("none");
    retrieve_item(2, $item[tuesday's ruby]);
	codpiece("peridot of peril,blood cubic zirconia,baseball diamond,tuesday's ruby,tuesday's ruby");
}

// ─── bulkFK and helpers (verbatim from farto.ash, not yet refactored) ────────

// Standard free-kill farming stance used all over weakMonsters()/bulkFK()'s
// one-off monster kills: comma chameleon out, maximize for familiar weight  <-- use Jill-of-All-Trades because im poor
// with the eternity codpiece equipped (so its own familiar-weight bonus
// doesn't get maximized away). extraMax, if given, is appended to
// maxOverride as-is (e.g. ",-weapon" in seals()).
void equipStockingMimic(){
    if (have_familiar($familiar[stocking mimic]))
        set_property("famOverride","stocking mimic");
    else
        set_property("famOverride","Skeleton of Crimbo Past");
}

void mimicPrep(string extraMax){
    equipStockingMimic();
    set_property("maxOverride","familiar weight, equip eternity codpiece" + extraMax);
}
void mimicPrep(){
    mimicPrep("");
}

void shorts(){
    mimicPrep();
    if (get_property("_cargoPocketEmptied") == "true")
        return;
    boolean[int] emptied;

    foreach i, s in split_string(get_property("cargoPocketsEmptied"), ",")
        emptied[to_int(s)] = true;

    foreach id in $ints[646,191,306,250,30,490,612,317,448,267,47,143,425,402,589,579,136,299,220,428,235,265,363,452,383,666,443,568] {
        if (!emptied[id]) {
            main@preadventure( );
            cli_execute("cargo pick " + id);
            return;
        }
    }
    main@postadventure( );
}
void augustCat(){
    if (to_int(get_property("_augSkillsCast")) >= 4)
        return;

    foreach id in $ints[8] {
        if (get_property("_aug" + id + "Cast") == false && to_int(get_property("_augSkillsCast")) < 4) {
            main@preadventure( );
            cli_execute("cast Aug. " + id);
            main@postadventure( );
        }
    }
}

void augustGolem(){
    if (to_int(get_property("_augSkillsCast")) >= 5)
        return;

    foreach id in $ints[22] {
        if (get_property("_aug" + id + "Cast") == false && to_int(get_property("_augSkillsCast")) < 5) {
            main@preadventure( );
            cli_execute("cast Aug. " + id);
            main@postadventure( );
        }
    }
}

void cyberzone() {
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
    }}
void shadowBoss(){
    cli_execute("cast Carol of the Hells");
    cli_execute("use scroll of drastic healing");
    // 1st round atks for 90% of max hp
    if (get_property("rufusQuestTarget") == "shadow scythe") {
        use($item[scroll of drastic healing]);
        set_property("hpAutoRecovery", 1.0);
        set_property("hpAutoRecoveryTarget", 1.0);
        set_property("maxOverride", "familiar weight, equip congressional medal of insanity");
    }
    // reflects spells, has more elemental resist
    else if (get_property("rufusQuestTarget") == "shadow orrery"){
        set_property("maxOverride","familiar weight");
        set_property("shirtOverride",", equip ultracolor");
        set_property("mainOverride",", equip june cleaver");
    } else if (get_property("rufusQuestTarget") == "shadow spire"){
        set_property("hpAutoRecovery",0.36);
        set_property("hpAutoRecoveryTarget",0.36);
        cli_execute("recover hp");
        if (have_item($item[petrified wood wizard's pouch]))
            set_property("maxOverride","familiar weight, equip petrified wood wizard's pouch");
        else
        set_property("maxOverride","familiar weight, equip congressional medal of insanity");
    }
}

// Legacy helper still used by the looseFK phase.
void shadowRealmFK(){
    //prep
    cli_execute("uneffect coldform");
    equipStockingMimic();
    if (!contains_text(get_property("maxOverride"),"familiar"))
        set_property("maxOverride","familiar weight, equip eternity codpiece");
    // If we finished the last quest ->  collect reward -> cash in reward
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);  // collect
        adv1($location[Shadow Rift (The Misspelled Cemetary)]); // cash in (no turn spent)
    }
    // Shadow Affinity has not been obtained today and a Rufus quest is already active
    if (get_property("_shadowAffinityToday") == false && get_property("questRufus") != "unstarted"){
        if (get_property("rufusQuestType") == "entity")
            shadowBoss();
        else if (have_effect($effect[shadow affinity]) < get_property("encountersUntilSRChoice").to_int()){
            abort("script out non entity case");
        }
    }
    // Dealing with scaling high resistance
    if ($monster[shadow slab].elemental_resistance > 85)
        set_property("acc3Override",",equip congressional medal of insanity");
    else
        set_property("acc3Override","");

    // Use Bat Wing Swoops if entering non-free shadow fight
    if (to_int(get_property("_batWingsSwoopUsed")) < 11 && (have_effect($effect[shadow affinity]) == 0))
        set_property("backOverride",", equip bat wings");
    // make sure quest is started
    if (get_property("questRufus") == "unstarted")
        use($item[closed-circuit pay phone]);
    if (get_property("questRufus") == "started" && get_property("rufusQuestType") == "items"){
        retrieve_item(3,to_item(get_property("rufusQuestTarget")));
    } else if (have_effect($effect[shadow affinity]) > 0){
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    } else {
        // use any free NC's or gear for free in-combat skills forcing NC's -> adv
        NCforce(false);
        if (get_property("rufusQuestType") == "entity"){
            // Parka NCs
            if (to_int(get_property("_spikolodonSpikeUses")) < 5 && have_effect($effect[everything looks yellow]) == 0){
                set_property("shirtOverride",", equip jurassic parka (spikolodon)");
            } else {
                set_property("shirtOverride","");
            }
            // Ski NCs
            if (to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
                set_property("offOverride",", equip mchugelarge left ski");
            else
                set_property("offOverride","");

            if (get_property("noncombatForcerActive") == "true" || get_property("encountersUntilSRChoice").to_int() == 0){
//                set_auto_attack(0);     --I think this needs to not be here but idk
                shadowBoss();
            }
        }
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    // Previous Rufus quest is complete -> turn it in and collect the reward
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    // Start a new quest and get Shadow Affinity for today
    if (get_property("_shadowAffinityToday") == false)
        use($item[closed-circuit pay phone]);
    //reset overrides
    set_property("shirtOverride","");
    set_property("backOverride","");
    set_property("mainOverride","");
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
                get_property("_shadowForestLooted").to_boolean() ? "2" : "3");
            if (!adv1(rift))
                abort("Rufus: could not redeem the lodestone.");
            if (total_turns_played() != turnsBefore)
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

// Morning: acquire today's Affinity, then adventure until it runs out.
// Leave quest turn-ins and remaining rewards to shadowRiftForcers().
void shadowRiftMorning() {
    location rift = $location[Shadow Rift (The Misspelled Cemetary)];
    string[string] saved;
    foreach pref in $strings[script, subscript, inSpendAdv, maxOverride, famOverride, shirtOverride, backOverride, mainOverride, offOverride, acc3Override, hpAutoRecovery, hpAutoRecoveryTarget]
        saved[pref] = get_property(pref);

    try {
        set_auto_attack(0);
        set_property("script", "FreeKill");
        set_property("subscript", "");
        set_property("inSpendAdv", "true");
        cli_execute("uneffect coldform");

        settleRufusRewards(false);
        if (!get_property("_shadowAffinityToday").to_boolean()) {
            if (get_property("questRufus") != "unstarted")
                abort("Rufus: an unfinished quest blocks accepting today's Affinity quest.");
            settleRufusRewards(true);
            if (have_effect($effect[Shadow Affinity]) == 0)
                abort("Rufus: today's quest did not grant Shadow Affinity.");
        }

        int freeInterruptions = 0;
        while (have_effect($effect[Shadow Affinity]) > 0) {
            foreach pref in $strings[shirtOverride, backOverride, mainOverride, offOverride, acc3Override]
                set_property(pref, "");
            set_property("hpAutoRecovery", saved["hpAutoRecovery"]);
            set_property("hpAutoRecoveryTarget", saved["hpAutoRecoveryTarget"]);
            mimicPrep();
            if ($monster[shadow slab].elemental_resistance > 85)
                set_property("acc3Override", ", equip congressional medal of insanity");
            if (get_property("questRufus") == "started" && get_property("rufusQuestType") == "entity"
                && (get_property("encountersUntilSRChoice").to_int() == 0 || get_property("noncombatForcerActive").to_boolean()))
                shadowBoss();

            int affinityBefore = have_effect($effect[Shadow Affinity]);
            int turnsBefore = total_turns_played();
            if (!adv1(rift))
                abort("Morning Rift adventure failed.");
            if (total_turns_played() != turnsBefore)
                abort("Morning Rift unexpectedly spent a turn.");
            // Free noncombats may leave Affinity unchanged. Allow them and retry.
            if (have_effect($effect[Shadow Affinity]) < affinityBefore)
                freeInterruptions = 0;
            else if (++freeInterruptions >= 20)
                abort("Morning Rift: 20 encounters without consuming Affinity; inspect the encounter.");
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}

// Evening: fight bosses already due, then use the remaining free NC forces.
void shadowRiftForcers() {
    location rift = $location[Shadow Rift (The Misspelled Cemetary)];
    string[string] saved;
    foreach pref in $strings[script, subscript, inSpendAdv, maxOverride, famOverride, shirtOverride, backOverride, mainOverride, offOverride, acc3Override, hpAutoRecovery, hpAutoRecoveryTarget]
        saved[pref] = get_property(pref);

    try {
        set_auto_attack(0);
        set_property("script", "FreeKill");
        set_property("subscript", "");
        set_property("inSpendAdv", "true");
        cli_execute("uneffect coldform");
        if (have_effect($effect[Shadow Affinity]) > 0)
            abort("Use shadowRiftMorning() to finish Affinity before spending NC forces.");

        while (true) {
            settleRufusRewards(false);
            if (get_property("questRufus") == "started" && get_property("rufusQuestType") != "entity")
                abort("Evening Rift routine expects an entity quest.");

            boolean bossDue = get_property("encountersUntilSRChoice").to_int() == 0;
            if (!bossDue && !get_property("noncombatForcerActive").to_boolean()) {
                if (item_amount($item[Apriling band tuba]) > 0 && available_amount($item[Apriling band helmet]) > 0 && get_property("_aprilBandTubaUses").to_int() < 3) {
                    cli_execute("aprilband play tuba");
                } else if (item_amount($item[Clara's bell]) > 0 && !get_property("_claraBellUsed").to_boolean()) {
                    use($item[Clara's bell]);
                } else if (available_amount($item[Cincho de Mayo]) > 0) {
                    // The helmet can provide extra free rests.
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
                if (!get_property("noncombatForcerActive").to_boolean())
                    break; // No free force available: do not enter a paid fight.
            }

            settleRufusRewards(true);
            foreach pref in $strings[shirtOverride, backOverride, mainOverride, offOverride, acc3Override]
                set_property(pref, "");
            set_property("hpAutoRecovery", saved["hpAutoRecovery"]);
            set_property("hpAutoRecoveryTarget", saved["hpAutoRecoveryTarget"]);
            mimicPrep();
            shadowBoss();

            int turnsBefore = total_turns_played();
            if (!adv1(rift))
                abort("Evening Rift boss encounter failed.");
            if (total_turns_played() != turnsBefore)
                abort("Evening Rift unexpectedly spent a turn.");
            if (get_property("questRufus") != "step1")
                abort("Expected a completed boss quest; inspect the encounter.");
            settleRufusRewards(false);
        }
    } finally {
        foreach pref, value in saved
            set_property(pref, value);
    }
}


void sandworm(){
    mimicPrep();
    if (get_property("_aprilBandTomUses").to_int() < 3){
        while (to_int(get_property("_aprilBandTomUses")) < 3 && available_amount($item[Apriling band quad tom]) > 0){
            main@preadventure( );
            cli_execute("aprilband play quad tom");
            run_combat();
            main@postadventure( );
        }
    }
}
void archaeologist(){
    if (to_int(get_property("_archSpadeDigs")) < 11 && can_adventure($location[A Mob of Zeppelin Protesters])){
        if (my_location() != $location[the red zeppelin]){
            if (get_property("zeppelinProgress").to_int() >= 6)
                set_property("mainOverride",", equip legendary seal-clubbing club");
            else
                set_property("mainOverride","");
            if (to_int(get_property("_glarkCableUses")) < 5) {
                retrieve_item(5,$item[glark cable]);
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
void uneffectBuff(){
    float [stat] adjBase_Stat = {
            $stat[muscle]:30,
            $stat[mysticality]:50,
            $stat[moxie]:30
    };

    stat st = $stat[muscle];
    foreach sta in $stats[mysticality, moxie]{
        if (my_buffedstat(sta) > my_buffedstat(st))
            st = sta;
    }

    effect toRemove;
    int statBuff;

    foreach ef in my_effects(){
        // Don't remove valuable farming/familiar buffs
        if (numeric_modifier(ef, "Item Drop") != 0
                || numeric_modifier(ef, "Meat Drop") != 0
                || numeric_modifier(ef, "Familiar Weight") != 0)
            continue;

        if ((numeric_modifier(ef, to_string(st) + " Percent") / 100)
                * adjBase_Stat[st] > statBuff){
            statBuff = (numeric_modifier(ef, to_string(st) + " Percent") / 100)
                    * adjBase_Stat[st];
            toRemove = ef;
        }


    }
    foreach ef in my_effects(){
        // Same protection when checking flat-stat buffs
        if (numeric_modifier(ef, "Item Drop") != 0
                || numeric_modifier(ef, "Meat Drop") != 0
                || numeric_modifier(ef, "Familiar Weight") != 0)
            continue;

        if (numeric_modifier(ef, to_string(st)) > statBuff){
            statBuff = numeric_modifier(ef, to_string(st));
            toRemove = ef;
        }
    }

    cli_execute("uneffect " + toRemove);
}

boolean looseFK(){
    set_property("maxOverride","familiar weight, equip eternity codpiece");
    if ((my_basestat($stat[submoxie]) - 62500) > BCZcost("SweatBulletsCasts") && get_property("_bczSweatBulletsCasts").to_int() < 13){
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        print ("FK is sweat");
        return true;
    }
    if (get_property("_bczSweatBulletsCasts").to_int() < 9){
        abort("Script has been skipping over sweat bullets for some reason");
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
        setClan("VIP");
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip jokester's gun");
        return true;
    }
    if (get_property("_assertYourAuthorityCast").to_int() < 3){
        print ("FK is assert");
        setClan("VIP");
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
    return false;
}

void resCheck(string str){
    if (numeric_modifier(pearls[str].ele_res) < 18)
        cli_execute("gain 18 " + pearls[str].ele_res);
    if (numeric_modifier(pearls[str].ele_res) < 18)
        abort(pearls[str].ele_res + " is below 18");
}

void underwaterBaseball(){
    mimicPrep();
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

boolean pearloP1Done(){
    foreach str in $strings[anemone,trench,bar]{
        if (get_property(pearls[str].donePref) == "false")
            return false;
    }
    return true;
}

void pearloP1(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0)
        use($item[willyweed]);
    if (have_effect($effect[driving waterproofly]) == 0)
        set_property("pantsOverride",", equip really nice swim");
    banishFish();
    if (get_auto_attack() == 0)
        aa("facsimile");
    equip($slot[acc2],$item[mafia pointer finger ring ]);
    set_property("acc2Override",", bonus mafia pointer finger");
    if (numeric_modifier("Critical Hit Percent") < 100)
        abort("can't guarantee critical hit");
    if ((baseballPlayers() >= 8 && get_property("_baseballInnings").to_int() < 3) || get_property("_curveballFightsLeft").to_int() > 0) {
        underwaterBaseball();
    } else if (looseFK()){
        set_property("acc3Override",", equip Time Bandit Badge of Courage");
        set_property("subscript","looseFK");
        foreach str in $strings[trench,bar]{
            if (get_property(pearls[str].donePref) == "false" || str == "bar"){
                resCheck(str);
                equipStockingMimic();
                adv1(pearls[str].loc);
                break;
            }
        }
    }
    set_property("pantsOverride","");
    set_property("acc2Override","");
}
void pearloP2(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0){
        use($item[willyweed]);
    }
    banishFish();
    foreach str in $strings[deepests,reef]{
        if (have_effect($effect[driving waterproofly]) == 0)
            set_property("pantsOverride", ", equip really nice swim");
        equipStockingMimic();
        //set_property("offOverride",",equip Kramco Sausage-o-Matic");
        if (get_property(pearls[str].donePref) == "false" || str == "reef"){
            resCheck(str);
            adv1(pearls[str].loc);
            break;
        }
    }
    set_property("pantsOverride","");
}
void pearloP3(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0){
        use($item[willyweed]);
    }
    banishFish();
    foreach str in $strings[anemone,bar,trench]{
        if (get_property(pearls[str].donePref) == "false" || str == "trench"){
            resCheck(str);
            adv1(pearls[str].loc);
            break;
        }
    }
}
void gingerbread(){
    if (get_property("gingerbreadCityAvailable") == false){
        if (get_property("_gingerbreadCityToday") == false)
            use($item[counterfeit city]);
    }
    retrieve_item(29,$item[gingerbread cigarette]);
    if (get_property("_gingerbreadCityTurns").to_int() < 30){
        mimicPrep();
        adv1($location[Gingerbread Upscale Retail District]);
    }
    if (contains_text(LastAdvTxt(),"almost midnight"))
        adv1($location[Gingerbread Civic Center]);
   //     adv1($location[Gingerbread Civic Centers]);
}

void habitatRecall(){
    while (to_int(get_property("_monsterHabitatsRecalled")) < 3 || to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
        banishFish();
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
/*
            if (get_property("beGregariousFightsLeft").to_int() == 1 && get_property("beGregariousCharges").to_int() == 0 && to_int(get_property("_monsterHabitatsRecalled")) == 3 && dayType() == 1){
                if (mall_price($item[flask of embalming fluid]) > 1000)
                    abort("reanimated reanimator is too expensive rn");
                altFam($familiar[reanimated reanimator]);
            }
            pearloP2();
*/
        }
        set_property("offOverride","");
        set_property("acc2Override","");
    }
}
void backup(){
    if (!have_item($item[backup camera])) return;
    while (to_int(get_property("_backUpUses")) < 11){
        if (to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 100){
            set_property("famOverride","chest mimic");
        } else
            equipStockingMimic();
        if (have_effect($effect[everything looks purple]) == 0 && (get_property("famOverride") == "Jill-of-All-Trades" || get_property("famOverride") == "stocking mimic")){
            set_property("offOverride",", equip roman candel");
        } //else
            //set_property("offOverride",",equip Kramco Sausage-o-Matic");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        if (have_effect($effect[driving waterproofly]) == 0)
            set_property("pantsOverride",", equip really nice swim");
        set_property("acc3Override",", equip backup camera");
        pearloP3();
    }
    set_property("offOverride","");
    set_property("pantsOverride","");
    set_property("acc3Override","");
}
void mimicEgg(){
    while (item_amount($item[mimic egg]) > 0 && dayType() == 1){
        mimicPrep();
        main@preadventure( );
        cli_execute("c2t_megg fight sausage goblin");
        run_combat();
        cli_execute("postadventure");
    }
}
void faxing(){
    if (get_property("_photocopyUsed") == false){
        setClan("VIP");
        visit_url("clan_viplounge.php?action=faxmachine&whichfloor=2");
        visit_url("clan_viplounge.php?preaction=receivefax&whichfloor=2");
        setClan("stash");
        if (item_amount($item[photocopied monster]) > 0){
            mimicPrep();
            main@preadventure( );
            use($item[photocopied monster]);
        }
    }
}
void reminisce() {
    while (get_property("_locketMonstersFought").split_string(",").count() < 3){
        foreach mon in $monsters[black crayon golem, black crayon spiraling shape]{
            if (get_property("_locketMonstersFought").contains_text(mon.to_int()))
                continue;
            mimicPrep();
            main@preadventure( );
            cli_execute("reminisce " + mon);
            main@postadventure();
            if (locketAvailable() == 0)
                break;
        }
    }
}
void seals(){
    while (get_property("_sealsSummoned").to_int() < 10 && my_class() == $class[seal clubber]){
        int n = get_property("_sealsSummoned").to_int();
        retrieve_item((10-n),$item[seal-blubber candle]);
        mimicPrep(",-weapon");
        set_property("mainOverride"," ");
        cli_execute("equip gnawed-up dog bone");
        main@preadventure( );
        use($item[figurine of a wretched-looking seal]);
    }
    set_property("mainOverride","");
}

// += 1 for every active effect that deals automatic per-round damage (mafia's
// "Damage Aura" / "Sporadic Damage Aura" modifiers -- Cowrruption, Boxing Day
// Glow, Spiky Hair, Simmering, Frostbeard, and so on). fightPicker() adds this
// to the double-ice estimate so chip damage doesn't kill a weak monster before
// the free kill lands.
int passiveDamage(){
	int n = 2;
	foreach ef in my_effects(){
		if (numeric_modifier(ef, "Damage Aura") != 0
			|| numeric_modifier(ef, "Sporadic Damage Aura") != 0
            || numeric_modifier(ef, "Thorns") != 0)
			n += 1;
	}
	return n;
}

float MLDamageReduction() {
    return max(0.50, (1 - (numeric_modifier($modifier[monster level])*0.004)));
}

// -- HP-headroom math for fightPicker() ----------------------------------------
// The double-ice build chips every monster each round (coldform proc plus the
// passive-damage auras counted by passiveDamage()). If that chip damage kills a
// weakling before the free kill lands, the free kill is wasted -- so fightPicker()
// only hands back a monster whose HP clears the relevant target below, buffing
// Monster Level to pad the monster's HP when it doesn't.

int estimatedIceDamage(){
    int highStat = max(my_buffedstat($stat[muscle]),
                       my_buffedstat($stat[mysticality]),
                       my_buffedstat($stat[moxie]));
    return to_int(highStat * MLDamageReduction());
}
// lowHPTarget: chip damage across a fast (~9-round) free kill.
// highHPTarget: chip damage across a slow (~29-round) one.
int lowHPTarget() {
    return (9 * passiveDamage()) + estimatedIceDamage();
}
int highHPTarget() {
    return (23 * passiveDamage()) + estimatedIceDamage();
}

boolean buffML(monster m){
    setClan("stash");
    int currentML = numeric_modifier("Monster level");
    int targetML = currentML + (lowHPTarget()-m.base_hp);
    //Monster level. Needs reconsidering to work with weakMonsters()
    string [int] mlEffects = {"Ur-Kel's Aria of Annoyance", "Pride of the Puffin", "Bloodbathed", "Misplaced Rage", "Manbait", "Sweetbreads Flamb&eacute;", "Red Lettered", "Spangled Star", "Tortious", "Litterbug", "Not Sharing", "Para-lyzed Jaw", "Contemptible Emanations", "Lapdog", "Ashen Burps", "Gelded", "Mysteriously Handsome", "Eau D'enmity", "Mediocri Tea", "Patent Sallowness", "Yoloswagyoloswag"};
    foreach i, effectName in mlEffects {
        effect ef = to_effect(effectName);
        targetML = currentML + (lowHPTarget()-m.base_hp) + 100; //padding this with extra ML cause im slaughtering too hard
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
// Toggles the april shower thoughts shield (extra double-ice) via offOverride when
// the monster has HP to spare, and buffs ML to pad it when it's too fragile;
// returns false only when even a maxed ML can't make it safe -- the caller then
// skips the fight. A $monster[none] (name lookup missed) is treated as safe.
boolean safeToFK(monster m){
    print(m + " HP will be " + m.base_hp);
    print("Icicle damage is " + estimatedIceDamage());
    print ("Monster HP must be above " + lowHPTarget());
    print ("Monster HP must be below " + highHPTarget());
    if (m == $monster[none]){
        set_property("offOverride","");
        return false;
    }
    if (m.base_hp > highHPTarget()){
        set_property("offOverride",", equip april shower thoughts shield");
        return false;
    }
    set_property("offOverride","");
    if (m.base_hp > lowHPTarget())
        return true;
    if (buffML(m))
        return true;
    else
        while (m.base_hp < lowHPTarget())
            uneffectBuff();
    return false;
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

// The ordered weaklings, flaming leaflets -> tied-up leaviathan (leaviathan
// deliberately last). Returns the first still-outstanding fight, or "done".
// checkHP applies safeToFK() -- available AND chip-safe (buffML'ing when it can),
// skipping any that can't be made safe. checkHP == false is the "delay is used
// up" pass: availability only, HP be damned, just finish the free kills. The
// item-summon fights look their representative monster up by name -- fix the
// strings if a lookup misses.
string pickWeakling(boolean checkHP){
    //custom variable to avoid shit I'm always dying to
    boolean ALWAYSDIE = true;
    if (!checkHP)
        set_property("offOverride","");
    if (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0
        && (!checkHP || safeToFK($monster[giant sandworm])))
        return "sandworm";
    if (to_int(get_property("_lynyrdSnareUses")) < 3
        && (!checkHP || safeToFK(to_monster("Lynyrd"))))
        return "lynyrd";
    if ((to_int(get_property("_glarkCableUses")) < 5 || to_int(get_property("_archSpadeDigs")) < 11)
        && can_adventure($location[A Mob of Zeppelin Protesters])
    //remove later maybe
        && !ALWAYSDIE
        && (!checkHP || safeToFK(to_monster("Red Snapper"))))
        return "zeppelin";
    if (contains_text(get_property("_trickOrTreatBlock"), "D")
        && (!checkHP || safeToFK(to_monster("vandal kid"))))
        return "trickortreat";
    if (get_property("_cargoPocketEmptied") != "true"
        && (!checkHP || safeToFK(to_monster("haxx0r")))
        && (have_item($item[Cargo Cultist Shorts])))
        return "shorts";
    if (to_int(get_property("_speakeasyFreeFights")) < 3
        && (!checkHP || safeToFK(to_monster("traveling hobo")))
        && (have_item($item[11001]))) //deed to Oliver's Place
    return "speakeasy";
    if (to_int(get_property("_brickoFights")) < 10
        && (!checkHP || safeToFK($monster[BRICKO ooze])))
        return "BRICKO";
    if (get_property("_aug8Cast") == "false"
        && to_int(get_property("_augSkillsCast")) < 4
        && (!checkHP || safeToFK($monster[Skeletal cat])))
        return "augustCat";
    if ((get_property("questPAGhost") == "started" || (get_property("questPAGhost") == "unstarted"
        && total_turns_played() >= to_int(get_property("nextParanormalActivity")) && get_property("ghostLocation") != ""))
        && (!checkHP || safeToFK(ghostFor(walkieGhost()))))
        return "ghost";
    if ((to_int(get_property("_leafMonstersFought")) < 5
            || get_property("_tiedUpFlamingLeafletFought") == "false")
        && (!checkHP || safeToFK($monster[flaming leaflet])))
        return "leaflet";
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
    return pickWeakling(false);
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

void weakMonsters(){
    setClan("stash");
    step("phase: weakMonsters start");
    set_property("acc3Override",", equip Time Bandit Badge of Courage");
    set_property("subscript","weakling");
    retrieve_item($item[shard of double-ice]);
    equip($slot[acc3],$item[Time Bandit Badge of Courage]);
    // fightPicker() returns one key per call, in strict priority order; run that
    // fight, then re-ask. It also sets offOverride and buffs ML as needed.
    // settleStance() before every fightPicker() so the pick is made with the real
    // combat gear on, not whatever the last dispatch left equipped.
    settleStance();
    string pick = fightPicker();

    if (pick != "done" && have_effect($effect[coldform]) == 0)   //moved so coldform isnt wasted if script rerun
        use($item[phial of coldness]);

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
            step("phase: weakMonsters flaming leaflets");
            mimicPrep();
            main@preadventure( );
            if (get_property("_tiedUpFlamingLeafletFought") == "false"){
                use($item[tied-up flaming leaflet]);
            } else {
                visit_url("campground.php?preaction=leaves");
                visit_url("choice.php?"+my_hash()+"&whichchoice=1510&option=1&leaves=11");
                run_combat();
            }
            main@postadventure( );
        } else if (pick == "augustCat"){
            step("phase: weakMonsters August Cat Day (skeletal cat)");
            mimicPrep();
            augustCat();
        } else if (pick == "BRICKO"){
            step("phase: weakMonsters BRICKO ooze");
            mimicPrep();
            main@preadventure( );
            use($item[bricko ooze]);
            main@postadventure( );
        } else if (pick == "speakeasy" && have_item($item[Cargo Cultist Shorts])){
            step("phase: weakMonsters traveling hobo");
            mimicPrep();
            adv1($location[An Unusually Quiet Barroom Brawl]);
        } else if (pick == "shorts" && have_item($item[Cargo Cultist Shorts])){
            step("phase: weakMonsters cargo shorts (haxx0r)");
            shorts();
        } else if (pick == "lynyrd"){
            step("phase: weakMonsters lynyrd snare");
            mimicPrep();
            main@preadventure( );
            use($item[lynyrd snare]);
            main@postadventure( );
        } else if (pick == "trickortreat"){
            step("phase: weakMonsters trick-or-treat kid");
            mimicPrep();
//            set_property("hatOverride",", equip beholed bedsheet");
            set_property("shirtOverride",", equip Unkillable Skeleton's breastplate");
            set_property("pantsOverride",", equip Unkillable Skeleton's shinguards");
            main@preadventure( );
            candy("fight");
            main@postadventure( );
//            set_property("hatOverride","");
            set_property("shirtOverride","");
            set_property("pantsOverride","");
        } else if (pick == "zeppelin"){
            step("phase: weakMonsters red zeppelin / archaeologist");
            if (to_int(get_property("_archSpadeDigs")) < 11) {
                set_property("archSkeleton","true");
                mimicPrep();
                archaeologist();
                set_property("archSkeleton","false");
            } else if (to_int(get_property("_glarkCableUses")) < 5 && can_adventure($location[A Mob of Zeppelin Protesters])){
                if (get_property("questL11Ron") == "step4")
                    set_property("mainOverride",", equip legendary seal-clubbing club");
                else
                    set_property("mainOverride","");
                mimicPrep();
                MobiusMaybe();
                retrieve_item(5,$item[glark cable]);
                adv1($location[the red zeppelin]);
                set_property("acc2Override","");
            }
            set_property("mainOverride","");
        } else if (pick == "sandworm"){
            step("phase: weakMonsters giant sandworm (quad tom)");
            sandworm();
            // Out of quad toms -- stop other _aprilBandTomUses < 3 guards retrying.
            if (available_amount($item[Apriling band quad tom]) == 0)
                set_property("_aprilBandTomUses","3");
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
    step("phase: special leaf monsters");
    cli_execute("acquire 4 lit leaf lasso");
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up flaming monstera]);
        main@postadventure( );
    }
    if (get_property("_tiedUpLeaviathanFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up leaviathan]);
        main@postadventure( );
    }

    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("mainOverride","");
    set_property("offOverride","");
    set_property("hatOverride","");
    set_property("subscript","");
}

void LBMWPrep(boolean CMOI){
    if (CMOI == true){
        set_property("acc1Override",", equip congressional medal of insanity");
    }
    aa("facsimile");
    set_property("acc3Override",", equip Time Bandit Badge of Courage");
    retrieve_item($item[shard of double-ice]);
    mimicPrep();
}

void locationBasedWeakMonsters(){
    step("phase: weakMonsters start");
    set_property("subscript","weakling");
    if (have_effect($effect[coldform]) == 0)
        use($item[phial of coldness]);
    equip($slot[acc3],$item[Time Bandit Badge of Courage]);
    step("phase: weakMonsters gingerbread");
    while (to_int(get_property("_gingerbreadCityTurns")) < 30){
        LBMWPrep (false);
        gingerbread();
    }
    step("phase: weakMonsters pearl P1");
    while (looseFK()){
        LBMWPrep (false);
        pearloP1();
    }
    set_property("subscript","weakling");
    while (to_int(get_property("_speakeasyFreeFights")) < 3){
        step("phase: weakMonsters traveling hobo");
        LBMWPrep (true);
        adv1($location[An Unusually Quiet Barroom Brawl]);
    }
    if (get_property("questPAGhost") == "started" && get_property("ghostLocation") != ""){
        step("phase: weakMonsters paranormal ghost (walkie-talkie)");
        LBMWPrep (true);
        while (get_property("ghostLocation").to_location() != $location[none])
            adv1(get_property("ghostLocation").to_location());
    }
    while (to_int(get_property("_glarkCableUses")) < 5 && can_adventure($location[A Mob of Zeppelin Protesters])){
        if (get_property("questL11Ron") == "step4")
            set_property("mainOverride",", equip legendary seal-clubbing club");
        else
            set_property("mainOverride","");
        LBMWPrep (true);
        if (to_int(get_property("_glarkCableUses")) == 4){
            set_property("mainOverride",", equip angelbone totem");
            equip($slot[off-hand],$item[angelbone totem]);
            equip($slot[off-hand],$item[shrunken head]);
            equip($slot[weapon],$item[angelbone totem]);
        }
        retrieve_item(5,$item[glark cable]);
        adv1($location[the red zeppelin]);
        set_property("mainOverride","");
        set_property("acc2Override","");
    }
}

void nonlocationBasedWeakMonsters(){
    step("phase: weakMonsters red zeppelin / archaeologist");
    while (to_int(get_property("_archSpadeDigs")) < 11){
        set_property("archSkeleton","true");
        LBMWPrep (true);
        archaeologist();
        set_property("archSkeleton","false");
    }
    if (get_property("_aug8Cast") == "false" && to_int(get_property("_augSkillsCast")) < 4){
        step("phase: weakMonsters August Cat Day (skeletal cat)");
        LBMWPrep (true);
        augustCat();
    }
    if (to_int(get_property("_brickoFights")) < 10){
        step("phase: weakMonsters BRICKO ooze");
        LBMWPrep (true);
        main@preadventure( );
        use($item[bricko ooze]);
        main@postadventure( );
    }
    if (get_property("_cargoPocketEmptied") != "true" && have_item($item[Cargo Cultist Shorts])){
        step("phase: weakMonsters cargo shorts (haxx0r)");
        shorts();
    }
    step("phase: weakMonsters lynyrd snare");
    while (to_int(get_property("_lynyrdSnareUses")) < 3){
        LBMWPrep (true);
        main@preadventure( );
        use($item[lynyrd snare]);
        main@postadventure( );
    }
    while (contains_text(get_property("_trickOrTreatBlock"), "D")){
        step("phase: weakMonsters trick-or-treat kid");
        LBMWPrep (true);
//            set_property("hatOverride",", equip beholed bedsheet");
        set_property("shirtOverride",", equip Unkillable Skeleton's breastplate");
        set_property("pantsOverride",", equip Unkillable Skeleton's shinguards");
        main@preadventure( );
        candy("fight");
        main@postadventure( );
//            set_property("hatOverride","");
        set_property("shirtOverride",", equip Unkillable Skeleton's breastplate");
        set_property("pantsOverride",", equip Unkillable Skeleton's shinguards");
    }
    while (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0){
        step("phase: weakMonsters giant sandworm (quad tom)");
        sandworm();
    }
/*     Note sure if I want this. Probably use personal eod diet to max fam lb
    if (my_fullness() < fullness_limit()){
        equip($item[devilbone corset]);
        equip($slot[acc3],$item[angelbone chopsticks]);
        eat($item[eldritch mushroom pizza]);
        cli_execute("unequip devilbone corset; unequip angelbone chopsticks");
    }
 */
    while (to_int(get_property("_leafMonstersFought")) < 5
            || get_property("_tiedUpFlamingLeafletFought") == "false"){
        step("phase: weakMonsters flaming leaflets");
        LBMWPrep (true);
        main@preadventure( );
        if (get_property("_tiedUpFlamingLeafletFought") == "false"){
            use($item[tied-up flaming leaflet]);
        } else {
            visit_url("campground.php?preaction=leaves");
            visit_url("choice.php?"+my_hash()+"&whichchoice=1510&option=1&leaves=11");
            run_combat();
        }
        main@postadventure( );
    }
    step("phase: special leaf monsters");
    cli_execute("buy 4 lit leaf lasso");
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up flaming monstera]);
        main@postadventure( );
    }
    if (get_property("_tiedUpLeaviathanFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up leaviathan]);
        main@postadventure( );
    }

    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("mainOverride","");
    set_property("offOverride","");
    set_property("hatOverride","");
    set_property("subscript","");
}

// True while weakMonsters() still has something to do -- gates the call in
// bulkFK(). Mirrors fightPicker()'s availability checks (minus the HP math).
boolean weakMonstersLeft(){
    if (to_int(get_property("_gingerbreadCityTurns")) < 30) return true;
    if (to_int(get_property("_leafMonstersFought")) < 5) return true;
    if (get_property("_tiedUpFlamingLeafletFought") == "false") return true;
    if (to_int(get_property("_brickoFights")) < 10) return true;
    //if (to_int(get_property("_speakeasyFreeFights")) < 3) return true;
    //if (get_property("_cargoPocketEmptied") != "true") return true;
    if (to_int(get_property("_lynyrdSnareUses")) < 3) return true;
    if (contains_text(get_property("_trickOrTreatBlock"), "D")) return true;
    if ((to_int(get_property("_glarkCableUses")) < 5 || to_int(get_property("_archSpadeDigs")) < 11)
        && can_adventure($location[A Mob of Zeppelin Protesters])) return true;
    if (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0) return true;
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"
        && mall_price($item[tied-up flaming monstera]) < 15000) return true;
    if (get_property("_tiedUpLeaviathanFought") == "false"
        && mall_price($item[tied-up leaviathan ]) < 15000) return true;
    if (get_property("_aug8Cast") == "false"
        && to_int(get_property("_augSkillsCast")) < 4) return true;
    if (get_property("questPAGhost") == "started"
        || (get_property("questPAGhost") == "unstarted"
            && total_turns_played() >= to_int(get_property("nextParanormalActivity"))
            && item_amount($item[almost-dead walkie-talkie]) > 0)) return true;
    return false;
}

void restOfHiddenCity(){
    if (!can_adventure($location[An Overgrown Shrine (Southeast)]) || (get_property("zigguratLianas") > 0 && to_int(get_property("_drunkPygmyBanishes")) >= 11))
        return;
    set_property("maxOverride","familiar experience");
    while (to_int(get_property("_drunkPygmyBanishes")) < 11){
        if (!contains_text(get_property("banishedMonsters"),"pygmy bowler") && contains_text(get_property("banishedMonsters"),"pygmy orderlies"))
            set_property("famOverride","patriotic eagle");
        else if (contains_text(get_property("banishedMonsters"),"pygmy orderlies") && dayType() == 1 && get_property("screechCombats").to_int() > 0)
            abort("do patriotic recharge");
        else
            set_property("famOverride","chest mimic");
        drunkPygmy();
    }
    while (get_property("zigguratLianas") == 0 && dayType() == 1){
        set_property("famOverride","chest mimic");
        lianas();
    }
    if (have_effect($effect[Everything looks Beige]) == 0 && have_item($item[crepe paper parachute cape])){
        adv1($location[An Overgrown Shrine (Southeast)]);
        cli_execute("equip weapon antique machete");
        visit_url("inventory.php?action=parachute");
        visit_url("choice.php?option=1&whichchoice=1543&monid=1426");
    }
}

// Essentially main function for Hat Path aftercore
void bulkFKD2(){
    step("phase: bulkFK start");
    set_property("inSpendAdv","true");
    set_property("script","FreeKill");
    mimicPrep();
    // starter() to set the consult script to unlockerCCS.ash
    // bulkFK() run (FKPrep skipped because the express card is already used) still fights.
    starter();
//    if (get_auto_attack() == 0)
//        aa("facsimile");

    step("phase: bulkFK initial shadow rift - Affinity Charges");
    shadowRiftMorning();

    if (weakMonstersLeft())
        weakMonsters();
    step("phase: August Golem");
        augustGolem();
    step("phase: bulkFK spleen (Extrovermectin)");
    if (my_spleen_use() < spleen_limit()){
        int toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
        int mojo = 3-get_property("currentMojoFilters").to_int();
        use(mojo,$item[mojo filter]);
        toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
    }
    step ("phase: use up hidden city");
    restOfHiddenCity();
    step("phase: bulkFK habitat recall");
// fix this to work for hat path
//    habitatRecall();
    step("phase: bulkFK backup camera");
    backup();
    step("phase: bulkFK cyberzone");
    while (get_property("_cyberFreeFights").to_int() < 10){
        cli_execute("use digital honeypot");
        constructBanish();
        mimicPrep();
        cyberzone();
    }
    step("phase: bulkFK loose FK");
    while (looseFK()){
        set_property("subscript","looseFK");
        if (baseballPlayers() == 9 && get_property("_curveballFightsLeft").to_int() == 0 && get_property("_baseballInnings").to_int() < 3)
            baseballD();
        //set_property("offOverride",",bonus Kramco Sausage-o-Matic");
        shadowRealmFK();
    }
    set_property("subscript","");

//    miscellaneousFams();      --- ADD BACK WHEN LESS POOR
    step("phase: bulkFK reminisce");
    reminisce();
    step("phase: bulkFK glitch monster");
    if (get_property("_glitchMonsterFights") == 0 && have_item($item[\[glitch season reward name\]])){
        mimicPrep();
        main@preadventure( );
        eat($item[[glitch season reward name]]);
    }
    set_property("hatOverride","");
    step("phase: bulkFK god lobster");
    setClan("stash");
    while (get_property("_godLobsterFights").to_int() < 3){
        use($item[dish of clarified butter]);
    }
    if (get_property("_molehillMountainUsed") == false)
        use($item[molehill mountain]);
    step("phase: bulkFK mimic egg");
    mimicEgg();
    step("phase: bulkFK faxing");
    faxing();
    if (item_amount($item[shaking 4-D camera]) > 0){
        mimicPrep();
        main@preadventure( );
        use($item[shaking 4-D camera]);
    }
    if (item_amount($item[envyfish egg]) > 0){
        mimicPrep();
        main@preadventure( );
        use($item[envyfish egg]);
    }
    if (my_class() == $class[seal clubber]){
        step("phase: bulkFK seals");
        seals();
    }
    if (get_property("eldritchTentaclesFought").to_int() < 11 && get_property("_eldritchTentacleFought") == "false"){
        main@preadventure();
        visit_url("place.php?whichplace=forestvillage&action=fv_scientist");
        run_choice(1);
        main@postadventure();
    }

    step("phase: bulkFK set fire to embezzlers with ~ Lucky! ~ sources");
    set_property("script","embezzler");
    altFam($familiar[Jill-of-All-Trades]);
    codpiece("none");
    cli_execute("maximize meat drop");    //maximize once to save time
    while(getLucky()){
        // Equip wings directly instead of triggering another maximize
        if (get_property("_batWingsFreeFights").to_int() < 5)
            equip($item[bat wings]);
        adv1(to_location("Cobb's knob treasury"));
    }

    // use NC forces at end so we dont waste effect turns meant for FKs when getting reward
    step("phase: bulkFK NC force in Shadow Rift");
    shadowRiftForcers();
//    stashreturn($item[pantsgiving]);
    if (!contains_text(get_property("thoth19_event_list"),"postFKD2"))
        cli_execute("ptrack add postFKD2");

    print("We made it through all the Free Kill sources for the day! YAY!", "blue");

/*
     DIGGING SKELETONS WITH ARCHEOLOGY NOT WORKING MAYBE?
 string confirmedFK = "";
 TODO:
  - Track actual fights, split into free vs turn-consuming
  - Refract + YR uses
  - Burn mana on Libram between adventures
  - use legendary beat and other temporary +item on sandworms
    // - fix shadow boss killing
    // party FKs not working
    // shield maiden at zeppelin?
    //vhs tape sausage goblins
    //moleman hill (free fight?) check
    //envyfish egg on sausage goblin in a flooded zone? - and uncomment envyfish egg under
*/

}
// add support for Opponent HP: X
// in the CCS facsimile - monsterhpbelow doesnt work without monster manual
void locationBasedAdventuring(){
    //miscellaneousFams();   -- too poor
    step ("phase: use up hidden city");
    restOfHiddenCity();
    step("phase: bulkFK habitat recall");
    habitatRecall();
    step("phase: bulkFK backup camera");
    backup();
    step("phase: bulkFK cyberzone");
    while (get_property("_cyberFreeFights").to_int() < 10){
        mimicPrep();
        cyberzone();
    }
    locationBasedWeakMonsters();
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

// Full free-kill run: FKPrep (skipped once the Yendorian express card is spent)
// then bulkFK. Individual phases are still reachable as `call StockingMimic.ash
// FKPrep` / `bulkFK`. Wrapped in try/finally so finisher() restores the account's
// mafia hooks / CCS / auto-recovery even if a phase aborts partway.
/*
void main(){
    try {
//UNCOMMENT ON FINAL RELEASE
//        if (!user_confirm("This script is currently coded for Hat Path. Continue?"))
//            abort();
//      cli_execute("mallcheck");
        starter();

//        if(false){   //for debug only
        if (get_property("expressCardUsed") == "false"){
            if (get_property("prusias_profitTracking_date") != today_to_string( ))
                cli_execute("ptrack add preprepD2");
            else if (!contains_text(get_property("thoth19_event_list"),"preprepD1") && dayType() == 0)
                cli_execute("ptrack add preprepD1");
            set_property("inSpendAdv","true");
            set_property("script","FreeKill");
            FKPrep();
            if (!contains_text(get_property("thoth19_event_list"),"postprepD2"))
                cli_execute("ptrack add postprepD2");
            else if (!contains_text(get_property("thoth19_event_list"),"postprepD1") && dayType() == 0)
                cli_execute("ptrack add postprepD1");
        }
        if (dayType() == 0)
            bulkFKD1();
        if (dayType() == 1)
            bulkFKD2();
    } finally {
        finisher();
    }
}
*/

void main(string phase) {
    try {
        starter();
        set_property("script", "FreeKill");
        set_property("subscript", "");
        set_property("inSpendAdv", "true");
        set_property("LastFKTurn", total_turns_played());
        mimicPrep();

        switch (phase) {
            case "prep":
                FKPrep();
                break;
            case "shadow":
                shadowRiftMorning();
                break;

            case "weak":
                if (weakMonstersLeft())
                    weakMonsters();
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
    } finally {
        finisher();
    }
}
