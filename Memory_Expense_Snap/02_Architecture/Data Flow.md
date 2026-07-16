---
type: architecture
status: priority
tags: [data-flow, transactions]
---

# Data Flow

The app now has a shared local transaction data flow plus frontend contracts for backend sync and capture integrations.

Current prepared flow:

```mermaid
flowchart LR
  A["Add Transaction"] --> B["Transaction Repository"]
  B --> C["Dashboard"]
  B --> D["History"]
  B --> E["Analytics"]
  B --> F["Local Cache"]
  B --> G["Sync Service Contract"]
  G --> H["Firestore later"]
  I["Voice/OCR Adapter Contracts"] --> A
  J["Attachment Service Contract"] --> B
```

`KharchaBootstrap` creates the local repositories, restores the app session through `AuthService`, injects `AppServices`, and chooses the initial route.

Related:

- [[Transactions]]
- [[Repository Plan]]
- [[State Management]]
- [[Phase 2 Real Expense Flow]]
- [[Transaction Model]]
