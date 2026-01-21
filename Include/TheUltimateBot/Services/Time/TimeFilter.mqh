//+------------------------------------------------------------------+
//|                                                   TimeFilter.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class TimeFilter {
private:
   int m_startHour;
   int m_startMinute;
   int m_endHour;
   int m_endMinute;

public:
   TimeFilter(int startH, int startM, int endH, int endM) {
      m_startHour = startH;
      m_startMinute = startM;
      m_endHour = endH;
      m_endMinute = endM;
   }

   // Retorna TRUE se estiver dentro do horário permitido
   bool IsTradingTime(datetime serverTime) {
      MqlDateTime dt;
      TimeToStruct(serverTime, dt); // Converte timestamp para struct (hora, min, dia)

      // Converte tudo para "Minutos do Dia" para facilitar comparação
      // Ex: 09:30 = 9*60 + 30 = 570
      int currentMinutes = dt.hour * 60 + dt.min;
      int startMinutes = m_startHour * 60 + m_startMinute;
      int endMinutes = m_endHour * 60 + m_endMinute;

      if(currentMinutes >= startMinutes && currentMinutes < endMinutes) {
         return true;
      }
      
      return false;
   }
   
   string ToString() {
      return StringFormat("%02d:%02d - %02d:%02d", m_startHour, m_startMinute, m_endHour, m_endMinute);
   }
};
//+------------------------------------------------------------------+