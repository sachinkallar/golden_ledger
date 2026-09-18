# 🪙 Golden Ledger

> **A sleek, modern, and privacy-first personal finance and expense tracking application built with Flutter.**

Golden Ledger combines executive aesthetics with powerful financial management tools. Built local-first with SQLite, it keeps all your personal financial records strictly on your device while offering natural-language expense entry, smart budgets, real-time net worth tracking, and actionable financial insights.

---

## ✨ Features

- **📊 Comprehensive Financial Dashboard**
  - Instant overview of Net Worth, monthly cash flow (Income vs. Expense), and savings rate.
  - Interactive income/expense breakdown charts.
  - Quick action shortcuts and recent transaction feed.

- **⚡ Natural Language Transaction Entry**
  - Type expenses naturally (e.g., *"Spent 450 on lunch at Swiggy"* or *"Received 50k salary"*).
  - Automatically extracts amount, transaction type (income, expense, transfer), and intelligent category matching.

- **🏦 Multi-Account & Wallet Management**
  - Track multiple accounts: Bank Accounts, Credit Cards, Cash, Digital Wallets, and Investments.
  - Real-time balance calculations with support for opening balances and inter-account transfers.

- **🏷️ Intelligent Categorization**
  - Built-in categories for essential living costs, discretionary spending, and income streams.
  - Color-coded icons and hierarchical parent-child category structuring.

- **🎯 Smart Budgets & Limit Alerts**
  - Set monthly category-wise spending limits.
  - Visual budget utilization bars with alert thresholds when approaching or exceeding limits.

- **📈 Visual Reports & Analytics**
  - Spending distribution pie charts and month-over-month trend analysis powered by `fl_chart`.
  - Detailed financial health breakdown.

- **💡 Financial Insights Engine**
  - Automated rules-based recommendations on savings rate, discretionary spending spikes, and budget compliance.

- **🔒 100% Local-First & Private**
  - Zero cloud tracking or third-party data harvesting.
  - All accounts, transactions, and budgets stay in an encrypted-ready local SQLite database.

- **📱 Adaptive & Premium UI**
  - Refined Material 3 Dark Theme with Obsidian and Gold design accents.
  - Fully responsive layout: Mobile bottom bar navigation and desktop/tablet navigation rail.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Targeting Windows, macOS, Linux, Android, iOS)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Cubit architecture)
- **Local Persistence**: [sqflite](https://pub.dev/packages/sqflite) & [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)
- **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Typography & Styling**: [google_fonts](https://pub.dev/packages/google_fonts) (Inter) with custom gold design tokens
- **Currency & Precision**: Integer minor-unit arithmetic (paise/cents) to eliminate floating-point rounding errors

---

## 📁 Directory Structure

```text
lib/
├── core/
│   ├── constants/        # Design tokens, colors, layout constants
│   ├── database/         # SQLite schema, migrations, and database helper
│   ├── theme/            # Obsidian & Gold Material 3 theme configurations
│   └── utils/            # Currency formatters, date helpers, financial calculators
├── features/
│   ├── accounts/         # Account models, repository, cubits, and views
│   ├── budgets/          # Budget management and progress tracking
│   ├── categories/       # Category definitions and management
│   ├── dashboard/        # Executive overview, net worth, and quick actions
│   ├── insights/         # Automated financial insight generation
│   ├── natural_entry/    # Natural language parsing engine
│   ├── reports/          # Analytics and visual charts
│   └── transactions/     # Transaction recording, filtering, and history
└── main.dart             # App initialization and responsive shell layout
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- For Desktop (Windows/macOS/Linux): Visual Studio C++ build tools or Xcode installed.

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd golden_ledger
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**

   - On Desktop (Windows):
     ```bash
     flutter run -d windows
     ```
   - On Android/iOS:
     ```bash
     flutter run
     ```
   - On Web (Debug):
     ```bash
     flutter run -d chrome
     ```

---

## 🧪 Testing & Code Quality

Run tests and static analysis:

```bash
# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
