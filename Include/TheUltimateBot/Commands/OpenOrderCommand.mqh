//+------------------------------------------------------------------+
//|                                             OpenOrderCommand.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/ICommand.mqh"

class OpenOrderCommand : public ICommand {
private:
   MqlTradeRequest m_request; // Struct nativa do MT5 que guarda os dados da ordem

public:
   // --- Construtor: A estratégia preenche isso ---
   OpenOrderCommand(string symbol, ENUM_ORDER_TYPE type, double volume, double price, double sl, double tp, string comment) {
      ZeroMemory(m_request);
      
      m_request.action = TRADE_ACTION_DEAL;
      m_request.symbol = symbol;
      m_request.volume = volume;
      m_request.type = type;
      m_request.price = price;
      m_request.sl = sl;
      m_request.tp = tp;
      m_request.comment = comment;
      m_request.type_filling = ORDER_FILLING_FOK; // Fill or Kill (B3 padrão)
   }

   // --- Execução ---
   void Execute() override {
      // Futuro: Aqui chamaremos this.bridge.SendOrder(m_request);
      // Por enquanto, apenas logamos a intenção
      PrintFormat(">>> COMMAND EXEC: %s %s Vol: %.2f Price: %.2f SL: %.2f TP: %.2f",
         (m_request.type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
         m_request.symbol,
         m_request.volume,
         m_request.price,
         m_request.sl,
         m_request.tp
      );
   }
};
//+------------------------------------------------------------------+