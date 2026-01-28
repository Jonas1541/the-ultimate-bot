//+------------------------------------------------------------------+
//|                                         ClosePositionCommand.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/ICommand.mqh>
#include <TheUltimateBot/Infrastructure/MT5Bridge.mqh>

class ClosePositionCommand : public ICommand {
private:
   ulong m_ticket;

public:
   ClosePositionCommand(ulong ticket) {
      m_ticket = ticket;
   }

   void Execute() override {
      PrintFormat(">>> [CMD] Fechando Posição %d (PANIC/CLOSE)...", m_ticket);
      // Usa o método helper da Bridge
      MT5Bridge::Get().ClosePosition(m_ticket);
   }
};
//+------------------------------------------------------------------+
