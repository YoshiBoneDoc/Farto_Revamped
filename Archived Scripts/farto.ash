import iotm.ash;
import preadventure.ash;
import zlib.ash; // for sell_val() -- item valuation for itemDropValueAt()

// ─── farto.ash ───────────────────────────────────────────────────────────────
// The meat-farming remainder of the old farto script. The free-kill flow
// (FKPrep / bulkFK and its helper tree) now lives in StockingMimic.ash and the
// shared utilities in iotm.ash; this file keeps only:
//   main()               -- the garbo() barf-mountain loop entry point
//   garbo() / cowo()     -- one farming turn (Barf Mountain / Coral Corral)
//   shadowRealmNCForce() -- NC-forcer burn-down, called by postadventure.ash via
//                           `cli_execute("ash import farto;shadowRealmNCForce()")`

// ─── drop-value weighting (garbo's modeValueOfMeat/modeValueOfItem) ─────────
// Real garbo doesn't maximize a fixed "2.5 Meat Drop, 0.72 Item Drop" -- it
// recomputes the weight every turn. The meat side is still a per-location
// constant in garbo too (each tourist/sea cow drops a fixed base Meat before
// modifiers -- 250 at Barf Mountain, 300 at the Coral Corral -- so 1% Meat
// Drop is worth base/100 actual meat), which is where the old "2.5" came
// from -- it was just never adjusted for the Coral Corral's higher base.
// The item side genuinely drifts as mall prices move, so that one actually
// needs recomputing live.
float baseMeatAt(location loc){
    if (loc == $location[the coral corral])
        return 300.0;
    return 250.0; // barf mountain
}

// Marginal cash value of 1% Item Drop at loc: for every monster there,
// weighted by encounter rate, sum up (drop rate) * (what the drop is worth
// right now) -- skipping boss/pickpocket-only drops, since Item Drop% doesn't
// touch those. Mirrors garbo's FarmingStrategy.itemDropValue(). Doesn't
// account for olfaction skewing a target monster's effective encounter
// weight the way garbo's adventureTargetToWeightedMap() does -- close enough
// for a maximize() weight, not exact.
float itemDropValueAt(location loc){
    float total;
    foreach mon, rate in appearance_rates(loc){
        if (rate <= 0 || mon == $monster[none])
            continue;
        foreach idx, rec in item_drops_array(mon){
            if (rec.type != "n" && rec.type != "")
                continue;
            float worth = sell_val(rec.drop);
            if (worth <= 0)
                continue;
            total += (rate / 100.0) * (rec.rate / 100.0) * worth;
        }
    }
    return total / 100.0; // per-adventure expected value -> value of 1% Item Drop
}

void setDropWeighting(location loc){
    set_property("maxOverride", to_string(baseMeatAt(loc) / 100.0) + " Meat Drop," + to_string(itemDropValueAt(loc)) + " Item Drop");
}

