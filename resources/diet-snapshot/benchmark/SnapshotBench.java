import java.io.*;
import java.nio.file.*;
import java.util.*;
import net.sourceforge.kolmafia.*;
import net.sourceforge.kolmafia.preferences.Preferences;
import net.sourceforge.kolmafia.persistence.*;
import net.sourceforge.kolmafia.objectpool.*;
import net.sourceforge.kolmafia.session.*;
import net.sourceforge.kolmafia.equipment.Slot;
import net.sourceforge.kolmafia.textui.AshRuntime;
public class SnapshotBench {
 public static void main(String[] args)throws Exception{
  RequestLogger.openCustom(System.out);
  KoLCharacter.reset("diet-optimization-offline");Preferences.reset("diet-optimization-offline-"+System.nanoTime());
  KoLCharacter.setAscensionClass("Turtle Tamer");KoLCharacter.setPath(AscensionPath.nameToPath("Hat Trick"));
  KoLCharacter.setKingLiberated(true);KoLCharacter.setRonin(false);KoLCharacter.setRestricted(false);
  KoLCharacter.setStatPoints(1000,1000000,1000,1000000,1000,1000000);
  Path snap=Path.of(args[3]);
  Map<String,String> state=new TreeMap<>();
  for(String line:Files.readAllLines(snap.resolve("teres-barf-diet-state.tsv"))){String[] p=line.split("\t",2);state.put(p[0],p[1]);}
  for(var e:state.entrySet()){
   String k=e.getKey(),v=e.getValue();
   if(k.startsWith("pref."))Preferences.setString(k.substring(5),v);
   if(k.startsWith("skill."))KoLCharacter.addAvailableSkill(Integer.parseInt(k.substring(6)));
   if(k.startsWith("effect.")){int duration=Integer.parseInt(v.split("\\\\t")[0]);if(duration>0)KoLConstants.activeEffects.add(EffectPool.get(Integer.parseInt(k.substring(7)),duration));}
   if(k.startsWith("familiar.")){String[] p=v.split("\\\\t");if(p[0].equals("true")){FamiliarData f=new FamiliarData(Integer.parseInt(k.substring(9)));f.setExperience(Integer.parseInt(p[1]));KoLCharacter.addFamiliar(f);}}
  }
  for(String line:Files.readAllLines(snap.resolve("teres-barf-diet-inventory.tsv"))){String[] p=line.split("\t");KoLConstants.inventory.add(ItemPool.get(Integer.parseInt(p[0]),Integer.parseInt(p[1])));}
  KoLCharacter.setFamiliar(KoLCharacter.usableFamiliar(state.get("familiar")));
  for(var e:state.entrySet())if(e.getKey().startsWith("equipment.")){
   String n=e.getKey().substring(10);Slot slot=switch(n){case "back"->Slot.CONTAINER;case "off-hand"->Slot.OFFHAND;case "acc1"->Slot.ACCESSORY1;case "acc2"->Slot.ACCESSORY2;case "acc3"->Slot.ACCESSORY3;default->Slot.byCaselessName(n);};
   int id=Integer.parseInt(e.getValue());if(id>0)EquipmentManager.setEquipment(slot,ItemPool.get(id,1));
  }
  KoLCharacter.setLevel(Integer.parseInt(state.get("level")));KoLCharacter.setAvailableMeat(Long.parseLong(state.get("meat")));
  KoLCharacter.setFullness(Integer.parseInt(state.get("fullness")));KoLCharacter.setInebriety(Integer.parseInt(state.get("drunkenness")));KoLCharacter.setSpleenUse(Integer.parseInt(state.get("spleen")));KoLCharacter.setAdventuresLeft(Integer.parseInt(state.get("adventures")));
  KoLCharacter.recalculateAdjustments();
  net.sourceforge.kolmafia.request.CharPaneRequest.setCanInteract(true);
  Preferences.setString("benchMode",args[0]);Preferences.setString("benchWorkload",args.length>1?args[1]:"practical");
  for(int i=4;i<args.length;i++){String[] setting=args[i].split("=",2);Preferences.setString(setting[0],setting[1]);}
  if(args[1].equals("live-native-checks"))new net.sourceforge.kolmafia.textui.command.AbstractCommand(){
   public void run(String command,String action){
    // Test-only callbacks change physical in-memory state within one ASH run.
    if(action.equals("barf-ban-check")){
     Preferences.setString("banishedMonsters","");Preferences.setString("banishedPhyla","");BanishManager.recalculate();
     for(String name:List.of("angry tourist","horrible tourist family")){
      BanishManager.banishMonster(MonsterDatabase.findMonster(name),BanishManager.Banisher.SEADENT_LIGHTNING);
      BanishManager.banishMonster(MonsterDatabase.findMonster(name),BanishManager.Banisher.SPRING_KICK);
     }
    }else if(action.equals("barf-yeti-low")||action.equals("barf-yeti-high")){
     KoLCharacter.usableFamiliar("Cooler Yeti").setExperience(action.equals("barf-yeti-low")?0:2000);
    }else if(action.startsWith("tourist-")){
     int buff=EffectDatabase.getEffectId("How to Scam Tourists"),guide=ItemDatabase.getItemId("How to Avoid Scams");
     KoLConstants.activeEffects.removeIf(it->it.getEffectId()==buff);
     int turns=Integer.parseInt(action.substring(8));
     if(turns>0)KoLConstants.activeEffects.add(EffectPool.get(buff,turns));
     if(turns==0){KoLConstants.inventory.removeIf(it->it.getItemId()==guide);KoLConstants.inventory.add(ItemPool.get(guide,5));}
     if(turns==20)AdventureResult.addResultToList(KoLConstants.inventory,ItemPool.get(guide,-1));
    }else if(action.equals("reset-capacity")){
     for(String pref:List.of("_distentionPillUsed","_sweetToothUsed","_voraciTeaUsed"))Preferences.setBoolean(pref,false);
    }else if(List.of("_distentionPillUsed","_sweetToothUsed","_voraciTeaUsed").contains(action)){
     KoLCharacter.setFullness(KoLCharacter.getStomachCapacity());Preferences.setBoolean(action,true);
    }else if(action.equals("sobrie-before")){
     Preferences.setBoolean("_sobrieTeaUsed",false);KoLCharacter.setInebriety(7);
    }else if(action.equals("sobrie-after")){
     Preferences.setBoolean("_sobrieTeaUsed",true);KoLCharacter.setInebriety(6);
    }else if(action.equals("loss-state")||action.equals("loss-noncombat")){
     net.sourceforge.kolmafia.combat.MonsterStatusTracker.setNextMonster(MonsterDatabase.findMonster("garbage tourist"));
     KoLCharacter.setTurnsPlayed(20);Preferences.setBoolean("_lastCombatLost",true);Preferences.setString("_lastCombatStarted","same");
     Preferences.setString("lastEncounter",action.equals("loss-state")?"garbage tourist":"a noncombat");
    }else if(action.startsWith("guard-")){
     int cool=EffectDatabase.getEffectId("Looking Cool"),retained=EffectDatabase.getEffectId("Down With Chow");
     KoLConstants.activeEffects.removeIf(it->it.getEffectId()==cool||it.getEffectId()==retained);
     KoLCharacter.setAdventuresLeft(action.equals("guard-at-reserve")?5:6);
     if(!action.equals("guard-expired-cool"))KoLConstants.activeEffects.add(EffectPool.get(cool,1));
     Preferences.setString("_teresBarfPlanRetained","");
     if(action.equals("guard-last-retained")||action.equals("guard-ready-retained")){
      KoLConstants.activeEffects.add(EffectPool.get(retained,action.equals("guard-last-retained")?5:6));
      Preferences.setString("_teresBarfPlanRetained",retained+",");
     }
    }else if(action.equals("no-coin")){
     int coin=ItemDatabase.getItemId("amulet coin");KoLConstants.inventory.removeIf(it->it.getItemId()==coin);
     for(FamiliarData f:KoLCharacter.ownedFamiliars())if(f.getItem().getItemId()==coin)f.setItem(net.sourceforge.kolmafia.request.EquipmentRequest.UNEQUIP);
     if(EquipmentManager.getEquipment(Slot.FAMILIAR).getItemId()==coin)EquipmentManager.setEquipment(Slot.FAMILIAR,net.sourceforge.kolmafia.request.EquipmentRequest.UNEQUIP);
    }else throw new AssertionError("Unknown native fixture action: "+action);
    KoLCharacter.recalculateAdjustments();
   }
  }.register("dietnativefixture");
  // The old export omitted kitchen access. Enable it only as an explicit fixture assumption.
  if(Preferences.getBoolean("benchCookingAccess"))KoLCharacter.setOven(true);
  net.sourceforge.kolmafia.persistence.ConcoctionDatabase.refreshConcoctions();
  System.out.println("Native character loaded: "+state.size()+" saved state rows; cooking fixture="+Preferences.getBoolean("benchCookingAccess"));
  AshRuntime r=new AshRuntime();if(!r.validate(new File(args[2]),null))throw new AssertionError("compile");
  long begin=System.nanoTime();var v=r.execute("snapshotBeam",null);
  if(v==null||!v.toString().equals("OK")||!KoLmafia.permitsContinue())throw new AssertionError("Benchmark failed: "+v);
  System.out.println("Runtime result="+v+" continue="+KoLmafia.permitsContinue()+" total seconds="+(System.nanoTime()-begin)/1e9);
 }
}
