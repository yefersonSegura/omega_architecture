# Inspector & VM Service

During **debug**, Omega can surface **live channel traffic**, **flow snapshots**, and quick **JSON** views of payloads — without shipping that UI to production. Three integration patterns are common; pick one or combine them.

---

## 1. In-app overlay

Embed **[OmegaInspector](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaInspector-class.html)** (e.g. in a `Stack`) so developers can expand/collapse a panel over the running app. Guard with **`kDebugMode`** so release builds stay lean.

---

## 2. Launcher (dialog or extra window)

**[OmegaInspectorLauncher](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaInspectorLauncher-class.html)** in an `AppBar` opens the inspector in a **dialog** (desktop/mobile) or a **new browser tab** on web (query flag pattern). Same **`kDebugMode`** guard.

---

## 3. Browser + VM Service (desktop / mobile)

**[OmegaInspectorServer](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaInspectorServer-class.html)** starts a small HTTP/WebSocket server; the console prints a URL (often `http://localhost:9292`) that loads the **hosted** inspector page and connects to your running VM.

**CLI shortcut** — paste the VM Service URL from `flutter run`:

```bash
dart run omega_architecture:omega inspector
```

---

## Hosted static page

The file **`inspector.html`** ships with this documentation site (**`/inspector.html`** under your Pages base path). `OmegaInspectorServer` and the CLI open it with a **hash** or query carrying the encoded VM Service URI so the page can attach.

---

## Security & production

- Treat VM Service URLs like **debug secrets** — do not expose them on untrusted networks.  
- Keep inspector widgets and servers **behind `kDebugMode`** (or a compile-time flag).  
- On **web**, `OmegaInspectorServer` is a stub — use the multi-window / receiver pattern from the package API docs instead.

---

## Related

- [Omega CLI](./cli) — `omega inspector` flags  
- [Time travel](./time-travel) — recorded sessions complement the inspector  
- **`example/lib/main.dart`** — overlay + launcher + server wiring  
