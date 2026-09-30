// ═══ iotm.ash ═══════════════════════════════════════════════════════════════
    // Shared helpers for the farto / free-kill environment.
    //   1. Globals
    //   2. General utilities
    //   3. Banish utilities
    //   4. Clan & instance access
    //   5. IOTM & item helpers   (one sub-section per item)
    //   6. Adventuring-state checks
    //   7. Unblemished pearls
    //   8. Universe calculator
    //  10. Script lifecycle

// ─── 1. GLOBALS ──────────────────────────────────────────────────────────────

    int uniInt, uniAdv, pearlsDoneToday;
    string clan = get_clan_name();
    int estimatedTurns;
    boolean [monster] haveLocketMonster = get_locket_monsters();

    // Mafia state snapshot, read once at import so finisher() can hand the account
    // back exactly what it had. starter() repoints the between-battle / after-
    // adventure / choice hooks, swaps in the CCCS custom combat script, pins the
    // auto-recovery levels and clears the native auto-attack; these captures happen
    // before the entry script's main() calls starter(), so restoring them is safe
    // even on an account with no garbo install.
    string ccsStorage                   = get_property("customCombatScript");
    string battleActionStorage          = get_property("battleAction");
    string autoAttackStorage            = get_property("defaultAutoAttack");
    string betweenBattleScriptStorage   = get_property("betweenBattleScript");
    string afterAdventureScriptStorage  = get_property("afterAdventureScript");
    string choiceAdventureScriptStorage = get_property("choiceAdventureScript");
    string hpAutoRecoveryStorage        = get_property("hpAutoRecovery");
    string hpAutoRecoveryTargetStorage  = get_property("hpAutoRecoveryTarget");
    string mpAutoRecoveryStorage        = get_property("mpAutoRecovery");
    string mpAutoRecoveryTargetStorage  = get_property("mpAutoRecoveryTarget");

// ─── 2. GENERAL UTILITIES ────────────────────────────────────────────────────

    int count_substring(string text, string sub) {
        int count = 0;
        int pos = 0;
        while (true) {
            pos = index_of(text, sub, pos);
            if (pos == -1) break;
            count += 1;
            pos += length(sub);
        }
        return count;
    }

    void aa(string str){
        set_auto_attack(str);
        if (get_auto_attack() == 0)
            cli_execute("/aa " + str);
        if (get_auto_attack() == 0)
            visit_url("account.php?am=1&value="+ get_property("combatMacroID") +"&ajax=1");
        if (get_auto_attack() == 0)
            abort("autoattack not set properly. Most likely mafia is a little broken and requires a restart");
    }

    item [effect] ETIManualAssignment = {
        $effect[beefy heart]:$item[Black and White Apron Meal Kit]
    };

    item effect_to_item(effect ef){
        if (contains_text(ef.default,"drink 1 ") || contains_text(ef.default,"chew 1 ")){
            return delete(to_buffer(ef.default),0,7).to_item();
        } else if (contains_text(ef.default,"eat 1 ") || contains_text(ef.default,"use 1 ")){
            return delete(to_buffer(ef.default),0,6).to_item();
        } else
            return ETIManualAssignment[ef];
    }

    record EffectNote {
        int turns;
        effect ef;
        string modifier;
    };

    EffectNote [item] notes;

    // Parses "N Effect Name (modifier)" out of it.notes, caches it in `notes`, and
    // hands the record straight back -- so itemEffectNotes(it).ef / .turns works
    // in one call instead of calling this to populate `notes` then indexing it.
    EffectNote itemEffectNotes(item it){
        if (notes contains it)
            return notes[it];
        matcher m = create_matcher("(\\d+) (.+?) \\((.+?)\\)", it.notes);
        if (m.find()){
            notes[it].turns = m.group(1).to_int();
            notes[it].ef = m.group(2).to_effect();
            notes[it].modifier = m.group(3);
        }
        return notes[it];
    }

    int organSpace(item it){
        int n = max(it.fullness, it.spleen, it.inebriety);
        return max(n,1);
    }

    // Mean of it.adventures' "X-Y" range (or just X, for a fixed-adventure item).
    float averageAdventures(item it){
        if (it.adventures == "")
            return 0.0;
        string [int] range = it.adventures.split_string("-");
        float total;
        foreach key, v in range
            total += v.to_float();
        return total / range.count();
    }

    // Use a skill if it appears as an option on the current page
    void use_if_have_skill(string page_text, skill sk) {
        if (contains_text(page_text, to_string(sk)))
            use_skill(sk);
    }

    // Returns true if the item exists anywhere accessible (inventory, equipped, storage, closet)
    boolean have_item(item it) {
        return item_amount(it) > 0
            || have_equipped(it)
            || storage_amount(it) > 0;
    }

    // Returns session log text from the current turn onward.
    // Mafia flushes the session log a beat after the fight resolves, so a fast
    // caller can read it before the "[<turn>]" marker for this adventure has been
    // written -- nowmark is then -1 and substring() aborts. Re-read a few times
    // with a short wait, and fall back to "" (callers only contains_text() it).
    string LastAdvTxt() {
        string lastlog;
        int nowmark = -1;
        for tries from 1 to 5 {
            lastlog = session_logs(1)[0];
            nowmark = max(
                last_index_of(lastlog, "[" + my_turncount() + "]"),
                last_index_of(lastlog, "[" + (my_turncount() + 1) + "]")
            );
            if (nowmark != -1) break;
            waitq(1);
        }
        if (nowmark == -1) return "";
        return substring(lastlog, nowmark);
    }

    boolean lastAdvWasCombat(){
        return (contains_text(lastAdvTxt(),"Round 1"));
    }

    boolean pullSequence(item it) {
        if (pulls_remaining() == 0)
            return false;
        if (!contains_text(get_property("_roninStoragePulls"), to_int(it))) {
            if (storage_amount(it) == 0){
                if (mall_price(it) > to_int(get_property("autoBuyPriceLimit"))){
                    if (!user_confirm("Price of " + it + " exeeds autoBuyPriceLimit, skip?"))
                        abort("Price of " + it + " exeeds autoBuyPriceLimit");
                }
                buy_using_storage(it);
            }
            return take_storage(1, it);
        }
        return false;
    }

    // Turns of buff one acquisition of an effect grants: a skill cast
    // (turns_per_cast already folds in Inigo's / Empathy / path multipliers) or a
    // single use/eat/drink of the item that grants it (mafia's modifiers.txt
    // "Effect Duration"). Returns 0 when neither resolves -- the effect comes from
    // a choice or combat and the caller has to know the number itself.
    int effectDuration(effect ef){
        skill sk = to_skill(ef);
        if (sk != $skill[none])
            return turns_per_cast(sk);
        item src = effect_to_item(ef);
        if (src != $item[none])
            return numeric_modifier(src, "Effect Duration");
        return 0;
    }

    // 1 on a farming / aftercore day, 0 mid-ascension. This replaced the old
    // get_property("ascensionsToday") checks and is the INVERSE polarity: where
    // those read "0" this reads 1, where they read "1" this reads 0.
    int dayType(){
        if (my_daycount() == 1){
            return 0;
        } else if (my_daycount() == 2){
            return 1;
        }
        if (get_property("dayTypeCheck") != today_to_string( )){
            set_property("dayType",user_prompt("Type 0 for freekills at the end of the day, type 1 for free kills at the beginning of the day"));
            set_property("dayTypeCheck",today_to_string( ));
        }
        return get_property("dayType").to_int();
    }

