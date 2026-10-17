string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();barfTwoDayState source=barfDietClone(initial);source.fullness=0;source.uses["capacityPolicy"]=0;
 source.schedule="phase\toriginal scope prefix\n";
 barfTwoDayState baseline=barfDietQuickFill(source,"food",6,false);requireSame(baseline.cash>=0,"original fill completes");
 foreach policy in $ints[8,9,15]{
  barfTwoDayState variant=barfDietClone(source);variant.uses["capacityPolicy"]=policy;variant.schedule="phase\tcaller policy "+policy+"\n";
  int hits=barfDietFillCacheHits;barfTwoDayState cached=barfDietQuickFill(variant,"food",6,false);
  requireSame(barfDietFillCacheHits==hits+1,"irrelevant later equipment policy shares this exact pure fill");
  barfTwoDayState uncached=barfDietQuickFillUncached(variant,"food",6,false);
  sameState(cached,uncached,"all physical/economic fields and caller policy/schedule equal uncached consumption");
  requireSame(cached.uses["capacityPolicy"]==policy&&variant.fullness==0,"caller policy restored without mutating input");
 }
 print("CHECKS MEMOIZATION SCOPE OK: later-policy normalization, caller restoration, exact uncached outcomes");return "OK";
}
