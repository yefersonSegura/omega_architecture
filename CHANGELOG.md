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
