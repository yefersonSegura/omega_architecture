## 0.0.13

- **Pub.dev:** README solo con enlaces https (documentación apunta a pub.dev API reference). CLI: cuerpo del `if` en `bin/omega.dart` envuelto en bloque para pasar el lint y recuperar puntos.

## 0.0.12

- **Favicon:** Favicon SVG con símbolo Omega dibujado por path (sin depender de fuentes). Enlace en `presentation/index.html`.
- **CLI:** Comando `omega doc` abre la documentación web oficial en el navegador.
- **Documentación web:** Barra de progreso de lectura, botón copiar en bloques de código, tema claro/oscuro con persistencia, botón scroll-to-top, meta SEO, breadcrumbs, footer con versión, accesibilidad (skip-link, focus-visible). Iconos Font Awesome en sidebar y navegación.
- **Docs:** GUIA.md, README con badge de documentación, example con enlace a la doc. pubspec: documentation, issue_tracker.

## 0.0.11

- **Documentación:** [docs/COMPARATIVA.md](docs/COMPARATIVA.md) con comparativa Omega vs BLoC vs Riverpod y cuándo elegir cada uno. Web (presentation) declarada como documentación completa; enlace "Comparativa" en la navegación. README y ROADMAP actualizados.
- **Inspector:** Diseño moderno (tema azul, gradientes, tarjetas con sombra, pills para estado y conteos). Mismo estilo en overlay y ventana remota (web).
- **Inspector web:** Al cerrar la ventana del inspector y volver a abrir, se usa un nombre de ventana único para que el navegador abra una ventana nueva correctamente.

## 0.0.10

- **Pub.dev static analysis:** Inspector web migrado de `dart:html` a `package:web` y `dart:js_interop` para eliminar el INFO de deprecación y recuperar los 10 puntos en "Pass static analysis". Dependencia `web: ^1.0.0` añadida.

## 0.0.9

- **Eventos e intents tipados:** [OmegaEventName] y [OmegaIntentName] (interfaces) + [OmegaEvent.fromName] y [OmegaIntent.fromName] para usar enums o clases y evitar strings mágicos (autocompletado, refactors). Documentación en README, ARQUITECTURA y ROADMAP; tests en omega_channel_test y omega_intent_test.
- **Example:** `example/lib/omega/app_semantics.dart` con enums AppEvent y AppIntent; main, auth_flow, auth_agent, auth_behavior y auth_page usan fromName y los nombres tipados. example/README.md actualizado.

## 0.0.8

- **Persistencia y restore:** Serialización de snapshots con `OmegaFlowSnapshot.toJson`/`fromJson` y `OmegaAppSnapshot.toJson`/`fromJson`. `OmegaFlow.restoreMemory` y `OmegaFlowManager.restoreFromSnapshot` para recuperar estado al abrir la app. Interfaz opcional `OmegaSnapshotStorage` (save/load). Documentación en README, ARQUITECTURA y ROADMAP.
- **Pub.dev:** `dependency_overrides: meta: ^1.18.1` para pasar "Support up-to-date dependencies" en el análisis estático.

## 0.0.7

- **Inspector en ventana separada (web, estilo Isar):** [OmegaInspectorLauncher] abre el inspector en otra pestaña/ventana del navegador; la app envía datos por BroadcastChannel. [OmegaInspectorReceiver] muestra eventos y snapshots en esa ventana. En plataformas no-web el launcher abre el inspector en un diálogo. Documentación en README y ARQUITECTURA.

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
