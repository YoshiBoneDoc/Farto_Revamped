// Run-scoped farming reports. Prices come from one mallcheck and data/mallprices.txt.
record farmingTotals {
    int freeFights;
    int freeMeat;
    int minimumMeat;
    int maximumMeat;
    int paidFights;
    int paidMeat;
    int meatGained;
    int[item] purchases;
};
record farmingItemChanges {
    int[item] gains;
    int[item] costs;
    int[item] retainedPurchases;
};
record farmingDropValue {
    item drop;
    int quantity;
    int each;
    int total;
};

boolean farmingReportActive = false;
string farmingReportDay;
int farmingReportOffset;
int farmingReportWallet;
int farmingReportSessionMeat;
int[item] farmingReportItems;
string[string] farmingReportSettings;

// Keep the old per-encounter wallet output in the same helper as the final report.
void reportFightWalletChange(){
    if (get_property("script") != "FreeKill")
        return;
    if (get_property("freeMeat").to_int() != my_meat()){
        print("FK wallet change of " + to_string(my_meat() - get_property("freeMeat").to_int(), "%,d")
            + " since the previous encounter", "blue");
        set_property("freeMeat", my_meat());
    }
}

void beginFarmingReport(){
    farmingReportActive = true;
    farmingReportDay = today_to_string();
    farmingReportOffset = length(session_logs(1)[0]);
    farmingReportWallet = my_meat();
    farmingReportSessionMeat = my_session_meat();
    farmingReportItems = my_session_items();
    foreach pref in $strings[logGainMessages, logBattleAction]
        farmingReportSettings[pref] = get_property(pref);
    set_property("logGainMessages", true);
    set_property("logBattleAction", true);
    set_property("freeMeat", my_meat());
}

void addFarmingFight(farmingTotals totals, boolean freeFight, int meat){
    if (freeFight){
        if (totals.freeFights == 0)
            totals.minimumMeat = meat;
        else
            totals.minimumMeat = min(totals.minimumMeat, meat);
        totals.maximumMeat = max(totals.maximumMeat, meat);
        totals.freeFights += 1;
        totals.freeMeat += meat;
    } else {
        totals.paidFights += 1;
        totals.paidMeat += meat;
    }
}

// Logs supply fight boundaries and gross Meat, which the native net tally doesn't retain.
// Item accounting comes from my_session_items(), the GUI's signed Session Results tally.
farmingTotals parseFarmingLog(string text){
    farmingTotals totals;
    boolean encounter = false;
    boolean combat = false;
    boolean freeFight = false;
    int fightMeat = 0;
    foreach i, raw in split_string(text, "\n"){
        string line = replace_all(create_matcher("^\\s+|\\s+$", raw), "");
        if (line == "" || starts_with(line, "Preference ") || starts_with(line, ">"))
            continue;
        boolean nextEncounter = starts_with(line, "Encounter:") || starts_with(line, "[");
        matcher request = create_matcher("^(?:cast |use |buy |pull |take from |add to |create |equip |unequip |outfit |mallsearch |Visiting |Submitting |Took choice )", line);
        if (nextEncounter || request.find()){
            if (combat)
                addFarmingFight(totals, freeFight, fightMeat);
            encounter = starts_with(line, "Encounter:");
            combat = false;
            freeFight = false;
            fightMeat = 0;
        }
        if (starts_with(line, "Round ")){
            combat = true;
            encounter = true;
        }
        if (line == "This combat did not cost a turn" && combat){
            addFarmingFight(totals, true, fightMeat);
            combat = false;
            encounter = false;
            fightMeat = 0;
        }
        matcher gain = create_matcher("^(?:Round [0-9]+: |After Battle: )?You gain ([0-9,]+) Meat\\.?$", line);
        if (gain.find()){
            int meat = to_int(to_string(replace_string(gain.group(1), ",", "")));
            totals.meatGained += meat;
            if (encounter)
                fightMeat += meat;
        }
        // Successful NPC/mall purchases are logged in this form by KoLmafia.
        matcher bought = create_matcher("^buy ([0-9,]+) (.+?) for [0-9,]+ each from ", line);
        if (bought.find()){
            item purchased = to_item(bought.group(2));
            if (purchased != $item[none])
                totals.purchases[purchased] += to_int(to_string(replace_string(bought.group(1), ",", "")));
        }
    }
    if (combat)
        addFarmingFight(totals, freeFight, fightMeat);
    return totals;
}

farmingItemChanges farmingItemDelta(int[item] before, int[item] after, int[item] purchases){
    farmingItemChanges changes;
    boolean[item] items;
    foreach it in before
        items[it] = true;
    foreach it in after
        items[it] = true;
    foreach it in items {
        int delta = after[it] - before[it];
        // Purchases remaining are assets, but aren't farming drops. Bought-and-used
        // supplies already cost cash; only net losses from existing stock cost extra.
        changes.retainedPurchases[it] = min(max(0, delta), purchases[it]);
        changes.gains[it] = max(0, delta - changes.retainedPurchases[it]);
        changes.costs[it] = max(0, -delta);
    }
    return changes;
}

