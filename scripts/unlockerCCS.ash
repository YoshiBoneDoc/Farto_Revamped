import iotm.ash;

// ─── HELPERS ──────────────────────────────────────────────────────────────────

void sauce(int n) { for i from 1 to n { use_skill($skill[saucegeyser]); } }
void attack(int n)   { for i from 1 to n { attack(); } }
void hurt(int n)  { for i from 1 to n { throw_items($item[new age hurting crystal],$item[new age hurting crystal]); } }
void heal_hurt()  { throw_items($item[new age healing crystal],$item[new age hurting crystal]); }

//dart stuff
skill butts(){
// +30% item drop
    int butts_int;
    matcher butts_matcher = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
    if (butts_matcher.find()){
        butts_int = butts_matcher.group(1).to_int();
    } else {
        butts_int = 0;
    }
    return to_skill(butts_int);
}
skill meatDart(){
    // +5X% Meat Drop, where X = min(11, dart level).
    matcher meat_matcher = create_matcher("(\\d+):(branch|door|foot|pseudopod|thorax|torso)\\b", get_property("_currentDartboard"));
    if (meat_matcher.find())
        return to_skill(meat_matcher.group(1).to_int());
    return $skill[none];
}
void dart() {
    while (to_int(get_property("_dartsLeft")) > 0 && current_round() > 0 && have_equipped($item[everfull dart holster])) {
        if (have_effect($effect[everything looks red]) == 0 && my_adventures() > 40)
            use_skill($skill[Darts: Aim for the Bullseye]);
        else if (have_skill(butts()))
            use_skill(butts());
        else if (have_skill(meatDart()))
            use_skill(meatDart());
        else
            use_skill($skill[Darts: Throw at %part1]);
    }
}

void farmingStuff(){
    dart();
    if (have_skill($skill[extract]))
        use_skill($skill[extract]);
    if (have_item($item[porquoise-handled sixgun]))
        throw_item($item[porquoise-handled sixgun]);
    if (have_item($item[pulled red taffy]))
        throw_item($item[pulled red taffy]);
}

