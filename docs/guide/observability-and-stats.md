# Observability & statistics

Omega is built so **behavior is traceable**: one channel, typed intents, flows that emit expressions, and agents that react on the bus. That shape is exactly what good **statistics and observability** need — not a black box of scattered `setState` calls.

This page explains **what to measure**, **what you already get in the package**, and **how to layer your own metrics** without polluting production builds.

---

## Example statistical dashboard (illustrative)

The diagram below is **not live data** from your app: it shows the **kinds of charts** that fit Omega naturally — category mix on the channel, **intent → expression** latency bands, an **events/minute** curve, and a **flow snapshot** row. You can reproduce these from **traces**, **inspector exports**, or **custom timers** around `handleIntent` / `emitExpression`.

![Example bar chart, latency p50 and p95 bars, events per minute area chart, and flow state chips for Omega observability](/omega-observability-dashboard.svg)

---

## Why this matters for your product

Users do not feel “Omega’s speed” as an abstract score. They feel **time to feedback** after a tap, **consistency** under load, and **whether bugs are explainable** after the fact. Omega’s architecture makes those questions answerable:

- **Intent → expression** — How long from a UI intent until the owning flow emits the next `OmegaFlowExpression`? That is the closest thing to “Omega latency” for the screen.
- **Event throughput** — How many channel events fire per second during a stress path? Spikes often reveal accidental loops or chatty agents.
- **Flow state** — Which flows are running, sleeping, or idle? Misconfigured activation shows up immediately in a snapshot.

You can present these ideas to stakeholders as **observability**: the same discipline that sells observability platforms, but mapped to **flows and agents** instead of generic logs alone.

---

## What you get today (no extra code)

These capabilities ship with **omega_architecture** and the docs site. They are aimed at **debug** and **internal builds**.

| Capability | What it gives you |
|------------|-------------------|
| **[Inspector](./inspector.md)** (`OmegaInspector`, launcher, VM page) | Recent channel events (default **30** visible in the overlay), payloads as JSON, and a **snapshot of all flows** — id, state, last expression. |
| **Time travel** | **[Record & replay](./time-travel.md)** sessions: ordered events you can step through — ideal for “what happened in the five seconds before the bug?” |
| **`omega trace` / CLI** | Export and inspect traces from the terminal — good for **statistics over saved sessions** (counts, ordering, which intent fired). |
| **Contracts (debug)** | **[Contracts](./contracts.md)** validate that intents and expressions match what the flow declared — fewer surprises when you aggregate behavior. |

None of this requires you to trust magic dashboards: you can **see the same events** your flows and agents see.

---

## Statistics that fit Omega (recommended set)

When you design a metrics story (even if the first version is a spreadsheet from a trace file), prioritize these:

1. **UI → flow response** — Stopwatch from `handleIntent` (or from your widget before emit) until the next expression your screen cares about. Per-flow percentiles (p50 / p95) tell you if a regression is in **flow logic** or in **network / agent IO**.
2. **Channel volume** — Events per second (global or per `namespace`). Sudden doubling after a release is a classic smell.
3. **Agent behavior** — Count of `onAction` calls, errors, or retries per session — especially if agents wrap APIs or local storage.
4. **Navigation** — Count of `navigate.*` intents and failures; pairs well with the **[navigation guide](./navigation-router.md)**.

Flutter’s own **DevTools** remains the place for **frame timing and jank**; Omega-focused stats complement that instead of replacing it.

---

## Rolling your own (thin and safe)

For **production**, keep overhead minimal:

- Wrap hot paths in **`kDebugMode`** or a **compile-time flag** (e.g. `assert`-only blocks, or a `Telemetry` interface with a no-op implementation in release).
- Prefer **sampling** (e.g. one in N sessions) for detailed timelines.
- Attach **correlation ids** on `OmegaEvent` metadata if you export to analytics — the channel is a natural choke point to stamp an id once.

The **[channel & events](./channel-events.md)** and **[data flow](./data-flow.md)** guides show where to hook without breaking the model.

---

## See also

- [Inspector & VM Service](./inspector.md) — overlay, dialog, browser, VM Service  
- [Time travel & traces](./time-travel.md) — recording and replay  
- [Data flow](./data-flow.md) — end-to-end path from UI to agent  
- [Flutter widgets](./widgets.md) — `OmegaInspector`, `OmegaBuilder`, debug shell  

If you later want **first-class histograms** inside the inspector (e.g. rolling latency of intent → expression), that is a natural extension of the same pipeline — the architecture is already **event-centric** and **flow-centric**, which is the hard part.
