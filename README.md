# JBM Order Manager

MQL5 Order Panel for MetaTrader 5 — TradingView-style order entry with automatic risk/reward and P&L calculation.

> **Subscription:** $5/month · $9/month Pro · $49 Lifetime

---

## Features (Phase 1 — MVP)

- **Order Types:** Market, Limit, Stop
- **Direction:** Buy / Sell with live Bid/Ask spread display
- **Quantity Modes (5 options):**
  - Units (manual lot)
  - Margin USD
  - % Balance
  - Risk, USD (auto-lot from SL distance)
  - Risk, % Balance (recommended for prop firm)
- **Take Profit — 5 input modes:**
  - Price, Pips, % Price, Reward USD, Reward % Balance
- **Stop Loss — 5 input modes:**
  - Price, Pips, % Price, Risk USD, Risk % Balance
- **Order Info panel:**
  - Trade Value, Margin Required / Available, Leverage, Pip Value
- **Time in Force:** Day, Week, Month, GTD

---

## Structure

```
Experts/
  └── JBM_OrderManager.mq5      # Main EA entry point
Include/
  └── JBM/
      ├── OM_Calc.mqh            # Pip value, lot sizing, margin, P&L math
      ├── OM_UI.mqh              # GUI panel objects & layout
      ├── OM_Exec.mqh            # Order execution via CTrade
      └── OM_License.mqh         # License validation (Phase 3)
docs/
  ├── PLAN.md                    # Full development & business plan
  └── CHANGELOG.md               # Version history
```

---

## Installation

1. Copy `Experts/JBM_OrderManager.mq5` → `MQL5/Experts/`
2. Copy `Include/JBM/` → `MQL5/Include/JBM/`
3. Compile in MetaEditor (F7)
4. Attach EA to any chart
5. Input License Key when prompted

---

## P&L Calculation Logic

```
Pip Value   = TickValue × (PipSize / TickSize)
Trade Value = Units × EntryPrice
Margin Req  = TradeValue / Leverage
Lot (Risk%) = (Balance × RiskPct%) / (SL_pips × PipValue)

Est. Profit = TP_pips × PipValue × Lots
Est. Loss   = SL_pips × PipValue × Lots
R:R Ratio   = TP_pips / SL_pips
```

---

## Roadmap

| Phase | Status | Features |
|-------|--------|----------|
| Phase 1 | 🔧 In Progress | Core panel, all order types, auto-lot, P&L calc |
| Phase 2 | Planned | R:R display, multi-order, presets, dashboard |
| Phase 3 | Planned | License system, prop firm mode, P&L tracker |

---

## License

Proprietary — JBM Trading Tools. All rights reserved.
