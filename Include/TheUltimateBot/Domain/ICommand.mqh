//+------------------------------------------------------------------+
//|                                                     ICommand.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

// Interface para qualquer ação que o robô queira tomar (Ordem, Log, Modificação)
class ICommand {
public:
   virtual ~ICommand() {}
   
   // O método que faz a mágica acontecer
   virtual void Execute() = 0;
};
//+------------------------------------------------------------------+