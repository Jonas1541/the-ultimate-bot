//+------------------------------------------------------------------+
//|                                                      ILogger.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class ILogger {
public:
   virtual ~ILogger() {}
   
   virtual void Log(string message) = 0;
   virtual void Error(string message) = 0;
};
//+------------------------------------------------------------------+
