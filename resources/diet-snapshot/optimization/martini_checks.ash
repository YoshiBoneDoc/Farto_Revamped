// Native October 17 snapshot: the shortlist must price real temporary drink gear.
string auditRun(barfTwoDayState initial){
    requireSame(available_amount($item[tuxedo shirt])>0&&can_equip($item[tuxedo shirt]),"fixture can temporarily wear its owned tuxedo shirt");
    foreach it in $items[Sacramento wine,low tide martini,Eye and a Twist]
        requireSame(barfDietCandidateStatus[it]=="Regular-fill shortlist","keep a viable modeled drink: "+it);
    barfTwoDayState s=barfDietClone(initial);
    s.mask=0;s.fullness=0;s.drunkenness=0;s.spleen=0;s.shotglass=0;
    s.uses["allCool"]=0;s.uses["coldRequired"]=0;
    clear(s.effects);
    float rate=barfDietRateAtStage(s,barfDietFarmingStage(s));
    barfTwoDayItem wine=barfDietCandidateDetails[$item[Sacramento wine]];
    barfTwoDayItem low=barfDietCandidateDetails[$item[low tide martini]];
    barfTwoDayItem eye=barfDietCandidateDetails[$item[Eye and a Twist]];
    barfTwoDayState a=barfDietConsumeState(s,wine,false,0,true);
    barfTwoDayState b=barfDietConsumeState(s,low,false,0,true);
    barfTwoDayState c=barfDietConsumeState(s,eye,false,0,true);
    requireSame(a.cash>=0&&a.minimumAdventures-s.minimumAdventures==7
        &&a.adventures-s.adventures==7.5,"ring rounds each five/six wine roll before Ode");
    requireSame(b.cash>=0&&b.minimumAdventures-s.minimumAdventures==6
        &&b.adventures-s.adventures==8,"low tide martini has +2 expected and +1 minimum tux bonus");
    requireSame(c.cash>=0&&c.minimumAdventures-s.minimumAdventures==7
        &&c.adventures-s.adventures==8.5,"Eye and a Twist has +2 expected and +1 minimum tux bonus");
    requireSame(contains_text(b.schedule,"tuxedo shirt;")&&contains_text(c.schedule,"tuxedo shirt;"),
        "martini execution instructions equip the tuxedo shirt");
    requireSame(barfDietCandidateRank(low,s,rate)>((low.average*rate-low.price)/low.drunkenness)
        &&barfDietCandidateRank(eye,s,rate)>((eye.average*rate-eye.price)/eye.drunkenness),
        "shortlist ranks the modeled tux bonus rather than raw adventure strings");
    requireSame(barfDietCandidateRank(wine,s,rate)>((wine.average*rate-wine.price)/wine.drunkenness),
        "shortlist ranks the rounded pinky-ring bonus");
    barfDietBuildItems();barfDietPruneItems(initial,false);
    requireSame(barfDietCandidateStatus[$item[low tide martini]]=="Outside regular-fill shortlist"
        &&barfDietCandidateStatus[$item[Eye and a Twist]]=="Outside regular-fill shortlist",
        "live replanning retains the previously validated candidate set");
    barfDietBuildItems();barfDietPruneItems(initial);
    requireSame(barfDietCandidateStatus[$item[low tide martini]]=="Regular-fill shortlist"
        &&barfDietCandidateStatus[$item[Eye and a Twist]]=="Regular-fill shortlist",
        "initial plan evaluates the extra martinis");
    print("MARTINI CHECKS OK: exact mean/minimum, ring rounding, shirt instruction, initial martinis and stable live replan set");
    return "OK";
}
