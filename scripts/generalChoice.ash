import iotm.ash;

int ESPmission(string page){
    int num;
    if (contains_text(page, "ever-changing constellation")){
        num = 1;
    }
    if (contains_text(page, "circle of light")){
        num = 2;
    }
    if (contains_text(page, "waves a fly")){
        num = 3;
    }
    if (contains_text(page, "back to square one")){
        num = 4;
    }
    if (contains_text(page, "adds to your anxiety")){
        num = 5;
    }
    return num;
}

// ─── Darts perk priority (choice 1525) ──────────────────────────────────────
// Ported from garbo-choice DART_PERKS: lower index = more preferred. An option
// not in the list is never taken unless it's the only kind offered.
string[int] dartPerks = {
    "Bullseyes do not impress you much",
    "You are less impressed by bullseyes",
    "25% better chance to hit bullseyes",
    "25% More Accurate bullseye targeting",
    "25% Better bullseye targeting",
    "Extra stats from stats targets",
    "Expand your dart capacity by 1",
    "Throw a second dart quickly",
    "Butt awareness",
    "Increase Dart Deleveling from deleveling targets",
    "Add Hot Damage",
    "Add Cold Damage",
    "Add Sleaze Damage",
    "Add Spooky Damage",
    "Add Stench Damage",
    "Deal 25-50% more damage",
    "Deal 25-50% extra damage",
    "Deal 25-50% greater damage"
};

int bestDartsOption(){
    string[int] opts = available_choice_options();
    int bestNum;
    int bestRank = 999;
    boolean seen;
    foreach num, text in opts{
        int rank = 999;
        foreach i, perk in dartPerks
            if (text == perk || contains_text(text, perk)){
                rank = i;
                break;
            }
        if (!seen || rank < bestRank){
            seen = true;
            bestRank = rank;
            bestNum = num;
        }
    }
    return bestNum;
}

// ─── Voting booth (choice 1331) ─────────────────────────────────────────────
// Ported from garbo-choice voterSetup: pick the better of _voteMonster1/2 for
// the g= field, and the highest-priority _voteLocal1..4 for both local[] picks.
// garbo's exact meat projection isn't reproducible here, so the initiative
// weights are hand values; Adventures uses valueOfAdventure.
float[string] voteInitPriority = {
    "Meat Drop: +30":               100.0,
    "Item Drop: +15":               30.0,
    "Adventures: +1":               get_property("valueOfAdventure").to_float(),
    "Familiar Experience: +2":      8.0,
    "Monster Level: +10":           5.0,
    "Muscle Percent: +25":          3.0,
    "Mysticality Percent: +25":     3.0,
    "Moxie Percent: +25":           3.0,
    "Experience (Muscle): +4":      2.0,
    "Experience (Mysticality): +4": 2.0,
    "Experience (Moxie): +4":       2.0,
    "Meat Drop: -30":               -2.0,
    "Item Drop: -15":               -2.0,
    "Familiar Experience: -2":      -2.0
};

float voteItemValue(item it){
    int h = historical_price(it);
    return to_float(h > 0 ? h : autosell_price(it));
}

float voteMonsterValue(monster m){
    switch (m){
    case $monster[terrible mutant]:      return voteItemValue($item[glob of undifferentiated tissue]) + 10;
    case $monster[angry ghost]:          return voteItemValue($item[ghostly ectoplasm]) * 1.11;
    case $monster[government bureaucrat]: return voteItemValue($item[absentee voter ballot]) * 0.05 + 68.75;
    case $monster[annoyed snake]:        return to_float(gameday_to_int());
    case $monster[slime blob]:           return 95.0 - gameday_to_int();
    }
    return 0;
}

int voteMonsterPick(){
    return voteMonsterValue(to_monster(get_property("_voteMonster1")))
        >= voteMonsterValue(to_monster(get_property("_voteMonster2"))) ? 1 : 2;
}

