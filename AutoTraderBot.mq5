//+------------------------------------------------------------------+
//|                                                AutoTraderBot.mq5 |
//|                              Configurable Auto Trading Expert    |
//|                                                                  |
//|  Features:                                                       |
//|  - 6 Trading Strategies (Trend, Scalp, Breakout, Reversion, Grid)|
//|  - Custom Strategy with 5 sub-types (MA+RSI, MACD+BB, etc.)     |
//|  - Full Risk Management (Dynamic Lots, SL/TP, Trailing, BE)      |
//|  - Telegram Notifications                                        |
//|  - On-chart Dashboard                                            |
//|  - Time & Spread Filters                                         |
//+------------------------------------------------------------------+
#property copyright   "AutoTraderBot"
#property link        ""
#property version     "1.00"
#property description "Fully configurable auto trading bot"
#property strict

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include "Settings.mqh"
#include "Indicators.mqh"
#include "RiskManager.mqh"
#include "TradeManager.mqh"
#include "Strategy.mqh"
#include "Utils.mqh"
#include "Dashboard.mqh"

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
string g_symbol;
int    g_prevPositionCount = 0;     // Track position changes for notifications
ulong  g_prevTickets[];             // Track open tickets for close detection
double g_prevPrices[];              // Track open prices for close detection
double g_prevLots[];                // Track lots for close detection
int    g_prevTypes[];               // Track types for close detection

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_symbol = Symbol();
   
   // Validate settings
   if(!ValidateSettings())
      return INIT_PARAMETERS_INCORRECT;
   
   // Initialize modules
   InitTradeManager();
   InitRiskManager();
   
   // Initialize indicators
   ENUM_TIMEFRAMES tf = (InpTimeframe == PERIOD_CURRENT) ? Period() : InpTimeframe;
   if(!InitIndicators(g_symbol, tf))
   {
      Print("ERROR: Failed to initialize indicators");
      return INIT_FAILED;
   }
   
   // Store current positions
   StorePositionSnapshot();
   
   // Startup log
   LogMessage("═══════════════════════════════════════");
   LogMessage("AutoTraderBot v1.00 STARTED");
   LogMessage("Symbol:   " + g_symbol);
   LogMessage("Strategy: " + GetStrategyName());
   LogMessage("Lot Mode: " + EnumToString(InpLotMode));
   LogMessage("Magic:    " + IntegerToString(InpMagicNumber));
   LogMessage("═══════════════════════════════════════");
   
   // Send Telegram startup message
   if(InpUseTelegram)
   {
      string msg = "🚀 <b>AutoTraderBot STARTED</b>\n";
      msg += "Symbol: " + g_symbol + "\n";
      msg += "Strategy: " + GetStrategyName() + "\n";
      msg += "Timeframe: " + EnumToString(InpTimeframe);
      SendTelegram(msg);
   }
   
   // Initial dashboard
   UpdateDashboard(g_symbol, InpMagicNumber);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeinitIndicators();
   RemoveDashboard();
   
   LogMessage("AutoTraderBot STOPPED. Reason: " + IntegerToString(reason));
   
   if(InpUseTelegram)
   {
      string msg = "🛑 <b>AutoTraderBot STOPPED</b>\n";
      msg += "Symbol: " + g_symbol + "\n";
      msg += "Reason: " + IntegerToString(reason);
      SendTelegram(msg);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   ENUM_TIMEFRAMES tf = (InpTimeframe == PERIOD_CURRENT) ? Period() : InpTimeframe;
   
   // 1. Manage existing positions (trailing & break even on every tick)
   ManageTrailingStop(g_symbol, InpMagicNumber);
   ManageBreakEven(g_symbol, InpMagicNumber);
   
   // 2. Check for closed positions (for notifications)
   CheckClosedPositions();
   
   // 3. Daily summary check
   CheckDailySummary(InpMagicNumber);
   
   // 4. Update dashboard (throttled)
   static datetime lastDashUpdate = 0;
   if(TimeCurrent() - lastDashUpdate >= 1) // Update every second max
   {
      UpdateDashboard(g_symbol, InpMagicNumber);
      lastDashUpdate = TimeCurrent();
   }
   
   // 5. Only check for new signals on new bar (except Grid strategy)
   if(InpStrategy != STRATEGY_GRID)
   {
      if(!IsNewBar(g_symbol, tf))
         return;
   }
   
   // 6. Check filters
   if(!IsTimeAllowed())
      return;
   
   if(!IsSpreadAllowed(g_symbol))
      return;
   
   // 7. Check risk limits
   if(!IsRiskAllowed(g_symbol))
      return;
   
   // 8. Get trading signal
   int signal = GetSignal(g_symbol, tf);
   
   if(signal == SIGNAL_NONE)
      return;
   
   // 9. Execute trade
   ExecuteTrade(signal);
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
   double lotSize;
   double sl, tp;
   
   if(signal == SIGNAL_BUY)
   {
      double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
      
      sl = CalculateSL(g_symbol, ORDER_TYPE_BUY, ask);
      tp = CalculateTP(g_symbol, ORDER_TYPE_BUY, ask);
      
      lotSize = CalculateLotSize(g_symbol, InpSL_Pips);
      
      // Grid lot multiplier
      if(InpStrategy == STRATEGY_GRID)
      {
         int level = CountPositions(InpMagicNumber, g_symbol);
         if(level > 0 && InpGridMultiplier > 1.0)
            lotSize = NormalizeDouble(lotSize * MathPow(InpGridMultiplier, level), 2);
      }
      
      // Check max buy orders
      if(InpMaxBuyOrders > 0)
      {
         int buyCount = CountPositions(InpMagicNumber, g_symbol, POSITION_TYPE_BUY);
         if(buyCount >= InpMaxBuyOrders) return;
      }
      
      if(OpenBuy(g_symbol, lotSize, sl, tp, InpComment))
      {
         SendNotification_Entry(g_symbol, "BUY", lotSize, ask, sl, tp);
         StorePositionSnapshot();
      }
   }
   else if(signal == SIGNAL_SELL)
   {
      double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
      
      sl = CalculateSL(g_symbol, ORDER_TYPE_SELL, bid);
      tp = CalculateTP(g_symbol, ORDER_TYPE_SELL, bid);
      
      lotSize = CalculateLotSize(g_symbol, InpSL_Pips);
      
      // Grid lot multiplier
      if(InpStrategy == STRATEGY_GRID)
      {
         int level = CountPositions(InpMagicNumber, g_symbol);
         if(level > 0 && InpGridMultiplier > 1.0)
            lotSize = NormalizeDouble(lotSize * MathPow(InpGridMultiplier, level), 2);
      }
      
      // Check max sell orders
      if(InpMaxSellOrders > 0)
      {
         int sellCount = CountPositions(InpMagicNumber, g_symbol, POSITION_TYPE_SELL);
         if(sellCount >= InpMaxSellOrders) return;
      }
      
      if(OpenSell(g_symbol, lotSize, sl, tp, InpComment))
      {
         SendNotification_Entry(g_symbol, "SELL", lotSize, bid, sl, tp);
         StorePositionSnapshot();
      }
   }
}

