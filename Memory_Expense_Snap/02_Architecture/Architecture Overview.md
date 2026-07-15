---
type: architecture
status: active
tags: [architecture, overview]
---

# Architecture Overview

Current app: Flutter UI shell under `kharcha/`.

Current limitation: screens own local/mock state instead of sharing one data spine.

Target architecture:

[[Feature Screens]] → controllers/viewmodels → repositories → local cache and remote services.

Related:

- [[Navigation Map]]
- [[Data Flow]]
- [[State Management]]
- [[Repository Plan]]
- [[Firebase Architecture]]
- [[Integrations]]
