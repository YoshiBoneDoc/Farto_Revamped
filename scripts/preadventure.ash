import iotm.ash;
import postadventure.ash;
// Shared buffs selected by the maximizer goal.
void mood(string function){
    if (function == "")
        function = get_property("maxOverride");
    switch (function){
        case "-combat":
            if (numeric_modifier("combat rate") > -35)
                cli_execute("gain -35 combat rate 100 maxmeatspent");
            if (have_effect($effect[Apriling Band Patrol Beat]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                cli_execute("aprilband effect nc");
            break;
        case "combat":
            if (numeric_modifier("combat rate") < 35)
                cli_execute("gain 35 combat rate 100 maxmeatspent");
            if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                cli_execute("aprilband effect c");
            break;
        case "item drop":
            if (numeric_modifier("item drop") < 666)
                cli_execute("gain 666 item drop 100 maxmeatspent");
            break;
        case "spooky res":
            if (numeric_modifier("spooky res") < 10)
                cli_execute("gain spooky res 100 maxmeatspent");
            break;
    }
}

// ---- HELPERS FOR MIMIC FARMING SCRIPT -----
void cheapFamXP(){
    if (have_effect($effect[heart of white]) == 0)
        use($item[white candy heart]);
    if (have_effect($effect[Candied Devil]) == 0)
        use($item[deviled candy egg]);
    while (have_effect($effect[Curiosity of Br'er Tarrypin]) < 30)
        use_skill($skill[Curiosity of Br'er Tarrypin]);
    while (have_effect($effect[Blue Swayed]) < 55)
        use($item[pulled blue taffy]);
}

// Mimic Mood - Always have shortly wired
void stockingMimicMood(){
    // only set this mood if we are using mimic
    if (my_familiar() != $familiar[stocking mimic])
    return;
    // Maintain Stocking Mimic combat buffs (2x acting for now); short potions frequency buff doesn't stack
    foreach ef in $effects[Shortly Wired]{
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
}

buffer preAdvMaximize(){
    buffer maximize;
    if (get_property("unconditionalOverride") != ""){
        append(maximize, get_property("unconditionalOverride"));
    } else {
        append(maximize, get_property("maxOverride") != "" ? get_property("maxOverride") : "item drop");
    }
    return maximize;
}

// Reuse a baseline within this run; only simple, single-slot requirements are
// temporary swaps. Accessories, exclusions and familiar/location changes define
// a new baseline. Other objectives, item modes and weapon conflicts use the solver.
boolean applyBaselineGear(string goal){
    string[int] clauses = split_string(goal, "\\s*,\\s*");
    string objective = replace_all(create_matcher("^\\s+|\\s+$", clauses[0]), "").to_lower_case();
    if (objective != "familiar weight" && objective != "familiar experience")
        return false;

    string baselineGoal = objective + ", -equip bat wings, -equip legendary seal-clubbing club, -equip McHugeLarge left pole";
    item[slot] overrides;
    boolean[item] excluded;
    foreach index, clause in clauses {
        if (index == 0)
            continue;
        clause = replace_all(create_matcher("^\\s+|\\s+$", clause), "");
        if (clause == "")
            continue;
        matcher equipment = create_matcher("(?i)^(-?)equip\\s+(.+)$", clause);
        if (!equipment.find())
            return false;
        item required = equipment.group(2).to_item();
        // These existing maximizer abbreviations are not exact ASH item names.
        if (required == $item[none] && equipment.group(2).to_lower_case() == "eternity codpiece")
            required = $item[The Eternity Codpiece];
        if (required == $item[none] && equipment.group(2).to_lower_case() == "legendary seal-clubbing")
            required = $item[legendary seal-clubbing club];
        // Mode suffixes and other special maximizer syntax stay with KoLmafia.
        if (required == $item[none] || contains_text(clause, "(") || contains_text(clause, ")"))
            return false;
        if (equipment.group(1) == "-") {
            excluded[required] = true;
            if (required != $item[bat wings] && required != $item[legendary seal-clubbing club]
                && required != $item[McHugeLarge left pole])
                baselineGoal += ", -equip " + required;
            continue;
        }
        slot position = to_slot(required);
        if ($slots[acc1, acc2, acc3] contains position) {
            baselineGoal += ", equip " + required;
            continue;
        }
        if (!($slots[hat, weapon, off-hand, back, shirt, pants, familiar] contains position)
            || (position == $slot[weapon] && weapon_hands(required) > 1)
            || (overrides contains position && overrides[position] != required))
            return false;
        overrides[position] = required;
    }
    foreach position, required in overrides
        if (excluded contains required)
            return false;

    // Hooks execute separately, so two scratch properties carry the baseline.
    // starter()/finisher() clear them; day, path and environment also delimit reuse.
    string key = today_to_string() + ":" + my_ascensions() + ":" + my_class()
        + ":" + my_path() + ":" + my_familiar() + ":" + my_location().environment
        + ":" + (my_location() != $location[none]
            && my_location() == get_property("_seadentWaveZone").to_location())
        + ":" + baselineGoal;
    if (get_property("_teresGearBaselineKey") != key) {
        clearPreAdvGearCache();
        print("Gear baseline: maximizing " + baselineGoal + ".", "blue");
        if (!maximize(baselineGoal, false))
            abort("preAdv baseline maximize() failed: " + baselineGoal);
        string outfit;
        foreach position in $slots[hat, weapon, off-hand, back, shirt, pants, acc1, acc2, acc3, familiar]
            outfit += (outfit == "" ? "" : ",") + to_int(equipped_item(position));
        set_property("_teresGearBaselineOutfit", outfit);
        set_property("_teresGearBaselineKey", key);
    }

    string[int] baseline = split_string(get_property("_teresGearBaselineOutfit"), ",");
    if (count(baseline) != 10) {
        clearPreAdvGearCache();
        return false;
    }
    item[slot] desired;
    int index = 0;
    int[item] copiesNeeded;
    foreach position in $slots[hat, weapon, off-hand, back, shirt, pants, acc1, acc2, acc3, familiar] {
        desired[position] = overrides contains position ? overrides[position] : baseline[index].to_int().to_item();
        index += 1;
        if (desired[position] != $item[none])
            copiesNeeded[desired[position]] += 1;
    }
    // A two-handed baseline needs a different weapon to support an off-hand.
    if (weapon_hands(desired[$slot[weapon]]) > 1 && desired[$slot[off-hand]] != $item[none])
        return false;
    foreach required, copies in copiesNeeded
        if (available_amount(required) < copies) {
            clearPreAdvGearCache();
            return false;
        }
    foreach position, required in desired
        if (required != $item[none] && equipped_item(position) != required && !can_equip(required))
            return false;

    // Clear the off-hand first when restoring a two-handed baseline; otherwise
    // switch the weapon before the off-hand. The rest only changes differing slots.
    if (desired[$slot[off-hand]] == $item[none] && equipped_item($slot[off-hand]) != $item[none])
        if (!equip($slot[off-hand], $item[none]))
            abort("Could not clear the off-hand for the gear baseline.");
    foreach position in $slots[hat, weapon, off-hand, back, shirt, pants, acc1, acc2, acc3, familiar]
        if (equipped_item(position) != desired[position]) {
            print("Gear swap: " + position + " -> " + desired[position] + ".", "blue");
            if (!equip(position, desired[position])) {
                clearPreAdvGearCache();
                abort("Could not equip " + desired[position] + " in " + position + ".");
            }
        }
    return true;
}

void applyPreAdvGear(buffer maximize){
    // The pole is a temporary skill tool, not part of the normal outfit.
    matcher poleRequest = create_matcher("(?i)(?:^|,)\\s*-?equip\\s+McHugeLarge left pole\\s*(?=,|$)", maximize.to_string());
    if (!poleRequest.find())
        append(maximize, ", -equip McHugeLarge left pole");
    // The eyepatch is opt-in: ordinary maximization must not select or retain it.
    matcher eyepatchRequest = create_matcher("(?i)(?:^|,)\\s*-?equip\\s+PirateRealm eyepatch\\s*(?=,|$)", maximize.to_string());
    if (!eyepatchRequest.find())
        append(maximize, ", -equip PirateRealm eyepatch");
    // Wings are opt-in: ordinary maximization must not select or retain them.
    matcher wingsRequest = create_matcher("(?i)(?:^|,)\\s*-?equip\\s+bat wings\\s*(?:,|$)", maximize.to_string());
    if (!wingsRequest.find())
        append(maximize, ", -equip bat wings");
    // The club is opt-in for a ready Next Week chain or the Back in Time FK.
    matcher clubRequest = create_matcher("(?i)(?:^|,)\\s*equip\\s+legendary seal-clubbing(?: club)?\\s*(?=,|$)", maximize.to_string());
    boolean clubRequested = clubRequest.find();
    boolean clubBackInTime = get_property("subscript") == "looseFK"
        && get_property("_clubEmTimeUsed").to_int() < 5;
    if (!clubRequested || (!clubNextWeekReady() && !clubBackInTime)) {
        if (clubRequested)
            maximize = replace_all(clubRequest, "").to_buffer();
        if (!contains_text(maximize.to_string().to_lower_case(), "-equip legendary seal-clubbing"))
            append(maximize, ", -equip legendary seal-clubbing club");
    }
    boolean yellowReady = have_effect($effect[everything looks yellow]) == 0;
    boolean greenReady = have_effect($effect[everything looks green]) == 0;
    boolean dartReady = have_effect($effect[everything looks red]) == 0;
    // Simple familiar outfits reuse a baseline; complex setups retain full maximization.
    if (!applyBaselineGear(maximize.to_string()) && !maximize(maximize.to_string(), false)) {
        // DEBUG for if maximize fails
        print("MAXIMIZE STRING: " + maximize.to_string(), "red");
        abort("preAdv maximize() failed: " + maximize.to_string());
    }

    // Free kill flag
    set_property("freeKillReady",
        ((have_equipped($item[The Jokester's gun]) && !get_property("_firedJokestersGun").to_boolean())
        || (have_equipped($item[jurassic parka]) && yellowReady)
        || (have_equipped($item[everfull dart holster]) && dartReady)
        || (have_equipped($item[spring shoes]) && greenReady)
        || (have_skill($skill[BCZ: Sweat Bullets]) && sweatBulletsReady(62500))
        || (have_equipped($item[sheriff pistol]) && have_skill($skill[Assert your Authority])
            && get_property("_assertYourAuthorityCast").to_int() < 3)) ? "true" : "false");

}

familiar selectFreeKillFamiliar(){
    int mimicXPTarget = 950;
    int yetiXPTarget = 2600; // (225 * 8) for Too Cool, 400 for nightcap, 400 base xp
    familiar selectedFamiliar;
    if (have_familiar($familiar[chest mimic]) && $familiar[chest mimic].experience < mimicXPTarget)
        selectedFamiliar = $familiar[chest mimic];
    else if (have_familiar($familiar[cooler yeti]) && $familiar[cooler yeti].experience < yetiXPTarget)
        selectedFamiliar = $familiar[cooler yeti];
    else if (get_property("_mapToACandyRichBlockDrops").to_int() < 1)
        selectedFamiliar = $familiar[Jill-of-All-Trades];
    else if (get_property("_knuckleboneDrops").to_int() < 100)
        selectedFamiliar = $familiar[skeleton of crimbo past];
    else
        selectedFamiliar = $familiar[Jill-of-All-Trades];
    return selectedFamiliar;
}

// Check the finalized outfit and supplies before any farming encounter starts.
void validateHiddenCityPreparation(){
    if (!hiddenCityFarming())
        return;
    if (item_amount($item[bowl of scorpions]) == 0)
        abort("Bowling Alley: no bowl of scorpions is available before combat.");
    if (!contains_text(get_property("banishedMonsters"), "pygmy bowler")
        && item_amount($item[stuffed yam stinkbomb]) == 0)
        abort("Bowling Alley: no stuffed yam stinkbomb is available before combat.");
    if (!contains_text(get_property("banishedMonsters"), "pygmy orderlies")) {
        skill banish = hiddenCityOrderliesBanish();
        if (banish == $skill[none])
            abort("Bowling Alley: the finalized outfit has no unused latte or ring banish.");
        if (my_mp() < mp_cost(banish) && !restore_mp(mp_cost(banish)))
            abort("Bowling Alley: could not restore MP for " + banish + ".");
        if (my_mp() < mp_cost(banish))
            abort("Bowling Alley: insufficient MP for " + banish + ".");
    }
}

void setupFreeKill(){
    string famOvr = get_property("famOverride");
    string maxOvr = get_property("maxOverride");
    boolean bowlingAlley = hiddenCityFarming();
    boolean godLobster = get_property("subscript") == "godLobster";
    boolean familiarExperienceFarming = bowlingAlley || godLobster;

    // ------- FAMILIAR HANDLING -------
    boolean keepStooper = false;
    if (my_familiar() == $familiar[stooper])  // Only evaluate drunk limit when Stooper is already equipped.
        keepStooper = my_inebriety() == inebriety_limit();
    if (!keepStooper || godLobster){
        if (famOvr != "")
            use_familiar(famOvr.to_familiar());
        else {
            familiar selectedFamiliar = selectFreeKillFamiliar();
            if (!use_familiar(selectedFamiliar))
                abort("Could not equip " + selectedFamiliar + " for FreeKill farming.");
        }
    }

    // Apply familiar specific buffs
    if ($familiars[chest mimic, cooler yeti] contains my_familiar())
        cheapFamXP();
    else if (my_familiar() == $familiar[stocking mimic])
        stockingMimicMood();

    // Familiar equipment --------------------
    string famEquipment;
    if (get_property("famEquipOverride") != "")                    famEquipment = get_property("famEquipOverride");
    else if (my_familiar() == $familiar[stocking mimic])           famEquipment = ", equip amulet coin";
    else if (my_familiar() == $familiar[skeleton of crimbo past])  famEquipment = ", equip small peppermint-flavored sugar walking crook";
    else if (my_familiar() == $familiar[cooler yeti])              famEquipment = ", equip toy cupid bow";
    else if (my_familiar() == $familiar[chest mimic])              famEquipment = ", equip toy cupid bow";
    else if (my_familiar() == $familiar[mini kiwi])                famEquipment = ", equip aviator goggles";
    else if (my_familiar() == $familiar[Meat Shield Maiden])       famEquipment = ", equip can of shield tenderizer";

    buffer maximize = preAdvMaximize();
    append(maximize, famEquipment);

    // Hidden City and God Lobster fights maximize XP without general farming gear overrides.
    if (!familiarExperienceFarming){
        int highStat = max(my_buffedstat($stat[muscle]),my_buffedstat($stat[mysticality]),my_buffedstat($stat[moxie]));
    // -- Overrides for all gear, accounting for diet > max, and FK charges --
        // No Hat overrides because of Hat Path
        // Mainhand
        if (have_equipped($item[angelbone totem]) || my_spleen_use() > 15)
            append(maximize, ", equip angelbone totem");
        if (get_property("mainOverride") != "")
            append(maximize, get_property("mainOverride"));
        else if (get_property("weaponOverride") != "")
            append(maximize, get_property("weaponOverride"));
        // Offhand
        if (have_equipped($item[Drunkula's wineglass]))
            append(maximize, ", equip Drunkula's wineglass");
        else if (get_property("offOverride") != "")
            append(maximize, get_property("offOverride"));
        // Back
        if (get_property("backOverride") != "")
            append(maximize, get_property("backOverride"));
        else if (have_item($item[protonic accelerator pack]) && get_property("questPAGhost") == "unstarted")
            append(maximize, ", equip protonic accelerator pack");
        // Quest/forcer shirts must win over the retained farming corset.
        if (contains_text(get_property("shirtOverride"), "equip PARTY HARD T-shirt")
            || (get_property("subscript") == "shadowForcers" && get_property("shirtOverride") != ""))
            append(maximize, get_property("shirtOverride"));
        else if (have_equipped($item[devilbone corset]))
            append(maximize, ", equip devilbone corset");
        else if (get_property("shirtOverride") != "")
            append(maximize, get_property("shirtOverride"));
        // Pants
        if (have_equipped($item[devilbone greaves]))
            append(maximize, ", equip devilbone greaves");
        else if (get_property("pantsOverride") != "")
            append(maximize, get_property("pantsOverride"));
        // Acc1
        if (have_equipped($item[angelbone dice]))
            append(maximize, ", equip angelbone dice");
        else if (get_property("acc1Override") != "")
            append(maximize, get_property("acc1Override"));
        // Acc2
        if (have_equipped($item[angelbone chopsticks]))
            append(maximize, ", equip angelbone chopsticks");
        else if (get_property("acc2Override") != "")
            append(maximize, get_property("acc2Override"));
        // Acc3
        if (have_equipped($item[devilbone rosary]))
            append(maximize, ", equip devilbone rosary");
        else if (get_property("acc3Override") != "")
            append(maximize, get_property("acc3Override"));
    }

    applyPreAdvGear(maximize);

    float mpTar = min(1, 500 / to_float(my_maxmp()));
    float hpTar = min(1, 1000 / to_float(my_maxhp()));
    string hpAutoRecovery = to_float(round(hpTar * 0.75 * 10000))/10000;
    string hpAutoRecoveryTarget = to_float(round(hpTar * 10000))/10000;
// For Hat Path Aftercore - just recover MP when below 200 mp, recover to 300 mp
//      string mpAutoRecovery = to_float(round(mpTar * 0.5 * 10000))/10000;
//      string mpAutoRecoveryTarget = to_float(round(mpTar * 10000))/10000;
    string mpAutoRecovery = 200.0 / my_maxmp();
    string mpAutoRecoveryTarget = 300.0 / my_maxmp();

    set_property("hpAutoRecovery",       hpAutoRecovery);
    set_property("hpAutoRecoveryTarget", hpAutoRecoveryTarget);
    set_property("mpAutoRecovery",       mpAutoRecovery);
    set_property("mpAutoRecoveryTarget", mpAutoRecoveryTarget);
    if (equipped_item($slot[codpiece5]) != $item[massive gemstone])
        codpiece("peridot of peril,blood cubic zirconia,baseball diamond,massive gemstone,massive gemstone");
// --dont flood the shadow realm in hat path
//            else if (dayType() == 1 && contains_text(get_property("lastEncounter"),"shadow")){
//                use_skill($skill[Sea *dent: Summon a Wave]);

    //monster level
    foreach ef in $effects[Ur-Kel's Aria of Annoyance,Pride of the Puffin,Bloodbathed,Misplaced Rage,Manbait,Sweetbreads Flamb&eacute;,Red Lettered,Spangled Star,Tortious,Litterbug,Not Sharing,Para-lyzed Jaw,Contemptible Emanations,Ashen Burps,The Cupcake of Wrath,Gelded,Mysteriously Handsome]{
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (numeric_modifier("Monster level") >= 150)
            break;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }

    foreach ef in $effects[Tranquilized Mind,Cunctatitis, Mathematically Precise]{
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }
    validateHiddenCityPreparation();
}

void setupBARF(){
    // TODO: Add BARF familiar, gear, buffs, and recovery settings here.
    // Familiar equipment: placeholder for BARF-specific selection.
}

// Lucky! fights need Meat gear and absolute recovery amounts, not percentages
// inherited from starter() or the previous farming phase.
void setupEmbezzler(){
    buffer maximize;
    append(maximize, "meat drop");
    if (get_property("backOverride") != "")
        append(maximize, get_property("backOverride"));
    if (get_property("famEquipOverride") != "")
        append(maximize, get_property("famEquipOverride"));
    applyPreAdvGear(maximize);

    // Shared combat may try up to ten Pastalord casts; usually one is enough.
    int combatMP = max(200, 10 * mp_cost($skill[Weapon of the Pastalord]));
    set_property("hpAutoRecovery", min(1.0, 750.0 / my_maxhp()));
    set_property("hpAutoRecoveryTarget", min(1.0, 1000.0 / my_maxhp()));
    set_property("mpAutoRecovery", min(1.0, to_float(combatMP) / my_maxmp()));
    set_property("mpAutoRecoveryTarget", min(1.0, to_float(max(300, combatMP)) / my_maxmp()));
}

// General gear fallback.
void setupDefault(){
    boolean clubEmReady = get_property("clubEmNextWeekMonster") != "" && clubNextWeekReady();
    boolean clubEmExact = total_turns_played() == get_property("clubEmNextWeekMonsterTurn").to_int() + 8;
    boolean jokesterReady = get_property("_firedJokestersGun") == "false";
    boolean avalancheReady = get_property("_mcHugeLargeAvalancheUses").to_int() < 3;
    boolean spikeReady = get_property("_spikolodonSpikeUses").to_int() < 5;
    boolean dartReady = have_effect($effect[everything looks red]) == 0;
    boolean greenReady = have_effect($effect[everything looks green]) == 0;
    boolean yellowReady = have_effect($effect[everything looks yellow]) == 0;
    boolean bcz = sweatBulletsReady(118881);
    boolean vote = item_amount($item[&quot;I Voted!&quot; sticker]) > 0 && total_turns_played()%11 == 1 && get_property("_voteFreeFights").to_int() < 3;
    boolean sheriff = get_property("_assertYourAuthorityCast").to_int() < 3 && item_amount($item[Sheriff pistol]) >= 1 && !clubEmReady;

    buffer maximize = preAdvMaximize();
    if (get_property("unconditionalOverride") == ""){
        // Hat
        if (get_property("hatOverride") != "")
            append(maximize, get_property("hatOverride"));
        else if (my_familiar() == $familiar[cooler yeti] || my_familiar() == $familiar[chest mimic])
            append(maximize, ", equip giant yellow hat");
        // Mainhand
        if (have_equipped($item[angelbone totem]) || my_spleen_use() > 15)
            append(maximize, ", equip angelbone totem");
        else if (clubEmReady)
            append(maximize, ", equip legendary seal-clubbing club");
        else if (get_property("mainOverride") != "")
            append(maximize, get_property("mainOverride"));
        else if (get_property("weaponOverride") != "")
            append(maximize, get_property("weaponOverride"));
        else if (dayType() == 0 && my_class() == $class[seal clubber])
            append(maximize, ", equip monodent");
        else if (jokesterReady)
            append(maximize, ", equip The Jokester's gun");
        else
            append(maximize, ", equip june cleaver");
        // Offhand
        if (have_equipped($item[Drunkula's wineglass]))
            append(maximize, ", equip Drunkula's wineglass");
        else if (get_property("offOverride") != "")
            append(maximize, get_property("offOverride"));
        else if (get_property("shrunkenHeadZombieMonster") == "" && item_amount($item[shrunken head]) > 0 && my_adventures() > 50)
            append(maximize, ", equip shrunken head");
        else if (clubEmExact && have_effect($effect[everything looks purple]) == 0)
            append(maximize, ", equip roman candelabra");
        else if (get_property("maxOverride") == "combat" || get_property("maxOverride") == "-combat")
            append(maximize, "");
        else
            append(maximize, ", equip carnivorous potted plant");
        // Back
        if (get_property("backOverride") != "")
            append(maximize, get_property("backOverride"));
        // Shirt
        if (have_equipped($item[devilbone corset]))
            append(maximize, ", equip devilbone corset");
        else if (get_property("shirtOverride") != "")
            append(maximize, get_property("shirtOverride"));
        else if (yellowReady && (my_adventures() > 100 || dayType() == 1))
            append(maximize, ", equip parka (dilophosaur)");
        else if (spikeReady)
            append(maximize, ", equip parka (spikolodon)");
        // Pants
        if (have_equipped($item[devilbone greaves]))
            append(maximize, ", equip devilbone greaves");
        else if (get_property("pantsOverride") != "")
            append(maximize, get_property("pantsOverride"));
        else if (get_property("sweat").to_int() < 90)
            append(maximize, ", equip designer sweatpants");
        // Acc1
        if (have_equipped($item[angelbone dice]))
            append(maximize, ", equip angelbone dice");
        else if (get_property("acc1Override") != "")
            append(maximize, get_property("acc1Override"));
        else if (dartReady && (my_adventures() > 40 || dayType() == 1))
            append(maximize, ", equip everfull dart holster");
        else if (greenReady && (my_adventures() > 30 || dayType() == 1))
            append(maximize, ", equip spring shoes");
        else if (bcz)
            append(maximize, ", equip blood cubic zirconia");
        else if (vote)
            append(maximize, ", equip &quot;I Voted!&quot; sticker");
        else
            append(maximize, ", equip mafia thumb ring");
        // Acc2
        if (have_equipped($item[angelbone chopsticks]))
            append(maximize, ", equip angelbone chopsticks");
        else if (get_property("acc2Override") != "")
            append(maximize, get_property("acc2Override"));
        else if (have_equipped($item[angelbone dice]))
            append(maximize, ", equip mafia thumb ring");
        else if (avalancheReady)
            append(maximize, ", equip McHugeLarge left ski");
        else
            append(maximize, ", equip lucky gold ring");
        // Acc3
        if (have_equipped($item[devilbone rosary]))
            append(maximize, ", equip devilbone rosary");
        else if (get_property("acc3Override") != "")
            append(maximize, get_property("acc3Override"));
        else if (MobiusNCReady())
            append(maximize, ", equip mobius ring");
        else
            append(maximize, ", equip ordnance magnet");
        // Fam equip
        string famEquipment;
        if (get_property("famEquipOverride") != "")                          famEquipment = get_property("famEquipOverride");
        else if (my_familiar() == $familiar[skeleton of crimbo past])         famEquipment = ", equip small peppermint-flavored sugar walking crook";
        else if (my_familiar() == $familiar[cooler yeti])                    famEquipment = ", equip toy cupid bow";
        else if (my_familiar() == $familiar[chest mimic])                    famEquipment = ", equip toy cupid bow";
        else if (my_familiar() == $familiar[mini kiwi])                       famEquipment = ", equip aviator goggles";
        else if (my_familiar() == $familiar[Hobo in Sheep's Clothing])        famEquipment = ", equip half-height cigar";
        else if ($familiars[robortender, none, purse rat] contains my_familiar()
            || $strings[-combat, combat] contains get_property("maxOverride")) famEquipment = "";
        else                                                                famEquipment = ", equip Li'l Businessman Kit";
        append(maximize, famEquipment);
    }
    applyPreAdvGear(maximize);

}

void preAdv(){
    if (get_property("script") == "FreeKill")
        prepareGingerbreadAdventure(my_location());
    if (get_property("script") == "FreeKill")
        setupFreeKill();
    else if (get_property("script") == "embezzler")
        setupEmbezzler();
    else if (get_property("script") == "BARF")
        setupBARF();
    else
        setupDefault();

    if (get_property("script") == "FreeKill" && my_location().zone == "Gingerbread City"
        && get_property("_gingerbreadCityTurns").to_int() < 30 && gingerbreadNeedsSlash()
        && !have_equipped($item[McHugeLarge left pole]))
        abort("The first Gingerbread sniff requires the McHugeLarge left pole equipped.");
    if (get_property("script") == "FreeKill"
        && contains_text(get_property("offOverride"), "equip McHugeLarge left pole")
        && (get_property("subscript") == "shadowAffinity" || get_property("subscript") == "looseFK")
        && !have_equipped($item[McHugeLarge left pole]))
        abort("The first Shadow Rift sniff requires the McHugeLarge left pole equipped.");
    if (get_property("script") == "FreeKill"
        && contains_text(get_property("offOverride"), "equip April Shower Thoughts shield")
        && (get_property("subscript") == "shadowAffinity" || get_property("subscript") == "looseFK")
        && !have_equipped($item[April Shower Thoughts shield]))
        abort("Shadow Rift Shieldbutt stalling requires the April shield equipped.");
    if (get_property("script") == "FreeKill" && get_property("subscript") == "weakling"
        && my_location().zone == "Gingerbread City" && get_property("_gingerbreadCityTurns").to_int() < 30
        && !gingerbreadNeedsSlash() && !have_equipped($item[April Shower Thoughts shield]))
        abort("Gingerbread Shieldbutt stalling requires the April shield equipped.");
    if (get_property("script") == "FreeKill" && get_property("subscript") == "weakling"
        && contains_text(get_property("offOverride"), "equip April Shower Thoughts shield")
        && !have_equipped($item[April Shower Thoughts shield]))
        abort("Shield stalling requires the April shield equipped.");
    if (get_property("script") == "FreeKill" && get_property("subscript") == "weakling"
        && contains_text(get_property("acc3Override"), "equip PirateRealm eyepatch")
        && !have_equipped($item[PirateRealm eyepatch]))
        abort("Stat-limited shard stalling requires the PirateRealm eyepatch equipped.");
    if (get_property("script") == "FreeKill" && get_property("subscript") == "weakling"
        && my_location() == $location[The Neverending Party]
        && contains_text(get_property("shirtOverride"), "equip PARTY HARD T-shirt")
        && (!have_equipped($item[PARTY HARD T-shirt]) || have_equipped($item[PirateRealm eyepatch])))
        abort("Party hard fights require the PARTY HARD T-shirt and no PirateRealm eyepatch.");

    // Shared supplies for the combat scripts.
    // Required for FreeKill stalling: stop before combat if acquisition fails.
    if (get_property("script") == "FreeKill" && item_amount($item[facsimile dictionary]) == 0) {
        retrieve_item(1, $item[facsimile dictionary]);
        if (item_amount($item[facsimile dictionary]) == 0)
            abort("FreeKill requires a facsimile dictionary; Combat was not started. Go get one before running again.");
    }
    // One balloon can be reused across fights when the monster returns it.
    if (get_property("script") == "FreeKill"
        && (my_familiar() == $familiar[stocking mimic]
            || $strings[weakling, looseFK, shadowAffinity] contains get_property("subscript"))
        && shouldTossWaterBalloons()
        && item_amount($item[water balloon]) == 0
        && !retrieve_item(1, $item[water balloon]))
        print("Could not acquire a water balloon; continuing with normal stalling.", "red");
    if (item_amount($item[peppermint parasol]) == 0
        && !retrieve_item(1, $item[peppermint parasol]))
        print("[DEBUG] Could not acquire a peppermint parasol before combat; continuing.", "red");
    // Keep the round-30 Cudgel fallback supplied before entering combat.
    if (item_amount($item[dry noodles]) == 0)
        retrieve_item(1, $item[dry noodles]);
    if (item_amount($item[dry noodles]) == 0)
        abort("Combat requires at least one dry noodles for Carbohydrate Cudgel.");
    if (item_amount($item[lit leaf lasso]) < 2)
        buy(2,$item[lit leaf lasso]);
    if (item_amount($item[logic grenade]) < 2)
        retrieve_item(2,$item[logic grenade]);
    if (item_amount($item[glitched malware]) < 1)
        retrieve_item(1,$item[glitched malware]);
    // Keep shards in inventory; only replenish when a shard phase needs one.
    if ($strings[weakling, looseFK, shadowAffinity] contains get_property("subscript")
        && item_amount($item[shard of double-ice]) == 0) {
        if (closet_amount($item[shard of double-ice]) > 0)
            take_closet(1, $item[shard of double-ice]);
        else
            retrieve_item(1, $item[shard of double-ice]);
        if (item_amount($item[shard of double-ice]) == 0)
            abort("Shard fights require at least one shard of double-ice in inventory.");
    }
    if (item_amount($item[4-D camera]) == 0)
        retrieve_item($item[4-D camera]);
    if (item_amount($item[pulled green taffy]) == 0)
        retrieve_item($item[pulled green taffy]);
    if (item_amount($item[pulled red taffy]) < 100 && mall_price($item[pulled red taffy]) < (redTaffyValue() - 100))
        buy($item[pulled red taffy], 2000, redTaffyValue() - 100);
    if (item_amount($item[stuffed yam stinkbomb]) == 0)
        retrieve_item($item[stuffed yam stinkbomb]);
    if (item_amount($item[new age healing crystal]) < 100)
        retrieve_item(110,$item[new age healing crystal]);
    if (item_amount($item[Arr\, M80]) < 60)
        retrieve_item(70,$item[Arr\, M80]);
}

void main(){
    set_property("autoSatisfyWithStash", "true");
    string boof = get_property("betweenBattleScript");
    try {
        if (get_property("noncombatForcerActive") == "true" && get_property("inSpendAdv") != "true")
            postAdv();
        preAdv();
        if (item_amount($item[4-D camera]) == 0)
            retrieve_item($item[4-D camera]);
        cli_execute("checkpoint clear");
        mood("");
    } finally {
        set_property("betweenBattleScript",boof);
    }
}
