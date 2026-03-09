# Guía de uso: Omega Architecture

Esta guía explica **qué hace cada parte de Omega** y muestra **ejemplos de código** para usarlas. Para el detalle técnico completo, ver [ARQUITECTURA.md](ARQUITECTURA.md).

---

## ¿Qué es Omega?

Omega es un framework de arquitectura para Flutter en el que:

- La **lógica de negocio** vive en **agentes** y **flujos**, no en la UI.
- Todo se comunica por un **canal de eventos** (OmegaChannel).
- La **UI** solo emite **intenciones** (intents) y reacciona a **eventos** y **expresiones**; no llama a métodos ni conoce rutas.
- Un **FlowManager** orquesta qué flujo está activo y reparte los intents.
- Un **navegador** (OmegaNavigator) traduce intents de navegación en pantallas.

**En una frase:** La UI dice “quiero hacer X”; el canal y los flows/agentes lo resuelven; la UI solo muestra el resultado.

---

## Flujo de datos resumido

1. **UI** → emite un **intent** (p. ej. "login" con credenciales) al canal o al FlowManager.
2. **Flow** (en running) recibe el intent en `onIntent`; puede emitir eventos al canal (p. ej. "auth.login.request").
3. **Agente** escucha ese evento; su **behavior** decide la reacción (p. ej. "doLogin"); el agente ejecuta y emite "auth.login.success" o "auth.login.error".
4. **Flow** escucha el evento en `onEvent`; emite **expresiones** hacia la UI ("loading", "success", "error") y/o un **intent de navegación** ("navigate.home").
5. **UI** escucha `flow.expressions` y se actualiza; el **navegador** recibe el intent y muestra la pantalla correspondiente.

---

## Componentes y ejemplos

### OmegaChannel (bus de eventos)

**Qué hace:** Es el bus central. Cualquiera puede **emitir** eventos (`emit(OmegaEvent)`) y cualquiera puede **suscribirse** a `channel.events` para reaccionar. Los agentes y flows se suscriben aquí.

**Ejemplo:**

```dart
final channel = OmegaChannel();

// Emitir un evento
channel.emit(OmegaEvent(
  id: "ev-1",
  name: "auth.login.request",
  payload: {"email": "a@b.com", "password": "***"},
));

// Escuchar eventos
channel.events.listen((event) {
  if (event.name == "auth.login.success") {
    // actuar con event.payload
  }
});

// Al cerrar la app
channel.dispose();
```

---

### OmegaEvent (evento)

**Qué hace:** Representa “algo que pasó”. Tiene `name` (ej. `"auth.login.success"`) y `payload` (datos opcionales). Se usa con `OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: data)` si defines nombres tipados. Para leer el payload con tipo: `event.payloadAs<User>()`.

**Ejemplo:**

```dart
// Crear con nombre tipado (enum AppEvent)
channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));

// En un listener, leer payload tipado
final user = event.payloadAs<User>();
if (user != null) { ... }
```

---

### OmegaIntent (intención)

**Qué hace:** Representa una petición de acción (login, navegar, etc.). La UI no llama métodos; emite intents. El FlowManager los envía a los flows en `running`. También se usan para navegación: el payload del intent llega a la pantalla como argumentos.

**Ejemplo:**

```dart
// Desde la UI: pedir login
flowManager.handleIntent(
  OmegaIntent.fromName(AppIntent.authLogin, payload: LoginCredentials(email: e, password: p)),
);

// Para navegar (se emite por el canal con nombre "navigation.intent")
channel.emit(OmegaEvent.fromName(
  AppEvent.navigationIntent,
  payload: OmegaIntent.fromName(AppIntent.navigateHome, payload: userData),
));
```

---

### OmegaAgent (agente)

**Qué hace:** Unidad de lógica autónoma. Se suscribe al canal; cuando llega un evento (o un intent), su **behavior** evalúa y devuelve una reacción (acción + payload). El agente ejecuta esa acción en `onAction`. Toda la lógica (llamadas a red, validación, etc.) puede vivir aquí y testearse sin Flutter.

**Ejemplo:**

