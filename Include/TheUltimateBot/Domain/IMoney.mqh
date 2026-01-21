//+------------------------------------------------------------------+
//|                                                       IMoney.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class IMoney {
public:
   virtual ~IMoney() {}

   // Recebe: Preço de Entrada e Preço de Stop Loss
   // Retorna: Quantidade de Lotes para operar
   virtual double GetLotSize(double entryPrice, double stopLossPrice) = 0;
};
//+------------------------------------------------------------------+