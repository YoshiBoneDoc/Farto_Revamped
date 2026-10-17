// Independent original full-state recursion; preserve ordering, stock and floating arithmetic.
barfTwoDayState chocolateReference(barfTwoDayState source,float rate){
    barfTwoDayState best=source;float score=source.adventures*rate-source.cost;
    if(barfDietDailyUsed("_chocolatesUsed")+source.uses["chocolates"]>=3)return best;
    foreach it in $items[chocolate seal-clubbing club,chocolate turtle totem,chocolate pasta spoon,chocolate saucepan,
        chocolate disco ball,chocolate stolen accordion,fancy chocolate,fancy but probably evil chocolate,fancy chocolate car,
        beet-flavored Mr. Mediocrebar,cabbage-flavored Mr. Mediocrebar,sweet-corn-flavored Mr. Mediocrebar,choco-Crimbot]{
        barfTwoDayState next=barfDietExtraState(source,it);
        if(next.cash<0||next.adventures*rate-next.cost<=source.adventures*rate-source.cost)continue;
        next=chocolateReference(next,rate);
        if(next.adventures*rate-next.cost>score){best=next;score=next.adventures*rate-next.cost;}
    }
    return best;
}

string auditRun(barfTwoDayState initial){
 int originalMillis=0;int fastMillis=0;
 for context from 0 to 5{
  barfTwoDayState s=barfDietClone(initial);s.finished=false;s.schedule="phase\tchocolate test prefix\n";
  s.uses["chocolates"]=context==1?2:0;
  if(context==2)s.cash=my_meat()+s.liquidIncome-100;
  if(context==3)s.cash=my_meat()+s.liquidIncome+1;
  if(context==4)s.uses["stock:"+to_int($item[chocolate turtle totem])]=barfDietOwnedAmount($item[chocolate turtle totem]);
  if(context==5)s.finished=true;
  string before=barfDietExactStateKey(s);float rate=context==1?100:6000;
  int started=now_to_int();barfTwoDayState expected=chocolateReference(s,rate);originalMillis+=now_to_int()-started;
  started=now_to_int();barfTwoDayState actual=barfDietChocolatePlan(s,rate);fastMillis+=now_to_int()-started;
  sameState(expected,actual,"light chocolate basket context "+context);
  requireSame(before==barfDietExactStateKey(s)&&s.schedule=="phase\tchocolate test prefix\n","chocolate caller isolation");
 }
 print("CHECKS CHOCOLATE OK: six exact native state/schedule matches; reference_ms="+originalMillis+" basket_ms="+fastMillis);return "OK";
}
