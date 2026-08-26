---
type: architecture
status: active
tags: [data-flow, transactions]
---

# Data Flow

The app operates on a local-first transaction data flow with automatic background synchronization via `AppSyncCoordinator`.

Current data flow:

```mermaid
flowchart LR
  A["Add Transaction Sheet"] --> B["Transaction Repository"]
  B --> C["Dashboard Screen"]
  B --> D["History Screen"]
  B --> E["Analytics Screen"]
  B --> F["Local Cache (SharedPreferences)"]
  B --> G["AppSyncCoordinator"]
  G --> H["Firestore (when Firebase enabled)"]
  I["Voice/OCR Adapter Contracts"] --> A
  J["Attachment Service Contract"] --> B
```

`KharchaBootstrap` creates the local repositories, restores the app session through `AuthService`, injects `AppServices`, and chooses the initial route.

Related:

- [[Transactions]]
- [[Repository Plan]]
- [[State Management]]
- [[Firebase Architecture]]
- [[Phase 2 Real Expense Flow]]
- [[Transaction Model]]
