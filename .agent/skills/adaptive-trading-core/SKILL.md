---
name: adaptive-trading-core
description: Defines the core architecture for the "Ultimate Bot" project. Mandates an asset-agnostic, multi-strategy orchestration engine with dynamic volatility-based sizing.
---

# Ultimate Bot - Core Architecture

This project implements an intelligent orchestration framework for algorithmic trading. It hosts multiple trading strategies and selects them dynamically based on real-time market analysis.

## 1. Asset & Market Scope (Asset Agnostic)
- **Single Codebase:** The bot must be capable of running on ANY asset (B3 Indices, Forex, Metals) without code changes.
- **Volatility Normalization (Critical):**
  - **No Hardcoded Points:** NEVER use fixed point values for Stop Loss or Take Profit (e.g., avoid `Stop = 150 points`).
  - **Dynamic Sizing:** ALWAYS calculate distances based on **ATR (Average True Range)** or percentage of price.
  - *Example:* `StopLoss = CurrentATR * StopMultiplier`. This ensures the logic works whether the asset is priced in thousands (Index) or decimals (Forex/Dollar).
- **Timeframes:** Primary focus on **M1** and **M5**, but logic should be timeframe-independent where possible.

## 2. The "Strategy Orchestrator" Pattern
The bot does not run a linear logic. It acts as a manager (Kernel) for a pool of isolated strategy implementations.

### The Logic Flow (OnTick):
1.  **Market Analysis:** The bot analyzes the current market state (Volatility, Trend, Volume) globally.
2.  **Scoring Loop:** The bot queries every available strategy: *"Given this market state, what is your confidence?"*
3.  **Selection:** Each strategy returns a **Score** (0.0 to 100.0).
4.  **Execution:** The Orchestrator selects the strategy with the highest score (above a minimum threshold) to manage the current trade or open a new one.

## 3. Implementation Guidelines
- **Interfaces:** All strategies must implement a common interface (e.g., `IStrategy`) containing methods like `CalculateScore()`, `ExecuteSignal()`, and `ManagePosition()`.
- **Decoupling:** Strategies must not know about each other. They only communicate with the Core/Kernel.
- **State Management:**
  - **Kernel:** Responsible for global risk management (Drawdown limit, Daily Goal, connection status).
  - **Strategies:** Responsible for trade logic (Entry price, specific Trailing Stops).

## 4. Key Terminology (English)
- **"Score"**: The confidence rating (0-100) returned by a strategy.
- **"Orchestrator" / "Kernel"**: The central manager class.
- **"MarketState"**: The data object containing shared analysis (ATR, Trend info).

## 5. Input & Configuration Architecture
- **Multipliers over Fixed Values:** Inputs should generally ask for "Factors" or "Multipliers" (e.g., `StopLoss_ATR_Multiplier`) rather than absolute points.
- **Magic Numbers:** The bot must expose a `MagicNumber` input to allow multiple instances on different charts (e.g., one on WIN, one on WDO) without collision.
- **Strategy Toggles:** Include inputs to enable/disable specific strategies manually (e.g., `Enable_TrendStrategy = true`).