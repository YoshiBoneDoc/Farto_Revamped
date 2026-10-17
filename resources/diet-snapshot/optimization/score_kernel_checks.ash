// Original independent scoring implementation, including original arithmetic order.
float kernelReferenceScore(barfTwoDayState s){
    if(s.cash<0)return -1000000000000.0;
    // Cache projected terms only; keep the original order of financial arithmetic.
    string key="";
    if(barfDietMemoize){
        key=s.mask+":"+s.stooper+":"+s.finished+":"+s.uses["forecastMode"]+":"+s.adventures+":"+s.minimumAdventures+":"+s.uses["touristTurns"]+barfDietEffectKey(s,true)
            +barfDietDelayedAdventureStateKey(s);
        if(barfDietFutureCache contains key)return (s.income-s.cost+barfDietTomorrowCache[key])+barfDietFutureCache[key];
    }
    float tomorrow=barfDietTomorrowValue(s);float score=s.income-s.cost+tomorrow;
    if(s.finished){
        if(barfDietMemoize){barfDietFutureCache[key]=0;barfDietTomorrowCache[key]=tomorrow;}
        return score;
    }
    float adventureBudget=max(0,(s.uses["forecastMode"]>0?s.adventures:s.minimumAdventures)
        -max(0,200-barfTwoDayRollover-barfDietNightcapMinimum()));
    float retentionBudget=1000000;
    foreach id,keep in s.retained if(keep)retentionBudget=min(retentionBudget,max(0,s.effects[id]-5));
    float budget=min(adventureBudget,retentionBudget);
    foreach it in $items[ghost pepper,Gets-You-Drunk]{
        int due=barfDietTurnsToDelayedAdventure(s,it);
        string delayedKey=barfDietDelayedAdventureKey(it);
        if(due>0&&due<=budget){
            float reward=s.uses["forecastMode"]>0?s.uses[delayedKey+":averageHalf"]/2.0:s.uses[delayedKey+":minimum"];
            budget=min(retentionBudget,budget+reward);
        }
    }
    float future=budget*barfDietRateAtStage(s,barfDietFarmingStage(s));
    future-=100*ceil(max(0,budget-s.uses["touristTurns"])/20.0);
    float base=barfBaseMeat()+(get_property("boomBoxSong")=="Total Eclipse of Your Meat"?25:0);
    float combatFraction=barfSetting("CombatsBetweenNC",30)/(barfSetting("CombatsBetweenNC",30)+1.0);
    barfTwoDayStage stage=barfDietFarmingStage(s);float weight=stage.weight;float percent=stage.weightPercent;
    foreach ef,t in barfTwoDayInitialEffects if(t>0){
        barfDietEffectData before=barfDietEffectAt(ef,t);barfDietEffectData after=barfDietEffectAt(ef,barfDietDuration(s,ef));
        weight+=after.weight-before.weight;percent+=after.weightPercent-before.weightPercent;
    }
    foreach id,t in s.effects if(t>0&&!(barfTwoDayInitialEffects contains to_effect(id))){barfDietEffectData data=barfDietEffectAt(to_effect(id),t);weight+=data.weight;percent+=data.weightPercent;}
    float multiplier=max(1.0,stage.leprechaunWeight);float effective=max(1,floor(weight*(1+percent/100)))*multiplier;
    // Beam ranking approximates overlapping weight expiries; final income is replayed per turn.
    foreach id,left in s.effects if(left>0&&left<budget){
        effect buff=to_effect(id);barfDietEffectData data=barfDietEffectAt(buff,left);float loss=base*(data.meat+stage.smithMeatPerPoint*data.smithsness)/100;
        if(stage.farmer==$familiar[Jill-of-All-Trades]){
            float after=max(1,floor((weight-data.weight)*(1+(percent-data.weightPercent)/100)))*multiplier;
            loss+=base*max(1.0,stage.leprechaunEffectiveness)*((220*effective)**0.5+2*effective-(220*after)**0.5-2*after)/100;
        }
        future-=(budget-left)*loss*combatFraction;
    }
    if(barfDietMemoize){barfDietFutureCache[key]=future;barfDietTomorrowCache[key]=tomorrow;}
    return score+future;
}

string auditRun(barfTwoDayState initial){
 int beforeMs=0;int afterMs=0;int cases=0;
 barfDietResetSearchCaches();
 for context from 0 to 5{
  barfTwoDayState source=barfDietClone(initial);source.mask=context%3==0?0:context%3==1?8:63;source.stooper=context>=3;
  source.cost=125879;source.income=381928.538475;source.uses["forecastMode"]=context%2;
  if(context==2)source.retained[to_int($effect[Down With Chow])]=true;
  if(context==4)source.effects[to_int($effect[Synthesis: Greed])]=57;
  for horizon from 0 to 150{
   source.adventures=horizon+0.5;source.minimumAdventures=horizon;source.uses["touristTurns"]=horizon%21;
   clear(barfDietFutureCache);clear(barfDietTomorrowCache);
   int started=now_to_int();float expected=kernelReferenceScore(source);beforeMs+=now_to_int()-started;
   clear(barfDietFutureCache);clear(barfDietTomorrowCache);
   started=now_to_int();float actual=barfDietScore(source);afterMs+=now_to_int()-started;
   requireSame(expected==actual,"exact cached projection context "+context+" horizon "+horizon+": "+expected+" / "+actual);cases+=1;
  }
 }
 requireSame(barfDietScoreKernelHits>800,"coefficient forecasts shared across adventure horizons");
 barfDietResetSearchCaches();requireSame(count(barfDietScoreKernels)==0&&barfDietScoreKernelHits==0,"snapshot reset clears coefficient cache");
 print("CHECKS SCORE KERNEL OK: "+cases+" exact native scores; reference_ms="+beforeMs+" cached_ms="+afterMs);return "OK";
}
