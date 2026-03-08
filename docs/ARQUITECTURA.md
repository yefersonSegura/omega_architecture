# Arquitectura Omega

Este documento describe qué hace cada parte del framework Omega para que quien lo use sepa cómo encaja todo.

---

## Visión general

Omega es un framework **reactivo y basado en agentes** para Flutter. La lógica de negocio vive en **agentes** y **flujos** que se comunican por un **canal de eventos**. La UI solo refleja lo que el sistema decide (eventos, expresiones, navegación).

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│     UI      │────▶│  OmegaChannel    │◀────│   Agentes   │
│ (Scope,     │     │  (bus eventos)   │     │  + Flows    │
│  Builder)   │◀────│                  │────▶│             │
└─────────────┘     └──────────────────┘     └─────────────┘
       │                      │                      │
       │                      ▼                      │
       │             OmegaFlowManager                │
       │             (activa/pausa flows,           │
       │              enruta intents)                │
       │                      │                      │
       └──────────────────────┼──────────────────────┘
                              ▼
                    OmegaNavigator
                    (navegación por intents)
```

---

## Core (núcleo)

### OmegaChannel

**Qué es:** El bus de eventos central. Todo el mundo que quiera comunicarse (agentes, flows, UI) usa el mismo canal.

**Qué hace:** Expone un `Stream<OmegaEvent>` al que te suscribes. Cualquiera puede llamar a `emit(OmegaEvent)` para publicar. Los agentes y flows escuchan eventos y reaccionan.

**Responsabilidad de ciclo de vida:** Quien crea el canal debe llamar a `dispose()` al cerrar la app.

---

### OmegaEvent

**Qué es:** Un evento que se emite por el canal. Tiene `id`, `name` (ej. `"auth.login.success"`) y `payload` (datos opcionales).

**Qué hace:** Representa “algo que pasó” en el sistema. Los agentes y flows escuchan por `event.name` y leen `event.payload` para actuar.

---

### OmegaIntent

**Qué es:** Una intención o petición de acción. Tiene `id`, `name` (ej. `"navigate.login"`) y `payload` opcional.

**Qué hace:** La UI (u otro componente) no llama directamente a métodos; emite un intent. El [OmegaFlowManager] enruta los intents a los flows que estén en `running`. También se usan para navegación: el canal emite un evento con payload [OmegaIntent] y el navegador reacciona.

---

### OmegaObject

**Qué es:** Clase base de los objetos del sistema. Proporciona `id` y `meta` (mapa de metadatos).

**Qué hace:** [OmegaEvent], [OmegaIntent] y [OmegaFailure] extienden de OmegaObject para tener identificador y metadatos de forma consistente.

---

### OmegaFailure

**Qué es:** Representación de un error o fallo. Tiene `message` y `details` opcional.

**Qué hace:** Útil para emitir errores semánticos por el canal o devolverlos desde agentes/flows de forma tipada.

---

## Agentes

### OmegaAgent

**Qué es:** La unidad de lógica autónoma. Tiene un `id`, un [OmegaChannel] y un motor de comportamiento ([OmegaAgentBehaviorEngine]).

**Qué hace:** Se suscribe al canal. Cuando llega un evento (o un mensaje directo), el **behavior** evalúa el contexto y devuelve una reacción (acción + payload). El agente ejecuta esa acción en `onAction`. La lógica no vive en la UI; vive en el agente y se puede testear sin Flutter.

**Ciclo de vida:** Llamar a `dispose()` para que deje de escuchar el canal.

---

### OmegaAgentBehaviorEngine

**Qué es:** El “cerebro” del agente: evalúa reglas y devuelve qué hacer.

**Qué hace:** Recibe un [OmegaAgentBehaviorContext] (evento, intent, estado del agente) y devuelve una [OmegaAgentReaction] (nombre de acción + payload) o `null` si ninguna regla aplica. Puedes extender esta clase y sobrescribir `evaluate`, o usar reglas con [OmegaAgentBehaviorRule].

---

### OmegaAgentBehaviorContext

**Qué es:** El contexto que recibe el behavior en cada evaluación: el evento actual, la intención (si hay) y una copia del estado interno del agente.

**Qué hace:** Proporciona toda la información que el motor de reglas necesita para decidir la reacción.

---

### OmegaAgentReaction

**Qué es:** El resultado de una regla: una acción a ejecutar y un payload.

**Qué hace:** El agente recibe la reacción y la ejecuta en `onAction(String action, dynamic payload)`.

---

### OmegaAgentBehaviorRule

**Qué es:** Una regla concreta que el motor puede evaluar (condición + reacción).

**Qué hace:** Permite componer el comportamiento del agente por reglas en lugar de un solo `evaluate` gigante.

---

### OmegaAgentProtocol

**Qué es:** El registro central de agentes. Conoce todos los agentes por id.

**Qué hace:** Permite enviar mensajes **directos** a un agente (`sendTo`) o **broadcast** a todos (`broadcast`). Los agentes se registran aquí en el bootstrap. No es el canal global; es comunicación punto a punto o broadcast entre agentes.

---

### OmegaAgentMessage / OmegaAgentInbox

**Qué es:** Mensaje que un agente recibe (por el protocolo o por el canal) y la bandeja de entrada del agente.

**Qué hace:** Encapsulan la comunicación directa entre agentes para no acoplar implementaciones.

---

## Flows

### OmegaFlow

**Qué es:** Un flujo de negocio (ej. login, checkout). Tiene estados (idle, running, paused, sleeping, ended) y emite **expresiones** hacia la UI.

**Qué hace:** Se suscribe al canal. Cuando está en `running`, recibe eventos globales y recibe intents (enrutados por el [OmegaFlowManager]). En `onEvent` y `onIntent` decides qué hacer: emitir expresiones, navegar (emitir un intent de navegación), pedir trabajo a un agente, etc. La UI escucha el stream `expressions` del flow para actualizarse.

**Ciclo de vida:** Se activa con `flowManager.activate(id)` o `flowManager.switchTo(id)`. Se pausa, duerme o finaliza con los métodos del manager. Al finalizar, el flow cierra su stream de expresiones.

---

### OmegaFlowManager

**Qué es:** El gestor de todos los flows registrados. Sabe cuáles están en ejecución y enruta los intents.

**Qué hace:**
- **registerFlow(flow):** Registra un flow por su `id`.
- **activate(id):** Pone el flow en `running` sin pausar los demás (varios flows pueden estar activos).
- **switchTo(id):** Activa ese flow y pausa el resto (un solo “principal”).
- **handleIntent(intent):** Envía el intent a todos los flows que estén en `running`.
- **wireNavigator(navigator):** Conecta el canal al navegador: cuando se emite un evento `navigation.intent` o `navigate.*`, el navegador ejecuta la ruta.

También ofrece `pause`, `sleep`, `end` por flow. Es idempotente: activar dos veces el mismo flow no hace nada extra.

**Ciclo de vida:** Llamar a `dispose()` para cancelar la suscripción usada en `wireNavigator`.

---

### OmegaFlowState

**Qué es:** Enum con los estados de un flow: `idle`, `running`, `sleeping`, `paused`, `ended`.

**Qué hace:** Solo los flows en `running` reciben intents y procesan eventos. El resto está en espera o finalizado.

---

### OmegaFlowExpression

**Qué es:** Un mensaje que un flow emite hacia la UI (ej. `"loading"`, `"success"`, `"error"` con payload).

**Qué hace:** El flow llama a `emitExpression(tipo, payload)`. La UI se suscribe a `flow.expressions` y reconstruye según la última expresión. Así la UI no pregunta “¿cuál es el estado?”; el flow lo anuncia.

---

### OmegaFlowContext

**Qué es:** El contexto que recibe un flow en `onEvent` y `onIntent`: el evento (si hay), la intención (si hay) y referencia al flow.

**Qué hace:** Proporciona la información necesaria para que el flow decida qué expresión emitir o qué navegación disparar.

---

### OmegaFlowSnapshot / OmegaAppSnapshot

**Qué es:** [OmegaFlowSnapshot] es una **foto** del estado de un flow: `flowId`, `state`, copia de `memory` y última expresión emitida. [OmegaAppSnapshot] agrupa el `activeFlowId` y la lista de snapshots de todos los flows. No modifican nada; solo **leen** el estado.

**Qué hace:** [OmegaFlow.getSnapshot] devuelve el snapshot de un flow. [OmegaFlowManager.getFlowSnapshot(id)], [getSnapshots] y [getAppSnapshot] exponen el estado actual. La memoria en el snapshot es una copia superficial (no se debe modificar el flow desde fuera).

**Para qué sirve (en resumen):**

- **Depuración:** Cuando algo falla, puedes obtener un snapshot y ver en qué estado estaba cada flow, qué había en la memoria y cuál fue la última “pantalla” que el flow le dijo a la UI. Así entiendes qué estaba pasando sin llenar el código de prints.
- **Persistencia:** Si quieres que al cerrar la app no se pierda todo, antes de cerrar llamas a `getAppSnapshot()` (o los `getSnapshot()` que necesites), guardas ese dato (disco, backend, etc.) y al reabrir lo lees y reconstruyes el estado. El snapshot te dice *qué había*; tú decides cómo guardarlo y restaurarlo.
- **Time-travel (avanzado):** En herramientas de desarrollo a veces se guarda un historial de snapshots; si algo sale mal, “vuelves atrás” a un snapshot anterior y ves cómo estaba la app. Es como un guardado de partida, pero del estado de tus flows.

En una frase: la finalidad es **poder ver (y opcionalmente guardar) el estado actual de los flows y de la app sin modificar nada**, para depurar, persistir o inspeccionar.

---

## UI (Flutter)

### OmegaScope

**Qué es:** Un [InheritedWidget] que inyecta [OmegaChannel] y [OmegaFlowManager] (y opcionalmente `initialFlowId`) en el árbol.

**Qué hace:** La app lo pone en la raíz. Cualquier hijo hace `OmegaScope.of(context)` para obtener el canal y el flow manager (y el id del flow inicial si se definió). No hace `dispose`; quien crea el channel y el manager debe llamar a su `dispose()`.

---

### OmegaBuilder

**Qué es:** Widget que se reconstruye cuando se emite un evento con un `eventName` concreto en el canal.

**Qué hace:** Se suscribe al canal y cuando llega un [OmegaEvent] con ese nombre, llama al `builder` con el evento. Útil para actualizar solo una parte de la UI cuando ocurre algo (ej. `user.updated`).

---

### OmegaInspector

**Qué es:** Panel de inspección (DevTools mínimo) que muestra en tiempo real los últimos eventos del canal y el estado de todos los flows (snapshot).

**Qué hace:** Usa [OmegaScope.of](context). Lista los últimos N eventos (nombre, payload resumido, hora) y, cada 2 s, un snapshot de los flows (id, estado, última expresión, tamaño de memory). Incluye botón para colapsar/expandir y refrescar. Pensado para **debug**; en release se puede ocultar con `kDebugMode`. Colócalo en un [Stack] o en un [Drawer] para inspeccionar sin interferir con la app.

**Inspector en otra ventana del navegador (estilo Isar):** En **web** puedes abrir el inspector en una pestaña/ventana aparte:

1. Añade **`OmegaInspectorLauncher`** (p. ej. en la AppBar, solo en debug). Al pulsar, en web se abre una nueva ventana con la misma app y `?omega_inspector=1`.
2. En el `main()` de tu app, si la URL tiene `omega_inspector=1`, muestra solo **`OmegaInspectorReceiver`** como pantalla inicial (ej.: `if (Uri.base.queryParameters['omega_inspector'] == '1') runApp(MaterialApp(home: OmegaInspectorReceiver()));`).
3. La ventana principal envía eventos y snapshots al receiver por **BroadcastChannel**; la ventana del inspector los muestra en tiempo real.

En plataformas no-web, el launcher abre el [OmegaInspector] en un diálogo.

---

### OmegaNavigator

**Qué es:** El puente entre intents de navegación y el [Navigator] de Flutter. Tiene una [GlobalKey] del Navigator.

**Contrato de navegación (canal):** El [OmegaFlowManager.wireNavigator] escucha dos formas de evento:
- **"navigation.intent"** con payload [OmegaIntent] → se llama `handleIntent(payload)`.
- **"navigate.xxx"** o **"navigate.push.xxx"** → se construye un intent con ese nombre y se llama `handleIntent`.

**Comportamiento de handleIntent:**
- **"navigate.&lt;id&gt;"** (ej. `navigate.login`) → reemplaza la pantalla actual (pushReplacement).
- **"navigate.push.&lt;id&gt;"** (ej. `navigate.push.detail`) → apila la pantalla (push). Útil para flujos donde el usuario puede volver atrás.
- El [OmegaIntent.payload] se pasa a la pantalla como [RouteSettings.arguments]; en el builder puedes leerlo con `ModalRoute.of(context)?.settings.arguments`.

**Qué hace:** Registras rutas con `registerRoute(OmegaRoute)`. Los mensajes de diagnóstico usan `debugPrint` (solo en debug).

---

### OmegaRoute

**Qué es:** Una ruta registrada en el navegador: `id` (ej. `"login"`) y un `builder` que devuelve el widget de la pantalla.

**Qué hace:** Define las pantallas que el navegador puede mostrar. "navigate.login" o "navigate.push.login" llevan a la ruta con `id: "login"`. Los argumentos del intent (payload) están en `RouteSettings.arguments` para el builder.

---

### OmegaNavigationEntry

**Qué es:** Representación interna de una “entrada” de navegación (qué ruta y con qué argumentos).

**Qué hace:** Lo usa el [OmegaNavigator] para ejecutar el push/pop correspondiente.

---

## Bootstrap (arranque)

### OmegaConfig

**Qué es:** La configuración que defines en tu app (en `omega_setup.dart`): lista de agentes, lista de flows, rutas y opcionalmente `initialFlowId`.

**Qué hace:** La función `createOmegaConfig(OmegaChannel)` devuelve este config. El [OmegaRuntime] lo usa para registrar agentes en el protocolo, flows en el manager y rutas en el navegador. Si pones `initialFlowId`, el runtime lo expone para que la app active ese flow al primer frame.

---

### OmegaRuntime

**Qué es:** El resultado del arranque: canal, flow manager, protocolo de agentes, navegador y `initialFlowId`.

**Qué hace:** `OmegaRuntime.bootstrap(createOmegaConfig)` crea el canal, construye el config, registra todo y devuelve el runtime. La app usa `runtime.channel`, `runtime.flowManager`, `runtime.navigator` y opcionalmente `runtime.initialFlowId` para montar [OmegaScope] y [MaterialApp], y en el primer frame activar el flow inicial y/o emitir la primera intención de navegación.

---

## Orden típico de uso

1. Definir `createOmegaConfig` con agentes, flows, rutas y `initialFlowId` si aplica.
2. En `main`, llamar a `OmegaRuntime.bootstrap(createOmegaConfig)`.
3. Envolver la app con `OmegaScope(channel, flowManager, initialFlowId, child: MyApp(navigator: runtime.navigator))`.
4. En [MaterialApp], usar `navigatorKey: runtime.navigator.navigatorKey` y un `home` que en `addPostFrameCallback` active el flow inicial (`flowManager.switchTo(scope.initialFlowId!)`) y/o emita la intención de navegación inicial.
5. En las pantallas, usar `OmegaScope.of(context)` para acceder al canal y al flow manager, y `OmegaBuilder` o el stream `flow.expressions` para reaccionar a eventos y expresiones.
6. Al cerrar la app, llamar a `channel.dispose()` y `flowManager.dispose()` (y `agent.dispose()` por cada agente si los creaste fuera del protocolo).

Con esto, quien use Omega puede ver en un solo documento qué hace cada pieza y cómo encaja en la arquitectura.
