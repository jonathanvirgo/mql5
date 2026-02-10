//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|                    Utility functions for AutoTraderBot            |
//+------------------------------------------------------------------+
#property copyright "AutoTraderBot"
#property strict

//+------------------------------------------------------------------+
//| Telegram: Send message via Bot API using WebRequest              |
//+------------------------------------------------------------------+
bool SendTelegram(string message)
{
   if(!InpUseTelegram) return false;
   if(InpTelegramToken == "" || InpTelegramChatID == "") 
   {
      Print("Telegram: Token or ChatID not configured");
      return false;
   }
   
   // URL encode the message
   string encodedMsg = UrlEncode(message);
   
   string url = "https://api.telegram.org/bot" + InpTelegramToken 
                + "/sendMessage?chat_id=" + InpTelegramChatID 
                + "&parse_mode=HTML&text=" + encodedMsg;
   
   char   data[];
   char   result[];
   string headers = "";
   string resultHeaders;
   
   int timeout = 5000; // 5 seconds
   
   int res = WebRequest("GET", url, headers, timeout, data, result, resultHeaders);
   
   if(res == -1)
   {
      int error = GetLastError();
      if(error == 4014)
      {
         Print("Telegram ERROR: Add 'https://api.telegram.org' to Tools > Options > Expert Advisors > Allow WebRequest for listed URL");
      }
      else
      {
         Print("Telegram ERROR: WebRequest failed, error=", error);
      }
      return false;
   }
   
   if(res != 200)
   {
      Print("Telegram ERROR: HTTP ", res, " Response: ", CharArrayToString(result));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Simple URL encoding for Telegram                                 |
//+------------------------------------------------------------------+
string UrlEncode(string text)
{
   string result = "";
   int len = StringLen(text);
   
   for(int i = 0; i < len; i++)
   {
      ushort ch = StringGetCharacter(text, i);
      
      if((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || 
         (ch >= '0' && ch <= '9') || ch == '-' || ch == '_' || ch == '.' || ch == '~')
      {
         result += CharToString((uchar)ch);
      }
      else if(ch == ' ')
      {
         result += "+";
      }
      else
      {
         result += StringFormat("%%%02X", ch);
      }
   }
   return result;
}

//+------------------------------------------------------------------+
//| Format trade notification message                                |
//+------------------------------------------------------------------+
string FormatTradeMessage(string action, string symbol, string direction, 
                           double lots, double price, double sl, double tp)
{
   string emoji = (direction == "BUY") ? "🟢" : "🔴";
   string msg = "";
   
   msg += "<b>" + emoji + " " + action + "</b>\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "📊 <b>Symbol:</b> " + symbol + "\n";
   msg += "📈 <b>Direction:</b> " + direction + "\n";
   msg += "📦 <b>Lots:</b> " + DoubleToString(lots, 2) + "\n";
   msg += "💰 <b>Price:</b> " + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "\n";
   
   if(sl > 0)
      msg += "🛑 <b>SL:</b> " + DoubleToString(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "\n";
   if(tp > 0)
      msg += "🎯 <b>TP:</b> " + DoubleToString(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "\n";
   
   msg += "━━━━━━━━━━━━━━\n";
   msg += "🤖 <i>AutoTraderBot</i> | " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   
   return msg;
}

//+------------------------------------------------------------------+
//| Format close position message                                    |
//+------------------------------------------------------------------+
string FormatCloseMessage(string symbol, string direction, double lots, 
                           double openPrice, double closePrice, double profit)
{
   string emoji = (profit >= 0) ? "✅" : "❌";
   string msg = "";
   
   msg += "<b>" + emoji + " POSITION CLOSED</b>\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "📊 <b>Symbol:</b> " + symbol + "\n";
   msg += "📈 <b>Direction:</b> " + direction + "\n";
   msg += "📦 <b>Lots:</b> " + DoubleToString(lots, 2) + "\n";
   msg += "💰 <b>Open:</b> " + DoubleToString(openPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "\n";
   msg += "💰 <b>Close:</b> " + DoubleToString(closePrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "\n";
   msg += "💵 <b>Profit:</b> $" + DoubleToString(profit, 2) + "\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "🤖 <i>AutoTraderBot</i> | " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   
   return msg;
}

//+------------------------------------------------------------------+
//| Format daily summary message                                     |
//+------------------------------------------------------------------+
string FormatDailySummary(int magicNumber)
{
   CAccountInfo account;
   
   double balance = account.Balance();
   double equity  = account.Equity();
   double dailyPnL = GetDailyPnL();
   double floatingPnL = GetFloatingPnL(magicNumber);
   int openOrders = CountAllPositions(magicNumber);
   
   string emoji = (dailyPnL >= 0) ? "📈" : "📉";
   string msg = "";
   
   msg += "<b>" + emoji + " DAILY SUMMARY</b>\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "💰 <b>Balance:</b> $" + DoubleToString(balance, 2) + "\n";
   msg += "💎 <b>Equity:</b> $" + DoubleToString(equity, 2) + "\n";
   msg += "📊 <b>Daily P/L:</b> $" + DoubleToString(dailyPnL, 2) + "\n";
   msg += "📋 <b>Floating:</b> $" + DoubleToString(floatingPnL, 2) + "\n";
   msg += "📂 <b>Open Orders:</b> " + IntegerToString(openOrders) + "\n";
   msg += "📉 <b>Drawdown:</b> " + DoubleToString(GetDrawdownPercent(), 1) + "%\n";
   msg += "━━━━━━━━━━━━━━\n";
   msg += "🤖 <i>AutoTraderBot</i> | " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   
   return msg;
}

//+------------------------------------------------------------------+
//| Send all notifications (Push + Email + Sound + Telegram)         |
//+------------------------------------------------------------------+
void SendNotification_Entry(string symbol, string direction, double lots, 
                             double price, double sl, double tp)
{
   string alertMsg = "AutoTraderBot: " + direction + " " + symbol + 
                     " Lots=" + DoubleToString(lots, 2) + 
                     " Price=" + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   
   // Sound
   if(InpUseSound)
      PlaySound(InpSoundFile);
   
   // Push notification
   if(InpUsePush)
      SendNotification(alertMsg);
   
   // Email
   if(InpUseEmail)
      SendMail("AutoTraderBot - " + direction + " " + symbol, alertMsg);
   
   // Telegram
   if(InpUseTelegram && InpTgNotifyEntry)
   {
      string tgMsg = FormatTradeMessage("NEW ORDER", symbol, direction, lots, price, sl, tp);
      SendTelegram(tgMsg);
   }
}

//+------------------------------------------------------------------+
//| Send close notifications                                         |
//+------------------------------------------------------------------+
void SendNotification_Exit(string symbol, string direction, double lots, 
                            double openPrice, double closePrice, double profit)
{
   string alertMsg = "AutoTraderBot: CLOSED " + direction + " " + symbol + 
                     " Profit=$" + DoubleToString(profit, 2);
   
   if(InpUseSound)
      PlaySound(InpSoundFile);
   
   if(InpUsePush)
      SendNotification(alertMsg);
   
   if(InpUseEmail)
      SendMail("AutoTraderBot - CLOSED " + symbol, alertMsg);
   
   if(InpUseTelegram && InpTgNotifyExit)
   {
      string tgMsg = FormatCloseMessage(symbol, direction, lots, openPrice, closePrice, profit);
      SendTelegram(tgMsg);
   }
}

//+------------------------------------------------------------------+
//| Send daily summary (call once per day)                           |
//+------------------------------------------------------------------+
datetime g_lastDailySummary = 0;

void CheckDailySummary(int magicNumber)
{
   if(!InpUseTelegram || !InpTgNotifyDaily) return;
   
   MqlDateTime dt;
   TimeCurrent(dt);
   
   // Send summary at 23:55 server time
   if(dt.hour == 23 && dt.min >= 55)
   {
      datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
      if(today > g_lastDailySummary)
      {
         g_lastDailySummary = today;
         string msg = FormatDailySummary(magicNumber);
         SendTelegram(msg);
      }
   }
}

//+------------------------------------------------------------------+
//| Check time filter                                                |
//+------------------------------------------------------------------+
bool IsTimeAllowed()
{
   if(!InpUseTimeFilter) return true;
   
   MqlDateTime dt;
   TimeCurrent(dt);
   
   // Check day of week
   switch(dt.day_of_week)
   {
      case 1: if(!InpTradeMonday)    return false; break;
      case 2: if(!InpTradeTuesday)   return false; break;
      case 3: if(!InpTradeWednesday) return false; break;
      case 4: if(!InpTradeThursday)  return false; break;
      case 5: if(!InpTradeFriday)    return false; break;
      default: return false; // Saturday/Sunday
   }
   
   // Check hour range
   if(InpStartHour < InpEndHour)
   {
      // Normal range (e.g., 8-20)
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
         return false;
   }
   else if(InpStartHour > InpEndHour)
   {
      // Overnight range (e.g., 22-6)
      if(dt.hour < InpStartHour && dt.hour >= InpEndHour)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check spread filter                                              |
//+------------------------------------------------------------------+
bool IsSpreadAllowed(string symbol)
{
   if(InpMaxSpread <= 0) return true;
   
   double spread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   
   if(spread > InpMaxSpread)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get strategy name as string                                      |
//+------------------------------------------------------------------+
string GetStrategyName()
{
   switch(InpStrategy)
   {
      case STRATEGY_TREND_FOLLOWING: return "Trend Following";
      case STRATEGY_SCALPING:        return "Scalping";
      case STRATEGY_BREAKOUT:        return "Breakout";
      case STRATEGY_MEAN_REVERSION:  return "Mean Reversion";
      case STRATEGY_GRID:            return "Grid";
      case STRATEGY_CUSTOM:
      {
         switch(InpCustomSignal)
         {
            case CUSTOM_MA_RSI:     return "Custom: MA+RSI";
            case CUSTOM_MACD_BB:    return "Custom: MACD+BB";
            case CUSTOM_ADX_STOCH:  return "Custom: ADX+Stoch";
            case CUSTOM_ICHIMOKU:   return "Custom: Ichimoku";
            case CUSTOM_MULTI_TF:   return "Custom: Multi-TF";
            default:                return "Custom";
         }
      }
      default: return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Log message with timestamp                                       |
//+------------------------------------------------------------------+
void LogMessage(string msg)
{
   Print("[AutoTraderBot] ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), " | ", msg);
}