```dart
class AuthAgent extends OmegaAgent {
  AuthAgent(OmegaChannel channel)
    : super(id: "Auth", channel: channel, behavior: AuthBehavior());

  @override
  void onAction(String action, dynamic payload) {
    if (action == "doLogin") _login(payload);
  }

  void _login(dynamic payload) {
    // llamar API, validar, emitir auth.login.success o auth.login.error
    channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
  }
}
```

---

### OmegaAgentBehaviorEngine (reglas del agente)

**Qué hace:** Define **cuándo** el agente reacciona y **qué acción** devolver. Recibe el contexto (evento, intent) y devuelve `OmegaAgentReaction("nombreAccion", payload: ...)` o `null`.

**Ejemplo:**

```dart
class AuthBehavior extends OmegaAgentBehaviorEngine {
  AuthBehavior() {
    addRule(OmegaAgentBehaviorRule(
      condition: (ctx) => ctx.event?.name == AppEvent.authLoginRequest.name,
      reaction: (ctx) => OmegaAgentReaction("doLogin", payload: ctx.event?.payload),
    ));
  }
}
```

---

### OmegaFlow (flujo de negocio)

**Qué hace:** Orquesta un caso de uso (login, checkout, etc.). Se suscribe al canal; cuando está en `running`, recibe **eventos** en `onEvent` e **intents** en `onIntent`. Desde ahí puede: emitir expresiones para la UI (`emitExpression("loading")`), emitir eventos al canal (para que un agente actúe), o emitir un intent de navegación. La UI escucha `flow.expressions` para actualizarse.

**Ejemplo:**

```dart
class AuthFlow extends OmegaFlow {
  @override
  void onIntent(OmegaFlowContext ctx) {
    if (ctx.intent?.name == AppIntent.authLogin.name) {
      emitExpression("loading");
      channel.emit(OmegaEvent.fromName(AppEvent.authLoginRequest, payload: ctx.intent!.payload));
    }
  }

  @override
  void onEvent(OmegaFlowContext ctx) {
    if (ctx.event?.name == AppEvent.authLoginSuccess.name) {
      emitExpression("success", payload: ctx.event!.payload);
      channel.emit(OmegaEvent.fromName(
        AppEvent.navigationIntent,
        payload: OmegaIntent.fromName(AppIntent.navigateHome, payload: ctx.event!.payload),
      ));
    }
  }
}
```

---

### OmegaFlowManager (gestor de flows)

**Qué hace:** Registra flows, los activa/pausa y reparte los intents. Solo los flows en estado `running` reciben intents. `activate(id)` deja varios flows activos; `switchTo(id)` activa uno y pausa el resto. Con `wireNavigator(navigator)` conecta el canal al navegador para que los eventos "navigate.*" o "navigation.intent" cambien de pantalla.

**Ejemplo:**

```dart
// Registrar flows (en bootstrap)
flowManager.registerFlow(AuthFlow(channel));
flowManager.registerFlow(CheckoutFlow(channel));

// Un solo flow “principal”
flowManager.switchTo("authFlow");

// Varios flows activos a la vez
flowManager.activate("authFlow");
flowManager.activate("cartFlow");

// La UI envía un intent; el manager lo reparte a los flows en running
flowManager.handleIntent(OmegaIntent.fromName(AppIntent.authLogin, payload: creds));
```

---

### OmegaScope (inyección en Flutter)

**Qué hace:** Widget que pone el `OmegaChannel` y el `OmegaFlowManager` (y opcionalmente `initialFlowId`) en el árbol. Cualquier hijo hace `OmegaScope.of(context)` para acceder al canal y al manager.

**Ejemplo:**

```dart
runApp(
  OmegaScope(
    channel: runtime.channel,
    flowManager: runtime.flowManager,
    initialFlowId: "authFlow",
    child: MyApp(navigator: runtime.navigator),
  ),
);

// En cualquier pantalla
final scope = OmegaScope.of(context);
scope.channel.emit(...);
scope.flowManager.handleIntent(...);
```

---

### OmegaBuilder (UI que reacciona a un evento)

**Qué hace:** Widget que se reconstruye cuando en el canal se emite un evento con un `eventName` concreto. Útil para mostrar algo que depende de un evento global (p. ej. "user.updated").

**Ejemplo:**

