#!/usr/bin/env python3
"""Offline, frozen-snapshot benchmarks. Never reads live KoLmafia account data."""
import argparse
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import os
import sys

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--mode',choices=['baseline','cache','early','bare','farm','combinedBare','combined'],default='combined')
parser.add_argument('--workload',choices=['schedule','practical','checks','frontier-checks','planner-checks','pour-checks','live-checks','live-native-checks','production','ingredient-checks','probe'],default='practical')
parser.add_argument('--jar',type=Path,default=Path.home()/'Downloads/KoLmafia.app/Contents/app/KoLmafia-29366.jar')
parser.add_argument('--java-home',type=Path,default=Path.home()/'Library/Java/JavaVirtualMachines/temurin-25.0.4.1/Contents/Home')
parser.add_argument('--reference',type=Path,help='Require exactly matching fixed schedule, or all completed practical trials from a baseline log.')
parser.add_argument('--memory',action='store_true',help='Measure native child peak RSS with wait4 (no system-wide profiling).')
parser.add_argument('--profile',action='store_true',help='Measure inclusive native timings and call counts in the offline harness only.')
parser.add_argument('--output',type=Path,help='Keep generated harness and log here; otherwise use a new temporary directory.')
parser.add_argument('--source',type=Path,help='Benchmark another saved production source against the same frozen inputs.')
parser.add_argument('--setting',action='append',default=[],metavar='NAME=VALUE',help='Set an isolated benchmark preference; repeat as needed.')
parser.add_argument('--snapshot',type=Path,help='Use a separate saved export directory; leaves the regression fixture unchanged.')
parser.add_argument('--probe',type=Path,help='Read-only investigation ASH defining auditRun(initial); requires --workload probe.')
args=parser.parse_args()
if (args.workload=='probe') != bool(args.probe):parser.error('--probe and --workload probe must be used together.')
if any('=' not in setting for setting in args.setting):parser.error('--setting requires NAME=VALUE.')
if args.reference and args.workload not in ('schedule','practical'):parser.error('--reference supports schedule or practical workloads.')
fixture=Path(__file__).resolve().parent
repo=fixture.parents[2]
snapshot=args.snapshot.resolve() if args.snapshot else fixture.parent
saved_state=dict(row.split('\t',1) for row in (snapshot/'teres-barf-diet-state.tsv').read_text().splitlines())
if not args.snapshot and saved_state.get('day')!='20261013':parser.error('This fixture expects the saved October 13 snapshot; update benchmark expectations before using different inputs.')
out=args.output.resolve() if args.output else Path(tempfile.mkdtemp(prefix='teres-diet-benchmark-'))
out.mkdir(parents=True,exist_ok=True)
if not args.jar.is_file():parser.error('Supply the installed KoLmafia JAR with --jar.')
java=args.java_home/'bin/java';javac=args.java_home/'bin/javac'
if not java.is_file() or not javac.is_file():parser.error('Supply a JDK with --java-home.')
# Imports resolve through an isolated Mafia home, never the real account folder.
home=out/'home'
mafia=home/'Library/Application Support/KoLmafia'
mafia.mkdir(parents=True,exist_ok=True)
link=mafia/'scripts'
if not link.exists():link.symlink_to(repo/'scripts',target_is_directory=True)
s=(args.source or repo/'scripts/TeresMimicDiet.ash').read_text()
# A matched control retains the original single final-pour comparisons but skips
# the additional allocation trials. Production has no benchmark-only preference.
s=s.replace('if(available_amount($item[tiny stillsuit])>0){\n        int middle=',
    'if(get_property("benchPourAllocations")!="false"&&available_amount($item[tiny stillsuit])>0){\n        int middle=',1)
# Timing limits are benchmark-only for the unconstrained production planner.
# Legacy sources still read their original property, so both controls remain reproducible.
benchmark_budget=dict(setting.split('=',1) for setting in args.setting).get('benchDietBudgetSeconds')
if benchmark_budget is None:benchmark_budget=dict(setting.split('=',1) for setting in args.setting).get('teresBarfDietPlanSeconds','0')
if 'int deadline=0;' in s:
    s=s.replace('int deadline=0;',f'int deadline={int(benchmark_budget)};deadline=deadline>0?started+deadline*1000:0;',1)
