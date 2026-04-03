## 0.0.27 (Autonomous Self-Healing)

- **Self-Healing Project Creation:** `omega create app` now automatically runs `dart analyze` after generation.
    - If compilation errors are found, the CLI uses AI to diagnose and **auto-fix** the code.
    - Ensures the generated project is 100% functional and error-free without manual intervention.
- **Improved AI Logic:** More precise prompts for AI-generated modules to minimize syntax errors.

## 0.0.26 (CLI Robustness & UX)

- **`omega create app` improvements:**
    - **Widget Test Fix:** The generator now correctly overwrites `test/widget_test.dart` with a compatible smoke test using `OmegaApp` and `OmegaRuntime`.
    - **Automatic Route Registration:** New modules generated via `g ecosystem` (including AI kickstart) now automatically register their primary route and UI import in `omega_setup.dart`.
    - **Windows Robustness:** Improved path resolution and added forced file overwriting for a cleaner initial setup.
- **Documentation & AI configuration:**
    - **Quick Start:** Added a dedicated section to `README.md` and web docs for instant onboarding.
    - **AI Configuration Guide:** Detailed instructions for setting up `OMEGA_AI_API_KEY` and other environment variables in `doc/GUIA.md` and `README.md`.
    - **Web Docs Enhancement:** Added "Steps for Success" to the CLI command panels.

## 0.0.25 (Orchestration & App Creation)

- **omega create app:** New top-level CLI command to bootstrap a full Flutter project with Omega pre-configured.
- **AI Kickstart:** Generates real business logic (agents, flows, UI) based on descriptions.
- **Widget Test Fix:** The generator now correctly overwrites `test/widget_test.dart` with a compatible smoke test, avoiding `MyApp` errors.
- **AI Auth Fix:** Corrected `$apiKey` escaping in provider calls.
- **OmegaNavigator compatibility:** Added `onGenerateRoute` support.
- **Exported Bootstrap:** `OmegaRuntime` and `OmegaConfig` are now exported from the main entry point.

## 0.0.24
- The official Omega documentation was added.

## 0.0.23 (AI Evolution)

- **omega ai coach module:** New AI-guided command to generate complete ecosystems with advanced boilerplate. Use `--template advanced` to generate `OmegaWorkflowFlow`, `OmegaStatefulAgent`, typed events, declarative contracts, and initial test files.
- **AI-assisted diagnosis and auditing:** Added `omega ai coach start` (step-by-step guidance) and `omega ai coach audit` (project gap analysis for features).
- **Plug-and-play UI templates:** Generated UI pages now dynamically connect to `OmegaFlowManager` via `OmegaScope` and use `StreamBuilder<OmegaFlowExpression>` for a reactive, decoupled experience.
- **Improved generator accuracy:** Fixed null-safety issues (`ctx.intent?.name`) and API usage (`OmegaEvent.fromName`) in all generated templates.
- **AI CLI output options:** AI commands now default to opening a temporary Markdown report in the editor for better readability, with a `--stdout` flag for console output.
- **Localization for AI:** AI reports and CLI messages now respect system locale or `OMEGA_AI_LANG` environment variables.

## 0.0.22

- **Reactive agent state (optional):** Added [OmegaStatefulAgent] and [OmegaAgentBuilder]. Agents can expose a typed reactive `viewState` (`stateStream`) for UI widgets while preserving Omega’s core event/intent model.
- **Workflow engine flow (optional):** Added [OmegaWorkflowFlow] for explicit step-based flows with `defineStep`, `startAt`, `next`, `failStep`, and `completeWorkflow` to model multi-step processes (e.g. checkout/onboarding) without replacing [OmegaFlow].
- **Example auth updated:** `example/lib/auth` now demonstrates reactive agent state in practice (`AuthAgent` + `AuthViewState` + `OmegaAgentBuilder` in login UI) with flow semantics kept focused on milestones.

## 0.0.21