// ─── 3. BANISH UTILITIES ─────────────────────────────────────────────────────

    record ban {
        string pref;
        skill banSkill;
    };

    ban [item] banMap = {
        $item[spring shoes]:        new ban("Spring Kick",           $skill[spring kick]),
        $item[monodent of the sea]: new ban("Sea \\*dent",           $skill[Sea *dent: Throw a Lightning Bolt]),
        $item[Heartstone]:          new ban("Heartstone %banish",    $skill[Heartstone: %banish]),
        $item[none]:                new ban("snokebomb",             $skill[snokebomb]),
    };

    // Returns all locations a given monster can appear in
    location [int] monster_found_in(monster m) {
        location [int] output;
        foreach o in $locations[]
            if (o.get_location_monsters() contains m)
                output[count(output)] = o;
        return output;
    }

    // Returns the monster currently banished by a given banisher string
    monster banished(string banisher) {
        matcher m = create_matcher("([^:]+):\\Q" + banisher,
            get_property("banishedMonsters")
        );
        return m.find() ? to_monster(m.group(1)) : $monster[none];
    }

    // Returns true if the given banisher has been used on a monster at your current location
    boolean banishUsedAtYourLocation(string banisher) {
        foreach num in monster_found_in(banished(banisher)) {
            if (monster_found_in(banished(banisher))[num] == my_location())
                return true;
        }
        return false;
    }

    // Equips the appropriate banish gear for a location (that hasn't been used yet) and sets the slot override property.
    // NOTE: has the side effect of setting an Override property — callers should be aware.
    item banishGear(location loc) {
        item it;
        foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
            if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
                continue;
            if (appearance_rates(loc)[banished(banMap[ite].pref)] == 0 && have_item(ite)) {
                it = ite;
                break;
            }
        }
        // No candidate leaves it at $item[none]; writing an override for it would
        // create a junk "noneOverride" property.
        if (it != $item[none]) {
            set_property(to_string(to_slot(it)) + "Override", ", equip " + it);
            print(to_string(to_slot(it)) + "Override");
        }
        return it;
    }

    // Returns the combat banish skill for the first equipped banish item
    // whose target is no longer appearing at your location
    skill combatBan() {
        foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
            if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
                continue;
            if (have_equipped(ite)
                && appearance_rates(my_location())[banished(banMap[ite].pref)] == 0) {
                print("Banish item being considered " + ite + " parsed banished monster is " + banished(banMap[ite].pref) + " and the calculated appearance rate at current location is " + appearance_rates(my_location())[banished(banMap[ite].pref)]);
                cli_execute("get banishedMonsters");
                return banMap[ite].banSkill;
            }
        }
        return $skill[none];
    }

    int patrioticDelays(){
        int delay;
        if (can_adventure($location[the hidden bowling alley])){
            int n = 11 - get_property("_drunkPygmyBanishes").to_int();
            delay += n;
        }
        if (get_property("zigguratLianas") == 0)
            delay += 10;
        return delay;
    }

