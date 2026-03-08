## 0.0.6

- **CLI fix:** When running `g agent <Name>` or `g flow <Name>` separately, the CLI now only removes and re-adds the import for the artifact being registered (agent or flow), so the other import is preserved. Previously, running `g flow Orders` after `g agent Orders` could remove the agent import.
- **Snapshot (Paso 2):** `OmegaFlowSnapshot` and `OmegaAppSnapshot` for debugging, persistence, and time-travel. `OmegaFlow.getSnapshot()`, `OmegaFlowManager.getFlowSnapshot`, `getSnapshots`, `getAppSnapshot`. Documentation of purpose in dartdoc and ARQUITECTURA.
- **Logging (Paso 3):** Replaced `print` with `debugPrint` in `omega_navigator.dart` and `omega_bootstrap.dart` (lib) so diagnostics only appear in debug mode.
- **Navigation (Paso 4):** Contract documented (`navigation.intent`, `navigate.*`). `navigate.<id>` = pushReplacement, `navigate.push.<id>` = push. Intent payload passed as `RouteSettings.arguments`. Constant `navigationIntentEvent`.
- **Testing (Paso 5):** More unit tests (agent receiveIntent, flow receiveIntent running/idle, OmegaFlowExpression). `example/README.md` for minimal login flow. `docs/TESTING.md` for testing agents and flows without Flutter.
- **CLI (Paso 6):** Clearer error messages (prefix "Error:", absolute paths). New generators: `omega g agent <Name>`, `omega g flow <Name>`. `omega validate` checks omega_setup.dart (structure, duplicate ids). All generators create files in the terminal’s current directory (CWD).
- **Docs:** ARQUITECTURA.md and README kept in sync with snapshot, navigation, testing, and CLI.

## 0.0.5

- Fix static analysis: enclose `while` body in a block in `bin/omega.dart` (pub.dev lint).

## 0.0.4

- CLI `g ecosystem`: create files in the **current directory** (where you run the command), not forced under `lib/`.
- CLI: refresh imports in `omega_setup.dart` (replace old paths with the correct one for the ecosystem).
- CLI: register both **Agent** and **Flow** in `OmegaConfig`; add `flows:` section if missing in `omega_setup.dart`.
- Docs: README and web updated with CLI behavior (CWD, path refresh, flow registration).

## 0.0.3

- Add official example in `example/lib/main.dart` for pub.dev scoring.
- Tweak documentation (README and website) to point to pub.dev installation.

## 0.0.2

- Publish on pub.dev and switch docs/install to pub.dev usage (`omega_architecture: ^0.0.2`).
- Add web documentation (presentation) and architecture diagram.
- Improve CLI behavior (flows/agents registration, no auto-route creation).
- Clarify runtime bootstrap and flow activation from the app host.

## 0.0.1

- Initial release of Omega Architecture: core agents/flows/channel runtime, basic CLI and auth example.
