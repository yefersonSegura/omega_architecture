# Example app

The **`example/`** directory in the repository is a **full Flutter application** — use it the same way you would study **`flutter/samples`** or template apps: read `main.dart` and `omega_setup.dart` first, then open each module.

---

## What it demonstrates

| Area | Files to read |
|------|----------------|
| **Bootstrap** | `lib/main.dart` — `OmegaRuntime.bootstrap`, `MaterialApp`, `navigatorKey`, first-frame `switchTo` + navigation |
| **Composition** | `lib/omega/omega_setup.dart` — namespaces, agents, flows, routes, cold start, intent registrars |
| **Semantics** | `lib/omega/app_semantics.dart`, `app_runtime_ids.dart` — `AppEvent` / `AppIntent` / flow & agent ids |
| **Auth module** | `lib/auth/*` — `AuthFlow`, `AuthAgent`, `AuthBehavior`, `auth_page`, **`AuthLoginIntent` / `handleTypedIntent`**, `emitTyped` / **`typedPayloadAs`**, **contracts** |
| **Other modules** | `lib/orders/`, `lib/provider/`, `lib/home/` — multi-flow patterns, typed `home` route |
| **Debug** | Inspector overlay / launcher, optional `OmegaInspectorServer`, time-travel panel |

---

## Run it

```bash
cd example
flutter run
```

Use **debug mode** to see inspector and time-travel UI.

---

## Align your app

After **`omega init`** in your own project, **diff** your `omega_setup.dart` against the example’s file until lists (`agents`, `flows`, `routes`) and cold-start fields match your product shape.

---

## Next

- [omega_setup.dart](./omega-setup)  
- [Getting started](./getting-started)  
