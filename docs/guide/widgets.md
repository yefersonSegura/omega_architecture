# Flutter widgets (Omega UI)

This page lists the **Flutter widgets and inherited scopes** exported from `package:omega_architecture/omega_architecture.dart` under **UI integration (Flutter)**. They sit between your `MaterialApp` / routes and the runtime (`OmegaChannel`, `OmegaFlowManager`, agents).

For **navigation types** that are not widgets (`OmegaNavigator`, `OmegaRoute`, `OmegaNavigationEntry`), see [Navigation & routes](./navigation-router.md).

---

## Summary table

| Widget / scope | Role |
|----------------|------|
| [OmegaScope](#omegascope) | Provides `channel`, `flowManager`, and optional cold-start hints to the whole tree. |
| [OmegaInitialRoute](#omegainitialroute--omegainitialnavigationemitter) | Emits the first navigation intent after the first frame (from scope or explicit intent). |
| [OmegaInitialNavigationEmitter](#omegainitialroute--omegainitialnavigationemitter) | Same as above when you pass the intent explicitly (no scope field). |
| [OmegaFlowActivator](#omegaflowactivator) | Activates or switches to a flow once when the route gets dependencies. |
| [OmegaFlowExpressionBuilder](#omegaflowexpressionbuilder) | Rebuilds when a flow’s **UI expression** changes. |
| [OmegaAgentScope](#omegaagentscope) | Provides an `OmegaAgent` to descendants via `InheritedWidget`. |
| [OmegaAgentBuilder](#omegaagentbuilder--omegascopedagentbuilder) | Rebuilds from a **stateful agent’s** `viewState` stream. |
| [OmegaScopedAgentBuilder](#omegaagentbuilder--omegascopedagentbuilder) | Same, agent resolved from `OmegaAgentScope`. |
| [OmegaBuilder](#omegabuilder) | Rebuilds when **channel events** arrive (optional filter by name). |
| [OmegaInspector](#omegainspector) | In-app debug panel: recent events + flow snapshot. |
| [OmegaInspectorLauncher](#omegainspectorlauncher--omegainspectorreceiver) | Opens the inspector (dialog on VM/desktop, new window on web). |
| [OmegaInspectorReceiver](#omegainspectorlauncher--omegainspectorreceiver) | Second window on web: listens on `BroadcastChannel` and shows the inspector UI. |
| [RootHandler](#roothandler) | Example shell: optional `Scaffold`, activates `initialFlowId`, debug AppBar actions. |

---

## OmegaScope

**Type:** `InheritedWidget`

**Purpose:** Injects `OmegaChannel` and `OmegaFlowManager` (and optionally `initialFlowId` + `initialNavigationIntent`) so any descendant can call `OmegaScope.of(context)`.

**When to use:** Once at the root of the app (typically wrapping `MaterialApp`), right after you build the runtime in `omega_setup.dart`.

**When not to use:** Do not nest multiple competing scopes with different channels unless you intentionally isolate subtrees (advanced).

**See also:** [omega_setup.dart](./omega-setup.md), [Data flow](./data-flow.md).

---

## OmegaInitialRoute & OmegaInitialNavigationEmitter

**Type:** `StatefulWidget` (both)

**Purpose:** After the **first frame**, emit a single `OmegaEvent` named for navigation (`navigationIntentEvent`) with a `navigate.*` intent so `OmegaNavigator` can push/replace the first screen.

- **`OmegaInitialRoute`:** Uses `intent` if passed, otherwise `OmegaScope.initialNavigationIntent` (typical cold start from `OmegaConfig` / runtime). If both are null, it only builds `child` (no emit).
- **`OmegaInitialNavigationEmitter`:** Always uses the `intent` you pass in the constructor.

**When to use:** Place **under** `MaterialApp` so `navigatorKey` is attached when the post-frame callback runs. Prefer `OmegaInitialRoute` when the intent already lives on `OmegaScope`.

**When not to use:** Not for in-app navigation after startup; emit intents through the channel or your navigation helper as usual.

**See also:** [Navigation & routes](./navigation-router.md), [Example app](./example-app.md).

---

## OmegaFlowActivator

**Type:** `StatefulWidget`

**Purpose:** Calls `OmegaFlowManager.activate` or `switchTo` **once** in `didChangeDependencies`, so you do not duplicate that logic in every screen.

**Parameters:**

- `flowId`: `String` or `OmegaFlowId` (e.g. enum with `OmegaFlowIdEnumWire`).
- `useSwitchTo`: `true` when this screen should be the **only** active flow; `false` when several flows may run together.

**When to use:** Wrap the body of a route that **owns** a flow.

**See also:** [Intents, flows & manager](./intents-flows-manager.md).

---

## OmegaFlowExpressionBuilder

**Type:** `StatelessWidget`

**Purpose:** Subscribes to `OmegaFlow.expressions` for the given `flowId` and rebuilds when a new `OmegaFlowExpression` is emitted (for example after `handleIntent`). Uses `lastExpression` as initial data because the stream is broadcast.

**When to use:** Declarative UI driven by the flow’s **expression** (recommended pattern for flow-owned screens).

**Agent scope:** If the flow overrides `OmegaFlow.uiScopeAgent`, the `builder` output is wrapped in `OmegaAgentScope` so `OmegaScopedAgentBuilder` works without manually wrapping the route.

**Requirements:** An `OmegaScope` above; the flow should already be activated or discoverable via `getFlowFlexible`.

**See also:** [Intents, flows & manager](./intents-flows-manager.md), [Agents & behaviors](./agents-behaviors.md).

---

## OmegaAgentScope

**Type:** `InheritedWidget`

**Purpose:** Exposes a single `OmegaAgent` to descendants. Retrieve with `OmegaAgentScope.omegaAgentOf` / `omegaAgentAs` / `maybeOmegaAgentAs`.

**When to use:** One agent per route or subtree (e.g. cart agent for the shop module). Often declared in `omega_setup.dart` inside `OmegaRoute`’s `builder`.

**When not to use:** For stateless helpers that do not need inheritance; pass dependencies explicitly if the tree is shallow.

**See also:** [Agents & behaviors](./agents-behaviors.md).

---

## OmegaAgentBuilder & OmegaScopedAgentBuilder

**Types:** `StatefulWidget` / `StatelessWidget`

**Purpose:** Subscribe to `OmegaStatefulAgent.stateStream` (view state) and rebuild the UI. Does **not** own the agent lifecycle.

- **`OmegaAgentBuilder`:** You pass `agent` explicitly.
- **`OmegaScopedAgentBuilder`:** Resolves the agent from `OmegaAgentScope` (same generic `TAgent` / `TState` pattern).

**When to use:** Any screen that displays `OmegaStatefulAgent` view state (forms, auth status, lists driven by agent state).

**When not to use:** For channel-wide cross-cutting UI unrelated to one agent; consider `OmegaBuilder` or expression-driven UI instead.

**See also:** [Agents & behaviors](./agents-behaviors.md).

---

## OmegaBuilder

**Type:** `StatelessWidget`

**Purpose:** `StreamBuilder` over `OmegaChannel.events`, optionally filtered by `eventName`. Rebuilds whenever a matching event is emitted.

**When to use:** Show banners, error text, or widgets that react to **named channel events** without pulling in a full flow expression.

**When not to use:** Primary screen structure is usually better tied to `OmegaFlowExpressionBuilder` so the flow stays the single source of UI truth.

**See also:** [Channel & events](./channel-events.md).

---

## OmegaInspector

**Type:** `StatefulWidget` (uses Material for the panel)

**Purpose:** Debug-only panel: recent channel events (up to `eventLimit`) and a snapshot of flows (id, state, last expression). Reads `OmegaScope.of(context)`.

**When to use:** Overlay in a `Stack` in debug builds (`kDebugMode`).

**When not to use:** Release-facing UI; gate with `kDebugMode` or exclude from production trees.

**See also:** [Inspector & VM Service](./inspector.md).

---

## OmegaInspectorLauncher & OmegaInspectorReceiver

**Types:** `StatefulWidget` / `StatelessWidget` (implementation varies by platform; same public names via conditional exports).

**OmegaInspectorLauncher**

- **VM / desktop / mobile (stub):** In debug mode, `IconButton` that opens a **dialog** embedding `OmegaInspector`. Outside debug, builds `SizedBox.shrink()`.
- **Web:** Opens a **new browser window** and streams JSON snapshots over `BroadcastChannel` (`omega_inspector`).

**OmegaInspectorReceiver**

- **Web:** Intended for the URL opened with `?omega_inspector=1`: listens on `BroadcastChannel` and renders the inspector UI in that window.
- **Other platforms:** Stub that explains using `OmegaInspector` in-app or the dialog launcher.

**When to use:** Developer tooling alongside `RootHandler(showInspector: true)` on web, or your own debug AppBar.

**See also:** [Inspector & VM Service](./inspector.md).

---

## RootHandler

**Type:** `StatefulWidget` (Material `Scaffold` / `AppBar` in debug)

**Purpose:** **Example / demo shell** placed after `OmegaInitialRoute`: wraps content in `OmegaFlowActivator` when `OmegaScope.initialFlowId` is set (`useSwitchTo: true`). Optional debug `AppBar` (docs hint, time-travel sheet, web inspector launcher when `showInspector`).

**Parameters (high level):** `appTitle`, `showInspector`, `wrapWithScaffold` (set `false` when each route has its own `Scaffold`), `child`.

**When to use:** Quickstarts and the packaged example app.

**When not to use:** Production apps often replace this with their own shell; keep `OmegaScope`, `OmegaFlowActivator`, and navigation setup, and drop the demo AppBar.

**See also:** [Example app](./example-app.md), [Time travel & traces](./time-travel.md).

---

## Related API (not a widget)

**`OmegaInspectorServer`** (exported from the same library section) is a **VM-side HTTP/WebSocket helper** to expose channel + flow snapshots to the static inspector page — not a Flutter widget. Use it from `main()` or setup code in debug when you want the external inspector tab.

**See also:** [Inspector & VM Service](./inspector.md).
