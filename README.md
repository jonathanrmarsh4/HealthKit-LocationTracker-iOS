# Trading Platform

A custom algorithmic cryptocurrency trading platform built on top of the [Jesse](https://github.com/jesse-ai/jesse) framework.

## About

This project is a fork of Jesse v1.12.2, an advanced crypto trading framework for backtesting, optimizing, and live-deploying trading strategies. We use it as the foundation for building our own custom trading platform.

## Features (inherited from Jesse)

- **Strategy Development** - Define trading strategies in simple Python
- **Backtesting** - Accurate backtesting without look-ahead bias
- **300+ Technical Indicators** - Comprehensive indicator library
- **Multi-Timeframe / Multi-Symbol** - Trade across timeframes and symbols simultaneously
- **Order Types** - Market, limit, and stop orders
- **Spot & Futures** - Support for both spot and futures trading
- **Leverage & Short-Selling** - First-class support
- **Optimization** - Hyperparameter tuning via Optuna
- **Live / Paper Trading** - Deploy strategies live or paper trade
- **Alerts** - Telegram, Slack, and Discord notifications

## Requirements

- Python >= 3.10
- PostgreSQL
- Redis

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Or install as a package
pip install -e .
```

See the [Jesse documentation](https://docs.jesse.trade/docs/getting-started) for detailed setup instructions.

## Project Structure

```
.
├── jesse/              # Core trading framework
│   ├── strategies/     # Strategy definitions
│   ├── indicators/     # Technical indicators
│   ├── exchanges/      # Exchange integrations
│   ├── models/         # Data models
│   └── services/       # Core services
├── tests/              # Test suite
├── utils/              # Utility scripts
├── setup.py            # Package configuration
├── requirements.txt    # Python dependencies
└── Dockerfile          # Container configuration
```

## Attribution

This project is based on [Jesse](https://github.com/jesse-ai/jesse) by Jesse.Trade, licensed under the MIT License.

## Disclaimer

This software is for educational purposes only. USE THE SOFTWARE AT YOUR OWN RISK. Do not risk money that you are afraid to lose. There might be bugs in the code - this software does not come with any warranty.
