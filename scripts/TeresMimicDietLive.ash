import TeresMimicDiet.ash;

// Live entry is explicit (teresBARF.ash run). The planner remains read-only.
barfTwoDayState barfLivePolicy;
item[int] barfLiveLateItems;
boolean[effect] barfLiveRetained;
boolean barfLiveDistill;
int barfLivePourDone;
int barfLiveStarted;
int barfLiveEarlyTurns;
int barfLiveHighWater;
boolean barfLiveCharged;
int barfLiveCoolSlots;

void barfLiveMood(string name){
    // The trailing zero selects the named mood without executing its actions,
    // including names which otherwise match a mood CLI subcommand.
    if(name=="")name="default";
    name=name.to_lower_case();cli_execute("mood "+name+" 0");
    if(get_property("currentMood")!=name)abort("Could not select mood "+name+".");
}

void barfLiveAcquire(item it,int quantity,int maximum){
    if(it==$item[none]||quantity<1)abort("Invalid planned acquisition.");
    int missing=max(0,quantity-item_amount(it));
    int n=min(missing,closet_amount(it));if(n>0&&!take_closet(n,it))abort("Could not retrieve "+it+" from closet.");
    missing=max(0,quantity-item_amount(it));n=min(missing,storage_amount(it));
    if(n>0&&!take_storage(n,it))abort("Could not retrieve "+it+" from storage.");
    missing=max(0,quantity-item_amount(it));n=min(missing,barfDietStashStock[it]);
    if(n>0){
        string original=get_clan_name();string clan=get_property("teresBarfStashClan");if(clan=="")clan="Soup Clan";
        try{
            if(original!=clan&&(!cli_execute("/whitelist "+clan)||get_clan_name()!=clan))abort("Could not access the planned diet stash.");
            if(!take_stash(n,it))abort("Planned stash supply of "+it+" is no longer available; replan.");
            barfDietStashStock[it]=max(0,barfDietStashStock[it]-n);
        }finally{if(get_clan_name()!=original&&(!cli_execute("/whitelist "+original)||get_clan_name()!=original))abort("Could not restore clan "+original+".");}
    }
    missing=max(0,quantity-item_amount(it));
    if(missing>0&&!it.tradeable&&barfDietCanCraft(it)){
        foreach part,q in barfDietIngredients(it)barfLiveAcquire(part,missing*q,barfDietCurrentPrice(part));
        if(creatable_turns(it,missing,true)>0)abort("Planned crafting would spend adventures: "+it+"; replan.");
        if(!create(missing,it)||item_amount(it)<quantity)abort("Could not craft the planned "+it+".");
        return;
    }
    int ceiling=min(maximum,barfSetting("DietMaxItemPrice",500000));
    if(missing>0&&(!it.tradeable||ceiling<=0||buy(missing,it,ceiling)!=missing))
        abort("Cannot acquire "+quantity+" "+it+" at the planned ceiling of "+ceiling+" Meat each. No higher-priced substitution was made; replan.");
    if(item_amount(it)<quantity)abort("Planned acquisition did not supply "+it+".");
}

void barfLiveUse(item it){
    barfLiveAcquire(it,1,barfDietCurrentPrice(it));
    if(!use(1,it))abort("Planned use failed: "+it+".");
}

barfTwoDayState barfLiveObserve(){
    barfTwoDayState s=barfDietInitialState();
    s.turns=total_turns_played()-barfLiveStarted;s.earlyJillTurns=barfLiveEarlyTurns;
    s.mask=get_property("_teresBarfPlanMask").to_int();s.stooper=get_property("_teresBarfPlanStooper").to_boolean();
    barfLiveHighWater=max(barfLiveHighWater,s.yetiXP);
    if(barfLiveHighWater>=barfSetting("YetiXP",2000))barfLiveCharged=true;
    s.uses["yetiHighWater"]=barfLiveHighWater;s.uses["yetiCharged"]=barfLiveCharged?1:0;
    foreach flag in $strings[noWhet,noSpork,noExtras,fillWidth,marginalHelpers,requiredChestXP,requiredYetiCharge,capacityPolicy]s.uses[flag]=barfLivePolicy.uses[flag];
    s.uses["pourStages"]=barfLivePolicy.uses["pourStages"];s.uses["pourMidTurn"]=barfLivePolicy.uses["pourMidTurn"];s.uses["pourDone"]=barfLivePourDone;
    foreach checkpoint in $ints[1,2]s.uses["pourSweat"+checkpoint]=barfLivePolicy.uses["pourSweat"+checkpoint];
    s.uses["allCool"]=1;s.uses["coldRequired"]=s.yetiDouble?1:0;s.uses["coolSlots"]=barfLiveCoolSlots;
    foreach buff,keep in barfLiveRetained if(keep)s.retained[to_int(buff)]=true;
    return s;
}

