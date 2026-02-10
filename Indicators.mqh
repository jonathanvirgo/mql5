//+------------------------------------------------------------------+
//|                                                   Indicators.mqh |
//|                              Indicator wrapper for AutoTraderBot |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

//+------------------------------------------------------------------+
//| Indicator handles (global)                                       |
//+------------------------------------------------------------------+
int g_handleMA_Fast   = INVALID_HANDLE;
int g_handleMA_Slow   = INVALID_HANDLE;
int g_handleRSI       = INVALID_HANDLE;
int g_handleBB        = INVALID_HANDLE;
int g_handleMACD      = INVALID_HANDLE;
int g_handleADX       = INVALID_HANDLE;
int g_handleStoch     = INVALID_HANDLE;
int g_handleIchimoku  = INVALID_HANDLE;

// Custom strategy extra handles
int g_handleCustomMA1 = INVALID_HANDLE;
int g_handleCustomMA2 = INVALID_HANDLE;
int g_handleCustomRSI = INVALID_HANDLE;
int g_handleCustomTF2_MA = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Convert our enum to MQL5 MA method                               |
//+------------------------------------------------------------------+
ENUM_MA_METHOD ConvertMAMethod(ENUM_MA_TYPE maType)
{
   switch(maType)
   {
      case MA_SMA:  return MODE_SMA;
      case MA_EMA:  return MODE_EMA;
      case MA_SMMA: return MODE_SMMA;
      case MA_LWMA: return MODE_LWMA;
      default:      return MODE_SMA;
   }
}