int[item] farmingMallPrices(string[int] rows){
    int[item] prices;
    int[item] timestamps;
    foreach i, row in rows {
        string[int] fields = split_string(row, "\t");
        if (count(fields) < 3)
            continue; // File version/header.
        item it = to_item(to_int(fields[0]));
        int timestamp = to_int(fields[1]);
        if (it != $item[none] && timestamp >= timestamps[it]){
            timestamps[it] = timestamp;
            prices[it] = max(0, to_int(fields[2]));
        }
    }
    return prices;
}

farmingDropValue[int] valueFarmingDrops(int[item] drops, int[item] prices){
    farmingDropValue[int] rows;
    foreach it, quantity in drops {
        if (quantity <= 0)
            continue;
        int each = is_tradeable(it) ? prices[it] : 0;
        rows[count(rows)] = new farmingDropValue(it, quantity, each, quantity * each);
    }
    sort rows by -value.total;
    return rows;
}

string farmingDropLine(farmingDropValue row){
    string label = row.quantity + " x " + row.drop + ": ";
    if (row.each <= 0)
        return label + (is_tradeable(row.drop) ? "no cached mall price" : "untradeable");
    return label + to_string(row.total, "%,d") + " Meat (" + to_string(row.each, "%,d") + " ea)";
}

string farmingHtmlEscape(string text){
    text=replace_all(create_matcher("&(?!(?:#[0-9]+|#x[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);)",text),"&amp;");
    return replace_string(replace_string(text,"<","&lt;"),">","&gt;");
}
int farmingItemsValue(int[item] quantities,int[item] prices){
    int total=0;foreach i,row in valueFarmingDrops(quantities,prices)total+=row.total;return total;
}
string farmingSummaryRow(string label,string value,string color){
    return "<tr><td><font color='#53647A'>"+farmingHtmlEscape(label)+"</font></td><td align='right'><font color='"+color+"'>"+value+"</font></td></tr>";
}
string farmingItemsHtml(string title,int[item] quantities,int[item] prices,string color){
    farmingDropValue[int] rows=valueFarmingDrops(quantities,prices);
    if(count(rows)==0)return "";
    string html="<br><table width='100%' cellspacing='0' cellpadding='5' bgcolor='#FFFFFF'>"
        +"<tr bgcolor='#EAF0F6'><td colspan='4'><font color='"+color+"'><b>"+farmingHtmlEscape(title)+"</b></font>"
        +"<br><font size='2' color='#69798D'>Highest total mall value first</font></td></tr>"
        +"<tr><td><font color='#69798D'>Item</font></td><td align='right'>Qty</td><td align='right'>Each (Meat)</td><td align='right'>Total (Meat)</td></tr>";
    foreach i,row in rows{
        string each=row.each>0?to_string(row.each,"%,d"):is_tradeable(row.drop)?"unpriced":"untradeable";
        string total=row.each>0?to_string(row.total,"%,d"):"&mdash;";
        html+="<tr bgcolor='"+(i%2==0?"#F6F8FB":"#FFFFFF")+"'><td><font color='#26384D'>"+farmingHtmlEscape(to_string(row.drop))
            +"</font></td><td align='right'>"+row.quantity+"</td><td align='right'><font color='#69798D'>"+each+"</font></td>"
            +"<td align='right'><font color='"+(row.each>0?color:"#69798D")+"'>"+total+"</font></td></tr>";
    }
    return html+"<tr bgcolor='#EAF0F6'><td colspan='3'><b>Priced subtotal</b></td><td align='right'><font color='"+color+"'><b>"
        +to_string(farmingItemsValue(quantities,prices),"%,d")+"</b></font></td></tr></table>";
}
int printFarmingItems(string title,int[item] quantities,int[item] prices){
    print_html(farmingItemsHtml(title,quantities,prices,"#356CA0"));
    return farmingItemsValue(quantities,prices);
}

