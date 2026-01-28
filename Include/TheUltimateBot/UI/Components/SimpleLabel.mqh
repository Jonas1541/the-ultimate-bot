//+------------------------------------------------------------------+
//|                                              SimpleLabel.mqh |
//|                                  Copyright 2026, TheUltimateBot  |
//+------------------------------------------------------------------+
#property copyright "TheUltimateBot"
#property strict

class SimpleLabel {
private:
   string m_name;
public:
   SimpleLabel(string name, int x, int y, int fontSize, color clr, string font="Consolas") {
      m_name = "TheUltimateBot_Lbl_" + name;
      
      // FORÇA RECRIAÇÃO LIMPA (Corrige bug "Label")
      ObjectDelete(0, m_name); 
      ObjectCreate(0, m_name, OBJ_LABEL, 0, 0, 0);
      
      ObjectSetInteger(0, m_name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, m_name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, m_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, m_name, OBJPROP_FONT, font);
      ObjectSetInteger(0, m_name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, m_name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, m_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, m_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, m_name, OBJPROP_HIDDEN, true);
   }

   ~SimpleLabel() { ObjectDelete(0, m_name); }

   void SetText(string text) { ObjectSetString(0, m_name, OBJPROP_TEXT, text); }
   void SetColor(color clr) { ObjectSetInteger(0, m_name, OBJPROP_COLOR, clr); }
};
//+------------------------------------------------------------------+