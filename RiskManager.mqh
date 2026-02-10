//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                           Risk management for AutoTraderBot      |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Global variables for risk tracking                               |
//+------------------------------------------------------------------+
double g_dailyStartBalance = 0.0;
datetime g_dailyResetDate  = 0;

//+------------------------------------------------------------------+
//| Initialize daily tracking                                        |
//+------------------------------------------------------------------+
void InitRiskManager()
{
   CAccountInfo account;
   g_dailyStartBalance = account.Balance();
   g_dailyResetDate = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
}

//+------------------------------------------------------------------+
//| Reset daily loss tracking at new day                             |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   if(today > g_dailyResetDate)
   {
      CAccountInfo account;
      g_dailyStartBalance = account.Balance();
      g_dailyResetDate = today;
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on mode                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, double slPips)
{
   double lotSize = InpLotSize;
   
   CAccountInfo account;
   CSymbolInfo symbolInfo;
   symbolInfo.Name(symbol);
   symbolInfo.RefreshRates();
   
   if(InpLotMode == LOT_PERCENT || InpLotMode == LOT_EQUITY)
   {
      double capital = (InpLotMode == LOT_PERCENT) ? account.Balance() : account.Equity();
      double riskAmount = capital * InpRiskPercent / 100.0;
      
      if(slPips > 0)
      {
         double tickValue = symbolInfo.TickValue();
         double tickSize  = symbolInfo.TickSize();
         double point     = symbolInfo.Point();
         
         if(tickValue > 0 && point > 0)
         {
            double pipValue = tickValue * (point * 10.0) / tickSize;
            lotSize = riskAmount / (slPips * pipValue);
         }
      }
      else
      {
         // Fallback if SL not set - use 1% of capital / 1000
         lotSize = NormalizeDouble(capital * InpRiskPercent / 100000.0, 2);
      }
   }
   
   // Normalize lot size
   double minLot  = symbolInfo.LotsMin();
   double maxLot  = symbolInfo.LotsMax();
   double lotStep = symbolInfo.LotsStep();
   
   // Apply user limits
   if(InpMinLotSize > minLot) minLot = InpMinLotSize;
   if(InpMaxLotSize < maxLot) maxLot = InpMaxLotSize;
   
   // Round to lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   
   // Clamp
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;
   
   return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Count open positions by type                                     |
//+------------------------------------------------------------------+
int CountPositions(int magicNumber, string symbol, ENUM_POSITION_TYPE posType = -1)
{
   int count = 0;
   CPositionInfo pos;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == magicNumber && pos.Symbol() == symbol)
         {
            if(posType == -1 || pos.PositionType() == posType)
               count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Count all open positions for this EA                             |
//+------------------------------------------------------------------+
int CountAllPositions(int magicNumber)
{
   int count = 0;
   CPositionInfo pos;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == magicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get total profit/loss for today                                  |
//+------------------------------------------------------------------+
double GetDailyPnL()
{
   CAccountInfo account;
   return account.Balance() - g_dailyStartBalance;
}

//+------------------------------------------------------------------+
//| Get current drawdown percentage                                  |
//+------------------------------------------------------------------+
double GetDrawdownPercent()
{
   CAccountInfo account;
   double balance = account.Balance();
   double equity  = account.Equity();
   
   if(balance <= 0) return 0.0;
   
   double drawdown = (balance - equity) / balance * 100.0;
   return (drawdown > 0) ? drawdown : 0.0;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed by risk rules                        |
//+------------------------------------------------------------------+
bool IsRiskAllowed(string symbol)
{
   CheckDailyReset();
   
   // Check max orders
   int totalOrders = CountAllPositions(InpMagicNumber);
   if(totalOrders >= InpMaxOrders)
   {
      Print("Risk: Max orders reached (", totalOrders, "/", InpMaxOrders, ")");
      return false;
   }
   
   // Check max buy/sell orders
   if(InpMaxBuyOrders > 0)
   {
      int buyCount = CountPositions(InpMagicNumber, symbol, POSITION_TYPE_BUY);
      if(buyCount >= InpMaxBuyOrders)
      {
         Print("Risk: Max buy orders reached");
         return false;
      }
   }
   
   if(InpMaxSellOrders > 0)
   {
      int sellCount = CountPositions(InpMagicNumber, symbol, POSITION_TYPE_SELL);
      if(sellCount >= InpMaxSellOrders)
      {
         Print("Risk: Max sell orders reached");
         return false;
      }
   }
   
   // Check daily loss
   if(InpMaxDailyLoss > 0)
   {
      double dailyPnL = GetDailyPnL();
      if(dailyPnL <= -InpMaxDailyLoss)
      {
         Print("Risk: Max daily loss reached ($", DoubleToString(MathAbs(dailyPnL), 2), ")");
         return false;
      }
   }
   
   // Check max drawdown
   if(InpMaxDrawdown > 0)
   {
      double dd = GetDrawdownPercent();
      if(dd >= InpMaxDrawdown)
      {
         Print("Risk: Max drawdown reached (", DoubleToString(dd, 1), "%)");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get total floating P/L for this EA                               |
//+------------------------------------------------------------------+
double GetFloatingPnL(int magicNumber)
{
   double totalPnL = 0.0;
   CPositionInfo pos;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == magicNumber)
            totalPnL += pos.Profit() + pos.Swap() + pos.Commission();
      }
   }
   return totalPnL;
}

//+------------------------------------------------------------------+
//| Calculate SL price from pips                                     |
//+------------------------------------------------------------------+
double CalculateSL(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice)
{
   if(!InpUseSL || InpSL_Pips <= 0) return 0.0;
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipSize = point * 10; // Standard pip
   
   // For JPY pairs and metals, adjust if needed
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 2) pipSize = point;
   
   double slDistance = InpSL_Pips * pipSize;
   
   if(orderType == ORDER_TYPE_BUY)
      return NormalizeDouble(entryPrice - slDistance, digits);
   else
      return NormalizeDouble(entryPrice + slDistance, digits);
}

//+------------------------------------------------------------------+
//| Calculate TP price from pips                                     |
//+------------------------------------------------------------------+
double CalculateTP(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice)
{
   if(!InpUseTP) return 0.0;
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipSize = point * 10;
   
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 2) pipSize = point;
   
   double tpPips = InpTP_Pips;
   
   // Risk:Reward ratio override
   if(InpRiskReward > 0 && InpSL_Pips > 0)
      tpPips = InpSL_Pips * InpRiskReward;
   
   if(tpPips <= 0) return 0.0;
   
   double tpDistance = tpPips * pipSize;
   
   if(orderType == ORDER_TYPE_BUY)
      return NormalizeDouble(entryPrice + tpDistance, digits);
   else
      return NormalizeDouble(entryPrice - tpDistance, digits);
}
