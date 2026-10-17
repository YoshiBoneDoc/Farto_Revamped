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
    $skill[Show them your ring]:          new combatResourceFlags(true,  true,  false, false),
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

// Age the last conservative helmet reading between reports. Only refresh the
// fight page when a missing report puts us close to the finishing cutoff.
int weaklingHPBound = -1;
boolean weaklingIced = false;
int weaklingHPRound = -1;
string weaklingHPFightKey;
int weaklingMissingGrace = -1;

int weaklingDamageAllowance(){
    int chip = icedChipDamage();
    if (weaklingIced)
        return chip;
    // Without the cold alignment, Coldform can still deliver a large hit.
    int regularDamage = to_int(ceil(max(0.0, numeric_modifier("Damage Aura"))
        + max(0.0, numeric_modifier("Sporadic Damage Aura"))
        + max(0.0, numeric_modifier("Thorns"))));
    if (have_effect($effect[Coldform]) > 0){
        int highStat = max(my_buffedstat($stat[muscle]), my_buffedstat($stat[mysticality]), my_buffedstat($stat[moxie]));
        // This is a regular-round allowance, not combat-item damage.
        regularDamage += max(1, to_int(ceil(highStat * monsterLevelDamageMultiplier()
            * coldDamageMultiplier(last_monster()))));
    }
    return max(chip, regularDamage);
}

boolean weaklingCanStall(){
    if (weaklingMissingGrace >= 0)
        return weaklingIced && weaklingMissingGrace > 0 && weaklingHPBound > 9;
    // Leave enough HP for one more damage round plus the original 9-HP reserve.
    return weaklingHPBound > 9 + weaklingDamageAllowance();
}

void updateWeaklingHP(string page_text, int extraDamage){
    if (current_round() == 0)
        return;
    string fightKey = get_property("_lastCombatStarted") + ":" + to_int(last_monster());
    if (weaklingHPFightKey != fightKey){
        weaklingHPFightKey = fightKey;
        // Until the first helmet report, use the pre-fight database estimate.
        // Missing reports then age this bound instead of discarding it.
        weaklingHPBound = last_monster().base_hp > 0
            ? max(0, to_int(floor(last_monster().base_hp * 0.925))
                - max(0, current_round() - 1) * weaklingDamageAllowance()) : -1;
        weaklingHPRound = current_round();
        weaklingMissingGrace = -1;
    }
    // After three failed refreshes, iced fights may stall up to two more rounds.
    for attempt from 0 to 3 {
        int hp = helmetHP(page_text);
        string text = replace_all(create_matcher("<[^>]*>", page_text), " ");
        text = to_string(replace_string(text, "&nbsp;", " "));
        matcher reading = create_matcher("Opponent\\s+HP\\s*:\\s*([0-9][0-9,]*)", text);
        if (hp >= 0 && reading.find()){
            weaklingHPBound = to_int(floor(hp * 0.925));
            weaklingHPRound = current_round();
            weaklingMissingGrace = -1;
            return;
        }
        int elapsedRounds = max(0, current_round() - weaklingHPRound);
        if (weaklingHPBound >= 0)
            weaklingHPBound = max(0, weaklingHPBound
                - elapsedRounds * weaklingDamageAllowance() - extraDamage);
        weaklingHPRound = current_round();
        extraDamage = 0;
        // Do not repeat the refresh attempts during or after the grace rounds.
        if (weaklingMissingGrace >= 0){
            weaklingMissingGrace = max(0, weaklingMissingGrace - elapsedRounds);
            return;
        }
        if (weaklingHPBound > 9 + 2 * weaklingDamageAllowance())
            return;
        if (attempt == 3 || current_round() == 0)
            break;
        // GET with no action: refresh the report without taking a combat round.
        page_text = visit_url("fight.php", false);
    }
    if (weaklingIced && weaklingHPBound > 9)
        weaklingMissingGrace = 2;
    else
        weaklingHPBound = -1;
}

void updateWeaklingHP(string page_text){
    updateWeaklingHP(page_text, 0);
}

boolean lateCombatWarningPrinted = false;

boolean shieldMicrophoneFight(){
    return !last_monster().boss && weaklingIced
        && have_equipped($item[April Shower Thoughts shield]) && have_skill($skill[Shieldbutt])
        && have_skill($skill[Ambidextrous Funkslinging])
        && get_property("subscript") != "looseFK" && my_location().zone != "Gingerbread City"
        && (my_location() != $location[Shadow Rift (The Misspelled Cemetary)]
            || $strings[shadowAffinity, shadowForcers] contains get_property("subscript")
            || have_effect($effect[Shadow Affinity]) > 0);
}

int weaklingFinisherRound(){
    // Required free kills get rounds 25-30 for Hat Trick retries.
    if(get_property("subscript")=="looseFK")return 25;
    return shieldMicrophoneFight() && item_amount($item[droppable microphone]) > 0 ? 26 : 28;
}

void throwLateMicrophones(){
    while (shieldMicrophoneFight() && current_round() >= 29 && current_round() <= 30){
        int microphones = item_amount($item[droppable microphone]);
        if (microphones == 0){
            print("No droppable microphones remain; continuing with the normal finisher.", "red");
            return;
        }
        int before = current_round();
        print("Round " + before + ": throwing " + min(2, microphones) + " droppable microphone(s).", "blue");
        string response = microphones >= 2
            ? to_string(throw_items($item[droppable microphone], $item[droppable microphone]))
            : to_string(throw_item($item[droppable microphone]));
        if (weaklingIced && current_round() > 0) updateWeaklingHP(response);
        if (current_round() == before){
            print("Droppable microphones did not advance combat; continuing with the normal finisher.", "red");
            return;
        }
    }
}

void warnLateCombat(){
    if (current_round() >= 30 && !lateCombatWarningPrinted){
        print("Warning: " + last_monster() + " is still alive at round " + current_round()
            + "; continuing combat despite the risk of losing.", "red");
        lateCombatWarningPrinted = true;
    }
}

// Retry only hat-blocked actions; other failures retain the caller's checks.
string freeKillUseState(skill action);
string combatSkill(skill action){
    if(current_round()==0)return "";
    string used=skillResourceFlags[action].freeKill?freeKillUseState(action):"";
    while(current_round()>0){
        throwLateMicrophones();
        if(current_round()==0)return "";
        warnLateCombat();
        int before=current_round();
        string response=to_string(use_skill(action));
        if(weaklingIced && current_round()>0)updateWeaklingHP(response);
        if(skillResourceFlags[action].freeKill&&freeKillUseState(action)!=used)return response;
        string text=replace_all(create_matcher("<[^>]*>",response)," ").to_lower_case();
        boolean distracted=contains_text(text,"too distracted")
            || (my_path()==$path[Hat Trick] && contains_text(text,"distracted"));
        if(!distracted || current_round()==0)return response;
        if(current_round()==before)abort("Hat-blocked "+action+" made no combat progress; combat paused.");
        if(action==$skill[Shieldbutt] && current_round()>=weaklingFinisherRound())return response;
        if(current_round()<30 && weaklingIced && !weaklingCanStall()
            && !skillResourceFlags[action].freeKill && action!=$skill[Carbohydrate Cudgel])
            abort("Hat-blocked "+action+" cannot safely retry before the finisher; combat paused.");
        print("Hats blocked "+action+"; retrying at round "+current_round()+".","blue");
    }
    return "";
}

void backupSpell(int n) { for i from 1 to n { if (current_round() == 0) return; combatSkill($skill[Weapon of the Pastalord]); } }
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
            combatSkill($skill[Darts: Aim for the Bullseye]);
        else if (have_skill(butts()))
            combatSkill(butts());
        else if (have_skill(meatDart()))
            combatSkill(meatDart());
        else
            combatSkill($skill[Darts: Throw at %part1]);
    }
}

void farmingStuff(){
    dart();
    if (have_skill($skill[extract]))
        combatSkill($skill[extract]);
    if (have_item($item[porquoise-handled sixgun]))
        throw_item($item[porquoise-handled sixgun]);
    if (have_item($item[pulled red taffy]))
        throw_item($item[pulled red taffy]);
}

