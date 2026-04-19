# Intents, flows & manager

This chapter covers **what the UI asks for** ([OmegaIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntent-class.html)), **who coordinates** ([OmegaFlow](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow-class.html)), and **who routes work** ([OmegaFlowManager](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager-class.html)).

---

## OmegaIntent

An intent is a **named request** with optional **payload**. Build them with **`OmegaIntent.fromName`** and enums implementing [OmegaIntentName](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntentName-class.html) (see **`AppIntent`** in the example’s **`app_semantics.dart`**).

The UI (or tests) send intents through **`flowManager.handleIntent(intent)`** — the manager forwards to every flow in **`OmegaFlowState.running`**.

---

## OmegaFlow

Subclass [OmegaFlow](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow-class.html), pass **`super(id: …)`**, and implement:

- **`onIntent`** — react to intents routed while this flow is running (login submit, refresh, …).  
- **`onEvent`** — react to **channel** events (often emitted by agents).  

Emit **expressions** for UI state via **`emitExpression(type, payload)`** and drive navigation by emitting the same **navigation events / intents** the [OmegaNavigator](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaNavigator-class.html) listens for (see [Navigation & routes](./navigation-router)).

**Lifecycle:** `idle` → `running` (via **`activate`** / **`switchTo`**) → `paused` / `sleeping` / `ended`. Only **running** flows receive intents in the default routing.

---

## OmegaFlowManager

| Method | Use |
|--------|-----|
| **`registerFlow`** | Register once at bootstrap. |
| **`activate(id)`** | Add a flow to the running set (multi-flow). |
| **`switchTo(id)`** | Single “main” flow: activates one and pauses others. |
| **`handleIntent`** | Entry point from UI. |
| **`wireNavigator`** | Called by [OmegaRuntime.bootstrap](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaRuntime/OmegaRuntime.bootstrap.html) — connects navigation traffic on the channel. |

---

## Lightweight handlers (optional)

For small features you can register **[registerIntentHandler](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager/registerIntentHandler.html)**, **[Omega.handle](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/Omega-class.html)**, **[OmegaIntentReducer](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntentReducer-class.html)**, or **[OmegaIntentHandlerPipeline](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntentHandlerPipeline-class.html)** via **`OmegaConfig.intentHandlerRegistrars`** — handlers run **before** intents reach running flows; **`consumeIntent: true`** skips flow delivery.

---

## UI rule of thumb

Widgets **emit intents** and **listen to expressions** (or `OmegaFlowExpressionBuilder`). They **do not** call repositories or imperative services for feature coordination — that belongs in **flows** and **agents**.

---

## Full example

Walk through **`example/lib/auth/auth_flow.dart`**, **`auth_page.dart`**, and **`omega_setup.dart`** on GitHub.

---

## Next

- [Agents & behaviors](./agents-behaviors)  
- [Contracts](./contracts)  
- [Data flow](./data-flow)  
