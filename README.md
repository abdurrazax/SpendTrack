# SpendTrack 💰

A personal finance iOS app built with **Swift**, **UIKit**, and **Core Data** following **MVVM + Clean Architecture**.

> This is a portfolio project demonstrating production-level iOS architecture patterns.

---

## 📱 Features

- Add, edit, and delete income/expense transactions
- Category-based spending breakdown
- Offline-first — all data persisted with Core Data (no internet required)
- Monthly summary with total income, expenses, and balance
- Clean, native iOS UI with UIKit

---

## 🏗 Architecture

```
SpendTrack/
├── Models/
│   ├── Transaction.swift          # Core Data entity wrapper
│   └── Category.swift             # Transaction category enum
├── ViewModels/
│   ├── TransactionListViewModel.swift
│   └── AddTransactionViewModel.swift
├── Views/
│   ├── TransactionListViewController.swift
│   ├── AddTransactionViewController.swift
│   └── SummaryView.swift
├── Services/
│   └── CoreDataService.swift      # Abstracted persistence layer
└── Utilities/
    └── Extensions.swift
```

**Pattern:** MVVM with protocol-based dependency injection — ViewModels are fully testable without UI.

---

## 🛠 Tech Stack

| Area | Technology |
|------|-----------|
| Language | Swift 5.9 |
| UI | UIKit (programmatic, no storyboards) |
| Persistence | Core Data |
| Architecture | MVVM + Clean Architecture |
| Concurrency | async/await |
| Min iOS | iOS 15+ |

---

## 🚀 Getting Started

1. Clone the repo: `git clone https://github.com/abdurrazaq-dev/SpendTrack.git`
2. Open `SpendTrack.xcodeproj` in Xcode 15+
3. Build and run on simulator or device (no API keys needed)

---

## 💡 Key Design Decisions

- **No third-party dependencies** — pure Apple frameworks only, demonstrating deep platform knowledge
- **Protocol-oriented persistence** — `CoreDataService` conforms to `PersistenceServiceProtocol`, making ViewModels fully mockable for unit tests
- **Programmatic UI** — all views built in code (no storyboards), enabling proper code review and merge conflict resolution

---

## 👨‍💻 Author

**Abdur Razaq** — Senior iOS Developer  
[LinkedIn](https://linkedin.com) · [GitHub](https://github.com/abdurrazaq-dev)
