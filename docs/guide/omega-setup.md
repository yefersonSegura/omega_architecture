# omega_setup.dart

Every Omega app has a **single composition root** — usually `lib/omega/omega_setup.dart` (name can differ). It is where you:

1. Create or receive the shared **[OmegaChannel](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannel-class.html)** (and optional **[namespace](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannel/namespace.html)** views per module).  
2. Instantiate **agents** (each typically **once**).  
3. Instantiate **flows**, passing the **same channel or namespace** and the **agent instances** they coordinate with.  
4. Register **[OmegaRoute](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaRoute-class.html)** entries whose **`id`** values match your **`navigate.*`** intent wires.  
5. Return **[OmegaConfig](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaConfig-class.html)** with **`initialFlowId`**, **`initialNavigationIntent`**, and optional **`intentHandlerRegistrars`**.

[OmegaRuntime.bootstrap](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaRuntime/OmegaRuntime.bootstrap.html) reads that config, registers everything, and calls **`wireNavigator`**.

---

## Minimal mental model

| List in `OmegaConfig` | Rule |
|----------------------|------|
| **`agents:`** | Each **variable** appears **once** (no duplicate `FooAgent(channel)` lines). |
| **`flows:`** | Each **flow type** once per active stack (no two `AuthFlow(...)` with the same role). |
| **`routes:`** | Each **`OmegaRoute(id: …)`** **unique** — duplicate ids break navigation resolution. |
| **Flow ctor** | Same **agent instance** referenced in `agents:` and in `SomeFlow(..., agent: thatAgent)`. |

---

## Cold start: `initialFlowId` + `initialNavigationIntent`

- **`initialFlowId`** — which [OmegaFlow](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow-class.html) is **running** after `flowManager.switchTo(...)` on first frame.  
- **`initialNavigationIntent`** — first **screen** the user should see (`OmegaIntent.fromName(AppIntent.navigateLogin)` etc.). It does **not** automatically push a route; you pass the same intent into **[OmegaScope](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaScope-class.html)** and use **[OmegaInitialRoute](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaInitialRoute-class.html)** (or **[OmegaInitialNavigationEmitter](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaInitialNavigationEmitter-class.html)**) so the first frame matches **`navigate.*`** semantics.

If you have **both** routes and flows registered, **`omega validate`** expects these two fields to be coherent (and may apply deterministic fixes — still run validate in CI).

---

## Namespaces (large apps)

Use **`channel.namespace('auth')`** (and pass that **bus** into flows/agents for that module) so event names can stay short without colliding with other modules. The **example** uses `auth`, `provider`, and `orders` namespaces.

---

## Intent handler registrars

For small apps you can attach **[OmegaFlowManager.registerIntentHandler](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager/registerIntentHandler.html)** or pipelines next to your config instead of putting everything in `main.dart`:

```dart
intentHandlerRegistrars: [ExampleIntentHandlerDemo.attach],
```

See **[Intents, flows & manager](./intents-flows-manager)**.

---

## Example (abbreviated)

The repository **`example/lib/omega/omega_setup.dart`** wires multiple agents, namespaced flows, typed routes, offline queue, and cold-start fields:

```dart
OmegaConfig createOmegaConfig(OmegaChannel channel) {
  final authNs = channel.namespace('auth');
  final authAgent = AuthAgent(authNs);
  return OmegaConfig(
    agents: <OmegaAgent>[/* … */],
    flows: <OmegaFlow>[AuthFlow(channel: authNs, agent: authAgent), /* … */],
    routes: [
      OmegaRoute(id: 'login', builder: (context) => OmegaLoginPage(authAgent: authAgent)),
      OmegaRoute.typed<LoginSuccessPayload>(id: 'home', builder: (context, data) => HomePage(userData: data)),
    ],
    initialFlowId: AppFlowId.authFlow.id,
    initialNavigationIntent: OmegaIntent.fromName(AppIntent.navigateLogin),
    intentHandlerRegistrars: [ExampleIntentHandlerDemo.attach],
  );
}
```

Open the **full file** on GitHub: [`example/lib/omega/omega_setup.dart`](https://github.com/yefersonSegura/omega_architecture/blob/main/example/lib/omega/omega_setup.dart).

---

## Commands

- **`omega init`** — scaffolds `omega_setup.dart`, `app_semantics.dart`, `app_runtime_ids.dart` (and **`--force`** overwrites setup only).  
- **`omega validate`** — structural checks on the setup file.  
- **`omega g ecosystem <Name>`** — adds a module folder + patches setup — run from the directory where you want files.

---

## Next

- [Navigation & routes](./navigation-router) — `navigate.*` vs `navigate.push.*`  
- [Contracts](./contracts) — optional `contract` on flows and agents  
- [Total architecture](./total-architecture) — full stack map  
