//+------------------------------------------------------------------+
//|  JBM Order Manager                                               |
//|  TradingView-style order panel for MetaTrader 5                  |
//|  Version: 0.1.0 (Phase 1 - MVP)                                  |
//|  (c) JBM Trading Tools — All rights reserved                     |
//+------------------------------------------------------------------+
#property copyright "JBM Trading Tools"
#property version   "0.10"
#property strict

#include <JBM/OM_Calc.mqh>
#include <JBM/OM_UI.mqh>
#include <JBM/OM_Exec.mqh>

// --- Input Parameters ---
input string   InpLicenseKey  = "";           // License Key
input double   InpDefaultRisk = 1.0;          // Default Risk % per trade
input int      InpPanelX      = 20;           // Panel X position
input int      InpPanelY      = 50;           // Panel Y position

// --- Global objects ---
COrderPanel    g_panel;
COrderCalc     g_calc;
COrderExec     g_exec;

//+------------------------------------------------------------------+
int OnInit()
  {
   // TODO Phase 3: validate license
   // if(!ValidateLicense(InpLicenseKey)) { Alert("Invalid license"); return INIT_FAILED; }

   if(!g_panel.Create(InpPanelX, InpPanelY))
     {
      Print("Failed to create order panel");
      return INIT_FAILED;
     }

   g_calc.SetDefaultRisk(InpDefaultRisk);
   g_panel.SetCalc(g_calc);
   g_panel.SetExec(g_exec);
   g_panel.Refresh();

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_panel.Destroy();
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   g_panel.OnTick();   // refresh Bid/Ask/Spread + recalc P&L
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   g_panel.OnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+
