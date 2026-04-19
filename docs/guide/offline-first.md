# Offline-first intents

When the network is down (or a call fails), you can **queue** [OmegaIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntent-class.html)s instead of dropping user actions. The package defines small **core types**; **persistence** (Hive, SQLite, `shared_preferences`, …) stays in your app.

---

## Core types

- **[OmegaQueuedIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaQueuedIntent-class.html)** — id, intent **name**, optional **payload**, **createdAt**. `OmegaQueuedIntent.fromIntent(intent)` is a convenience constructor. Payloads should be **JSON-serializable** if you store them.
- **[OmegaOfflineQueue](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaOfflineQueue-class.html)** — abstract queue API your implementation satisfies (enqueue, dequeue, peek, clear, …).
- **[OmegaMemoryOfflineQueue](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaMemoryOfflineQueue-class.html)** — in-memory implementation for tests or ephemeral sessions.

---

## Wiring in a flow

The **`example/`** app’s **`OrdersFlow`** takes an offline queue dependency and shows how a flow can **retry** or **surface** queued work when connectivity returns. Read **`example/lib/orders/orders_flow.dart`** next to **`omega_setup.dart`** where the queue is constructed once and injected.

---

## Related

- [Intents, flows & manager](./intents-flows-manager)  
- [Channel & events](./channel-events)  
- [Total architecture](./total-architecture) — cross-cutting table  
