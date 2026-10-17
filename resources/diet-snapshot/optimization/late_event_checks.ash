// Offline bounded event graph: late equipment, fill, and farm decisions.
barfTwoDayState[string,int] auditLateLabels;
barfTwoDayState auditLateBest;barfTwoDayState auditLateInitial;barfDietLateMenu auditLateMenu;boolean auditLateDistill;
int auditLateVisited;int auditLateDominated;int auditLateComplete;
string auditLateKey(barfTwoDayState source){
 barfTwoDayState s=barfDietClone(source);s.income=0;s.cost=0;s.cash=0;s.liquidIncome=0;s.schedule="";
 return barfDietExactStateKey(s);
}
boolean auditLateDominates(barfTwoDayState a,barfTwoDayState b){
 return a.income-a.cost>=b.income-b.cost&&a.liquidIncome-a.cash>=b.liquidIncome-b.cash;
}
void auditLateVisit(barfTwoDayState s){
 if(s.cash<0||!barfDietFundingLegal(s))return;
 string key=auditLateKey(s);int[int] removeSlots;
 foreach i,old in auditLateLabels[key]{
  if(auditLateDominates(old,s)){auditLateDominated+=1;return;}
  if(auditLateDominates(s,old))removeSlots[count(removeSlots)]=i;
 }
 foreach n,i in removeSlots remove auditLateLabels[key,i];
 int labelSlot=0;foreach i,old in auditLateLabels[key]labelSlot=max(labelSlot,i+1);
 auditLateLabels[key,labelSlot]=barfDietClone(s);auditLateVisited+=1;
 if(auditLateVisited%250==0)print("AUDIT RESULT late_states="+auditLateVisited+" dominated="+auditLateDominated+" gain="+(barfDietScore(auditLateBest)),"blue");
 if(auditLateVisited>10000)abort("Offline event-graph feasibility probe exceeded 10000 labels; no production change.");
 if(s.mask==63){
  barfTwoDayState next=barfDietQuickPrepareTail(s,auditLateMenu,auditLateDistill);
  if(next.cash>=0)next=barfDietQuickComplete(next,auditLateMenu);
  if(barfDietMeetsTargets(next)){
   auditLateComplete+=1;
   if(barfDietScore(next)>barfDietScore(auditLateBest)&&barfDietReplay(auditLateInitial,next))auditLateBest=next;
  }
 }
 // Filling can be deferred across several late equipment changes. Farm legality
 // and all organ/resource transitions are still supplied by the production model.
 barfTwoDayState filled=barfDietQuickFillStage(s,auditLateMenu,auditLateDistill);
 if(filled.cash>=0)filled=barfDietQuickResources(filled,auditLateMenu,auditLateDistill,true);
 if(filled.cash>=0)filled=barfDietQuickFarm(filled,auditLateMenu,auditLateDistill);
 if(filled.cash>=0&&auditLateKey(filled)!=key)auditLateVisit(filled);
 foreach bit in $ints[0,1,2,3,4,5] if(!barfDietBit(s.mask,bit)){
  barfTwoDayState next=barfDietCapacityState(s,bit);
  if(next.cash>=0)auditLateVisit(next);
 }
}

string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();barfDietLateMenu menu;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=1;initial.uses["initialColdRequired"]=1;
 initial.uses["requiredChestXP"]=950;initial.uses["requiredYetiCharge"]=2000;
 initial.uses["marginalHelpers"]=1;initial.uses["noExtras"]=0;
 barfTwoDayState plan=barfDietQuickSchedule(initial,menu,false);
 requireSame(barfDietMeetsTargets(plan)&&barfDietReplay(initial,plan),"late event native reference validates");
 barfTwoDayState root=barfDietReplayStart(initial,plan);
 foreach n,row in split_string(plan.schedule,"\n"){
  if(starts_with(row,"capacity\t"))break;
  if(row!="")root=barfDietReplayAction(root,row);
 }
 requireSame(root.turns>100&&root.mask==0&&barfDietStageKey(root)<128,"capacity decisions stay after main farming and training");
 foreach bit in $ints[2,3,4,5]root=barfDietCapacityState(root,bit);
 requireSame(root.cash>=0&&root.mask==60,"two-piece controlled event graph");
 string original=barfDietExactStateKey(root);
 auditLateInitial=initial;auditLateMenu=menu;auditLateDistill=false;auditLateBest.cash=-1;
 int start=now_to_int();auditLateVisit(root);int beforeMs=now_to_int()-start;
 requireSame(barfDietMeetsTargets(auditLateBest)&&barfDietReplay(initial,auditLateBest),"depth-first reference winner replays");
 clear(barfDietEventLabels);clear(barfDietEventLabelIds);clear(barfDietEventActive);clear(barfDietEventFrontier);
 barfDietEventInitial=initial;barfDietEventMenu=menu;barfDietEventDistill=false;barfDietEventBest.cash=-1;
 start=now_to_int();barfDietEventVisit(root);int afterMs=now_to_int()-start;
 requireSame(barfDietMeetsTargets(barfDietEventBest)&&barfDietReplay(initial,barfDietEventBest),"topological winner replays");
 requireSame(max(barfDietScore(auditLateBest)-barfDietScore(barfDietEventBest),barfDietScore(barfDietEventBest)-barfDietScore(auditLateBest))<0.01,"event order preserves complete-diet objective");
 requireSame(original==barfDietExactStateKey(root),"event frontier leaves its caller unchanged");
 barfTwoDayState expensive=barfDietClone(root);expensive.cost+=100;expensive.cash+=100;
 requireSame(barfDietEventKey(root)==barfDietEventKey(expensive)&&barfDietEventDominates(root,expensive)
  &&!barfDietEventDominates(expensive,root),"higher purchase spending is never a dominance advantage");
 expensive=barfDietClone(root);expensive.effects[to_int($effect[Feeling Fancy])]+=50;
 requireSame(barfDietEventKey(root)!=barfDietEventKey(expensive),"training effects remain economically distinct");
 expensive=barfDietClone(root);expensive.uses["stock:"+to_int($item[Yeast of Boris])]+=1;
 requireSame(barfDietEventKey(root)!=barfDietEventKey(expensive),"shared recipe stock stays distinct");
 print("CHECKS LATE EVENTS OK: native objective/replay, late-only capacity, financial dominance, effects/stock and caller isolation; DFS_ms="+beforeMs+" topological_ms="+afterMs);
 return "OK";
}
