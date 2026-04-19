# Contracts (flows & agents)

Omega can enforce **declared boundaries** in **debug**: what each [OmegaFlow](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow-class.html) listens to, which [OmegaIntent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntent-class.html)s it accepts, and which **expression** types it may emit — and the same idea for [OmegaAgent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgent-class.html) with **events** and **reactions**.

Contracts are **optional**. Production behavior is unchanged if you omit them; they add **documentation in code** and **early warnings** when wiring drifts.

---

## Why use contracts

| Benefit | What you get |
|---------|----------------|
| **Onboarding** | New teammates read `contract` instead of hunting `onEvent` / `onIntent` |
| **Refactors** | Rename an event wire — debug may warn the contract no longer matches |
| **Reviews** | PRs show an explicit surface area per flow/agent |
| **Inspector / tooling** | Room for future UI that reads declared sets |

---

## Flow contract

Override [contract](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlow/contract.html) on your flow:

```dart
@override
OmegaFlowContract? get contract => OmegaFlowContract.fromTyped(
  listenedEvents: [
    AppEvent.authLoginSuccess,
    AppEvent.authLoginError,
  ],
  acceptedIntents: [
    AppIntent.authLogin,
    AppIntent.authLogout,
  ],
  emittedExpressionTypes: {'loading', 'success', 'error'},
);
```

**Semantics (debug):**

- **Empty set** for a dimension = *no constraint* on that dimension (all allowed).
- Non-empty **listened event names** → warn if the flow’s `onEvent` receives something not listed (same namespace rules apply as elsewhere).
- **Accepted intents** → warn on unexpected `onIntent` delivery.
- **Emitted expression types** → warn if `emitExpression` uses a type string you did not declare.

Reference: **`example/lib/auth/auth_flow.dart`** in the repository.

---

## Agent contract

[OmegaAgentContract](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentContract-class.html) lists **events the agent listens to** and **intent names** it may react to (via behavior). Same empty-set = no rule.

Reference: **`example/lib/auth/auth_agent.dart`**.

---

## Typed names

Prefer **`OmegaFlowContract.fromTyped`** with enums implementing [OmegaEventName](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaEventName-class.html) / [OmegaIntentName](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaIntentName-class.html) so wires stay refactor-safe. Central app enums live in **`app_semantics.dart`** (see the example app’s `AppEvent` / `AppIntent`).

---

## Related

- [Agents & behaviors](./agents-behaviors) — where reactions must align with `onAction` **string** cases  
- [Intents, flows & manager](./intents-flows-manager) — how intents reach flows  
- [Testing](./testing) — asserting channel + flow behavior without full UI  