void shadowRealmNCForce(){
    if (get_property("script") != "stick" && get_property("script") != "coat"){
        if (get_property("_shadowAffinityToday") == "false" || have_effect($effect[shadow affinity]) > 0){
            if (get_property("questRufus")== "unstarted"){
                use($item[closed-circuit pay phone]);
            }
            while (have_effect($effect[shadow affinity]) > 0){
                shadowRealm();
            }
        }
        if (have_effect($effect[null afternoon]) == 0)
            use($item[null-day exploit]);
        while (get_property("noncombatForcerActive") == "true"){
            set_property("acc2Override",", equip petrified wood wizard's pouch");
            use($item[closed-circuit pay phone]);
            if (get_property("_mcHugeLargeAvalancheUses").to_int() < 3)
                set_property("acc3Override",", equip McHugeLarge left ski");
            if (get_property("_spikolodonSpikeUses").to_int() < 5){
                set_property("shirtOverride",", equip parka spikolodon");
            }
            if (get_property("rufusQuestTarget") == "shadow scythe")
                use_skill($skill[Cannelloni Cocoon]);
            if (get_property("rufusQuestTarget") == "shadow orrery"){    
                set_property("betweenBattleScript","");
                cli_execute("maximize elemental damage");
            }
            adv1($location[Shadow Rift (The Nearby Plains)],0,"");
            use($item[closed-circuit pay phone]);
            if (item_amount($item[Rufus's shadow lodestone]) > 0)
                adv1($location[Shadow Rift (The Nearby Plains)],0,"");
        }
        set_property("shirtOverride","");
        set_property("acc2Override","");
        set_property("acc3Override","");
        set_property("maxOverride","");
    }
}
void garbo(){
    setDropWeighting($location[barf mountain]);
    if (have_effect($effect[Citizen of a Zone]) == 0){
        set_property("famOverride","patriotic eagle");
    } else {
        set_property("famOverride","");
    }
    set_property("backOverride","");
    if (!contains_text(get_property("trackedMonsters"),"garbage tourist:McHugeLarge Slash") && to_int(get_property("_knuckleboneDrops")) == 100){
        set_property("offOverride",", equip McHugeLarge left pole");
        set_property("acc1Override",", equip peridot of peril");
    } else if (!contains_text(get_property("trackedMonsters"),"angry tourist:McHugeLarge Slash") && to_int(get_property("_knuckleboneDrops")) < 100){
        set_property("offOverride",", equip McHugeLarge left pole");
    } else {
        set_property("offOverride","");
        set_property("acc1Override","");
    }
    if (!everfullReady()) {
        set_property("acc1Override",", equip everfull dart holster");
    } else {
        set_property("acc1Override","");
    }
    if ((to_int(get_property("_pantsgivingCount")) >= 500) || (to_int(get_property("_pantsgivingCount")) >= 50 && dayType() == 0)){
        if (available_amount($item[pantsgiving]) > 0)
            stashreturn($item[pantsgiving]);
    }
    adv1($location[barf mountain],0,"");
}

void cowo(){
    setDropWeighting($location[the coral corral]);
    set_property("famOverride","");
    if (!everfullReady()) {
        set_property("acc1Override",", equip everfull dart holster");
    } else {
        set_property("acc1Override","");
    }
    if ((to_int(get_property("_pantsgivingCount")) >= 500 && dayType() == 1)
            || (to_int(get_property("_pantsgivingCount")) >= 50 && dayType() == 0))
        if (available_amount($item[pantsgiving]) > 0)
            stashreturn($item[pantsgiving]);
    if (have_effect($effect[driving waterproofly]) == 0)
        set_property("backOverride",", equip elf guard scuba tank");
    item banItem = $item[none];
    if (!contains_text(get_property("banishedMonsters"),"Mer-kin rustler")
        || !contains_text(get_property("banishedMonsters"),"sea cowboy"))
            banItem = banishGear($location[The Coral Corral]);
    if (banItem != $item[none])
        equip(banItem);
    adv1($location[the coral corral],0,"");
    // banishGear() leaves a slot override behind, and preadventure feeds every override to
    // the maximizer, so without this the banish item stays forced on in other zones.
    if (banItem != $item[none])
        set_property(to_string(to_slot(banItem)) + "Override", "");
}

//unusued, bunchu free kills, spooky VHS tape (shadow rift is a great target), god lobster,  red zeppelin? debatable tbh
//since I can only get 1k meat from FK, should save FK and relavant wanderers for cyberzone
//For the same reason I can see with FK is better to farm spice melange.... Hypothetically pearl farming has higher value???? ~4k
void main(){
    try {
        starter();
        if (to_int(get_property("_pantsgivingCount")) < 500)
            stashgrab($item[pantsgiving]);
        set_property("script","farto");
        while (my_adventures() > 0){
            if (dayType() == 0)
                main@postadventure();
            if (get_property("questL05Goblin") == "started")
                outskirts();
            else if (((my_class() == $class[pastamancer] || have_effect($effect[fishy]) > 0) && numeric_modifier($modifier[meat drop]) > 1700) || dayType() == 0)
                cowo();
            else{
                if (get_property("_stenchAirportToday") == "false")
                    use($item[one-day ticket to Dinseylandfill]);
                garbo();
            }
        }
    } finally {
        finisher();
        stashreturn($item[pantsgiving]);
    }
}
