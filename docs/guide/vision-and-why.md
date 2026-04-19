# Vision & why Omega

Not sure Omega fits your app? Read this page first, then **[Getting started](./getting-started)**.

## The problem

In growing Flutter apps, business logic often leaks into widgets: `setState`, services called from `build`, and navigation sprinkled across screens. Refactors hurt, tests need heavy UI harnesses, and new teammates lack a single map of “who decides what.”

## What Omega optimizes for

- **Thin UI** — screens emit **intents** and render **expressions**; they do not own domain rules.
- **One nervous system** — **`OmegaChannel`** carries events; **flows** and **agents** subscribe and collaborate predictably.
- **Safer refactors** — typed events and intents, optional **contracts** (debug warnings when wiring drifts).
- **Debuggable sessions** — **inspector** (in-app or browser + VM Service) and **time-travel** traces.
- **Velocity** — **`omega`** CLI scaffolds ecosystems, validates projects, and optional **Omi** AI helpers.

## When to look elsewhere

Omega adds structure. Prototypes that intentionally throw away code, or apps with almost no cross-screen coordination, might not need it yet. If you adopt Omega, commit to **intents + channel + flows/agents** as the default path for features.

## Next

1. **[Core concepts](./concepts)** — glossary  
2. **[Data flow](./data-flow)** — end-to-end path  
3. **[Getting started](./getting-started)** — install and first commands  

Deep reference in repo: [GUIA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md) (Spanish walkthrough with code).
