string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();barfDietLateMenu empty;
 barfTwoDayState source=barfDietClone(initial);source.yetiXP=5000;source.earlyJillTurns=0;
 source.adventures=5;source.minimumAdventures=5;source.fullness=barfDietFullLimit(source);
 source.drunkenness=barfDietLiverLimit(source);source.spleen=barfDietSpleenLimit(source);
 source.uses["noExtras"]=1;source.uses["trainingFood"]=0;source.uses["allCool"]=0;source.uses["coldRequired"]=0;
 source.uses["yetiHighWater"]=5000;source.uses["yetiCharged"]=1;source.uses["milk"]=1;
 foreach action in $strings[sweat,aug16,mojo,melange,doghair,distention,sweettooth,voraci,sobrie,noodleSpleen]source.uses[action]=3;
 for n from 1 to 10{
  source.uses["cache-test-context"]=n;barfTwoDayState next=barfDietQuickCapacityStart(source,empty,false);
  requireSame(next.cash>=0,"cheap complete prefix for eviction test");
  requireSame(count(barfDietCapacityStartCache)<=8&&count(barfDietCapacityStartCache)==count(barfDietCapacityStartAges),"bounded prefix and age maps remain consistent");
 }
 requireSame(count(barfDietCapacityStartCache)==8,"store eight independent exact prefixes");
 source.uses["cache-test-context"]=3;int hits=barfDietCapacityStartHits;
 barfTwoDayState first=barfDietQuickCapacityStart(source,empty,false);barfTwoDayState expected=barfDietClone(first);
 requireSame(barfDietCapacityStartHits==hits+1,"older retained prefix is reused");
 source.uses["cache-test-context"]=11;barfTwoDayState inserted=barfDietQuickCapacityStart(source,empty,false);
 source.uses["cache-test-context"]=3;hits=barfDietCapacityStartHits;
 first=barfDietQuickCapacityStart(source,empty,false);
 requireSame(barfDietCapacityStartHits==hits+1,"recently used prefix survives eviction");sameState(first,expected,"exact prefix survives unrelated insertions");
 first.uses["cache-test-mutation"]=1;first.effects[to_int($effect[Looking Cool])]=999;
 sameState(barfDietQuickCapacityStart(source,empty,false),expected,"caller cannot mutate stored prefix");
 source.uses["cache-test-context"]=4;hits=barfDietCapacityStartHits;barfTwoDayState evicted=barfDietQuickCapacityStart(source,empty,false);
 requireSame(barfDietCapacityStartHits==hits,"least recently used prefix was evicted");
 barfDietResetSearchCaches();requireSame(count(barfDietCapacityStartCache)==0&&count(barfDietCapacityStartAges)==0,"snapshot reset clears both bounded maps");
 print("CHECKS PREFIX CACHE OK: exact reuse, eight-entry bound, LRU eviction, caller isolation and snapshot reset");return "OK";
}
