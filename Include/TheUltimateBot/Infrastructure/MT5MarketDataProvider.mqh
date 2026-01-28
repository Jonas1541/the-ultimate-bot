//+------------------------------------------------------------------+
//|                                        MT5MarketDataProvider.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/IMarketDataProvider.mqh>

class MT5MarketDataProvider : public IMarketDataProvider {
public:
   MT5MarketDataProvider() {}
   ~MT5MarketDataProvider() {}
   
   // --- IMPLEMENTAÇÃO WINE-SAFE (Carrega -> Copia -> Libera) ---
   
   double GetEMA(string symbol, ENUM_TIMEFRAMES tf, int period, int shift) override {
      // 1. Cria o Handle
      int handle = iMA(symbol, tf, period, 0, MODE_EMA, PRICE_CLOSE);
      if(handle == INVALID_HANDLE) return 0.0;

      // 2. Prepara buffer
      double buffer[];
      ArraySetAsSeries(buffer, true); 

      // 3. Copia dados
      if(CopyBuffer(handle, 0, shift, 1, buffer) < 1) {
         IndicatorRelease(handle); // Libera em caso de erro
         return 0.0;
      }

      double result = buffer[0];

      // 4. Libera Handle IMEDIATAMENTE (Crítico para Linux/Wine com muitos indicadores)
      IndicatorRelease(handle);
      
      return result;
   }
   
   int GetRates(string symbol, ENUM_TIMEFRAMES tf, int count, MqlRates &rates[]) override {
      ArraySetAsSeries(rates, true);
      return CopyRates(symbol, tf, 0, count, rates);
   }
};
//+------------------------------------------------------------------+
