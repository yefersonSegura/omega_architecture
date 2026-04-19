# Core concepts

Short glossary for Omega on Flutter.

| Concept | Role |
|--------|------|
| **OmegaChannel** | Event bus: `emit` / `events`, optional `namespace('auth')` per module. |
| **OmegaEvent** | Something that happened (`name` + `payload`), often typed. |
| **OmegaIntent** | Something the UI wants (`login`, `navigate.home`, …); handled by flows / navigator. |
| **OmegaFlow** | Orchestrates a feature: `onIntent`, `onEvent`, emits expressions and navigation intents. |
| **OmegaAgent** | Subscribes to the channel; **behavior** maps reactions to imperative work (HTTP, storage). |
| **Flow manager** | Decides which flow is **running** and delivers intents. |
| **OmegaNavigator** | Maps navigation intents to **routes** and arguments for screens. |
| **Expressions** | Stream of UI-facing state from a flow (loading, error, data). |

**One sentence:** the UI says what it wants (**intent**); the channel carries **events**; **flows** and **agents** decide what happens; the UI only reflects **expressions** and route changes.

For a full stack map (bootstrap, snapshots, tooling), see **[Total architecture](./total-architecture)**.

Next: **[Data flow](./data-flow)**.
