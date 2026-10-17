// Forced actions in a temporary complete schedule; no production search change.
string auditBundle;
barfDietLateMenu auditMenu(){
 barfDietLateMenu m;foreach it in $items[body spradium,abstraction: joy]foreach i,e in barfTwoDayItems if(e.target==it){
  m.indices[count(m.indices)]=i;m.fullness+=e.fullness;m.drunkenness+=e.drunkenness;m.spleen+=e.spleen;
 }return m;
}
barfTwoDayState auditAction(barfTwoDayState s,string action){
 if(!contains_text(action,"eat:"))return barfDietResourceState(s,action);
 item it=to_item(substring(action,4).to_int());
 if(!(barfDietCandidateDetails contains it)){print("AUDIT RESOURCE missing native candidate="+it+" reason="+barfDietCandidateStatus[it]);s.cash=-1;return s;}
 return barfDietQuickConsume(s,barfDietCandidateDetails[it],false);
}
barfTwoDayState auditForcedBundle(barfTwoDayState s,barfDietLateMenu menu,boolean distill){
 if(auditBundle=="")return s;
 foreach n,action in split_string(auditBundle,","){
  barfTwoDayState next=auditAction(s,action);
  print("AUDIT RESOURCE bundle="+auditBundle+" action="+action+" legal="+(next.cash>=0)+" before="+s.fullness+","+s.drunkenness+","+s.spleen);
  if(next.cash<0)return next;
  s=next;
 }return barfDietQuickFillStage(s,menu,distill);
}
barfTwoDayState auditLateConsume(barfTwoDayState s,barfTwoDayItem e){
 barfTwoDayState next=barfDietQuickConsume(s,e,true);
 if(next.cash<0){
  string key=e.dailyGroup==""?to_string(e.target):e.dailyGroup;
  print("AUDIT BLOCKED bundle="+auditBundle+" late="+e.target+" dailyUsed="+s.uses[key]+" limit="+e.dailyRemaining
   +" organs="+s.fullness+"/"+barfDietFullLimit(s)+","+s.drunkenness+"/"+barfDietLiverLimit(s)+","+s.spleen+"/"+barfDietSpleenLimit(s)
   +" size="+e.fullness+","+e.drunkenness+","+e.spleen+" cash="+s.cash+" availableCash="+(my_meat()+s.liquidIncome));
 }return next;
}
// AUDIT_SCHEDULE_COPY
barfTwoDayState auditTrial(barfTwoDayState initial,barfDietLateMenu menu){
 barfDietQuickFailure="";barfTwoDayState next=auditSchedule(initial,menu,true);
 // Match production QuickTrial's two extra cooling-slot retries exactly.
 for retry from 1 to 2{
  if(next.cash>=0||initial.uses["allCool"]==0||initial.yetiXP<225)break;
  initial=barfDietClone(initial);initial.uses["coolSlots"]+=1;initial.uses["initialCoolSlots"]=initial.uses["coolSlots"];
  next=auditSchedule(initial,menu,true);
 }
 return next;
}

string auditRun(barfTwoDayState initial){
 barfDietQuickDeadline=0;initial.uses["marginalHelpers"]=1;initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=6;initial.uses["pourMidTurn"]=335;
 barfDietLateMenu menu=auditMenu();
 // Local resource+refill gate measured at the real initial-fill event.
 barfTwoDayState filled=barfDietResourceState(initial,"milk");filled=barfDietEarlyTrainingFood(filled);
 filled=barfDietQuickExtras(filled);filled=barfDietQuickFillStage(filled,menu,true);
 foreach action in $strings[sweat,aug16,mojo,melange,doghair,distention,sweettooth,voraci,sobrie,noodleSpleen]{
  barfTwoDayState next=barfDietResourceState(filled,action);
  if(next.cash>=0)next=barfDietQuickFillStage(next,menu,true);
  print("AUDIT RESOURCE gate="+action+" legal="+(next.cash>=0)+" localDelta="+(next.cash>=0?barfDietScore(next)-barfDietScore(filled):0.0));
 }
 foreach it in $items[spice melange,mojo filter,synthetic dog hair pill,distention pill,cuppa Sobrie tea,extra-greasy slider,jar of fermented pickle juice,Mr. Burnsger,Doc Clock's thyme cocktail]
  print("AUDIT RESOURCE item="+it+" price="+barfDietCurrentPrice(it)+" stock="+barfDietOwnedAmount(it)+" candidate="+(barfDietCandidateDetails contains it));
 auditBundle="";barfTwoDayState baseline=auditTrial(initial,menu);
 if(!barfDietMeetsTargets(baseline)||!barfDietReplay(initial,baseline))abort("Clearing baseline invalid.");
 print("AUDIT RESULT clearing-baseline combined="+barfDietScore(baseline)+" encounters="+baseline.turns);
 foreach bundle in $strings[melange,sobrie,melange\,sobrie,sobrie\,melange,sweat\,sweat,mojo\,mojo\,mojo,doghair\,distention,melange\,distention\,aug16\,eat:3327,melange\,aug16\,eat:8823,eat:3325,eat:8822,sweat\,eat:3325,sweat\,sweat\,eat:3325]{
  if(get_property("benchAuditBundles")!=""&&!contains_text(";"+get_property("benchAuditBundles")+";",";"+bundle+";"))continue;
  auditBundle=bundle;barfTwoDayState next=auditTrial(initial,menu);
  boolean valid=next.cash>=0&&barfDietMeetsTargets(next)&&barfDietReplay(initial,next);
  print("AUDIT RESULT bundle="+bundle+" valid="+valid+" complete="+next.finished+" encounters="+next.turns
   +" delta="+(valid?barfDietScore(next)-barfDietScore(baseline):0.0)+" income="+next.income+" cost="+next.cost+" cash="+next.cash+" failure="+barfDietQuickFailure);
  if(valid)foreach i,row in split_string(next.schedule,"\n")print("AUDIT ROW bundle="+bundle+" "+i+" "+row);
 }
 return "OK";
}
