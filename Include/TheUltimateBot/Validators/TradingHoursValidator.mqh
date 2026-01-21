//+------------------------------------------------------------------+
//|                                    TradingHoursValidator.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/IValidator.mqh"
#include "../Services/Time/TimeFilter.mqh"

class TradingHoursValidator : public IValidator {
private:
   TimeFilter* m_timeService; // Usa o serviço existente

public:
   TradingHoursValidator(TimeFilter* service) {
      m_timeService = service;
   }

   bool Validate(string &message) override {
      if(!m_timeService.IsTradingTime(TimeCurrent())) {
         message = "Outside Trading Hours: " + m_timeService.ToString();
         return false; // BLOQUEIA
      }
      return true; // LIBERA
   }
};
//+------------------------------------------------------------------+