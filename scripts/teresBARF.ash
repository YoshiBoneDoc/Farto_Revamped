/**
 *          ~ teresBARF.ash ~
 * Turn-burning script for BARF Mountain.
 * Hat Path has no Sea access, so remaining turns are spent at BARF.
 *
 * - Currently designed for Hat Path aftercore
 * - Run after bulkFKD1() in TeresMimic.ash
 */

import TeresMimic.ash;

//  ---- HELPER FUNCTIONS ----

// Template
void dailyMoodAndNightcap(){
/*        TEMPLATE
    cli_execute("mood apathetic; uneffect cletus");
    if (get_property("lawOfAveragesAvailable") == true)
        use($item[law of averages]);
    use_familiar($familiar[Stooper]);
    equip($item[devilbone rosary]);
    equip($item[angelbone dice]);
    cli_execute("CONSUME NIGHTCAP");
    */
}

// Template
void BARFprep(){



/*
        -vip clan
        1. drink 1 TRIO with paw(1) + yeti
        2. get carpe
        3. get 2002 stuff
        4. favorite bird
        5. war concert
        6. summon chamber
        7. bcz flush
        8. VIP clan buffs
        9. august lighthouse
        10. calc universe
        11. buffs (trivialskills, others)
        12. mayan calender


        for roaming cockroach at barf (be gregarious from spleening extro)
            ccs:
                if monstername cockroach && hasskill Be Gregarious
                    skill be gregarious
                endif
                skill bowl straight up
                attack with weapon






                TEMPLATE
    cli_execute("mood apathetic; uneffect cletus");
    if (get_property("lawOfAveragesAvailable") == true)
        use($item[law of averages]);
    use_familiar($familiar[Stooper]);
    equip($item[devilbone rosary]);
    equip($item[angelbone dice]);
    cli_execute("CONSUME NIGHTCAP");
    */
}



// ---- MAIN EXPORT FUNCTION ----
export function garboDiet() {

/*
    _______ Working Blueprint ________
    1. daily chores - BARFprep()

        - buff keep
        - DRINKS:
            - stillsuit (calculations below)
            - 5 beers + 5 paws + Yetis ("TRIO cup of beer" looks like best option): 11.5/drunk ~ 6-7 (TRIO) + 4-6 (Salty Mouth)
                cli:    - monkeypaw effect Salty Mouth
                        - yeti cool
            - Gets-You-Drunk: 8/drunk ~ 2 booze for 16-20 adv (8-10 plus another 8-10 after 4 combats)
        - mall check
        - burn bcz
        - bird a day
        - blue rocket or candle shit
        - sweatpants
        - maybe gets-you-drunk
        - pasta
        - 5 knucklebones from rests
        - trick or treat
        - amulet coin
    - possibly some dieting at end of free kills
    - save room to drink while adventuring with sweatsuit + paw wishes for beer + yeti
            ..cast shit ton of ode
            1. cli_execute("monkeypaw effect salty mouth;")
            2. code for yeti:
                Looking Cool effect = cli_execute("ash visit_url("main.php?talktoyeti=1",false,true).buffer_to_file("_yeti_talk2.html"); run_choice(3); run_choice(1);");
                Double Booze = cli_execute("ash visit_url("main.php?talktoyeti=1",false,true).buffer_to_file("_yeti_talk2.html"); run_choice(2); run_choice(1);");
            3. cli_execute("drink party beer bomb;")    <-- TRIO cup optimal but not sure if worth 17k for avg 1 extra adventure over (500 meat) party beer bomb (6-7 vs 5-6 adv)
            4. -- yeti 2x boose
            5. -- frosty mug + dread cold-fash
            ..use shit ton of kiwi aioli
            tubetto With my Spleen
                //calc if roasted veg of F better (8adv/full):(15-17/2full) but no buff (only +10 fam xp) --OR-- ghost pepper (17.5adv/full):(16-19/2full)
                //gotta also account for advs lost from tubetto
            tubetto double food buffs
            3x boris bread
            tubetto double food buffs
            3x prize turkey - (5.5adv/full):(10-12 adv/2 full) + 50 turns(x2 with tubetto) of +100% meat
                ::OR Jumping horse radish (5-6adv/1full), 50 turns(x2 with tub) of 100% meat (maybe better since 1 full? + WAY cheaper)
            6. sweat out booze
            - yeti + fermented pickle J to remove spleen
            - swwet synthesis
            - aug 16th for -1 full
            - cup of 13s (maybe? should be depleted)
                - 3x sponge pants gives 80x3=240 turns of +100% meat but 3 adv
            - consider spleening extrovermectin for killing roaming roaches (be gregarious - 3 killed per pill)




    - burn pvp adventures before next step
    - at the end use extra diet from ascension rewards for +LB buffs (possibly, unless we are way over rollover adventures
    - use up batwing flaps mp
    - shrunken head (see preAdv)
    - 1 zap with wand maybe
    - free mining
    - law of averages?
    -  use Jerks' Health™ Magazine for pvp fights
    - spelunky?


    stillsuit calculations:
        Adv/Drunk: Avg turns needed to produce - [range in calculation shown]
        10: 152.5 - (279+357/2)/3
        11: 197   - (358+448/2)/3
        12: 241.8 - (449+553/2)/3


 ========= old run plan backbone ========-

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
