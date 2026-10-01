// ═══ Dinner.ash ══════════════════════════════════════════════════════════════
// End-of-day wind-down chores. This pass is a pure reshape of the old flat
// top-to-bottom script into named phases -- every condition and cli_execute
// string is unchanged, just pulled into functions and called in the same
// order from main().

void step(string msg){
    print("DN: " + msg, "blue");
}

// ─── PHASES ──────────────────────────────────────────────────────────────────

// Heavy familiar weight (>350): top off spleen with Extrovermectin/mojo
// filters, then fill the last few booze slots (hot socks at 3-from-limit,
// vintage smart drink once maxed).
void heavyWeightBooze(){
    int n = fullness_limit() - my_fullness() + to_int(!have_equipped($item[devilbone corset])) + to_int(!have_equipped($item[angelbone chopsticks]));
    if (n == 3){
        equip($item[devilbone corset]);
        equip($item[angelbone chopsticks]);
    }
    if (my_inebriety() <= inebriety_limit()){
        equip($slot[acc3],$item[devilbone rosary]);
        equip($slot[acc2],$item[angelbone dice]);
        use_familiar($familiar[stooper]);
        cli_execute("uneffect ur-kel; cast 2 ode");
        cli_execute("/whitelist hyrule");
        cli_execute("drink hot socks");
        drink($item[vintage smart drink]);
    }
    if (my_spleen_use() < spleen_limit()){
        equip($item[devilbone greaves]);
        equip($item[angelbone totem]);
        int toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
        int mojo = 3-get_property("currentMojoFilters").to_int();
        use(mojo,$item[mojo filter]);
        toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
    }
}

void pvpCombat(){
    int peevp = pvp_attacks_left();
    if (peevp > 70) {
        cli_execute("pvpcombat");
    }
}

void takerspaceStart(){
    if (get_property("_workshedItemUsed") == "false" && get_workshed( ) != $item[TakerSpace letter of Marque]){
        cli_execute("use takerspace");
    }
}

void augSkills(){
    if (get_property("_augSkillsCast") < 5){
        cli_execute("cast Aug. 13th");
        if (get_property("_augSkillsCast") < 5)
            cli_execute("cast Aug. 7th");
    }
    if (get_property("_heartstoneLuckUsed") == "false"){
        use_skill($skill[heartstone: %LUCK]);
    }
}

void clockworkMaid(){
    if (!contains_text(visit_url("campground.php?action=inspectdwelling"),"maid2"))
        cli_execute("use clockwork maid");
}

// Weight-gated closing outfit, then refresh inventory.
void finalOutfit(){
    if (numeric_modifier("familiar weight") > 350){
        cli_execute("maximize pvp fights, equip spacegate military insignia, equip ratskin pajama pants");
    }else
        cli_execute("familiar jill;maximize adv");
}

// If more adventures are already banked/incoming than the day can plausibly
// spend, offer to burn day shorteners on the overflow.
void dayShorteners(){
    float wastedAdv = to_float(my_adventures()) + to_float(numeric_modifier("Adventures")) + 40 - 200;
    if (wastedAdv > 0){
        if (user_confirm("Use "+ (wastedAdv/5) + " day shorteners?")){
            use(ceil(wastedAdv/5),$item[day shortener]);
        }
    }
}

// Philter the day's booze, then park anything over 3M meat in the closet.
void closingMeatChores(){
    cli_execute("philter");
    if (my_meat() - 3000000 > 0){
        int new_meat = my_meat() - 3000000;
        visit_url("closet.php?addtake=add&action=addtakeclosetmeat&quantity=" + new_meat);
    }
}

string messages(){
    return visit_url("messages.php");
}

// ── Fart Scauce only ────────────────────────────────────────────────────────
// Personal inbox housekeeping: deletes kmails from a handful of trade bots and
// every "Loathing Postal Service" package notice on each run. The sender ids are
// account-specific and the Postal Service sweep is destructive with no prompt
// (it would eat gift packages, IOTM deliveries, etc.), so it only runs for this
// character. Every other account skips the whole block.
void fartScauceInboxCleanup(){
    if (my_name().to_lower_case() != "fart scauce")
        return;
    int deleted = 0;
    foreach str in $strings[3690803,1053259,1699424,1533476,3877087]{
        matcher m = create_matcher("name=\"sel(\\d+)\"></td><td class=small><b>From</b> <a href=\"showplayer\\.php\\?who=" + str, messages());
        while (m.find()){
            visit_url("messages.php?the_action=delete&box=Inbox&sel"+ m.group(1) + "=on");
            deleted += 1;
        }
    }
    matcher m = create_matcher("name=\"sel(\\d+)\"></td><td class=small><b>From</b> The Loathing Postal Service", messages());
    while (m.find()){
        visit_url("messages.php?the_action=delete&box=Inbox&sel"+ m.group(1) + "=on");
        deleted += 1;
    }

    print( deleted + " messages deleted");
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    step("phase: heavy weight booze");
    heavyWeightBooze();
    step("phase: pvp");
    pvpCombat();
    step("phase: takerspace");
    takerspaceStart();
    step("phase: aug skills");
    augSkills();
    cli_execute ("maximize adv; av-snapshot.ash");
 //   step("phase: clockwork maid");
   // clockworkMaid();
    step("phase: final outfit");
    finalOutfit();
    step("phase: day shorteners");
    dayShorteners();
    step("phase: closing meat chores");
    closingMeatChores();
    if (!contains_text(get_property("thoth19_event_list"),"postFarmD1"))
        cli_execute("ptrack add postFarmD1");
    step("phase: inbox cleanup");
    fartScauceInboxCleanup();
}