# Independent cache controls exist only in generated offline copies.
benchmark_settings=dict(setting.split('=',1) for setting in args.setting)
if benchmark_settings.get('benchFillPolicyCache')=='false':
    s=s.replace('if(source.uses["capacityPolicy"]!=0){normalized=',
        'if(false&&source.uses["capacityPolicy"]!=0){normalized=',1)
if benchmark_settings.get('benchCapacityPolicies')=='false':
    s=s.replace('foreach policy in $ints[1,8,9,2,10,4,12,7,15]{',
        'if(false)foreach policy in $ints[1,8,9,2,10,4,12,7,15]{',1)
if benchmark_settings.get('benchFillCache')=='false':
    s=s.replace('if(!barfDietMemoize||(target<=barfDietOrganUsed(source,organ)',
        'if(true||!barfDietMemoize||(target<=barfDietOrganUsed(source,organ)',1)
if benchmark_settings.get('benchPreparationCache')=='false':
    s=s.replace('if(!barfDietMemoize)return barfDietQuickPrepare(initial,menu,distill);',
        'if(true||!barfDietMemoize)return barfDietQuickPrepare(initial,menu,distill);',1)
fixed_milk='if(it==$item[milk of magnesium])return 100;' in s
# Use the same saved stock/price reconstruction as the earlier measured run.
recipe_pricing='int barfDietRecipePrice(item it)' in s
if recipe_pricing:
    # Freeze the external price lookup, preserving real recursive recipe valuation.
    s=s.replace('int market=mall_price(it);int npc=npc_price(it);',
        'int market=benchFrozenBuyable[it]?benchFrozenPrices[it]:-1;int npc=npc_price(it);',1)
else:
    a=s.index('int barfDietCurrentPrice(item it){');b=s.index('\nstring barfDietStageGoal',a)
    s=s[:a]+'''int barfDietCurrentPrice(item it){
     if(it==$item[none])return 0;
     if(!(barfDietPrices contains it)){barfDietPrices[it]=benchFrozenPrices[it];barfDietBuyable[it]=benchFrozenBuyable[it];}
     return barfDietPrices[it];
    }
    '''+s[b:]
    if fixed_milk:s=s.replace('int barfDietCurrentPrice(item it){','int barfDietCurrentPrice(item it){\n if(it==$item[milk of magnesium])return 100;',1)
a=s.index('void barfDietBuildItems()');s=s[:a]+s[a:].replace('historical_price(it)','benchFrozenPrices[it]')
def replace_ash_function(source, signature, replacement):
    start=source.index(signature)
    masked=re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',lambda m:' '*len(m[0]),source,flags=re.S)
    end=masked.index('{',start)+1;depth=1
    while depth:
        depth+=(masked[end]=='{')-(masked[end]=='}');end+=1
    return source[:start]+replacement+source[end:]
s=replace_ash_function(s,'boolean barfDietReadStash(){','boolean barfDietReadStash(){return true;}')
if 'void barfDietReadColdOffer(){' in s:
    s=replace_ash_function(s,'void barfDietReadColdOffer(){','void barfDietReadColdOffer(){barfDietColdOfferPrice=0;barfDietColdOfferStore=0;}')