- **Typed events (OmegaTypedEvent + emitTyped):** New [OmegaTypedEvent] interface and [OmegaEventBus.emitTyped] method so you can model events as classes (e.g. `LoginRequestedEvent`) instead of plain string names with loose payloads. The channel wraps them into [OmegaEvent] with the instance as payload; listeners use `event.payloadAs<LoginRequestedEvent>()` for full type safety. Example app updated (AuthFlow, AuthAgent, `auth/models.dart`) and tests added in `omega_channel_test.dart`.
- **Docs (GUIA, README, ROADMAP):** [doc/GUIA.md](doc/GUIA.md) now has a dedicated “Eventos tipados (clase como evento)” section with a full example; README’s feature list highlights typed events as the recommended style; [doc/ROADMAP.md](doc/ROADMAP.md) marks typed events as completed under “Contratos y convenciones”.
- **Web docs — What’s new section:** `presentation/index.html` and `index-en.html` include a new “Nuevas mejoras / What’s new” slide with a collapsible block per version (`<details><summary>…</summary>`) starting with 0.0.21 and a concrete code snippet for `LoginRequestedEvent + emitTyped`. Future releases can append new collapsibles there.
- **Analytics for documentation site:** Both `presentation/index.html` and `index-en.html` now embed Google Analytics 4 (`G-Q2XTRMEHHH`) so you can track visits to the Omega documentation pages.

## 0.0.20

- **Inspector (VM Service + public web):** [OmegaInspectorServer] now exposes Omega state via a VM Service extension instead of a local HTTP server. On Android/iOS/desktop it prints a URL of the form `http://yefersonsegura.com/projects/omega/inspector.html#<encoded-VM-URL>` that opens the online Inspector and auto-connects; no `adb reverse` is required.
- **Inspector CLI:** New CLI command `omega inspector` opens the hosted Inspector page in the browser. When combined with the URL printed by [OmegaInspectorServer], you can debug a device from the PC without searching for the HTML file.
- **Inspector UI refresh (web + public):** `presentation/inspector.html` and the web receiver (`OmegaInspectorReceiver` in `omega_inspector_receiver_web.dart`) share a modern dark dashboard layout: flows sidebar, events list with timeline, and a JSON details panel for the selected event/flow. Layout adapts to desktop, tablet and mobile widths.
- **Inspector server (web stub):** When [OmegaInspectorServer.start] is called on web, a debug message is printed explaining that the server is not available on web and to use [OmegaInspectorLauncher] instead.


## 0.0.19

- **Channel namespaces:** [OmegaChannel.namespace](lib/omega/core/channel/omega_channel.dart) and [OmegaChannelNamespace] for scoped events (e.g. `auth`, `checkout`). [OmegaEvent] and [OmegaIntent] have optional `namespace`; [OmegaEventBus] abstraction so [OmegaFlow] and [OmegaAgent] accept either the global channel or a namespace view. Example app uses namespaces per domain (auth, provider, orders). ROADMAP and [doc/GUIA.md](doc/GUIA.md) updated.
- **Inspector server (web stub):** When [OmegaInspectorServer.start] is called on web, a debug message is printed explaining that the server is not available on web and to use [OmegaInspectorLauncher] instead.
- **Inspector example and docs:** Example app shows overlay + launcher + server in debug; [doc/INSPECTOR.md](doc/INSPECTOR.md) added with full copy-paste guide (overlay, launcher, server) and "Inspector not showing" troubleshooting.
- **Inspector server (IO) encoding fix:** Events whose payload is an [OmegaIntent] (e.g. `navigation.intent`) are now serialized safely for WebSocket broadcast; fixes "Converting object to an encodable object failed: Instance of 'OmegaIntent'" when running on mobile or desktop with the Inspector server.

## 0.0.18

- **CLI:** Wrapped single-statement `if` body in `omega doctor` in a block to satisfy `curly_braces_in_flow_control_structures` lint.

## 0.0.17

- **OmegaInspectorServer:** Inspector in browser (desktop/mobile): [OmegaInspectorServer.start](lib/omega/ui/flutter/omega_inspector_server.dart) runs an HTTP/WebSocket server so you can open the Inspector at e.g. `http://localhost:9292` without the in-app overlay. Stub on web (no-op). Example and [doc/GUIA.md](doc/GUIA.md) updated.
- **Inspector safe for production:** [OmegaInspector], [OmegaInspectorLauncher], [OmegaInspectorReceiver] and [OmegaInspectorServer] guard with `kDebugMode`: in release they do not subscribe, show the button, or start the server; receiver shows a short message. No inspector code runs in production.
- **CLI:** Replaced `print` with `stdout.writeln` in `bin/omega.dart` to satisfy the `avoid_print` lint.
- **Docs:** README and example/README with Inspector usage (overlay, launcher, server). Web docs (ES/EN): "Uso del Inspector" in OmegaScope section and API section updated with OmegaInspectorServer and release behavior.

## 0.0.16

