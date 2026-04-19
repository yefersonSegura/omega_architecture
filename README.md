# Ω Omega Architecture



<p align="center">

  <img src="assets/omega_logo.svg" alt="Omega Architecture Logo" width="220">

</p>



[![pub package](https://img.shields.io/pub/v/omega_architecture.svg)](https://pub.dev/packages/omega_architecture)

[![documentation](https://img.shields.io/badge/docs-site%20%26%20API-blue)](https://yefersonsegura.github.io/omega_architecture/)

[![API](https://img.shields.io/badge/pub.dev-API-0175C2)](https://pub.dev/documentation/omega_architecture/latest)



**Omega** turns messy Flutter apps into something you can reason about: **thin screens**, **flows** that orchestrate, **agents** that do the real work, and **one channel** so every feature speaks the same language. You ship faster, refactor safer, and debug with an **inspector** and **traces** instead of guesswork.



---



## Why Omega



| You want | You get |

|----------|---------|

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



Add Pub’s global **`bin`** to your **`PATH`** (Windows: `%LOCALAPPDATA%\Pub\Cache\bin`). If `omega` is not found, see **[doc/COMANDOS_CLI.md](doc/COMANDOS_CLI.md)** — PATH, shims, and `dart run omega_architecture:omega …`.



**Existing app:** add **`omega_architecture`** from [pub.dev](https://pub.dev/packages/omega_architecture) to `pubspec.yaml`, then `dart run omega_architecture:omega init` from the app root.



---



## What it feels like



The UI says what it wants (**intent**). **Flows** coordinate. **Agents** react through a **behavior** engine. The channel carries **events**; navigation and state surface as predictable **streams** — not `setState` spaghetti across the tree.



```dart

OmegaScope(

  channel: channel,

  flowManager: flowManager,

  child: const MyApp(),

);

```



More depth: **[site](https://yefersonsegura.github.io/omega_architecture/)** · **[doc/GUIA.md](doc/GUIA.md)** (walkthrough + code) · **[API](https://pub.dev/documentation/omega_architecture/latest)**



---



## CLI at a glance



|  |  |

|--|--|

| **`omega create app`** | New Flutter app, Omega wired |

| **`omega init`** | Drop Omega into an existing app |

| **`omega g ecosystem <Name>`** | Flow + agent + behavior + page |

| **`omega validate` / `doctor`** | Catch wiring mistakes early |

| **`omega inspector`** | VM Service → inspect in the browser |

| **`omega ai coach …`** | Optional — scaffold or evolve modules (env + API keys) |



Full command matrix: **[doc/COMANDOS_CLI.md](doc/COMANDOS_CLI.md)**



---



## Where to look next



| Link | For |

|------|-----|

| **[Web docs](https://yefersonsegura.github.io/omega_architecture/)** | Guides, architecture map, `/doc/` mirror (Spanish deep dives) |

| **[doc/GUIA.md](doc/GUIA.md)** | Copy-paste tour of every piece |

| **[doc/INSPECTOR.md](doc/INSPECTOR.md)** | Overlay, launcher, VM / browser |

| **[example/](example/)** | Reference login flow — `cd example && flutter run` |



---



## Package layout



```

lib/omega/   → core (channel, intents, events) · agents · flows · ui · bootstrap

lib/omega_architecture.dart   → public exports

```



---



## License



MIT — [LICENSE](LICENSE)


