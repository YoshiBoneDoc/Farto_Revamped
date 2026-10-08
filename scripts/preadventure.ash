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

void applyPreAdvGear(buffer maximize){
    boolean yellowReady = have_effect($effect[everything looks yellow]) == 0;
    boolean greenReady = have_effect($effect[everything looks green]) == 0;
    boolean dartReady = have_effect($effect[everything looks red]) == 0;
    // Run Maximize string
    if (!maximize(maximize.to_string(), false)) {
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

void setupFreeKill(){
    string famOvr = get_property("famOverride");
    string maxOvr = get_property("maxOverride");

    // ------- FAMILIAR HANDLING -------
    boolean keepStooper = false;
    if (my_familiar() == $familiar[stooper])  // Only evaluate drunk limit when Stooper is already equipped.
        keepStooper = my_inebriety() == inebriety_limit();
    if (!keepStooper){
        if (famOvr != "")
            use_familiar(famOvr.to_familiar());
        else {
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
    else if (my_familiar() == $familiar[skeleton of crimbo past])  famEquipment = ", equip small peppermint-flavored sugar walking crook";
    else if (my_familiar() == $familiar[cooler yeti])              famEquipment = ", equip toy cupid bow";
    else if (my_familiar() == $familiar[chest mimic])              famEquipment = ", equip toy cupid bow";
    else if (my_familiar() == $familiar[mini kiwi])                famEquipment = ", equip aviator goggles";
    else if (my_familiar() == $familiar[Meat Shield Maiden])       famEquipment = ", equip can of shield tenderizer";
    else                                                           famEquipment = ", equip tiny stillsuit";

    buffer maximize = preAdvMaximize();
    append(maximize, famEquipment);

    if (get_property("subscript") == "drunkPygmy" && my_location() == $location[The Hidden Bowling Alley]){
        // Keep the farming outfit simple; wanderers use the normal combat handlers.
        append(maximize, ", equip latte lovers member's mug");
    } else {
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
        // Shirt
        if (have_equipped($item[devilbone corset]))
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
    if (get_property("_seadentWaveUsed") == "false") {
        if (dayType() == 0 && contains_text(get_property("lastEncounter"), "gingerbread")) {
            use_skill($skill[Sea *dent: Summon a Wave]);
        }
    }
// --dont flood the shadow realm in hat path
//            else if (dayType() == 1 && contains_text(get_property("lastEncounter"),"shadow")){
//                use_skill($skill[Sea *dent: Summon a Wave]);

    //monster level
    foreach ef in $effects[Ur-Kel's Aria of Annoyance,Pride of the Puffin,Bloodbathed,Misplaced Rage,Manbait,Sweetbreads Flamb&eacute;,Red Lettered,Spangled Star,Tortious,Litterbug,Not Sharing,Para-lyzed Jaw,Contemptible Emanations,Lapdog,Ashen Burps,The Cupcake of Wrath,Gelded,Mysteriously Handsome]{
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
}

void setupBARF(){
    // TODO: Add BARF familiar, gear, buffs, and recovery settings here.
    // Familiar equipment: placeholder for BARF-specific selection.
}

// General gear fallback, also used by TeresMimic's embezzler phase.
void setupDefault(){
    boolean clubEmReady = get_property("clubEmNextWeekMonster") != "" && total_turns_played() >= get_property("clubEmNextWeekMonsterTurn").to_int() + 8;
    boolean clubEmExact = total_turns_played() == get_property("clubEmNextWeekMonsterTurn").to_int() + 8;
    boolean jokesterReady = get_property("_firedJokestersGun") == "false";
    boolean avalancheReady = get_property("_mcHugeLargeAvalancheUses").to_int() < 3;
    boolean spikeReady = get_property("_spikolodonSpikeUses").to_int() < 5;
    boolean batReady = get_property("_batWingsFreeFights").to_int() < 5;
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
        else if (batReady)
            append(maximize, ", equip bat wings");
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
        setupFreeKill();
    else if (get_property("script") == "BARF")
        setupBARF();
    else
        // dailyFKs switches script to "embezzler" for Lucky! Treasury fights; use the general gear setup.
        setupDefault();

    // Shared supplies for the combat scripts.
    // Required for FreeKill stalling: stop before combat if acquisition fails.
    if (get_property("script") == "FreeKill" && item_amount($item[facsimile dictionary]) == 0) {
        retrieve_item(1, $item[facsimile dictionary]);
        if (item_amount($item[facsimile dictionary]) == 0)
            abort("FreeKill requires a facsimile dictionary; Combat was not started. Go get one before running again.");
    }
    if (item_amount($item[peppermint parasol]) == 0
        && !retrieve_item(1, $item[peppermint parasol]))
        print("[DEBUG] Could not acquire a peppermint parasol before combat; continuing.", "red");
    if (item_amount($item[dry noodles]) < 2)
        retrieve_item(2,$item[dry noodles]);
    if (item_amount($item[lit leaf lasso]) < 2)
        buy(2,$item[lit leaf lasso]);
    if (item_amount($item[logic grenade]) < 2)
        retrieve_item(2,$item[logic grenade]);
    if (item_amount($item[glitched malware]) < 1)
        retrieve_item(1,$item[glitched malware]);
    if (get_property("subscript") == "weakling" || get_property("subscript") == "looseFK"){
        if (closet_amount($item[shard of double-ice]) > 0)
            take_closet($item[shard of double-ice]);
        else
            retrieve_item($item[shard of double-ice]);
    } else {
        put_closet(item_amount($item[shard of double-ice]),$item[shard of double-ice]);
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
        if (item_amount($item[dry noodles]) == 0)
            retrieve_item($item[dry noodles]);
        if (item_amount($item[4-D camera]) == 0)
            retrieve_item($item[4-D camera]);
        cli_execute("checkpoint clear");
        mood("");
    } finally {
        set_property("betweenBattleScript",boof);
    }
}
