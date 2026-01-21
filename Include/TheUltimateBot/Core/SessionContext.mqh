//+------------------------------------------------------------------+
//|                                           SessionContext.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <Trade/DealInfo.mqh>

class SessionContext {
private:
   double   m_initialBalance;    // Saldo no início do dia
   double   m_currentProfit;     // Lucro Liquido acumulado hoje
   int      m_lastDayOfYear;     // Para detectar virada de dia
   
   CDealInfo m_deal;             // Biblioteca padrão para ler histórico

public:
   SessionContext() {
      m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_lastDayOfYear = DayOfYear(TimeCurrent());
      m_currentProfit = 0.0;
   }

   // Chamado pelo Kernel a cada tick para manter os números atualizados
   void Update() {
      datetime now = TimeCurrent();
      int currentDay = DayOfYear(now);

      // 1. Virada de Dia: Reseta tudo
      if(currentDay != m_lastDayOfYear) {
         Print(">>> [SESSION] Novo dia detectado. Resetando contadores.");
         m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         m_currentProfit = 0.0;
         m_lastDayOfYear = currentDay;
         return;
      }

      // 2. Calcula Lucro do Dia
      // Estratégia simples: Saldo Atual (Equity) - Saldo Inicial
      // Nota: Usamos Equity para considerar flutuação de ordens abertas (Stop Móvel)
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      m_currentProfit = currentEquity - m_initialBalance;
   }

   // --- Getters ---
   double GetDailyProfit() { return m_currentProfit; }
   double GetInitialBalance() { return m_initialBalance; }
   
   // Retorna string formatada para logs
   string ToString() {
      return StringFormat("Daily P/L: %.2f", m_currentProfit);
   }
   
   // Método auxiliar para pegar dia do ano
   int DayOfYear(datetime date) {
      MqlDateTime dt;
      TimeToStruct(date, dt);
      return dt.day_of_year;
   }
};
//+------------------------------------------------------------------+