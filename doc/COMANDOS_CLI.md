 # Comandos del CLI Omega

Referencia para quien desarrolla con el paquete **omega_architecture**. El ejecutable se declara en `pubspec.yaml` como `omega` (véase `executables`).

Para la ayuda integrada en terminal:

```bash
dart run omega_architecture:omega --help
dart run omega_architecture:omega ai --help
```

---

## Cómo ejecutar el CLI

| Forma | Cuándo usarla |
|--------|----------------|
| `dart run omega_architecture:omega <comando> …` | Proyecto que ya tiene `omega_architecture` en `pubspec.yaml` (recomendado en CI y equipos). |
| `dart pub global activate omega_architecture` y luego `omega …` | Comando `omega` en el PATH (ver [README](../README.md#1-global-activation)). |
| `dart run bin/omega.dart …` | Solo al trabajar **dentro del repo** del paquete. |

**Directorio de trabajo**

- `init`, `validate`, `doctor`, `create app`, `ai …`: suele ejecutarse desde la **raíz del proyecto Flutter** (donde está `pubspec.yaml`).
- `g ecosystem` / `g agent` / `g flow`: desde la **carpeta donde quieres crear** los archivos del módulo (p. ej. `lib/features/pedidos`).

---

## Resumen rápido

| Comando | Descripción breve |
|---------|-------------------|
| `doc` | Abre la documentación web en el navegador. |
| `inspector` | Abre el Inspector local (HTML) para conectar al VM Service de la app en ejecución. |
| `init [--force]` | Crea `lib/omega/omega_setup.dart`, y si faltan `app_semantics.dart` / `app_runtime_ids.dart` también los crea (`--force` solo sobrescribe `omega_setup`). |
| `g ecosystem <Nombre>` | Genera agente, flow, behavior y página; **actualiza** `lib/omega/app_runtime_ids.dart` (debe existir: `omega init`); registra en `omega_setup`. |
| `g agent <Nombre>` | Solo agente + behavior. |
| `g flow <Nombre>` | Solo flow. |
| `validate [ruta]` | Valida `omega_setup` (estructura, **mismo `id:` en dos `OmegaRoute`**, **misma variable dos veces en `agents:`**, **mismo `*Flow` repetido en `flows:`**), rutas vs `*Page`). Si hay **al menos una ruta y un flow**, exige **`initialFlowId`** y **`initialNavigationIntent`**. Comprueba **`AppIntent.navigateLogin` / `navigateHome` / `navigateRoot`** ↔ `OmegaRoute(id: …)` cuando aparecen en el archivo. |
| `trace view <archivo.json>` | Resumen de una traza grabada. |
| `trace validate <archivo.json>` | Valida el JSON; código de salida 0/1. |
| `doctor [ruta]` | Salud del proyecto (setup, conteos, sugerencias de contratos). |
| `create app <Nombre>` | Nuevo proyecto Flutter con Omega preconfigurado. |
| `ai doctor` | Comprueba variables y clave de IA. |
| `ai env` | Lista variables de entorno soportadas. |
| `ai explain <trace.json>` | Explicación de traza (offline y/o con API). |
| `ai coach …` | Plan, auditoría, módulo con IA o rediseño solo UI (ver abajo). |

Alias: `g` = `generate` = `create` (excepto `create app`, que es otro comando).

Opciones globales: `-h` / `--help`, `-v` / `--version`.

---

## Comandos principales

### `doc`

Abre el sitio de documentación configurado (no modifica el proyecto).

```bash
dart run omega_architecture:omega doc
```

### `inspector`

Abre el HTML del Inspector Omega para depuración en tiempo de ejecución (conexión al **Dart VM Service**). Útil junto con la app en modo debug. Más detalle: [INSPECTOR.md](INSPECTOR.md) y el [README § Inspector](../README.md).

```bash
dart run omega_architecture:omega inspector
```

### `init`

Crea `lib/omega/omega_setup.dart` si no existe. También crea `lib/omega/app_semantics.dart` y `lib/omega/app_runtime_ids.dart` si no están: `AppIntent` incluye por defecto **`navigateRoot`** (wire `navigate.root` → ruta id **`root`**) más `navigationIntent`; amplía enums según tu producto. `AppFlowId`/`AppAgentId` con placeholders. Con `--force`, sobrescribe solo `omega_setup.dart`.

```bash
dart run omega_architecture:omega init
dart run omega_architecture:omega init --force
```

### Generación: `g ecosystem`, `g agent`, `g flow`

- **ecosystem:** carpeta del módulo con `*_agent`, `*_flow`, `*_behavior`, `ui/*_page.dart`; **fusiona** ids en `lib/omega/app_runtime_ids.dart` (debe existir: ejecutar `omega init` antes) y actualiza imports/registros en `omega_setup.dart`.
- **agent / flow:** solo el artefacto indicado y la parte correspondiente del setup.

```bash
cd lib
dart run omega_architecture:omega g ecosystem Auth
dart run omega_architecture:omega g agent Orders
dart run omega_architecture:omega g flow Profile
```

### `validate`

Analiza `lib/omega/omega_setup.dart` y coherencia con páginas (`*Page` y parámetro `agent` en rutas). Opcionalmente una carpeta inicial de búsqueda (monorepo). Falla si hay **dos rutas con el mismo `OmegaRoute(id: …)`**, si en `agents: <OmegaAgent>[...]` aparece **dos veces la misma variable** (p. ej. `orderManagementAgent` duplicado) o **dos constructores `FooAgent(channel)`** del mismo módulo, o si en `flows:` hay **dos líneas del mismo `FooFlow(...)`**. Con **rutas y flows** registrados, exige **`initialFlowId`** y **`initialNavigationIntent`**. Acepta listas de rutas como `routes: <OmegaRoute>[...]` o `routes: [...]`.

```bash
dart run omega_architecture:omega validate
```

### `trace view` / `trace validate`

Trabajan con JSON exportado desde **OmegaTimeTravelRecorder** / sesión grabada. Ver [TIME_TRAVEL.md](TIME_TRAVEL.md).

```bash
dart run omega_architecture:omega trace view trace.json
dart run omega_architecture:omega trace validate trace.json
```

### `doctor`

Informe de salud: setup válido, recuento de agents/flows, avisos opcionales (p. ej. contratos). El argumento opcional es la carpeta desde la que empezar a buscar `pubspec.yaml` (útil en monorepos: `omega doctor example`).

```bash
dart run omega_architecture:omega doctor
dart run omega_architecture:omega doctor example
```

### `create app <nombre>`

Crea un proyecto Flutter nuevo con Omega enlazado, `main` de arranque y `omega init`. Opciones:

- `--kickstart "descripción"` — contexto para generación asistida por IA.
- `--provider-api` — usar API del proveedor cuando la generación lo permita.

```bash
omega create app mi_app
omega create app mi_app --kickstart "login, perfil y ajustes" --provider-api
```

Ejecutar **fuera** de un proyecto Flutter existente (es un creador de carpetas).

---

## Subcomando `ai`

### `ai doctor` y `ai env`

Comprueban configuración e imprimen ayuda de variables (`OMEGA_AI_ENABLED`, `OMEGA_AI_PROVIDER`, `OMEGA_AI_API_KEY`, `OMEGA_AI_MODEL`, `OMEGA_AI_BASE_URL`, etc.). Lista ampliada y contexto del paquete: salida de `ai env`.

### `ai explain <archivo.json>`

Interpreta una traza. Modificadores comunes:

- `--json` — salida pensada para máquinas.
- `--provider-api` — intenta modelo remoto (p. ej. OpenAI) con retorno a heurística offline si falla.
- `--stdout` — imprime en consola en lugar de archivo temporal.

### `ai coach`

Acciones (primera palabra tras `coach`):

| Acción | Uso típico |
|--------|------------|
| `start` | Plan guiado para implementar una feature: `"omega ai coach start \"login con MFA\""`. |
| `audit` | Auditar huecos del proyecto para una feature concreta. |
| `module` | Generar (o evolucionar) un módulo completo con asistencia de IA. |
| `redesign` | Regenerar **solo** `ui/*_page.dart`; no toca events/agent/flow/behavior. |

**Opciones comunes del coach**

- `--template basic|advanced` — plantilla del scaffold (por defecto suele ser `advanced` en flujos de diseño).
- `--provider-api` — usar API configurada cuando aplique.
- `--json` / `--stdout` — formato de salida (informes en archivo temporal por defecto).
- `--module` / `-m` — módulo explícito en `module` / `redesign` cuando haga falta acotar el nombre.

Ejemplos:

```bash
dart run omega_architecture:omega ai coach start "onboarding en tres pasos"
dart run omega_architecture:omega ai coach audit "auth"
dart run omega_architecture:omega ai coach module "Delivery: lista de pedidos en tiempo real" --template advanced --provider-api
dart run omega_architecture:omega ai coach redesign "Auth: barra de búsqueda y filtros" --template advanced --provider-api
```

La IA y la auto-sanación del CLI respetan el contexto del paquete (ejemplos en `example/`) salvo que desactives variables como `OMEGA_AI_SKIP_PACKAGE_CONTEXT`. Ver salida de `omega ai env`.

---

## Documentación relacionada

- **Sitio / HTML local:** la misma guía interactiva está en [presentation/index.html](../presentation/index.html) (ES) y [presentation/index-en.html](../presentation/index-en.html) (EN): sección **CLI** con pestañas; enlaza aquí y al README para la tabla completa. Tras publicar o copiar `presentation/` al hosting, `omega doc` puede abrir esa URL.
- [README principal](../README.md) — Instalación global, flujo “Quick Start” y sección **Omega CLI** en inglés (mismo contenido ampliado con ejemplos de éxito/error).
- [GUIA.md](GUIA.md) — Uso de channel, intents, flows y agentes en código.
- [TIME_TRAVEL.md](TIME_TRAVEL.md) — Trazas y `trace view` / `validate`.
- [INSPECTOR.md](INSPECTOR.md) — Inspector y VM Service.
- [TESTING.md](TESTING.md) — Pruebas sin Flutter UI.

### Omega Studio (opcional, no publicado en marketplace)

En el repositorio existe la carpeta `omega_studio/` con una extensión para VS Code/Cursor que lanza los mismos comandos `omega` desde la paleta. Es **opcional**; para uso local puedes empaquetar un `.vsix` con `@vscode/vsce` si lo necesitas el equipo. No forma parte del paquete publicado en pub.dev.
