//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                         Trade execution for AutoTraderBot        |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Trade object                                                     |
//+------------------------------------------------------------------+
CTrade g_trade;

//+------------------------------------------------------------------+
//| Initialize trade manager                                         |
//+------------------------------------------------------------------+
void InitTradeManager()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(20); // Slippage
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   g_trade.SetAsyncMode(false);
}

//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
bool OpenBuy(string symbol, double lotSize, double sl, double tp, string comment = "")
{
   if(comment == "") comment = InpComment;
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   
   if(sl > 0) sl = NormalizeDouble(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   if(tp > 0) tp = NormalizeDouble(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   
   if(g_trade.Buy(lotSize, symbol, ask, sl, tp, comment))
   {
      Print("BUY opened: ", symbol, " Lot=", lotSize, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      Print("BUY failed: ", symbol, " Error=", GetLastError(), " RetCode=", g_trade.ResultRetcode());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
bool OpenSell(string symbol, double lotSize, double sl, double tp, string comment = "")
{
   if(comment == "") comment = InpComment;
   
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(sl > 0) sl = NormalizeDouble(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   if(tp > 0) tp = NormalizeDouble(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   
   if(g_trade.Sell(lotSize, symbol, bid, sl, tp, comment))
   {
      Print("SELL opened: ", symbol, " Lot=", lotSize, " SL=", sl, " TP=", tp);
      return true;
   }
   else
   {
      Print("SELL failed: ", symbol, " Error=", GetLastError(), " RetCode=", g_trade.ResultRetcode());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close all positions for symbol                                   |
//+------------------------------------------------------------------+
void CloseAllPositions(string symbol, int magicNumber)
{
   CPositionInfo pos;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == magicNumber && pos.Symbol() == symbol)
         {
            g_trade.PositionClose(pos.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close positions by type                                          |
//+------------------------------------------------------------------+
void ClosePositionsByType(string symbol, int magicNumber, ENUM_POSITION_TYPE posType)
{
   CPositionInfo pos;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == magicNumber && pos.Symbol() == symbol && pos.PositionType() == posType)
         {
            g_trade.PositionClose(pos.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Trailing Stop                                             |
//+------------------------------------------------------------------+
void ManageTrailingStop(string symbol, int magicNumber)
{
   if(!InpUseTrailing) return;
   
   CPositionInfo pos;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipSize = point * 10;
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 2) pipSize = point;
   
   double trailStartDist = InpTrailingStart * pipSize;
   double trailStopDist  = InpTrailingStop * pipSize;
   double trailStepDist  = InpTrailingStep * pipSize;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Magic() != magicNumber || pos.Symbol() != symbol) continue;
      
      double openPrice = pos.PriceOpen();
      double currentSL = pos.StopLoss();
      double currentTP = pos.TakeProfit();
      
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
         double profitDist = bid - openPrice;
         
         if(profitDist >= trailStartDist)
         {
            double newSL = NormalizeDouble(bid - trailStopDist, digits);
            
            if(newSL > currentSL + trailStepDist || currentSL == 0)
            {
               g_trade.PositionModify(pos.Ticket(), newSL, currentTP);
            }
         }
      }
      else if(pos.PositionType() == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
         double profitDist = openPrice - ask;
         
         if(profitDist >= trailStartDist)
         {
            double newSL = NormalizeDouble(ask + trailStopDist, digits);
            
            if(newSL < currentSL - trailStepDist || currentSL == 0)
            {
               g_trade.PositionModify(pos.Ticket(), newSL, currentTP);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Break Even                                                |
//+------------------------------------------------------------------+
void ManageBreakEven(string symbol, int magicNumber)
{
   if(!InpUseBreakEven) return;
   
   CPositionInfo pos;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipSize = point * 10;
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 2) pipSize = point;
   
   double beDist   = InpBE_Pips * pipSize;
   double lockDist = InpBE_LockPips * pipSize;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Magic() != magicNumber || pos.Symbol() != symbol) continue;
      
      double openPrice = pos.PriceOpen();
      double currentSL = pos.StopLoss();
      double currentTP = pos.TakeProfit();
      
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
         
         if(bid - openPrice >= beDist)
         {
            double newSL = NormalizeDouble(openPrice + lockDist, digits);
            
            if(currentSL < newSL || currentSL == 0)
            {
               g_trade.PositionModify(pos.Ticket(), newSL, currentTP);
            }
         }
      }
      else if(pos.PositionType() == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
         
         if(openPrice - ask >= beDist)
         {
            double newSL = NormalizeDouble(openPrice - lockDist, digits);
            
            if(currentSL > newSL || currentSL == 0)
            {
               g_trade.PositionModify(pos.Ticket(), newSL, currentTP);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get last position ticket for this EA                             |
//+------------------------------------------------------------------+
ulong GetLastPositionTicket(string symbol, int magicNumber)
{
   CPositionInfo pos;
   ulong lastTicket = 0;
   datetime lastTime = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Magic() == magicNumber && pos.Symbol() == symbol)
         {
            if(pos.Time() > lastTime)
            {
               lastTime = pos.Time();
               lastTicket = pos.Ticket();
            }
         }
      }
   }
   return lastTicket;
}

//+------------------------------------------------------------------+
//| Get last position open price                                     |
//+------------------------------------------------------------------+
double GetLastPositionPrice(string symbol, int magicNumber)
{
   CPositionInfo pos;
   ulong ticket = GetLastPositionTicket(symbol, magicNumber);
   
   if(ticket > 0 && pos.SelectByTicket(ticket))
      return pos.PriceOpen();
      
   return 0.0;
}