s=s.replace('if (count(barfGreedCandies) == 0) barfGreedCandies = sweet_synthesis_pair($effect[Synthesis: Greed],8);','')
s=s.replace('import teresBarfSupport.ash;','import teresBarfSupport.ash;\nint[item] benchFrozenPrices;boolean[item] benchFrozenBuyable;\nint[string] benchCounts;',1)
s=s.replace('barfTwoDayState barfDietConsumeState(barfTwoDayState source,barfTwoDayItem entry,boolean retain,int yeti,boolean bare){','barfTwoDayState barfDietConsumeState(barfTwoDayState source,barfTwoDayItem entry,boolean retain,int yeti,boolean bare){\n benchCounts["consumes"]+=1;',1)
s=s.replace('float barfDietScore(barfTwoDayState s){','float barfDietScore(barfTwoDayState s){\n benchCounts["scores"]+=1;',1)
s=s.replace('float barfDietRateAtStageUncached(barfTwoDayState s,barfTwoDayStage stage){','float barfDietRateAtStageUncached(barfTwoDayState s,barfTwoDayStage stage){\n benchCounts["rateMisses"]+=1;',1)
s=s.replace('while(remaining>0){\n        int nextStage=','while(remaining>0){\n        benchCounts["farmBlocks"]+=1;\n        int nextStage=',1)
s=s.replace('if(best>0){\n            barfDietFarmPrefix prefix=', 'if(best>0){\n            benchCounts["forecastHits"]+=1;\n            barfDietFarmPrefix prefix=',1)
if args.profile:
    s=s.replace('int[string] benchCounts;', 'int[string] benchProfileCalls;int[string] benchProfileMillis;int[string] benchCounts;',1)
    wrappers=[]
    for result_type,name,parameters,arguments in [
        ('float','barfDietScore','barfTwoDayState s','s'),
        ('string','barfDietExactStateKey','barfTwoDayState s','s'),
        ('barfTwoDayState','barfDietConsumeState','barfTwoDayState source,barfTwoDayItem entry,boolean retain,int yeti,boolean bare','source,entry,retain,yeti,bare'),
        ('barfTwoDayState','barfDietQuickConsume','barfTwoDayState s,barfTwoDayItem e,boolean retain','s,e,retain'),
        ('barfDietFillChoices','barfDietQuickChoices','barfTwoDayState source,string organ,int room,boolean broad','source,organ,room,broad'),
        ('barfTwoDayState','barfDietQuickFill','barfTwoDayState source,string organ,int target,boolean broad','source,organ,target,broad'),
    ]:
        signature=f'{result_type} {name}({parameters})'
        assert s.count(signature+'{')==1,signature
        prototype='' if signature+';' in s else signature+';\n'
        s=s.replace(signature+'{',prototype+f'{result_type} {name}Profiled({parameters})'+'{',1)
        wrappers.append(f'''{signature}{{
 int started=now_to_int();benchProfileCalls["{name}"]+=1;
 {result_type} result={name}Profiled({arguments});
 benchProfileMillis["{name}"]+=now_to_int()-started;return result;
}}''')
    s+='\n'+'\n'.join(wrappers)+'\n'
# Reconstruct exactly the same frozen price inputs for every variant.
prices={}
for row in (snapshot/'mallprices.txt').read_text().splitlines()[1:]:
    cells=row.split('\t')
    if len(cells)==3:prices[int(cells[0])]=int(cells[2])
for row in (snapshot/'teres-barf-diet-prices.tsv').read_text().splitlines():
    key,value=row.split('\t',1);prices[int(key)]=int(value.split('\\t')[0])
setup='''string snapshotBeam(){
 barfDietFastGear=true;barfDietBaseModes="";
 barfTwoDayRollover=145;barfTwoDayWeightCalibration=(13006.6/660.0+14040.76/692.5)/2*167;
 foreach it in $items[]{barfDietPrices[it]=-1;barfDietBuyable[it]=false;}
'''
for key,value in prices.items():
    if value>0:setup+=f'barfDietPrices[to_item({key})]={value};barfDietBuyable[to_item({key})]=to_item({key}).tradeable;\n'
