//+------------------------------------------------------------------+
//|                                                     Strategy.mqh |
//|                          Strategy logic for AutoTraderBot        |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

//+------------------------------------------------------------------+
//| Signal constants                                                 |
//+------------------------------------------------------------------+
#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

//+------------------------------------------------------------------+
//| Track if signal was already processed on current bar             |
//+------------------------------------------------------------------+
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar(string symbol, ENUM_TIMEFRAMES tf)
{
   datetime barTime[];
   if(CopyTime(symbol, tf, 0, 1, barTime) != 1) return false;
   
   if(barTime[0] != g_lastBarTime)
   {
      g_lastBarTime = barTime[0];
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Main strategy dispatcher                                         |
//+------------------------------------------------------------------+
int GetSignal(string symbol, ENUM_TIMEFRAMES tf)
{
   switch(InpStrategy)
   {
      case STRATEGY_TREND_FOLLOWING: return SignalTrendFollowing(symbol, tf);
      case STRATEGY_SCALPING:        return SignalScalping(symbol, tf);
      case STRATEGY_BREAKOUT:        return SignalBreakout(symbol, tf);
      case STRATEGY_MEAN_REVERSION:  return SignalMeanReversion(symbol, tf);
      case STRATEGY_GRID:            return SignalGrid(symbol, tf);
      case STRATEGY_CUSTOM:          return SignalCustom(symbol, tf);
      case STRATEGY_AI:              return SignalAI(symbol, tf);
      case STRATEGY_AI_HYBRID:       return SignalAI_Hybrid(symbol, tf);
      default:                       return SIGNAL_NONE;
   }
}

//+------------------------------------------------------------------+
//| STRATEGY 1: Trend Following                                      |
//| MA Crossover + ADX filter                                        |
//| BUY:  Fast MA crosses above Slow MA + ADX > threshold            |
//| SELL: Fast MA crosses below Slow MA + ADX > threshold            |
//+------------------------------------------------------------------+
int SignalTrendFollowing(string symbol, ENUM_TIMEFRAMES tf)
{
   // Current and previous MA values
   double fastMA_1 = GetMA_Fast(1);
   double fastMA_2 = GetMA_Fast(2);
   double slowMA_1 = GetMA_Slow(1);
   double slowMA_2 = GetMA_Slow(2);
   
   // ADX filter
   double adx = GetADX(1);
   double plusDI  = GetADX_PlusDI(1);
   double minusDI = GetADX_MinusDI(1);
   
   if(adx < InpADX_Threshold)
      return SIGNAL_NONE; // No trend
   
   // Buy: Fast crosses above Slow
   if(fastMA_2 <= slowMA_2 && fastMA_1 > slowMA_1 && plusDI > minusDI)
      return SIGNAL_BUY;
   
   // Sell: Fast crosses below Slow
   if(fastMA_2 >= slowMA_2 && fastMA_1 < slowMA_1 && minusDI > plusDI)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| STRATEGY 2: Scalping                                             |
//| RSI + Bollinger Bands                                            |
//| BUY:  Price touches lower BB + RSI oversold                      |
//| SELL: Price touches upper BB + RSI overbought                    |
//+------------------------------------------------------------------+
int SignalScalping(string symbol, ENUM_TIMEFRAMES tf)
{
   double close[];
   if(CopyClose(symbol, tf, 1, 1, close) != 1) return SIGNAL_NONE;
   double price = close[0];
   
   double rsi  = GetRSI(1);
   double bbUpper = GetBB_Upper(1);
   double bbLower = GetBB_Lower(1);
   
   // Buy: Price at/below lower BB + RSI oversold
   if(price <= bbLower && rsi <= InpRSI_Oversold)
      return SIGNAL_BUY;
   
   // Sell: Price at/above upper BB + RSI overbought
   if(price >= bbUpper && rsi >= InpRSI_Overbought)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| STRATEGY 3: Breakout                                             |
//| Donchian Channel                                                 |
//| BUY:  Price breaks above Donchian High                           |
//| SELL: Price breaks below Donchian Low                            |
//+------------------------------------------------------------------+
int SignalBreakout(string symbol, ENUM_TIMEFRAMES tf)
{
   double close[];
   if(CopyClose(symbol, tf, 0, 1, close) != 1) return SIGNAL_NONE;
   double currentPrice = close[0];
   
   double donchianHigh = GetDonchian_High(symbol, tf, InpDonchian_Period, 1);
   double donchianLow  = GetDonchian_Low(symbol, tf, InpDonchian_Period, 1);
   
   if(donchianHigh == 0 || donchianLow == 0) return SIGNAL_NONE;
   
   // ADX filter for breakout strength
   double adx = GetADX(1);
   
   // Buy: Price breaks above Donchian High
   if(currentPrice > donchianHigh && adx > InpADX_Threshold)
      return SIGNAL_BUY;
   
   // Sell: Price breaks below Donchian Low
   if(currentPrice < donchianLow && adx > InpADX_Threshold)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| STRATEGY 4: Mean Reversion                                       |
//| RSI + Bollinger Bands bounce                                     |
//| BUY:  RSI oversold + price bouncing from lower BB                |
//| SELL: RSI overbought + price bouncing from upper BB              |
//+------------------------------------------------------------------+
int SignalMeanReversion(string symbol, ENUM_TIMEFRAMES tf)
{
   double close1[], close2[];
   if(CopyClose(symbol, tf, 1, 1, close1) != 1) return SIGNAL_NONE;
   if(CopyClose(symbol, tf, 2, 1, close2) != 1) return SIGNAL_NONE;
   
   double price1 = close1[0];
   double price2 = close2[0];
   
   double rsi1   = GetRSI(1);
   double rsi2   = GetRSI(2);
   double bbUpper = GetBB_Upper(1);
   double bbLower = GetBB_Lower(1);
   double bbMiddle = GetBB_Middle(1);
   
   // Buy: RSI was oversold and bouncing up, price was below lower BB
   if(rsi2 <= InpRSI_Oversold && rsi1 > InpRSI_Oversold && price2 <= bbLower)
      return SIGNAL_BUY;
   
   // Sell: RSI was overbought and bouncing down, price was above upper BB
   if(rsi2 >= InpRSI_Overbought && rsi1 < InpRSI_Overbought && price2 >= bbUpper)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| STRATEGY 5: Grid Trading                                         |
//| Places orders at grid spacing intervals                          |
//+------------------------------------------------------------------+
int SignalGrid(string symbol, ENUM_TIMEFRAMES tf)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pipSize = point * 10;
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 2) pipSize = point;
   
   double gridDist = InpGridSpacing * pipSize;
   
   int totalPos = CountPositions(InpMagicNumber, symbol);
   
   // First order - use MA direction
   if(totalPos == 0)
   {
      double fastMA = GetMA_Fast(1);
      double slowMA = GetMA_Slow(1);
      if(fastMA > slowMA) return SIGNAL_BUY;
      if(fastMA < slowMA) return SIGNAL_SELL;
      return SIGNAL_NONE;
   }
   
   // Check if max grid levels reached
   if(totalPos >= InpGridMaxLevels) return SIGNAL_NONE;
   
   // Get last position price
   double lastPrice = GetLastPositionPrice(symbol, InpMagicNumber);
   if(lastPrice == 0) return SIGNAL_NONE;
   
   double currentBid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Grid: open same direction if price moved against us by grid spacing
   CPositionInfo pos;
   ulong lastTicket = GetLastPositionTicket(symbol, InpMagicNumber);
   if(lastTicket > 0 && pos.SelectByTicket(lastTicket))
   {
      if(pos.PositionType() == POSITION_TYPE_BUY)
      {
         if(currentBid <= lastPrice - gridDist)
            return SIGNAL_BUY;
      }
      else
      {
         if(currentBid >= lastPrice + gridDist)
            return SIGNAL_SELL;
      }
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| STRATEGY 6: Custom Strategy                                      |
//| User-configurable combinations                                   |
//+------------------------------------------------------------------+
int SignalCustom(string symbol, ENUM_TIMEFRAMES tf)
{
   switch(InpCustomSignal)
   {
      case CUSTOM_MA_RSI:      return SignalCustom_MA_RSI(symbol, tf);
      case CUSTOM_MACD_BB:     return SignalCustom_MACD_BB(symbol, tf);
      case CUSTOM_ADX_STOCH:   return SignalCustom_ADX_Stoch(symbol, tf);
      case CUSTOM_ICHIMOKU:    return SignalCustom_Ichimoku(symbol, tf);
      case CUSTOM_MULTI_TF:    return SignalCustom_MultiTF(symbol, tf);
      default:                 return SIGNAL_NONE;
   }
}

//+------------------------------------------------------------------+
//| Custom: MA + RSI Combo                                           |
//| Uses CustomParam1 as fast MA, CustomParam2 as slow MA,           |
//| CustomParam3 as RSI period                                       |
//+------------------------------------------------------------------+
int SignalCustom_MA_RSI(string symbol, ENUM_TIMEFRAMES tf)
{
   double ma1_cur = GetCustomMA1(1);
   double ma1_prev = GetCustomMA1(2);
   double ma2_cur = GetCustomMA2(1);
   double ma2_prev = GetCustomMA2(2);
   double rsi = GetCustomRSI(1);
   
   // Buy: MA crossover up + RSI not overbought
   if(ma1_prev <= ma2_prev && ma1_cur > ma2_cur && rsi < InpCustomLevel2)
      return SIGNAL_BUY;
   
   // Sell: MA crossover down + RSI not oversold
   if(ma1_prev >= ma2_prev && ma1_cur < ma2_cur && rsi > InpCustomLevel1)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Custom: MACD + Bollinger Bands                                   |
//| MACD crossover + price relative to BB                            |
//+------------------------------------------------------------------+
int SignalCustom_MACD_BB(string symbol, ENUM_TIMEFRAMES tf)
{
   double macdMain1   = GetMACD_Main(1);
   double macdMain2   = GetMACD_Main(2);
   double macdSignal1 = GetMACD_Signal(1);
   double macdSignal2 = GetMACD_Signal(2);
   
   double bbMiddle = GetBB_Middle(1);
   double bbLower  = GetBB_Lower(1);
   double bbUpper  = GetBB_Upper(1);
   
   double close[];
   if(CopyClose(symbol, tf, 1, 1, close) != 1) return SIGNAL_NONE;
   double price = close[0];
   
   // Buy: MACD crosses above signal + price below BB middle
   if(macdMain2 <= macdSignal2 && macdMain1 > macdSignal1 && price < bbMiddle)
      return SIGNAL_BUY;
   
   // Sell: MACD crosses below signal + price above BB middle
   if(macdMain2 >= macdSignal2 && macdMain1 < macdSignal1 && price > bbMiddle)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Custom: ADX + Stochastic                                         |
//| ADX for trend strength + Stochastic for entry timing             |
//+------------------------------------------------------------------+
int SignalCustom_ADX_Stoch(string symbol, ENUM_TIMEFRAMES tf)
{
   double adx    = GetADX(1);
   double plusDI  = GetADX_PlusDI(1);
   double minusDI = GetADX_MinusDI(1);
   
   double stochK1 = GetStoch_K(1);
   double stochK2 = GetStoch_K(2);
   double stochD1 = GetStoch_D(1);
   
   if(adx < InpADX_Threshold) return SIGNAL_NONE;
   
   // Buy: Uptrend + Stochastic crosses up from oversold
   if(plusDI > minusDI && stochK2 <= InpStoch_Lower && stochK1 > stochD1)
      return SIGNAL_BUY;
   
   // Sell: Downtrend + Stochastic crosses down from overbought
   if(minusDI > plusDI && stochK2 >= InpStoch_Upper && stochK1 < stochD1)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Custom: Ichimoku Cloud                                           |
//| Tenkan/Kijun cross + Cloud filter                                |
//+------------------------------------------------------------------+
int SignalCustom_Ichimoku(string symbol, ENUM_TIMEFRAMES tf)
{
   double tenkan1 = GetIchimoku_Tenkan(1);
   double tenkan2 = GetIchimoku_Tenkan(2);
   double kijun1  = GetIchimoku_Kijun(1);
   double kijun2  = GetIchimoku_Kijun(2);
   double spanA   = GetIchimoku_SpanA(1);
   double spanB   = GetIchimoku_SpanB(1);
   
   double close[];
   if(CopyClose(symbol, tf, 1, 1, close) != 1) return SIGNAL_NONE;
   double price = close[0];
   
   double cloudTop    = MathMax(spanA, spanB);
   double cloudBottom = MathMin(spanA, spanB);
   
   // Buy: Tenkan crosses above Kijun + Price above cloud
   if(tenkan2 <= kijun2 && tenkan1 > kijun1 && price > cloudTop)
      return SIGNAL_BUY;
   
   // Sell: Tenkan crosses below Kijun + Price below cloud
   if(tenkan2 >= kijun2 && tenkan1 < kijun1 && price < cloudBottom)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Custom: Multi-Timeframe MA                                       |
//| MA on current TF + MA on higher TF must agree                    |
//+------------------------------------------------------------------+
int SignalCustom_MultiTF(string symbol, ENUM_TIMEFRAMES tf)
{
   double fastMA_1 = GetMA_Fast(1);
   double fastMA_2 = GetMA_Fast(2);
   double slowMA_1 = GetMA_Slow(1);
   double slowMA_2 = GetMA_Slow(2);
   
   // Higher TF MA direction
   double htfMA = GetCustomTF2_MA(1);
   
   double close[];
   if(CopyClose(symbol, tf, 1, 1, close) != 1) return SIGNAL_NONE;
   double price = close[0];
   
   // Buy: Current TF MA cross up + Price above higher TF MA (both bullish)
   if(fastMA_2 <= slowMA_2 && fastMA_1 > slowMA_1 && price > htfMA)
      return SIGNAL_BUY;
   
   // Sell: Current TF MA cross down + Price below higher TF MA (both bearish)
   if(fastMA_2 >= slowMA_2 && fastMA_1 < slowMA_1 && price < htfMA)
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}
