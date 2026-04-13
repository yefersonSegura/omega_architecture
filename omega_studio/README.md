# Omega Studio

**Omega Studio** brings [**Omega Architecture**](https://pub.dev/packages/omega_architecture) into **Visual Studio Code** (and compatible editors): one **Ω** icon in the activity bar, your Flutter project in sync with the **`omega`** CLI, and a clear path to optional AI help.

---

## What is Omega?

**Omega** is a Flutter architecture where **screens stay simple** and **business logic lives in flows and agents**. Everything coordinates through a single **event channel**: the UI sends **intents**, flows orchestrate work, agents run rules, and navigation stays predictable. You get structure that scales, easier debugging, and tooling (CLI + inspector + traces) built for that model.

**Why people adopt it**

- **Separation that sticks** — widgets do not call repositories “just this once”; intents and events keep boundaries clear.  
- **One mental map** — channel, flows, agents, navigator; new teammates onboard faster.  
- **Tooling, not only theory** — validate setup, generate modules, record sessions, open the inspector.  
- **Optional AI** — when you want it, **Omi** (below) helps design modules, audit gaps, explain traces, and more—without replacing the architecture.

---

## Who is **Omi**?

**Omi** is the **Omega assistant**: the friendly name for the **AI layer inside the `omega` CLI**. When you run commands like `omega ai coach …`, `omega ai explain …`, or use **AI** actions from this extension, **Omi** talks to your configured provider (for example OpenAI or Gemini), follows Omega’s patterns, and returns plans, code, or reports.

- **Omi is “asleep” by default** — safe for everyone; no keys required for normal Omega usage.  
- **You wake Omi** by setting `OMEGA_AI_ENABLED=true` and a provider + API key (see **Wake Omi** below).  
- **Omega Studio** does not replace the CLI: it **runs** `omega` for you and can **store secrets** in the editor so Omi’s commands work from the IDE.

---

## What Omega Studio does for you

| You want to… | In the extension |
|----------------|------------------|
| See every Omega action in one place | Open the **Ω → Commands** tree (categories: Project, Generate, Traces, AI) |
| Run anything quickly | **Command Palette** (`Ctrl+Shift+P` / `Cmd+Shift+P`) → search **Omega** → pick the command that lists all actions (category **Omega**), or any specific **Omega:** command |
| Check the project | **Validate**, **Doctor**, **Init** |
| Scaffold features | **Generate ecosystem / agent / flow**, or **Create Flutter app** |
| Debug sessions | **Trace: view** / **Trace: validate** |
| Use Omi from the IDE | **AI: Configure…**, **AI: Doctor**, **Coach**, **Module**, **Redesign** |
| Tweak a screen with Omi | Editor title bar or **right‑click** a `*_page.dart` → **Redesign this screen with AI** |
| Add a module with Omi | **Right‑click** in Explorer → **Create module with AI design** |

Output from commands appears in the **Omega Studio** output channel.

---

## Requirements

1. **[`omega_architecture`](https://pub.dev/packages/omega_architecture)** installed globally (`dart pub global activate …` or `flutter pub global activate …` from pub.dev or Git). **Omega Studio** runs the **`omega` / `omega.bat`** shim under Pub’s global **`bin`** (Pub does not support `dart`/`flutter pub global run` for Flutter-dependent packages). Without `omega` on `PATH`, call that shim by full path or fix `PATH` (see [README — Troubleshooting](https://github.com/yefersonSegura/omega_architecture/blob/main/README.md#troubleshooting-omega-command-not-found)).  
2. Open the **root folder** of your Flutter app as the workspace (the folder that contains `pubspec.yaml`).

> If the editor cannot find `dart` / `flutter`, configure **Dart: Flutter SDK** / **Dart: Sdk Path** in Settings—the extension inherits the same environment as other Dart tooling. If commands still fail, run **`dart pub global activate omega_architecture`** again with the same SDK as the IDE and restart the window.

---

## Install

Install **Omega Studio** from the VS Code Marketplace (search “Omega Studio”) or from the **Extensions** view, then reload the window.

---

## Wake **Omi** (enable AI)

1. In VS Code: **Command Palette** → **`Omega: AI: Configure OMEGA_AI_*…`** and follow the wizard **or** set values under **Settings → Omega Studio** (provider, model, optional base URL).  
2. API keys are stored in the **editor Secret Storage** when you use the wizard (safer than pasting into random files).  
3. Run **`Omega: AI: Doctor`** — if Omi’s environment is valid, you can use **Coach**, **Explain trace**, **Module**, and **Redesign** with **`--provider-api`** style flows from the UI.  
4. **`Omega: AI: Show saved configuration`** prints a **masked** summary to the output channel.

For a full list of environment variables, run in a terminal:

```bash
omega ai env
```

---

## Everyday examples

**New app (no AI)** — quick standard bootstrap:

- **Ω → Commands** → **Create Flutter app** → choose parent folder → project name → *without* AI kickstart.

**New app with Omi** — describe the product once:

- Configure Omi (above), then **Create Flutter app** → enable kickstart path when prompted so the CLI can run **`omega create app … --kickstart "…" --provider-api`**.

**New feature slice (templates)**:

- `cd lib` in the integrated terminal (generators use the **current directory**), then **Generate ecosystem** and enter a name (e.g. `Orders`).

**Let Omi design a full module**:

- **AI: Coach module** (or Explorer context **Create module with AI**) and describe the feature in plain language.

**Refresh only the UI of a page**:

- Open `something_page.dart` → use the **sparkle / Omega** action in the editor title **or** right‑click the file → **Redesign this screen with AI**.

**Health check before a PR**:

- **Validate** + **Doctor** from **Project** in the Ω sidebar.

---

## Links

- [omega_architecture on pub.dev](https://pub.dev/packages/omega_architecture)  
- [Repository](https://github.com/yefersonSegura/omega_architecture)  
- [Omega documentation (web)](https://yefersonsegura.com/projects/omega/)  
- Root package README for CLI and architecture overview: [README.md](../README.md)

---

## License

MIT — see [LICENSE](LICENSE).
