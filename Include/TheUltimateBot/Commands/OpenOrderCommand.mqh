//+------------------------------------------------------------------+
//|                                             OpenOrderCommand.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <TheUltimateBot/Domain/ICommand.mqh>
#include <TheUltimateBot/Infrastructure/MT5Bridge.mqh> 

class OpenOrderCommand : public ICommand {
private:
   MqlTradeRequest m_request; 

public:
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
      
      // Importante para B3: Preenchimento
      m_request.type_filling = ORDER_FILLING_RETURN; 
   }

   void Execute() override {
      // Struct para receber a resposta da corretora
      MqlTradeResult result;
      ZeroMemory(result);

      PrintFormat(">>> [CMD] Enviando ordem %s...", m_request.symbol);

      // Chamamos o Singleton da Bridge para disparar a ordem
      MT5Bridge::Get().SendRawRequest(m_request, result);
   }
};
//+------------------------------------------------------------------+