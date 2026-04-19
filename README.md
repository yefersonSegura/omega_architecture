# Ω Omega Architecture

<p align="center">
  <img src="assets/omega_logo.svg" alt="Omega Architecture Logo" width="220">
</p>

[![pub package](https://img.shields.io/pub/v/omega_architecture.svg)](https://pub.dev/packages/omega_architecture)
[![documentation](https://img.shields.io/badge/docs-API%20%26%20web-blue)](https://pub.dev/documentation/omega_architecture/latest)

**Omega** is a reactive, agent-based architecture for **Flutter**: your screens stay thin, business rules live in **flows** and **agents**, and everything talks through one **event channel**. You get predictable navigation, easier testing, and a CLI that scaffolds features and optional **AI** helpers when you want them.

---

## Why teams pick Omega

| You want… | Omega gives you… |
|-----------|------------------|
| UI that does not own business logic | **Intents** from the UI; **flows** decide what happens next |
| One place to “hear” the app | **`OmegaChannel`** for events; agents subscribe and react |
| Safer refactors | **Typed events / intents**, optional **contracts** (debug warnings) |
| Debug weird state | **Inspector** (overlay, launcher, or browser + VM Service) and **time-travel** traces |
| Speed when starting features | **`omega g ecosystem`** + optional **`omega ai coach …`** |

---

## Install in 60 seconds

**Option A — global CLI** (run `omega` from any folder):

```bash
dart pub global activate omega_architecture
# Bleeding edge from the repository:
# dart pub global activate --source git https://github.com/yefersonSegura/omega_architecture.git
```

Add Pub’s global `bin` to your `PATH` (Windows: `%LOCALAPPDATA%\Pub\Cache\bin` · macOS/Linux: `$HOME/.pub-cache/bin`), then:

```bash
omega create app my_app
cd my_app && flutter run
```

**Option B — add to an existing Flutter app** in `pubspec.yaml`:

```yaml
dependencies:
  omega_architecture: ^1.0.4
```

Then from your **app root**:

```bash
dart run omega_architecture:omega init
```

---

## Troubleshooting: omega command not found

`dart pub global activate …` installs a launcher into Pub’s **global `bin`**. If the shell says **`omega: command not found`** (common on **Windows** and **Git Bash**), the directory is usually not on **`PATH`**, or the terminal was opened **before** you fixed `PATH`.

1. **Confirm the package is active**  
   `dart pub global list` — you should see `omega_architecture`.

2. **Confirm the launcher exists**  
   - **Windows (cmd):** `dir "%LOCALAPPDATA%\Pub\Cache\bin\omega.bat"`  
   - **PowerShell:** `Test-Path "$env:LOCALAPPDATA\Pub\Cache\bin\omega.bat"`  
   - **Git Bash:** `ls "/c/Users/$USER/AppData/Local/Pub/Cache/bin/omega"` (adjust drive/user if needed).

3. **Put Pub’s global `bin` on your `PATH`**, then open a **new** terminal (otherwise Windows prints *`omega` is not recognized…* even right after a successful `dart pub global activate`).

   **Windows**
   - Pub installs shims such as `omega.bat` under **`%LOCALAPPDATA%\Pub\Cache\bin`**, which is the same folder Pub mentions in the warning *“installs executables into … which is not on your path”* — for example  
     **`C:\Users\<YourWindowsUser>\AppData\Local\Pub\Cache\bin`**.
   - Add **that directory** to your **user** **`Path`** (not only system-wide if your user `Path` overrides expectations):
     1. Press **Win**, search **environment variables**, open **Edit the system environment variables** → **Environment Variables…**, *or* **Edit environment variables for your account**.
     2. Under **User variables for …**, select **`Path`** → **Edit** → **New**.
     3. Enter **`%LOCALAPPDATA%\Pub\Cache\bin`** (or paste the full path Pub showed, ending in `\Pub\Cache\bin`).
     4. **OK** all dialogs, then **close every** cmd / PowerShell / IDE terminal and open a **new** one.
   - Verify: **`where omega`** (cmd) should list `omega.bat`, or run **`omega --help`**.

   **macOS / Linux:** `export PATH="$PATH:$HOME/.pub-cache/bin"` in `~/.zshrc` / `~/.bashrc`, or your shell’s equivalent.

4. **Git Bash on Windows** often does not pick up a freshly edited Windows `PATH` until **Cursor/VS Code / Terminal is fully restarted**. If it still fails, append Pub’s `bin` explicitly (use your real username):

   ```bash
   export PATH="$PATH:/c/Users/YOUR_USER/AppData/Local/Pub/Cache/bin"
   ```

5. **Without `omega` on `PATH` (after global activate)** — Pub does **not** support **`dart pub global run`** nor **`flutter pub global run`** for packages that depend on the Flutter SDK (same error: *“requires the Flutter SDK, which is unsupported for global executables”*). Use one of these:

   - **Windows (cmd):** run the shim by full path, from your app root:

     ```bat
     "%LOCALAPPDATA%\Pub\Cache\bin\omega.bat" validate
     ```

   - **Any OS:** add Pub’s global `bin` to `PATH` (step 3 above), then use `omega …` as usual.

   - **From a project** that lists `omega_architecture` in `pubspec.yaml`: `dart run omega_architecture:omega …` (uses that app’s Flutter toolchain).

6. **Multiple Dart / Flutter installs (FVM, etc.)**  
   Use **`where flutter`** / **`which flutter`** and run **`flutter pub global activate …`** with the same toolchain you use for your apps. Activating with one SDK and running the shim with another can break.

---

## AI kickstart (optional)

Describe the product once; the CLI can scaffold agents, flows, behavior, and pages (requires provider config and network when using `--provider-api`):

```bash
export OMEGA_AI_ENABLED=true
export OMEGA_AI_PROVIDER=openai
export OMEGA_AI_API_KEY=sk-...
omega create app my_store --kickstart "e-commerce with cart and checkout" --provider-api
```

Plain **`omega create app my_store`** still gives you Flutter + Omega wired up, without AI-generated modules.

---

## Mental model (one paragraph)

The **UI** sends **intents** (“log in”, “open settings”). The **`OmegaFlowManager`** delivers those intents to the right **flow(s)**. **Flows** coordinate steps and talk to **agents** through the **`OmegaChannel`**. **Agents** run domain logic via a **behavior engine**. Flows emit **expressions** (loading, success, navigation, etc.) and the UI rebuilds with **`OmegaBuilder`** or your navigator. Nothing in the widget tree needs to call repositories directly.

For a **walkthrough with code for each piece**, see **[doc/GUIA.md](doc/GUIA.md)**.

---

## Framework capabilities (with tiny examples)

**Channel + event** — publish once, many listeners:

```dart
final channel = OmegaChannel();
channel.emit(const OmegaEvent(id: '1', name: 'greet'));
```

**Agent + behavior** — rules return reactions; the agent runs actions:

```dart
class GreetBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    if (ctx.event?.name == 'greet') {
      return const OmegaAgentReaction('sayHello', payload: 'Welcome!');
    }
    return null;
  }
}
```

**Flutter wiring** — scope provides channel + flow manager to the tree:

```dart
OmegaScope(
  channel: myChannel,
  flowManager: myFlowManager,
  child: const MyApp(),
);
```

**UI reacts to one event name** — no `setState` scattered everywhere:

```dart
OmegaBuilder(
  eventName: 'user.updated',
  builder: (context, event) {
    return Text('User: ${event?.payload['name']}');
  },
);
```

**Also included** (details in docs linked below):

- **Stateful agents** — typed `viewState` stream for UI-friendly agent state  
- **Workflow flows** — multi-step processes (`defineStep`, `next`, …)  
- **Typed routes** — `OmegaRoute.typed<T>` and `routeArguments<T>`  
- **Persistence** — `OmegaAppSnapshot` save/restore across launches  
- **Time-travel** — record channel sessions to JSON, replay for demos or bugs  
- **Contracts** — declare what each flow/agent may receive or emit; get **debug** warnings when something drifts  

---

## Omega CLI — what to run and when

Run from a project that **depends** on `omega_architecture` (or use the globally activated `omega`):

```bash
dart run omega_architecture:omega <command> [options]
```

**Important:** `omega init` and `omega g …` look for **`lib/omega/omega_setup.dart`**. Generators write files into the **current working directory** (often `lib/`), then patch `omega_setup.dart` for you.

| Command | When you use it | Example |
|--------|-------------------|---------|
| **`doc`** | Open the official site in the browser | `dart run omega_architecture:omega doc` |
| **`inspector`** | Paste your VM Service URL and inspect flows/events | `dart run omega_architecture:omega inspector` |
| **`init`** | First-time Omega file in an existing app | `dart run omega_architecture:omega init` |
| **`init --force`** | Regenerate `omega_setup.dart` (overwrites) | `dart run omega_architecture:omega init --force` |
| **`g ecosystem <Name>`** | New feature: agent + flow + behavior + page | `cd lib && dart run omega_architecture:omega g ecosystem Orders` |
| **`g agent <Name>`** | Only a new agent (+ behavior) | `dart run omega_architecture:omega g agent Notifications` |
| **`g flow <Name>`** | Only a new flow | `dart run omega_architecture:omega g flow Checkout` |
| **`validate`** | `omega_setup.dart` structure, duplicates, route↔page agent wiring; **with any routes + flows**, requires **`initialFlowId`** + **`initialNavigationIntent`**; validates **`navigateLogin` / `navigateHome` / `navigateRoot`** vs `OmegaRoute` ids when referenced | `dart run omega_architecture:omega validate` |
| **`doctor`** | Human-readable health + counts | `dart run omega_architecture:omega doctor` |
| **`trace view`** | Summarize a saved session JSON | `dart run omega_architecture:omega trace view ./trace.json` |
| **`trace validate`** | Check trace file shape (exit code for CI) | `dart run omega_architecture:omega trace validate ./trace.json` |
| **`create app`** | New Flutter app with Omega pre-wired | `omega create app my_app` |

Aliases: `g` = `generate` = `create` for generators.

### AI commands (optional)

| Command | What it does | Example |
|--------|----------------|---------|
| **`ai doctor`** | Is AI env configured? | `dart run omega_architecture:omega ai doctor` |
| **`ai env`** | Print supported env vars | `dart run omega_architecture:omega ai env` |
| **`ai explain <file.json>`** | Heuristic (or provider) report from a trace | `dart run omega_architecture:omega ai explain trace.json --provider-api` |
| **`ai coach start`** | Step-by-step plan for a feature | `dart run omega_architecture:omega ai coach start "two-factor auth"` |
| **`ai coach audit`** | Score gaps in the repo for a feature | `dart run omega_architecture:omega ai coach audit "auth"` |
| **`ai coach module`** | Generate or evolve a full module | `dart run omega_architecture:omega ai coach module "Orders: list and detail" --provider-api` |
| **`ai coach redesign`** | Regenerate **UI pages only** for a module | `dart run omega_architecture:omega ai coach redesign "Auth: darker theme"` |

Typical AI env vars: `OMEGA_AI_ENABLED`, `OMEGA_AI_PROVIDER` (`openai`, `anthropic`, `gemini`, `ollama`, `none`), `OMEGA_AI_API_KEY`, `OMEGA_AI_MODEL`, `OMEGA_AI_BASE_URL`. Optional language override: `OMEGA_AI_LANG` / `OMEGA_AI_LANGUAGE`.

---

## Inspector (debug only)

Three common patterns:

1. **Overlay** — `OmegaInspector(eventLimit: 20)` in a `Stack`  
2. **Launcher** — `OmegaInspectorLauncher()` in an `AppBar` (dialog or web tab)  
3. **Browser + VM** — `OmegaInspectorServer.start` prints a URL; or run **`omega inspector`** and paste the VM Service URL from `flutter run`  

```dart
if (kDebugMode)
  AppBar(
    title: const Text('My App'),
    actions: [OmegaInspectorLauncher()],
  )
```

**Local (embedded)** — flows sidebar, event list, JSON detail:

![Local Inspector](assets/inspector_local.png)

**Online (same UI in the browser + VM Service)**:

![Online Inspector](assets/inpector_online.png)

Full copy-paste steps: **[doc/INSPECTOR.md](doc/INSPECTOR.md)**. Release builds stay lean (Inspector is guarded by `kDebugMode`).

---

## Flow activation & persistence (cheat sheet)

- **Several flows listening:** `flowManager.activate('flowId')` for each.  
- **One “main” flow:** `flowManager.switchTo('flowId')` pauses the others.  
- **Save / restore:** `flowManager.getAppSnapshot().toJson()` → persist → `OmegaAppSnapshot.fromJson` → `flowManager.restoreFromSnapshot(snapshot)`.  

---

## Example app

The **`example/`** project is the reference: login UI, **AuthFlow**, **AuthAgent**, typed payloads, contracts, and routes.

```bash
cd example && flutter run
```

Key files: [omega_setup.dart](example/lib/omega/omega_setup.dart), [auth_flow.dart](example/lib/auth/auth_flow.dart), [auth_agent.dart](example/lib/auth/auth_agent.dart), [auth_page.dart](example/lib/auth/ui/auth_page.dart).

---

## Documentation index

| Doc | Use it for |
|-----|------------|
| [doc/GUIA.md](doc/GUIA.md) | Guided tour + examples per component |
| [doc/COMANDOS_CLI.md](doc/COMANDOS_CLI.md) | CLI tables and extended command notes |
| [doc/INSPECTOR.md](doc/INSPECTOR.md) | Inspector setup and troubleshooting |
| [doc/CONTRACTS.md](doc/CONTRACTS.md) | Declarative flow/agent contracts |
| [doc/TIME_TRAVEL.md](doc/TIME_TRAVEL.md) | Record / replay sessions |
| [doc/ARQUITECTURA.md](doc/ARQUITECTURA.md) | Deep technical reference |
| [doc/COMPARATIVA.md](doc/COMPARATIVA.md) | Comparison with other approaches |
| [doc/TESTING.md](doc/TESTING.md) | Testing agents and flows |
| [doc/ROADMAP.md](doc/ROADMAP.md) | Long-term direction |
| [API on pub.dev](https://pub.dev/documentation/omega_architecture/latest) | Generated API reference |
| [Web documentation (VitePress)](https://yefersonsegura.github.io/omega_architecture/) | Guide site (same stack as Omega Angular `docs/`) |

**How the web docs are published:** [`.github/workflows/docs.yml`](.github/workflows/docs.yml) pushes the VitePress build to branch **`gh-pages`**. Each successful run prints **where** in the log (**“Push dist to gh-pages”** — banner with URLs) and in the **Actions** run **Summary** tab (table: branch, link to `tree/gh-pages`, public URL). GitHub only serves **`https://yefersonsegura.github.io/omega_architecture/`** after **Settings → Pages** → **Deploy from a branch** → **`gh-pages`** → **`/ (root)`**. **Settings → Actions → General** → **Read and write** so the workflow can push.

---

## Package layout (library)

```
lib/
├── omega/
│   ├── core/       # Channel, events, intents
│   ├── agents/     # Agents, behaviors
│   ├── flows/      # Flows, manager, expressions
│   ├── ui/         # Scope, builder, navigation helpers
│   └── bootstrap/  # Config, runtime
└── omega_architecture.dart
```

---

## License

MIT — see [LICENSE](LICENSE).
