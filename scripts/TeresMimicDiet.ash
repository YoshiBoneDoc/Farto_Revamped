/** ~ Custom Dieting Script for farming with Mimic ~
 * to be used with the TeresMimic.ash script
 */

//  ---- HELPER FUNCTIONS ----

//retrieve and use a usable item
function downUse(consumable: string, amount: number): void {
    let consume: Item = Item.get(consumable);
    if (itemAmount(consume) < 1) retrieveItem(consume, 1);
    use(consume, amount); //  +1 full cap 60k
}

//retrieve and drink something
function downDrink(consumable: string, amount: number): void {
    let consume: Item = Item.get(consumable);
    if (itemAmount(consume) < 1) retrieveItem(consume, 1);
    drink(consume, amount); //  +1 full cap 60k
}

//retrieve and eat something
function downFood(consumable: string, amount: number): void {
    let consume: Item = Item.get(consumable);
    if (itemAmount(consume) < 1) retrieveItem(consume, 1);
    eat(consume, amount); //  +1 full cap 60k
}

//retrieve and chew something
function downSpleen(consumable: string, amount: number): void {
    let consume: Item = Item.get(consumable);
    if (itemAmount(consume) < 1) retrieveItem(consume, 1);
    chew(consume, amount); //  +1 full cap 60k
}

// ---- DIET PLANS ----
function eodDiet(){
    //save spleen for extros
/*      TOTALS - Drunk:1  Fullness: 7  Spleen:
 */
        PLAN:
            Feliz Navidad - 1 drunk
            Strix stix - 2 full
            rat pizza - 2 full
            Apron Meal Kit - 3 full - (sometimes) ****

 */

    foreach dr in $items[Feliz Navidad]{
        if (valueOfFamPot(dr) > valueOfOrgan("liver"))
            drink(dr);
    }
    foreach fo in $effects[Sugar-Frosted Pet Guts, ratabunga\, dude!, Beefy Heart]{
        if (my_fullness() >= fullness_limit())
            break;
        if (have_effect(fo) > 0)
            continue;
        if (effect_to_item(fo) == $item[Black and White Apron Meal Kit]){
            if (valueOfFamPot($item[Black and White Apron Meal Kit]) < valueOfOrgan("liver"))
            continue;
            if (my_class() == $class[seal clubber]){
                retrieve_item($item[cranberries]);
                visit_url("inv_use.php?which=3&whichitem=11472");
                visit_url("choice.php?whichchoice=1518&option=1&meal=0&ingredients0%5B%5D=672");
            } else if (my_class() == $class[pastamancer]){
                retrieve_item($item[philosopher's scone]);
                visit_url("inv_use.php?which=3&whichitem=11472");
                visit_url("choice.php?whichchoice=1518&option=1&meal=1&ingredients1%5B%5D=4956");
            }else
                abort();
        } else if (valueOfFamPot(effect_to_item(fo)) > valueOfOrgan("stomach")){
            eat(effect_to_item(fo));
        }
    }

}


// ---- MAIN EXPORT FUNCTION ----
export function hoboDiet() {

/*  old diet plan from hobo
	 ----   DIET PLAN ----
	> hobopolis adv drinks 5d 5f 0s
	> Dread cold-fashioned  9d 5f 0s
	> blood-drive sticker/voodoo snuff/antimatter wad  9d 5f 15s
	> fermented pickle juice  14d 5f 10s
	> Slider   14d 10f 5s
	> Mr. Burnsger 12d 14f 5s
	> Doc Clock 16d 13f 5s
	> tin cup 16d 15f 5s
	> Hodge blanket 18d 15f 5s
	> melange 15d 12f 5s
	> 3x mojo filter 15d 12f 2s
	> dog hair/distention pill 14d 11f 2s
	> cuppa Voraci/sweet tooth tea 13d 10f 2s
	> Gets-you-drunk 15d 10f 2s
	> Dread dank and stormy 19d 10f 2s
	> ghost pepper 19d 12f 2s
	> cookie 19d 13f 2s
 */



}