void free_kill(string ptext) {
    foreach sk in $skills[Spit jurassic acid, Darts: Aim for the Bullseye] {
        if (contains_text(ptext, to_string(sk))) {
            if (sk == $skill[Darts: Aim for the Bullseye] && my_adventures() < 40)
                continue;
            if (sk == $skill[Spit jurassic acid] && my_adventures() < 10)
                continue;
            use_skill(sk);
            if (sk == $skill[Darts: Aim for the Bullseye])
                while (to_int(get_property("_dartsLeft")) > 0 && current_round() > 0) use_skill(sk);
        }
    }
    if (get_property("script") == "farto" || (get_property("script") == "FreeKill" && get_property("subscript") != "looseFK"))
        return;
    foreach sk in $skills[Assert your Authority, Fire the Jokester's Gun,
        BCZ: Sweat Bullets, Shattering Punch,
        Gingerbread Mob Hit, Club 'Em Back in Time] {
        if (my_location() == $location[hobopolis town square] && sk == $skill[Club 'Em Back in Time])
            continue;
        if (sk == $skill[BCZ: Sweat Bullets] && ((my_basestat($stat[submoxie]) - 62500) <= BCZcost("SweatBulletsCasts") || get_property("_bczSweatBulletsCasts").to_int() >= 13))
            continue;
        if (contains_text(ptext, to_string(sk))) {
            use_skill(sk);
        }
    }
    if (item_amount($item[interesting coin]) > 0 && get_property("_interestingCoinHeads") == "false"){
        while (get_property("_interestingCoinHeads") == "false" && current_round() > 0 && current_round() < 30)
            throw_item($item[interesting coin]);
    }
    if (available_amount($item[shadow brick]) > 0 && get_property("_shadowBricksUsed").to_int() < 13)
        throw_item($item[shadow brick]);
}

void free_run(string ptext) {
    if (last_monster() == $monster[Knob Goblin Embezzler])
        abort("Trying to run from an embezzler");
    foreach sk in $skills[spring away, snokebomb] {
        if (contains_text(ptext, to_string(sk))) {
            if (my_location() == $location[hobopolis town square] && sk == $skill[snokebomb]) continue;
            if (sk == $skill[spring away] && my_adventures() < 30) continue;
            use_skill(sk);
        }
    }
    if (my_familiar() == $familiar[pair of stomping boots] || ((my_familiar() == $familiar[comma chameleon] && get_property("commaFamiliar") == "Pair of Stomping Boots"))){
        print("HELLO WORLD");
        runaway();
    }
}

void insta_kill(string ptext) {
    set_property("choiceAdventure1589", 2);
    foreach sk in $skills[northern explosion, Club 'Em Into Next Week,
        Club 'Em Across the Battlefield, monkey slap] {
        if (sk == $skill[northern explosion]
            && (get_property("_aprilShowerNorthernExplosion") == "true"
                || !have_equipped($item[April Shower Thoughts shield])))
            continue;
        if (contains_text(ptext, to_string(sk))) use_skill(sk);
    }
}

skill [element] elementBonus = {
    $element[hot]:    $skill[Eggsplosion],
    $element[spooky]: $skill[Awesome Balls of Fire],
    $element[cold]:   $skill[Raise Backup Dancer],
    $element[sleaze]: $skill[Snowclone],
    $element[stench]: $skill[Grease Lightning]
};

string [item] basePairs = {
    $item[memory of a CT base pair]: "more attractive",
    $item[memory of a CG base pair]: "smarter",
    $item[memory of a CA base pair]: "stronger",
    $item[memory of a GT base pair]: "more resilient",
    $item[memory of an AT base pair]: "more aggressive",
    $item[memory of an AG base pair]: "faster"
};

// Lowest toy space helmet HP estimate seen in the current fight.
// Missing readings keep the saved value; -1 means no reading yet.
int helmetHP(string page_text) {
    if (current_round() == 0)
        return -1;

    string fightKey = get_property("_lastCombatStarted") + ":" + to_int(last_monster());
    int savedHP = -1;
    if (get_property("teresHelmetFightKey") == fightKey && get_property("teresHelmetLowestHP") != "")
        savedHP = get_property("teresHelmetLowestHP").to_int();

    string text = replace_all(create_matcher("<[^>]*>", page_text), " ");
    text = to_string(replace_string(text, "&nbsp;", " "));
    matcher hp_match = create_matcher("Opponent\\s+HP\\s*:\\s*([0-9][0-9,]*)", text);
    while (hp_match.find()) {
        int reading = to_int(to_string(replace_string(hp_match.group(1), ",", "")));
        if (savedHP < 0 || reading < savedHP)
            savedHP = reading;
    }

    // Keep the cache across consult calls; a new fight/opponent resets it.
    set_property("teresHelmetFightKey", fightKey);
    set_property("teresHelmetLowestHP", savedHP);
    // Debug: uncomment to show the saved HP each time this function is called.
    // print("Helmet HP -- round " + current_round() + ": " + savedHP, "blue");
    return savedHP;
}

// ─── CATEGORY SETS ────────────────────────────────────────────────────────────
// To add a new zone/monster to a category, just add it to the relevant set.
// No new else-if block needed.

// Zones where the entire combat is just saucegeyser x4
boolean [location] sauceLocs = {
    $location[Cyberzone 3]:                        true,
    $location[cyberzone 2]:                        true,
    $location[cyberzone 1]:                        true,
    $location[The Secret Government Laboratory]:   true,
    $location[Seaside Megalopolis]:                true,
    $location[The Jungles of Ancient Loathing]:    true,
    $location[The Bubblin' Caldera]:               true,
    $location[The Red Queen's Garden]:             true,
    $location[The Laugh Floor]:                    true,
    $location[Infernal Rackets Backstage]:         true,
    $location[Vanya's Castle]:                     true,
    $location[Megalo-City]:                     true,
    $location[Hero's Field]:                     true,
    $location[The Fungus Plains]:                     true
};

// Monsters where combat is just saucegeyser x4 regardless of location
boolean [monster] sauceMobs = {
    $monster[terrible mutant]:       true,
    $monster[slime blob]:            true,
    $monster[government bureaucrat]: true,
    $monster[angry ghost]:           true,
    $monster[annoyed snake]:         true,
    $monster[time cop]:              true
};

void sniff (monster mons){
    foreach sk in $skills[McHugeLarge Slash, Transcendent Olfaction, Gallapagosian Mating Call] {
        if (!have_skill(sk))
            continue;
        string tracked = get_property("trackedMonsters");
        string skill_name = sk.to_string();
        boolean skill_missing = !contains_text(tracked, ":" + skill_name + ":");
        boolean wrong_monster = false;
        if (!skill_missing) {
            matcher m = create_matcher("([^:]+):" + skill_name + ":\\d+", tracked);

            while (m.find()) {
                string mon = group(m, 1);

                if (mon != to_string(mons)) {
                    wrong_monster = true;
                    break;
                }
            }
        }
        if ((skill_missing || wrong_monster) && sk.timescast < sk.dailylimit) {
            use_skill(1, sk);
        }
    }
}

void cleanUp() {
    int loopCount = 0;
    while (current_round() > 0) {
        int round = current_round();
        use_skill($skill[saucegeyser]);
        if (round == current_round()) {
            loopCount += 1;
            if (loopCount > 3)
                abort("May be stuck in an infinite attack loop");
        }
    }
}

void waffleShadowGuy(){
    float itDropMult = item_drop_modifier( )/100 + 1;
    int shadowGuyValue = item_drops_array($monster[shadow guy])[0].rate/100 * itDropMult * mall_price(item_drops_array($monster[shadow guy])[0].drop);
    int avgPrice = (mall_price($item[shadow brick]) + mall_price($item[shadow stick]))/2;
    int otherGuyValue = (item_drops_array($monster[shadow slab])[0].rate/100 * itDropMult * avgPrice) - mall_price($item[waffle]);
    if (shadowGuyValue < otherGuyValue)
        throw_item($item[waffle]);
}

boolean free_location(){
    return $locations[cyberzone 3, cyberzone 2, cyberzone 1,The Red Zeppelin,An Unusually Quiet Barroom Brawl] contains my_location();
}

boolean free_monster() {
    if (contains_text(last_monster().attributes,"FREE"))
        return true;
    if (contains_text(last_monster().name,"hacker"))
        return true;
    if (my_location().zone == "Shadow Rift")
        return true;
    if (free_location())
        return true;
    return $monsters[black crayon golem, time cop,
        kid who is too old to be Trick-or-Treating,
        suburban security civilian, vandal kid,terrible mutant,
        slime blob,government bureaucrat,Moleman, giant sandworm] contains last_monster();
}

// Zones where the entire combat is just hurt(n) — new age hurting crystals
boolean [location] hurtLocs = {
    $location[the cursed village]: true
};

// Monsters where combat is just hurt(n)
boolean [monster] hurtMobs = {
    $monster[Beast with X Ears]: true,
    $monster[Beast with X Eyes]: true,
    $monster[X Bottles of Beer on a Golem]: true,
    $monster[Pharaoh Amoon-Ra Cowtep]:      true
};

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text) {
    int opponentHP = helmetHP(page_text);
    // print("Lowest helmet HP seen: " + opponentHP, "blue");

    print ("monster hp is " + last_monster().base_hp);
    print ("monster level is "+ numeric_modifier("monster level"));
    print ("high stat is " + max(my_buffedstat($stat[muscle]),my_buffedstat($stat[mysticality]),my_buffedstat($stat[moxie])));
    if (last_monster() == $monster[sausage goblin]){
        if (get_property("_monsterHabitatsFightsLeft") == 0 && to_int(get_property("_monsterHabitatsRecalled")) < 3){
            use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
        } else if (get_property("_monsterHabitatsFightsLeft") == 0 && get_property("beGregariousFightsLeft").to_int() == 0 && get_property("beGregariousCharges").to_int() > 0 && dayType() == 1){
            use_skill($skill[Be Gregarious]);
        }
        if (have_equipped($item[roman candelabra]))
            use_skill($skill[blow the purple candle!]);
    }
    if ($locations[Shadow Rift (The Misspelled Cemetary)] contains my_location()){
        if (get_property("_circadianRhythmsRecalled") == "false")
            use_skill($skill[RECALL FACTS: %PHYLUM CIRCADIAN RHYTHMS]);
    }
    if ($locations[cyberzone 1,cyberzone 2,cyberzone 3] contains my_location()){
        if (last_monster().phylum == $phylum[construct]){
            while (current_round() > 0 && current_round() < 10 && my_hp( ) > my_maxhp()/10)
                use_skill($skill[throw cyber rock]);
            if ($monsters[ICE barrier,corruption quarantine,parental controls,null container] contains last_monster())
                use_skill($skill[deploy glitched malware]);
            use_skill($skill[Launch Logic Grenade]);
        }
    }
    if ($location[The Hidden Bowling Alley] == my_location()){
        if (last_monster() == $monster[pygmy bowler]){
            use_skill($skill[Show them your ring]);
        }
        if (last_monster() == $monster[pygmy orderlies]){
            use_skill($skill[spring kick]);
            use_skill($skill[spring away]);
        }
        if (last_monster() == $monster[pygmy janitor]){
            use_skill($skill[Throw Latte on Opponent]);
        }
    }

    phylum [location] ScreechCheck = {
        $location[the briniest deepests]:$phylum[fish],
        $location[madness bakery]:$phylum[construct]
    };

    if (get_property("subscript") == "screech" && last_monster().phylum == ScreechCheck[my_location()]){
        if (contains_text(last_monster().attributes,"WANDERER"))
            abort("wanderer");
        use_skill($skill[%fn, Release the Patriotic Screech!]);
        print("Ya boi");
        if (dayType() == 1){
            print("Ya boi1");
            if (get_property("_snokebombUsed").to_int() < 3)
                use_skill($skill[snokebomb]);
            else
                throw_item($item[peppermint parasol]);
        } else {
            throw_item($item[stuffed yam stinkbomb]);
        }
        if (get_property("script") == "FreeKill") {
            free_run(page_text);
            if (current_round() > 0)
                abort("use free run");
        }
    }
    if (get_property("subscript") == "stompingBoots"){
        if (last_monster() == $monster[infinite meat bug])
            abort();
        runaway();
    }

    if (last_monster() == $monster[shadow spire]){
        if (current_round() > 0)
            use_skill($skill[saucegeyser]);
    }
    if (last_monster() == $monster[shadow orrery]){
        attack(30);
    }

    // ── Group: comma chameleon / stocking mimic, subscript "weakling", script "FreeKill" ──
    // The generic pre-combat buffs (avalanche/spikolodon/reanimate/bowling-ball/kill-a-lot)
    // are kept ahead of this whole group so they still apply before every branch in it, same
    // as they did before this section existed as its own block.
    if (last_monster() != $monster[shadow scythe] && last_monster() != $monster[shadow spire] && last_monster() != $monster[Guard turtle]) {
        if (have_skill($skill[McHugeLarge Avalanche]))         use_skill($skill[McHugeLarge Avalanche]);
        if (have_skill($skill[Launch spikolodon spikes]))      use_skill($skill[Launch spikolodon spikes]);
        if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
        if (item_amount($item[cosmic bowling ball]) > 0){
            use_skill($skill[Bowl Straight Up]);
        }
        if (to_int(last_monster()) == to_int(get_property("killThisGuy")) && get_property("swordSniff") == true)
            use_skill($skill[%fn, kill a lot of these guys]);
    }

    if (get_property("script") == "FreeKill" && have_equipped($item[backup camera]) && get_property("lastCopyableMonster") == "Black Crayon Mer-kin"){
        use_skill($skill[BACK-UP TO YOUR LAST ENEMY]);
        if (last_monster() == $monster[black crayon mer-kin]){
            while (my_familiar() == $familiar[chest mimic] && to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 50){
                use_skill($skill[%FN, LAY AN EGG]);
            }
        }
    }

    if (get_property("script") == "FreeKill")
        use_skill($skill[Steal Monster's Heart]);

    if ((my_familiar() == $familiar[comma chameleon] || my_familiar() == $familiar[stocking mimic]) && (last_monster() == $monster[flaming monstera] || last_monster() == $monster[leaviathan])){
        while (current_round() > 0 && current_round() < 10 && monster_hp() > 9)
            throw_item($item[facsimile dictionary]);
        throw_items($item[lit leaf lasso],$item[lit leaf lasso]);
        if (current_round() > 0)
            abort();
    }

    if (get_property("subscript") == "weakling"){
        if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
        while (current_round() > 0 && current_round() < 30 && monster_hp() > 9){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            else{
                throw_item($item[facsimile dictionary]);
                if (current_round() > 10)
                    break;
            }
            if (my_hp() < 100)
                throw_items($item[new age healing crystal],$item[new age healing crystal]);
        }
        if (last_monster() == $monster[eldritch tentacle])
            sauce(4);
        if (last_monster() == $monster[flaming leaflet])
            throw_items($item[lit leaf lasso],$item[lit leaf lasso]);
        if (last_monster() == $monster[Ron "The Weasel" Copperhead]){
            use_skill($skill[Club 'Em Back in Time]);
            while (current_round() > 0 && current_round() < 30){
                attack();
            }
        }
        if (my_location() == $location[the red zeppelin] && get_property("_glarkCableUses").to_int() < 5 && get_property("NCtoC") == "false")
            throw_item($item[glark cable]);
        if (my_location() == $location[Gingerbread Upscale Retail District] || my_location() == $location[Gingerbread civic center]){
            if (last_monster().phylum == $phylum[dude])
                throw_item($item[gingerbread cigarette]);
            else if (last_monster() == $monster[eldritch tentacle]){
                while (current_round() > 0 && current_round() < 30)
                    use_skill($skill[shieldbutt]);
            }
        }
        if (have_equipped($item[congressional medal of insanity]))
            use_skill($skill[saucegeyser]);
        while (current_round() > 0 && current_round() < 30 && monster_hp() > 9){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            else
                attack();
        }
        while (current_round() < 30 && current_round() > 0){
            throw_item($item[facsimile dictionary]);
        }
        if (item_amount($item[dry noodles]) > 0)
            use_skill($skill[carbohydrate cudgel]);
        else
            abort();
        return;
    }

    if ((my_familiar() == $familiar[comma chameleon] || my_familiar() == $familiar[stocking mimic]) && last_monster() == $monster[black crayon flower]){
        use_skill($skill[lecture on relativity]);
        use_skill($skill[Tear Away your Pants!]);
        if (dayType() == 1)
            use_skill($skill[deliver your thesis!]);
        if (my_hp() < 500)
            throw_items($item[new age healing crystal],$item[new age healing crystal]);
        sauce(3);
        return;
    }

    if ((my_familiar() == $familiar[comma chameleon] || my_familiar() == $familiar[stocking mimic]) && get_property("script") == "FreeKill"){
        if (my_location().zone == "Shadow Rift")
            use_skill($skill[swoop like a bat]);
        while (current_round() > 0 && current_round() < 30 && monster_hp() > 9 && have_equipped($item[april shower thoughts shield])){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            if (my_hp() < 100)
                throw_items($item[new age healing crystal],$item[new age healing crystal]);
        }
        if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
        while (current_round() > 0 && current_round() < 10){
            throw_item($item[facsimile dictionary]);
            if (have_effect($effect[everything looks purple]) == 0 && have_equipped($item[roman candelabra]))
                use_skill($skill[blow the purple candle!]);
            if (last_monster() == $monster[black crayon mer-kin]){
                if (item_amount($item[pulled green taffy]) > 0 && item_amount($item[envyfish egg]) == 0 && get_property("_envyfishEggUsed") == "false")
                    throw_item($item[pulled green taffy]);
                if (item_amount($item[4-d camera]) > 0 && item_amount($item[shaking 4-d camera]) == 0 && get_property("_cameraUsed") == "false")
                    throw_item($item[4-d camera]);
            }
            if ((my_location().environment == "underwater" || my_location() == to_location(get_property("_seadentWaveZone"))) && !contains_text(get_property("_lastCombatActions"),"it6367")){
                if (item_amount($item[pulled red taffy]) > 0)
                    throw_item($item[pulled red taffy]);
            }
            if (my_hp() < 200)
                throw_items($item[new age healing crystal],$item[new age healing crystal]);
        }
        if (my_location() == $location[Gingerbread Civic Center])
            throw_item($item[gingerbread cigarette]);
        if ((my_basestat($stat[submysticality]) - 62500) > BCZcost("GazeCasts") && last_monster() == $monster[shadow guy])
            use_skill($skill[BCZ: Refracted Gaze]);
        else if (last_monster() == $monster[shadow guy])
            waffleShadowGuy();
        if (get_property("subscript") == "looseFK" && have_equipped($item[mafia pointer finger ring]) && current_round() < 28)
            attack();
        if (get_property("subscript") == "looseFK" && (get_property("_curveballMonster").to_monster() != last_monster() || get_property("_curveballFightsLeft").to_int() == 0) && last_monster().boss == false)
            free_kill(page_text);
        if (get_property("_curveballMonster").to_monster() == last_monster() && get_property("_curveballFightsLeft").to_int() > 0){
            sauce(5);
            use_skill($skill[carbohydrate cudgel]);
        }
        if (get_property("subscript") == "looseFK" && current_round() > 0 && last_monster().boss == false &&(my_location() != $location[Shadow Rift (The Misspelled Cemetary)] || have_effect($effect[shadow affinity]) == 0))
            abort();
        if (current_round() > 0 && current_round() < 10)
            abort();
        if (last_monster() == $monster[spawn of wally])
            attack(10);
        sauce(20);
        return;
    }
    if (last_monster() == $monster[witchess bishop] || last_monster() == $monster[sausage goblin] || last_monster() == $monster[witchess rook] || last_monster() == $monster[witchess pawn] || last_monster() == $monster[witchess knight]) {
        if (have_effect($effect[everything looks purple]) == 0) use_skill($skill[Blow the Purple Candle!]);
        use_skill($skill[Club 'Em Into Next Week]); sauce(2); attack(5); return;
    }

    // ── Category: pure sauce locations ────────────────────────────────────────
    if (sauceLocs[my_location()] || sauceMobs[last_monster()]) {
        if (!free_monster() && !free_location()){
            free_run(page_text);
        }
        if (my_location() == $location[The Laugh Floor] || my_location() == $location[Infernal Rackets Backstage]){
            if (dayType() == 0 && my_class() == $class[seal clubber]){
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                if (last_monster() != $monster[some fish])
                    abort("talk to some fish didn't work for some reason");
            }
        }
        sauce(7);
        attack();
        attack();
        attack();
        return;
    }

    if (get_property("BoFaWishRWB") == "true"){
        use_skill($skill[%fn, fire a Red, White and Blue Blast]);
    }

    if (last_monster() == $monster[%monster%] && last_monster() == $monster[God Lobster]){
        sauce(5);
        return;
    }

    // ── Category: pure hurt locations/monsters ────────────────────────────────
    if (hurtLocs[my_location()] || hurtMobs[last_monster()]) {
        while (current_round() > 0) hurt(1);
        return;
    }

    // Garbo
    if (my_location() == $location[barf mountain]){
        if (have_skill($skill[pocket crumbs]) && to_int(get_property("_pantsgivingCrumbs")) < 9)
            use_skill($skill[pocket crumbs]);
        if (my_familiar() == $familiar[patriotic eagle])
            use_skill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]);
        if (last_monster() == $monster[garbage tourist] && to_int(get_property("_knuckleboneDrops")) == 100){
            sniff($monster[garbage tourist]);
        } else if (last_monster() == $monster[angry tourist] && to_int(get_property("_knuckleboneDrops")) < 100){
            sniff($monster[angry tourist]);
        }
        free_kill(page_text);
        free_run(page_text);
        dart();
        cleanUp();
        return;
    }

    if ($locations[cyberzone 1, cyberzone 2,cyberzone 3] contains my_location()){
        if (have_equipped($item[heartstone]) && (last_monster() == $monster[greyhat hacker] || last_monster() == $monster[bluehat hacker]))
            use_skill($skill[Steal Monster's Heart]);
        if (get_property("_cyberFreeFights").to_int() == 9)
            use_skill($skill[sea *dent: throw a lightning bolt]);
        sauce(5);
        return;
    }

    if (my_location() == $location[the red zeppelin]){
        if (to_int(get_property("_glarkCableUses")) < 5)
            throw_item($item[glark cable]);
        if (last_monster() == $monster[red skeleton]){
            sauce(5);
        }
        if (current_round() != 0)
            abort();
        return;
    }

    // ── Category: Dread (Woods, Village, Castle share opener) ─────────────────
    if ($locations[Dreadsylvanian Woods, Dreadsylvanian Village,
        Dreadsylvanian Castle] contains my_location()) {
        free_run(page_text);
        free_kill(page_text);
        if (last_monster() != $monster[hot werewolf])
            dart();
        if (have_skill($skill[Slay the Dead])) use_skill($skill[Slay the Dead]);
        insta_kill(page_text);
        boolean paw = get_property("_monkeyPawWishesUsed") == "0"
            && have_equipped($item[cursed monkey's paw]);

        if (my_location() == $location[Dreadsylvanian Woods]) {
            if (paw && last_monster() == $monster[hot werewolf]) { use_skill($skill[monkey slap]); return; }
            if (paw) { use_skill($skill[monkey slap]); return; }
            if (contains_text(to_string(last_monster().name),"bugbear")) {
                if (contains_text(to_string(last_monster().name),"cold"))
                    use_skill($skill[Carbohydrate Cudgel]);
                attack(9);
                return; }
            if (contains_text(to_string(last_monster().name),"werewolf")) {
                if (!contains_text(to_string(last_monster().name),"sleaze"))
                    attack(2);
                for i from 1 to 5 { use_skill(elementBonus[monster_element()]); }
                return;
            }

        } else if (my_location() == $location[Dreadsylvanian Village]) {
            if (paw) { use_skill($skill[monkey slap]); return; }
            sauce(6);
            return;

        } else if (my_location() == $location[Dreadsylvanian Castle]) {
            if (paw) { use_skill($skill[monkey slap]); return; }
            if (contains_text(to_string(last_monster().name),"skeleton")
                || contains_text(to_string(last_monster().name),"vampire")) {
                if (have_effect($effect[chilled to the bone]) > 0
                    && contains_text(to_string(last_monster().name),"skeleton"))
                    throw_item($item[shadow brick]);
                for i from 1 to 10 { use_skill(elementBonus[monster_element()]); }
                use_skill($skill[stuffed mortar shell]);
                attack(3); sauce(3); attack(24);
                return;
            }
            sauce(1);
            return;
        }
    }

    // ── Category: Hobopolis ───────────────────────────────────────────────────
    if (my_location().zone == "Hobopolis") {
        if (last_monster() == $monster[Frosty]) {
            throw_items($item[cinnamon troll doll],       $item[grape troll doll]);
            throw_items($item[blue raspberry troll doll], $item[bag of gross foreign snacks]);
            throw_items($item[crazy hobo notebook],       $item[hedgeturtle]);
            for i from 1 to 11 {
                throw_items($item[d8], $item[d8]);
                if (my_hp() < 100) throw_items($item[new age healing crystal], $item[d8]);
            }
            if (monster_hp() <= 18) attack();
            return;
        }
        if (last_monster() == $monster[Ol' Scratch] || last_monster() == $monster[Oscus] || last_monster() == $monster[Chester]) {
            for i from 1 to 7 { use_skill($skill[snowclone]); }
            return;
        }
        if (last_monster() == $monster[zombo]) {
            for i from 1 to 13 { hurt(1); if (my_hp() < 250) heal_hurt(); }
            return;
        }
        if (my_location() == $location[A Maze of Sewer Tunnels]) {
            steal();
            if (get_property("cleeshSewers") == "true"){
                if (last_monster() == $monster[giant zombie goldfish])
                    use_skill($skill[spring kick]);
                use_skill($skill[Sea *dent: Talk to some fish]);
                if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
            }
            if (last_monster() == $monster[giant zombie goldfish]) {
                use_skill($skill[spring kick]); free_run(page_text); sauce(2); return;
            }

            if (last_monster() == $monster[Sewer gator]) {
                use_skill($skill[Sea *dent: Throw a Lightning Bolt]); sauce(2); return;
            }
            free_run(page_text);
            free_kill(page_text);
            attack(); use_skill($skill[saucegeyser]); attack(); sauce(2); attack(3);
        } else if (my_location() == $location[Hobopolis Town Square]) {
            free_run(page_text);
            free_kill(page_text);
            if ($strings[boots,skulls,eyes,crotches,guts] contains get_property("parts_collection")) {
                use_skill($skill[Stuffed Mortar Shell]);
                throw_item($item[seal tooth]);
            } else if (get_property("parts_collection") == "skins") {
                use_skill($skill[Lunging Thrust-Smack]);
            }
        } else if (my_location() == $location[Exposure Esplanade]) {
            free_run(page_text);
            free_kill(page_text);
            insta_kill(page_text);
            set_property("choiceAdventure1589","1&victim=690");
            sauce(4);
        } else if (my_location() == $location[The Ancient Hobo Burial Ground]) {
            free_run(page_text);
            free_kill(page_text);
            attack(15);
        } else if ($locations[The Purple Light District, The Heap,Burnbarrel Blvd.] contains my_location()) {
            if ((my_location() == $location[The Purple Light District] && to_int(get_property("PLD_left")) >= 50 && get_property("cleeshPLD") == "true") ||
            (my_location() == $location[The Heap]) && get_property("cleeshHeap") == "true"){
                use_skill($skill[Sea *dent: Talk to some fish]);
                if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
            }
            free_run(page_text);
            free_kill(page_text);
            sauce(4);
        }
        return;
    }

    // Spacegate
    if (my_location() == $location[Through the Spacegate]){
        if (last_monster() == $monster[spant soldier])
            abort();
        sauce(6);
        return;
    }

    // ── Category: FantasyRealm ────────────────────────────────────────────────
    if (my_location().zone == "FantasyRealm") {
        if (my_location() == $location[The Barrow Mounds])  { runaway(); return; }
        if (my_location() == $location[The Troll Fortress]) { for i from 1 to 4 { use_skill($skill[Awesome Balls of Fire]); } return; }
        if (last_monster() == $monster[Flock of every birds])          { for i from 1 to 9 { use_skill($skill[garbage nova]); } return; }
        if (last_monster() == $monster[crypt creeper])                 { for i from 1 to 6 { throw_items($item[gauze garter],$item[gauze garter]); } return; }
        if (last_monster() == $monster[Sewage Treatment Dragon])       { for i from 1 to 3 { throw_items($item[new age healing crystal],$item[new age hurting crystal]); } return; }
        if ($monsters[plywood cultists, Ley Incursion, quadfaerie] contains last_monster()) { attack(24); return; }
        sauce(4);
        return;
    }

    // ── Category: Gingerbread City ────────────────────────────────────────────
    if (my_location().zone == "Gingerbread City") {
        if ($monsters[gingerbread convict, gingerbread finance bro,
            gingerbread gentrifier, gingerbread lawyer,
            gingerbread tech bro, judge fudge] contains last_monster()
            && item_amount($item[gingerbread cigarette]) > 0)
            throw_item($item[gingerbread cigarette]);
        sauce(9);
        return;
    }

    // ── Category: Glaciest ────────────────────────────────────────────────────
    if (my_location().zone == "The Glaciest") {
        free_run(page_text);
        free_kill(page_text);
        if (my_location() == $location[the ice hotel]) {
            if (last_monster() == $monster[ice concierge]) {
                if (!contains_text(get_property("trackedMonsters"),"ice concierge:McHugeLarge Slash"))
                    use_skill($skill[MCHUGELARGE SLASH]);
                if (!contains_text(get_property("trackedMonsters"),"ice concierge:Transcendent Olfaction"))
                    use_skill($skill[TRANSCENDENT OLFACTION]);
            }
            if (get_property("walfordBucketItem") == "blood") attack();
            if (get_property("walfordBucketItem") == "ice")   use_skill($skill[Weapon of the Pastalord]);
            use_skill($skill[saucegeyser]);
        }
        if ($locations[the ice hole, VYKEA] contains my_location()) sauce(4);
        return;
    }

    // ── Category: Spring Break Beach ────────────────────────────────────────────────────
    if (my_location().zone == "Spring Break Beach") {
        if (my_location() == $location[The Fun-Guy Mansion]) {
                float minHP = to_float(my_maxhp())*0.8872;
                if (my_hp() < minHP){
                    throw_item($item[new age healing crystal]);
                }
                if (!free_monster())
                    free_kill(page_text);
                use_skill($skill[Saucegeyser]);
                throw_item($item[new age hurting crystal]);
                attack();
        }
        if (my_location() == $location[Sloppy Seconds Diner]) {
            if (last_monster() == $monster[Sloppy Seconds Sundae]){
                if (!contains_text(get_property("trackedMonsters"),"Sloppy Seconds Sundae:Transcendent Olfaction")){
                    use_skill($skill[Transcendent Olfaction]);
                }
                if (!contains_text(get_property("trackedMonsters"),"Sloppy Seconds Sundae:McHugeLarge Slash")){
                    use_skill($skill[McHugeLarge Slash]);
                }
                if (!contains_text(get_property("trackedMonsters"),"Sloppy Seconds Sundae:Gallapagosian Mating Call")){
                    use_skill($skill[Gallapagosian Mating Call]);
                }
            }
            if (contains_text(get_property("banishedMonsters"),"broctopus") && last_monster() == $monster[broctopus]){
                use_skill($skill[spring kick]);
            }
            if (!free_monster())
                free_kill(page_text);
            use_skill($skill[stuffed mortar shell]);
            use_skill($skill[Saucegeyser]);
            use_skill($skill[Saucegeyser]);
        }
        if (my_location() == $location[The Sunken Party Yacht]) {
            if (!contains_text(get_property("banishedMonsters"),"broctopus") && have_effect($effect[fishy]) >= 20){
                use_skill($skill[spring kick]);
            }
            if (!free_monster())
                free_kill(page_text);
            use_skill($skill[stuffed mortar shell]);
            use_skill($skill[Saucegeyser]);
            use_skill($skill[Saucegeyser]);
        }
        return;
    }

    // The Sea
    if (my_location() == $location[The Marinara Trench]){
        if (last_monster() == $monster[giant squid] && my_class() == $class[accordion thief]){
            sniff($monster[giant squid]);
        }
    }

    // ── Individual locations / monsters ───────────────────────────────────────

    if (last_monster() == $monster[black crayon spiraling shape]){
        while (my_familiar() == $familiar[chest mimic] && to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 100){
            use_skill($skill[%fn, lay an egg]);
        }
        sauce(6);
        return;
    }

    if (last_monster() == $monster[giant sandworm]){
        sauce(6);
        return;
    }
    if (my_location()== $location[Convention Hall Lobby]){
        while (current_round() > 0){
            throw_item($item[bottle of G&uuml;-Gone]);
        }
        return;
    }

    if (my_location()== $location[The Outer Compound]){
        while (current_round() > 0){
            use_skill($skill[Apprivoisez la tortue]);
        }
        return;
    }

    if (my_location() == $location[The Slime Tube]) {
        // After a uvula is tickled we carry the rusty grave robbing shovel to
        // squeeze a gall bladder; doing so spends the shovel and empties the
        // weapon slot. Once it's gone, advance <clanId>Tickled to "done" so
        // slime.ash / preadventure.ash stop re-equipping it.
        if (get_property(get_clan_id() + "Tickled") == "tickled"){
            while (have_equipped($item[rusty grave robbing shovel]))
                throw_item($item[facsimile dictionary]);
            if (equipped_item($slot[weapon]) == $item[none])
                set_property(get_clan_id() + "Tickled","done");
        }
        // Mother Slime: stack Backup Dancers before the damage skills below.
        if (last_monster() == $monster[mother slime]){
            use_skill($skill[Raise Backup Dancer]);
            use_skill($skill[Raise Backup Dancer]);
        }
        free_kill(page_text); free_run(page_text); insta_kill(page_text);
        // Shadow bricks are the cheap kill while ML-farming on the purse rat.
        if (my_familiar() == $familiar[purse rat] && have_effect($effect[coated in slime]) > 10 && to_int(get_property("_shadowBricksUsed")) < 13){
            throw_item($item[shadow brick]);
        }
        for i from 1 to 4 {
            if (my_hp() < 500 && my_hp() < my_maxhp()/2)
                throw_items($item[new age healing crystal],$item[new age healing crystal]);
            use_skill($skill[weapon of the pastalord]);
        }
        return;
    }

    if (my_location() == $location[Domed City of Grimacia]) {
        if (last_monster().phylum == $phylum[horror])
            use_skill($skill[%fn, Release the Patriotic Screech!]);
        else {
            if (to_int(get_property("_mildEvilPerpetrated")) < 3) use_skill($skill[perpetrate mild evil]);
            if (to_int(get_property("_batWingsSwoopUsed")) < 11)  use_skill($skill[swoop like a bat]);
            while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == "false")
                use_skill($skill[douse foe]);
        }
        sauce(5); return;
    }

    if (my_location() == $location[The Broodling Grounds]) {
        if (last_monster() == $monster[hellseal pup]) {
            throw_item($item[seal tooth]);
            throw_item($item[seal tooth]);
            throw_item($item[seal tooth]);
        }
        attack(3); return;
    }

    if (my_location() == $location[The Brinier Deepers]) {
        if (last_monster() == $monster[trophyfish]) abort();
        return;
    }
    if (my_location() == $location[Mer-kin Elementary School]) {
        if (contains_text(get_property("banishedMonsters"),"hacker"))
            use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
    }
    if (my_location() == $location[cobb's knob treasury]){
        if (last_monster() == $monster[Knob Goblin Embezzler])
            attack(5);
        else
            free_run(page_text);
    }
    if (my_location() == $location[the black forest]){
        free_kill(page_text);
    }
    if (my_location() == $location[the coral corral]){
        if (!contains_text(get_property("banishedPhyla"), "fish")){
            if (last_monster() == $monster[mer-kin rustler])
                use_skill(combatBan());
            if (last_monster() == $monster[sea cowboy])
                use_skill(combatBan());
        }
        farmingStuff();
        attack();
        attack();
        attack();
        cleanUp();
        return;
    }

    if (my_location() == $location[Shadow Rift (The Nearby Plains)]) {
        if (last_monster() == $monster[shadow scythe]) sauce(2);
        if (last_monster() == $monster[shadow orrery])
            attack(20);
        if (last_monster() == $monster[shadow matrix])
            sauce(6);
        if (last_monster().elemental_resistance > 85){
            free_kill(page_text);
            free_run(page_text);
            for i from 1 to 20 {
                use_skill($skill[snowclone]);
            }
        } else
            sauce(20);
        return;
    }
    if (my_location() == $location[Shadow Rift (The Misspelled Cemetary)]) {
        steal();
        if (last_monster() == $monster[shadow scythe]) abort();
        if (last_monster() == $monster[shadow orrery]) {
            attack(20);
        }
        if (last_monster() == $monster[shadow matrix]) {
            sauce(6);
        }
        if (last_monster().boss == true){
            cleanUp();
        }
        if (last_monster() == $monster[shadow guy]){
            if (have_equipped($item[blood cubic zirconia])){
                use_skill($skill[BCZ: Refracted Gaze]);
                use_skill($skill[swoop like a bat]);
            }
            while (to_int(get_property("_douseFoeUses")) < 3
                && get_property("_douseFoeSuccess") == "false"
                && current_round() < 25 && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory]))
                use_skill($skill[douse foe]);
        } else if (have_equipped($item[bat wings])){
            use_skill($skill[swoop like a bat]);
        }
        if (get_property("script") == "FreeKill"){
            cleanUp();
        }
        free_run(page_text);
        free_kill(page_text);
        cleanUp();
        return;
    }

    if (my_location() == $location[The Spooky Forest]) { abort("Check spikolodon or else run"); free_run(page_text); return; }
    if (my_location() == $location[The Outskirts of Cobb's Knob]) { free_run(page_text);}

    if (my_location() == $location[Investigating a Plaintive Telegram]) {
        if (last_monster() == $monster[Former Sheriff Dan Driscoll])  attack(18);
        if (last_monster() == $monster[Snake-Eyes Glenn])             for i from 1 to 6 { use_skill($skill[grease lightning]); }
        if (last_monster() == $monster[Clara])                        for i from 1 to 6 { use_skill($skill[eggsplosion]); }
        if (last_monster() == $monster[Pharaoh Amoon-Ra Cowtep])      hurt(4);
        if (last_monster() == $monster[cow cultist]
            && contains_text(get_property("lastEncounter"),"reprehensible"))
            for i from 1 to 3 { use_skill($skill[toynado]); }
        sauce(6); return;
    }

    if (my_location() == $location[The Primordial Soup]) {
        if (last_monster() == $monster[Cyrus the Virus]) {
            foreach it in $items[memory of a CT base pair, memory of a CG base pair,
                memory of a CA base pair, memory of a GT base pair,
                memory of an AT base pair, memory of an AG base pair] {
                if (item_amount(it) > 0
                    && !contains_text(get_property("cyrusAdjectives"), basePairs[it]))
                    throw_item(it);
            }
        }
        sauce(3); return;
    }

    if (my_location() == $location[the deep dark jungle]) {
        if (get_property("_questESp") == "questESpSmokes") {
            if (last_monster() != $monster[smoke monster] && last_monster() != $monster[Mercenary of Fortune])
                use_skill(combatBan());
            sauce(3);
        }
        if (get_property("_questESp") == "questESpOutOfOrder") {
            if (last_monster() != $monster[Mercenary of Fortune]) use_skill(combatBan());
            sauce(3);
        }
        return;
    }

    if (my_location() == $location[The Mansion of Dr. Weirdeaux]) {
        if (get_property("_questESp") == "questESpClipper")
            for i from 1 to 3 { throw_item($item[military-grade fingernail clippers]); }
        sauce(3); return;
    }

    if (my_location() == $location[The Tower of Procedurally-Generated Skeletons]) {
        if (contains_text(get_property("lastEncounter"),"shiny")
            || contains_text(get_property("lastEncounter"),"disorienting")) {
            if (contains_text(get_property("lastEncounter"),"dancing")) abort();
            if (contains_text(get_property("lastEncounter"),"ghostly"))
                for i from 1 to 3 { throw_items($item[boozebomb],$item[boozebomb]); }
            hurt(6);
        } else {
            sauce(6);
        }
        return;
    }

    if (my_location() == $location[the nightmare meatrealm]) {
        use_skill($skill[spring away]); runaway(); return;
    }

    if ($strings[Le Marais D&egrave;gueulasse] contains my_location().zone) {
        sauce(3); return;
    }

    // ── Fallback ──────────────────────────────────────────────────────────────
    insta_kill(page_text);
    sauce(30);
    attack();
}
