# Omega Architecture

A reactive, agent-based architecture framework for Flutter applications.

## Features

- **Reactive Agents**: Autonomous entities that react to system events and direct messages.
- **Behavior Engine**: Decoupled logic using rules and conditions to determine agent reactions.
- **Event-Driven**: Global communication through `OmegaChannel`.
- **Flow Management**: Orchestrate complex state transitions and business logic flows.
- **Semantic Intents**: High-level abstraction for user or system requests.

## Core Concepts

### Agents (`OmegaAgent`)
The building blocks of the architecture. Each agent has an ID, a channel for communication, and a behavior engine.

### Behavior Engine (`OmegaAgentBehaviorEngine`)
The "brain" of an agent. It evaluates incoming events or intents and produces reactions (actions to be performed).

### Channels (`OmegaChannel`)
The medium through which events are broadcasted and received by agents.

### Flows (`OmegaFlow`)
Structures that define a sequence of states and transitions, managed by `OmegaFlowManager`.

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  omega_architecture:
    path: ./
```

## Usage

Define a behavior engine and an agent:

```dart
class MyBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    if (ctx.event?.name == "greet") {
      return const OmegaAgentReaction("sayHello", payload: "Welcome home!");
    }
    return null;
  }
}

class MyAgent extends OmegaAgent {
  MyAgent(OmegaChannel channel) 
    : super(id: "my_agent", channel: channel, behavior: MyBehavior());

  @override
  void onMessage(OmegaAgentMessage msg) {
    // Handle direct messages
  }

  @override
  void onAction(String action, dynamic payload) {
    if (action == "sayHello") {
      print(payload);
    }
  }
}

void main() {
  final channel = OmegaChannel();
  final agent = MyAgent(channel);

  channel.emit(const OmegaEvent(id: "1", name: "greet"));
}
```

## Flutter Integration (DI & Reactive UI)

Omega provides specialized widgets for clean Dependency Injection and reactive UI updates.

### OmegaScope (Dependency Injection)

Wrap your app with `OmegaScope` to provide the `OmegaChannel` and `OmegaFlowManager` to the widget tree.

```dart
OmegaScope(
  channel: myChannel,
  flowManager: myFlowManager,
  child: MyApp(),
)
```

### OmegaBuilder (Reactive UI)

Use `OmegaBuilder` to rebuild parts of your UI when specific events occur in the system.

```dart
OmegaBuilder(
  eventName: 'user.updated',
  builder: (context, event) {
    return Text('User: ${event?.payload['name']}');
  },
)
```

## Project Structure

- `lib/omega/core`: Core primitives (Channels, Events, Intents).
- `lib/omega/agents`: Agent definitions and Behavior Engine.
- `lib/omega/flows`: Flow management components.
- `lib/omega/ui`: Navigation and UI-related architecture.
