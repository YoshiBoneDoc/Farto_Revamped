/**
 *          ~ teresBARF.ash ~
 * Turn-burning script for BARF Mountain.
 * Hat Path has no Sea access, so remaining turns are spent at BARF.
 *
 * - Currently designed for Hat Path aftercore
 * - Run after bulkFKD1() in TeresMimic.ash
 */


//  ---- HELPER FUNCTIONS ----

// Template
function downUse(consumable: string, amount: number): void {
    let consume: Item = Item.get(consumable);
    if (itemAmount(consume) < 1) retrieveItem(consume, 1);
    use(consume, amount); //  +1 full cap 60k
}

// Template
function downDrink(consumable: string, amount: number): void {
    let consume: Item = Item.get(consumable);
    if (itemAmount(consume) < 1) retrieveItem(consume, 1);
    drink(consume, amount); //  +1 full cap 60k
}


// ---- MAIN EXPORT FUNCTION ----
export function garboDiet() {



/*  run plan? kind of

    //cli_execute("garbo quick");

    // bulk of main stuff
    cli_execute("familiar Cooler Yeti");
    cli_execute("equip amulet coin");
    cli_execute("outfit capacity");
    cli_execute("use clockwork maid");
    cli_execute("/whitelist Bonus Adventures from Hell");
    cli_execute("acquire carpe");
    cli_execute("equip carpe");

    //buffs for fam exp
    cli_execute("/whitelist soup clan");
    cli_execute("use 10 white candy heart");
    cli_execute("use 10 pulled blue taffy");
    cli_execute("use 10 deviled");
    cli_execute("use 50 scams");
    cli_execute("use 6 flapper fly");
    cli_execute("use 3 savings bond");
    cli_execute("use 3 autumn dollar");
    cli_execute("use 4 pork elf mouthwash");
    cli_execute("use 5 be wealthier");

    //partial diet for yeti charge
    cli_execute("use 2 mini kiwi aioli");
    cli_execute("eat roasted vegetable focaccia");
    cli_execute("synthesize Synthesis: Greed");
    cli_execute("synthesize Synthesis: Greed");

    //adventure a few to get xp on cooler Yeti
    cli_execute("adventure 15 Barf Mountain");

    //use the yeti for looking cool
    cli_execute("cast ode");

    //drink 1
    visit_url("main.php?talktoyeti=1, false");
    run_choice(3);
    run_choice(3);
    cli_execute("/drink Ambitious Turkey");

    //drink 2
    visit_url("main.php?talktoyeti=1, false");
    run_choice(3);
    run_choice(3);
    cli_execute("/drink Ambitious Turkey");

    // top off and adventure
    cli_execute("CONSUME ALL");
    cli_execute("adventure * Barf Mountain");

    // Stooper
    cli_execute("familiar Stooper");
    cli_execute("equip amulet coin");
    cli_execute("cast ode");
    cli_execute("/drink Ambitious Turkey");

//DRINK NIGHTCAP MANUALLY SO U CAN USE UR YETI
    //cli_execute("CONSUME NIGHTCAP");

    cli_execute("PVP_MAB");
    cli_execute("Hobo.js breakfast");

    //cli_execute("wear burning cape");
    //cli_execute("make snow belt");
    cli_execute("maximize adv");
    cli_execute("wear ratskin pants");

    someHelperFunction();
*/

}
