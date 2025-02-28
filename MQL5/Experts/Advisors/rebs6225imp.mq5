//+------------------------------------------------------------------+
//|                       Price Impulse(barabashkakvn's edition).mq5 |
//|                                                            runik |
//|                                                  ngb2008@mail.ru |
//+------------------------------------------------------------------+
#property copyright "runik"
#property link      "ngb2008@mail.ru"
#property version   "1.000"
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//+------------------------------------------------------------------+
//| ENUM_TICK_FLAGS                                                  |
//+------------------------------------------------------------------+

enum ENUM_TICK_FLAGS
  {
   TICK_FLAGS_INFO=1,     // только Bid и Ask
   TICK_FLAGS_TRADE=2,    // только Last и Volume
   TICK_FLAGS_ALL=-1,     // все тики
  };
  
input ENUM_TICK_FLAGS tick_flags = TICK_FLAGS_INFO; // тики, вызванные изменениями Bid и/или Ask; ticks causados ​​por mudanças no Bid e/ou Ask

//--- input parameters
input double   InpLots           = 0.1;      // Lots
input ushort   InpStopLoss       = 150;      // Stop Loss
input ushort   InpTakeProfit     = 50;       // Take Profit
input int      InpPoints         = 15;       // цена должна пройти NNN пунктов
input int      InpTicks          = 15;       // за XXX тиков
input int      InpSleep          = 100;      // минимальная пауза между трейдами
//input uint DefaultTickCount      = 15; // Default tick count after a trade

//--- массивы для приема тиков matrizes para receber ticks
MqlTick        tick_array_curr[];            // массив тиков полученный на текущем тике;conjunto de ticks recebidos no tick atual
MqlTick        tick_array_prev[];            // массви тиков полученный на предыдущем тике; conjunto de ticks obtidos no tick anterior

ulong          tick_from = 1;                  // se o parâmetro tick_from=0, então os últimos tick_count ticks são retornados
uint           tick_count= 15;                // количество тиков, которые необходимо получить ; número de ticks a serem obtidos
//---
double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtPoints=0.0;
bool           first_start=false;
long           last_trade_time=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
/*int OnInit()
  {
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);

   tick_count+=InpTicks;               // будем запрашивать "tick_count" + "за XXX тиков"
   ExtStopLoss=InpStopLoss*Point();
   ExtTakeProfit=InpTakeProfit*Point();
   ExtPoints=InpPoints*Point();
   first_start=false;
//--- запросим тики (первое заполнение)
   int copied=CopyTicks(Symbol(),tick_array_curr,tick_flags,tick_from,tick_count);
   Print("hello: ", copied);
   if(copied!=tick_count)
      first_start=false;
   else
     {
      first_start=true;
      
      
      ArrayCopy(tick_array_prev,tick_array_curr);
     }Print("hello222: ", copied);
//---
   return(INIT_SUCCEEDED);
     

  }*/
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ResetTicks();
   
  }



void OnTick()
{
   //--- проверка на первый старт; primeira verificação de partida
   int copied=-1;
   if(!first_start)
      {
      copied=CopyTicks(Symbol(), tick_array_curr, tick_flags, tick_from, tick_count);
      if (copied != tick_count)
         first_start=false;
      else
      {
         first_start=true;
         ArrayCopy(tick_array_prev, tick_array_curr);
      }
   }
//--- запросим тики; vamos convidar tiques
   copied=CopyTicks(Symbol(),tick_array_curr,tick_flags,tick_from,tick_count);
   Print("copied: ", copied);
   Print("tickK: ", tick_count);
   Print("tickFrom: ", tick_from);


   
   if (copied!=tick_count)
      return;

   int index_new=-1;
   long last_time_msc = tick_array_prev[tick_count - 1].time_msc;
   for(int i=(int)tick_count-1;i>=0;i--)
   {
      if(last_time_msc == tick_array_curr[i].time_msc)
        {
         index_new=i;
         break;
      }
   }

   if (index_new != -1 && tick_array_curr[tick_count - 1].time_msc - last_trade_time > InpSleep * 1000)
   {
      int shift = (int)tick_count - 1 - index_new - InpTicks; // смещение в текущем масиве тиков
      shift = (shift < 0) ? 0 : shift;
      if (tick_array_curr[tick_count - 1].ask - tick_array_curr[shift].ask > ExtPoints)
      {  int d=0;
      
      //Print("tickK: ", d);
         //--- открываем BUY
         double sl = (InpStopLoss == 0) ? 0.0 : tick_array_curr[tick_count - 1].ask - ExtStopLoss;
         double tp = (InpTakeProfit == 0) ? 0.0 : tick_array_curr[tick_count - 1].ask + ExtTakeProfit;
         m_trade.Buy(InpLots, m_symbol.Name(), tick_array_curr[tick_count - 1].ask,
                         m_symbol.NormalizePrice(sl),
                         m_symbol.NormalizePrice(tp));
         {
            last_trade_time=tick_array_curr[tick_count-1].time_msc;
            //ResetTicks(); // Reset ticks after a trade
           copied = d ;
           //Print("copieeed: ", copied);
           
         }
      }     
         else if(tick_array_curr[shift].bid-tick_array_curr[tick_count-1].bid>ExtPoints)
        {
         int d=0;
         //--- открываем SELL
         double sl=(InpStopLoss==0)?0.0:tick_array_curr[tick_count-1].bid+ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:tick_array_curr[tick_count-1].bid-ExtTakeProfit;
         m_trade.Sell(InpLots,m_symbol.Name(),tick_array_curr[tick_count-1].bid,
                      m_symbol.NormalizePrice(sl),
                      m_symbol.NormalizePrice(tp));
           last_trade_time=tick_array_curr[tick_count-1].time_msc;           
         }
      }

   ArrayCopy(tick_array_prev, tick_array_curr);
	 
}

 //Function to reset tick arrays and tick count
void ResetTicks()
{
   
   ArrayResize(tick_array_curr, 0);
   ArrayResize(tick_array_prev, 0);
   first_start = false; // Reset first_start to ensure fresh start
}


//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

  }


