string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();
 barfTwoDayState s=barfDietClone(initial);s.fullness=0;s.schedule="phase\toriginal prefix\n";
 int target=min(6,barfDietFullLimit(s));
 barfTwoDayState reference=barfDietQuickFillUncached(s,"food",target,false);
 requireSame(reference.cash>=0,"uncached exact fill completes");
 barfTwoDayState first=barfDietQuickFill(s,"food",target,false);
 sameState(first,reference,"cache miss exactly matches original fill");
 int hits=barfDietFillCacheHits;s.schedule="phase\tdifferent earlier actions\n";
 barfTwoDayState second=barfDietQuickFill(s,"food",target,false);
 requireSame(barfDietFillCacheHits==hits+1,"same complete state reuses the fill despite different schedule prefix");
 requireSame(barfDietExactStateKey(second)==barfDietExactStateKey(first),"cached organs/resources/buffs/stock/XP/finances match");
 requireSame(second.schedule==s.schedule+substring(first.schedule,length("phase\toriginal prefix\n")),"only schedule suffix is reused");
 second.uses["cache-test-mutation"]=1;second.effects[to_int($effect[Looking Cool])]=999;
 barfTwoDayState isolated=barfDietQuickFill(s,"food",target,false);
 requireSame(barfDietExactStateKey(isolated)==barfDietExactStateKey(first),"mutating a returned result cannot alter the stored fill");
 string key=barfDietExactStateKey(s);
 // Every changed context must either miss or be independently verified against its actual fill.
 for context from 0 to 6{
  barfTwoDayState changed=barfDietClone(s);
  if(context==0)changed.cash+=1;
  if(context==1)changed.yetiXP+=1;
  if(context==2)changed.effects[to_int($effect[Feeling Fancy])]+=1;
  if(context==3)changed.uses["stock:"+to_int($item[special seasoning])]+=1;
  if(context==4)changed.uses["noWhet"]=1;
  if(context==5)changed.uses["fillWidth"]=2;
  if(context==6)changed.mask=63;
  hits=barfDietFillCacheHits;
  barfTwoDayState actual=barfDietQuickFill(changed,"food",target,false);
  requireSame(barfDietFillCacheHits==hits,"changed economic/resource input misses the exact cache");
  barfTwoDayState expected=barfDietQuickFillUncached(changed,"food",target,false);
  sameState(actual,expected,"changed state still exactly matches the original fill");
 }
 requireSame(barfDietExactStateKey(s)==key,"fill/cache never mutate the caller");
 barfDietResetSearchCaches();requireSame(count(barfDietFillCache)==0&&barfDietFillCacheHits==0,"new planning snapshot invalidates stored fills");
 print("CHECKS FILL CACHE OK: exact outcomes, rebased schedules, stock/buffs/XP/cash/policy/capacity separation and reset");return "OK";
}
