# Agents & behaviors

**[OmegaAgent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgent-class.html)** is the home for **side effects** and **domain reactions**: HTTP, local DB, device APIs, analytics. It listens to the same **[OmegaChannel](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannel-class.html)** (or a **namespace**) as your flows.

The **[OmegaAgentBehaviorEngine](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentBehaviorEngine-class.html)** turns **incoming events / intents + agent state** into an **[OmegaAgentReaction](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentReaction-class.html)** — a **string action id** and optional payload. The agent then executes **`onAction(String action, dynamic payload)`** with a **`switch (action)`** using **string literals** for each branch (see package lints — do **not** use `enumCase.name` in switch cases).

---

## Why separate agent from flow?

| Flow | Agent |
|------|--------|
| Orchestrates user-visible **steps**, expressions, navigation | Performs **IO**, retries, mapping to domain models |
| Answers “what happens next in the product story?” | Answers “how do we talk to the world?” |

Keeping widgets free of both keeps **tests** small: drive the channel and assert events / state.

---

## Stateful agents

[OmegaStatefulAgent](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaStatefulAgent-class.html) exposes **`viewState`** / **`viewStateStream`** for UI that binds to typed state — use **[OmegaScopedAgentBuilder](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaScopedAgentBuilder-class.html)** under **[OmegaAgentScope](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentScope-class.html)** so pages do not thread the agent through every constructor.

---

## Agent protocol (direct messaging)

[OmegaAgentProtocol](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentProtocol-class.html) registers agents for **point-to-point** or **broadcast** messages — complementary to the global channel, not a replacement.

---

## Contracts

Optional [OmegaAgentContract](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAgentContract-class.html) lists events and intents the agent is prepared for — debug warnings when traffic does not match. See **[Contracts](./contracts)**.

---

## Reference implementation

Read **`example/lib/auth/auth_agent.dart`** and **`auth_behavior.dart`** in the repository line by line.

---

## Next

- [Channel & events](./channel-events)  
- [Intents, flows & manager](./intents-flows-manager)  
- [Testing](./testing)  
