//+------------------------------------------------------------------+
//|                                                  MarketState.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "Types.mqh"

class MarketState {
public:
   // --- Preços Atuais ---
   double            bid;
   double            ask;

   // --- Atributos do Contexto de Mercado ---
   ETrendState       trend;            
   EVolatilityState  volatility;       
   
   double            atrValue;         
   double            volumeProjection; 
   
   bool              isNewsEvent;      
   datetime          serverTime;       
   
   MarketState() {
      bid = 0.0;
      ask = 0.0;
      trend = TREND_NEUTRAL;
      volatility = VOL_NORMAL;
      atrValue = 0.0;
      volumeProjection = 1.0;
      isNewsEvent = false;
   }
   
   string ToString() {
      return StringFormat("Trend: %d | Vol: %d | Ask: %.2f", trend, volatility, ask);
   }
};
//+------------------------------------------------------------------+