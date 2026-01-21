//+------------------------------------------------------------------+
//|                                            CommandInvoker.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "../Domain/ICommand.mqh"

class CommandInvoker {
public:
   CommandInvoker() {
      Print(">>> [CORE] Command Invoker ready.");
   }
   
   ~CommandInvoker() {}

   // Recebe o comando, executa e limpa a memória
   void Execute(ICommand* command) {
      if(command == NULL) return;

      // 1. Executa a ação (Chama a Bridge internamente)
      command.Execute();
      
      // 2. O comando já cumpriu seu propósito, podemos descartar
      // Isso evita vazamento de memória (Memory Leak)
      delete command;
   }
};
//+------------------------------------------------------------------+