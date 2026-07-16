---
type: architecture
status: active
tags: [navigation, routes]
---

# Navigation Map

Current route flow:

```mermaid
flowchart TD
  A["main.dart"] --> B["OnboardingScreen"]
  B --> C["AuthScreen"]
  C --> D["PersonalizationFlow"]
  C --> E["LoginScreen"]
  D --> F["DashboardScreen"]
  F --> G["Dashboard tab"]
  F --> H["AnalyticsScreen"]
  F --> I["HistoryScreen"]
  F --> J["ProfileScreen"]
  F --> K["AddTransactionSheet"]
  I --> K
```

Dashboard tab back behavior:

- System back from Analytics, History, or Profile selects the Dashboard Home tab.
- System back only leaves the Dashboard route when Home is already active.

Related:

- [[Flutter Entry Point]]
- [[Dashboard]]
- [[Auth Login]]
- [[Personalization]]
