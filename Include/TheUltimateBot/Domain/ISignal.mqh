//+------------------------------------------------------------------+
//|                                                      ISignal.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "MarketState.mqh"
#include "ICommand.mqh"

// Interface Base para todas as estratégias
class ISignal {
public:
   // Destrutor virtual é obrigatório em MQL5/C++ para interfaces
   virtual ~ISignal() {}

   // --- O CORAÇÃO DO SISTEMA (SCORING) ---
   // Recebe o contexto e retorna uma nota de 0.0 a 1.0
   virtual double GetScore(MarketState &state) = 0;

   virtual ICommand* Tick(MarketState &state) = 0; 
   
   // Identificação (para logs)
   virtual string GetName() = 0;
};
//+------------------------------------------------------------------+