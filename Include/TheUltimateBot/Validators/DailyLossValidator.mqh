//+------------------------------------------------------------------+
//|                                           DailyLossValidator.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/IValidator.mqh"
#include "../Core/SessionContext.mqh"

class DailyLossValidator : public IValidator {
private:
   SessionContext* m_session; // Dependência do Contexto
   double          m_maxLoss; // Limite de Perda (Valor Positivo, ex: 50.0)

public:
   DailyLossValidator(SessionContext* session, double maxLoss) {
      m_session = session;
      m_maxLoss = maxLoss; // Ex: Se passar 50.0, significa que para em -50.0
   }

   bool Validate(string &message) override {
      // Pega o lucro atual (pode ser negativo)
      double currentPL = m_session.GetDailyProfit();

      // Se o prejuízo for maior que o limite (Ex: -60 < -50)
      if(currentPL <= -m_maxLoss) {
         message = StringFormat("DAILY LOSS LIMIT REACHED! (P/L: %.2f | Limit: -%.2f)", currentPL, m_maxLoss);
         return false; // BLOQUEIA
      }

      return true; // LIBERA
   }
};
//+------------------------------------------------------------------+