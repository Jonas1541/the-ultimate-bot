//+------------------------------------------------------------------+
//|                                                   FileLogger.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

#include "ILogger.mqh"

class FileLogger : public ILogger {
private:
   int m_fileHandle;
   string m_fileName;

   void WriteLine(string level, string msg) {
      if(m_fileHandle == INVALID_HANDLE) return;
      
      string time = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
      string line = StringFormat("[%s] [%s] %s", time, level, msg);
      
      FileWrite(m_fileHandle, line);
      FileFlush(m_fileHandle); // Importante para não perder dados se crashar
   }

public:
   FileLogger() {
      // Cria nome do arquivo baseado no dia: TheUltimateBot/Logs/Log_20260127.txt
      string date = TimeToString(TimeCurrent(), TIME_DATE);
      StringReplace(date, ".", ""); // remove pontos
      
      // Cria diretório se não existir (Requer flag FILE_COMMON se fosse fora da sandbox, mas aqui é na Sandbox do Terminal)
      // MQL5 não cria diretórios recursivamente com FileOpen simples, então salvamos na raiz ou pasta Logs se ja existir.
      // Assumindo estrutura simples:
      m_fileName = StringFormat("TheUltimateBot_Log_%s.txt", date);
      
      // Tenta abrir ou criar (APPEND)
      m_fileHandle = FileOpen(m_fileName, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE);
      
      if(m_fileHandle != INVALID_HANDLE) {
         FileSeek(m_fileHandle, 0, SEEK_END);
         WriteLine("SYS", ">>> LOGGER INITIATED <<<");
      } else {
         Print("!!! CRITICAL: Failed to open log file: ", m_fileName);
      }
   }

   ~FileLogger() {
      if(m_fileHandle != INVALID_HANDLE) {
         WriteLine("SYS", ">>> LOGGER SHUTDOWN <<<");
         FileClose(m_fileHandle);
      }
   }

   void Log(string message) override {
      Print(message); // Mantém output no terminal
      WriteLine("INFO", message);
   }

   void Error(string message) override {
      Print("!!! ERROR: ", message);
      WriteLine("ERROR", message);
   }
};
//+------------------------------------------------------------------+
