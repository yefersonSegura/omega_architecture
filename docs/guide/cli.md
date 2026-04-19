# Omega CLI

Run **`omega`** after `dart pub global activate omega_architecture`, or from a project:

```bash
dart run omega_architecture:omega <command> [options]
```

**Global:** `-h` / `--help`, `-v` / `--version`.

**Aliases:** `g` = `generate` = `create` for **generators only** (`g ecosystem` …). **`create app`** is separate: `omega create app <name>`.

---

## Commands (complete)

| Command | Purpose |
|---------|---------|
| **`doc`** | Open the official documentation site in the browser. |
| **`inspector`** | Open the Omega Inspector HTML (connect to Dart **VM Service**). |
| **`init`** | Create `lib/omega/omega_setup.dart` (+ `app_semantics.dart`, `app_runtime_ids.dart` if missing). **`--force`** overwrites **only** `omega_setup.dart`. |
| **`g ecosystem <Name>`** | Agent + flow + behavior + page + events; merges **`app_runtime_ids.dart`**; registers in **`omega_setup.dart`**. |
| **`g agent <Name>`** | Agent + behavior only; merges agent id. |
| **`g flow <Name>`** | Flow only; merges flow id (expects an existing `*_agent` for the module). |
| **`validate`** | Lint **`omega_setup.dart`**: structure, duplicates, routes vs `*Page`, cold-start **`initialFlowId`** / **`initialNavigationIntent`** when routes + flows exist, navigate intents vs **`OmegaRoute` ids**. Optional path root for monorepos. |
| **`trace view <file.json>`** | Human-readable summary of a recorded session. |
| **`trace validate <file.json>`** | Validate trace JSON shape (exit code for CI). |
| **`doctor [path]`** | Project health report; optional start folder (e.g. `example`). |
| **`create app <name>`** | New Flutter project with Omega wired. **`--kickstart "…"`** product context for AI. **`--provider-api`** when remote AI should run (adds deps Omi may need). |

**Working directory:** `init`, `validate`, `doctor`, `create app`, `ai …` → usually app **root** (`pubspec.yaml`). **`g …`** → folder where generated files should live (often `lib/...`).

---

## `ai` (Omi) — complete

| Subcommand | Purpose |
|------------|---------|
| **`ai doctor`** | Check `OMEGA_AI_*` env (enabled, provider, model, keys). |
| **`ai env`** | Print supported env variable names and hints. |
| **`ai explain <file.json>`** | Explain a trace: offline heuristics; add **`--provider-api`** for remote model. **`--json`** machine output. **`--stdout`** print instead of temp file. |

**`ai coach`** — first token is the mode:

| Mode | Purpose |
|------|---------|
| **`start`** | Guided implementation plan for a feature (quoted description). |
| **`audit`** | Audit project gaps for a feature. |
| **`module`** | Generate / evolve a full ecosystem module with Omi. |
| **`redesign`** | Regenerate **`ui/*_page.dart` only** (agent / flow / behavior / events unchanged). **Requires `--provider-api`.** |

**Coach flags (common):** `--json`, `--provider-api`, `--stdout`, **`--template basic|advanced`**, **`--module <name>`** / **`-m <name>`** (target module for `module` / `redesign`).

```bash
dart run omega_architecture:omega ai doctor
dart run omega_architecture:omega ai env
dart run omega_architecture:omega ai explain ./trace.json --json
dart run omega_architecture:omega ai coach start "two-factor auth"
dart run omega_architecture:omega ai coach audit "auth"
dart run omega_architecture:omega ai coach module "Orders: list and detail" --template advanced --provider-api
dart run omega_architecture:omega ai coach redesign "Auth: search bar" --template advanced --provider-api
```

Env overview: run **`omega ai env`**. Package / heal tuning variables are listed there.

---

## More help

- **Inspector:** [Inspector & VM Service](./inspector)
- **Spanish (PATH, tables, edge cases):** [COMANDOS_CLI](/doc/COMANDOS_CLI) (synced from `doc/`)