void barfLiveSave(){
    set_property("_teresBarfPlanDay",today_to_string());set_property("_teresBarfPlanYetiHighWater",barfLiveHighWater);
    set_property("_teresBarfPlanYetiCharged",barfLiveCharged);
    string kept="";foreach buff,keep in barfLiveRetained if(keep)kept+=to_int(buff)+",";
    set_property("_teresBarfPlanRetained",kept);
}

barfTwoDayState barfLiveObserveFresh(){
    // Forecast caches belong to one physical snapshot. In particular, a used
    // capacity resource is now part of Mafia's limits, not a simulated extra.
    barfDietResetSearchCaches();clear(barfTwoDayStages);clear(barfTwoDayInitialEffects);clear(barfDietDropIncomeCache);clear(barfDietEffectCache);
    barfDietBaseModes="";
    return barfLiveObserve();
}

void barfLiveGear(){
    barfTwoDayState s=barfLiveObserve();int key=barfDietStageKey(s);
    set_property("_teresBarfPlanTrainer",key>=256?256:key>=128?128:0);
    barfGear();
    if(my_fullness()>fullness_limit()||my_inebriety()>inebriety_limit()||my_spleen_use()>spleen_limit())abort("Planned gear cannot hold the current organs.");
}

void barfLiveTrainingPrep(){
    if(get_property("_teresBarfPlanTrainer").to_int()==0)return;
    foreach it in $items[white candy heart,deviled candy egg,pulled blue taffy]{
        effect buff=effect_modifier(it,"Effect");int target=it==$item[pulled blue taffy]?51:1;
        while(have_effect(buff)<target){int before=have_effect(buff);barfLiveUse(it);if(have_effect(buff)<=before)abort("Training preparation did not grant "+buff+".");}
    }
    skill curiosity=$skill[Curiosity of Br'er Tarrypin];
    if(have_skill(curiosity)&&have_effect($effect[Curiosity of Br'er Tarrypin])==0){
        if(my_mp()<mp_cost(curiosity)&&!restore_mp(mp_cost(curiosity)))abort("Could not fund Curiosity.");
        if(!use_skill(1,curiosity))abort("Could not cast Curiosity.");
    }
    barfLiveAcquire($item[love song of icy revenge],1,barfDietCurrentPrice($item[love song of icy revenge]));
}

void barfLiveYeti(int mode){
    if(mode==0)return;
    if(get_property("coolerYetiMode")!="")abort("A drink enhancement is already pending; it must not be overwritten.");
    int xp=mode==2?400:225;
    if($familiar[Cooler Yeti].experience<xp||(mode==2&&get_property("_coolerYetiAdventures").to_boolean()))abort("Insufficient Yeti resources for the planned drink.");
    familiar farmer=my_familiar();string choices=get_property("choiceAdventureScript");
    try{
        set_property("choiceAdventureScript","");if(!use_familiar($familiar[Cooler Yeti]))abort("Could not select Cooler Yeti.");
        visit_url("main.php?talktoyeti=1",false,true);
        if(!handling_choice()||last_choice()!=1560)abort("Could not open Cooler Yeti's choice.");
        run_choice(mode==2?2:3);if(handling_choice()&&last_choice()==1560)run_choice(1);
        if(get_property("coolerYetiMode")!=(mode==2?"adventures":"effect"))abort("Yeti did not prepare the requested enhancement.");
    }finally{set_property("choiceAdventureScript",choices);if(!use_familiar(farmer))abort("Could not restore the farming familiar.");}
}

void barfLiveConsume(string[int] c){
    item it=to_item(c[1].to_int());barfTwoDayItem e;boolean found=false;
    foreach i,entry in barfTwoDayItems if(entry.target==it){e=entry;found=true;break;}
    if(c[0]=="noodleSpleen"){
        e.target=it;e.price=barfDietCurrentPrice(it);e.fullness=1;e.drunkenness=0;e.spleen=0;e.special="noodles";e.crafted=false;found=true;
    }
    if(!found)abort("Planned consumable is no longer eligible: "+it+".");
    if((e.crafted&&it.tradeable)||e.special=="synthesis"){
        foreach part,q in e.ingredients barfLiveAcquire(part,q,barfDietCurrentPrice(part));
        if(e.crafted){
            if(creatable_turns(it,1,true)>0)abort("Planned crafting would spend adventures: "+it+"; replan.");
            int before=item_amount(it);if(!create(1,it)||item_amount(it)<before+1)abort("Could not create the planned new "+it+".");
        }
    }else if(e.special!="speakeasy")barfLiveAcquire(it,1,e.price);
    if(e.special=="synthesis"){
        item[int] candies;foreach part,q in e.ingredients for copy from 1 to q candies[count(candies)]=part;
        if(count(candies)!=2||!sweet_synthesis(1,candies[0],candies[1]))abort("Planned Greed synthesis failed.");return;
    }
    string prep=c[2];
    if(contains_text(prep,"Ode;"))barfOde(e.drunkenness);
    foreach n,token in split_string(prep,";"){
        item helper=token=="aioli"?$item[mini kiwi aioli]:token=="whet"?$item[whet stone]:token=="spork"?$item[fudge spork]
            :token=="fork"?$item[Ol' Scratch's salad fork]:token=="mug"?$item[Frosty's frosty mug]:token=="seasoning"?$item[special seasoning]:$item[none];
        if(helper==$item[none])continue;
        barfLiveAcquire(helper,1,barfDietCurrentPrice(helper));
        boolean ok=token=="spork"||token=="fork"?eatsilent(1,helper):token=="mug"?drinksilent(1,helper):token=="seasoning"?true:use(1,helper);
        if(!ok)abort("Planned helper failed: "+helper+".");
    }
    item[slot] swaps;
    // Try an unoccupied capacity slot first. Removing a capacity item must leave
    // enough room for the drink/food itself, not just the pre-consumption organs.
    if(contains_text(prep,"mafia pinky ring;")){
        slot chosen=$slot[none];
        foreach spot in $slots[acc3,acc2,acc1]{
            item old=equipped_item(spot);
            int f=fullness_limit()-round(numeric_modifier(old,"Stomach Capacity"));
            int d=inebriety_limit()-round(numeric_modifier(old,"Liver Capacity"));
            int spent=e.drunkenness==1&&barfLiveObserve().shotglass>0?0:e.drunkenness;
            if(my_fullness()+e.fullness<=f&&my_inebriety()+spent<=d){chosen=spot;break;}
        }
        if(chosen==$slot[none])abort("No legal temporary slot for the planned pinky ring.");
        swaps[chosen]=equipped_item(chosen);
    }
    if(contains_text(prep,"tuxedo shirt;"))swaps[$slot[shirt]]=equipped_item($slot[shirt]);
    string choices=get_property("choiceAdventureScript");string noodle=get_property("choiceAdventure1599");
    try{
        foreach spot,old in swaps if(!equip(spot,spot==$slot[shirt]?$item[tuxedo shirt]:$item[mafia pinky ring]))abort("Could not equip planned consumption gear.");
        int liver=e.drunkenness==1&&barfLiveObserve().shotglass>0?0:e.drunkenness;
        if(my_fullness()+e.fullness>fullness_limit()||my_inebriety()+liver>inebriety_limit()||my_spleen_use()+e.spleen>spleen_limit())abort("Consumption gear leaves insufficient organ space for the planned item.");
        int noodleChoice=c[0]=="noodleSpleen"?1:5;
        if(e.special=="noodles"){set_property("choiceAdventureScript","");set_property("choiceAdventure1599",noodleChoice);}
        barfLiveYeti(c[3].to_int());
        boolean ok=e.fullness>0?eatsilent(1,it):e.drunkenness>0?drinksilent(1,it):chew(1,it);
        if(!ok)abort("Planned consumption failed: "+it+".");
        if(handling_choice()&&last_choice()==1599)run_choice(noodleChoice);
        if(c[0]=="noodleSpleen"&&!get_property("_legendaryNoodlesSpleen").to_boolean())abort("Noodle spleen choice did not apply.");
        if(get_property("coolerYetiMode")!="")abort("The Yeti enhancement was not consumed by the planned drink.");
        if(c[4].to_boolean()){barfLiveRetained[e.buff]=true;foreach i,late in barfLiveLateItems if(late==it){remove barfLiveLateItems[i];break;}}
    }finally{
        clear_food_helper();clear_booze_helper();
        set_property("choiceAdventureScript",choices);set_property("choiceAdventure1599",noodle);
        foreach spot,old in swaps if(!equip(spot,old))abort("Could not restore capacity gear after consumption.");
    }
}

void barfLiveResource(string[int] c){
    string action=c[1];
    if(index_of(action,"wish:")==0){
        effect buff=to_effect(substring(action,5).to_int());int before=get_property("_monkeyPawWishesUsed").to_int();
        if(before>=5||!cli_execute("monkeypaw effect "+buff)||get_property("_monkeyPawWishesUsed").to_int()!=before+1||have_effect(buff)==0)abort("Planned free paw wish failed.");
        if(barfDietCanRetain(buff))barfLiveRetained[buff]=true;
    }else if(action=="sweat"||action=="aug16"){
        skill cast=action=="sweat"?$skill[Sweat Out Some Booze]:$skill[Aug. 16th: Roller Coaster Day!];
        if(my_mp()<mp_cost(cast)&&!restore_mp(mp_cost(cast)))abort("Could not restore MP for "+cast+".");
        if(!use_skill(1,cast))abort("Planned organ-clearing skill failed: "+cast+".");
    }else barfLiveUse(to_item(c[2].to_int()));
}

barfTwoDayState barfLivePredict(barfTwoDayState source,string[int] c){
    if(c[0]=="resource")return barfDietResourceState(source,c[1]);
    if(c[0]=="extra")return barfDietExtraState(source,to_item(c[1].to_int()));
    if(c[0]=="noodleSpleen")return barfDietResourceState(source,"noodleSpleen");
    if(c[0]=="distill")return barfDietDistillState(source,count(c)>4?c[4].to_int():-1);
    if(c[0]=="pourSkip")return barfDietSkipPour(source,c[1].to_int());
    if(c[0]=="consume")foreach i,e in barfTwoDayItems if(to_int(e.target)==c[1].to_int())return barfDietConsumeState(source,e,c[4].to_boolean(),c[3].to_int(),contains_text(c[2],"bare;"));
    barfTwoDayState rejected;rejected.cash=-1;return rejected;
}

void barfLiveApply(string row){
    string[int] c=split_string(row,"\t");barfTwoDayState before=barfLiveObserveFresh();
    barfTwoDayState predicted=barfLivePredict(before,c);
    if(predicted.cash<0)abort("The next planned action is no longer legal: "+row+". Replan before continuing.");
    int turn=total_turns_played();
    print("Executing diet: "+replace_string(row,"\t"," / "),"blue");
    if(c[0]=="consume"||c[0]=="noodleSpleen")barfLiveConsume(c);
    else if(c[0]=="resource")barfLiveResource(c);
    else if(c[0]=="extra")barfLiveUse(to_item(c[1].to_int()));
    else if(c[0]=="distill"){
        string choices=get_property("choiceAdventureScript");
        try{
            set_property("choiceAdventureScript","");
            visit_url("inventory.php?action=distill");
            if(!handling_choice()||last_choice()!=1476)abort("Could not open the planned stillsuit pour.");
            run_choice(1);
            if(count(c)>4)barfLivePourDone=predicted.uses["pourDone"];
            else barfLiveDistill=false;
        }finally{set_property("choiceAdventureScript",choices);}
    }else if(c[0]=="pourSkip")barfLivePourDone=predicted.uses["pourDone"];
    if(total_turns_played()!=turn||handling_choice()||current_round()>0)abort("A diet action unexpectedly spent a turn or left combat/a choice open.");
    if(my_fullness()!=predicted.fullness||my_inebriety()!=predicted.drunkenness||my_spleen_use()!=predicted.spleen)abort("Actual organs differ from the planned action. Stop and replan from the current state.");
    if(c[0]=="consume"&&c[3]=="1"&&have_effect($effect[Looking Cool])<barfDietDuration(before,$effect[Looking Cool])+100)abort("The planned Looking Cool refresh did not apply.");
    if(c[0]=="consume"&&c[3]=="1")barfLiveCoolSlots=max(0,barfLiveCoolSlots-1);
    if(c[0]=="consume"&&c[3]=="2"&&!get_property("_coolerYetiAdventures").to_boolean())abort("The planned Yeti adventure double did not apply.");
    barfLiveSave();
}

void barfLiveRejectUnsupported(barfTwoDayState plan){
    foreach i,row in split_string(plan.schedule,"\n"){
        string[int] c=split_string(row,"\t");
        if(c[0]=="consume"&&to_item(c[1].to_int())==$item[Extrovermectin&trade;])
            abort("The plan includes an Extrovermectin copied-fight forecast, whose fight sequence is not implemented here. Set teresBarfCopiedGoblinMeat=0 and replan for live BARF.");
    }
}

barfTwoDayState barfLiveRemaining(){
    clear(barfDietExtraMenu);barfDietExtraMenuReady=false;barfTwoDayWarnings="";
    // Live low rolls can change the cooling XP needed by a newly chosen drink mix.
    // Use the established shortlist until those reserve changes are modeled end to end.
    barfTwoDayState initial=barfLiveObserveFresh();barfDietBuildItems();barfDietPruneItems(initial,false);barfDietEnsureFillers();
    barfDietLateMenu menu;
    foreach n,it in barfLiveLateItems{
        boolean found=false;
        foreach i,e in barfTwoDayItems if(e.target==it){menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;found=true;break;}
        if(!found)abort("A reserved end-of-day item is no longer available: "+it+".");
    }
    barfTwoDayState estimate=barfDietClone(initial);remove estimate.uses["allCool"];remove estimate.uses["coldRequired"];
    barfDietQuickDeadline=0;estimate=barfDietQuickSchedule(estimate,menu,barfLiveDistill);
    if(estimate.cash<0)abort("Could not rebuild a complete remaining diet from the actual results.");
    initial.uses["coolSlots"]=max(0,ceil((estimate.turns-initial.turns-barfDietDuration(initial,$effect[Looking Cool]))/100.0));
    initial.uses["initialCoolSlots"]=initial.uses["coolSlots"];initial.uses["initialColdRequired"]=initial.uses["coldRequired"];
    barfTwoDayState plan=barfDietQuickSchedule(initial,menu,barfLiveDistill);
    for retry from 1 to 2{
        if(plan.cash>=0)break;initial.uses["coolSlots"]+=1;initial.uses["initialCoolSlots"]=initial.uses["coolSlots"];
        plan=barfDietQuickSchedule(initial,menu,barfLiveDistill);
    }
    if(plan.cash<0||!barfDietMeetsTargets(plan)||!barfDietReplay(initial,plan))abort("The updated remaining diet failed validation. Stopped before another action.");
    barfLiveRejectUnsupported(plan);
    barfLiveCoolSlots=initial.uses["coolSlots"];
    print("Remaining diet recalculated from actual adventures, organs, XP and daily resources.","blue");return plan;
}

boolean barfLiveCanFarm(barfTwoDayState actual){
    // Gear is checked against real organ limits by barfLiveGear. Avoid a cached
    // forecast stage here; the physical account has already used its resources.
    int reserve=max(barfSetting("ReserveAdventures",0),max(0,200-barfTwoDayRollover-barfDietNightcapMinimum()));
    return !actual.finished&&actual.adventures>=reserve+1&&barfDietDuration(actual,$effect[Looking Cool])>0&&barfDietRetentionLegal(actual,1);
}

boolean barfLiveCompletedLoss(boolean wasLost,string started,int turn){
    if(current_round()>0||in_multi_fight()||handling_choice()||!get_property("_lastCombatLost").to_boolean())return false;
    // Mafia timestamps combat starts to the second. Consecutive losses can
    // share that stamp; paid progress plus the resolved monster identifies them.
    return !wasLost||started!=get_property("_lastCombatStarted")
        ||(total_turns_played()>turn&&last_monster()!=$monster[none]&&get_property("lastEncounter")==to_string(last_monster()));
}

void barfLiveTouristPrep(){
    if(have_effect($effect[How to Scam Tourists])==0){
        barfLiveAcquire($item[How to Avoid Scams],1,100);
        if(!use(1,$item[How to Avoid Scams])||have_effect($effect[How to Scam Tourists])==0)
            abort("Could not maintain How to Scam Tourists for BARF farming.");
    }
}

void barfLiveVhsPrep(){
    if(get_property("_teresBarfPlanMask").to_int()!=0||get_property("_teresBarfPlanStooper").to_boolean())return;
    if(get_property("spookyVHSTapeMonster")=="")
        barfLiveAcquire($item[spooky VHS tape],1,barfSetting("MaxItemPrice",100000));
    if(barfVhsDue()&&barfVhsFamiliar()==$familiar[Stocking Mimic]){
        barfLiveAcquire($item[facsimile dictionary],1,barfSetting("MaxItemPrice",100000));
        if(have_effect($effect[Shortly Wired])==0)barfLiveUse($item[short white]);
    }
}

boolean barfLiveAdventure(){
    barfLiveGear();barfTwoDayState beforeState=barfLiveObserve();
    if(!barfLiveCanFarm(beforeState))abort("The next BARF turn would violate cooling, retained effects or the rollover reserve.");
    barfLiveVhsPrep();
    barfLiveTouristPrep();
    barfLiveTrainingPrep();
    int turn=total_turns_played();int adventures=my_adventures();string fight=get_property("_lastCombatStarted");
    string progress=barfProgressKey();boolean lostBefore=get_property("_lastCombatLost").to_boolean();
    boolean ok=adv1($location[Barf Mountain],-1,"");
    for chain from 1 to 20{
        if(current_round()==0&&!in_multi_fight())break;run_combat();
    }
    if(current_round()>0||in_multi_fight()||handling_choice())abort("BARF left combat or a choice unresolved; resolve it before resuming.");
    boolean lost=barfLiveCompletedLoss(lostBefore,fight,turn);
    if(!ok&&!lost)abort("BARF adventure failed without a completed lost fight.");
    if(lost)print("BARF lost this fight; continuing from actual XP and adventures.","orange");
    barfLiveObserve();barfLiveSave();
    return lost||turn!=total_turns_played()||adventures!=my_adventures()||progress!=barfProgressKey()||fight!=get_property("_lastCombatStarted");
}

void barfLiveFinish(){
    barfTwoDayState actual=barfLiveObserve();
    if(actual.yetiXP<barfSetting("YetiReserveXP",0)||!barfLiveCharged||(have_familiar($familiar[Chest Mimic])&&$familiar[Chest Mimic].experience<barfSetting("ChestXP",950))
        ||actual.uses["coldRequired"]>0||!barfDietRetentionLegal(actual,0)||barfDietProjectedStart(actual,0)<200
        ||my_fullness()!=fullness_limit()||my_inebriety()!=inebriety_limit()||my_spleen_use()!=spleen_limit())abort("Final diet targets/reserves are not satisfied; refusing to nightcap.");
    barfLiveAcquire($item[vintage smart drink],1,barfDietCurrentPrice($item[vintage smart drink]));barfOde(10);
    if(total_turns_played()!=barfLiveStarted+actual.turns||!barfDietRetentionLegal(barfLiveObserve(),0)||barfDietProjectedStart(barfLiveObserve(),0)<200)
        abort("Nightcap preparation changed the farming reserve or retained buffs; replan before drinking Vintage.");
    if(!overdrink(1,$item[vintage smart drink])||have_effect($effect[Smart Drunk])!=1||my_inebriety()<=inebriety_limit())abort("Final Vintage nightcap did not apply correctly.");
    if(!outfit(get_property("teresBarfRolloverOutfit")))abort("Could not equip the configured rollover outfit after the nightcap.");
    if(my_adventures()+barfTwoDayRollover<200)abort("Actual nightcap yield left fewer than 200 projected tomorrow adventures; rollover outfit is equipped, but the reserve needs manual review.");
    print("Planned BARF completed. Vintage was the final consumption; rollover outfit equipped. No further farming.","green");
}

void barfDietExecute(int limit){
    if(!barfDietPlanReady)abort("Generate a complete validated diet before execution.");
    if(!can_adventure($location[Barf Mountain])||handling_choice()||current_round()>0||in_multi_fight())abort("BARF access is required, with no pending combat or choice.");
    if(my_fullness()!=barfDietPlannedInitial.fullness||my_inebriety()!=barfDietPlannedInitial.drunkenness||my_spleen_use()!=barfDietPlannedInitial.spleen
        ||my_adventures()!=barfDietPlannedInitial.adventures||$familiar[Cooler Yeti].experience!=barfDietPlannedInitial.yetiXP)abort("Character changed while planning; generate a new plan before executing.");
    if(limit==0){
        string name=get_property("teresBarfRolloverOutfit");
        if(name==""||!have_outfit(name))abort("For a full run, set teresBarfRolloverOutfit to your saved rollover outfit. A limited run stops before final consumption.");
        if(my_path()==$path[Hat Trick])foreach i,it in outfit_pieces(name)if(to_slot(it)==$slot[hat]&&it!=equipped_item($slot[hat]))abort("Rollover outfit would change the locked Hat Trick hat.");
    }
    barfLiveRejectUnsupported(barfDietPlanned);
    barfLivePolicy=barfDietClone(barfDietPlanned);clear(barfLiveLateItems);clear(barfLiveRetained);
    barfLiveCoolSlots=barfLivePolicy.uses["initialCoolSlots"];
    barfLiveDistill=false;barfLivePourDone=barfDietPlannedInitial.uses["pourDone"];barfLiveStarted=total_turns_played();barfLiveEarlyTurns=barfDietPlannedInitial.earlyJillTurns;
    boolean sameDay=get_property("_teresBarfPlanDay")==today_to_string();
    barfLiveHighWater=max(barfDietPlannedInitial.yetiXP,sameDay?get_property("_teresBarfPlanYetiHighWater").to_int():0);
    barfLiveCharged=sameDay&&get_property("_teresBarfPlanYetiCharged").to_boolean();
    if(sameDay)foreach i,id in split_string(get_property("_teresBarfPlanRetained"),",")if(id.to_int()>0)barfLiveRetained[to_effect(id.to_int())]=true;
    foreach i,row in split_string(barfLivePolicy.schedule,"\n"){
        string[int] c=split_string(row,"\t");
        if(c[0]=="consume"&&c[4].to_boolean())barfLiveLateItems[count(barfLiveLateItems)]=to_item(c[1].to_int());
        if(c[0]=="distill"&&count(c)<5)barfLiveDistill=true;
    }
    set_property("_teresBarfPlanMask",barfDietPlannedInitial.mask);set_property("_teresBarfPlanStooper",barfDietPlannedInitial.stooper);
    set_property("_teresBarfPlanMinimumAdventures",max(0,200-barfTwoDayRollover-barfDietNightcapMinimum()));
    try{
        clear_food_helper();clear_booze_helper();
        barfLiveGear();barfLiveSave();barfTwoDayState plan=barfLivePolicy;
        while(true){
            boolean checkpoint=false;
            foreach i,row in split_string(plan.schedule,"\n"){
                if(row=="")continue;string[int] c=split_string(row,"\t");
                if(limit>0&&total_turns_played()-barfLiveStarted>=limit){print("BARF paid-turn limit reached; no final buffs or nightcap applied.","blue");return;}
                if(c[0]=="phase"){
                    if(limit>0&&index_of(c[1],"Final consumption:")==0){print("Limited BARF run finished before end-of-day consumption.","blue");return;}
                    continue;
                }
                if(c[0]=="farm"){
                    int remaining=c[1].to_int();int attempts=0;int empty=0;
                    while(remaining>0&&barfLiveCanFarm(barfLiveObserve())){
                        if(limit>0&&total_turns_played()-barfLiveStarted>=limit)break;
                        int before=total_turns_played();empty=barfLiveAdventure()?0:empty+1;remaining-=max(0,total_turns_played()-before);
                        if(empty>=5)abort("BARF made no progress for five attempts.");
                        if(++attempts>c[1].to_int()+100)abort("Too many free encounters without completing the planned farming block.");
                    }
                    checkpoint=true;break;
                }
                if(c[0]=="capacity"){set_property("_teresBarfPlanMask",c[2].to_int());barfLiveGear();}
                else if(c[0]=="stooper"){set_property("_teresBarfPlanStooper",true);barfLiveGear();}
                else if(c[0]=="coolReserveRelease"){barfLiveCoolSlots=0;continue;}
                else if(c[0]=="nightcap"){if(limit>0)return;barfLiveFinish();return;}
                else if(c[0]=="rollover")abort("Rollover reached without a successful final nightcap.");
                else barfLiveApply(row);
            }
            if(!checkpoint)abort("The remaining diet ended without its final nightcap.");
            if(limit>0&&total_turns_played()-barfLiveStarted>=limit){print("BARF paid-turn limit reached; no nightcap applied.","blue");return;}
            plan=barfLiveRemaining();
        }
    }finally{clear_food_helper();clear_booze_helper();barfLiveObserve();barfLiveSave();}
}
