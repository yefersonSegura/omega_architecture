# Ω Omega Architecture

[![pub package](https://img.shields.io/pub/v/omega_architecture.svg)](https://pub.dev/packages/omega_architecture) [![documentation](https://img.shields.io/badge/docs-API%20%26%20web-blue)](https://pub.dev/documentation/omega_architecture/latest)

A reactive, agent-based architecture framework for Flutter applications.

**What Omega does:** Business logic lives in **agents** and **flows** that communicate through a central **event channel**. The UI only emits **intents** (e.g. "login", "navigate to home") and reacts to **events** and **expressions**; it does not call domain methods or hold navigation state. A **FlowManager** routes intents to the active flow(s); a **navigator** turns navigation intents into screens. So you get a clear separation: UI → intents/events → flows and agents → expressions/navigation → UI. For a **guided tour with examples** of each component, see **[docs/GUIA.md](docs/GUIA.md)**.

## Features

- **Reactive Agents** — Autonomous entities that react to system events and direct messages.
- **Behavior Engine** — Decoupled logic using rules and conditions to determine agent reactions.
- **Event-Driven** — Global communication through `OmegaChannel`.
- **Flow Management** — Orchestrate complex state transitions and business logic flows; run one or multiple flows at once.
- **Semantic Intents** — High-level abstraction for user or system requests. Optional **typed names** via [OmegaEventName]/[OmegaIntentName] and [OmegaEvent.fromName]/[OmegaIntent.fromName] to avoid magic strings and ease refactors. **Typed payload when reading:** use the `payloadAs<T>()` extension on [OmegaEvent], [OmegaIntent], and [OmegaFlowExpression] to get a safely cast payload. See the [example](example/lib/omega/app_semantics.dart) for full usage (`AppEvent` / `AppIntent` enums).
- **Persistence & restore** — Serialize [OmegaAppSnapshot] to JSON and restore on launch ([toJson]/[fromJson], [OmegaFlowManager.restoreFromSnapshot], optional [OmegaSnapshotStorage]).
- **Typed routes** — Use `OmegaRoute.typed<T>` so the route builder receives the intent payload as `T?`; or `routeArguments<T>(context)` when you don't use typed. See the [example](example/lib/omega/omega_setup.dart) (home route with `LoginSuccessPayload`).
- **Declarative contracts** — Optional [OmegaFlowContract] and [OmegaAgentContract] declare which events a flow listens to, which intents it accepts, and which expression types it emits (and for agents: events and intents). In **debug** mode Omega warns in the console when something is received or emitted that is not in the contract. **Example:** The [example](example/) app implements contracts in [AuthFlow](example/lib/auth/auth_flow.dart) and [AuthAgent](example/lib/auth/auth_agent.dart); run `cd example && flutter run` to see them in action. See [docs/CONTRACTS.md](docs/CONTRACTS.md).
- **CLI** — Scaffold setup and generate ecosystems (agent, flow, behavior, page) from the command line.

**Documentation:**  
- **[docs/GUIA.md](docs/GUIA.md)** — What each Omega component does, with **code examples** (channel, event, intent, agent, flow, manager, scope, navigator, routes, persistence, inspector). Start here to see how everything fits together.  
- **Documentation** — [API reference](https://pub.dev/documentation/omega_architecture/latest) (pub.dev). Full web doc (architecture, comparison, CLI, inspector): `yefersonsegura.com/proyects/omega/`. Local copy: [presentation/index.html](presentation/index.html). Run `dart run omega_architecture:omega doc` to open the doc in the browser.  
- **[docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)** — Technical reference for each component.  
- **[docs/COMPARATIVA.md](docs/COMPARATIVA.md)** — When to choose Omega; full comparison table.  
- **[docs/TESTING.md](docs/TESTING.md)** — Testing agents and flows without Flutter.  
- **[docs/CONTRACTS.md](docs/CONTRACTS.md)** — Declarative contracts for flows and agents (events, intents, expression types); debug-time validation. The [example](example/) app is the reference implementation (AuthFlow, AuthAgent).
- **[docs/ROADMAP.md](docs/ROADMAP.md)** — Long-term vision.

## Core Concepts

| Concept | Description |
|--------|-------------|
| **OmegaAgent** | Building block of the architecture. Has an ID, a channel, and a behavior engine. |
| **OmegaAgentBehaviorEngine** | Evaluates events/intents and returns reactions (actions to run). |
| **OmegaChannel** | Event bus. Agents and flows subscribe to `events` and use `emit()` to publish. |
| **OmegaFlow** | Business flow with states (idle, running, paused, etc.). Orchestrates UI and agents. |
| **OmegaFlowManager** | Registers flows, routes intents to running flows, and activates/pauses them. |

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  omega_architecture: ^0.0.11
```

## Omega CLI

The CLI helps you bootstrap Omega in your app and generate new ecosystems.

### How to run

From a project that depends on `omega_architecture`:

```bash
dart run omega_architecture:omega <command> [options] [arguments]
```

Or by path (from the `omega_architecture` repo):

```bash
dart run bin/omega.dart <command> [options] [arguments]
```

**Important:** The CLI runs in **your app’s** project (the host app that depends on `omega_architecture`). It uses the current directory to find your project root. **`omega init`** creates `lib/omega/omega_setup.dart` in your app. **`omega g ecosystem`** creates the ecosystem files in the **directory where you open the terminal** (current working directory), then finds `omega_setup.dart` in your project and registers the new agent and flow there. You own the setup and add your own routes.

### Commands

| Command | Description |
|---------|-------------|
| `init [--force]` | Creates `lib/omega/omega_setup.dart` **in your app** with an empty `OmegaConfig` (agents, flows, routes). Use `--force` to overwrite. Run from your app root. |
| `g ecosystem <Name>` | Generates agent, flow, behavior and page **in the current directory**, then registers agent and flow in `omega_setup.dart`. Run `omega init` first. |
| `g agent <Name>` | Generates only agent + behavior in the current directory and registers the agent in `omega_setup.dart`. |
| `g flow <Name>` | Generates only flow in the current directory and registers the flow in `omega_setup.dart`. |
| `validate` | Checks `omega_setup.dart`: structure (`createOmegaConfig`, `OmegaConfig`, `agents:`), duplicate agent/flow registrations. Run from app root. |

### How `g ecosystem` uses omega_setup

When you run `omega g ecosystem <Name>` from your host app:

1. The CLI resolves your **project root** (directory that contains `pubspec.yaml`).
2. It looks for **`lib/omega/omega_setup.dart`** in that project. If it doesn’t exist, it prints *"Run 'omega init' first"* and does not create any files.
3. It creates the ecosystem files (agent, flow, behavior, page) in the **current directory** (the folder where you opened the terminal).
4. It **updates** `omega_setup.dart`: removes any existing imports for that ecosystem and adds the new imports (package or relative path depending on location). It registers the **agent** and **flow** in `OmegaConfig`; if the file has no `flows:` section, it adds it with the new flow.

**`g agent` and `g flow`:** When you generate only the agent or only the flow, the CLI updates **only** that artifact’s import and registration in `omega_setup.dart`. It does not remove the other (e.g. running `g flow Orders` after `g agent Orders` keeps the agent import and only adds/refreshes the flow import). So you can create agent and flow separately for the same name without overwriting each other.

Aliases: `generate` and `create` are equivalent to `g`.

### Global options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help. |
| `-v`, `--version` | Show CLI version. |

### Examples

```bash
# First-time setup
dart run omega_architecture:omega init

# Overwrite existing setup
dart run omega_architecture:omega init --force

# Generate an ecosystem (e.g. Auth, Orders, Profile)
dart run omega_architecture:omega g ecosystem Auth
dart run omega_architecture:omega g agent Orders    # agent + behavior only
dart run omega_architecture:omega g flow Profile   # flow only

# Validate omega_setup.dart (structure, duplicate ids)
dart run omega_architecture:omega validate
```

Generated by `omega g ecosystem Auth` (in the directory where you run the command):

- `auth/auth_agent.dart`, `auth/auth_flow.dart`, `auth/auth_behavior.dart`
- `auth/ui/auth_page.dart`
- **Updates to `lib/omega/omega_setup.dart`**: the CLI finds this file in your app, refreshes the imports for this ecosystem (correct path), and registers the new **agent** and **flow** in `OmegaConfig` (adds `flows:` if it was missing).

## Usage

### Agent and behavior

```dart
class MyBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    if (ctx.event?.name == "greet") {
      return const OmegaAgentReaction("sayHello", payload: "Welcome!");
    }
    return null;
  }
}

class MyAgent extends OmegaAgent {
  MyAgent(OmegaChannel channel)
      : super(id: "my_agent", channel: channel, behavior: MyBehavior());

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {
    if (action == "sayHello") print(payload);
  }
}

void main() {
  final channel = OmegaChannel();
  final agent = MyAgent(channel);
  channel.emit(const OmegaEvent(id: "1", name: "greet"));
}
```

### Flutter: OmegaScope and OmegaBuilder

Wrap your app with `OmegaScope` to provide `OmegaChannel` and `OmegaFlowManager`:

```dart
OmegaScope(
  channel: myChannel,
  flowManager: myFlowManager,
  child: MyApp(),
)
```

Use `OmegaBuilder` to rebuild UI when specific events occur:

```dart
OmegaBuilder(
  eventName: 'user.updated',
  builder: (context, event) {
    return Text('User: ${event?.payload['name']}');
  },
)
```

In debug you can inspect the channel (last N events) and flow snapshots in two ways:

- **Overlay:** Add **`OmegaInspector`** in a `Stack` (only when `kDebugMode`). The panel uses a modern theme (blue gradient header, cards with subtle shadow, pills for event count and flow state).
- **Separate browser window (web):** Add **`OmegaInspectorLauncher`** (e.g. in the AppBar). On web it opens a new window; the app must show **`OmegaInspectorReceiver`** when loaded with `?omega_inspector=1` (see [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)). Each time you tap the launcher, a new window is opened (unique name), so you can close the inspector and open it again without issues.

### Activating flows

- **Several flows at once:** use `flowManager.activate("flowId")` for each. All stay in `running` and receive intents via `handleIntent`.
- **Single “main” flow:** use `flowManager.switchTo("flowId")` to activate one and pause the others.

### Persistence (restore on launch)

To save app state and restore it when the user reopens the app:

1. **Serialize:** `final json = flowManager.getAppSnapshot().toJson()` then save (e.g. `jsonEncode(json)` to a file or `SharedPreferences`). Flow `memory` values must be JSON-serializable.
2. **Restore:** On startup, load the saved map, then `final snapshot = OmegaAppSnapshot.fromJson(jsonDecode(loaded)); flowManager.restoreFromSnapshot(snapshot);`. This restores each flow's memory and activates the previous active flow.
3. **Optional:** Implement [OmegaSnapshotStorage] (`save` / `load`) with your preferred backend (file, prefs, API) and call it from app lifecycle. See [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) for details.

### Declarative contracts (optional)

You can declare what each flow and agent is allowed to receive and emit. Override `contract` in your flow or agent and return an [OmegaFlowContract] or [OmegaAgentContract]. In **debug** mode, Omega prints a warning when a flow receives an event or intent not in its contract, or emits an expression type not declared (and similarly for agents). Empty sets mean no constraint; if you don't set a contract, behavior is unchanged.

```dart
// In your flow
@override
OmegaFlowContract? get contract => OmegaFlowContract.fromTyped(
  listenedEvents: [AppEvent.authLoginSuccess, AppEvent.authLoginError],
  acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
  emittedExpressionTypes: {'loading', 'success', 'error'},
);

// In your agent
@override
OmegaAgentContract? get contract => OmegaAgentContract.fromTyped(
  listenedEvents: [AppEvent.authLoginRequest],
  acceptedIntents: [AppIntent.authLogin],
);
```

**Reference:** The [example](example/) app implements contracts in [AuthFlow](example/lib/auth/auth_flow.dart) and [AuthAgent](example/lib/auth/auth_agent.dart)—run `cd example && flutter run` to try it. See **[docs/CONTRACTS.md](docs/CONTRACTS.md)** for full details.

### Lifecycle and dispose

- **OmegaChannel** — Whoever creates it should call `channel.dispose()` when the app is shutting down.
- **OmegaFlowManager** — Call `flowManager.dispose()` to cancel the subscription used by `wireNavigator`.
- **OmegaAgent** — Call `agent.dispose()` so the agent unsubscribes from the channel.
- **OmegaScope** does not dispose anything; the widget that creates `channel` and `flowManager` should call their `dispose()` in its `State.dispose`.

## Example: Authentication flow

A full example lives in the **`example/`** folder. Run it with `cd example && flutter run`. It shows:

1. **UI** — Login screen that emits intents with typed payload (`LoginCredentials`).
2. **Flow** — Orchestrates login, reads payload with `payloadAs<LoginCredentials>()`, navigates to home with `OmegaIntent.fromName(AppIntent.navigateHome, payload: userData)`.
3. **Agent** — Performs login logic, emits `LoginSuccessPayload` or `OmegaFailure`.
4. **Behavior** — Rules that react to auth events/intents.
5. **Typed route** — Home registered as `OmegaRoute.typed<LoginSuccessPayload>` so the screen receives the payload without casting.

Relevant files:

- [Omega setup (config, routes)](example/lib/omega/omega_setup.dart)
- [Main entry](example/lib/main.dart)
- [Auth flow](example/lib/auth/auth_flow.dart)
- [Auth agent](example/lib/auth/auth_agent.dart)
- [Login page](example/lib/auth/ui/auth_page.dart)
- [Home (typed payload)](example/lib/home/home.dart)
- [Models (LoginCredentials, LoginSuccessPayload)](example/lib/auth/models.dart)
- [App semantics (AppEvent, AppIntent)](example/lib/omega/app_semantics.dart)

## Project structure

```
lib/
├── omega/
│   ├── core/          # Channel, events, intents, types
│   ├── agents/        # OmegaAgent, behavior engine, protocol
│   ├── flows/         # OmegaFlow, OmegaFlowManager, expressions
│   ├── ui/            # OmegaScope, OmegaBuilder, navigation
│   └── bootstrap/     # Config, runtime
├── examples/          # Full examples and feature demos
└── omega_architecture.dart  # Barrel exports
```

## Releasing (publishing to pub.dev)

Before publishing a new version:

1. Update [CHANGELOG.md](CHANGELOG.md) with the new version and changes.
2. Bump `version` in [pubspec.yaml](pubspec.yaml).
3. Update the version in this README and in `presentation/index.html` if you show the dependency snippet.
4. Run `flutter test` and `dart analyze lib`.
5. Run `dart pub publish` (dry-run first with `dart pub publish --dry-run`).

## License

See [LICENSE](LICENSE).
