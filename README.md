<h1 align="center">Ω Omega Architecture</h1>

<p align="center">
  <strong>Reactive, agent-based architecture for Flutter</strong><br/>
  One channel · typed intents · flows · agents · CLI · inspector · traces
</p>

<p align="center">
  <img src="assets/omega_logo.svg" alt="Omega Architecture logo" width="200">
</p>

<p align="center">
  <a href="https://pub.dev/packages/omega_architecture"><img src="https://img.shields.io/pub/v/omega_architecture?style=flat-square&label=pub" alt="pub version"></a>
  &nbsp;
  <a href="https://yefersonsegura.github.io/omega_architecture/"><img src="https://img.shields.io/badge/docs-site%20%26%20API-0175C2?style=flat-square" alt="Documentation"></a>
  &nbsp;
  <a href="https://pub.dev/documentation/omega_architecture/latest"><img src="https://img.shields.io/badge/pub.dev-API-0175C2?style=flat-square" alt="API reference"></a>
</p>

<p align="center">
  <a href="#introduction">Intro</a> ·
  <a href="#why-omega">Why Omega</a> ·
  <a href="#start-in-one-minute">Quick start</a> ·
  <a href="#what-it-feels-like">Mental model</a> ·
  <a href="#cli-at-a-glance">CLI</a> ·
  <a href="#where-to-look-next">Links</a>
</p>

---

## Introduction

### What is Omega?

**Omega Architecture** is a **Dart / Flutter package** plus a **`omega` CLI** that organizes your app around a few clear ideas: a single **`OmegaChannel`** for events, **flows** that orchestrate use cases, **agents** that run side effects and domain logic, and a **thin UI** that sends **intents** and reacts to **flow expressions** — instead of growing a tangle of `setState`, callbacks, and hidden dependencies across widgets.

### Why use it?

- **Easier to reason about** — business rules live in flows and agents; screens stay declarative.
- **Safer evolution** — typed intent/event names, optional **contracts** in debug, and **`omega validate`** catch wiring mistakes before they ship.
- **Better debugging** — **inspector** (overlay, dialog, or browser + VM Service), **time-travel** sessions, and traces so you see *what* happened and *in what order*.
- **Less boilerplate** — **`omega g ecosystem`**, project templates, and an optional **AI coach** for scaffolding.

This README is only a **summary**. **Go to the documentation** for install steps, diagrams, every guide, and the learning path:

<p align="center">
  <strong>
    <a href="https://yefersonsegura.github.io/omega_architecture/">Documentation site →</a>
  </strong>
  <br/>
  <sub>Suggested path: <a href="https://yefersonsegura.github.io/omega_architecture/guide/getting-started.html">Getting started</a> · <a href="https://yefersonsegura.github.io/omega_architecture/guide/concepts.html">Core concepts</a> · <a href="https://yefersonsegura.github.io/omega_architecture/guide/data-flow.html">Data flow</a></sub>
</p>

---

## Why Omega

| You want | You get |
| --- | --- |
| UI that does not drown in logic | **Intents** in, **expressions** out — widgets stay declarative |
| One nervous system for the app | **`OmegaChannel`** — events everyone hears |
| Confidence when the app grows | **Typed** names, optional **contracts**, **`omega validate`** |
| To see what the app is doing | **Inspector** (in-app, tab, or browser + VM Service) + **time-travel** |
| New features without boilerplate fatigue | **`omega g ecosystem`** + optional **AI coach** |

---

## Start in one minute

```bash
dart pub global activate omega_architecture
omega create app my_app && cd my_app && flutter run
```

Add Pub’s global **`bin`** to your **`PATH`** (Windows: `%LOCALAPPDATA%\Pub\Cache\bin`). If `omega` is not found, use the **[CLI guide](https://yefersonsegura.github.io/omega_architecture/guide/cli.html)** (`PATH`, `dart run omega_architecture:omega …`).

**Existing app:** add [`omega_architecture`](https://pub.dev/packages/omega_architecture) to `pubspec.yaml`, then from the app root:

```bash
dart run omega_architecture:omega init
```

---

## What it feels like

The UI states what it wants (**intent**). **Flows** coordinate. **Agents** react through a **behavior** engine. The channel carries **events**; navigation and state show up as predictable **streams** — not `setState` spaghetti across the tree.

```dart
OmegaScope(
  channel: channel,
  flowManager: flowManager,
  child: const MyApp(),
);
```

**More depth:** [Documentation](https://yefersonsegura.github.io/omega_architecture/) · [API reference](https://pub.dev/documentation/omega_architecture/latest)

---

## CLI at a glance

| Command | What it does |
| --- | --- |
| **`omega create app`** | New Flutter app with Omega wired in |
| **`omega init`** | Drop Omega into an existing app |
| **`omega g ecosystem <Name>`** | Flow + agent + behavior + page |
| **`omega validate` / `doctor`** | Catch wiring mistakes early |
| **`omega inspector`** | VM Service → inspect in the browser |
| **`omega ai coach …`** | Optional — scaffold or evolve modules (env + API keys) |

Full reference: **[CLI guide](https://yefersonsegura.github.io/omega_architecture/guide/cli.html)**

---

## Where to look next

|  |  |
| --- | --- |
| **[Web docs](https://yefersonsegura.github.io/omega_architecture/)** | Guides, architecture map, CLI, inspector |
| **[CLI](https://yefersonsegura.github.io/omega_architecture/guide/cli.html)** | All `omega` and `omega ai` commands |
| **[Inspector](https://yefersonsegura.github.io/omega_architecture/guide/inspector.html)** | Overlay, launcher, VM / browser |
| **[`example/`](example/)** | Auth reference — `cd example && flutter run` |

---

## Package layout

```
lib/omega/                 → channel, intents, events, agents, flows, ui, bootstrap
lib/omega_architecture.dart → public barrel export
```

---

## License

[MIT](LICENSE)
