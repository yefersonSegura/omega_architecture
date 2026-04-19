# Omega vs other Flutter approaches

Omega is **not a replacement for Flutter** — it is a **structure** for how screens, coordination, and side effects talk to each other. Here is an honest comparison so you can choose deliberately.

---

## Omega vs BLoC / Cubit

| Topic | BLoC / Cubit | Omega |
|-------|----------------|-------|
| **Unit of logic** | Bloc/Cubit classes + streams | **Flows** (orchestration) + **agents** (IO + rules) + **channel** |
| **UI contract** | `BlocBuilder`, `context.read` | **Intents**, **expressions**, `OmegaScope`, builders |
| **Navigation** | Often imperative or router package | **Navigation intents** wired through [OmegaNavigator](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaNavigator-class.html) |
| **Global events** | `BlocProvider` tree or event bus libs | **One [OmegaChannel](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaChannel-class.html)** (+ namespaces) |

**Choose Omega** when you want **one bus**, **flow-centric features**, and **agent-shaped** domain code with first-class **inspector / trace** tooling. **Choose BLoC** when your team already standardised on it and you do not need Omega’s vocabulary.

---

## Omega vs Riverpod

| Topic | Riverpod | Omega |
|-------|-----------|-------|
| **State access** | `ref.watch` / providers | **Scope** + channel streams + flow expressions |
| **Side effects** | `AsyncNotifier`, family providers, etc. | **Agents** + **behavior** reactions |
| **Testability** | Override providers in tests | Inject channel / manager; drive events and intents |

**Choose Riverpod** for **fine-grained reactive graph** and ecosystem. **Choose Omega** when you model product work as **flows** and **cross-cutting channel traffic** matters.

---

## Omega vs “setState + services”

Ad-hoc services from widgets scale poorly. Omega pushes **intents**, **typed events**, and **explicit flow state** so refactors have a spine. The **`omega validate`** command encodes common mistakes (duplicate route ids, cold start, etc.).

---

## When Omega is too much

- Throwaway prototypes with **no shared coordination**  
- Apps with **almost no cross-screen** business rules  

For everything else, start with **[Getting started](./getting-started)** and the **`example/`** app.