// ─── 4. CLAN & INSTANCE ACCESS ───────────────────────────────────────────────

    int [string] clan_to_ID {
        "Hyrule" : 72876,
        "Dread and Final" : 2047010985,
        "Dread Mart" : 2047010683,
        "Dread Outlet Bargain Market" : 2047010572,
        "Dreadleys" : 2047010988,
        "DreadNugget" : 2047010986,
        "Dreadway" : 2047010667,
        "Fart Sauce Annex" : 2047010939
    };

    void whitelist(string clan){
        visit_url("showclan.php?whichclan="+clan_to_ID[clan]+"&action=joinclan&confirm=on");
    }

    // stashgrab / stashreturn hop to a specific shared-stash clan (2047009940) and
    // back. Only Fart Scauce is whitelisted there and wants this side effect, so
    // they are no-ops on any other account.
    void stashgrab(item it){
        if (my_name().to_lower_case() != "fart scauce") return;
        visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
        if (stash_amount(it) > 0)
            take_stash(it, 1 );
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
        if (get_property("_clanFortuneConsultUses") == 0){
            cli_execute("/whitelist Bonus Adventures from Hell");
            visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
        }}

    void stashreturn(item it){
        if (my_name().to_lower_case() != "fart scauce") return;
        visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
        cli_execute("unequip "+ it);
        if (available_amount(it) > 0)
            put_stash(it, 1 );
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");}

    // Returns the number of chamois available in the clan slime tube
    int chamoixAmount() {
        matcher m = create_matcher("There are (\\d+) chamoi", visit_url("clan_slimetube.php?action=bucket"));
        return m.find() ? to_int(m.group(1)) : 0;
    }

    void camo() {
        if (chamoixAmount() < 1) {
            string current_clan = get_clan_id();
            try {
                foreach str in $strings[2046992052,2047010985,2047010683,2047010572,2047010988,2047010986,2047010667]{
                    visit_url("showclan.php?whichclan="+ str +"&action=joinclan&confirm=on");
                    if (chamoixAmount() >= 1)
                        break;
                    if (str == 2047010667)
                        abort("out of chamoix");
                }
                visit_url("clan_slimetube.php?action=chamois");
            } finally {
                visit_url("showclan.php?whichclan=" + current_clan + "&action=joinclan&confirm=on");
            }
        } else {
            visit_url("clan_slimetube.php?action=chamois");
        }
    }

    // Clan fortune-teller onlyfax for the day's 3 free consults (needs a clan
    // with a fortune teller; 90485 is a public one -- see the config note above).
    void clanFortune(){
        if (get_property("_clanFortuneConsultUses").to_int() == 3)
            return;
        visit_url("showclan.php?whichclan=90485&action=joinclan&confirm=on");
        cli_execute("fortune onlyfax pizza batman thick");
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
    }

// ─── 5. IOTM & ITEM HELPERS ──────────────────────────────────────────────────

    // ── Everfull Dart Holster ────────────────────────────────────────────────────
    string perks = get_property("everfullDartPerks");
    boolean bullseyeReady() {
        int n = count_substring(perks, "25% Better bullseye targeting") + count_substring(perks, "25% better chance to hit bullseyes") + count_substring(perks, "25% More Accurate bullseye targeting");
        return (n >= 2);
    }

    boolean everfullReady(){
        if (!bullseyeReady())
            return false;
        return (contains_text(perks, "You are less impressed by bullseyes")
                && contains_text(perks, "Bullseyes do not impress you much"))
            || count_substring(perks, "Bullseyes do not impress you much") >= 2
            || count_substring(perks, "You are less impressed by bullseyes") >= 2;
        return true;
    }

    void darts() {
        while (to_int(get_property("_dartsLeft")) > 0
            && have_equipped($item[everfull dart holster])
            && current_round() > 0) {
            if (contains_text(get_property("everfullDartPerks"), "Butt")) {
                matcher m = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
                if (!m.find()) break;
                use_skill(to_skill(to_int(m.group(1))));
            } else {
                use_skill($skill[Darts: Throw at %part1]);
            }
        }
    }

    // ── Blood Cubic Zirconia ─────────────────────────────────────────────────────

    int BCZcost(string BCZskill) {
        int cast = to_int(get_property("_bcz" + BCZskill));
        if (cast == 12) return 420000;
        if (cast > 12) cast -= 1;
        int castMathFloor = floor(cast / 3);
        int castMathModulo = cast % 3;
        int substatBase;
        switch (castMathModulo) {
            case 0: substatBase = 11; break;
            case 1: substatBase = 23; break;
            case 2: substatBase = 37; break;
        }
        // Pattern: 11, 23, 37, 110, 230, 370, ... 13th cast handled separately but unreachable
        return substatBase * 10 ** ((cast < 12 || (cast > 12 && castMathModulo == 0))
            ? castMathFloor : castMathFloor + 1);
    }

    // ── The Eternity Codpiece ────────────────────────────────────────────────────

    void codpiece(string input) {
        visit_url("inventory.php?action=docodpiece");
        if (input == "none") {
            string verify = visit_url("inventory.php?action=docodpiece");
            if (!contains_text(verify, " mounted in slot #"))
                return;
            for slots from 1 to 5 {
                if (contains_text(verify," Empty slot #" + slots )){
                    continue;
                } else {
                    visit_url("choice.php?whichchoice=1588&option=2&which=" + slots);
                }
            }
        } else {
            string [int] slots = split_string(input, ",");
            foreach num in slots {
                if (available_amount(to_item(slots[num])) == 0 ){
                    slots[num] = "";
                    continue;
                }
                visit_url("choice.php?whichchoice=1588&option=1&which=" + (num + 1)
                    + "&iid=" + to_int(to_item(slots[num])));
            }
            // Verify all slots mounted correctly
            string verify = visit_url("inventory.php?action=docodpiece");
            foreach num in slots {
                if (!contains_text(verify, to_item(slots[num]) + " mounted in slot #" + (num + 1)))
                    abort("Codpiece slot incorrect");
            }
        }
        cli_execute("refresh inv");
    }

    // ── Combat Baseball ──────────────────────────────────────────────────────────

    int baseballPlayers(){
        string [int] lineup = split_string(get_property("baseballTeam"), ",");
        int players;
        foreach num in lineup { players = num + 1; }
        return players;
    }

    void fillPrereqs(int outcomeSlot, string pitchType) {
        int filled = 0;
        int before = outcomeSlot - 1;
        while (filled < 2 && before >= 1) {
            if (get_property("pitchNum" + before) == "") {
                set_property("pitchNum" + before, pitchType);
                filled += 1;
            }
            before -= 1;
        }
        if (filled < 2)
            abort("Not enough open slots to fill prereqs for outcome at slot " + outcomeSlot);
    }
    void baseballD() {
        string [int] lineup = split_string(get_property("baseballTeam"), ",");
        int players;
        foreach num in lineup { players = num + 1; }
        if (players != 9) return;

        try {
            int YRPitchNum;
            int FKPitchNum;
            int BanishPitchNum;

            // Scan 9→3, take the latest slot for each outcome type
            for x from 9 to 3 {
                if (YRPitchNum == 0 && $strings[2278,2282] contains lineup[x-1]) {
                    YRPitchNum = x;
                    set_property("pitchNum" + x, "1");
                }
                if (FKPitchNum == 0 && $strings[768,2274,2278,2282] contains lineup[x-1]) {
                    FKPitchNum = x;
                    set_property("pitchNum" + x, "3");
                }
                // Banish (third pitch) only activates if slot 9 is already claimed by another outcome
                if (BanishPitchNum == 0 && $strings[2274] contains lineup[x-1]
                    && (YRPitchNum == 9 || FKPitchNum == 9)) {
                    BanishPitchNum = x;
                    set_property("pitchNum" + x, "2");
                }
            }

            if (YRPitchNum == 0 && FKPitchNum == 0) {
                print("No yellow ray or free kill pitchers in lineup, skipping.", "red");
                return;
            }

            // Assigning other pitches
            int [int] pitchOrder   = {1: YRPitchNum, 2: BanishPitchNum, 3: FKPitchNum};
            string [int] pitchChoice = {1: "1", 2: "2",        3: "3"};

            //Ordering pitches from latest to earliest
            for i from 1 to 3 {
                for j from 1 to (3 - i) {
                    if (pitchOrder[j] < pitchOrder[j+1]) {
                        int tmpS = pitchOrder[j];   pitchOrder[j]   = pitchOrder[j+1]; pitchOrder[j+1]   = tmpS;
                        string tmpP = pitchChoice[j]; pitchChoice[j] = pitchChoice[j+1]; pitchChoice[j+1] = tmpP;
                    }
                }
            }

            foreach i in pitchOrder {
                if (pitchOrder[i] > 0)
                    fillPrereqs(pitchOrder[i], pitchChoice[i]);
            }
            visit_url("inventory.php?pwd=" + my_hash() + "&action=pball",false);
            for x from 1 to 9 {
                string pitch = get_property("pitchNum" + x);
                run_choice(pitch == "" ? 4 : to_int(pitch));
            }
            run_choice(6);

        } finally {
            for x from 1 to 9 {
                set_property("pitchNum" + x, "");
            }
        }
    }

    // ── Model Train Set ──────────────────────────────────────────────────────────

    void trainset() {
        int pos = to_int(get_property("trainsetPosition")) % 8;
        int [int] slots = {
            (pos)     % 8: 8,   // next station
            (pos + 1) % 8: 1,
            (pos + 2) % 8: 15,
            (pos + 3) % 8: 20,
            (pos + 4) % 8: 3,
            (pos + 5) % 8: 7,
            (pos + 6) % 8: 2,
            (pos + 7) % 8: 19
        };
        visit_url("choice.php?forceoption=0?whichchoice=1485&option=1"
            + "&slot%5B0%5D=" + slots[0]
            + "&slot%5B1%5D=" + slots[1]
            + "&slot%5B2%5D=" + slots[2]
            + "&slot%5B3%5D=" + slots[3]
            + "&slot%5B4%5D=" + slots[4]
            + "&slot%5B5%5D=" + slots[5]
            + "&slot%5B6%5D=" + slots[6]
            + "&slot%5B7%5D=" + slots[7]);
    }

    // Locket

    int locketAvailable(){
        int n;
        if (available_amount($item[combat lover's locket]) > 0){
            string [int] lockets = split_string(get_property("_locketMonstersFought"), ",");
            n += 3-count(lockets);
        }
        return n;
    }

    // ── Leprecondo ───────────────────────────────────────────────────────────────

    string [int] lepRoomToNum = {
        1:"buckets of concrete",        2:"thrift store oil painting",
        3:"boxes of old comic books",   4:"second-hand hot plate",
        5:"beer cooler",                6:"free mattress",
        7:"gigantic chess set",         8:"UltraDance karaoke machine",
        9:"cupcake treadmill",          10:"beer pong table",
        11:"padded weight bench",       12:"internet-connected laptop",
        13:"sous vide laboratory",      14:"programmable blender",
        15:"sensory deprivation tank",  16:"fruit-smashing robot",
        17:"ManCave™ sports bar set",   18:"couch and flatscreen",
        19:"kegerator",                 20:"fine upholstered dining table set",
        21:"whiskeybed",                22:"high-end home workout system",
        23:"complete classics library", 24:"ultimate retro game console",
        25:"Omnipot",                   26:"fully-stocked wet bar",
        27:"four-poster bed"
    };

    void leprecondo(string input) {
        string [int] rooms = split_string(input, ",");
        int [int] lepRoom;
        int count;
        foreach num in rooms {
            int val = to_int(rooms[num]);
            string discovered = get_property("leprecondoDiscovered");
            // Two-digit room numbers need a plain contains; single-digit need comma guards
            // to avoid matching "1" inside "10", "11", etc.
            boolean found = (val >= 10)
                ? contains_text(discovered, rooms[num])
                : contains_text(discovered, "," + rooms[num] + ",");
            if (found) {
                lepRoom[count] = val;
                count += 1;
            }
        }
        cli_execute("leprecondo furnish "
            + lepRoomToNum[lepRoom[3]] + ","
            + lepRoomToNum[lepRoom[2]] + ","
            + lepRoomToNum[lepRoom[1]] + ","
            + lepRoomToNum[lepRoom[0]]);
    }

    // ── Möbius Ring ──────────────────────────────────────────────────────────────

    int [int] mobiusEncounters = {
        0:0,
        1:4,
        2:7,
        3:13,
        4:19,
        5:25,
        6:31,
        7:41,
        8:41,
        9:41,
        10:41,
        11:41,
        12:51,
        13:51,
        14:51,
        15:51,
        16:51,
        17:76,
        18:76,
        19:76,
        20:76
    };

    boolean MobiusNCReady(){
        if (total_turns_played( ) > get_property("_lastMobiusStripTurn").to_int() + mobiusEncounters[get_property("_mobiusStripEncounters").to_int()])
            return true;
        return false;
    }

    // Aprilband
    void aprilBand(){
        if (get_property("_aprilBandInstruments").to_int() >= 2)
            return;
        cli_execute("aprilband item quad tom");
        if (dayType() == 0)
            cli_execute("aprilband item tuba");
        else
            cli_execute("aprilband item saxophone");
    }

    // ── Comma Chameleon ──────────────────────────────────────────────────────────

    familiar chameleon(){
        matcher m = create_matcher("<b>\\d+</b> pound ([^,]+), Chameleon", visit_url("charpane.php"));
        if (m.find())
            return to_familiar(m.group(1));
        return $familiar[none];
    }

    void altFam(familiar fam){
        if (have_familiar(fam)){
            use_familiar(fam);
            set_property("famOverride",fam.to_string());
        } else {
            use_familiar($familiar[Jill-of-All-Trades]);
            set_property("famOverride","Jill-of-All-Trades");
/*
            use_familiar($familiar[comma chameleon]);
            if (chameleon() != fam){
                retrieve_item(familiar_equipment(fam));
                visit_url("inv_equip.php?which=2&action=equip&whichitem=" + familiar_equipment(fam).to_int());
                if (chameleon() != fam)
                    abort();
                set_property("commaFamiliar",fam.to_string());
            }
            set_property("famOverride","comma chameleon");
 */
        }
    }

    // ─── TRICK OR TREAT ───────────────────────────────────────────────────────

    void candy(string action) {
        if (action == "fight"){
            int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
            visit_url("place.php?whichplace=town&action=town_trickortreat");
            visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
            run_combat();
        } else if (action == "treat"){
            while (contains_text(get_property("_trickOrTreatBlock"),"L")){
                string before = get_property("_trickOrTreatBlock");
                int houseToVisit;
                if (contains_text(get_property("_trickOrTreatBlock"),"S")){
                    houseToVisit = index_of(before, "S");
                } else {
                    houseToVisit = index_of(before, "L");
                }
                visit_url("place.php?whichplace=town&action=town_trickortreat");
                visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
                if (get_property("_trickOrTreatBlock") == before){
                    print("candy: trick-or-treat block unchanged after treating house " + houseToVisit + " -- stopping", "red");
                    break;
                }
            }
        }
    }

    // ── Pulled Red Taffy ─────────────────────────────────────────────────────────

    // Drop weights for using a pulled red taffy underwater (Briny Deeps).
    float [item] redTaffyWeights = {
        $item[Alewife&trade; Ale]: 0.03,             $item[bazookafish bubble gum]: 0.03,
        $item[beefy fish meat]: 0.03,          $item[dull fish scale]: 0.0925,
        $item[eel battery]: 0.03,              $item[eel sauce]: 0.03,
        $item[glistening fish meat]: 0.03,     $item[high-pressure seltzer bottle]: 0.03,
        $item[imitation crab crate]: 0.03,     $item[ink bladder]: 0.03,
        $item[live nautical mine]: 0.03,       $item[Mer-kin healscroll]: 0.03,
        $item[Mer-kin lunchbox]: 0.0925,       $item[Mer-kin thingpouch]: 0.03,
        $item[pufferfish spine]: 0.03,         $item[rough fish scale]: 0.03,
        $item[salinated mint julep]: 0.03,     $item[sand dollar]: 0.125,
        $item[sea lace]: 0.03,                 $item[seaweed]: 0.03,
        $item[shark cartilage]: 0.03,          $item[slick fish meat]: 0.03,
        $item[slug of rum]: 0.03,              $item[slug of shochu]: 0.03,
        $item[slug of vodka]: 0.03,            $item[soggy seed packet]: 0.03,
    };

    float redTaffyValue() {
        float value;
        foreach it in redTaffyWeights
            value += redTaffyWeights[it] * mall_price(it);
        return value;
    }

// ─── 6. ADVENTURING-STATE CHECKS ─────────────────────────────────────────────

    // stack == false: pre-charge NC-forcing resources before a forcer is active (the
    // original call sites' behavior). stack == true: forceNoncombats() wants to spend
    // an additional resource to stack another forced NC on top of one already active.
    // Loops -- spending one resource per pass -- until noncombatForcerActive no longer
    // matches stack or today's free rests run out; a normal day can legitimately take
    // ~20 passes, so loopCount aborts well above that instead of at a tight bound, but
    // still catches the case where tuba/bell/cincho are all exhausted with free rests
    // still left, which would otherwise spin forever since nothing changes state.
    boolean NCforce(boolean stack) {
        int loopCount = 0;
        while (get_property("timesRested").to_int() < total_free_rests()){
            if (loopCount++ > 50)
                abort("NCforce: looped over 50 times with no progress -- probably out of tuba/bell/cincho to force NCs with");
            if (get_property("noncombatForcerActive").to_boolean() == true && stack == false)
                return true;
            if (have_item($item[apriling band helmet]) && to_int(get_property("_aprilBandTubaUses")) < 3 && have_item($item[Apriling band tuba])) {
                print(1,"red");
                cli_execute("aprilband play tuba");
            }  else if (get_property("_claraBellUsed") == false && have_item($item[clara's bell])){
                print(2,"red");
                use($item[clara's bell]);
            } else if (have_item($item[Cincho de Mayo])){
                print(3,"red");
                int cinchRestLoopCount = 0;
                while (to_int(get_property("_cinchUsed")) > 40
                        && to_int(get_property("timesRested")) < total_free_rests()) {
                    if (cinchRestLoopCount++ > 50)
                        abort("NCforce: cincho rest-down looped over 50 times with no progress -- camp rest free is probably failing");
                    cli_execute("unequip hat; equip apriling band helmet; camp rest free");
                }
                if (to_int(get_property("_cinchUsed")) <= 40) {
                    equip($slot[acc3], $item[cincho de mayo]);
                    use_skill($skill[Cincho: Fiesta Exit]);
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
        return get_property("noncombatForcerActive").to_boolean();
    }

    // Returns true if there are free-run resources available to burn for delay.
    boolean free_Run() {
        if (to_int(get_property("_snokebombUsed")) < 3)
            return true;
        if (have_effect($effect[everything looks green]) == 0 && my_adventures() > 60)
            return true;
        return false;
    }

    boolean free_Kill(){
        if (have_effect($effect[everything looks red]) == 0 && bullseyeReady() && my_adventures() > 30)
            return true;
        if (have_effect($effect[everything looks yellow]) == 0 && my_adventures() > 100)
            return true;
        return false;
    }

    boolean wanderer() {
        if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
            && get_property("clubEmNextWeekMonster") != "")
            return true;
        // Fixed: was incorrectly checking clubEmNextWeekMonster for the VHS tape condition
        if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
            && get_property("spookyVHSTapeMonster") != "")
            return true;
            if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0
            && total_turns_played() % 11 == 1
            && to_int(get_property("_voteFreeFights")) < 3)
            return true;
        return false;
    }

    boolean delay(){
        if (wanderer() || free_Run())
            return true;
        return false;
    }

    void getLucky() {
        if (have_effect($effect[Lucky!]) > 0)
            return;
        if (have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5) {
            use_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (available_amount($item[heartstone]) > 0 && get_property("heartstoneLuckUnlocked") == true && get_property("_heartstoneLuckUsed") == false) {
            use_skill($skill[Heartstone: %luck]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (item_amount($item[apriling band saxophone]) > 0 && get_property("_aprilBandSaxophoneUses").to_int() < 3)
            cli_execute("aprilband play saxophone");
        if (numeric_modifier("Meat drop") > 4400){
            use($item[11-leaf clover]);
            return;
        }
        if (have_effect($effect[lucky!]) == 0)
            abort("Did not acquire lucky");
    }

// ─── 7. UNBLEMISHED PEARLS ───────────────────────────────────────────────────

    record pearl {
        location loc;
        modifier ele_res;
        string donePref;
    };
    pearl[string] pearls = {
        "anemone":  new pearl($location[Anemone Mine],              $modifier[spooky resistance],   "_unblemishedPearlAnemoneMine"),
        "bar":	    new pearl($location[The Dive Bar],              $modifier[sleaze resistance],   "_unblemishedPearlDiveBar"),
        "reef":	    new pearl($location[Madness Reef],              $modifier[stench resistance],   "_unblemishedPearlMadnessReef"),
        "trench":	new pearl($location[The Marinara Trench],       $modifier[hot resistance],      "_unblemishedPearlMarinaraTrench"),
        "deepests":	new pearl($location[The Briniest Deepests],     $modifier[cold resistance],     "_unblemishedPearlTheBriniestDeepests"),
    };

// ─── 8. UNIVERSE CALCULATOR ──────────────────────────────────────────────────
    // Finds the adventure count at which the universe alignment hits 69.
    // Sets globals uniInt and uniAdv as a side effect and also returns uniAdv.

    int [string] sign = {
        "Mongoose":1, "Wallaby":2, "Vole":3,    "Platypus":4,
        "Opossum":5,  "Marmot":6,  "Wombat":7,  "Blender":8,
        "Packrat":9,  "Bad Moon":10
    };

    int universe() {
        for y from 0 to my_adventures() {
            for x from 1 to 99 {
                if (((x + my_ascensions() + sign[my_sign()])
                    * (my_spleen_use() + my_level())
                    + (my_adventures() - y)) % 100 == 69) {
                    uniInt = x;
                    uniAdv = my_adventures() - y;
                    break;
                }
            }
            if (uniInt > 0) break;
        }
        return uniAdv;
    }

// ─── 9. GRIMACE MAPS ──────────────────────────────────────────────────

    boolean mapgrim() {
        item it = $item[Map to Safety Shelter Grimace Prime];
        string out;
        while (my_adventures() >= 1 && available_amount(it) > 0) {
            //get effect to adventure in zone if needed
            if (have_effect($effect[Transpondent]) == 0){
                if (item_amount(it) < 5)
                    break;
                retrieve_item(1,$item[transporter transponder]);
                use($item[transporter transponder]);
            }
            if (have_effect($effect[Transpondent]) == 0){
                print (`Unable to get the Transpondent effect. Still have {available_amount(it)} {available_amount(it) != 1?it.plural:it}.`);
                return false;
            }
            use (it);
        }

        if (available_amount(it) == 0) {
            print(`Finished using all {it.plural}.`,'blue');
            return true;
        }
        return false;
    }

// ─── 10. INTEGRATED BUSKING ──────────────────────────────────────────────────

    // Beret Busking (5 casts/day, tracked by _beretBuskingUses) grants buffs
    // decided by total equipment power and the cast index.
    // beret_busking_effects(power, cast) predicts the effects for any pairing.
    //
    // Power = sum over hat/shirt/pants of get_power(item) * slot multiplier:
    // shirt x1, hat x(Tao ? 2 : 1), pants x(Tao ? 2 : 1) + (Hammertime ? 3 : 0).
    // With a Mad Hatrack the beret rides the familiar and any hat fills the hat
    // slot; without one the beret is the hat.
    //
    // beretBusking(modifiers) sweeps every reachable power for each remaining
    // cast, scores the predicted effects against the weighted modifier spec,
    // assembles the cheapest outfit hitting the best power, and casts. Owned gear
    // only unless that can't solve, then it widens to mall buys up to
    // autoBuyPriceLimit per piece.

    int beretGearCap = get_property("autoBuyPriceLimit").to_int();   // max mall price per piece

    record beretOutfit {
        item hat;
        item shirt;
        item pants;
        boolean ok;
    };

    float[string]   beretWeights;    // modifier name -> weight, per beretBusking() call
    boolean[effect] beretWishlist;   // effects that should win a busk outright
    boolean         beretAllowMall;  // widen candidate gear to mall buys
    boolean       beretClothesCached;
    item[int]     beretHats;
    item[int]     beretPants;
    item[int]     beretShirts;

    // Power multiplier for a slot, as Beret Busking reads it.
    int beretMult(slot sl){
        int tao = have_skill($skill[Tao of the Terrapin]) ? 2 : 1;
        if (sl == $slot[shirt]) return 1;
        if (sl == $slot[hat])   return tao;
        if (sl == $slot[pants]) return tao + (have_effect($effect[Hammertime]) > 0 ? 3 : 0);
        return 0;
    }

    // Power of the currently equipped hat/shirt/pants, for the post-assembly check.
    int beretEquippedPower(){
        int n;
        foreach sl in $slots[hat, shirt, pants]
            n += beretMult(sl) * get_power(equipped_item(sl));
        return n;
    }

    // "Familiar Weight" | "5 Meat Drop, 10 Familiar Weight" -> {name: weight}.
    // Names go straight to numeric_modifier(), so they must be real modifier names.
    float[string] beretParseModifiers(string spec){
        float[string] out;
        foreach _, raw in split_string(spec, ","){
            matcher m = create_matcher("^\\s*(?:([0-9]+(?:\\.[0-9]+)?)\\s+)?(.+?)\\s*$", raw);
            if (!find(m) || m.group(2) == "") continue;
            out[m.group(2)] = m.group(1) == "" ? 1.0 : m.group(1).to_float();
        }
        return out;
    }

    // Comma-separated effect names -> set; unrecognised names are dropped.
    boolean[effect] beretParseEffects(string spec){
        boolean[effect] out;
        foreach _, raw in split_string(spec, ","){
            matcher m = create_matcher("^\\s*(.+?)\\s*$", raw);
            if (!find(m)) continue;
            effect e = to_effect(m.group(1));
            if (e != $effect[none]) out[e] = true;
        }
        return out;
    }

    // Value of one busk's predicted effects (meat payout skipped). A wishlist
    // effect is worth a huge constant so any busk granting one beats a busk that
    // only stacks modifiers; everything else scores as the weighted modifier sum.
    float beretScore(int[effect] effects){
        float total;
        foreach e, dur in effects{
            if (e == $effect[none]) continue;
            if (beretWishlist contains e){
                total += 1000000.0 + dur;
                continue;
            }
            foreach mod in beretWeights
                total += beretWeights[mod] * numeric_modifier(e, mod);
        }
        return total;
    }

    void beretResetClothes(){
        beretClothesCached = false;
        clear(beretHats);
        clear(beretPants);
        clear(beretShirts);
    }

    // Candidate gear per slot, built once per (owned-only / mall) pass.
    void beretBuildClothes(){
        if (beretClothesCached) return;
        boolean hatrack = have_familiar($familiar[Mad Hatrack]);
        foreach it in $items[]{
            slot sl = to_slot(it);
            if (sl != $slot[hat] && sl != $slot[pants] && sl != $slot[shirt]) continue;
            if (!can_equip(it)) continue;
            if (!have_item(it) && (!beretAllowMall || !it.tradeable || mall_price(it) > beretGearCap || mall_price(it) < 100)) continue;

            if (sl == $slot[hat]){
                if (hatrack) beretHats[count(beretHats)] = it;   // beret goes on the rack, not here
            } else if (sl == $slot[pants]){
                beretPants[count(beretPants)] = it;
            } else {
                beretShirts[count(beretShirts)] = it;
            }
        }
        if (hatrack) beretHats[count(beretHats)] = $item[none];
        else         beretHats[0] = $item[prismatic beret];
        beretPants[count(beretPants)]   = $item[none];
        beretShirts[count(beretShirts)] = $item[none];
        beretClothesCached = true;
    }

    // Every distinct power total the candidate wardrobe can reach.
    int[int] beretPowerSums(){
        beretBuildClothes();
        boolean[int] hp;
        boolean[int] pp;
        boolean[int] sp;
        foreach _, h in beretHats   hp[beretMult($slot[hat])   * get_power(h)] = true;
        foreach _, p in beretPants  pp[beretMult($slot[pants]) * get_power(p)] = true;
        foreach _, s in beretShirts sp[get_power(s)] = true;

        boolean[int] sums;
        foreach a in hp
            foreach b in pp
                foreach c in sp
                    sums[a + b + c] = true;

        int[int] out;
        foreach v in sums
            out[count(out)] = v;
        return out;
    }

    // The reachable power whose predicted busk scores highest for this cast.
    int beretBestPower(int cast){
        int[int] sums = beretPowerSums();
        int best;
        float bestScore;
        boolean seen;
        foreach _, power in sums{
            float sc = beretScore(beret_busking_effects(power, cast));
            if (!seen || sc > bestScore){
                seen = true;
                bestScore = sc;
                best = power;
            }
        }
        return best;
    }

    int beretPrice(item it){
        return (it == $item[none] || have_item(it)) ? 0 : mall_price(it);
    }

    // power -> cheapest single item reaching it in this slot; owned beats bought.
    item[int] beretItemsByPower(item[int] pool, int cap, int mult){
        item[int] m;
        foreach _, it in pool{
            int p = get_power(it) * mult;
            if (p > cap) continue;
            if (!(m contains p)){
                m[p] = it;
                continue;
            }
            if (!have_item(m[p]) && (have_item(it) || mall_price(it) < mall_price(m[p])))
                m[p] = it;
        }
        return m;
    }

    // Cheapest hat/shirt/pants whose multiplied powers sum to exactly `power`.
    beretOutfit beretFindOutfit(int power){
        beretBuildClothes();
        item[int] hats   = beretItemsByPower(beretHats,   power, beretMult($slot[hat]));
        item[int] pants  = beretItemsByPower(beretPants,  power, beretMult($slot[pants]));
        item[int] shirts = beretItemsByPower(beretShirts, power, 1);

        beretOutfit best;
        int bestPrice;
        boolean seen;
        foreach a, h in hats
            foreach b, p in pants
                foreach c, s in shirts{
                    if (a + b + c != power) continue;
                    int price = beretPrice(h) + beretPrice(p) + beretPrice(s);
                    if (seen && price >= bestPrice) continue;
                    seen = true;
                    bestPrice = price;
                    best.hat = h;
                    best.pants = p;
                    best.shirt = s;
                    best.ok = true;
                }
        return best;
    }

    // Equip one slot: unequip for none, buy up to the cap if we don't own it.
    void beretEquip(slot sl, item it){
        if (it == $item[none]){
            if (equipped_item(sl) != $item[none])
                cli_execute("unequip " + sl);
            return;
        }
        if (available_amount(it) == 0)
            buy(1, it, beretGearCap);
        equip(sl, it);
    }

    // Solve and cast every remaining Beret Busking use.
    //   modifiers  weighted numeric modifiers, e.g. "Familiar Weight" or
    //              "5 Meat Drop, 10 Familiar Weight"  (pass "" to skip)
    //   effects    comma-separated effect names to prioritise; a busk granting
    //              one of these outscores any modifier-only busk  (pass "" to skip)
    void beretBusking(string modifiers, string effects){
        if (!have_item($item[prismatic beret]) && !have_skill($skill[Beret Busking]))
            return;
        beretWeights  = beretParseModifiers(modifiers);
        beretWishlist = beretParseEffects(effects);
        if (count(beretWeights) == 0 && count(beretWishlist) == 0)
            abort("beretBusking: nothing to value — modifiers '" + modifiers + "', effects '" + effects + "'");

        boolean hatrack = have_familiar($familiar[Mad Hatrack]);
        beretAllowMall = true;
        beretResetClothes();

        int cast = get_property("_beretBuskingUses").to_int();
        if (cast <= 4){
            int power = beretBestPower(cast);
            beretOutfit fit = beretFindOutfit(power);

            // Owned gear couldn't build it — widen to mall buys once, then stay widened.
            if (!fit.ok && !beretAllowMall){
                beretAllowMall = true;
                beretResetClothes();
                power = beretBestPower(cast);
                fit = beretFindOutfit(power);
            }
            if (!fit.ok)
                abort("beretBusking: no outfit reaches " + power + " power for cast " + cast);

            if (hatrack){
                use_familiar($familiar[Mad Hatrack]);
                equip($slot[familiar], $item[prismatic beret]);
            } else {
                retrieve_item($item[prismatic beret]);
            }
            beretEquip($slot[hat],   fit.hat);
            beretEquip($slot[shirt], fit.shirt);
            beretEquip($slot[pants], fit.pants);

            if (beretEquippedPower() != power)
                abort("beretBusking: wanted " + power + " power for cast " + cast
                    + ", assembled " + beretEquippedPower());

            print("Beret Busk " + (cast + 1) + ": power " + power + " — "
                + fit.hat + " / " + fit.shirt + " / " + fit.pants, "blue");
            use_skill($skill[Beret Busking]);
            cast += 1;
        }
    }

    void beretBusking(string modifiers){
        beretBusking(modifiers, "");
    }

// ─── 99. SCRIPT LIFECYCLE ────────────────────────────────────────────────────

    // starter(): point mafia's between-battle / after-adventure / choice hooks and the CCS at this environment.
    void starter(){
        set_property("hpAutoRecovery",0.75);
        set_property("hpAutoRecoveryTarget",0.95);
        set_property("mpAutoRecovery",0.25);
        set_property("mpAutoRecoveryTarget",0.3);
        set_auto_attack(0);
        set_property("battleAction", "custom combat script");
        buffer ccs = "consult unlockerCCS.ash \n abort";
            write_ccs(ccs, "CCCS");
        set_ccs ("CCCS");
        set_property("betweenBattleScript","preadventure.ash");
        set_property("afterAdventureScript","postadventure.ash");
        set_property("choiceAdventureScript", "generalChoice.ash");
    }

    // finisher(): undo everything starter() changed. Restores the hooks, CCS,
    // battle action and auto-recovery levels captured at import, drops the native
    // auto-attack, and clears this environment's own scratch properties (script /
    // subscript / inSpendAdv / every *Override).
    void finisher() {
        set_property("script", "");
        set_property("subscript", "");
        set_property("betweenBattleScript",   betweenBattleScriptStorage);
        set_property("afterAdventureScript",  afterAdventureScriptStorage);
        set_property("battleAction",          battleActionStorage);
        set_property("customCombatScript",    ccsStorage);
        set_property("hpAutoRecovery",        hpAutoRecoveryStorage);
        set_property("hpAutoRecoveryTarget",  hpAutoRecoveryTargetStorage);
        set_property("mpAutoRecovery",        mpAutoRecoveryStorage);
        set_property("mpAutoRecoveryTarget",  mpAutoRecoveryTargetStorage);
        // Numeric macro ids go through the int overload; a skill-name auto-attack
        // (to_int == 0) goes through the string one; empty / "0" just clears it.
        if (autoAttackStorage == "" || autoAttackStorage == "0")
            set_auto_attack(0);
        else if (autoAttackStorage.to_int() > 0)
            set_auto_attack(autoAttackStorage.to_int());
        else
            set_auto_attack(autoAttackStorage);
        foreach slotName in $strings[unconditional, max, fam, hat, main, weapon, off, back, shirt, pants, acc1, acc2, acc3, famEquip] {
            set_property(slotName + "Override", "");
        }
        stashreturn($item[pantsgiving]);
        set_property("inSpendAdv","false");
    }
