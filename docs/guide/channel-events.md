# Channel & events

**[OmegaChannel](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannel-class.html)** is the shared **event bus**: any part of the app can **`emit(OmegaEvent)`** and **listen** to **`channel.events`**. Flows and agents subscribe here; the UI typically sends **intents** through the **[OmegaFlowManager](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager-class.html)** or emits events for cross-cutting updates.

---

## Minimal usage

```dart
final channel = OmegaChannel();
channel.emit(OmegaEvent.fromName(AppEvent.authLoginRequest, payload: creds));
// Or: OmegaEvent.fromName<MyDto>(AppEvent.someCase, payload: dto) — generic matches payload type.
channel.events.listen((e) {
  // e.payloadAs<MyDto>() or e.typedPayloadAs<MyTypedEvent>() when payload implements OmegaTypedEvent
});
// When the app shuts down:
// channel.dispose();
```

Always **`dispose()`** the channel when the owning scope tears down (same lifetime as your `MaterialApp` / process).

---

## Typed names

Prefer **`OmegaEvent.fromName`** / **`OmegaIntent.fromName`** (**static** methods on the classes) with enums implementing [OmegaEventName](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaEventName-class.html) / [OmegaIntentName](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntentName-class.html) (see **`AppEvent` / `AppIntent`** in **`example/lib/omega/app_semantics.dart`**). That keeps wire strings in **one place** and survives refactors.

Use **`payloadAs<T>()`** on [OmegaEvent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaEvent-class.html) / [OmegaIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntent-class.html) for safe casts. Use **`typedPayloadAs<T>()`** on **events** when **`T`** implements **[OmegaTypedEvent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaTypedEvent-class.html)** (usually after **`emitTyped`**), and on **intents** when **`T`** implements **[OmegaTypedIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaTypedIntent-class.html)** (usually after **`handleTypedIntent`**).

---

## Typed payloads (analyzer-checked)

- **`OmegaEvent.fromName<T>(enumCase, payload: …)`** / **`OmegaIntent.fromName<T>(enumCase, payload: …)`** — the type parameter **`T`** must match the **`payload`** you pass (plain DTOs in **`example/lib/auth/auth_events.dart`**).
- **Bus:** [OmegaTypedEvent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaTypedEvent-class.html) + **`emitTyped`** — one class carries **`name`** + fields; listeners use **`typedPayloadAs`** or **`payloadAs`**.
- **UI → flow:** [OmegaTypedIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaTypedIntent-class.html) + **`flowManager.handleTypedIntent(myIntent)`** — the **same object** is the wire (`implements` [OmegaIntentName](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntentName-class.html)) and the **`OmegaIntent.payload`**. In **`onIntent`**, read **`ctx.intent?.typedPayloadAs<MyIntent>()`** (see **`AuthLoginIntent`** / **`AuthLogoutIntent`** in the example).

---

## Namespaces

For large apps, **`channel.namespace('orders')`** returns an **[OmegaChannelNamespace](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannelNamespace-class.html)** (bus view) so module traffic stays grouped. Flows and agents can take a **namespace** instead of the root channel — the **example** wires `auth`, `provider`, and `orders`.

---

## Typed events on the bus

[OmegaTypedEvent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaTypedEvent-class.html) + **`emitTyped`** give stronger typing for **bus** events when you need it. For **intents**, either a **plain DTO** with **`OmegaIntent.fromName<Dto>(…)`** or a single class **`implements OmegaTypedIntent`** with **`handleTypedIntent`** (example auth).

---

## OmegaEventBus abstraction

[OmegaFlow](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow-class.html) and [OmegaAgent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgent-class.html) accept an **[OmegaEventBus](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaEventBus-class.html)** — either the root channel or a namespace — so the same code works scoped or global.

---

## Debugging

- **[OmegaBuilder](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaBuilder-class.html)** rebuilds when a **named** event arrives.  
- **[Inspector](./inspector)** shows recent events and flow snapshots.  
- **[Time travel](./time-travel)** records and replays event streams.

---

## Full examples

Study **`example/lib/auth/`** (login request / success / error events) alongside **`example/lib/omega/omega_setup.dart`** for namespace wiring.

---

## Next

- [Data flow](./data-flow)  
- [Intents, flows & manager](./intents-flows-manager)  
