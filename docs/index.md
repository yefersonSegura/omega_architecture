---
layout: home

hero:
  name: Omega Flutter
  text: Reactive, agent-based architecture
  tagline: One event channel, typed intents, flows and agents — inspect, trace, and measure what matters.
  image:
    src: /omega-logo.svg
    alt: Omega
  actions:
    - theme: brand
      text: Vision & why Omega
      link: /guide/vision-and-why
    - theme: alt
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: pub.dev package
      link: https://pub.dev/packages/omega_architecture
    - theme: alt
      text: Source
      link: https://github.com/yefersonSegura/omega_architecture
    - theme: alt
      text: Observe & measure
      link: /guide/observability-and-stats

features:
  - title: Vision
    details: Intent-first collaboration — flows orchestrate, agents handle IO, one shared channel.
  - title: OmegaChannel & events
    details: Broadcast typed events, namespaces for modules, and optional contracts in debug — see the channel guide.
  - title: Flows & agents
    details: OmegaFlow receives intents and events; OmegaAgent runs behaviors. The UI stays thin; business rules live outside widgets.
  - title: Tooling
    details: omega CLI (create app, generate ecosystem, traces, optional Omi AI), inspector overlay or browser + VM Service, and time-travel traces.
  - title: Observability & statistics
    details: See live channel traffic and flow snapshots, record sessions for replay, and map intent→expression latency — one architecture, measurable behavior.
---

::: tip Built to be watched, not guessed
Omega keeps **one clear pipeline** from UI to flows to agents. That means you can **inspect** what happened, **replay** it, and **define statistics** (throughput, response paths, flow state) without reverse‑engineering a forest of providers. **[Observability & statistics →](/guide/observability-and-stats)**
:::

<OmegaObservabilityDashboard link-to-guide />

### What each panel means

The figure is a **layout example** with placeholder numbers. In a real setup you would compute the same views from traces, inspector exports, or your own timers. For the full metrics story, see **[Observability & statistics](/guide/observability-and-stats)**.

1. **Channel events (1 min)** — A **count mix** of everything that crossed the Omega channel in the last minute, grouped by rough kind: **Intents** (mostly UI → flow), **Agent** (agent / bus traffic you attribute to agents), **Nav** (`navigate.*` and related), and **Other** (everything else). Spikes in one bucket often point to a chatty widget, a loop, or a navigation storm.

2. **Intent to expression (ms)** — **Latency bands** for “how long from handling an intent until the owning flow emits the next `OmegaFlowExpression`.” **p50** is the typical case; **p95** catches tail latency users still feel. This is the closest single chart to “Omega felt speed” for the screen.

3. **Events per minute (session excerpt)** — A **time series** of channel throughput (events per minute) over a short window (here labeled **start → +10 min**). Use it to spot bursts, plateaus, or regressions after a release.

4. **Active flows (snapshot)** — A **point-in-time row** of flows that exist in the session: each **pill** is a flow name plus a **coarse state** (for example running vs idle vs sleeping). It answers “what is alive right now?” — useful next to the inspector’s flow list.

## By the numbers (why teams reach for it)

|  |  |
|--|--|
| **One channel** | A single **OmegaChannel** coordinates the app: every important message has a name and a place in the timeline. |
| **Every flow, one snapshot** | The inspector summarizes **all registered flows** — state and last expression — so “who is running?” is never a mystery. |
| **30 recent events (default)** | The inspector keeps a rolling window of **channel events** in view so you spot storms, duplicates, and ordering bugs quickly. |
| **Ordered sessions** | Time‑travel recording preserves **event order** for offline analysis or CLI tooling — your first “statistics export” is often a trace file. |

---

## What is this site?

Structured documentation for the **[omega_architecture](https://pub.dev/packages/omega_architecture)** package (**Flutter**): same role as official **[Flutter docs](https://docs.flutter.dev/)** — **Get started** → **Topics** → **Advanced** → **Tools** → **API reference**. Use the **left sidebar** on any guide page to move between sections.

---

## Documentation hub

### Get started

|  |  |
|--|--|
| **[Getting started](/guide/getting-started)** | Install CLI, new app, existing app, learning path |
| **[Core concepts](/guide/concepts)** | Glossary: channel, intent, flow, agent, expressions |
| **[Data flow](/guide/data-flow)** | UI → manager → flow → channel → agent → UI |
| **[omega_setup.dart](/guide/omega-setup)** | Composition, cold start, namespaces, handlers |
| **[Example app](/guide/example-app)** | Runnable auth + modules in `example/` |

### Understand & decide

|  |  |
|--|--|
| **[Vision & why Omega](/guide/vision-and-why)** | When Omega fits your team |
| **[Total architecture](/guide/total-architecture)** | One diagram of the whole stack |
| **[Omega vs BLoC / Riverpod](/guide/comparison)** | Honest trade-offs |
| **[Observability & statistics](/guide/observability-and-stats)** | Inspector, traces, metrics mindset, intent→expression |

### Build features

|  |  |
|--|--|
| **[Channel & events](/guide/channel-events)** | Bus, namespaces, typed names, dispose |
| **[Intents, flows & manager](/guide/intents-flows-manager)** | Routing intents, flow lifecycle |
| **[Agents & behaviors](/guide/agents-behaviors)** | Side effects, `onAction`, stateful agents |
| **[Navigation & routes](/guide/navigation-router)** | `navigate.*`, typed routes |
| **[Flutter widgets](/guide/widgets)** | `OmegaScope`, flow/agent builders, inspector, `RootHandler` |

### Advanced

|  |  |
|--|--|
| **[Contracts](/guide/contracts)** | Flow/agent contracts in debug |
| **[Time travel & traces](/guide/time-travel)** | Record, replay, `omega trace`, AI explain |
| **[Offline-first intents](/guide/offline-first)** | Queued intents when offline |

### Tools & reference

|  |  |
|--|--|
| **[Omega CLI](/guide/cli)** | All commands including **`omega ai`** |
| **[Inspector & VM Service](/guide/inspector)** | Overlay, launcher, browser + VM |
| **[Testing](/guide/testing)** | Unit-test flows and agents |
| **[API reference](/guide/api-reference)** | Map to **pub.dev** API docs |
| **[Repository layout](/guide/repository)** | `lib/`, `example/`, `docs/`, CI |

The hosted **[Inspector HTML (VM Service)](https://yefersonsegura.com/projects/omega/inspector.html)** page is the URL the CLI and `OmegaInspectorServer` open; a copy also ships with this site at **[Inspector HTML](/inspector.html)**.

The **[README](https://github.com/yefersonSegura/omega_architecture/blob/main/README.md)** on GitHub has a short pitch and badges.

## Author

**Omega** is developed by **[Yeferson Segura](https://yefersonsegura.com/)** (mobile · web · product-oriented software). More context: **[About the author](/guide/about)**.