string farmingSummaryHtml(boolean completed,farmingTotals totals,int netMeat,int walletChange,farmingItemChanges changes,int[item] prices){
    int gains=farmingItemsValue(changes.gains,prices);int costs=farmingItemsValue(changes.costs,prices);
    int retained=farmingItemsValue(changes.retainedPurchases,prices);int profit=netMeat+gains+retained-costs;
    string profitColor=profit>=0?"#247455":"#AD4444";
    string html="<br><table width='100%' cellspacing='0' cellpadding='10'><tr bgcolor='#24384E'><td>"
        +"<font color='#FFFFFF' size='4'><b>Farming summary</b></font><br><font color='"+(completed?"#BFDAE9":"#F1CC83")+"'>"
        +(completed?"Completed run":"Partial run &middot; totals recorded before stopping")+"</font></td></tr>"
        +"<tr bgcolor='"+(profit>=0?"#EDF6F1":"#FBEFEF")+"'><td><font color='#53647A'>ESTIMATED NET PROFIT</font><br>"
        +"<font color='"+profitColor+"' size='5'><b>"+to_string(profit,"%,d")+" Meat</b></font>"
        +"<br><font size='2' color='#69798D'>Net session Meat + net cached item value</font></td></tr></table>";
    html+="<br><table width='100%' cellspacing='0' cellpadding='5' bgcolor='#FFFFFF'><tr bgcolor='#EAF0F6'><td colspan='2'><font color='#356CA0'><b>COMBAT</b></font></td></tr>";
    html+=farmingSummaryRow("Free fights completed",to_string(totals.freeFights,"%,d"),"#26384D");
    html+=farmingSummaryRow("Meat gained from free fights",to_string(totals.freeMeat,"%,d")+" Meat","#247455");
    html+=farmingSummaryRow("Average Meat per free fight",totals.freeFights>0?to_string(to_float(totals.freeMeat)/totals.freeFights,"%,.1f")+" Meat":"&mdash;","#26384D");
    html+=farmingSummaryRow("Free-fight Meat range",totals.freeFights>0?to_string(totals.minimumMeat,"%,d")+" &ndash; "+to_string(totals.maximumMeat,"%,d")+" Meat":"&mdash;","#26384D");
    html+=farmingSummaryRow("Paid fights",to_string(totals.paidFights,"%,d"),"#26384D");
    html+=farmingSummaryRow("Meat gained from paid fights",to_string(totals.paidMeat,"%,d")+" Meat","#247455");
    html+="</table><br><table width='100%' cellspacing='0' cellpadding='5' bgcolor='#FFFFFF'><tr bgcolor='#EAF0F6'><td colspan='2'><font color='#356CA0'><b>MEAT &amp; ITEM ACCOUNTING</b></font></td></tr>";
    html+=farmingSummaryRow("Gross Meat gained during the run",to_string(totals.meatGained,"%,d")+" Meat","#247455");
    html+=farmingSummaryRow("Meat spent / lost",to_string(max(0,totals.meatGained-netMeat),"%,d")+" Meat","#AD4444");
    html+=farmingSummaryRow("Net Meat (KoLmafia Session Results)",to_string(netMeat,"%,d")+" Meat",netMeat>=0?"#247455":"#AD4444");
    html+=farmingSummaryRow("Net wallet change",to_string(walletChange,"%,d")+" Meat",walletChange>=0?"#247455":"#AD4444");
    html+=farmingSummaryRow("Cached mall value of net item gains",to_string(gains,"%,d")+" Meat","#247455");
    html+=farmingSummaryRow("Existing stock consumed / lost",to_string(costs,"%,d")+" Meat","#9B5E25");
    html+=farmingSummaryRow("Purchased items remaining",to_string(retained,"%,d")+" Meat","#356CA0");
    html+="</table>"+farmingItemsHtml("Item gains / rewards &middot; purchases excluded",changes.gains,prices,"#247455")
        +farmingItemsHtml("Existing stock consumed / lost",changes.costs,prices,"#9B5E25")
        +farmingItemsHtml("Purchased items remaining",changes.retainedPurchases,prices,"#356CA0");
    return html+"<br><font size='2' color='#69798D'>Mall values use the saved mallprices.txt cache after mallcheck. Unpriced and untradeable items are listed but excluded from the profit estimate. Purchased items are separated from farming gains.</font><br><br>";
}

void finishFarmingReport(boolean completed){
    if (!farmingReportActive)
        return;
    farmingReportActive = false;
    // Restore logging even when a fight aborted the caller.
    foreach pref, saved in farmingReportSettings
        set_property(pref, saved);
    int walletChange = my_meat() - farmingReportWallet;
    int netMeat = my_session_meat() - farmingReportSessionMeat;
    int[item] finalItems = my_session_items();
    string log = session_logs(1)[0];
    if (today_to_string() == farmingReportDay)
        log = substring(log, min(farmingReportOffset, length(log)));
    else {
        string[int] logs = session_logs(2);
        log = substring(logs[1], min(farmingReportOffset, length(logs[1]))) + "\n" + log;
    }
    farmingTotals totals = parseFarmingLog(log);
    farmingItemChanges changes = farmingItemDelta(farmingReportItems, finalItems, totals.purchases);
    if (!cli_execute("mallcheck"))
        print("mallcheck did not finish; using the saved mallprices.txt prices.", "red");
    int[item] prices = farmingMallPrices(file_to_array("mallprices.txt"));
    print_html(farmingSummaryHtml(completed,totals,netMeat,walletChange,changes,prices));
}
