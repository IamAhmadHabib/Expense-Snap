---
type: code-map
status: active
tags: [code, dashboard]
---

# Dashboard Code

Source:

```text
kharcha/lib/features/dashboard/dashboard_screen.dart
```

Shell responsibilities:

- Retains Home, Analytics, History, and Profile tab children.
- Routes avatar and notification actions.
- Opens Add Transaction with the requested initial capture mode.
- Intercepts system back on non-Home tabs and selects Home before allowing the Dashboard route to pop.

Related:

- [[Dashboard]]
- [[Add Transaction]]
- [[Data Flow]]
- [[Design Debt]]
