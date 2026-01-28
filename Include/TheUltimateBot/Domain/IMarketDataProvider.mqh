//+------------------------------------------------------------------+
//|                                          IMarketDataProvider.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

// Interface para abstrair o acesso a dados de mercado (Indicadores e Preço)
// Útil para Mocking em testes e para isolar a lógica "Wine-Safe"
class IMarketDataProvider {
public:
   virtual ~IMarketDataProvider() {}
   
   // Retorna o valor de uma EMA (Exponential Moving Average)
   // Retorna 0.0 em caso de erro
   virtual double GetEMA(string symbol, ENUM_TIMEFRAMES tf, int period, int shift) = 0;
   
   // Preenche um array com os últimos N rates (velas)
   // Retorna a quantidade copiada
   virtual int GetRates(string symbol, ENUM_TIMEFRAMES tf, int count, MqlRates &rates[]) = 0;
};
//+------------------------------------------------------------------+