setup+='''
 set_property("pizzaOfLegendEaten","true");set_property("calzoneOfLegendEaten","true");set_property("deepDishOfLegendEaten","true");
 foreach it in $items[]{
  if(!it.tradeable&&barfDietOwnedAmount(it)>0)barfDietPrices[it]=0;
  int npc=npc_price(it);if(npc>0){barfDietPrices[it]=barfDietPrices[it]>0?min(npc,barfDietPrices[it]):npc;barfDietBuyable[it]=true;}
  if(it.tradeable&&barfDietPrices[it]<0&&barfDietOwnedAmount(it)>0)barfDietPrices[it]=autosell_price(it);
 }
 foreach it,value in barfDietPrices {benchFrozenPrices[it]=value;benchFrozenBuyable[it]=barfDietBuyable[it];}
 barfGreedCandies[0]=$item[PEEZ dispenser];barfGreedCandies[1]=$item[Glo-Pop];
 barfDietDailyTable();barfTwoDayState initial=barfDietInitialState();
 barfDietBuildItems();barfDietPruneItems(initial);barfDietEnsureFillers();
 if(!BENCH_RECIPE_PRICING&&count(barfTwoDayItems)!=171)abort("Frozen candidate pool changed: "+count(barfTwoDayItems)+"; expected 171.");
 print("FROZEN SNAPSHOT: BENCH_SNAPSHOT_DAY, "+count(barfTwoDayItems)+" candidates; practical planner; no game requests/actions. Income is provisional.");
 initial.uses["requiredChestXP"]=950;initial.uses["requiredYetiCharge"]=2000;
 initial.uses["allCool"]=1;initial.uses["coldRequired"]=initial.yetiDouble?1:0;
 initial.uses["initialColdRequired"]=initial.uses["coldRequired"];
 return benchmarkRun(initial);
}
'''
setup=setup.replace('BENCH_SNAPSHOT_DAY',saved_state['day'])
setup=setup.replace('BENCH_RECIPE_PRICING','true' if recipe_pricing else 'false')
if recipe_pricing:
    setup=setup.replace(' barfGreedCandies[0]',''' foreach it in $items[] if(!it.tradeable)remove barfDietPrices[it];
 clear(barfDietRecipePrices);clear(barfDietPricingRecipe);
 barfGreedCandies[0]''',1)
entry='''

// BENCH_HELPERS
string benchmarkRun(barfTwoDayState initial){
 string mode=get_property("benchMode");
 barfDietResetSearchCaches();barfDietMemoize=mode!="baseline";
 barfDietSkipBare=mode=="early"||mode=="bare"||mode=="combinedBare"||mode=="combined";
 barfDietShareFarmForecasts=mode=="farm"||mode=="combinedBare"||mode=="combined";
 initial.uses["coolSlots"]=7;initial.uses["initialCoolSlots"]=7;
 int begin=now_to_int();
 if(get_property("benchWorkload")=="production"){
  set_property("teresBarfDietSkipPriceRefresh","true");barfDietPlan();
  if(!(barfDietComparisons contains "helpers allowed"))abort("Production entry did not complete its baseline.");
  print("PRODUCTION OK: actual entry, completed comparison replays, dry-run gate; ms="+(now_to_int()-begin));return "OK";
 }
 if(get_property("benchWorkload")=="schedule"){
  barfDietLateMenu empty;barfDietQuickDeadline=0;
  barfTwoDayState plan=barfDietQuickSchedule(initial,empty,false);
  int elapsed=now_to_int()-begin;
  print("SCHEDULE ms="+elapsed+" finished="+plan.finished+" cash="+plan.cash+" encounters="+plan.turns+" income="+plan.income+" cost="+plan.cost+" combined="+barfDietScore(plan)+" replay="+(plan.cash>=0&&barfDietReplay(initial,plan))+" targets="+barfDietMeetsTargets(plan));
  print("SCHEDULE ROWS "+replace_string(plan.schedule,"\\n"," / "));
 }else if(get_property("benchWorkload")=="practical"){
  remove initial.uses["allCool"];remove initial.uses["coldRequired"];remove initial.uses["coolSlots"];
  barfTwoDayState plan=barfDietQuickPlan(initial);
  foreach key,value in benchCounts print("PRACTICAL COUNT "+key+"="+value);
  print("PRACTICAL EXACT "+barfDietExactStateKey(plan));
  print("PRACTICAL ROWS "+replace_string(plan.schedule,"\\n"," / "));
  foreach key,trial in barfDietTrials if(trial.cash>=0){
   print("TRIAL EXACT "+key+" score="+barfDietScore(trial)+" state="+barfDietExactStateKey(trial)+" schedule="+replace_string(trial.schedule,"\\n"," / "));
  }
  print("PRACTICAL ms="+(now_to_int()-begin)+" encounters="+plan.turns+" combined="+barfDietScore(plan)+" replay="+(plan.cash>=0&&barfDietReplay(initial,plan))+" targets="+barfDietMeetsTargets(plan));
  if(plan.cash>=0)barfDietReport(plan,-1);
 }

 return "OK";
}
'''
if args.workload=='pour-checks':
    entry=entry.replace('// BENCH_HELPERS', (fixture/'pour_checks.ash').read_text()+'\n// BENCH_HELPERS',1)
    entry=entry.replace('int begin=now_to_int();','int begin=now_to_int();\n if(get_property("benchWorkload")=="pour-checks")return pourChecks(initial);',1)
