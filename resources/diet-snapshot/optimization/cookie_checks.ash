string auditRun(barfTwoDayState initial){
 barfTwoDayItem e=checkItem($item[Affirmation Cookie]);
 requireSame(e.fullness==1&&e.minimum==9&&e.average==9&&e.dailyRemaining==1,"cookie discovery: 9 adventures, one fullness, one remaining daily use");
 requireSame(barfDietRegularFillItem(e)&&barfDietQualityAllowed(e.target),"cookie remains eligible through the quality and ordinary-fill filters");
 barfTwoDayState s=barfDietClone(initial);s.fullness=0;s.milk=0;s.aioli=0;s.whet=0;s.spork=0;
 clear(s.effects);s.noodles=0;s.uses["allCool"]=0;s.uses["coldRequired"]=0;
 s.uses["stock:"+to_int($item[special seasoning])]=barfDietOwnedAmount($item[special seasoning]);
 barfTwoDayState one=barfDietConsumeBare(s,e,false,0);
 requireSame(one.cash>=0&&one.fullness==1&&one.adventures==s.adventures+9&&one.minimumAdventures==s.minimumAdventures+9,"cookie simulator and guaranteed/expected yields agree");
 requireSame(barfDietConsumeBare(one,e,false,0).cash<0&&s.uses[e.dailyGroup]==0,"second cookie rejected without mutating source");
 set_property("_affirmationCookieEaten","true");barfDietBuildItems();
 foreach i,f in barfTwoDayItems requireSame(f.target!=e.target,"already-used cookie excluded from discovery");
 print("CHECKS COOKIE OK: discovery, eligibility, exact nine adventure yield, shared daily counter and source isolation");return "OK";
}
