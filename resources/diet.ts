import type { UtilityTask } from "../engine/task";
import {
	fullnessLimit,
	inebrietyLimit,
	spleenLimit,
	myFullness,
	myInebriety,
	mySpleenUse,
	print,
	myTurncount,
	toString,
	cliExecute,
	itemAmount,
	Item,
	chew,
	retrieveItem,
	eat,
	drink,
	use,
} from "kolmafia";
import { args } from "../args";

function canDiet(): boolean {
	return (
		myFullness() < fullnessLimit() ||
		myInebriety() < inebrietyLimit() ||
		mySpleenUse() < spleenLimit()
	);
}

export class HoboDiet {
	static tasks(): UtilityTask[] {
		let ran = false; // delete this logic after fully implemented (also in the do() loop below)

		return [
			{
				name: "Diet: Startup",
				limit: { turns: 0 },

				ready: () => !ran && canDiet(),
				completed: () => ran || !canDiet(),

				do: () => {
					ran = true; // ✅ mark done immediately so it can't loop

					print("=== DIET TASK STARTED ===", "blue");
					print(`Fullness: ${myFullness()}/${fullnessLimit()}`, "blue");
					print(`Drunkenness: ${myInebriety()}/${inebrietyLimit()}`, "blue");
					print(`Spleen: ${mySpleenUse()}/${spleenLimit()}`, "blue");
					print("=== DIET TASK FINISHED ===", "blue");
				},
			},
		];
	}
}



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

export function hoboDiet() {
	//MAKE SURE U CAN SURVIVE MUG AND FORK - NEED 1000 HP

	//if were out of these don't run the diet
	if (itemAmount(Item.get("synthetic dog hair pill")) < 1 || itemAmount(Item.get("distention pill")) < 1) {
		print("We're out of synthetic dog hair pill and/or distention pills.", "red");
//		return;
	}

/*
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



	// For surviving ghost peppers and gets-you-drunk
	cliExecute("use scroll of minor invulnerability"); //+2 all res
	cliExecute("use spooky sap"); //+3 spooky res
	cliExecute("use lotion of sleaziness"); //+2 hot
	cliExecute("use lotion of hotness"); //+2 cold
	cliExecute("use lotion of spookiness"); //+2 cold
	cliExecute("use lotion of stench"); //+2 hot
	cliExecute("use autumnic balm"); // +2 all
	cliExecute("use pec oil"); //+2 all
	cliExecute("use rainbow glitter candle"); //+2 all

	// try to get 1000 hp with this - needs testing
	cliExecute("use Ferrigno's Elixir of Power");
	cliExecute("use Chubby and Plump bar");
	cliExecute("wear nurse's hat");
	cliExecute("use scroll of drastic healing");

	// Cold-fashioned +4 drunk
	cliExecute("buy 1 Dreadsylvanian cold-fashioned @ 100000");
	downDrink("Frosty's frosty mug", 1);
	downDrink("Dreadsylvanian cold-fashioned", 1); //need to be lv 26   // +4 drunk

	// full up spleen to +15
	downSpleen("blood-drive sticker", 1);
	downSpleen("voodoo snuff", 1);
	downSpleen("antimatter wad", 1);


	// +5 drunk, -5 spleen
	downDrink("jar of fermented pickle juice", 1); //-5 spleen


	//slider +5 full -5 spleen
	// downUse("whet stone", 1);
	cliExecute("use scroll of drastic healing");
	downUse("milk of magnesium", 1);
	retrieveItem(Item.get("Special Seasoning")); //automatically consumed
	downUse("mini kiwi aioli", 1);
	downFood("fudge spork", 1);
	downFood("Ol' Scratch's salad fork", 1);
	downFood("Extra-greasy slider", 1); //-5 spleen

	//Mr. Burnsger
	cliExecute("acquire 1 Mr. Burnsger @ 120000");
	retrieveItem(Item.get("Special Seasoning")); //automatically consumed
	downUse("mini kiwi aioli", 1);
	downFood("Mr. Burnsger", 1); //-2 drunk

	//Doc Clock
	cliExecute("acquire 1 Doc Clock's thyme cocktail @ 130000");
	downDrink("Doc Clock's thyme cocktail", 1); // -2 fullness
// im at 12/15f 16/19d 5/15s here

	//Tin cup to cap fullness
	retrieveItem(Item.get("Special Seasoning")); //automatically consumed
	downUse("mini kiwi aioli", 1);
	downFood("tin cup of mulligan stew", 1); // +2 full

	//Hodge blanket
	downDrink("Hodgman's blanket", 1); // +2 drunk

	//spice melange
	downUse("spice melange", 1); // -3 drink/full
	//mofo filters
	downUse("mojo filter", 3);
	//pills
	use(Item.get("synthetic dog hair pill"), 1); // -1 fullness
	use(Item.get("distention pill"), 1); // -1 drunkness
	//cuppa shit
	downUse("cuppa Voraci tea", 1);
	downUse("sweet tooth", 1);

	// must survive hot damage
	downDrink("Gets-You-Drunk", 1); // +2 drunk

	//while supplies lasts
	downDrink("Dreadsylvanian dank and stormy", 1); // +4 drunk each

	// ghost peppers
	retrieveItem(Item.get("Special Seasoning")); //automatically consumed
	downUse("mini kiwi aioli", 1);
	downFood("ghost pepper", 1); //+2 fullness

	// Affirmation cookie
	downUse("mini kiwi aioli", 1);
	downFood("Affirmation Cookie", 1); // +1 full

	// top off spleen
	downSpleen("blood-drive sticker", 1);
	downSpleen("transdermal smoke patch", 1);
	downSpleen("antimatter wad", 1);

	print(" FINISHED DIETING! ", "blue");
}