if args.workload=='ingredient-checks':
    live=(repo/'scripts/TeresMimicDietLive.ash').read_text()
    masked=re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',lambda m:' '*len(m[0]),live,flags=re.S)
    start=live.index('void barfLiveAcquire(');end=masked.index('{',start)+1;depth=1
    while depth:
        depth+=(masked[end]=='{')-(masked[end]=='}');end+=1
    acquire=live[start:end].replace('barfLiveAcquire(','benchIngredientAcquire(')
    for a,b in [('item_amount(','benchIngredientAmount('),('closet_amount(','benchIngredientNoStock('),
                ('storage_amount(','benchIngredientNoStock('),('buy(','benchIngredientBuy('),('create(','benchIngredientCreate(')]:
        acquire=acquire.replace(a,b)
    ingredient_checks=(fixture/'ingredient_live_checks.ash').read_text()+'\n'+acquire+'\n'+(fixture/'ingredient_checks.ash').read_text()
    entry=entry.replace('// BENCH_HELPERS',ingredient_checks+'\n// BENCH_HELPERS',1)
    entry=entry.replace('int begin=now_to_int();','int begin=now_to_int();\n if(get_property("benchWorkload")=="ingredient-checks")return ingredientChecks(initial);',1)
entry=entry.replace('// BENCH_HELPERS', (fixture/'checks.ash').read_text()+'\n// BENCH_HELPERS',1)
if 'boolean barfDietFillDominates(' in s:
    frontier_checks=(fixture/'frontier_checks.ash').read_text()
    frontier_checks+='\nstring frontierChecks(barfTwoDayState initial){partialFrontierChecks(initial);return "OK";}\n'
    entry=entry.replace('// BENCH_HELPERS',frontier_checks+'\n// BENCH_HELPERS',1)
    entry=entry.replace('int begin=now_to_int();','int begin=now_to_int();\n if(get_property("benchWorkload")=="frontier-checks")return frontierChecks(initial);',1)
if 'barfDietExtraState(' in s:
    planner_checks=(fixture/'planner_checks.ash').read_text()
    if 'barfDietQuickConsumeMode(' not in s:
        planner_checks=planner_checks[planner_checks.index('string plannerChecks('):].replace(' consumptionLoopChecks(initial);\n','',1)
    if 'barfDietFillDominates(' not in s:
        planner_checks=planner_checks.replace('partialFrontierChecks(initial);\n','')
    entry=entry.replace('// BENCH_HELPERS', planner_checks+'\n// BENCH_HELPERS',1)
    entry=entry.replace('int begin=now_to_int();', 'int begin=now_to_int();\n if(get_property("benchWorkload")=="planner-checks")return plannerChecks(initial);',1)
    entry=entry.replace('if(plan.cash>=0)barfDietReport(plan,-1);', '''if(get_property("benchValidateTrials").to_boolean()){
   int verified=0;foreach key,trial in barfDietTrials if(trial.cash>=0){
    if(!barfDietReplay(initial,trial))abort("Completed starting/improvement diet failed ordered replay.");verified+=1;
   }
   print("VALIDATED COMPLETE TRIALS "+verified);
  }
  if(plan.cash>=0)barfDietReport(plan,-1);''',1)