- **omega trace:** CLI command `omega trace view <file.json>` (trace summary: events, initial snapshot) and `omega trace validate <file.json>` (validates structure; exit 0/1). Trace files are generated by saving [OmegaRecordedSession.toJson()] (e.g. after [OmegaTimeTravelRecorder.stopRecording]).
- **omega doctor:** CLI command that checks project health: validates `omega_setup.dart` (structure, duplicate IDs) and optionally lists flows/agents without a contract (recommendation).
- **Trace serialization:** [OmegaEvent.toJson]/[OmegaEvent.fromJson] and [OmegaRecordedSession.toJson]/[OmegaRecordedSession.fromJson] to save and load recorded sessions (time-travel, debugging).
- **CLI documentation:** CLI section on the web (ES/EN) in tabs (doc, init, g ecosystem, g agent, g flow, validate, trace, doctor) with "Why", instruction (both forms when applicable), concept and examples. README: commands listed one under the other with **Why**, instruction, concept and examples; `omega doctor` and `omega init` in both forms (with/without path, with/without `--force`).
- **Export session to JSON:** In [doc/TIME_TRAVEL.md](doc/TIME_TRAVEL.md) section "Export session to JSON (trace file)" with examples for mobile (path_provider + File), web (blob + download) and minimal usage. README and trace tab on the web with snippet and link to TIME_TRAVEL.md.
- **Example:** Contracts added to OrdersFlow, ProviderFlow and ProviderAgent so `omega doctor` does not list them under "Optional (contracts)".

## 0.0.15

- **Inspector:** Visual tweaks for a cleaner, more modern look (softer colors, fewer shadows, clearer separation between event list and flow state), keeping all previous functionality.

## 0.0.14

- **Declarative contracts:** [OmegaFlowContract] and [OmegaAgentContract] to declare which events a flow listens to, which intents it accepts, and which expression types it emits (and for agents: events and intents). In debug mode Omega warns in the console when something undeclared is received or emitted. Optional `contract` override on [OmegaFlow] and [OmegaAgent]; empty sets = no restriction. Factory `fromTyped` for [OmegaEventName]/[OmegaIntentName] enums.
- **Time-travel:** [OmegaTimeTravelRecorder] records channel events and an initial snapshot; [OmegaRecordedSession] stores them. `replay(session, channel, flowManager, upToIndex: n)` restores the snapshot and re-emits events up to index n for debugging or reproducing a session. See [doc/TIME_TRAVEL.md](doc/TIME_TRAVEL.md). Web (presentation): "Time-travel" section in Spanish and English.
- **Offline-first (infra):** New types [OmegaQueuedIntent], [OmegaOfflineQueue] and [OmegaMemoryOfflineQueue] to queue intents when the network fails and re-emit them when connectivity is restored. Example in `example/` (`OrdersFlow` + "Crear pedido (offline demo)" button on `HomePage`).
- **Inspector / DevTools:** Cleaner dashboard-style inspector: two columns (events on the left, flow state on the right) with a small timeline of recent events above the list, in both overlay and web window.
- **Docs:** [doc/CONTRACTS.md](doc/CONTRACTS.md) with guide and examples; [doc/TIME_TRAVEL.md](doc/TIME_TRAVEL.md) and Offline-first section in [doc/GUIA.md](doc/GUIA.md); web (presentation) with glossary and mentions of contracts, time-travel, offline queue and timeline.

## 0.0.13

- **Pub.dev:** README with https links only (documentation points to pub.dev API reference). CLI: `if` body in `bin/omega.dart` wrapped in a block to pass the lint and recover points.

## 0.0.12

- **Favicon:** SVG favicon with Omega symbol drawn by path (no font dependency). Link in `presentation/index.html`.
- **CLI:** Command `omega doc` opens the official web documentation in the browser.
- **Web documentation:** Reading progress bar, copy button on code blocks, light/dark theme with persistence, scroll-to-top button, SEO meta, breadcrumbs, footer with version, accessibility (skip-link, focus-visible). Font Awesome icons in sidebar and navigation.
- **Docs:** GUIA.md, README with documentation badge, example with link to docs. pubspec: documentation, issue_tracker.

## 0.0.11

- **Documentation:** [doc/COMPARATIVA.md](doc/COMPARATIVA.md) with Omega vs BLoC vs Riverpod comparison and when to choose each. Web (presentation) declared as full documentation; "Comparativa" link in navigation. README and ROADMAP updated.
- **Inspector:** Modern design (blue theme, gradients, shadowed cards, pills for state and counts). Same style in overlay and remote (web) window.
- **Inspector web:** When closing the inspector window and reopening, a unique window name is used so the browser opens a new window correctly.

## 0.0.10

