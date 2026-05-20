//+------------------------------------------------------------------+
//|  OM_Calc.mqh — Calculation Engine                                |
//|  Handles: pip value, lot sizing, margin, trade value, P&L        |
//+------------------------------------------------------------------+
#ifndef OM_CALC_MQH
#define OM_CALC_MQH

class COrderCalc
  {
private:
   double   m_defaultRisk;    // % of balance
   string   m_symbol;

public:
   COrderCalc() : m_defaultRisk(1.0) {}

   void SetDefaultRisk(double riskPct) { m_defaultRisk = riskPct; }
   void SetSymbol(string symbol)       { m_symbol = symbol; }

   //--- Pip size (0.0001 for forex, 0.01 for JPY pairs, etc.)
   double GetPipSize()
     {
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      return (digits == 3 || digits == 5) ? point * 10 : point;
     }

   //--- Pip value in account currency (universal formula)
   double GetPipValue(double lots = 1.0)
     {
      double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double pipSize   = GetPipSize();
      // tickValue is already per 1 lot — no need to multiply by contract size
      // Verified: AUDUSD 10 lots → 1.0 * (0.0001/0.00001) * 10 = 100 USD ✓
      return tickValue * (pipSize / tickSize) * lots;
     }

   //--- Trade value (notional)
   double GetTradeValue(double lots, double price)
     {
      double contractSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      return lots * contractSize * price;
     }

   //--- Margin required for a position
   double GetMarginRequired(ENUM_ORDER_TYPE orderType, double lots, double price)
     {
      double margin = 0;
      OrderCalcMargin(orderType, m_symbol, lots, price, margin);
      return margin;
     }

   //--- Auto lot from risk % (requires SL in pips)
   double GetLotFromRiskPct(double riskPct, double slPips, double price)
     {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskAmt   = balance * riskPct / 100.0;
      double pipVal    = GetPipValue(1.0);   // per 1 lot
      if(pipVal <= 0 || slPips <= 0) return 0;
      double lots = riskAmt / (slPips * pipVal);
      return NormalizeLots(lots);
     }

   //--- Auto lot from risk USD
   double GetLotFromRiskUSD(double riskUSD, double slPips)
     {
      double pipVal = GetPipValue(1.0);
      if(pipVal <= 0 || slPips <= 0) return 0;
      return NormalizeLots(riskUSD / (slPips * pipVal));
     }

   //--- Auto lot from margin USD
   double GetLotFromMarginUSD(double marginUSD, ENUM_ORDER_TYPE orderType, double price)
     {
      double marginPer1Lot = 0;
      OrderCalcMargin(orderType, m_symbol, 1.0, price, marginPer1Lot);
      if(marginPer1Lot <= 0) return 0;
      return NormalizeLots(marginUSD / marginPer1Lot);
     }

   //--- Auto lot from % balance (of full balance as margin)
   double GetLotFromBalancePct(double pct, ENUM_ORDER_TYPE orderType, double price)
     {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double marginUSD = balance * pct / 100.0;
      return GetLotFromMarginUSD(marginUSD, orderType, price);
     }

   //--- Distance from entry to price in pips
   double PriceToPips(double entry, double targetPrice)
     {
      return MathAbs(entry - targetPrice) / GetPipSize();
     }

   //--- Estimated P&L in account currency
   double EstimateProfit(double lots, double pips)
     {
      return pips * GetPipValue(lots);
     }

   //--- R:R ratio
   double GetRR(double tpPips, double slPips)
     {
      if(slPips <= 0) return 0;
      return tpPips / slPips;
     }

   //--- Normalize lot to broker constraints
   double NormalizeLots(double lots)
     {
      double minLot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxLot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      lots = MathFloor(lots / lotStep) * lotStep;
      return MathMin(MathMax(lots, minLot), maxLot);
     }
  };

#endif // OM_CALC_MQH
