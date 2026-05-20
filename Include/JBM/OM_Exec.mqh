//+------------------------------------------------------------------+
//|  OM_Exec.mqh — Order Execution Engine                            |
//|  Handles: Market, Limit, Stop orders with TP/SL via CTrade       |
//+------------------------------------------------------------------+
#ifndef OM_EXEC_MQH
#define OM_EXEC_MQH
#include <Trade/Trade.mqh>

class COrderExec
  {
private:
   CTrade   m_trade;
   string   m_symbol;

public:
   COrderExec()
     {
      m_trade.SetExpertMagicNumber(20260520);
      m_trade.SetDeviationInPoints(10);
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
      m_trade.LogLevel(LOG_LEVEL_ERRORS);
     }

   void SetSymbol(string symbol) { m_symbol = symbol; }

   //--- Market Order
   bool PlaceMarket(bool isBuy, double lots, double sl, double tp, string comment = "JBM-OM")
     {
      bool result;
      if(isBuy)
         result = m_trade.Buy(lots, m_symbol, 0, sl, tp, comment);
      else
         result = m_trade.Sell(lots, m_symbol, 0, sl, tp, comment);

      if(!result)
         Print("Market order failed: ", m_trade.ResultRetcodeDescription());
      return result;
     }

   //--- Limit Order
   bool PlaceLimit(bool isBuy, double lots, double price, double sl, double tp,
                   datetime expiry = 0, string comment = "JBM-OM")
     {
      ENUM_ORDER_TYPE type = isBuy ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
      bool result = m_trade.OrderOpen(m_symbol, type, lots, 0, price, sl, tp,
                                      expiry > 0 ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC,
                                      expiry, comment);
      if(!result)
         Print("Limit order failed: ", m_trade.ResultRetcodeDescription());
      return result;
     }

   //--- Stop Order
   bool PlaceStop(bool isBuy, double lots, double price, double sl, double tp,
                  datetime expiry = 0, string comment = "JBM-OM")
     {
      ENUM_ORDER_TYPE type = isBuy ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP;
      bool result = m_trade.OrderOpen(m_symbol, type, lots, 0, price, sl, tp,
                                      expiry > 0 ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC,
                                      expiry, comment);
      if(!result)
         Print("Stop order failed: ", m_trade.ResultRetcodeDescription());
      return result;
     }

   //--- Time in Force helper
   datetime GetExpiry(string tif)
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);

      if(tif == "Day")
        { dt.hour = 23; dt.min = 59; dt.sec = 59; return StructToTime(dt); }
      if(tif == "Week")
        { return TimeCurrent() + (7 - dt.day_of_week) * 86400; }
      if(tif == "Month")
        { dt.day = 28; dt.hour = 23; dt.min = 59; dt.sec = 59; return StructToTime(dt); }
      return 0; // GTC
     }

   string GetLastError() { return m_trade.ResultRetcodeDescription(); }
   uint   GetLastRetcode() { return m_trade.ResultRetcode(); }
  };

#endif // OM_EXEC_MQH