elif args.workload=='planner-checks':parser.error('planner-checks requires the updated planner source.')
entry=entry.replace('int begin=now_to_int();\n if(get_property', 'int begin=now_to_int();\n if(get_property("benchWorkload")=="checks")return semanticChecks(initial);\n if(get_property',1)
if args.workload=='live-native-checks':
    live=(repo/'scripts/TeresMimicDietLive.ash').read_text().replace('import TeresMimicDiet.ash;','',1)
    # Only the guide-use request is substituted; keep the real upkeep guard,
    # acquisition and native modifier/effect calculations under test.
    live=live.replace('use(1,$item[How to Avoid Scams])','cli_execute("dietnativefixture tourist-20")',1)
    s+='\n'+live+'\n'
    entry=entry.replace('// BENCH_HELPERS', (fixture/'live_native_checks.ash').read_text()+'\n// BENCH_HELPERS',1)
    entry=entry.replace('int begin=now_to_int();','int begin=now_to_int();\n if(get_property("benchWorkload")=="live-native-checks")return liveNativeChecks(initial);',1)
if args.workload=='live-checks':
    # Only the irreversible adapters are substituted. Keep the production driver,
    # checkpoint replanning, farm guards, and action prediction under test.
    live=(repo/'scripts/TeresMimicDietLive.ash').read_text().replace('import TeresMimicDiet.ash;','',1)
    mocks=(fixture/'live_mocks.ash').read_text().split('// ADAPTER\n')
    for block in mocks[1:]:
        signature,body=block.split('\n',1)
        a=live.index(signature+'{');start=a+len(signature)
        depth=0;end=start
        for end in range(start,len(live)):
            if live[end]=='{':depth+=1
            elif live[end]=='}':
                depth-=1
                if depth==0:break
        live=live[:start]+'{\n'+body.strip()+'\n}'+live[end+1:]
    live=live.replace('if(!can_adventure($location[Barf Mountain])||handling_choice()||current_round()>0||in_multi_fight())','if(false)',1)
    live=live.replace('if(name==""||!have_outfit(name))','if(false)',1)
    live=live.replace('if(my_path()==$path[Hat Trick])foreach i,it in outfit_pieces(name)','if(false)foreach i,it in outfit_pieces(name)',1)
    live=live.replace('total_turns_played()','benchLiveActual.turns').replace('my_adventures()','benchLiveActual.adventures.to_int()')
    live=live.replace('initial.uses["coolSlots"]=max(0,','initial.uses["coolSlots"]=initial.uses["coolRefreshes"]+max(0,',1)
    live=live.replace('barfLiveCoolSlots=initial.uses["coolSlots"];','barfLiveCoolSlots=initial.uses["coolSlots"]-initial.uses["coolRefreshes"];',1)
    # Exercise the real consumption dispatcher against a recording item API too.
    live=live.replace('eatsilent(1,','benchLiveEat(1,').replace('drinksilent(1,','benchLiveDrink(1,')
    live=live.replace('use(1,','benchLiveUseItem(1,').replace('equip(spot,','benchLiveEquip(spot,')
    live=live.replace('barfOde(e.drunkenness)','benchLiveOde(e.drunkenness)')
    live=live.replace('sweet_synthesis(1,','benchLiveSynthesis(1,')
    declarations='void requireSame(boolean ok,string label);\nbarfTwoDayState benchLiveActual;int benchLiveNightcaps;int benchLiveActions;boolean benchLiveLost;boolean benchLiveFree;string benchLiveTrace;\n'
    declarations+='''boolean benchLiveEat(int q,item it){benchLiveTrace+="eat:"+it+";";if(it==$item[Tubetto Gelatto]){benchLiveTrace+="noodleChoice:"+get_property("choiceAdventure1599")+";";if(get_property("choiceAdventure1599")=="1")set_property("_legendaryNoodlesSpleen",true);}return true;}
boolean benchLiveDrink(int q,item it){benchLiveTrace+="drink:"+it+";";return true;}
boolean benchLiveUseItem(int q,item it){benchLiveTrace+="use:"+it+";";return true;}
boolean benchLiveEquip(slot spot,item it){benchLiveTrace+="equip:"+spot+":"+it+";";return true;}
void benchLiveOde(int q){benchLiveTrace+="ode:"+q+";";}
boolean benchLiveSynthesis(int q,item a,item b){benchLiveTrace+="synthesis:"+a+":"+b+";";return true;}
'''
    s+='\n'+declarations+live+'\n'
    entry=entry.replace('// BENCH_HELPERS', (fixture/'live_checks.ash').read_text()+'\n// BENCH_HELPERS',1)
    entry=entry.replace('int begin=now_to_int();','int begin=now_to_int();\n if(get_property("benchWorkload")=="live-checks")return liveChecks(initial);',1)