//+------------------------------------------------------------------+
//| Validate input settings                                          |
//+------------------------------------------------------------------+
bool ValidateSettings()
{
   bool valid = true;
   
   if(InpMA_FastPeriod >= InpMA_SlowPeriod)
   {
      Print("WARNING: Fast MA period should be less than Slow MA period");
      // Not fatal, just warning
   }
   
   if(InpMagicNumber <= 0)
   {
      Print("ERROR: Magic Number must be positive");
      valid = false;
   }
   
   if(InpLotSize <= 0 && InpLotMode == LOT_FIXED)
   {
      Print("ERROR: Fixed lot size must be positive");
      valid = false;
   }
   
   if(InpRiskPercent <= 0 && (InpLotMode == LOT_PERCENT || InpLotMode == LOT_EQUITY))
   {
      Print("ERROR: Risk percent must be positive");
      valid = false;
   }
   
   if(InpMaxOrders <= 0)
   {
      Print("ERROR: Max orders must be positive");
      valid = false;
   }
   
   if(InpUseTelegram && (InpTelegramToken == "" || InpTelegramChatID == ""))
   {
      Print("WARNING: Telegram enabled but Token/ChatID not set");
   }
   
   return valid;
}

//+------------------------------------------------------------------+
//| Store snapshot of current positions for close detection           |
//+------------------------------------------------------------------+
void StorePositionSnapshot()
{
   CPositionInfo pos;
   int count = 0;
   
   // First pass: count positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == InpMagicNumber && pos.Symbol() == g_symbol)
            count++;
      }
   }
   
   ArrayResize(g_prevTickets, count);
   ArrayResize(g_prevPrices, count);
   ArrayResize(g_prevLots, count);
   ArrayResize(g_prevTypes, count);
   g_prevPositionCount = count;
   
   // Second pass: store data
   int idx = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == InpMagicNumber && pos.Symbol() == g_symbol)
         {
            g_prevTickets[idx] = pos.Ticket();
            g_prevPrices[idx]  = pos.PriceOpen();
            g_prevLots[idx]    = pos.Volume();
            g_prevTypes[idx]   = (int)pos.PositionType();
            idx++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if any positions were closed (for exit notification)       |
//+------------------------------------------------------------------+
void CheckClosedPositions()
{
   int currentCount = CountPositions(InpMagicNumber, g_symbol);
   
   if(currentCount < g_prevPositionCount)
   {
      // A position was closed - find which one
      CPositionInfo pos;
      
      for(int i = 0; i < g_prevPositionCount; i++)
      {
         bool found = false;
         
         for(int j = PositionsTotal() - 1; j >= 0; j--)
         {
            if(pos.SelectByIndex(j))
            {
               if(pos.Ticket() == g_prevTickets[i])
               {
                  found = true;
                  break;
               }
            }
         }
         
         if(!found)
         {
            // This position was closed - try to find it in history
            HistorySelectByPosition(g_prevTickets[i]);
            
            string direction = (g_prevTypes[i] == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            double closePrice = SymbolInfoDouble(g_symbol, SYMBOL_BID);
            
            // Calculate approximate profit
            double profit = 0;
            if(HistoryDealsTotal() > 0)
            {
               ulong dealTicket = HistoryDealGetTicket(HistoryDealsTotal() - 1);
               if(dealTicket > 0)
               {
                  profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) + 
                           HistoryDealGetDouble(dealTicket, DEAL_SWAP) +
                           HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                  closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
               }
            }
            
            LogMessage("Position closed: " + direction + " " + g_symbol + 
                       " Profit=$" + DoubleToString(profit, 2));
            
            SendNotification_Exit(g_symbol, direction, g_prevLots[i], 
                                   g_prevPrices[i], closePrice, profit);
         }
      }
      
      StorePositionSnapshot();
   }
   else if(currentCount > g_prevPositionCount)
   {
      // New position opened externally, update snapshot
      StorePositionSnapshot();
   }
}
//+------------------------------------------------------------------+
