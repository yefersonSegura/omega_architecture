# Omega contracts (declarative schemas)

Contracts let you declare what each flow and agent is allowed to receive and emit. In **debug mode**, Omega prints a warning when a flow or agent receives an event or intent not listed in its contract, or when a flow emits an expression type not declared.

**Reference example:** The package **`example/`** app implements contracts in [AuthFlow](https://github.com/yefersonSegura/omega_architecture/blob/main/example/lib/auth/auth_flow.dart) and [AuthAgent](https://github.com/yefersonSegura/omega_architecture/blob/main/example/lib/auth/auth_agent.dart). Run `cd example && flutter run` to see login/logout with contracts; in debug, any event or intent not in the contract will trigger a console warning. Use that app as the main reference when adding contracts to your own flows and agents.

## Why use contracts

- **Documentation**: Each flow/agent explicitly lists the events it listens to and the intents it accepts.
- **Early detection**: In development, typos or wrong event/intent names are caught when the contract is violated.
- **Foundation for tooling**: The Inspector (or future tools) can show "expected intents" per flow; codegen or strict mode can be added later.

## Flow contract

Override `contract` in your flow and return an `OmegaFlowContract`:

```dart
class AuthFlow extends OmegaFlow {
  AuthFlow(OmegaChannel c) : super(id: 'authFlow', channel: c);

  @override
  OmegaFlowContract? get contract => OmegaFlowContract(
    listenedEventNames: {
      AppEvent.authLoginSuccess.name,
      AppEvent.authLoginError.name,
    },
    acceptedIntentNames: {
      AppIntent.authLogin.name,
      AppIntent.authLogout.name,
    },
    emittedExpressionTypes: {'loading', 'success', 'error'},
  );

  @override
  void onEvent(OmegaFlowContext ctx) { ... }

  @override
  void onIntent(OmegaFlowContext ctx) { ... }
}
```

With typed names (enums), use `OmegaFlowContract.fromTyped`:

```dart
@override
OmegaFlowContract? get contract => OmegaFlowContract.fromTyped(
  listenedEvents: [AppEvent.authLoginSuccess, AppEvent.authLoginError],
  acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
  emittedExpressionTypes: {'loading', 'success', 'error'},
);
```

- **Empty sets** mean "no constraint" (everything is allowed). So you can declare only events, or only intents.
- Validation runs only when `kDebugMode` is true (Flutter debug builds). Release builds are unchanged.

## Agent contract

Override `contract` in your agent and return an `OmegaAgentContract`:

```dart
class AuthAgent extends OmegaAgent {
  AuthAgent(OmegaChannel c) : super(id: 'Auth', channel: c, behavior: AuthBehavior());

  @override
  OmegaAgentContract? get contract => OmegaAgentContract.fromTyped(
    listenedEvents: [AppEvent.authLoginRequest],
    acceptedIntents: [AppIntent.authLogin],
  );

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) { ... }
}
```

Same rule: empty sets = no constraint. Warnings only in debug.

## Optional

- You can omit `contract` (return `null`): no validation, behavior as before.
- Contracts are optional and additive; existing Omega apps work without any change.
