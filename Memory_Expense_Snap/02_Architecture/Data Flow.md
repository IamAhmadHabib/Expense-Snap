---
type: architecture
status: priority
tags: [data-flow, transactions]
---

# Data Flow

The missing spine of the app is a shared transaction data flow.

Target flow:

```mermaid
flowchart LR
  A["Add Transaction"] --> B["Transaction Repository"]
  B --> C["Dashboard"]
  B --> D["History"]
  B --> E["Analytics"]
  B --> F["Local Cache"]
  B --> G["Firestore later"]
```

Related:

- [[Transactions]]
- [[Repository Plan]]
- [[State Management]]
- [[Phase 2 Real Expense Flow]]
- [[Transaction Model]]