//+------------------------------------------------------------------+
//| Initialize all indicators based on strategy                      |
//+------------------------------------------------------------------+
bool InitIndicators(string symbol, ENUM_TIMEFRAMES tf)
{
   ENUM_MA_METHOD maMethod = ConvertMAMethod(InpMA_Method);
   
   // MA indicators (many strategies need these)
   g_handleMA_Fast = iMA(symbol, tf, InpMA_FastPeriod, 0, maMethod, InpMA_Price);
   g_handleMA_Slow = iMA(symbol, tf, InpMA_SlowPeriod, 0, maMethod, InpMA_Price);
   
   if(g_handleMA_Fast == INVALID_HANDLE || g_handleMA_Slow == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create MA indicators");
      return false;
   }
   
   // RSI
   g_handleRSI = iRSI(symbol, tf, InpRSI_Period, PRICE_CLOSE);
   if(g_handleRSI == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create RSI indicator");
      return false;
   }
   
   // Bollinger Bands
   g_handleBB = iBands(symbol, tf, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
   if(g_handleBB == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create Bollinger Bands indicator");
      return false;
   }
   
   // MACD
   g_handleMACD = iMACD(symbol, tf, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   if(g_handleMACD == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create MACD indicator");
      return false;
   }
   
   // ADX
   g_handleADX = iADX(symbol, tf, InpADX_Period);
   if(g_handleADX == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ADX indicator");
      return false;
   }
   
   // Stochastic
   g_handleStoch = iStochastic(symbol, tf, InpStoch_KPeriod, InpStoch_DPeriod, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
   if(g_handleStoch == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create Stochastic indicator");
      return false;
   }
   
   // Ichimoku (for custom strategy)
   g_handleIchimoku = iIchimoku(symbol, tf, 9, 26, 52);
   if(g_handleIchimoku == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create Ichimoku indicator");
      return false;
   }
   
   // Custom strategy extra indicators
   if(InpStrategy == STRATEGY_CUSTOM)
   {
      if(InpCustomSignal == CUSTOM_MA_RSI)
      {
         g_handleCustomMA1 = iMA(symbol, tf, InpCustomParam1, 0, maMethod, InpMA_Price);
         g_handleCustomMA2 = iMA(symbol, tf, InpCustomParam2, 0, maMethod, InpMA_Price);
         g_handleCustomRSI = iRSI(symbol, tf, InpCustomParam3, PRICE_CLOSE);
      }
      else if(InpCustomSignal == CUSTOM_MULTI_TF)
      {
         g_handleCustomTF2_MA = iMA(symbol, InpCustomTF2, InpCustomParam1, 0, maMethod, InpMA_Price);
         if(g_handleCustomTF2_MA == INVALID_HANDLE)
         {
            Print("ERROR: Failed to create Multi-TF MA indicator");
            return false;
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                    |
//+------------------------------------------------------------------+
void DeinitIndicators()
{
   if(g_handleMA_Fast   != INVALID_HANDLE) IndicatorRelease(g_handleMA_Fast);
   if(g_handleMA_Slow   != INVALID_HANDLE) IndicatorRelease(g_handleMA_Slow);
   if(g_handleRSI       != INVALID_HANDLE) IndicatorRelease(g_handleRSI);
   if(g_handleBB        != INVALID_HANDLE) IndicatorRelease(g_handleBB);
   if(g_handleMACD      != INVALID_HANDLE) IndicatorRelease(g_handleMACD);
   if(g_handleADX       != INVALID_HANDLE) IndicatorRelease(g_handleADX);
   if(g_handleStoch     != INVALID_HANDLE) IndicatorRelease(g_handleStoch);
   if(g_handleIchimoku  != INVALID_HANDLE) IndicatorRelease(g_handleIchimoku);
   if(g_handleCustomMA1 != INVALID_HANDLE) IndicatorRelease(g_handleCustomMA1);
   if(g_handleCustomMA2 != INVALID_HANDLE) IndicatorRelease(g_handleCustomMA2);
   if(g_handleCustomRSI != INVALID_HANDLE) IndicatorRelease(g_handleCustomRSI);
   if(g_handleCustomTF2_MA != INVALID_HANDLE) IndicatorRelease(g_handleCustomTF2_MA);
}

//+------------------------------------------------------------------+
//| Get indicator value by handle                                    |
//+------------------------------------------------------------------+
double GetIndicatorValue(int handle, int bufferIndex, int shift)
{
   double value[];
   if(handle == INVALID_HANDLE) return 0.0;
   if(CopyBuffer(handle, bufferIndex, shift, 1, value) != 1) return 0.0;
   return value[0];
}

//+------------------------------------------------------------------+
//| Get MA value                                                     |
//+------------------------------------------------------------------+
double GetMA_Fast(int shift = 1)  { return GetIndicatorValue(g_handleMA_Fast, 0, shift);  }
double GetMA_Slow(int shift = 1)  { return GetIndicatorValue(g_handleMA_Slow, 0, shift);  }

//+------------------------------------------------------------------+
//| Get RSI value                                                    |
//+------------------------------------------------------------------+
double GetRSI(int shift = 1)      { return GetIndicatorValue(g_handleRSI, 0, shift);      }

//+------------------------------------------------------------------+
//| Get Bollinger Band values                                        |
//+------------------------------------------------------------------+
double GetBB_Middle(int shift = 1) { return GetIndicatorValue(g_handleBB, 0, shift); }
double GetBB_Upper(int shift = 1)  { return GetIndicatorValue(g_handleBB, 1, shift); }
double GetBB_Lower(int shift = 1)  { return GetIndicatorValue(g_handleBB, 2, shift); }

//+------------------------------------------------------------------+
//| Get MACD values                                                  |
//+------------------------------------------------------------------+
double GetMACD_Main(int shift = 1)   { return GetIndicatorValue(g_handleMACD, 0, shift);   }
double GetMACD_Signal(int shift = 1) { return GetIndicatorValue(g_handleMACD, 1, shift);   }

//+------------------------------------------------------------------+
//| Get ADX values                                                   |
//+------------------------------------------------------------------+
double GetADX(int shift = 1)       { return GetIndicatorValue(g_handleADX, 0, shift);     }
double GetADX_PlusDI(int shift = 1)  { return GetIndicatorValue(g_handleADX, 1, shift);   }
double GetADX_MinusDI(int shift = 1) { return GetIndicatorValue(g_handleADX, 2, shift);   }

//+------------------------------------------------------------------+
//| Get Stochastic values                                            |
//+------------------------------------------------------------------+
double GetStoch_K(int shift = 1)   { return GetIndicatorValue(g_handleStoch, 0, shift);   }
double GetStoch_D(int shift = 1)   { return GetIndicatorValue(g_handleStoch, 1, shift);   }

//+------------------------------------------------------------------+
//| Get Ichimoku values                                              |
//+------------------------------------------------------------------+
double GetIchimoku_Tenkan(int shift = 1)  { return GetIndicatorValue(g_handleIchimoku, 0, shift);  }
double GetIchimoku_Kijun(int shift = 1)   { return GetIndicatorValue(g_handleIchimoku, 1, shift);  }
double GetIchimoku_SpanA(int shift = 1)   { return GetIndicatorValue(g_handleIchimoku, 2, shift);  }
double GetIchimoku_SpanB(int shift = 1)   { return GetIndicatorValue(g_handleIchimoku, 3, shift);  }

//+------------------------------------------------------------------+
//| Get Donchian Channel (manual calculation)                        |
//+------------------------------------------------------------------+
double GetDonchian_High(string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 1)
{
   double high[];
   if(CopyHigh(symbol, tf, shift, period, high) != period) return 0.0;
   
   double maxHigh = high[0];
   for(int i = 1; i < period; i++)
   {
      if(high[i] > maxHigh) maxHigh = high[i];
   }
   return maxHigh;
}

double GetDonchian_Low(string symbol, ENUM_TIMEFRAMES tf, int period, int shift = 1)
{
   double low[];
   if(CopyLow(symbol, tf, shift, period, low) != period) return 0.0;
   
   double minLow = low[0];
   for(int i = 1; i < period; i++)
   {
      if(low[i] < minLow) minLow = low[i];
   }
   return minLow;
}

//+------------------------------------------------------------------+
//| Get Custom Strategy indicator values                             |
//+------------------------------------------------------------------+
double GetCustomMA1(int shift = 1) { return GetIndicatorValue(g_handleCustomMA1, 0, shift);  }
double GetCustomMA2(int shift = 1) { return GetIndicatorValue(g_handleCustomMA2, 0, shift);  }
double GetCustomRSI(int shift = 1) { return GetIndicatorValue(g_handleCustomRSI, 0, shift);  }
double GetCustomTF2_MA(int shift = 1) { return GetIndicatorValue(g_handleCustomTF2_MA, 0, shift); }