```dart
OmegaBuilder(
  eventName: 'user.updated',
  builder: (context, event) => Text('Hola ${event?.payload?['name']}'),
)
```

---

### OmegaNavigator y rutas

**Qué hace:** Traduce intents de navegación en rutas de Flutter. Si el canal emite un evento `navigation.intent` con un `OmegaIntent` en el payload, o se emite "navigate.home" / "navigate.push.detail", el navegador hace push o pushReplacement a la ruta con ese `id`. El **payload del intent** se pasa a la pantalla como `RouteSettings.arguments`.

**Ejemplo de registro de rutas:**

```dart
navigator.registerRoute(OmegaRoute(id: "login", builder: (context) => LoginPage()));

// Ruta que recibe un tipo: la vista recibe Producto? sin castear
navigator.registerRoute(OmegaRoute.typed<Producto>(
  id: "productoForm",
  builder: (context, product) => ProductoFormPage(producto: product),
));
```

**Ejemplo de navegación desde un flow:**

```dart
channel.emit(OmegaEvent.fromName(
  AppEvent.navigationIntent,
  payload: OmegaIntent.fromName(AppIntent.navigateProductoForm, payload: product),
));
```

---

### OmegaRuntime (arranque)

**Qué hace:** Crea el canal, el config (agentes, flows, rutas), registra todo y devuelve el runtime. La app usa `runtime.channel`, `runtime.flowManager`, `runtime.navigator` y `runtime.initialFlowId` para montar OmegaScope y el MaterialApp.

**Ejemplo:**

```dart
void main() {
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      initialFlowId: runtime.initialFlowId,
      child: MyApp(navigator: runtime.navigator),
    ),
  );
}
```

---

### Persistencia (snapshot y restore)

**Qué hace:** `flowManager.getAppSnapshot()` devuelve una foto del estado (flows, memoria, flow activo). Puedes serializarla con `toJson()`, guardarla y al reabrir la app cargar con `fromJson` y llamar a `flowManager.restoreFromSnapshot(snapshot)`.

**Ejemplo:**

```dart
// Guardar
final snapshot = flowManager.getAppSnapshot();
final json = jsonEncode(snapshot.toJson());
await prefs.setString("omega_state", json);

// Restaurar al abrir
final loaded = prefs.getString("omega_state");
if (loaded != null) {
  final snapshot = OmegaAppSnapshot.fromJson(jsonDecode(loaded));
  flowManager.restoreFromSnapshot(snapshot);
}
```

---

### Inspector (debug)

**Qué hace:** Muestra en tiempo real los últimos eventos del canal y el estado de los flows. Puedes usarlo como overlay en la app o, en web, en una ventana aparte (OmegaInspectorLauncher abre la ventana; esa ventana muestra OmegaInspectorReceiver).

**Ejemplo (overlay):**

```dart
if (kDebugMode)
  Stack(
    children: [
      MyContent(),
      Positioned(right: 0, top: 0, child: OmegaInspector()),
    ],
  )
```

---

## Ejemplo completo

El proyecto incluye un **example** (carpeta `example/`) con login, navegación a home con payload tipado, rutas tipadas y uso de nombres tipados (AppEvent, AppIntent) y payloadAs. Archivos clave:

- `example/lib/omega/omega_setup.dart` — Config, agentes, flows, rutas (incluida `OmegaRoute.typed<LoginSuccessPayload>` para home).
- `example/lib/auth/auth_flow.dart` — Flow que reacciona a intents y eventos y navega con payload.
- `example/lib/auth/auth_agent.dart` — Agente que hace login y emite éxito/error.
- `example/lib/auth/ui/auth_page.dart` — UI que emite intents y escucha expresiones.
- `example/lib/home/home.dart` — Pantalla que recibe `LoginSuccessPayload?` por la ruta tipada.

Para ejecutar: `cd example && flutter run`.

---

## Enlaces

- [ARQUITECTURA.md](ARQUITECTURA.md) — Detalle técnico de cada componente.
- [TESTING.md](TESTING.md) — Cómo testear agentes y flows sin Flutter.
- [COMPARATIVA.md](COMPARATIVA.md) — Cuándo elegir Omega frente a BLoC/Riverpod.
- [README principal](../README.md) — Instalación, CLI y resumen.
