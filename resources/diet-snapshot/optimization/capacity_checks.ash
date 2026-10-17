string auditRun(barfTwoDayState initial){
 barfDietQuickDeadline=0;initial.uses["marginalHelpers"]=1;initial.uses["trainingFood"]=10990;
 initial.uses["pourStages"]=6;initial.uses["pourMidTurn"]=335;
 barfDietLateMenu menu;
 foreach it in $items[body spradium,abstraction: joy]foreach i,e in barfTwoDayItems if(e.target==it){
  menu.indices[count(menu.indices)]=i;menu.fullness+=e.fullness;menu.drunkenness+=e.drunkenness;menu.spleen+=e.spleen;
 }
 requireSame(count(menu.indices)==2,"native retained menu discovered");
 barfTwoDayState prefix=barfDietQuickCapacityStart(initial,menu,true);
 requireSame(prefix.cash>=0&&prefix.mask==0,"original preparation prefix completes before capacity swaps");
 int hits=barfDietCapacityStartHits;barfTwoDayState variant=barfDietClone(initial);variant.uses["capacityPolicy"]=9;
 barfTwoDayState shared=barfDietQuickCapacityStart(variant,menu,true);shared.uses["capacityPolicy"]=0;
 requireSame(barfDietCapacityStartHits==hits+1,"capacity comparisons reuse their identical initial farming/training prefix");
 sameState(prefix,shared,"shared prefix preserves all state and action rows");
 barfDietLateMenu reserve;reserve.fullness=2;reserve.drunkenness=menu.drunkenness;reserve.spleen=menu.spleen;
 foreach bit in $ints[0,1,2,3,4,5]{
  item piece=barfTwoDayCapacityItems[bit];int organ=barfDietCapacityOrgan(bit);
  requireSame(organ>=0,"organ grouping comes from actual native capacity modifiers");
  barfTwoDayState next=barfDietCapacityState(prefix,bit);
  if(organ==0){
   requireSame(!barfDietCapacityUseful(prefix,next,reserve,true),"food gear whose space is wholly reserved can be deferred");
   requireSame(barfDietCapacityUseful(prefix,next,menu,true),"currently usable food capacity is not classified as reserved");
  }
 }
 barfTwoDayState baseline=barfDietQuickSchedule(initial,menu,true);
 requireSame(barfDietMeetsTargets(baseline)&&barfDietReplay(initial,baseline),"unchanged baseline fully validates");
 float best=barfDietScore(baseline);
 foreach policy in $ints[1,8,9,2,10,4,12,7,15]{
  variant=barfDietClone(initial);variant.uses["capacityPolicy"]=policy;
  int started=now_to_int();barfTwoDayState result=barfDietQuickSchedule(variant,menu,true);
  requireSame(barfDietMeetsTargets(result)&&barfDietReplay(initial,result),"capacity policy "+policy+" keeps stock/cash/XP/cooling/required equipment and reserve legal");
  float gain=barfDietScore(result)-barfDietScore(baseline);best=max(best,barfDietScore(result));
  print("AUDIT RESULT capacity-policy="+policy+" ms="+(now_to_int()-started)+" combined="+barfDietScore(result)+" gain="+gain+" encounters="+result.turns+" replay=true targets=true");
  if(policy==1)requireSame(gain>4000,"general food grouping discovers the demonstrated profitable alternative");
 }
 requireSame(best-barfDietScore(baseline)>7000,"generic grouping/deferral reaches at least the demonstrated combined improvement");
 print("CHECKS CAPACITY OK: native organ grouping, reserved-space deferral, identical shared prefix and complete legal profitable continuations");return "OK";
}
