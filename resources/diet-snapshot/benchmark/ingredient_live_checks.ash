void requireSame(boolean ok,string label);
void benchIngredientAcquire(item it,int quantity,int maximum);
int[item] benchIngredientInventory;
int benchIngredientSpent;int benchIngredientCreates;
int benchIngredientAmount(item it){return benchIngredientInventory[it];}
int benchIngredientNoStock(item it){return 0;}
int benchIngredientBuy(int q,item it,int ceiling){
 requireSame(it.tradeable&&ceiling>=barfDietCurrentPrice(it),"live raw purchase respects planned price");
 benchIngredientSpent+=q*barfDietCurrentPrice(it);benchIngredientInventory[it]+=q;return q;
}
boolean benchIngredientCreate(int q,item it){
 requireSame(barfDietCanCraft(it),"live creation uses a supported method");
 foreach part,n in barfDietIngredients(it){
  requireSame(benchIngredientInventory[part]>=q*n,"live crafting has every ingredient");
  benchIngredientInventory[part]-=q*n;
 }
 benchIngredientInventory[it]+=q;benchIngredientCreates+=1;return true;
}
void liveIngredientChecks(){
 clear(barfDietStashStock);clear(benchIngredientInventory);benchIngredientSpent=0;benchIngredientCreates=0;
 benchIngredientInventory[$item[baked veggie ricotta casserole]]=1;
 benchIngredientAcquire($item[baked veggie ricotta casserole],1,5200);
 requireSame(benchIngredientSpent==0&&benchIngredientCreates==0,"live owned meal does not recraft or rebuy ingredients");
 clear(benchIngredientInventory);
 benchIngredientAcquire($item[baked veggie ricotta casserole],1,5200);
 requireSame(benchIngredientSpent==5200&&benchIngredientCreates==3&&benchIngredientInventory[$item[baked veggie ricotta casserole]]==1,"live missing meal builds both intermediates and final meal");
 clear(benchIngredientInventory);benchIngredientSpent=0;benchIngredientCreates=0;
 benchIngredientInventory[$item[Pete's rich ricotta]]=1;
 benchIngredientAcquire($item[baked veggie ricotta casserole],1,5200);
 requireSame(benchIngredientSpent==2600&&benchIngredientCreates==2,"live recipe uses an owned intermediate without rebuying its inputs");
}
