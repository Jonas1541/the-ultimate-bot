//+------------------------------------------------------------------+
//|                                                    MT5Bridge.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

// Aqui sim importamos a biblioteca de Trade oficial
#include <Trade/Trade.mqh>

class MT5Bridge {
private:
   CTrade   m_trade;       // O objeto oficial que envia ordens
   ulong    m_magicNumber; // O RG do robô (para não mexer em ordens manuais)
   
   // --- SINGLETON PATTERN ---
   // Construtor privado: Ninguém pode dar "new MT5Bridge" fora daqui
   MT5Bridge() {
      m_magicNumber = 123456; // Defina um ID único pro seu robô
      m_trade.SetExpertMagicNumber(m_magicNumber);
      m_trade.SetMarginMode();
      m_trade.SetTypeFillingBySymbol(_Symbol); // Auto-detecta (FOK/IOC)
   }
   
   // A única instância estática que existirá na memória
   static MT5Bridge *s_instance;

public:
   // Destrutor
   ~MT5Bridge() {
      if(CheckPointer(s_instance) == POINTER_DYNAMIC) {
         delete s_instance;
         s_instance = NULL;
      }
   }

   // Método Estático para pegar a instância única (Global Access Point)
   static MT5Bridge* Get() {
      if(s_instance == NULL) {
         s_instance = new MT5Bridge();
      }
      return s_instance;
   }

   // --- MÉTODOS DE NEGOCIAÇÃO ---

   // Envia uma requisição crua (vinda do Command)
   bool SendRawRequest(MqlTradeRequest &request, MqlTradeResult &result) {
      // Garante que o Magic Number é o nosso
      request.magic = m_magicNumber;
      
      // Envia para a corretora
      bool success = m_trade.OrderSend(request, result);
      
      if(!success) {
         PrintFormat("!!! ERRO DE EXECUÇÃO: %s (Retcode: %d)", m_trade.ResultComment(), result.retcode);
      } else {
         PrintFormat(">>> SUCESSO: Ordem enviada! Ticket: %d", result.order);
      }
      
      return success;
   }
   
   // Fecha uma posição específica pelo Ticket
   bool ClosePosition(ulong ticket) {
      if(!m_trade.PositionClose(ticket)) {
         PrintFormat("!!! ERRO AO FECHAR POSIÇÃO %d: %s", ticket, m_trade.ResultComment());
         return false;
      }
      PrintFormat(">>> SUCESSO: Posição %d fechada.", ticket);
      return true;
   }
   
   // Configurações extras
   void SetMagicNumber(ulong magic) {
      m_magicNumber = magic;
      m_trade.SetExpertMagicNumber(magic);
   }
};

// Inicialização da variável estática (Obrigatório em C++)
MT5Bridge *MT5Bridge::s_instance = NULL;
//+------------------------------------------------------------------+