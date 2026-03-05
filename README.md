# Ω Omega Architecture

A reactive, agent-based architecture framework for Flutter applications.

## Features

- **Reactive Agents** — Autonomous entities that react to system events and direct messages.
- **Behavior Engine** — Decoupled logic using rules and conditions to determine agent reactions.
- **Event-Driven** — Global communication through `OmegaChannel`.
- **Flow Management** — Orchestrate complex state transitions and business logic flows; run one or multiple flows at once.
- **Semantic Intents** — High-level abstraction for user or system requests.
- **CLI** — Scaffold setup and generate ecosystems (agent, flow, behavior, page) from the command line.

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
  omega_architecture:
    git:
      url: https://github.com/yefersonSegura/omega_architecture.git
      ref: main  # or a tag / commit
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

### Commands

| Command | Description |
|---------|-------------|
| `init [--force]` | Creates `lib/omega/omega_setup.dart` with an empty `OmegaConfig`. Use `--force` to overwrite if it already exists. |
| `g ecosystem <Name>` | Generates a new ecosystem: agent, flow, behavior, and page, and registers them (and the route) in `omega_setup.dart`. Run `omega init` first. |

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
dart run omega_architecture:omega generate ecosystem Orders
```

Generated files for `omega g ecosystem Auth` (when run from `lib/` or a subfolder):

- `auth_agent.dart`, `auth_flow.dart`, `auth_behavior.dart`
- `ui/auth_page.dart`
- Updates to `lib/omega/omega_setup.dart` (imports, agents, flows, routes)

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

### Activating flows

- **Several flows at once:** use `flowManager.activate("flowId")` for each. All stay in `running` and receive intents via `handleIntent`.
- **Single “main” flow:** use `flowManager.switchTo("flowId")` to activate one and pause the others.

### Lifecycle and dispose

- **OmegaChannel** — Whoever creates it should call `channel.dispose()` when the app is shutting down.
- **OmegaFlowManager** — Call `flowManager.dispose()` to cancel the subscription used by `wireNavigator`.
- **OmegaAgent** — Call `agent.dispose()` so the agent unsubscribes from the channel.
- **OmegaScope** does not dispose anything; the widget that creates `channel` and `flowManager` should call their `dispose()` in its `State.dispose`.

## Example: Authentication flow

A full example lives under `lib/examples/` and shows:

1. **UI** — Login screen that emits intents.
2. **Flow** — Orchestrates login, navigation, and UI expressions.
3. **Agent** — Performs login logic and emits success/error events.
4. **Behavior** — Rules and reactions for the auth agent.

Relevant files:

- [Main setup](lib/examples/omega_main_setup_example.dart)
- [Auth flow](lib/examples/auth/auth_flow.dart)
- [Login page](lib/examples/auth/ui/omega_login_page.dart)

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

## License

See [LICENSE](LICENSE).
