//+------------------------------------------------------------------+
//|                                                      ISignal.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "MarketState.mqh"
#include "ICommand.mqh"
#include "IValidator.mqh" // Novo Include

// Agora é uma Classe Abstrata com funcionalidade de Validação
class ISignal {
protected:
   // Lista de Filtros (Chain of Responsibility)
   IValidator* m_validators[];

public:
   virtual ~ISignal() {
      // Nota: Não deletamos os validadores aqui pois eles podem ser 
      // compartilhados entre várias estratégias (Depende da implementação do Main)
      ArrayFree(m_validators);
   }

   // --- MÉTODOS ABSTRATOS (A estratégia DEVE implementar) ---
   virtual double GetScore(MarketState &state) = 0;
   virtual ICommand* Tick(MarketState &state) = 0; 
   virtual string GetName() = 0;

   // --- MÉTODOS CONCRETOS (A estratégia ganha de graça) ---
   
   // Adiciona um novo filtro na corrente
   void AddValidator(IValidator* validator) {
      int size = ArraySize(m_validators);
      ArrayResize(m_validators, size + 1);
      m_validators[size] = validator;
   }

   // Roda todos os filtros
   bool ValidateAll(string &failedReason) {
      int total = ArraySize(m_validators);
      for(int i=0; i<total; i++) {
         if(!m_validators[i].Validate(failedReason)) {
            return false; // Bloqueia se QUALQUER um falhar
         }
      }
      return true; // Passou em todos
   }
};
//+------------------------------------------------------------------+