// The booth keeps TWO of the four offered initiatives. Return the 0-indexed
// positions of the best two _voteLocal1..4, highest first.
int[int] voteLocalPicks(){
    float[int] val;
    for i from 1 to 4{
        string loc = get_property("_voteLocal" + i);
        val[i - 1] = voteInitPriority contains loc
            ? voteInitPriority[loc]
            : (contains_text(loc, "-") ? -1.0 : 1.0);
    }
    int first, second;
    boolean haveFirst, haveSecond;
    foreach idx, v in val{
        if (!haveFirst || v > val[first]){
            second = first; haveSecond = haveFirst;
            first = idx;    haveFirst = true;
        } else if (!haveSecond || v > val[second]){
            second = idx;   haveSecond = true;
        }
    }
    int[int] out;
    out[0] = first;
    out[1] = second;
    return out;
}

void main(int whichchoice, string page) {
    if (get_property("script") == "BARF" && whichchoice == 1073){
        item saved = equipped_item($slot[acc3]);
        try {
            if (get_property("questEStSuperLuber") == "started" && available_amount($item[lube-shoes]) > 0)
                equip($slot[acc3],$item[lube-shoes]);
            run_choice(1);
        } finally { equip($slot[acc3],saved); }
        return;
    }
    if (whichchoice == 536){
        item pill;
        int target;
        if (available_amount($item[distention pill]) < available_amount($item[synthetic dog hair pill])) {
            pill = $item[distention pill];
            target = 1;
        } else {
            pill = $item[synthetic dog hair pill];
            target = 2;
        }
        int start = available_amount(pill);

        //keep trying even on server errors
        int tries = 0,max = 5;
        repeat {
            //do the choice chain to evenly get pills
            if (available_choice_options()[1] == "Down the Hatch!")
                run_choice(1);
            if (available_choice_options()[1] == "Have a Drink")
                run_choice(1);
            if (available_choice_options()[2] == "Try That One Door")
                run_choice(2);
            if (available_choice_options()[1] == "Follow Captain Smirk")
                run_choice(target);
            //if still in choice, give it a few seconds before trying again
            if (handling_choice()) {
                print("problem encountered while handling the choice","blue");
                if (++tries < max) {
                    print("waiting a few seconds to try again","blue");
                    wait(5);
                }
                else {
                    print(`giving up after {tries} tries`,"red");
                }
            }
        } until (!handling_choice());
    }
    switch (whichchoice){
        // ── simple: a single fixed run_choice(#), grouped by that number, then by case # ──
        case 633:
        case 705:
        case 1344:
        case 1471:
        case 1472:
        case 1475:
        case 1566:
            run_choice(1);
            break;

        case 693:
        case 857:
        case 866:
        case 1202:
            run_choice(2);
            break;

        case 690:
        case 691:
        case 692:
        case 793:
        case 920:
        case 1208:
        case 1467:
        case 1469:
            run_choice(3);
            break;

        case 584:
            run_choice(4);
            break;

        case 1599:
            run_choice(5);
            break;

        case 781:
        case 783:
        case 791:
        case 1119:
        case 1237:
        case 1250:
            run_choice(6);
            break;

        // ── complex: conditional / multiple / dynamic run_choice, or none at all -- sorted by case # ──
        // Was `case 211: case 1310: run_choice(1);` falling through into 1467's
        // run_choice(3); inlined here so 1467 could move up to the simple run_choice(3)
        // group above.
        case 211:
        case 1310:
            run_choice(1);
            run_choice(3);
            break;
        case 787:
            run_choice(1);
            run_choice(6);
            break;
        case 218:
            if (get_property("choiceAdventure218") == "0"){
                buffer heapQueue = to_buffer(get_property("heapQueue"));
                append(heapQueue, ", " + last_choice());
                delete(heapQueue,0,5);
                set_property("heapQueue",to_string(heapQueue));
            }
            if (get_property("script") == "junko")
                user_confirm("Heap manually");
            break;
        // Slime Tube uvula/gall-bladder choice. <clanId>Tickled state (set by
        // slime.ash / advanced by unlockerCCS): "done"/"ML" -> skip (option 2);
        // fresh ("" / "started") + a caustic slime nodule -> tickle (option 1),
        // stamp "tickled". Tickling is once per instance.
        case 337:
            if (get_property(get_clan_id() + "Tickled") == "done"){
                run_choice(2);
            } else if (get_property(get_clan_id() + "Tickled") == "ML"){
                run_choice(2);
            } else if (item_amount($item[caustic slime nodule]) > 0 && (get_property(get_clan_id() + "Tickled") != "finished" && get_property(get_clan_id() + "Tickled") != "ML" && get_property(get_clan_id() + "Tickled") != "tickled")){
                run_choice(1);
                set_property(get_clan_id() + "Tickled","tickled");
            } else {
                run_choice(2);
            }
            break;
        case 360:
            if (item_amount($item[memory of a glowing crystal]) == 0){
                run_choice(1);
                cli_execute("porkfuture");
            } else {
                run_choice(2);
            }
            break;
        // Was `case 399/400/401:` (queue update, no break) falling through into
        // `case 1344: case 705: run_choice(1);`; the run_choice(1) is inlined here so
        // 1344 and 705 could move up to the simple run_choice(1) group above.
        case 399:
        case 400:
        case 401:
            buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
            run_choice(1);
            break;
        case 443:
            cli_execute("chess solve");
            break;
        case 451:
            if (item_amount($item[plus sign]) == 0){
                run_choice(3);
            } else {
                run_choice(5);
            }
            break;
        case 580:
            run_choice(2);
            run_choice(4);
            run_choice(1);
            break;
        case 627:
            run_choice(to_int(get_property("chibiChoice1")));
            run_choice(to_int(get_property("chibiChoice2")));
            run_choice(7);
            break;
        case 696:
            if (get_property("maraisDarkUnlock") == "false"){
                run_choice(1);
            }
            if (get_property("maraisWildlifeUnlock") == "false"){
                run_choice(2);
            }
            break;
        case 697:
            if (get_property("maraisCorpseUnlock") == "false"){
                run_choice(1);
            }
            if (get_property("maraisWizardUnlock") == "false"){
                run_choice(2);
            }
            break;
        case 698:
            if (get_property("maraisBeaverUnlock") == "false"){
                run_choice(1);
            }
            if (get_property("maraisVillageUnlock") == "false"){
                run_choice(2);
            }
            break;
        // Was falling through into the run_choice(6) group above; the run_choice(6)
        // is inlined here so that group could stay a clean simple group.
        case 785:
            if (have_equipped($item[candy cane sword cane]))
                run_choice(4);
            run_choice(6);
            break;
        case 918:
            if (to_int(today_to_string()) > to_int(format_date_time("yyyy-MM-dd",get_property("umdLastObtained"),"yyyyMMdd"))){
                run_choice(1);
            } else {
                run_choice(3);
                run_choice(2);
            }
            break;
        case 919:
            if (to_int(get_property("_sloppyDinerBeachBucks")) < 4){
                run_choice(1);
            } else {
                run_choice(6);
            }
            break;
        case 923:
            if (get_property("candyCaneSwordBlackForest") == "false" && have_equipped($item[candy cane sword cane]))
                run_choice(5);
            run_choice(1);
            run_choice(1);
            break;
        case 989:
            print (ESPmission(page));
            break;
        case 1076:
            if (get_property("mayoMinderSetting") == "")
                run_choice(2);
            else
                run_choice(6);
            break;
        case 1114:
            if (whichchoice == 1114){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    print(`{num}: {choice_text}`);
                }
                foreach task in $strings[moonbeams,blood,bolts, ice, chicken, chum, milk, rain]{
                    foreach num, choice_text in choices {
                        if (contains_text(choice_text,task)){
                            run_choice(num);
                            exit;
                        }
                    }
                }
                run_choice(1);
            }
            break;
        case 1115:
            if (get_property("_VYKEALoungeRaided") == false){
                run_choice(4);
            } else{
                run_choice(3);
            }
            break;
        case 1116:
            if (get_property("_iceHotelRoomsRaided") == false){
                run_choice(5);
            } else{
                run_choice(3);
            }
            break;
        case 1203:
            if (item_amount($item[sprinkles]) > 550)
                run_choice(2);
            else
                run_choice(4);
            break;
        case 1468:
            run_choice(4);
            run_choice(3);
            break;
        case 1470:
            run_choice(4);
            run_choice(2);
            break;
        case 1473:
            run_choice(4);
            run_choice(1);
            break;
        case 1474:
            run_choice(4);
            run_choice(2);
            break;
        case 1483:
            run_choice(1);
            run_choice(3);
            break;
        case 1497:
            if (have_effect($effect[shadow affinity]) > 0){
                run_choice(2);
            } else if (get_property("rufusDesiredEntity") == "shadow scythe"){
                run_choice(2);
            } else{
                run_choice(1);
            }
            break;
        case 1331: {
            // I Voted! booth: best monster for g=, best two distinct initiatives for local[].
            int[int] lp = voteLocalPicks();
            string url = "choice.php?whichchoice=1331&option=1&g=" + voteMonsterPick()
                + "&local[]=" + lp[0] + "&local[]=" + lp[1];
            print(url);
            visit_url(url);
            break;
        }
        case 1525:
            run_choice(bestDartsOption());
            break;
        case 1557:
            if (my_location() == $location[the black forest]){
                if (item_amount($item[broken wings]) == 0){
                    run_choice(1, "bandersnatch=416");
                } else if (item_amount($item[sunken eyes]) == 0){
                    run_choice(1, "bandersnatch=414");
                }
            }
            if (my_location() == $location[Madness Bakery])
                run_choice(1, "bandersnatch=1748");
            if (my_location() == $location[barf mountain])
                run_choice(1, "bandersnatch=1760");
            if (my_location() == $location[the marinara trench] && my_class() == $class[accordion thief])
                run_choice(1, "bandersnatch=763");
            else {
                run_choice(2);
            }
            break;
        case 1562: {
            // First available entry wins. Keep separate lists so each script can be tuned.
            string[int] priorities;
            if (get_property("script") == "FreeKill") {
                priorities = {
                    "Fix your parents' relationship",
                    "Repay yourself in the past",
                    "Let yourself get lifted up by your bootstraps",
                    "Take the long odds on the trifecta",
                    "Fix the race and also fix the race"
                };
            } else if (get_property("script") == "BARF") {
                priorities = {
                    "Meet your parents when they were young",
                    "Borrow meat from your future",
                    "Lift yourself up by your bootstraps",
                    "Take the long odds on the trifecta",
                    "Fix the race and also fix the race"
                };
            }

            // Use this list when the script's preferred choices aren't offered,
            // or when another script reaches this choice. Preserve the original list order.
            string[int] fallbackPriorities = {
                "Go back and set an alarm",
                "Go back and take a 20-year-long nap"
            };
            string[int] choices = available_choice_options();
            int selectedOption = 0;
            for pass from 1 to 2 {
                if (pass == 2)
                    priorities = fallbackPriorities;
                foreach rank, preferred in priorities {
                    foreach num, choice_text in choices {
                        if (contains_text(choice_text, preferred)) {
                            selectedOption = num;
                            break;
                        }
                    }
                    if (selectedOption != 0)
                        break;
                }
                if (selectedOption != 0)
                    break;
            }
            if (selectedOption == 0) {
                print("[DEBUG] No listed Mobius ring choice is available; choose manually.", "red");
                break;
            }
            run_choice(selectedOption);
            if (have_effect($effect[Marked by the Don]) > 0) {
                if (!handling_choice() && have_skill($skill[Disco Nap]))
                    use_skill(1, $skill[Disco Nap]);
                if (have_effect($effect[Marked by the Don]) > 0)
                    print("[DEBUG] Could not clear Marked by the Don with Disco Nap.", "red");
            }
            break;
        }
        case 1596:
            set_property("NCtoC","true");
            run_choice(3);
            break;
    }
}