if args.probe:
    anchor=' initial.uses["coolSlots"]=7;initial.uses["initialCoolSlots"]=7;\n int begin=now_to_int();'
    assert entry.count(anchor)==1
    entry=entry.replace(anchor,anchor+'\n return auditRun(initial);',1)
    entry=entry.replace('// BENCH_HELPERS',args.probe.read_text()+'\n// BENCH_HELPERS',1)
if args.profile:
    entry=entry.replace('return "OK";\n}', 'foreach name,calls in benchProfileCalls print("PROFILE "+name+" calls="+calls+" inclusive_ms="+benchProfileMillis[name]);\n return "OK";\n}')
(out/'benchmark.ash').write_text(s+entry+setup)
shutil.copyfile(fixture/'SnapshotBench.java',out/'SnapshotBench.java')
subprocess.run([str(javac),'-cp',str(args.jar),str(out/'SnapshotBench.java')],check=True)
log=out/'output.log'
with log.open('w') as stream:
    command=[str(java),'-Xmx2g','-Djava.awt.headless=true',f'-Duser.home={home}',
        '-cp',f'{args.jar}:{out}','SnapshotBench',args.mode,args.workload,str(out/'benchmark.ash'),str(snapshot),*args.setting]
    if args.memory:
        process=subprocess.Popen(command,stdout=stream,stderr=subprocess.STDOUT)
        _,status,usage=os.wait4(process.pid,0);process.returncode=os.waitstatus_to_exitcode(status)
        result=subprocess.CompletedProcess(command,process.returncode)
        stream.write(f"NATIVE PEAK_RSS bytes={int(usage.ru_maxrss)*(1 if sys.platform=='darwin' else 1024)}\n")
    else:result=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT)

for row in log.read_text().splitlines():
    if row.startswith(('FROZEN','SCHEDULE ms=','PRACTICAL ms=','PRACTICAL COUNT ','PROFILE ','BEAM ','CHECKS ','PARTIAL FRONTIER CHECKS ','JOINT BUFF CHECKS ','CLEARING RETRY CHECKS ','MARGINAL HELPER CHECKS ','FOOD XP CHECKS ','PLANNER CHECKS ','LIVE CHECKS ','LIVE NATIVE ','VALIDATED COMPLETE TRIALS ','PRODUCTION ','INGREDIENT CHECKS ','AUDIT RESULT ','AUDIT FOOD ','AUDIT DELTA ','AUDIT INVALID ','AUDIT RESOURCE ','AUDIT BUDGET ','Runtime result=')):print(row)
print('Full output:',log)
if result.returncode:raise SystemExit(result.returncode)
if 'Runtime result=OK' not in log.read_text():raise SystemExit('Native benchmark did not complete; inspect the full output for parse/runtime errors.')
if args.reference:
    reference=args.reference.read_text().splitlines();current=log.read_text().splitlines()
    if args.workload=='practical':prefixes=('PRACTICAL EXACT ','PRACTICAL ROWS ','TRIAL EXACT ','VALIDATED COMPLETE TRIALS ')
    else:prefixes=('SCHEDULE ROWS ',)
    expected=[row for row in reference if row.startswith(prefixes) and not row.startswith('FRONTIER STATUS ')]
    actual=[row for row in current if row.startswith(prefixes) and not row.startswith('FRONTIER STATUS ')]
    if not expected or expected!=actual:raise SystemExit('EQUIVALENCE FAILED: retained states, scores or ordered schedules differ.')
    if args.workload in ('schedule','practical'):
        prefix='SCHEDULE ms=' if args.workload=='schedule' else 'PRACTICAL ms='
        field=' finished=' if args.workload=='schedule' else ' encounters='
        summaries=[next(row for row in lines if row.startswith(prefix)).split(field,1)[1] for lines in (reference,current)]
        if summaries[0]!=summaries[1]:raise SystemExit('EQUIVALENCE FAILED: completed-diet totals or validation results differ.')
    print('EQUIVALENCE OK:',len(actual),'exact matching output row(s).')
