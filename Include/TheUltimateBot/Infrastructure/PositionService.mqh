//+------------------------------------------------------------------+
//|                                           PositionService.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include <Trade/PositionInfo.mqh>

class PositionService {
private:
   CPositionInfo  m_position;    // Wrapper oficial do MT5
   ulong          m_magicNumber; // ID do nosso robô

   // Singleton Pattern (Mesma lógica da Bridge)
   static PositionService *s_instance;
   
   PositionService() {
      m_magicNumber = 123456; // Tem que bater com o da Bridge!
   }

public:
   ~PositionService() {
      if(CheckPointer(s_instance) == POINTER_DYNAMIC) delete s_instance;
      s_instance = NULL;
   }

   static PositionService* Get() {
      if(s_instance == NULL) s_instance = new PositionService();
      return s_instance;
   }

   // --- MÉTODOS DE CONSULTA ---

   // Retorna TRUE se já existir uma posição aberta para este símbolo e magic number
   bool HasOpenPosition(string symbol) {
      // Loop por todas as posições abertas na conta
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         // Seleciona a posição para ler os dados
         if(m_position.SelectByIndex(i)) {
            // Verifica se é do nosso robô e do nosso par
            if(m_position.Symbol() == symbol && m_position.Magic() == m_magicNumber) {
               return true;
            }
         }
      }
      return false;
   }

   // Retorna o tipo da posição atual (POSITION_TYPE_BUY ou SELL)
   // Retorna -1 se não tiver posição
   ENUM_POSITION_TYPE GetPositionType(string symbol) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(m_position.SelectByIndex(i)) {
            if(m_position.Symbol() == symbol && m_position.Magic() == m_magicNumber) {
               return m_position.PositionType();
            }
         }
      }
      return (ENUM_POSITION_TYPE)-1; 
   }

   // Preenche um array com os tickets abertos deste robô
   void GetOpenTickets(ulong &tickets[]) {
      ArrayResize(tickets, 0); 
      
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(m_position.SelectByIndex(i)) {
            if(m_position.Magic() == m_magicNumber) { // Filtra apenas as nossas
               int size = ArraySize(tickets);
               ArrayResize(tickets, size + 1);
               tickets[size] = m_position.Ticket();
            }
         }
      }
   }
};

PositionService *PositionService::s_instance = NULL;
//+------------------------------------------------------------------+