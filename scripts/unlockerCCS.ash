import iotm.ash;

// ─── COMBAT RESOURCE FLAGS ─────────────────────────────────────────────────────
// A resource can have several flags. These describe capabilities, not readiness:
// equipment, charges, cooldowns, target restrictions and success still need checking.
// freeRun: ends combat without a kill or a spent adventure.
// freeKill: kills without spending an adventure; yellowRay: forces eligible item drops.
// banish: excludes a monster/phylum; it does not necessarily end combat or save a turn.
record combatResourceFlags {
    boolean freeRun;
    boolean banish;
    boolean freeKill;
    boolean yellowRay;
};

// Constructor order:                                      freeRun, banish, freeKill, yellowRay
combatResourceFlags[skill] skillResourceFlags = {
    $skill[Spit Jurassic Acid]:            new combatResourceFlags(false, false, true,  true),
    $skill[Darts: Aim for the Bullseye]:    new combatResourceFlags(false, false, true,  false),
    $skill[Assert your Authority]:         new combatResourceFlags(false, false, true,  false),
    $skill[Fire the Jokester's Gun]:        new combatResourceFlags(false, false, true,  false),
    $skill[BCZ: Sweat Bullets]:             new combatResourceFlags(false, false, true,  false),
    $skill[Shattering Punch]:              new combatResourceFlags(false, false, true,  false),
    $skill[Gingerbread Mob Hit]:           new combatResourceFlags(false, false, true,  false),
    $skill[Club 'Em Back in Time]:         new combatResourceFlags(false, false, true,  false),
    $skill[Spring Away]:                   new combatResourceFlags(true,  false, false, false),
    $skill[Snokebomb]:                     new combatResourceFlags(true,  true,  false, false),
    $skill[Spring Kick]:                   new combatResourceFlags(true,  true,  false, false),
    $skill[Throw Latte on Opponent]:       new combatResourceFlags(true,  true,  false, false),
    $skill[Monkey Slap]:                   new combatResourceFlags(false, true,  false, false),
    $skill[%fn, Release the Patriotic Screech!]: new combatResourceFlags(false, true, false, false),
    $skill[Sea *dent: Throw a Lightning Bolt]:   new combatResourceFlags(false, true, false, false),
    $skill[Heartstone: %banish]:            new combatResourceFlags(false, true,  false, false)
};
combatResourceFlags[item] itemResourceFlags = {
    $item[spitball]:                       new combatResourceFlags(false, false, true,  true),
    $item[peppermint parasol]:             new combatResourceFlags(true,  false, false, false),
    $item[stuffed yam stinkbomb]:          new combatResourceFlags(true,  true,  false, false),
    $item[divine champagne popper]:        new combatResourceFlags(true,  true,  false, false),
    $item[interesting coin]:               new combatResourceFlags(false, false, true,  false),
    $item[shadow brick]:                   new combatResourceFlags(false, false, true,  false)
};

// Examples: skillResourceFlags[$skill[Spit Jurassic Acid]].freeKill
//           skillResourceFlags[$skill[Spit Jurassic Acid]].yellowRay
//           itemResourceFlags[$item[stuffed yam stinkbomb]].banish

// ─── HELPERS ──────────────────────────────────────────────────────────────────

void sauce(int n) { for i from 1 to n { if (current_round() == 0) return; use_skill($skill[saucegeyser]); } }
void attack(int n) { for i from 1 to n { if (current_round() == 0) return; attack(); } }
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
        if (sk == $skill[Fire the Jokester's Gun] && get_property("_firedJokestersGun").to_boolean())
            continue;
        if (sk == $skill[Assert your Authority] && get_property("_assertYourAuthorityCast").to_int() >= 3)
            continue;
        if (my_location() == $location[hobopolis town square] && sk == $skill[Club 'Em Back in Time])
            continue;
        if (sk == $skill[BCZ: Sweat Bullets] && !sweatBulletsReady(62500))
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
    if (current_round() == 0)
        return;
    if (last_monster() == $monster[Knob Goblin Embezzler])
        abort("Trying to run from an embezzler");
    foreach sk in $skills[spring away, snokebomb] {
        if (current_round() == 0)
            return;
        if (contains_text(ptext, to_string(sk))) {
            if (sk == $skill[snokebomb] && get_property("_snokebombUsed").to_int() >= 3) continue;
            if (sk == $skill[spring away] && my_adventures() < 30) continue;
            use_skill(sk);
        }
    }
    // Parasol, navel ring, and GAP share this counter: only the first 3 are guaranteed.
    if (current_round() > 0 && get_property("_navelRunaways").to_int() < 3
        && item_amount($item[peppermint parasol]) > 0){
        throw_item($item[peppermint parasol]);
        if (current_round() > 0)
            print("[DEBUG] Peppermint parasol did not end combat; continuing.", "red");
    }
    // stuffed yam stinkbomb
    if (current_round() > 0 && item_amount($item[stuffed yam stinkbomb]) > 0){
        throw_item($item[stuffed yam stinkbomb]);
        if (current_round() > 0)
            print("[DEBUG] Stuffed yam stinkbomb did not end combat; continuing.", "red");
    }
    // divine champagne popper
    if (current_round() > 0 && item_amount($item[divine champagne popper]) > 0){
        throw_item($item[divine champagne popper]);
        if (current_round() > 0)
            print("[DEBUG] Divine champagne popper did not end combat.", "red");
    }
    if (current_round() > 0)
        abort("We ran out of free run sources. Aborting.");
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

// Copy the requested monster with mimic/4-d/green taffy.
void copyMonster(monster target){
    if (last_monster() != target || current_round() == 0)
        return;
        // Green taffy can create an envyfish egg only during an underwater fight.
    if (my_location().environment == "underwater" && !get_property("_envyfishEggUsed").to_boolean()
        && item_amount($item[envyfish egg]) == 0 && item_amount($item[pulled green taffy]) > 0){
        throw_item($item[pulled green taffy]);
        if (item_amount($item[envyfish egg]) == 0)
            print("[DEBUG] Could not copy " + target + " with green taffy.", "red");
    }
        // 4-D camera
    if (!get_property("_cameraUsed").to_boolean() && item_amount($item[shaking 4-D camera]) == 0
        && item_amount($item[4-D camera]) > 0){
        throw_item($item[4-D camera]);
        if (item_amount($item[shaking 4-D camera]) == 0)
            print("[DEBUG] Could not copy " + target + " with the 4-D camera.", "red");
    }
        // Mimic eggs
    while (current_round() > 0 && my_familiar() == $familiar[chest mimic]
        && get_property("_mimicEggsObtained").to_int() < 10
        && $familiar[chest mimic].experience > 100){
        int eggsBefore = get_property("_mimicEggsObtained").to_int();
        use_skill($skill[%fn, lay an egg]);
        if (get_property("_mimicEggsObtained").to_int() <= eggsBefore){
            print("[DEBUG] Could not collect a mimic egg from " + target + "; continuing combat.", "red");
            break;
        }
    }
}

// Schedule roaming goblins with Habitat recalls first, then Be Gregarious.
void chainRoamingMonster(monster target){
    if (last_monster() != target || current_round() == 0)
        return;
    // Do not replace an existing Habitat or Gregarious chain.
    if (current_round() > 0
        && get_property("_monsterHabitatsFightsLeft").to_int() == 0
        && get_property("beGregariousFightsLeft").to_int() == 0){
        if (have_skill($skill[RECALL FACTS: MONSTER HABITATS])
            && get_property("_monsterHabitatsRecalled").to_int() < 3){
            use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
            if (get_property("_monsterHabitatsFightsLeft").to_int() == 0)
                print("[DEBUG] Could not schedule Habitat roaming copies of " + target + ".", "red");
        } else if (target == $monster[sausage goblin] && have_skill($skill[Be Gregarious])
            && get_property("beGregariousCharges").to_int() > 0){
            int chargesBefore = get_property("beGregariousCharges").to_int();
            use_skill($skill[Be Gregarious]);
            // Validate the saved result even when combat ends on the casting round.
            if (get_property("beGregariousMonster").to_monster() != target
                || get_property("beGregariousCharges").to_int() >= chargesBefore)
                print("[DEBUG] Could not schedule Gregarious roaming copies of " + target + ".", "red");
        }
    }
}

// Return true when a shadow boss was handled so main skips other combat actions.
boolean handleShadowRiftBoss(){
    // Handle these bosses before any free kills, runaways, or other combat actions.
    if ($monsters[shadow scythe, shadow spire] contains last_monster()) {
        while (current_round() > 0) {
            int roundBefore = current_round();
            use_skill($skill[Weapon of the Pastalord]);
            if (current_round() == roundBefore)
                abort("Weapon of the Pastalord failed against " + last_monster());
        }
        return true;
    }
    if (last_monster() == $monster[shadow orrery]){
        while (current_round() > 0){
            int roundBefore = current_round();
            attack();
            if (current_round() == roundBefore)
                abort("Weapon attack failed against shadow orrery.");
        }
        return true;
    }

    return false;
}

// Standard mimic stall: use only the dictionary until round 10.
// The caller chooses when to stall and how to finish combat afterward.
void standardMimicStall(){
    while (current_round() > 0 && current_round() < 10){
        int roundBefore = current_round();
        throw_item($item[facsimile dictionary]);
        if (current_round() == roundBefore){
            print("[DEBUG] Could not stall " + last_monster() + " with the facsimile dictionary; continuing combat.", "red");
            break;
        }
    }
}

// ─── FREEKILL: COMMON COMBAT ACTIONS ───────────────────────────────────────────

void prepareFreeKillCombat(){
    if (current_round() == 0)
        return;
    else {
        if (have_skill($skill[McHugeLarge Avalanche])) use_skill($skill[McHugeLarge Avalanche]);
        if (current_round() > 0 && have_skill($skill[Launch spikolodon spikes])) use_skill($skill[Launch spikolodon spikes]);
        if (current_round() > 0 && have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
        if (current_round() > 0 && item_amount($item[cosmic bowling ball]) > 0)
            use_skill($skill[Bowl Straight Up]);
        if (current_round() > 0 && last_monster() == get_property("killThisGuy").to_monster()
            && get_property("swordSniff").to_boolean())
            use_skill($skill[%fn, kill a lot of these guys]);
    }
    if (current_round() > 0 && have_skill($skill[Steal Monster's Heart]))
        use_skill($skill[Steal Monster's Heart]);
}

// Stocking Mimic preparation shared by its normal fights and location handlers.
void prepareStockingMimicCombat(){
    // Plants tear-away
    if (current_round() > 0 && last_monster() == $monster[black crayon flower]
        && have_skill($skill[Tear Away your Pants!]))
        use_skill($skill[Tear Away your Pants!]);
    // Reanimate
    if (current_round() > 0 && have_skill($skill[Prepare to reanimate your Foe]))
        use_skill($skill[Prepare to reanimate your Foe]);
    // red taffy if underwater or flooded  -- maybe move this somewhere global in the future so we can just do this regardless of familiar
    if (current_round() > 0 && my_location() != $location[none]
        && (my_location().environment == "underwater"
        || my_location() == to_location(get_property("_seadentWaveZone")))
        && !contains_text(get_property("_lastCombatActions"), "it6367")
        && item_amount($item[pulled red taffy]) > 0)
        throw_item($item[pulled red taffy]);
    // Stall with facsimile
    int stallUntil = last_monster() == $monster[sausage goblin] ? 11 : 10;
    while (current_round() > 0 && current_round() < stallUntil){
        int roundBefore = current_round();
        throw_item($item[facsimile dictionary]);
        if (current_round() == roundBefore){
            print("[DEBUG] Could not stall Stocking Mimic with the dictionary; continuing combat.", "red");
            break;
        }
        if (current_round() > 0 && my_hp() < 200)
            throw_items($item[new age healing crystal], $item[new age healing crystal]);
    }
}

// Free-kill resources and the final attack, after any location-specific actions.
void finishStockingMimicCombat(string page_text, boolean requireFreeKill){
    if (current_round() == 0)
        return;
    boolean isLooseFK = get_property("subscript") == "looseFK";
    if (isLooseFK){
        if (have_equipped($item[mafia pointer finger ring]) && current_round() < 28)
            attack();
        if (current_round() > 0 && !last_monster().boss
            && (get_property("_curveballMonster").to_monster() != last_monster()
                || get_property("_curveballFightsLeft").to_int() == 0))
            free_kill(page_text);
    }
    // Curveball finishing also applies outside looseFK.
    if (current_round() > 0 && get_property("_curveballMonster").to_monster() == last_monster()
        && get_property("_curveballFightsLeft").to_int() > 0){
        sauce(5);
        if (current_round() > 0)
            use_skill($skill[carbohydrate cudgel]);
    }
    if (isLooseFK && current_round() > 0
        && !last_monster().boss && requireFreeKill)
        abort("Free-kill action did not end combat.");
    if (current_round() > 0 && current_round() < 10)
        print("[DEBUG] Stocking Mimic did not reach round 10; continuing to the kill.", "red");
    if (current_round() > 0 && last_monster() == $monster[spawn of wally])
        attack(10);
    // Default finish after stalling: Saucegeyser, or weapon attacks if unavailable.
    if (current_round() > 0){
        if (have_skill($skill[Saucegeyser])){
            sauce(5);
            attack(10);
        }
        else
            attack(20);
    }
}

boolean handleStockingMimicCombat(string page_text){
    if (my_familiar() != $familiar[stocking mimic])
        return false;
    prepareStockingMimicCombat();
    finishStockingMimicCombat(page_text, true);
    return true;
}

// Coldform / shard-of-double-ice fights retain their separate weakling strategy.
void prepareWeaklingCombat(){
    if (current_round() > 0 && have_skill($skill[Prepare to reanimate your Foe]))
        use_skill($skill[Prepare to reanimate your Foe]);
    while (current_round() > 0 && current_round() < 30 && monster_hp() > 9){
        int roundBefore = current_round();
        if (have_equipped($item[april shower thoughts shield]))
            use_skill($skill[shieldbutt]);
        else
            throw_item($item[facsimile dictionary]);
        if (current_round() == roundBefore){
            print("[DEBUG] Weakling preparation failed; continuing combat.", "red");
            break;
        }
        if (!have_equipped($item[april shower thoughts shield]) && current_round() > 10)
            break;
        if (current_round() > 0 && my_hp() < 100)
            throw_items($item[new age healing crystal], $item[new age healing crystal]);
    }
    if (current_round() > 0 && last_monster() == $monster[eldritch tentacle])
        sauce(4);
    if (current_round() > 0 && last_monster() == $monster[flaming leaflet])
        throw_items($item[lit leaf lasso], $item[lit leaf lasso]);
    if (current_round() > 0 && last_monster() == $monster[Ron "The Weasel" Copperhead]){
        use_skill($skill[Club 'Em Back in Time]);
        while (current_round() > 0 && current_round() < 30){
            int roundBefore = current_round();
            attack();
            if (current_round() == roundBefore){
                print("[DEBUG] Attack failed against The Weasel; continuing combat.", "red");
                break;
            }
        }
    }
}

void finishWeaklingCombat(){
    if (current_round() > 0 && have_equipped($item[congressional medal of insanity]))
        use_skill($skill[saucegeyser]);
    while (current_round() > 0 && current_round() < 30 && monster_hp() > 9){
        int roundBefore = current_round();
        if (have_equipped($item[april shower thoughts shield]))
            use_skill($skill[shieldbutt]);
        else
            attack();
        if (current_round() == roundBefore){
            print("[DEBUG] Weakling attack failed; continuing combat.", "red");
            break;
        }
    }
    while (current_round() > 0 && current_round() < 30){
        int roundBefore = current_round();
        throw_item($item[facsimile dictionary]);
        if (current_round() == roundBefore){
            print("[DEBUG] Weakling dictionary stall failed; continuing to the kill.", "red");
            break;
        }
    }
    if (current_round() == 0)
        return;
    if (item_amount($item[dry noodles]) > 0)
        use_skill($skill[carbohydrate cudgel]);
    else
        abort("No dry noodles available for the weakling free kill.");
}

// ─── FREEKILL: LOCATIONS AND COMBAT MODES ───────────────────────────────────────

// Bosses remain immediate exceptions; regular Rift fights are handled here in one place.
boolean handleShadowRiftCombat(string page_text){
    if (my_location() != $location[Shadow Rift (The Misspelled Cemetary)])
        return false;
    standardMimicStall();
    if (current_round() == 0)
        return true;
    if (!get_property("_circadianRhythmsRecalled").to_boolean())
        use_skill($skill[RECALL FACTS: %PHYLUM CIRCADIAN RHYTHMS]);
    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    steal();
    if (my_familiar() == $familiar[stocking mimic]){
        if (have_equipped($item[bat wings]))
            use_skill($skill[swoop like a bat]);
        prepareStockingMimicCombat();
        if (current_round() > 0 && last_monster() == $monster[shadow guy]){
            if ((my_basestat($stat[submysticality]) - 62500) > BCZcost("GazeCasts"))
                use_skill($skill[BCZ: Refracted Gaze]);
            else
                waffleShadowGuy();
        }
        finishStockingMimicCombat(page_text, have_effect($effect[shadow affinity]) == 0);
        return true;
    }
    // Preserve the previous Rift handling for other familiars.
    if (current_round() > 0 && last_monster() == $monster[shadow matrix])
        sauce(6);
    if (current_round() > 0 && !last_monster().boss){
        if (last_monster() == $monster[shadow guy]){
            if (have_equipped($item[blood cubic zirconia])){
                use_skill($skill[BCZ: Refracted Gaze]);
                if (current_round() > 0 && have_equipped($item[bat wings]))
                    use_skill($skill[swoop like a bat]);
            }
            while (current_round() > 0 && current_round() < 25
                && get_property("_douseFoeUses").to_int() < 3
                && !get_property("_douseFoeSuccess").to_boolean()
                && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory])){
                int roundBefore = current_round();
                use_skill($skill[douse foe]);
                if (current_round() == roundBefore){
                    print("[DEBUG] Douse Foe failed; continuing combat.", "red");
                    break;
                }
            }
        } else if (have_equipped($item[bat wings]))
            use_skill($skill[swoop like a bat]);
    }
    cleanUp();
    return true;
}

boolean handleCyberzoneCombat(string page_text){
    if (!($locations[cyberzone 1, cyberzone 2, cyberzone 3] contains my_location()))
        return false;
    if (last_monster().phylum == $phylum[construct]){
        while (current_round() > 0 && current_round() < 10 && my_hp() > my_maxhp()/10){
            int roundBefore = current_round();
            use_skill($skill[throw cyber rock]);
            if (current_round() == roundBefore){
                print("[DEBUG] Throw Cyber Rock failed; continuing combat.", "red");
                break;
            }
        }
        if (current_round() > 0 && $monsters[ICE barrier, corruption quarantine, parental controls, null container] contains last_monster())
            use_skill($skill[deploy glitched malware]);
        if (current_round() > 0)
            use_skill($skill[Launch Logic Grenade]);
    }
    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        finishWeaklingCombat();
    } else if (!handleStockingMimicCombat(page_text)){
        sauce(7);
        attack(3);
    }
    return true;
}

// Failed pygmy banishes fall through to normal familiar combat.
boolean handleBowlingAlleyCombat(){
    if (my_location() != $location[The Hidden Bowling Alley])
        return false;
    if (last_monster() == $monster[pygmy bowler]){
        throw_item($item[stuffed yam stinkbomb]);
        if (current_round() > 0)
            print("[DEBUG] Failed to banish the pygmy bowler with a stuffed yam stinkbomb.", "red");
    } else if (last_monster() == $monster[pygmy orderlies]){
        use_skill($skill[Throw Latte on Opponent]);
        if (current_round() > 0)
            print("[DEBUG] Failed to banish pygmy orderlies with Throw Latte on Opponent.", "red");
    } else if (last_monster() == $monster[pygmy janitor]){
        if (get_property("subscript") == "drunkPygmy")
            print("[DEBUG] Unexpected pygmy janitor: check janitor relocation for this ascension; continuing combat.", "red");
        else
            use_skill($skill[Snokebomb]);
    }
    return current_round() == 0;
}

boolean handleScreechCombat(string page_text){
    phylum[location] screechPhylum = {
        $location[the briniest deepests]: $phylum[fish],
        $location[madness bakery]: $phylum[construct]
    };
    if (get_property("subscript") != "screech" || !(screechPhylum contains my_location())
        || last_monster().phylum != screechPhylum[my_location()])
        return false;
    if (contains_text(last_monster().attributes, "WANDERER")){
        print("[DEBUG] Hit a WANDERER while trying to screech something.", "red");
        attack(30);
        if (current_round() == 0)
            return true;
    }
    print("Ya boi screeching a " + last_monster() + " . . . ", "blue");
    string screechResponse = to_string(use_skill($skill[%fn, Release the Patriotic Screech!]));
    if (!contains_text(screechResponse, "releases an ear shattering screech"))
        print("[DEBUG] Patriotic Screech failed; attempting the free run.", "red");
    free_run(page_text);
    return true;
}
// Script dispatch decides whether to free-run or continue combat after pledging.
boolean handleEaglePledgeCombat(string page_text, boolean freeRunAfterPledge){
    if (get_property("subscript") != "eaglePledge")
        return false;
    if (my_familiar() != $familiar[patriotic eagle])
        abort("Eagle pledge combat requires the Patriotic Eagle.");
    if (have_effect($effect[Citizen of a Zone]) == 0
        || get_property("_citizenZone") != to_string(my_location())){
        page_text = to_string(use_skill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]));
    }
    if (have_effect($effect[Citizen of a Zone]) == 0
        || get_property("_citizenZone") != to_string(my_location()))
        abort("Eagle pledge failed; combat is paused for inspection.");
    if (freeRunAfterPledge){
        if (current_round() > 0)
            free_run(page_text);
        return true;
    }
    return current_round() == 0;
}


boolean handleGingerbreadCombat(string page_text){
    if (my_location().zone != "Gingerbread City")
        return false;
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        if (current_round() > 0 && ($locations[Gingerbread Upscale Retail District, Gingerbread Civic Center] contains my_location())){
            if (last_monster().phylum == $phylum[dude])
                throw_item($item[gingerbread cigarette]);
            else if (last_monster() == $monster[eldritch tentacle]){
                while (current_round() > 0 && current_round() < 30){
                    int roundBefore = current_round();
                    use_skill($skill[shieldbutt]);
                    if (current_round() == roundBefore){
                        print("[DEBUG] Gingerbread Shieldbutt failed; continuing combat.", "red");
                        break;
                    }
                }
            }
        }
        finishWeaklingCombat();
    } else if (my_familiar() == $familiar[stocking mimic]){
        prepareStockingMimicCombat();
        if (current_round() > 0 && my_location() == $location[Gingerbread Civic Center])
            throw_item($item[gingerbread cigarette]);
        finishStockingMimicCombat(page_text, true);
    } else {
        if ($monsters[gingerbread convict, gingerbread finance bro, gingerbread gentrifier,
            gingerbread lawyer, gingerbread tech bro, judge fudge] contains last_monster()
            && item_amount($item[gingerbread cigarette]) > 0)
            throw_item($item[gingerbread cigarette]);
        if (current_round() > 0)
            sauce(9);
    }
    return true;
}

boolean handleRedZeppelinCombat(string page_text){
    if (my_location() != $location[The Red Zeppelin])
        return false;
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        if (current_round() > 0 && get_property("_glarkCableUses").to_int() < 5 && !get_property("NCtoC").to_boolean())
            throw_item($item[glark cable]);
        finishWeaklingCombat();
    } else if (!handleStockingMimicCombat(page_text)){
        if (get_property("_glarkCableUses").to_int() < 5)
            throw_item($item[glark cable]);
        if (current_round() > 0 && last_monster() == $monster[red skeleton])
            sauce(5);
        if (current_round() > 0)
            abort("Red Zeppelin free kill did not end combat.");
    }
    return true;
}

boolean handleDomedCityCombat(string page_text){
    if (my_location() != $location[Domed City of Grimacia])
        return false;
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        finishWeaklingCombat();
    } else if (!handleStockingMimicCombat(page_text)){
        if (last_monster().phylum == $phylum[horror])
            use_skill($skill[%fn, Release the Patriotic Screech!]);
        else {
            if (get_property("_mildEvilPerpetrated").to_int() < 3)
                use_skill($skill[perpetrate mild evil]);
            if (current_round() > 0 && get_property("_batWingsSwoopUsed").to_int() < 11)
                use_skill($skill[swoop like a bat]);
            while (current_round() > 0 && get_property("_douseFoeUses").to_int() < 3
                && !get_property("_douseFoeSuccess").to_boolean()){
                int roundBefore = current_round();
                use_skill($skill[douse foe]);
                if (current_round() == roundBefore){
                    print("[DEBUG] Domed City Douse Foe failed; continuing combat.", "red");
                    break;
                }
            }
        }
        if (current_round() > 0)
            sauce(5);
    }
    return true;
}

// Existing FreeKill turn-burning recipe; future script=BARF combat remains separate.
boolean handleFreeKillBarfMountainCombat(string page_text){
    if (my_location() != $location[barf mountain])
        return false;
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        finishWeaklingCombat();
    // if script=freekill and location is barf mountain, we want to use_skill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]); and then use a free run
    } else if (!handleStockingMimicCombat(page_text)){
        if (my_familiar() == $familiar[patriotic eagle])
            use_skill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]);
        if (current_round() > 0 && last_monster() == $monster[garbage tourist] && get_property("_knuckleboneDrops").to_int() == 100)
            sniff($monster[garbage tourist]);
        else if (current_round() > 0 && last_monster() == $monster[angry tourist] && get_property("_knuckleboneDrops").to_int() < 100)
            sniff($monster[angry tourist]);
        if (current_round() > 0)
            free_kill(page_text);
        if (current_round() > 0)
            free_run(page_text);
        if (current_round() > 0)
            dart();
        cleanUp();
    }
    return true;
}

// ─── FREEKILL: MONSTER EXCEPTIONS ──────────────────────────────────────────────

boolean handleFlamingPlantCombat(){
    if (my_familiar() != $familiar[stocking mimic]
        || !($monsters[flaming monstera, leaviathan] contains last_monster()))
        return false;
    while (current_round() > 0 && current_round() < 10 && monster_hp() > 9){
        int roundBefore = current_round();
        throw_item($item[facsimile dictionary]);
        if (current_round() == roundBefore){
            print("[DEBUG] Flaming plant dictionary stall failed; continuing to the lasso.", "red");
            break;
        }
    }
    if (current_round() > 0)
        throw_items($item[lit leaf lasso], $item[lit leaf lasso]);
    if (current_round() > 0)
        abort("Lit leaf lasso did not end the flaming plant fight.");
    return true;
}

// Goblins use the same copy -> roaming setup -> kill order in every location.
boolean handleSausageGoblinCombat(string page_text){
    if (last_monster() != $monster[sausage goblin])
        return false;
    copyMonster($monster[sausage goblin]);
    chainRoamingMonster($monster[sausage goblin]);
    // Chest Mimic copies eggs; only Stocking Mimic uses purple-candle chaining.
    if (current_round() > 0 && my_familiar() == $familiar[stocking mimic]
        && have_effect($effect[everything looks purple]) == 0
        && have_equipped($item[roman candelabra]))
        use_skill($skill[blow the purple candle!]);
    boolean stockingMimic = my_familiar() == $familiar[stocking mimic];
    if (stockingMimic)
        prepareStockingMimicCombat();
    // Other familiars cast after copying; Stocking Mimic waits until round 11.
    if (current_round() > 0 && (!stockingMimic || current_round() >= 11)
        && have_skill($skill[Club 'Em Into Next Week])
        && get_property("_clubEmNextWeekUsed").to_int() < 5)
        use_skill($skill[Club 'Em Into Next Week]);
    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    if (stockingMimic)
        finishStockingMimicCombat(page_text, true);
    else {
        if (current_round() > 0)
            sauce(2);
        if (current_round() > 0)
            attack(5);
    }
    return true;
}

boolean handleSandwormCombat(string page_text){
    if (last_monster() != $monster[giant sandworm])
        return false;
    if (!handleStockingMimicCombat(page_text))
        sauce(6);
    return true;
}

// ─── SCRIPT DISPATCHERS ───────────────────────────────────────────────────────

// True means a handler claimed the fight; false allows the shared rules below.
boolean handleFreeKillCombat(string page_text){
    if (handleEaglePledgeCombat(page_text, true))
        return true;
    if (handleShadowRiftBoss())
        return true;

    // Handle roaming goblins before the location that their fight interrupted.
    if (handleSausageGoblinCombat(page_text)) return true;

    // Banish setup precedes ordinary damage skills.
    if (handleScreechCombat(page_text)) return true;
    if (handleBowlingAlleyCombat()) return true;

    // These location handlers own their opening actions and familiar differences.
    if (handleShadowRiftCombat(page_text)) return true;
    if (handleCyberzoneCombat(page_text)) return true;

    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    if (handleFlamingPlantCombat()) return true;
    if (handleGingerbreadCombat(page_text)) return true;
    if (handleRedZeppelinCombat(page_text)) return true;
    if (handleDomedCityCombat(page_text)) return true;
    if (handleFreeKillBarfMountainCombat(page_text)) return true;

    // Remaining weakling fights keep priority over normal familiar combat.
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        finishWeaklingCombat();
        return true;
    }
    if (handleSandwormCombat(page_text)) return true;
    if (handleStockingMimicCombat(page_text)) return true;
    if (last_monster() == $monster[God Lobster]){
        sauce(5);
        return true;
    }
    return false;
}

// BARF combat placeholder. False means shared combat handling can continue.
boolean handleBARFCombat(string page_text){
    if (handleEaglePledgeCombat(page_text, false))
        return true;
    // TODO: Add BARF farming combat rules here.
    return false;
}

// ─── SHARED GENERAL COMBAT ────────────────────────────────────────────────────

boolean handleGeneralCombat(string page_text){
    if (sauceLocs[my_location()] || sauceMobs[last_monster()]){
        if (!free_monster() && !free_location()){
            free_run(page_text);
            return true;
        }
        sauce(7);
        attack(3);
        return true;
    }
    // Final fallback is shared by every script.
    if (current_round() > 0)
        sauce(10);
    if (current_round() > 0)
        attack(20);
    return true;
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text){
    if (current_round() == 0)
        return;

    helmetHP(page_text);
    print("monster hp is " + last_monster().base_hp);
    print("monster level is " + numeric_modifier("monster level"));
    print("high stat is " + max(my_buffedstat($stat[muscle]), my_buffedstat($stat[mysticality]), my_buffedstat($stat[moxie])));

    if (get_property("script") == "FreeKill"){
        if (handleFreeKillCombat(page_text))
            return;
    } else if (get_property("script") == "BARF"){
        if (handleBARFCombat(page_text))
            return;
    }
    if (current_round() == 0)
        return;
    handleGeneralCombat(page_text);
}
