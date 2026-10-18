// teresspelunky.ash
// Spelunky automation:
// - Start Spelunky if necessary
// - Attack with Weapon
// - Visit LOLmec's Lair once
// - Farm Temple Ruins
// - Automatically quit when Spelunky time runs out
// - Restore original settings


// ============================================
// SPELUNKY TIME TRACKING
// ============================================

int spelunkyTurnsRemaining() {
    string status = get_property("spelunkyStatus");

    if (!contains_text(status, "Turns: "))
        abort("Spelunky: Could not read the remaining turns; refresh the character pane before resuming.");

    string turns = substring(status, index_of(status, "Turns: ") + 7);
    int comma = index_of(turns, ",");

    if (comma >= 0)
        turns = substring(turns, 0, comma);

    return to_int(turns);
}


// ============================================
// START SPELUNKY
// ============================================

void startSpelunky() {
    string savedChoice = get_property("choiceAdventure993");

    try {
        set_property("choiceAdventure993", "1");

        if (!retrieve_item(1, $item[Tales of Spelunking]))
            abort("Could not acquire Tales of Spelunking.");

        if (!use(1, $item[Tales of Spelunking]))
            abort("Could not use Tales of Spelunking.");

        if (handling_choice() && last_choice() == 993)
            run_choice(1);

    } finally {
        set_property("choiceAdventure993", savedChoice);
    }
}


// ============================================
// QUIT SPELUNKY
// ============================================

void quitSpelunky() {
    if (limit_mode() != "spelunky" && !handling_choice()) {
        print("Spelunky: Already finished and back in the normal game.", "green");
        return;
    }
    if (current_round() > 0 || in_multi_fight())
        abort("Spelunky: Resolve the unfinished fight before quitting.");
    print("Spelunky: Time is up. Quitting Spelunky.", "blue");

    // Open the Spelunky quit confirmation.
    if (!handling_choice())
        visit_url("place.php?whichplace=spelunky&action=spelunky_quit");
    if (limit_mode() != "spelunky" && !handling_choice()) {
        print("Spelunky: Quit completed automatically.", "green");
        return;
    }

    // Choice #1027: The End of the Tale of Spelunking.
    if (handling_choice() && last_choice() == 1027) {
        string [int] options = available_choice_options();

        print("Spelunky: Available quit options:", "blue");

        foreach option, description in options {
            print(option + ": " + description, "blue");
        }

        // Find the option to close the book.
        foreach option, description in options {
            if (contains_text(to_lower_case(description), "close the book")) {
                run_choice(option);
                if (handling_choice() || limit_mode() == "spelunky")
                    abort("Spelunky: Finish the remaining exit/perk choice before resuming BARF.");
                print("Spelunky: Successfully submitted quit confirmation.", "green");
                return;
            }
        }

        abort("Spelunky: Could not find the quit confirmation option.");
    }

    abort("Spelunky: Expected choice #1027 but did not encounter it.");
}


// ============================================
// MAIN SCRIPT
// ============================================

void main() {
    if (limit_mode() != "" && limit_mode() != "spelunky")
        abort("Spelunky: Cannot start while another special game mode is active.");
    if (current_round() > 0 || in_multi_fight()
        || (handling_choice() && last_choice() != 1027))
        abort("Spelunky: Resolve the pending fight or choice before starting.");
    string savedChoice1036 = get_property("choiceAdventure1036");
    string savedChoice1037 = get_property("choiceAdventure1037");
    string savedScript = get_property("choiceAdventureScript");
    string savedBefore = get_property("betweenBattleScript");
    string savedAfter = get_property("afterAdventureScript");
    string savedCombat = get_property("battleAction");
    int savedAutoAttack = get_auto_attack();

    boolean visitedLOLmec = false;

    try {
        set_auto_attack(1);
        set_property("betweenBattleScript", "");
        set_property("afterAdventureScript", "");
        set_property("battleAction", "attack with weapon");

        // Prevent recursive execution of this script.
        set_property("choiceAdventureScript", "");

        // Built-in choices.
        set_property("choiceAdventure1036", "4");
        set_property("choiceAdventure1037", "6");

        // Start Spelunky if not already inside.
        // The saved status can retain zero turns after leaving a previous run.
        if (handling_choice() && last_choice() == 1027) {
            quitSpelunky();
            return;
        }
        if (limit_mode() != "spelunky")
            startSpelunky();
        if (limit_mode() != "spelunky")
            abort("Spelunky: The book did not start a run.");
        visit_url("charpane.php");

        // ============================================
        // ADVENTURE LOOP
        // ============================================

        while (limit_mode() == "spelunky" && spelunkyTurnsRemaining() > 0) {
            if (handling_choice() && last_choice() == 1027) break;

            // Attempt LOLmec once per script execution.
            if (!visitedLOLmec
                && contains_text(get_property("spelunkyStatus"), "LOLmec's Lair")) {

                visitedLOLmec = true;

                print("Spelunky: Checking LOLmec's Lair.", "blue");

                if (!adv1($location[LOLmec's Lair])) {
                    print(
                        "LOLmec unavailable or already defeated. Continuing.",
                        "blue"
                    );
                }

                continue;
            }

            // Set #1037 based on whether the golden door is still needed.
            if (contains_text(get_property("spelunkyStatus"), "City of Goooold")) {
                set_property("choiceAdventure1037", "6");
            }
            else {
                set_property("choiceAdventure1037", "2");
            }

            // Stop if Spelunky time has run out.
            if (spelunkyTurnsRemaining() <= 0)
                break;

            // Farm Temple Ruins.
            if (!adv1($location[The Temple Ruins])) {
                print("Temple Ruins adventure failed. Stopping.", "red");
                break;
            }
        }

        // ============================================
        // QUIT SPELUNKY WHEN TIME RUNS OUT
        // ============================================

        if (limit_mode() != "spelunky" || (handling_choice() && last_choice() == 1027)
            || spelunkyTurnsRemaining() <= 0) {
            quitSpelunky();
        }
        else abort("Spelunky: The run stopped with turns remaining; resume Spelunky before BARF continues.");

    } finally {

        // Restore original settings.
        set_property("choiceAdventure1036", savedChoice1036);
        set_property("choiceAdventure1037", savedChoice1037);
        set_property("choiceAdventureScript", savedScript);
        set_property("betweenBattleScript", savedBefore);
        set_property("afterAdventureScript", savedAfter);
        set_property("battleAction", savedCombat);
        set_auto_attack(savedAutoAttack);
    }
}
