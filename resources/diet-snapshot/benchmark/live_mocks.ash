// These adapters never call a game endpoint or modify the live account.
// ADAPTER
void barfLiveAcquire(item it,int quantity,int maximum)
 benchLiveTrace+="acquire:"+it+":"+quantity+":"+maximum+";";
// ADAPTER
void barfLiveGear()
 benchLiveActual.mask=get_property("_teresBarfPlanMask").to_int();
 benchLiveActual.stooper=get_property("_teresBarfPlanStooper").to_boolean();
// ADAPTER
void barfLiveYeti(int mode)
 benchLiveTrace+="yeti:"+mode+";";
// ADAPTER
barfTwoDayState barfLiveObserve()
 barfTwoDayState s=barfDietClone(benchLiveActual);s.schedule="";
 s.earlyJillTurns=barfLiveEarlyTurns;
 foreach flag in $strings[noWhet,noSpork,noExtras,fillWidth,marginalHelpers,requiredChestXP,requiredYetiCharge]s.uses[flag]=barfLivePolicy.uses[flag];
 s.uses["pourStages"]=barfLivePolicy.uses["pourStages"];s.uses["pourMidTurn"]=barfLivePolicy.uses["pourMidTurn"];s.uses["pourDone"]=barfLivePourDone;
 barfLiveHighWater=max(barfLiveHighWater,s.yetiXP);
 if(barfLiveHighWater>=barfSetting("YetiXP",2000))barfLiveCharged=true;
 s.uses["yetiCharged"]=barfLiveCharged?1:0;s.uses["yetiHighWater"]=barfLiveHighWater;
 // The real observer starts new daily-resource counters from current Mafia prefs.
 // This mock instead retains simulated usage against the frozen original prefs.
 s.uses["coolSlots"]=s.uses["coolRefreshes"]+barfLiveCoolSlots;
 foreach buff,keep in barfLiveRetained if(keep)s.retained[to_int(buff)]=true;
 return s;
// ADAPTER
void barfLiveSave()
// ADAPTER
void barfLiveApply(string row)
 string[int] c=split_string(row,"\t");barfTwoDayState source=barfLiveObserve();
 barfTwoDayState next=barfLivePredict(source,c);
 requireSame(next.cash>=0,"live action remains legal: "+row);
 float expectedGain=next.adventures-source.adventures;
 // Integer low rolls deliberately differ from the mean-yield plan.
 next.adventures=source.adventures+floor(expectedGain);
 next.minimumAdventures=next.adventures;next.schedule="";
 if(c[0]=="consume"){
  if(c[3]=="1")barfLiveCoolSlots=max(0,barfLiveCoolSlots-1);
  if(c[4].to_boolean()){
   foreach i,e in barfTwoDayItems if(to_int(e.target)==c[1].to_int())barfLiveRetained[e.buff]=true;
   foreach i,it in barfLiveLateItems if(to_int(it)==c[1].to_int()){remove barfLiveLateItems[i];break;}
  }
 }
 if(c[0]=="resource"&&index_of(c[1],"wish:")==0){effect buff=to_effect(substring(c[1],5).to_int());if(barfDietCanRetain(buff))barfLiveRetained[buff]=true;}
 if(c[0]=="distill"&&count(c)<5)barfLiveDistill=false;
 if(c[0]=="distill"||c[0]=="pourSkip")barfLivePourDone=next.uses["pourDone"];
 benchLiveActual=next;benchLiveActions+=1;
// ADAPTER
boolean barfLiveAdventure()
 barfTwoDayState source=barfLiveObserve();
 requireSame(barfLiveCanFarm(source),"every paid turn respects actual reserve, buffs and cooling");
 if(!benchLiveFree){benchLiveFree=true;return true;}
 barfTwoDayState next=barfDietFarmState(source,1);requireSame(next.cash>=0,"mock farm remains legal");
 if(!benchLiveLost&&barfDietStageKey(source)>=128){next.yetiXP=source.yetiXP;next.chestXP=source.chestXP;benchLiveLost=true;}
 next.minimumAdventures=next.adventures;next.schedule="";benchLiveActual=next;return true;
// ADAPTER
void barfLiveFinish()
 barfTwoDayState source=barfLiveObserve();barfTwoDayState next=barfDietFinishState(source);
 requireSame(next.cash>=0&&barfDietMeetsTargets(next),"final actual state meets all targets/reserves");
 benchLiveActual=next;benchLiveNightcaps+=1;
