//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                          On-chart Dashboard for AutoTraderBot    |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

//+------------------------------------------------------------------+
//| Dashboard object names prefix                                    |
//+------------------------------------------------------------------+
#define DASH_PREFIX "ATB_DASH_"

//+------------------------------------------------------------------+
//| Create a text label on chart                                     |
//+------------------------------------------------------------------+
void DashCreateLabel(string name, int x, int y, string text, color clr, int fontSize = 9)
{
   string objName = DASH_PREFIX + name;
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   }
   
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetString(0, objName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Create background rectangle                                      |
//+------------------------------------------------------------------+
void DashCreateBackground(int x, int y, int width, int height, color bgColor)
{
   string objName = DASH_PREFIX + "BG";
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   }
   
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, C'50,50,70');
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Update the dashboard                                             |
//+------------------------------------------------------------------+
void UpdateDashboard(string symbol, int magicNumber)
{
   if(!InpShowDashboard) return;
   
   int x = InpDashX;
   int y = InpDashY;
   int lineHeight = InpDashFontSize + 6;
   int fs = InpDashFontSize;
   color tc = InpDashColor;
   
   CAccountInfo account;
   
   double balance    = account.Balance();
   double equity     = account.Equity();
   double margin     = account.Margin();
   double freeMargin = account.FreeMargin();
   double dailyPnL   = GetDailyPnL();
   double floatingPnL = GetFloatingPnL(magicNumber);
   double drawdown   = GetDrawdownPercent();
   int    openOrders = CountAllPositions(magicNumber);
   int    buyOrders  = CountPositions(magicNumber, symbol, POSITION_TYPE_BUY);
   int    sellOrders = CountPositions(magicNumber, symbol, POSITION_TYPE_SELL);
   double spread     = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   
   // Colors
   color profitColor  = C'0,200,100';
   color lossColor    = C'255,80,80';
   color headerColor  = C'100,180,255';
   color accentColor  = C'255,200,50';
   
   // Background - adjust height for AI info
   int bgHeight = lineHeight * 16 + 15;
   if(InpStrategy == STRATEGY_AI || InpStrategy == STRATEGY_AI_HYBRID)
      bgHeight = lineHeight * 18 + 15;
   DashCreateBackground(x - 5, y - 5, 280, bgHeight, InpDashBgColor);
   
   int row = 0;
   
   // Header
   DashCreateLabel("HDR", x, y + lineHeight * row, "━━━ AutoTraderBot ━━━", accentColor, fs + 1);
   row++;
   
   // Strategy
   DashCreateLabel("STR", x, y + lineHeight * row, "Strategy: " + GetStrategyName(), headerColor, fs);
   row++;
   
   // Symbol & TF
   string tfStr = EnumToString(InpTimeframe);
   DashCreateLabel("SYM", x, y + lineHeight * row, "Symbol:   " + symbol + " | " + tfStr, tc, fs);
   row++;
   
   // Separator
   DashCreateLabel("SEP1", x, y + lineHeight * row, "━━━━━━━━━━━━━━━━━━━━━", C'60,60,80', fs);
   row++;
   
   // Account info
   DashCreateLabel("BAL", x, y + lineHeight * row, "Balance:  $" + DoubleToString(balance, 2), tc, fs);
   row++;
   
   DashCreateLabel("EQU", x, y + lineHeight * row, "Equity:   $" + DoubleToString(equity, 2), tc, fs);
   row++;
   
   DashCreateLabel("MRG", x, y + lineHeight * row, "Free Mgn: $" + DoubleToString(freeMargin, 2), tc, fs);
   row++;
   
   // Separator
   DashCreateLabel("SEP2", x, y + lineHeight * row, "━━━━━━━━━━━━━━━━━━━━━", C'60,60,80', fs);
   row++;
   
   // P/L
   color dpColor = (dailyPnL >= 0) ? profitColor : lossColor;
   DashCreateLabel("DPL", x, y + lineHeight * row, "Daily PnL: $" + DoubleToString(dailyPnL, 2), dpColor, fs);
   row++;
   
   color fpColor = (floatingPnL >= 0) ? profitColor : lossColor;
   DashCreateLabel("FPL", x, y + lineHeight * row, "Floating:  $" + DoubleToString(floatingPnL, 2), fpColor, fs);
   row++;
   
   color ddColor = (drawdown > 10) ? lossColor : (drawdown > 5) ? accentColor : tc;
   DashCreateLabel("DDN", x, y + lineHeight * row, "Drawdown:  " + DoubleToString(drawdown, 1) + "%", ddColor, fs);
   row++;
   
   // Separator
   DashCreateLabel("SEP3", x, y + lineHeight * row, "━━━━━━━━━━━━━━━━━━━━━", C'60,60,80', fs);
   row++;
   
   // Orders
   DashCreateLabel("ORD", x, y + lineHeight * row, 
      "Orders:   " + IntegerToString(openOrders) + "/" + IntegerToString(InpMaxOrders) + 
      " (B:" + IntegerToString(buyOrders) + " S:" + IntegerToString(sellOrders) + ")", tc, fs);
   row++;
   
   // Spread
   color spColor = (InpMaxSpread > 0 && spread > InpMaxSpread) ? lossColor : tc;
   DashCreateLabel("SPR", x, y + lineHeight * row, "Spread:   " + DoubleToString(spread, 0) + " pts", spColor, fs);
   row++;
   
   // Status
   bool timeOk = IsTimeAllowed();
   bool spreadOk = IsSpreadAllowed(symbol);
   bool riskOk = IsRiskAllowed(symbol);
   
   string status = "ACTIVE";
   color stColor = profitColor;
   
   if(!timeOk) { status = "TIME FILTER"; stColor = accentColor; }
   else if(!spreadOk) { status = "SPREAD HIGH"; stColor = lossColor; }
   else if(!riskOk) { status = "RISK LIMIT"; stColor = lossColor; }
   
   DashCreateLabel("STS", x, y + lineHeight * row, "Status:   " + status, stColor, fs);
   row++;
   
   // AI info (if using AI strategy)
   if(InpStrategy == STRATEGY_AI || InpStrategy == STRATEGY_AI_HYBRID)
   {
      DashCreateLabel("SEP4", x, y + lineHeight * row, "━━━━━━━━━━━━━━━━━━━━━━━━━", C'60,60,80', fs);
      row++;
      
      string aiStatus = g_aiAvailable ? "Online" : "Offline";
      color aiColor = g_aiAvailable ? profitColor : lossColor;
      DashCreateLabel("AIS", x, y + lineHeight * row, 
         "AI: " + aiStatus + " | Conf: " + IntegerToString(g_aiLastConfidence) + "% | " +
         (g_aiLastSignal == SIGNAL_BUY ? "BUY" : (g_aiLastSignal == SIGNAL_SELL ? "SELL" : "HOLD")),
         aiColor, fs);
      row++;
   }
   
   // Time
   DashCreateLabel("TIM", x, y + lineHeight * row, "Time:     " + TimeToString(TimeCurrent(), TIME_SECONDS), C'120,120,140', fs);
}

//+------------------------------------------------------------------+
//| Remove all dashboard objects                                     |
//+------------------------------------------------------------------+
void RemoveDashboard()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, DASH_PREFIX) == 0)
      {
         ObjectDelete(0, name);
      }
   }
}