string freeKillUseState(skill action){
    if(action==$skill[Spit Jurassic Acid])return to_string(have_effect($effect[Everything Looks Yellow])>0);
    if(action==$skill[Darts: Aim for the Bullseye])return to_string(have_effect($effect[Everything Looks Red])>0);
    string[skill] counters={
        $skill[Assert your Authority]:"_assertYourAuthorityCast",$skill[Fire the Jokester's Gun]:"_firedJokestersGun",
        $skill[BCZ: Sweat Bullets]:"_bczSweatBulletsCasts",$skill[Shattering Punch]:"_shatteringPunchUsed",
        $skill[Gingerbread Mob Hit]:"_gingerbreadMobHitUsed",$skill[Club 'Em Back in Time]:"_clubEmTimeUsed"};
    return get_property(counters[action]);
}

boolean freeKillSkillReady(skill action){
    // Use Mafia's current combat skill list, not names in the opening fight page.
    // Known/granted skills also count: the parsed combat list can omit them.
    if(!have_skill(action))return false;
    if(action==$skill[Spit Jurassic Acid])return my_adventures()>=10&&have_effect($effect[Everything Looks Yellow])==0;
    if(action==$skill[Darts: Aim for the Bullseye])return my_adventures()>=40&&have_effect($effect[Everything Looks Red])==0&&get_property("_dartsLeft").to_int()>0;
    if(action==$skill[Assert your Authority])return get_property("_assertYourAuthorityCast").to_int()<3;
    if(action==$skill[Fire the Jokester's Gun])return !get_property("_firedJokestersGun").to_boolean();
    if(action==$skill[BCZ: Sweat Bullets])return sweatBulletsReady(62500);
    if(action==$skill[Shattering Punch])return get_property("_shatteringPunchUsed").to_int()<3;
    if(action==$skill[Gingerbread Mob Hit])return !get_property("_gingerbreadMobHitUsed").to_boolean();
    return action==$skill[Club 'Em Back in Time]&&get_property("_clubEmTimeUsed").to_int()<5
        &&my_location()!=$location[Hobopolis Town Square];
}

void retryFreeKillSkill(skill action){
    string used=freeKillUseState(action);
    print("Free kill: trying "+action+" at round "+current_round()+".","blue");
    while(current_round()>0&&freeKillSkillReady(action)){
        int before=current_round();
        combatSkill(action);
        // A spent source must not consume another daily charge in this fight.
        if(current_round()==0||freeKillUseState(action)!=used)return;
        if(current_round()==before){
            print("Free kill "+action+" made no combat progress; trying the fallback finisher.","red");
            return;
        }
        print("Free kill "+action+" has not registered; retrying while it remains available.","blue");
    }
}

void finishFreeKillFallback(){
    if(current_round()==0)return;
    print("Free-kill source is spent or unavailable; finishing with Carbohydrate Cudgel and continuing.","red");
    if(!have_skill($skill[Carbohydrate Cudgel]))abort("Cannot finish the free-kill fight: Carbohydrate Cudgel is unavailable.");
    // Only this explicitly authorized recovery may explain a paid FK encounter.
    set_property("_teresFreeKillFallbackTurn",total_turns_played());
    while(current_round()>0){
        int before=current_round();
        combatSkill($skill[Carbohydrate Cudgel]);
        if(current_round()==before)abort("Carbohydrate Cudgel did not advance combat; inspect the fight.");
    }
}

void free_kill(string ptext) {
    if (current_round() > 0 && have_effect($effect[Everything Looks Blue]) == 0
        && item_amount($item[blue rocket]) > 0){
        throw_item($item[blue rocket]);
        if (have_effect($effect[Everything Looks Blue]) == 0)
            abort("Blue rocket did not grant Everything Looks Blue; combat paused.");
    }
    foreach sk in $skills[Spit jurassic acid, Darts: Aim for the Bullseye] {
        if (current_round() == 0)
            return;
        warnLateCombat();
        if (freeKillSkillReady(sk)) {
            retryFreeKillSkill(sk);
            return;
        }
    }
    if (get_property("script") == "farto" || (get_property("script") == "FreeKill" && get_property("subscript") != "looseFK"))
        return;
    foreach sk in $skills[Assert your Authority, Fire the Jokester's Gun,
        BCZ: Sweat Bullets, Shattering Punch,
        Gingerbread Mob Hit, Club 'Em Back in Time] {
        if (current_round() == 0)
            return;
        warnLateCombat();
        if (freeKillSkillReady(sk)) {
            retryFreeKillSkill(sk);
            return;
        }
    }
    if (current_round() > 0 && item_amount($item[interesting coin]) > 0 && get_property("_interestingCoinHeads") == "false"){
        while (get_property("_interestingCoinHeads") == "false" && current_round() > 0 && item_amount($item[interesting coin]) > 0){
            int before=current_round();warnLateCombat();
            throw_item($item[interesting coin]);
            if(current_round()==before)break;
        }
        return;
    }
    int bricksUsed=get_property("_shadowBricksUsed").to_int();
    while (current_round() > 0 && item_amount($item[shadow brick]) > 0 && bricksUsed < 13
        && get_property("_shadowBricksUsed").to_int()==bricksUsed){
        int before=current_round();warnLateCombat();
        throw_item($item[shadow brick]);
        if(current_round()==before)break;
    }
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
            combatSkill(sk);
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
        if (sk == $skill[Club 'Em Into Next Week] && (get_property("script") == "FreeKill" || !clubNextWeekReady()))
            continue;
        if (sk == $skill[northern explosion]
            && (get_property("_aprilShowerNorthernExplosion") == "true"
                || !have_equipped($item[April Shower Thoughts shield])))
            continue;
        if (contains_text(ptext, to_string(sk))) combatSkill(sk);
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

// Shared opening stall action. A failed attempt must not loop or spend finisher rounds.
boolean bowlStraightUpAttempted = false;
boolean bowlWaitingForShard = false;
boolean bowlStraightUpStall(boolean trackHP){
    if (current_round() == 0 || current_round() >= 28 || last_monster().boss
        || bowlStraightUpAttempted || bowlWaitingForShard || !have_skill($skill[Bowl Straight Up])
        || item_amount($item[cosmic bowling ball]) == 0
        || contains_text(get_property("_lastCombatActions"), "sk7407;"))
        return false;
    bowlStraightUpAttempted = true;
    int roundBefore = current_round();
    string response = to_string(combatSkill($skill[Bowl Straight Up]));
    if (trackHP && current_round() > 0)
        updateWeaklingHP(response);
    if (current_round() == roundBefore){
        print("Bowl Straight Up failed; continuing with the usual combat actions.", "red");
        return false;
    }
    return true;
}

// These handlers must transform/shard before the global opening stall action.
boolean deferBowlUntilOpener(){
    if (get_property("script") != "FreeKill")
        return false;
    if (get_property("subscript") == "habitatBunny" || shardCombatMode() || get_property("subscript") == "shadowForcers")
        return true;
    if (get_property("subscript") == "weakling")
        return true;
    if (my_location().zone == "Gingerbread City" && appearance_rates(my_location()) contains last_monster())
        return true;
    return my_location() == $location[Shadow Rift (The Misspelled Cemetary)]
        && my_familiar() == $familiar[stocking mimic]
        && (get_property("subscript") == "shadowAffinity" || get_property("subscript") == "looseFK");
}

void startWeaklingCombat(string page_text, boolean afterTransformation){
    if (!last_monster().boss && shardEyepatchRequired()
        && !have_equipped($item[PirateRealm eyepatch]))
        abort("Shard combat requires the PirateRealm eyepatch equipped; combat is paused before any action.");
    weaklingIced = have_effect($effect[Coldform]) > 0
        && (last_monster().defense_element == $element[cold]
            || (!afterTransformation && contains_text(get_property("_lastCombatActions"), "it5048;")));
    updateWeaklingHP(page_text);
    bowlWaitingForShard = false;
    if (current_round() >= 28 || weaklingIced || have_effect($effect[Coldform]) == 0 || last_monster().boss){
        return;
    }
    // Combat HP controls when to stop stalling, not whether to throw the opener.
    bowlWaitingForShard = true;
    if (item_amount($item[shard of double-ice]) > 0){
        int openingDamage = estimatedShardOpeningDamage(last_monster());
        if (get_property("teresCombatDebug").to_boolean())
            print("[Shard test] Opening: highest stat="
                + max(my_buffedstat($stat[muscle]), my_buffedstat($stat[mysticality]), my_buffedstat($stat[moxie]))
                + "; item bonus=" + numeric_modifier("Combat Item Damage Percent") + "% (not applied to this estimate)"
                + "; ML multiplier=" + monsterLevelDamageMultiplier()
                + "; defensive element=" + last_monster().defense_element
                + "; cold multiplier=" + coldDamageMultiplier(last_monster())
                + "; predicted burst=" + openingDamage
                + "; HP bound before=" + weaklingHPBound, "darkorange");
        int roundBefore = current_round();
        string response = to_string(throw_item($item[shard of double-ice]));
        weaklingIced = current_round() > roundBefore;
        bowlWaitingForShard = !weaklingIced;
        // A missing post-shard reading must account for the burst, not just chip.
        updateWeaklingHP(response, weaklingIced ? openingDamage : 0);
        if (get_property("teresCombatDebug").to_boolean())
            print("[Shard test] After opening: round=" + current_round()
                + "; iced=" + weaklingIced + "; HP bound=" + weaklingHPBound
                + "; per-round allowance=" + weaklingDamageAllowance()
                + "; can stall=" + (current_round() > 0 && weaklingCanStall()), "darkorange");
    }
    // Do not put another action ahead of a missing/failed required shard.
    if (current_round() > 0 && !weaklingIced)
        abort("Required ice-shard opener failed; combat is paused before other actions.");
}

void startWeaklingCombat(string page_text){
    startWeaklingCombat(page_text, false);
}

// ─── CATEGORY SETS ────────────────────────────────────────────────────────────
// To add a new zone/monster to a category, just add it to the relevant set.
// No new else-if block needed.

// Zones where the entire combat is just Weapon of the Pastalord x4
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

// Monsters where combat is just Weapon of the Pastalord x4 regardless of location
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
            combatSkill(sk);
        }
    }
}

void cleanUp() {
    int loopCount = 0;
    while (current_round() > 0) {
        int round = current_round();
        combatSkill($skill[Weapon of the Pastalord]);
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
    boolean useWaffle = shadowGuyValue < otherGuyValue && item_amount($item[waffle]) > 0;
    if (get_property("teresCombatDebug").to_boolean())
        print("[Shadow Rift] Shadow Guy loot estimate=" + shadowGuyValue
            + "; rerolled loot estimate after waffle cost=" + otherGuyValue
            + "; waffle available=" + (item_amount($item[waffle]) > 0)
            + "; use waffle=" + useWaffle, "darkorange");
    if (useWaffle)
        throw_item($item[waffle]);
}

boolean free_location(){
    return $locations[cyberzone 3, cyberzone 2, cyberzone 1,The Red Zeppelin] contains my_location();
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
        updateWeaklingHP(to_string(throw_item($item[pulled green taffy])));
        if (item_amount($item[envyfish egg]) == 0)
            print("[DEBUG] Could not copy " + target + " with green taffy.", "red");
    }
        // 4-D camera
    if (current_round() > 0 && !get_property("_cameraUsed").to_boolean() && item_amount($item[shaking 4-D camera]) == 0
        && item_amount($item[4-D camera]) > 0){
        updateWeaklingHP(to_string(throw_item($item[4-D camera])));
        if (item_amount($item[shaking 4-D camera]) == 0)
            print("[DEBUG] Could not copy " + target + " with the 4-D camera.", "red");
    }
        // Mimic eggs
    while (current_round() > 0 && current_round() < 28 && my_familiar() == $familiar[chest mimic]
        && (!weaklingIced || weaklingCanStall())
        && get_property("_mimicEggsObtained").to_int() < 10
        && $familiar[chest mimic].experience > 100){
        int eggsBefore = get_property("_mimicEggsObtained").to_int();
        updateWeaklingHP(to_string(combatSkill($skill[%fn, lay an egg])));
        if (get_property("_mimicEggsObtained").to_int() <= eggsBefore){
            print("[DEBUG] Could not collect a mimic egg from " + target + "; continuing combat.", "red");
            break;
        }
    }
}

// Retry Hat Trick distractions, validating Mafia's successful-use counter.
void combatCounterSkill(skill action, string counter){
    string before = get_property(counter);
    boolean barfSniffing = get_property("script") == "BARF"
        && $skills[Transcendent Olfaction,Gallapagosian Mating Call] contains action;
    while (current_round() > 0 && (barfSniffing || current_round() < 27) && get_property(counter) == before){
        int roundBefore = current_round();
        string response = to_string(combatSkill(action));
        if (get_property("script") == "FreeKill" && weaklingIced) updateWeaklingHP(response);
        if (get_property(counter) != before) return;
        if (current_round() == roundBefore || !contains_text(response, "distracted"))
            abort("Required combat action failed: " + action + ". Combat paused.");
    }
    if (get_property(counter) == before)
        print("Warning: required combat action did not succeed before the round limit: " + action
            + "; continuing combat.", "red");
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
            combatSkill($skill[RECALL FACTS: MONSTER HABITATS]);
            if (get_property("_monsterHabitatsFightsLeft").to_int() == 0)
                print("[DEBUG] Could not schedule Habitat roaming copies of " + target + ".", "red");
        } else if (target == $monster[sausage goblin] && have_skill($skill[Be Gregarious])
            && get_property("beGregariousCharges").to_int() > 0){
            int chargesBefore = get_property("beGregariousCharges").to_int();
            combatSkill($skill[Be Gregarious]);
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
    item song=$item[love song of smoldering passion];
    if (last_monster() == $monster[shadow scythe]){
        while (current_round()>0){
            warnLateCombat();
            int before=current_round();
           if (my_hp() < my_maxhp() * 0.5
                && item_amount($item[soggy used band-aid]) > 0 && item_amount(song) > 0)
                throw_items($item[soggy used band-aid],song);
            else if (item_amount(song)>=2)
                throw_items(song,song);
            else {
                print("Shadow Scythe: paired love songs unavailable; finishing with Weapon of the Pastalord.","red");
                combatSkill($skill[Weapon of the Pastalord]);
            }
            if (current_round()==before)
                abort("Shadow Scythe finisher did not advance combat; inspect the fight.");
        }
        return true;
    }
    if ($monsters[shadow spire, shadow matrix] contains last_monster()) {
        while (current_round() > 0) {
           int roundBefore = current_round();
           if (my_hp() < my_maxhp() * 0.4
                && item_amount($item[soggy used band-aid]) > 0 && item_amount(song) > 0)
                    throw_items($item[soggy used band-aid],song);
           combatSkill($skill[Weapon of the Pastalord]);
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

// Optional balloon exchanges replace existing stall rounds. Leave two rounds
// for the return, and use the dictionary while waiting (Shieldbutt staggers).
boolean waterBalloonUnavailable = false;
int waterBalloonHPBound = -1;
int waterBalloonHPRound = -1;

int waterBalloonDamageAllowance(){
    if (weaklingIced)
        return weaklingDamageAllowance();
    // Budget two familiar weights as well as the existing Coldform/aura estimate.
    int weight = max(1, familiar_weight(my_familiar()) + weight_adjustment());
    return weaklingDamageAllowance() + 2 * weight;
}

void updateWaterBalloonHP(string page_text){
    if (waterBalloonHPRound < 0 && last_monster().base_hp > 0)
        waterBalloonHPBound = max(0, to_int(floor(last_monster().base_hp * 0.925))
            - max(0, current_round() - 1) * waterBalloonDamageAllowance());
    string text = replace_all(create_matcher("<[^>]*>", page_text), " ");
    text = to_string(replace_string(text, "&nbsp;", " "));
    matcher reading = create_matcher("Opponent\\s+HP\\s*:\\s*([0-9][0-9,]*)", text);
    if (reading.find())
        waterBalloonHPBound = to_int(floor(helmetHP(page_text) * 0.925));
    else if (waterBalloonHPBound >= 0 && waterBalloonHPRound >= 0)
        waterBalloonHPBound = max(0, waterBalloonHPBound
            - max(0, current_round() - waterBalloonHPRound) * waterBalloonDamageAllowance());
    waterBalloonHPRound = current_round();
}

boolean waterBalloonStall(int lastStallRound, boolean trackHP){
    if (current_round() == 0 || current_round() > lastStallRound)
        return false;
    boolean heldByEnemy = get_property("_waterBalloonHeldByEnemy").to_boolean();
    if (!trackHP)
        updateWaterBalloonHP("");
    if (!heldByEnemy){
        if (waterBalloonUnavailable || !shouldTossWaterBalloons()
            || item_amount($item[water balloon]) == 0 || current_round() > lastStallRound - 2)
            return false;
        // Keep room for a toss, a return, and a delayed return. Missing reports
        // keep the aged estimate; required finishers take priority over catching.
        if (trackHP && weaklingHPBound <= 9 + 3 * weaklingDamageAllowance())
            return false;
        if (!trackHP && waterBalloonHPBound <= 100 + 3 * waterBalloonDamageAllowance())
            return false;
    }
    int roundBefore = current_round();
    string response = to_string(throw_item(heldByEnemy ? $item[facsimile dictionary] : $item[water balloon]));
    if (trackHP)
        updateWeaklingHP(response);
    else
        updateWaterBalloonHP(response);
    if (current_round() == roundBefore){
        waterBalloonUnavailable = true;
        print("Water balloon stall failed; continuing with the usual combat actions.", "red");
        return false;
    }
    return true;
}

// Standard mimic stall: balloon exchanges or the dictionary through round 10.
// The caller continues with its next combat actions from round 11 onward.
void standardMimicStall(boolean dictionaryOnly){
    if (!dictionaryOnly)
        bowlStraightUpStall(false);
    while (current_round() > 0 && current_round() <= 10){
        int roundBefore = current_round();
        if (dictionaryOnly || !waterBalloonStall(10, false))
            updateWaterBalloonHP(to_string(throw_item($item[facsimile dictionary])));
        if (current_round() == roundBefore){
            print("[DEBUG] Could not stall " + last_monster() + " with the facsimile dictionary; continuing combat.", "red");
            break;
        }
    }
}

void standardMimicStall(){
    standardMimicStall(false);
}

// ─── FREEKILL: COMMON COMBAT ACTIONS ───────────────────────────────────────────

void prepareFreeKillCombat(){
    // Uniced weaklings own their opener; the final paid phase arms only one forcer.
    if (current_round() == 0 || get_property("subscript") == "shadowForcers"
        || (get_property("subscript") == "weakling" && !weaklingIced))
        return;
    else {
        foreach sk in $skills[McHugeLarge Avalanche, Launch spikolodon spikes, Prepare to reanimate your Foe]{
            if (current_round() == 0 || current_round() >= 28 || (weaklingIced && !weaklingCanStall()))
                break;
            if (combat_skill_available(sk)
                && !contains_text(get_property("_lastCombatActions"), "sk" + to_int(sk) + ";")){
                string response = to_string(combatSkill(sk));
                if (weaklingIced)
                    updateWeaklingHP(response);
            }
        }
        if (current_round() > 0 && current_round() < 28 && (!weaklingIced || weaklingCanStall())
            && last_monster() == get_property("killThisGuy").to_monster()
            && get_property("swordSniff").to_boolean()
            && !contains_text(get_property("_lastCombatActions"), "sk" + to_int($skill[%fn, kill a lot of these guys]) + ";"))
            updateWeaklingHP(to_string(combatSkill($skill[%fn, kill a lot of these guys])));
    }
    if (current_round() > 0 && current_round() < 28 && (!weaklingIced || weaklingCanStall())
        && have_skill($skill[Steal Monster's Heart])
        && !contains_text(get_property("_lastCombatActions"), "sk" + to_int($skill[Steal Monster's Heart]) + ";"))
        updateWeaklingHP(to_string(combatSkill($skill[Steal Monster's Heart])));
}

// Coldform / shard-of-double-ice fights retain their separate weakling strategy.
// Stall through round 27; reserve 28 for Candyblast, 29 for Pastalord, and 30 for Cudgel.
// With microphones, finishers move to 26-28 and microphones own rounds 29-30.
void prepareWeaklingCombat(){
    prepareFreeKillCombat();
    if (current_round() > 0 && current_round() < 28 && weaklingCanStall() && have_skill($skill[Prepare to reanimate your Foe])
        && !contains_text(get_property("_lastCombatActions"), "sk" + to_int($skill[Prepare to reanimate your Foe]) + ";"))
        updateWeaklingHP(to_string(combatSkill($skill[Prepare to reanimate your Foe])));
    bowlStraightUpStall(true);
    int finishRound = weaklingFinisherRound();
    while (current_round() > 0 && current_round() < finishRound && weaklingCanStall()){
        int roundBefore = current_round();
        boolean shieldStall = weaklingIced && have_equipped($item[april shower thoughts shield]) && have_skill($skill[Shieldbutt]);
        if (!shieldStall && current_round() >= 11)
            break;
        if (!waterBalloonStall(shieldStall ? finishRound - 1 : 10, true)){
            if (shieldStall)
                updateWeaklingHP(to_string(combatSkill($skill[shieldbutt])));
            else
                updateWeaklingHP(to_string(throw_item($item[facsimile dictionary])));
        }
        if (current_round() == roundBefore){
            print("[DEBUG] Weakling preparation failed; continuing combat.", "red");
            break;
        }
        if ((!weaklingIced || !have_equipped($item[april shower thoughts shield]) || !have_skill($skill[Shieldbutt])) && current_round() > 10)
            break;
        if (current_round() > 0 && current_round() < finishRound && my_hp() < 100 && weaklingCanStall())
            updateWeaklingHP(to_string(throw_items($item[new age healing crystal], $item[new age healing crystal])));
    }
    if (current_round() > 0 && current_round() < finishRound && last_monster() == $monster[eldritch tentacle])
        backupSpell(min(4, finishRound - current_round()));
    if (current_round() > 0 && last_monster() == $monster[flaming leaflet])
        updateWeaklingHP(to_string(throw_items($item[lit leaf lasso], $item[lit leaf lasso])));
}

// Shared late stall, without damage spells before a required free-kill item.
void stallWeaklingCombat(){
    bowlStraightUpStall(true);
    int finishRound = weaklingFinisherRound();
    while (current_round() > 0 && current_round() < finishRound && weaklingIced && weaklingCanStall()){
        int roundBefore = current_round();
        if (!waterBalloonStall(finishRound - 1, true)){
            if (have_equipped($item[april shower thoughts shield]) && have_skill($skill[Shieldbutt]))
                updateWeaklingHP(to_string(combatSkill($skill[shieldbutt])));
            else
                updateWeaklingHP(to_string(attack()));
        }
        if (current_round() == roundBefore){
            print("[DEBUG] Weakling attack failed; continuing combat.", "red");
            break;
        }
    }
    while (current_round() > 0 && current_round() < finishRound && weaklingCanStall()){
        int roundBefore = current_round();
        if (!waterBalloonStall(finishRound - 1, true))
            updateWeaklingHP(to_string(throw_item($item[facsimile dictionary])));
        if (current_round() == roundBefore){
            print("[DEBUG] Weakling dictionary stall failed; continuing to the kill.", "red");
            break;
        }
    }
}

void finishWeaklingCombat(boolean lateStall){
    if (current_round() > 0 && current_round() < weaklingFinisherRound() && weaklingIced && weaklingCanStall()
        && have_equipped($item[congressional medal of insanity]))
        updateWeaklingHP(to_string(combatSkill($skill[Weapon of the Pastalord])));
    if (lateStall)
        stallWeaklingCombat();
    if (current_round() == 0)
        return;
    boolean microphoneFinisher = shieldMicrophoneFight() && current_round() >= 25
        && item_amount($item[droppable microphone]) > 0;
    int finishRound = microphoneFinisher ? 26 : 28;
    if (current_round() == finishRound)
        combatSkill($skill[Candyblast]);
    // If the HP safety check ended stalling early, finish early as well.
    while (current_round() > 0 && current_round() < finishRound + 2){
        int roundBefore = current_round();
        combatSkill($skill[Weapon of the Pastalord]);
        if (current_round() == roundBefore)
            abort("Weapon of the Pastalord failed; combat is paused before the round limit.");
    }
    if (current_round() > 0)
        combatSkill($skill[Carbohydrate Cudgel]);
    while (current_round() > 0){
        int roundBefore = current_round();
        combatSkill($skill[Weapon of the Pastalord]);
        if (current_round() == roundBefore)
            abort("Weapon of the Pastalord failed to advance combat.");
    }
}

void finishWeaklingCombat(){
    finishWeaklingCombat(true);
}

// Stocking Mimic preparation shared by its normal fights and location handlers.
void prepareStockingMimicCombat(){
    boolean shardFight = shardCombatMode() && !last_monster().boss;
    if (shardFight)
        startWeaklingCombat(visit_url("fight.php", false));
    if (shardFight)
        prepareFreeKillCombat();
    // Plants tear-away
    if (current_round() > 0 && current_round() < 28 && (!shardFight || weaklingCanStall())
        && last_monster() == $monster[black crayon flower]
        && have_skill($skill[Tear Away your Pants!]))
        updateWeaklingHP(to_string(combatSkill($skill[Tear Away your Pants!])));
    // Reanimate
    if (current_round() > 0 && current_round() < 28 && (!shardFight || weaklingCanStall())
        && have_skill($skill[Prepare to reanimate your Foe])
        && !contains_text(get_property("_lastCombatActions"), "sk" + to_int($skill[Prepare to reanimate your Foe]) + ";"))
        updateWeaklingHP(to_string(combatSkill($skill[Prepare to reanimate your Foe])));
    // red taffy if underwater or flooded  -- maybe move this somewhere global in the future so we can just do this regardless of familiar
    if (current_round() > 0 && current_round() < 28 && (!shardFight || weaklingCanStall())
        && my_location() != $location[none]
        && (my_location().environment == "underwater"
        || my_location() == to_location(get_property("_seadentWaveZone")))
        && !contains_text(get_property("_lastCombatActions"), "it6367")
        && item_amount($item[pulled red taffy]) > 0)
        updateWeaklingHP(to_string(throw_item($item[pulled red taffy])));
    if (shardFight){
        prepareWeaklingCombat();
        return;
    }
    bowlStraightUpStall(false);
    // Stall through round 10; proceed to the finish on round 11.
    while (current_round() > 0 && current_round() <= 10){
        int roundBefore = current_round();
        if (!waterBalloonStall(10, false))
            updateWaterBalloonHP(to_string(throw_item($item[facsimile dictionary])));
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
    if (weaklingIced && !last_monster().boss){
        boolean shieldStall = have_equipped($item[April Shower Thoughts shield]) && have_skill($skill[Shieldbutt]);
        if (shieldStall)
            stallWeaklingCombat();
        // Goblin chain kills follow the stall, even when the opening page offered them.
        if (current_round() > 0 && last_monster() == $monster[sausage goblin]
            && have_skill($skill[Club 'Em Into Next Week]) && get_property("script") != "FreeKill" && clubNextWeekReady())
            combatSkill($skill[Club 'Em Into Next Week]);
        if (current_round() > 0 && isLooseFK)
            free_kill(visit_url("fight.php", false));
        if (current_round() > 0 && isLooseFK && requireFreeKill)
            finishFreeKillFallback();
        if (current_round() > 0)
            finishWeaklingCombat(shieldStall);
        return;
    }
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
        backupSpell(5);
        if (current_round() > 0)
            combatSkill($skill[Weapon of the Pastalord]);
    }
    if (isLooseFK && current_round() > 0
        && !last_monster().boss && requireFreeKill)
        finishFreeKillFallback();
    if (current_round() > 0 && current_round() < 11)
        print("[DEBUG] Stocking Mimic did not reach round 11; continuing to the kill.", "red");
    if (current_round() > 0 && last_monster() == $monster[spawn of wally])
        attack(10);
    // Default finish from round 11 onward: Weapon of the Pastalord, or weapon attacks if unavailable.
    if (current_round() > 0){
        if (have_skill($skill[Weapon of the Pastalord])){
            backupSpell(5);
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

// ─── FREEKILL: LOCATIONS AND COMBAT MODES ───────────────────────────────────────

// Transform first, shard the final opponent, then sniff/harvest the Shadow Tree.
void prepareShadowTreeCombat(string page_text, boolean trackHP, boolean transformed){
    boolean trackingTree = trackHP && shadowRiftNeedsSlash()
        && !shadowRiftOffhandReserved(get_property("maxOverride"));
    int wafflesUsed = 0;
    if (trackingTree){
        weaklingIced = false;
        updateWeaklingHP(page_text);
        if (!have_equipped($item[McHugeLarge left pole]) || !have_skill($skill[McHugeLarge Slash]))
            abort("Shadow Rift tracking requires the McHugeLarge left pole and Slash skill.");
        while (current_round() > 0 && last_monster() != $monster[shadow tree]){
            // Reserve rounds for a replacement shard, Slash, all three Mild Evil casts, and the kill.
            int lastWaffleRound = 23;
            if (have_skill($skill[Bowl Straight Up]) && item_amount($item[cosmic bowling ball]) > 0)
                lastWaffleRound -= 1;
            if (current_round() >= lastWaffleRound || wafflesUsed >= 15 || !weaklingCanStall())
                abort("Shadow Rift: could not safely reach a Shadow Tree for tracking; combat is paused.");
            if (item_amount($item[waffle]) == 0)
                abort("Shadow Rift: ran out of waffles before finding a Shadow Tree.");
            int roundBefore = current_round();
            int wafflesBefore = item_amount($item[waffle]);
            throw_item($item[waffle]);
            if (current_round() == 0)
                return;
            if (current_round() <= roundBefore || item_amount($item[waffle]) >= wafflesBefore)
                abort("Shadow Rift: waffle did not advance combat or consume an item; combat is paused.");
            wafflesUsed += 1;
            // A transformation can retain the same monster ID. Never reuse its old HP/alignment.
            weaklingHPFightKey = "";
            weaklingHPRound = -1;
            weaklingHPBound = -1;
            weaklingMissingGrace = -1;
            weaklingIced = false;
            page_text = visit_url("fight.php", false);
            updateWeaklingHP(page_text);
        }
    }
    if (current_round() == 0)
        return;
    // Old shard actions cannot prove a waffle replacement is still cold-aligned.
    if (trackHP)
        startWeaklingCombat(page_text, trackingTree || transformed);
    if (current_round() == 0)
        return;
    if (trackingTree){
        if (!weaklingIced)
            abort("Shadow Rift tracking requires cold alignment before Slash or Mild Evil.");
        if (current_round() >= 28 || !weaklingCanStall())
            abort("Shadow Rift: not enough safe time/HP to Slash the Shadow Tree.");
        int usesBefore = get_property("_mcHugeLargeSlashUses").to_int();
        updateWeaklingHP(to_string(combatSkill($skill[McHugeLarge Slash])));
        if (get_property("_mcHugeLargeSlashUses").to_int() <= usesBefore)
            abort("Shadow Rift: McHugeLarge Slash did not register; tracking remains pending.");
        set_property("_teresShadowRiftSlashDone", true);
        if (get_property("teresCombatDebug").to_boolean())
            print("[Shadow Rift] Shadow Tree Slashed after " + wafflesUsed + " waffles; normal offhand resumes next fight.", "darkorange");
    }
    while (current_round() > 0 && current_round() < 28
        && last_monster() == $monster[shadow tree]
        && have_skill($skill[Perpetrate Mild Evil])
        && get_property("_mildEvilPerpetrated").to_int() < 3
        && (!trackHP || weaklingCanStall())){
        int usesBefore = get_property("_mildEvilPerpetrated").to_int();
        int roundBefore = current_round();
        string response = to_string(combatSkill($skill[Perpetrate Mild Evil]));
        if (trackHP && current_round() > 0)
            updateWeaklingHP(response, 1);
        if (get_property("_mildEvilPerpetrated").to_int() <= usesBefore
            || (current_round() > 0 && current_round() == roundBefore)){
            print("[Shadow Rift] Perpetrate Mild Evil did not advance its daily counter or combat round; continuing to the finisher.", "red");
            break;
        }
    }
}

// Affinity and FK exhaustion share shard stalling, but have different finishers.
// The phase is chosen before entering combat so the last Affinity fight cannot
// consume an FK resource just because an effect counter changes afterward.
boolean handleIcedShadowRiftCombat(string page_text){
    boolean requiresFreeKill = get_property("subscript") == "looseFK"
        || (get_property("subscript") != "shadowAffinity" && have_effect($effect[Shadow Affinity]) == 0);
    // All waffle replacements precede the shard, including Affinity's loot reroll.
    // Tracking takes priority; otherwise retain Affinity's preference for Gaze.
    boolean transformed = false;
    boolean canGaze = get_property("subscript") == "shadowAffinity"
        && last_monster() == $monster[shadow guy]
        && (my_basestat($stat[submysticality]) - 62500) > BCZcost("GazeCasts");
    boolean trackingTree = shadowRiftNeedsSlash()
        && !shadowRiftOffhandReserved(get_property("maxOverride"));
    if (!trackingTree && last_monster() == $monster[shadow guy]
        && (get_property("subscript") == "looseFK" || !canGaze)){
        int roundBefore = current_round();
        waffleShadowGuy();
        if (current_round() == 0)
            return true;
        if (current_round() != roundBefore){
            transformed = true;
            weaklingIced = false;
            weaklingHPFightKey = "";
            weaklingHPRound = -1;
            weaklingHPBound = -1;
            weaklingMissingGrace = -1;
            // Discard the original monster's page and HP reading after the reroll.
            page_text = visit_url("fight.php", false);
        }
    }
    prepareShadowTreeCombat(page_text, true, transformed);
    if (current_round() == 0)
        return true;
    prepareFreeKillCombat();
    // The final opponent is cold-aligned before this damage/loot action.
    if (current_round() > 0 && current_round() < 28 && weaklingIced && weaklingCanStall()
        && $monsters[shadow tree, shadow slab] contains last_monster()
        && get_property("_batWingsSwoopUsed").to_int() < 11
        && have_equipped($item[bat wings]) && have_skill($skill[Swoop like a Bat])
        && !contains_text(get_property("_lastCombatActions"), "sk7530;")){
        int usesBefore = get_property("_batWingsSwoopUsed").to_int();
        updateWeaklingHP(to_string(combatSkill($skill[Swoop like a Bat])));
        if (get_property("_batWingsSwoopUsed").to_int() <= usesBefore)
            print("Shadow Rift Swoop did not register; continuing with normal stalling.", "red");
    }
    // Non-ending loot/setup actions precede the first stall action.
    if (!requiresFreeKill && current_round() > 0 && weaklingCanStall()
        && !get_property("_circadianRhythmsRecalled").to_boolean())
        updateWeaklingHP(to_string(combatSkill($skill[RECALL FACTS: %PHYLUM CIRCADIAN RHYTHMS])));
    if (!requiresFreeKill && current_round() > 0 && weaklingCanStall())
        updateWeaklingHP(to_string(steal()));
    boolean shieldStall = weaklingIced && have_equipped($item[April Shower Thoughts shield])
        && have_skill($skill[Shieldbutt]);
    bowlStraightUpStall(true);
    while (current_round() > 0 && current_round() <= 10 && weaklingCanStall()){
        int roundBefore = current_round();
        if (!waterBalloonStall(shieldStall ? 27 : 10, true)){
            if (shieldStall)
                updateWeaklingHP(to_string(combatSkill($skill[Shieldbutt])));
            else
                updateWeaklingHP(to_string(throw_item($item[facsimile dictionary])));
        }
        if (current_round() == roundBefore){
            print("[DEBUG] Shadow Rift dictionary stall failed; continuing to the finisher.", "red");
            break;
        }
        if (current_round() > 0 && my_hp() < 200 && weaklingCanStall())
            updateWeaklingHP(to_string(throw_items($item[new age healing crystal], $item[new age healing crystal])));
    }
    if (current_round() == 0)
        return true;

    if (requiresFreeKill){
        if (shieldStall)
            stallWeaklingCombat();
        if (current_round() == 0)
            return true;
        // No Swoop, Gaze, attack, or other damage before the required free kill.
        free_kill(page_text);
        if (current_round() > 0)
            finishFreeKillFallback();
        return true;
    }

    // Combat-ending Gaze follows the full stall; Affinity supplies the free fight.
    if (shieldStall)
        stallWeaklingCombat();
    if (current_round() > 0 && weaklingCanStall() && last_monster() == $monster[shadow guy] && canGaze)
        combatSkill($skill[BCZ: Refracted Gaze]);
    if (shieldStall){
        finishWeaklingCombat();
    } else
        finishStockingMimicCombat(page_text, false);
    return true;
}

// Paid final phase: arm one combat force before damage/stalling can end the fight.
boolean handleShadowRiftForcerCombat(string page_text){
    if (get_property("subscript") != "shadowForcers"
        || my_location() != $location[Shadow Rift (The Misspelled Cemetary)])
        return false;
    weaklingIced = false;
    if (!last_monster().boss && shardCombatMode())
        startWeaklingCombat(page_text);
    if (current_round() > 0 && !last_monster().boss && !get_property("noncombatForcerActive").to_boolean()){
        skill forcer = shadowRiftCombatForcer();
        if (forcer != $skill[none]){
            if (!combat_skill_available(forcer))
                abort("Shadow Rift: " + forcer + " is not available in the prepared outfit.");
            string response = to_string(combatSkill(forcer));
            if (weaklingIced)
                updateWeaklingHP(response);
            if (!get_property("noncombatForcerActive").to_boolean())
                abort("Shadow Rift: " + forcer + " did not arm the next noncombat.");
        }
    }
    if (current_round() > 0 && !last_monster().boss){
        if (weaklingIced)
            prepareStockingMimicCombat();
        else
            standardMimicStall(true);
    }
    if (current_round() > 0)
        finishStockingMimicCombat(page_text, false);
    return true;
}

// Bosses remain immediate exceptions; regular Rift fights are handled here in one place.
boolean handleShadowRiftCombat(string page_text){
    if (my_location() != $location[Shadow Rift (The Misspelled Cemetary)])
        return false;
    if (!last_monster().boss && my_familiar() == $familiar[stocking mimic]
        && (shardCombatMode() || get_property("subscript") == "shadowAffinity"
            || get_property("subscript") == "looseFK"))
        return handleIcedShadowRiftCombat(page_text);
    standardMimicStall();
    if (current_round() == 0)
        return true;
    prepareShadowTreeCombat(page_text, false, false);
    if (current_round() == 0)
        return true;
    if (!get_property("_circadianRhythmsRecalled").to_boolean())
        combatSkill($skill[RECALL FACTS: %PHYLUM CIRCADIAN RHYTHMS]);
    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    steal();
    if (my_familiar() == $familiar[stocking mimic]){
        if (have_equipped($item[bat wings]))
            combatSkill($skill[swoop like a bat]);
        prepareStockingMimicCombat();
        if (current_round() > 0 && last_monster() == $monster[shadow guy]){
            if ((my_basestat($stat[submysticality]) - 62500) > BCZcost("GazeCasts"))
                combatSkill($skill[BCZ: Refracted Gaze]);
            else
                waffleShadowGuy();
        }
        finishStockingMimicCombat(page_text, have_effect($effect[shadow affinity]) == 0);
        return true;
    }
    // Preserve the previous Rift handling for other familiars.
    if (current_round() > 0 && last_monster() == $monster[shadow matrix])
        backupSpell(6);
    if (current_round() > 0 && !last_monster().boss){
        if (last_monster() == $monster[shadow guy]){
            if (have_equipped($item[blood cubic zirconia])){
                combatSkill($skill[BCZ: Refracted Gaze]);
                if (current_round() > 0 && have_equipped($item[bat wings]))
                    combatSkill($skill[swoop like a bat]);
            }
            while (current_round() > 0 && current_round() < 25
                && get_property("_douseFoeUses").to_int() < 3
                && !get_property("_douseFoeSuccess").to_boolean()
                && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory])){
                int roundBefore = current_round();
                combatSkill($skill[douse foe]);
                if (current_round() == roundBefore){
                    print("[DEBUG] Douse Foe failed; continuing combat.", "red");
                    break;
                }
            }
        } else if (have_equipped($item[bat wings]))
            combatSkill($skill[swoop like a bat]);
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
            combatSkill($skill[throw cyber rock]);
            if (current_round() == roundBefore){
                print("[DEBUG] Throw Cyber Rock failed; continuing combat.", "red");
                break;
            }
        }
        if (current_round() > 0 && $monsters[ICE barrier, corruption quarantine, parental controls, null container] contains last_monster())
            combatSkill($skill[deploy glitched malware]);
        if (current_round() > 0)
            combatSkill($skill[Launch Logic Grenade]);
    }
    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    if (get_property("subscript") == "weakling"){
        prepareWeaklingCombat();
        finishWeaklingCombat();
    } else if (!handleStockingMimicCombat(page_text)){
        backupSpell(7);
        attack(3);
    }
    return true;
}

// Wanderers and failed bowler banishes continue through normal combat.
// Orderlies still require the equipped latte/ring banish during farming.
boolean handleBowlingAlleyCombat(){
    if (my_location() != $location[The Hidden Bowling Alley])
        return false;
    boolean farming = hiddenCityFarming();
    if (last_monster() == $monster[pygmy bowler]){
        throw_item($item[stuffed yam stinkbomb]);
        if (current_round() > 0)
            print("[DEBUG] Failed to banish the pygmy bowler with a stuffed yam stinkbomb.", "red");
    } else if (last_monster() == $monster[pygmy orderlies]){
        skill banish = hiddenCityOrderliesBanish();
        if (banish != $skill[none])
            combatSkill(banish);
        else if (farming)
            abort("Bowling Alley: no equipped, unused latte or ring banish is available for pygmy orderlies.");
        if (current_round() > 0) {
            if (farming)
                abort("Bowling Alley: pygmy orderlies banish failed; combat is paused.");
            print("[DEBUG] Failed to banish pygmy orderlies with the latte or ring.", "red");
        }
    } else if (last_monster() == $monster[pygmy janitor]){
        if (farming)
            print("[DEBUG] Unexpected pygmy janitor: check janitor relocation for this ascension; continuing combat.", "red");
        else
            combatSkill($skill[Snokebomb]);
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
    if (shardCombatMode() && !last_monster().boss)
        startWeaklingCombat(page_text);
    if (current_round() == 0)
        abort("The screech target died before the banish; inspect the encounter.");
    if (contains_text(last_monster().attributes, "WANDERER")){
        print("[DEBUG] Hit a WANDERER while trying to screech something.", "red");
        attack(30);
        if (current_round() == 0)
            return true;
    }
    print("Ya boi screeching a " + last_monster() + " . . . ", "blue");
    string screechResponse = to_string(combatSkill($skill[%fn, Release the Patriotic Screech!]));
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
    if (shardCombatMode() && !last_monster().boss)
        startWeaklingCombat(page_text);
    if (current_round() == 0)
        abort("The pledge target died before pledging; inspect the encounter.");
    // _citizenZone comes from the effect description; the effect confirms the pledge here.
    if (have_effect($effect[Citizen of a Zone]) == 0){
        page_text = to_string(combatSkill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]));
    }
    if (have_effect($effect[Citizen of a Zone]) == 0)
        abort("Eagle pledge failed; combat is paused for inspection.");
    if (freeRunAfterPledge){
        if (current_round() > 0)
            free_run(page_text);
        return true;
    }
    return current_round() == 0;
}


// The cigarette ends a Gingerbread dude fight for free; it does not advance
// the city's clock. Use it after the Mimic's early stall, or after round 27
// when farming Shieldbutt buffs; finish sooner if HP is unsafe.
void finishGingerbreadDude(){
    if (current_round() == 0)
        return;
    warnLateCombat();
    if (item_amount($item[gingerbread cigarette]) == 0)
        abort("No gingerbread cigarette remains; combat is paused before a damage finisher.");
    throw_item($item[gingerbread cigarette]);
    if (current_round() > 0)
        abort("The gingerbread cigarette did not finish combat; inspect before spending a turn.");
}

boolean handleGingerbreadCombat(string page_text){
    if (my_location().zone != "Gingerbread City"
        || !(appearance_rates(my_location()) contains last_monster()))
        return false;
    boolean transformed = false;
    // Transform before the shard opener; the new opponent needs its own HP state.
    while (current_round() > 0 && (last_monster().phylum == $phylum[beast]
        || $monsters[gingerbread pigeon, gingerbread rat] contains last_monster())){
        if (current_round() >= 28 || item_amount($item[waffle]) == 0)
            abort("Could not waffle to a Gingerbread dude within the stall rounds; combat is paused.");
        int roundBefore = current_round();
        page_text = to_string(throw_item($item[waffle]));
        if (current_round() == roundBefore)
            abort("Gingerbread waffle failed; combat is paused.");
        weaklingIced = false;
        transformed = true;
        weaklingHPFightKey = "";
        weaklingHPRound = -1;
        set_property("teresHelmetFightKey", "");
    }
    if (current_round() == 0)
        return true;

    boolean weakling = get_property("subscript") == "weakling"
        || (shardCombatMode() && !last_monster().boss);
    if (weakling){
        updateWeaklingHP(page_text);
        // A fragile dude must get its cigarette before the shard can kill it.
        if (last_monster().phylum == $phylum[dude]
            && have_effect($effect[Coldform]) > 0 && last_monster().defense_element != $element[cold]
            && !contains_text(get_property("_lastCombatActions"), "it5048;")
            && weaklingHPBound <= estimatedShardOpeningDamage(last_monster()) + 9 + weaklingDamageAllowance()){
            finishGingerbreadDude();
            return true;
        }
        startWeaklingCombat(page_text, transformed);
    }
    if (current_round() == 0)
        return true;
    boolean usedSlashThisFight = false;
    if (last_monster().phylum == $phylum[dude] && gingerbreadNeedsSlash()){
        if (weakling && !weaklingCanStall()){
            finishGingerbreadDude();
            return true;
        }
        if (current_round() >= 28){
            finishGingerbreadDude();
            return true;
        }
        if (!have_equipped($item[McHugeLarge left pole]) || !have_skill($skill[McHugeLarge Slash]))
            abort("The first Gingerbread sniff requires McHugeLarge Slash; combat is paused.");
        int usedBefore = get_property("_mcHugeLargeSlashUses").to_int();
        updateWeaklingHP(to_string(combatSkill($skill[McHugeLarge Slash])));
        if (get_property("_mcHugeLargeSlashUses").to_int() <= usedBefore)
            abort("McHugeLarge Slash failed; combat is paused.");
        set_property("_teresGingerbreadSlashDone", true);
        usedSlashThisFight = true;
    }
    if (current_round() == 0)
        return true;
    if (weakling){
        prepareWeaklingCombat();
        // Only the fight that actually cast Slash ends after the Mimic's early
        // stall. Subsequent fights retain the normal late Shieldbutt stall.
        if (!usedSlashThisFight)
            stallWeaklingCombat();
        if (last_monster().phylum == $phylum[dude])
            finishGingerbreadDude();
        else
            finishWeaklingCombat();
    } else if (my_familiar() == $familiar[stocking mimic]){
        prepareStockingMimicCombat();
        if (current_round() > 0 && last_monster().phylum == $phylum[dude])
            finishGingerbreadDude();
        if (current_round() > 0)
            finishStockingMimicCombat(page_text, true);
    } else {
        if (last_monster().phylum == $phylum[dude])
            finishGingerbreadDude();
        else
            backupSpell(9);
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
        int cablesUsed=get_property("_glarkCableUses").to_int();
        while (current_round()>0&&cablesUsed<5&&item_amount($item[glark cable])>0
            &&get_property("_glarkCableUses").to_int()==cablesUsed){
            int before=current_round();
            throw_item($item[glark cable]);
            if(current_round()==before)break;
        }
        if (current_round() > 0 && last_monster() == $monster[red skeleton])
            backupSpell(5);
        if (current_round() > 0)
            finishFreeKillFallback();
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
            combatSkill($skill[%fn, Release the Patriotic Screech!]);
        else {
            if (get_property("_mildEvilPerpetrated").to_int() < 3)
                combatSkill($skill[perpetrate mild evil]);
            if (current_round() > 0 && get_property("_batWingsSwoopUsed").to_int() < 11)
                combatSkill($skill[swoop like a bat]);
            while (current_round() > 0 && get_property("_douseFoeUses").to_int() < 3
                && !get_property("_douseFoeSuccess").to_boolean()){
                int roundBefore = current_round();
                combatSkill($skill[douse foe]);
                if (current_round() == roundBefore){
                    print("[DEBUG] Domed City Douse Foe failed; continuing combat.", "red");
                    break;
                }
            }
        }
        if (current_round() > 0)
            backupSpell(5);
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
            combatSkill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]);
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
    // Stall through round 10, then use the lassos from round 11 onward.
    boolean weakling = get_property("subscript") == "weakling";
    bowlStraightUpStall(weakling);
    while (current_round() > 0 && current_round() <= 10 && (weakling ? weaklingCanStall() : monster_hp() > 9)){
        int roundBefore = current_round();
        if (!waterBalloonStall(10, weakling)){
            string response = to_string(throw_item($item[facsimile dictionary]));
            if (weakling)
                updateWeaklingHP(response);
            else
                updateWaterBalloonHP(response);
        }
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

// Goblins are copied before killing; automatic roaming chains are paused.
boolean handleSausageGoblinCombat(string page_text){
    if (last_monster() != $monster[sausage goblin])
        return false;
    boolean shardFight = shardCombatMode() && !last_monster().boss;
    if (shardFight)
        startWeaklingCombat(page_text);
    if (current_round() == 0)
        return true;
    if (get_property("subscript") == "habitatRecall"
        && get_property("_monsterHabitatsFightsLeft").to_int() == 0
        && get_property("_monsterHabitatsRecalled").to_int() < 3)
        combatCounterSkill($skill[Recall Facts: Monster Habitats], "_monsterHabitatsRecalled");
    copyMonster($monster[sausage goblin]);
    if (shardFight && current_round() > 0)
        updateWeaklingHP(visit_url("fight.php", false));
    // chainRoamingMonster($monster[sausage goblin]); // Re-enable after choosing Habitat/Gregarious targets.
    // Chest Mimic copies eggs; only Stocking Mimic uses purple-candle chaining.
    if (current_round() > 0 && my_familiar() == $familiar[stocking mimic]
        && have_effect($effect[everything looks purple]) == 0
        && have_equipped($item[roman candelabra]))
        updateWeaklingHP(to_string(combatSkill($skill[blow the purple candle!])));
    boolean stockingMimic = my_familiar() == $familiar[stocking mimic];
    if (shardFight)
        prepareFreeKillCombat();
    if (stockingMimic || shardFight)
        prepareStockingMimicCombat();
    // Other familiars cast after copying; Stocking Mimic stalls through round 10 first.
    if (current_round() > 0 && !weaklingIced && (!stockingMimic || current_round() >= 11)
        && have_skill($skill[Club 'Em Into Next Week])
        && get_property("script") != "FreeKill" && clubNextWeekReady())
        combatSkill($skill[Club 'Em Into Next Week]);
    if (!shardFight)
        prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    if (stockingMimic || shardFight)
        finishStockingMimicCombat(page_text, true);
    else {
        if (current_round() > 0)
            backupSpell(2);
        if (current_round() > 0)
            attack(5);
    }
    return true;
}

boolean handleSandwormCombat(string page_text){
    if (last_monster() != $monster[giant sandworm])
        return false;
    if (!handleStockingMimicCombat(page_text))
        backupSpell(6);
    return true;
}

// ─── SCRIPT DISPATCHERS ───────────────────────────────────────────────────────

boolean handleShieldMaidenCombat(){
    if (get_property("subscript") != "shieldMaiden")
        return false;
    if (last_monster() != $monster[sausage goblin]
        || my_familiar() != $familiar[Meat Shield Maiden])
        abort("Shield Maiden: unexpected monster or familiar in the blessing fight.");
    if (!get_property("_blessingShieldSleazeReceived").to_boolean()){
        combatSkill($skill[%fn, protect me!]);
        if (!get_property("_blessingShieldSleazeReceived").to_boolean())
            abort("Shield Maiden: Protect did not grant the sleaze blessing.");
    }
    // The goblin is already free: finish normally without spending FK/copy resources.
    if (current_round() > 0)
        backupSpell(10);
    if (current_round() > 0)
        attack(20);
    return true;
}

// True means a handler claimed the fight; false allows the shared rules below.
boolean handleFreeKillCombat(string page_text){
    if (get_property("subscript") == "habitatBunny" && last_monster() == $monster[fluffy bunny]){
        while (current_round() > 0 && current_round() < 27 && !is_banished($monster[fluffy bunny])){
            int before = current_round();
            string response = to_string(throw_item($item[stuffed yam stinkbomb]));
            if (is_banished($monster[fluffy bunny])) return true;
            if (current_round() == before || !contains_text(response, "distracted"))
                abort("Dire Warren bunny banish failed; combat paused.");
        }
        if (!is_banished($monster[fluffy bunny])) abort("Dire Warren bunny was not banished.");
        return true;
    }
    if (!last_monster().boss && shardEyepatchRequired()
        && !have_equipped($item[PirateRealm eyepatch]))
        abort("Shard combat requires the PirateRealm eyepatch equipped; combat is paused before any action.");
    if (handleShieldMaidenCombat()) return true;
    // Familiar combat actions are suppressed here; finish without Mimic stalling.
    if (last_monster() == $monster[God Lobster]){
        backupSpell(5);
        attack(10);
        return true;
    }
    // Summoned golems can retain the previous adventure's location. Route by
    // monster first so they use Mimic stalling rather than that zone's handler.
    if ($monsters[Tooth Golem, Moleman] contains last_monster())
        return handleStockingMimicCombat(page_text);
    if (handleEaglePledgeCombat(page_text, true))
        return true;
    if (handleShadowRiftBoss())
        return true;
    if (handleShadowRiftForcerCombat(page_text))
        return true;

    // Handle roaming goblins before the location that their fight interrupted.
    if (handleSausageGoblinCombat(page_text)) return true;

    // Gingerbread owns transformations, the first sniff, and the cigarette.
    if (handleGingerbreadCombat(page_text)) return true;

    // Immediate banishes stay ahead of ordinary stalling. Waffles belong to
    // the Rift/Gingerbread handlers; Cyber constructs keep their own combat.
    if (handleScreechCombat(page_text)) return true;
    if (handleBowlingAlleyCombat()) return true;
    boolean transforms = my_location().zone == "Shadow Rift"
        || ($locations[cyberzone 1, cyberzone 2, cyberzone 3] contains my_location()
            && last_monster().phylum == $phylum[construct]);
    if (shardCombatMode() && !last_monster().boss && !transforms)
        startWeaklingCombat(page_text);
    if (current_round() == 0)
        return true;

    if (get_property("subscript") == "weakling"){
        if (!transforms)
            startWeaklingCombat(page_text);
        if (current_round() == 0)
            return true;
        if (handleFlamingPlantCombat()) return true;
        // Item summons can inherit Cyberzone/Rift/etc. Route those monsters
        // through weakling combat rather than the previous zone's handler.
        if (last_monster() == $monster[Eldritch Tentacle]
            || my_location() == $location[The Neverending Party]
            || my_location() == $location[none] || !(appearance_rates(my_location()) contains last_monster())){
            prepareWeaklingCombat();
            finishWeaklingCombat();
            return true;
        }
    }

    // These location handlers own their opening actions and familiar differences.
    if (handleShadowRiftCombat(page_text)) return true;
    if (handleCyberzoneCombat(page_text)) return true;

    prepareFreeKillCombat();
    if (current_round() == 0)
        return true;
    if (handleFlamingPlantCombat()) return true;
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
    return false;
}

void barfSniff(monster target){
    foreach source in $skills[Transcendent Olfaction, Gallapagosian Mating Call]{
        if (current_round() == 0 || !have_skill(source) || source.dailylimit == 0
            || my_mp() < mp_cost(source)) continue;
        string counter = source == $skill[Transcendent Olfaction] ? "olfactedMonster" : "_gallapagosMonster";
        // A successful cast must set its own target; hat distractions consume rounds, not success.
        if (to_monster(get_property(counter)) != target) combatCounterSkill(source,counter);
    }
}

void barfReanimate(){
    while (current_round() > 0 && current_round() < 27 && have_equipped($item[shrunken head])){
        int before = current_round();
        string response = to_string(combatSkill($skill[Prepare to reanimate your Foe]));
        if (!have_equipped($item[shrunken head])) return;
        if (current_round() == before || !contains_text(response, "distracted"))
            abort("Reanimation did not consume the shrunken head; combat paused.");
    }
    if (have_equipped($item[shrunken head]))
        print("Warning: reanimation did not succeed before the round limit; continuing combat.", "red");
}


// BARF combat placeholder. False means shared combat handling can continue.
boolean handleBARFCombat(string page_text){
    if (handleEaglePledgeCombat(page_text, false)) return true;
    // TODO: Add BARF farming combat rules here.
    string mode = get_property("_teresBarfMode");
    if (mode == "battlefield" && my_location() == $location[The Battlefield (Hippy Uniform)] && !last_monster().boss
        && appearance_rates(my_location()) contains last_monster()){
        if (!have_equipped($item[blood cubic zirconia])) abort("Battlefield detour needs the blood cubic zirconia.");
        combatCounterSkill($skill[BCZ: Refracted Gaze], "_bczRefractedGazeCasts");
        while (current_round() > 0 && current_round() < 27 && have_effect($effect[Everything Looks Yellow]) == 0){
            int before = current_round();
            string response;
            if (have_skill($skill[Spit jurassic acid]) && $skill[Spit jurassic acid].dailylimit != 0)
                response = to_string(combatSkill($skill[Spit jurassic acid]));
            else response = to_string(throw_item($item[yellow rocket]));
            if (have_effect($effect[Everything Looks Yellow]) > 0) return true;
            if (current_round() == before || !contains_text(response, "distracted"))
                abort("Battlefield yellow ray failed; combat paused.");
        }
        if (have_effect($effect[Everything Looks Yellow]) == 0) abort("Battlefield yellow ray did not succeed.");
        return true;
    }
    if (mode == "goat" && my_location() == $location[The Goatlet]){
        while (current_round() > 0 && last_monster() != $monster[drunk goat]){
            if (current_round() >= 20 || item_amount($item[waffle]) == 0) abort("Could not waffle to a drunk goat; combat paused.");
            int before = current_round();
            throw_item($item[waffle]);
            if (current_round() == before) abort("Goat waffle failed; combat paused.");
        }
    }
    if (last_monster() == $monster[sausage goblin]){
        if (my_familiar() != $familiar[Stocking Mimic]) abort("BARF goblin arrived without the Stocking Mimic; inspect wanderer scheduling.");
        if (have_equipped($item[Roman Candelabra]) && have_effect($effect[Everything Looks Purple]) == 0)
            combatCounterSkill($skill[Blow the Purple Candle!], "romanCandelabraPurpleCasts");
        if (have_skill($skill[Prepare to reanimate your Foe])) barfReanimate();
        // Other BARF monsters die promptly; goblins produce Mimic Meat through round ten.
        while (current_round() > 0 && current_round() < 11){
            int before = current_round();
            throw_item($item[facsimile dictionary]);
            if (current_round() == before) abort("BARF goblin dictionary stall failed.");
        }
        if (current_round() > 0 && get_property("clubEmNextWeekMonster") == ""
            && have_skill($skill[Club 'Em Into Next Week]) && clubNextWeekReady())
        {
            combatCounterSkill($skill[Club 'Em Into Next Week], "_clubEmNextWeekUsed");
            return true;
        }
    } else if (!last_monster().boss){
        // BARF tourists have NOBANISH; neither Screech, Sea *dent nor Spring Kick can exclude them.
        if (my_location() == $location[Barf Mountain] && last_monster() == $monster[garbage tourist]){
            // Olfaction replaces an existing target directly; keep a garbage-tourist trail.
            barfSniff($monster[garbage tourist]);
            if (current_round() > 0 && get_property("spookyVHSTapeMonster") == ""
                && !get_property("_teresBarfVhsEncounter").to_boolean()
                && (!get_property("_teresBarfPlannedExecution").to_boolean()
                    ||(get_property("_teresBarfPlanMask").to_int()==0&&!get_property("_teresBarfPlanStooper").to_boolean()))
                && item_amount($item[spooky VHS tape]) > 0){
                while (current_round() > 0 && current_round() < 27 && get_property("spookyVHSTapeMonster") == ""){
                    int before = current_round();
                    string response = to_string(throw_item($item[spooky VHS tape]));
                    if (get_property("spookyVHSTapeMonster") != "") break;
                    if (current_round() == before || !contains_text(response, "distracted")) abort("VHS recording failed; combat paused.");
                }
            }
        }
        if (current_round() > 0 && last_monster() == $monster[drunk goat] && have_skill($skill[Prepare to reanimate your Foe]))
            barfReanimate();
        if (current_round() > 0 && have_equipped($item[everfull dart holster])
            && have_effect($effect[Everything Looks Red]) == 0 && have_skill($skill[Darts: Aim for the Bullseye])){
            while (current_round() > 0 && current_round() < 27 && have_effect($effect[Everything Looks Red]) == 0){
                int before = current_round();
                string response = to_string(combatSkill($skill[Darts: Aim for the Bullseye]));
                if (current_round() == 0 || have_effect($effect[Everything Looks Red]) > 0) return true;
                if (current_round() == before || !contains_text(response, "distracted")) break;
            }
        }
    }
    if(my_location()==$location[Barf Mountain]&&get_property("_teresBarfVhsEncounter").to_boolean()
        &&my_familiar()==$familiar[Stocking Mimic]&&!last_monster().boss){
        while(current_round()>0&&current_round()<11){
            int before=current_round();throw_item($item[facsimile dictionary]);
            if(current_round()==before)abort("BARF VHS dictionary stall made no progress.");
        }
    }
    if (current_round() > 0 && $familiars[Chest Mimic, Cooler Yeti] contains my_familiar()){
        while (current_round() > 0){
            warnLateCombat();
            if (item_amount($item[love song of icy revenge]) == 0){
                if(get_property("_teresBarfPlannedExecution").to_boolean()){
                    print("Planned BARF training ran out of icy love songs; finishing normally and replanning from actual XP.","orange");break;
                }
                abort("BARF training ran out of icy love songs.");
            }
            int before = current_round();
            throw_item($item[love song of icy revenge]);
            if (current_round() > 0 && current_round() <= before) abort("BARF training love song did not advance combat.");
        }
        if(current_round()==0)return true;
    }
    if (current_round() > 0 && last_monster() != $monster[sausage goblin] && !last_monster().boss
        && have_skill($skill[Extract])) combatSkill($skill[Extract]);
    // Paid farming kills promptly: no shard, waffle, free-run or free-kill resources.
    if (current_round() > 0 && last_monster() != $monster[sausage goblin]) bowlStraightUpStall(false);
    while (current_round() > 0){
        warnLateCombat();
        int before = current_round();
        if (my_hp() < min(300,my_maxhp()) && have_skill($skill[Cannelloni Cocoon]) && my_mp() >= mp_cost($skill[Cannelloni Cocoon])){
            combatSkill($skill[Cannelloni Cocoon]); continue;
        }
        if (have_skill($skill[Weapon of the Pastalord]) && my_mp() >= mp_cost($skill[Weapon of the Pastalord]))
            combatSkill($skill[Weapon of the Pastalord]);
        else attack();
        if (current_round() > 0 && current_round() <= before) return true;
    }
    return true;
}

// ─── SHARED GENERAL COMBAT ────────────────────────────────────────────────────

boolean handleGeneralCombat(string page_text){
    if (sauceLocs[my_location()] || sauceMobs[last_monster()]){
        if (!free_monster() && !free_location()){
            free_run(page_text);
            return true;
        }
        backupSpell(7);
        attack(3);
        return true;
    }
    // Final fallback is shared by every script.
    if (current_round() > 0)
        backupSpell(10);
    if (current_round() > 0)
        attack(20);
    return true;
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text){
    if (current_round() == 0)
        return;
    warnLateCombat();
    if (get_property("script") == "BARF"){
        handleBARFCombat(page_text);
        return;
    }

    updateWaterBalloonHP(page_text);
    print("monster hp is " + last_monster().base_hp);
    print("monster level is " + numeric_modifier("monster level"));
    print("high stat is " + max(my_buffedstat($stat[muscle]), my_buffedstat($stat[mysticality]), my_buffedstat($stat[moxie])));

    if (!deferBowlUntilOpener())
        bowlStraightUpStall(false);
    if (current_round() == 0)
        return;

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
