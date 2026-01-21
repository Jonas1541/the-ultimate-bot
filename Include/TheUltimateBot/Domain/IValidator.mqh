//+------------------------------------------------------------------+
//|                                               IValidator.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class IValidator {
public:
   virtual ~IValidator() {}

   // Retorna TRUE se for seguro operar.
   // Se retornar FALSE, preenche a string 'message' com o motivo.
   virtual bool Validate(string &message) = 0;
};
//+------------------------------------------------------------------+