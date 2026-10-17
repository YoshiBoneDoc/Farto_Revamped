string auditRun(barfTwoDayState initial){
 barfDietResetSearchCaches();barfTwoDayState rich=barfDietClone(initial);
 rich.uses["noExtras"]=0;rich.adventures=1000;rich.minimumAdventures=1000;
 foreach it in $items[] if(barfDietExtra(it,rich).group!="")rich.uses["stock:"+to_int(it)]=barfDietOwnedAmount(it);
 barfTwoDayState first=barfDietQuickExtras(rich);
 requireSame(first.cash>=0&&first.adventures>rich.adventures,"rich caller selects profitable extra adventures");
 string richKey=barfDietExtraMenuKey;
 barfTwoDayState poor=barfDietClone(rich);poor.cash=my_meat()+poor.liquidIncome-100;
 string parent=barfDietExactStateKey(poor);
 barfTwoDayState actual=barfDietQuickExtras(poor);
 requireSame(actual.cash>=0&&barfDietFundingLegal(actual),"cached rich menu cannot reject an otherwise feasible poor plan");
 requireSame(barfDietExtraMenuKey!=richKey,"different liquidity receives a new decision");
 barfDietExtraMenuReady=false;
 barfTwoDayState fresh=barfDietQuickExtras(poor);
 sameState(fresh,actual,"reused/fresh menu decisions have exact native state and schedule");
 requireSame(parent==barfDietExactStateKey(poor),"extra menu leaves its caller unchanged");
 barfDietResetSearchCaches();requireSame(barfDietExtraMenuKey==""&&!barfDietExtraMenuReady,"snapshot reset clears menu context");
 print("CHECKS EXTRA CACHE OK: starting-state scope, liquidity, native equivalence, caller isolation and reset");return "OK";
}