- **Pub.dev static analysis:** Inspector web migrated from `dart:html` to `package:web` and `dart:js_interop` to remove deprecation INFO and recover 10 points on "Pass static analysis". Dependency `web: ^1.0.0` added.

## 0.0.9

- **Typed events and intents:** [OmegaEventName] and [OmegaIntentName] (interfaces) + [OmegaEvent.fromName] and [OmegaIntent.fromName] to use enums or classes and avoid magic strings (autocomplete, refactors). Documentation in README, ARQUITECTURA and ROADMAP; tests in omega_channel_test and omega_intent_test.
- **Example:** `example/lib/omega/app_semantics.dart` with AppEvent and AppIntent enums; main, auth_flow, auth_agent, auth_behavior and auth_page use fromName and typed names. example/README.md updated.

## 0.0.8

- **Persistence and restore:** Snapshot serialization with `OmegaFlowSnapshot.toJson`/`fromJson` and `OmegaAppSnapshot.toJson`/`fromJson`. `OmegaFlow.restoreMemory` and `OmegaFlowManager.restoreFromSnapshot` to restore state when opening the app. Optional `OmegaSnapshotStorage` interface (save/load). Documentation in README, ARQUITECTURA and ROADMAP.
- **Pub.dev:** `dependency_overrides: meta: ^1.18.1` to pass "Support up-to-date dependencies" in static analysis.

## 0.0.7

- **Inspector in separate window (web, Isar-style):** [OmegaInspectorLauncher] opens the inspector in another browser tab/window; the app sends data via BroadcastChannel. [OmegaInspectorReceiver] shows events and snapshots in that window. On non-web platforms the launcher opens the inspector in a dialog. Documentation in README and ARQUITECTURA.

## 0.0.6

- **CLI fix:** When running `g agent <Name>` or `g flow <Name>` separately, the CLI now only removes and re-adds the import for the artifact being registered (agent or flow), so the other import is preserved. Previously, running `g flow Orders` after `g agent Orders` could remove the agent import.
- **Snapshot (Step 2):** `OmegaFlowSnapshot` and `OmegaAppSnapshot` for debugging, persistence, and time-travel. `OmegaFlow.getSnapshot()`, `OmegaFlowManager.getFlowSnapshot`, `getSnapshots`, `getAppSnapshot`. Documentation of purpose in dartdoc and ARQUITECTURA.
- **Logging (Step 3):** Replaced `print` with `debugPrint` in `omega_navigator.dart` and `omega_bootstrap.dart` (lib) so diagnostics only appear in debug mode.
- **Navigation (Step 4):** Contract documented (`navigation.intent`, `navigate.*`). `navigate.<id>` = pushReplacement, `navigate.push.<id>` = push. Intent payload passed as `RouteSettings.arguments`. Constant `navigationIntentEvent`.
- **Testing (Step 5):** More unit tests (agent receiveIntent, flow receiveIntent running/idle, OmegaFlowExpression). `example/README.md` for minimal login flow. `doc/TESTING.md` for testing agents and flows without Flutter.
- **CLI (Step 6):** Clearer error messages (prefix "Error:", absolute paths). New generators: `omega g agent <Name>`, `omega g flow <Name>`. `omega validate` checks omega_setup.dart (structure, duplicate ids). All generators create files in the terminal's current directory (CWD).
- **Docs:** ARQUITECTURA.md and README kept in sync with snapshot, navigation, testing, and CLI.

## 0.0.5

- Fix static analysis: enclose `while` body in a block in `bin/omega.dart` (pub.dev lint).

## 0.0.4

- CLI `g ecosystem`: create files in the **current directory** (where you run the command), not forced under `lib/`.
- CLI: refresh imports in `omega_setup.dart` (replace old paths with the correct one for the ecosystem).
- CLI: register both **Agent** and **Flow** in `OmegaConfig`; add `flows:` section if missing in `omega_setup.dart`.
- Docs: README and web updated with CLI behavior (CWD, path refresh, flow registration).

## 0.0.3

- Add official example in `example/lib/main.dart` for pub.dev scoring.
- Tweak documentation (README and website) to point to pub.dev installation.

## 0.0.2

- Publish on pub.dev and switch doc/install to pub.dev usage (`omega_architecture: ^0.0.2`).
- Add web documentation (presentation) and architecture diagram.
- Improve CLI behavior (flows/agents registration, no auto-route creation).
- Clarify runtime bootstrap and flow activation from the app host.

## 0.0.1

- Initial release of Omega Architecture: core agents/flows/channel runtime, basic CLI and auth example.
