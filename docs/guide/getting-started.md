# Getting started

This page is the **on-ramp**: install the toolchain, create or adopt a project, then follow the **learning path** in the sidebar (same idea as [Flutter documentation](https://docs.flutter.dev/) — start here, then branch by topic).

---

## 1. Install the toolchain

**A. Global CLI** (so `omega` is available everywhere):

```bash
dart pub global activate omega_architecture
```

**Bleeding edge** from Git:

```bash
dart pub global activate --source git https://github.com/yefersonSegura/omega_architecture.git
```

Add Pub’s **`bin`** to your **`PATH`**:

| OS | Typical path |
|----|----------------|
| **Windows** | `%LOCALAPPDATA%\Pub\Cache\bin` → e.g. `C:\Users\<you>\AppData\Local\Pub\Cache\bin` |
| **macOS / Linux** | `$HOME/.pub-cache/bin` |

Verify:

```bash
omega --help
```

If the shell cannot find `omega`, use **`dart run omega_architecture:omega …`** from a project that lists the package in **`pubspec.yaml`**, or invoke **`omega.bat`** by full path on Windows. Pub does **not** support `dart pub global run` for Flutter-dependent globals — see the [README](https://github.com/yefersonSegura/omega_architecture/blob/main/README.md) for details.

---

## 2. New application

```bash
omega create app my_app
cd my_app && flutter run
```

Optional **AI kickstart** (requires env + keys):

```bash
omega create app my_store --kickstart "e-commerce with cart" --provider-api
```

---

## 3. Existing Flutter app

Add the dependency (pick the current version on [pub.dev](https://pub.dev/packages/omega_architecture)):

```yaml
dependencies:
  omega_architecture: ^1.0.5
```

From the **app root**:

```bash
dart run omega_architecture:omega init
```

Then align **`lib/omega/omega_setup.dart`** with your modules — see **[omega_setup.dart](./omega-setup)** and the **`example/`** tree on GitHub.

---

## 4. Learning path (recommended order)

| Step | Guide | Why |
|------|--------|-----|
| 1 | [Vision & why Omega](./vision-and-why) | Fit and trade-offs |
| 2 | [Core concepts](./concepts) | Glossary |
| 3 | [Data flow](./data-flow) | End-to-end path |
| 4 | [Total architecture](./total-architecture) | One map of the whole stack |
| 5 | [omega_setup.dart](./omega-setup) | Composition + cold start |
| 6 | [Channel & events](./channel-events) → [Intents & flows](./intents-flows-manager) → [Agents](./agents-behaviors) | Core library |
| 7 | [Navigation & routes](./navigation-router) | `navigate.*` and typed routes |
| 8 | [Omega CLI](./cli) | Every command + **`omega ai`** |
| 9 | [Inspector](./inspector) | Debug UX |
| 10 | [Testing](./testing) | Tests without heavy UI |
| 11 | [Contracts](./contracts) / [Time travel](./time-travel) / [Offline-first](./offline-first) | Advanced topics |
| 12 | [Comparison](./comparison) | vs BLoC / Riverpod |

---

## 5. API reference

Generated API docs live on **pub.dev**: [omega_architecture API](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/omega_architecture-library.html).

The **[API reference](./api-reference)** page in this site explains how to navigate them.
