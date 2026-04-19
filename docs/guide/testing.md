# Testing

Omega pushes **business rules** into [OmegaFlow](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow-class.html) and [OmegaAgent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgent-class.html) classes that depend on an **[OmegaChannel](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannel-class.html)** and **[OmegaFlowManager](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager-class.html)** — you can **`flutter test`** them with **plain Dart** (no `WidgetTester`) for most scenarios.

---

## What to test first

| Target | Idea |
|--------|------|
| **Agent + behavior** | Emit events on a **test channel**; assert reactions / follow-up events / `onAction` branches. |
| **Flow** | Put flow in **`running`**, call **`receiveIntent`** / drive **`onEvent`**, assert **expressions** or emitted events. |
| **FlowManager** | **`registerFlow`**, **`switchTo`**, **`handleIntent`** / **`handleTypedIntent`**, then read **`getAppSnapshot()`** or expression streams. |
| **Navigator** | Integration-style tests can still pump **`MaterialApp`** with **`navigatorKey`** from bootstrap — keep these fewer in number. |

Idle / paused flows **ignore** intents until activated — assert both paths.

---

## Package tests as reference

The **`omega_architecture`** repository **`test/`** folder contains unit tests for flows, agents, expressions, and manager behaviour. Clone or browse on GitHub and copy patterns into your app’s **`test/`** tree.

---

## Contracts in tests

When you use [OmegaFlowContract](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowContract-class.html) / [OmegaAgentContract](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentContract-class.html), debug warnings only appear in **debug mode** — tests run with assertions you write explicitly; contracts remain useful as **documentation** of expected traffic.

---

## Related

- [Agents & behaviors](./agents-behaviors)  
- [Intents, flows & manager](./intents-flows-manager)  
- [Contracts](./contracts)  
- [Omega CLI](./cli) — `omega validate` before CI merge  
