---
layout: home

hero:
  name: Omega Architecture
  text: Reactive, agent-based architecture for Flutter
  tagline: One event channel, typed intents, flows and agents, first-class CLI, inspector, and traces — same philosophy as Omega Angular for the web.
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

features:
  - title: Vision
    details: Intent-first collaboration — flows orchestrate, agents handle IO, one shared channel. Pairs naturally with the Angular package omega-angular for full-stack teams.
  - title: OmegaChannel & events
    details: Broadcast typed events, namespaces for modules, and optional contracts in debug — see the channel guide.
  - title: Flows & agents
    details: OmegaFlow receives intents and events; OmegaAgent runs behaviors. The UI stays thin; business rules live outside widgets.
  - title: Tooling
    details: omega CLI (create app, generate ecosystem, traces, optional Omi AI), inspector overlay or browser + VM Service, and time-travel traces.
---

## What is this site?

This site documents the **[omega_architecture](https://pub.dev/packages/omega_architecture)** Dart package and the **[omega_architecture](https://github.com/yefersonSegura/omega_architecture)** GitHub repository — **Flutter only**.

- Read **[Vision & why Omega](/guide/vision-and-why)** for purpose and fit, then **[Getting started](/guide/getting-started)** and **[Core concepts](/guide/concepts)**.  
- Follow **[Data flow](/guide/data-flow)** for an end-to-end picture, then **[Channel & events](/guide/channel-events)**, **[Intents & flows](/guide/intents-flows-manager)**, and **[Agents & behaviors](/guide/agents-behaviors)**.  
- Use **[API reference](/guide/api-reference)** as the map to the generated API docs on pub.dev.

Long-form Markdown in the repo lives under **`doc/`** (e.g. [GUIA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md)). The **[online Inspector](/inspector.html)** page (VM Service) ships as a static asset next to this site.

Monorepo layout, `example/`, and publishing are summarized under **[Repository layout](/guide/repository)** and the README on GitHub.

## Author

**Omega** is developed by **[Yeferson Segura](https://yefersonsegura.com/)** (mobile · web · product-oriented software). More context: **[About the author](/guide/about)**.
