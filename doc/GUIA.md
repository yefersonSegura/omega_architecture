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

**Namespaces (canales temáticos):** En apps grandes o con módulos, puedes acotar eventos por dominio con `channel.namespace('auth')`, `channel.namespace('checkout')`, etc. Los eventos emitidos con `channel.namespace('auth').emit(ev)` llevan ese namespace; `channel.namespace('auth').events` solo entrega eventos globales (sin namespace) y los del namespace `auth`. Así evitas colisiones de nombres entre módulos (p. ej. `auth.loading` vs `checkout.loading`) y preparas el terreno para OmegaModule.

```dart
final auth = channel.namespace('auth');
auth.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
auth.events.listen((e) { /* solo global + auth */ });
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

### Eventos tipados (clase como evento) — recomendado

**Qué hace:** En vez de emitir un nombre + payload por separado, defines una **clase que implementa [OmegaTypedEvent]** con el nombre del evento y los datos (ej. `email`, `password`). Emites la instancia con `channel.emitTyped(LoginRequestedEvent(email, password))` y en el listener lees `event.payloadAs<LoginRequestedEvent>()`. Así tienes autocompletado, type safety y menos bugs.

**Ejemplo:**

```dart
// Definir el evento tipado
class LoginRequestedEvent implements OmegaTypedEvent {
  final String email;
  final String password;
  LoginRequestedEvent(this.email, this.password);
  @override
  String get name => 'auth.login.request';
}

// Emitir
channel.emitTyped(LoginRequestedEvent(email, password));

// En un listener
final ev = event.payloadAs<LoginRequestedEvent>();
if (ev != null) {
  // ev.email, ev.password con tipo
}
```

**Beneficios:** autocompletado, type safety en compilación, refactors más seguros, menos errores en runtime.

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

### OmegaStatefulAgent (agente con estado reactivo de vista)

**Qué hace:** Es una variante opcional de `OmegaAgent` que mantiene un estado tipado para UI (`viewState`) y lo expone como stream (`stateStream`). Sirve para renderizar widgets reactivos sin sacar la lógica de negocio del agente.

**Cuándo usarlo:** Cuando un agente necesita actuar como mini-store observable (por ejemplo login, carrito, filtros), manteniendo el canal/intents/eventos como base de Omega.

**Ejemplo:**

```dart
class AuthAgent extends OmegaStatefulAgent<AuthViewState> {
  AuthAgent(OmegaEventBus channel)
      : super(
          id: "Auth",
          channel: channel,
          behavior: AuthBehavior(),
          initialState: AuthViewState.empty,
        );

  Future<void> _login(LoginCredentials creds) async {
    setViewState(viewState.copyWith(isLoading: true, errorMessage: null));
    // ... lógica
    setViewState(viewState.copyWith(isLoading: false));
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

### OmegaWorkflowFlow (workflow engine opcional)

**Qué hace:** Extiende `OmegaFlow` con pasos explícitos para procesos largos (checkout, onboarding, approvals): `defineStep`, `startAt`, `next`, `failStep`, `completeWorkflow`.

**Cuándo usarlo:** Cuando el flow deja de ser lineal/simple y necesitas transiciones de paso claras, trazabilidad y manejo uniforme de errores de proceso.

**Ejemplo:**

```dart
class CheckoutFlow extends OmegaWorkflowFlow {
  CheckoutFlow(OmegaEventBus channel)
      : super(id: "checkoutFlow", channel: channel) {
    defineStep("validateCart", _validateCart);
    defineStep("calculateTotal", _calculateTotal);
    defineStep("confirmOrder", _confirmOrder);
  }

  @override
  void onStart() {
    startAt("validateCart");
  }

  Future<void> _validateCart() async {
    final cartEmpty = false;
    if (cartEmpty) return failStep("cart.empty", message: "Cart is empty");
    await next("calculateTotal");
  }

  Future<void> _calculateTotal() async => next("confirmOrder");
  Future<void> _confirmOrder() async => completeWorkflow();

  @override
  void onIntent(OmegaFlowContext ctx) {}

  @override
  void onEvent(OmegaFlowContext ctx) {}
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

**Handlers ligeros (menos boilerplate):** Antes de los flows, el manager puede ejecutar callbacks registrados con `registerIntentHandler` (mismo `intentName` que el intent). Si alguno coincide con `consumeIntent: true`, el intent **no** se envía a los flows (útil para lógica trivial o efectos laterales). Equivalente corto: `Omega.handle(flowManager, AppIntent.xxx, (intent, ctx) { ... }, consumeIntent: true)`. Puedes agrupar el registro en `createOmegaConfig` con `intentHandlerRegistrars: [MiModulo.attach]` (tipo `OmegaIntentHandlerRegistrar`); [OmegaRuntime.bootstrap] los ejecuta al final, junto al resto de la config, sin tocar `main`. Para un único estado que se actualiza como un reducer (`state + 1`), usa `OmegaIntentReducer<T>(initial, flowManager)` y `reducer.on(AppIntent.increment, (s, intent) => s + 1)`. Si no quieres repetir `miIntent('cadena.larga')` en el enum: con `OmegaIntentNameDottedCamel` basta un identificador camelCase por caso y el alambre lleva puntos (`ordersCreate` → `orders.create`). Con `OmegaIntentNameEnumWire` el alambre es exactamente el `Enum.name` (sin puntos). Lo mismo para eventos: `OmegaEventNameDottedCamel` / `OmegaEventNameEnumWire`. Para recorridos de dominio y contratos, sigue prefiriendo un `OmegaFlow` completo.

---

### OmegaScope (inyección en Flutter)

**Qué hace:** Widget que pone el `OmegaChannel` y el `OmegaFlowManager` (y opcionalmente `initialFlowId` / `initialNavigationIntent` para [OmegaInitialRoute]) en el árbol. Cualquier hijo hace `OmegaScope.of(context)` para acceder al canal y al manager.

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

### OmegaFlowActivator (activar el flow de una pantalla sin boilerplate)

**Qué hace:** En el primer `didChangeDependencies` del subárbol llama a `flowManager.activate` / `switchTo` con el id resuelto. El parámetro `flowId` admite un `String` o un [OmegaFlowId] (p. ej. enum con [OmegaFlowIdEnumWire], mismo estilo que [OmegaIntentName]).

**Ejemplo:** mismo id que `super(id: AppFlowId.authFlow.id, ...)` en el flow:

```dart
@override
Widget build(BuildContext context) {
  return OmegaFlowActivator(
    flowId: AppFlowId.authFlow,
    child: Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ...,
    ),
  );
}
```

Sigue usando `OmegaScope.of(context).flowManager.handleIntent(...)` donde lo necesites.

---

### Intent handlers: qué elegir (DX)

- **Recorrido de negocio con pasos, memoria del flow y expresiones UI** → un [OmegaFlow] completo + contrato.
- **Un solo callback por intent** (efecto lateral o lógica mínima) → [OmegaFlowManager.registerIntentHandler] o [Omega.handle].
- **Estado escalar tipo reducer** (`n + 1`) → [OmegaIntentReducer].
- **Varias etapas legibles** (validar → ejecutar async → éxito / error) → [OmegaIntentHandlerPipeline] (`withPayload` → opcional `validate` → `execute` → `onSuccess` / `onError` / `onPayloadMissing` → `register`). No añade `ctx.state` ni DI al paquete: cierras sobre tus servicios en los lambdas.
- **Solo emitir señales al bus** → [OmegaChannel.emit] / `emitTyped`; los agentes reaccionan a eventos, no a `handleIntent` salvo que también lo modeles en un flow.

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

### OmegaAgentBuilder (UI que reacciona al estado de un agente)

**Qué hace:** Escucha `stateStream` de un `OmegaStatefulAgent` y reconstruye el widget cuando cambia `viewState`. Es útil para loading/error/estado de vista sin duplicar `setState` manual.

**Ejemplo:**

```dart
OmegaAgentBuilder<AuthAgent, AuthViewState>(
  agent: authAgent,
  builder: (context, state) {
    if (state.isLoading) return const CircularProgressIndicator();
    if (state.errorMessage != null) return Text(state.errorMessage!);
    return const SizedBox.shrink();
  },
)
```

### OmegaAgentScope, OmegaScopedAgentBuilder y OmegaFlowExpressionBuilder (desacoplar la pantalla del agente)

**Problema que resuelven:** no hace falta poner `required CartAgent cartAgent` en **toda** la página si solo una parte del árbol necesita el agente o el estado reactivo. También puedes escuchar **expresiones del flujo** (`emitExpression`) sin montar tú el `StreamBuilder` a mano.

**OmegaAgentScope** — expone un `OmegaAgent` a los descendientes (típicamente en el `builder` de la ruta en `omega_setup.dart`).

**OmegaScopedAgentBuilder** — es un `OmegaAgentBuilder` que lee el agente del `OmegaAgentScope` (no recibe `agent:` en el constructor).

**OmegaFlowExpressionBuilder** — escucha `flow.expressions` por **id de flujo**; usa `OmegaFlow.lastExpression` como dato inicial del `StreamBuilder` (el stream es broadcast y no repite el último valor).

**Si combinas con `OmegaScopedAgentBuilder`:** el flujo debe sobrescribir `OmegaAgent? get uiScopeAgent => …` devolviendo **el mismo** `OmegaAgent` que el flujo usa para esa pantalla. Así el builder envuelve el subárbol con `OmegaAgentScope` automáticamente. Si no lo haces, tendrás que envolver la ruta con `OmegaAgentScope` en `omega_setup` o usar `OmegaAgentBuilder(agent: …)`.

```dart
// user_interface_flow.dart (ejemplo)
class UserInterfaceFlow extends OmegaFlow {
  UserInterfaceFlow({required super.id, required super.channel, required this.agent});

  final UserInterfaceAgent agent;

  @override
  OmegaAgent? get uiScopeAgent => agent;
}
```

**Ejemplo — ruta sin pasar el agente al `StatefulWidget` raíz:**

```dart
// omega_setup.dart (fragmento)
final cartAgent = CartAgent(channel);

OmegaRoute(
  id: 'shop',
  builder: (context) => OmegaAgentScope(
    agent: cartAgent,
    child: const ShopDemoPage(), // sin required CartAgent
  ),
)
```

**Ejemplo — panel que solo necesita el estado del agente:**

```dart
// shop_demo_page.dart (dentro del build o un hijo)
OmegaScopedAgentBuilder<CartAgent, CartUiState>(
  builder: (context, cart) {
    if (cart.isLoading) return const LinearProgressIndicator();
    return Text('Items: ${cart.items.length}');
  },
)
```

**Ejemplo — reaccionar a lo que emite el flujo tras un `handleIntent`:**

```dart
OmegaFlowExpressionBuilder(
  flowId: 'cartFlow', // mismo string que super(id: 'cartFlow', ...)
  builder: (context, exp) {
    if (exp == null) return const SizedBox.shrink();
    if (exp.type == 'error') {
      return Text(exp.payload?.toString() ?? 'Error');
    }
    if (exp.type == 'success') {
      final data = exp.payloadAs<CheckoutResult>();
      return Text('OK: ${data?.orderId ?? ''}');
    }
    return const CircularProgressIndicator();
  },
)
```

**Obtener el agente sin builder:** `OmegaAgentScope.omegaAgentAs<CartAgent>(context)` o `maybeOmegaAgentAs` si es opcional.

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

**Qué hace:** Crea el canal, el config (agentes, flows, rutas), registra todo y devuelve el runtime. La app usa `runtime.channel`, `runtime.flowManager`, `runtime.navigator`, `runtime.initialFlowId` y opcionalmente **`runtime.initialNavigationIntent`** para montar OmegaScope y el MaterialApp.

`initialFlowId` solo activa el flow en el árbol ([OmegaFlowActivator]); **no** elige la primera [OmegaRoute]. Para la ruta inicial: en `OmegaConfig` pon **`initialNavigationIntent:`** `OmegaIntent.fromName(AppIntent.navigateLogin)` (alineado con `OmegaRoute(id: …)`), pasa **`initialNavigationIntent: runtime.initialNavigationIntent`** en **[OmegaScope]** y usa **`home: OmegaInitialRoute(child: …)`** en el `MaterialApp` (lee el intent del scope; sin parámetros extra en tu `MyApp`). Alternativa: [OmegaInitialNavigationEmitter] con `intent:` explícito.

**Ejemplo:**

```dart
void main() {
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      initialFlowId: runtime.initialFlowId,
      initialNavigationIntent: runtime.initialNavigationIntent,
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

**Qué hace:** Muestra en tiempo real los últimos eventos del canal y el estado de los flows. Puedes usarlo como overlay en la app o, en web, en una ventana aparte (OmegaInspectorLauncher abre la ventana; esa ventana muestra OmegaInspectorReceiver). Incluye una **timeline visual**: una fila horizontal de puntos que representan los eventos recientes (similar a Redux DevTools), encima de la lista de eventos.

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

**Inspector en el navegador (tipo DevTools):** En **desktop y mobile** (no en web) puedes abrir el Inspector en una pestaña del navegador. Arranca un servidor HTTP que envía eventos y snapshots por WebSocket; así no necesitas el overlay en la app. Solo en **debug**:

```dart
if (kDebugMode) {
  OmegaInspectorServer.start(runtime.channel, runtime.flowManager);
}
```

La consola imprimirá algo como `Omega Inspector: http://localhost:9292`. Abre esa URL en el navegador para ver eventos y estado de flows en tiempo real. En **web** `OmegaInspectorServer.start` no hace nada (usa la ventana separada con OmegaInspectorLauncher). Para detener el servidor: `OmegaInspectorServer.stop()`.

---

## Ejemplo completo

El proyecto incluye un **example** (carpeta `example/`) con login, navegación a home con payload tipado, rutas tipadas y uso de nombres tipados (`AppEvent`, `AppIntent`) y `payloadAs`. Los intents/eventos globales del example usan **solo camelCase** en el enum y [OmegaIntentNameDottedCamel] / [OmegaEventNameDottedCamel] (sin `const x('a.b')` por caso). Archivos clave:

- `example/lib/omega/app_semantics.dart` — Definición de `AppEvent` / `AppIntent` con mixins punteados.
- `example/lib/omega/app_runtime_ids.dart` — `AppFlowId` / `AppAgentId` tipados para flows y agentes.
- `example/lib/omega/omega_setup.dart` — Config, agentes, flows, rutas (incluida `OmegaRoute.typed<LoginSuccessPayload>` para home).
- `example/lib/auth/auth_flow.dart` — Flow que reacciona a intents y eventos y navega con payload. **Implementa contrato** (`OmegaFlowContract`): eventos e intents declarados; en debug Omega avisa si llega algo no declarado.
- `example/lib/auth/auth_agent.dart` — Agente que hace login y emite éxito/error. **Implementa contrato** (`OmegaAgentContract`). Referencia principal para ver contratos en uso.
- `example/lib/main.dart` — [OmegaScope] con `initialNavigationIntent`; `MaterialApp.home` = [OmegaInitialRoute] + `_RootHandler` con [OmegaFlowActivator] (`useSwitchTo: true`, `initialFlowId`).
- `example/lib/home/home.dart` — [OmegaFlowActivator] para `ordersFlow` antes de `handleIntent` del botón de pedido.
- `example/lib/auth/ui/auth_page.dart` — UI que emite intents y escucha expresiones; [OmegaFlowActivator] para `authFlow`.
- `example/lib/home/home.dart` — Pantalla que recibe `LoginSuccessPayload?` por la ruta tipada.

Para ejecutar: `cd example && flutter run`. Para más sobre contratos: [CONTRACTS.md](CONTRACTS.md).

---

### Versionado de intents (patrón recomendado)

Cuando necesites cambiar la estructura de un intent de forma incompatible (por ejemplo, añadir campos obligatorios), en lugar de modificar el intent original, crea una **nueva versión** (miembros distintos en el enum):

```dart
enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  authLoginV1,
  authLoginV2,
}
// authLoginV1.name == 'auth.login.v1'; authLoginV2.name == 'auth.login.v2'
```

Si prefieres fijar el string a mano, sigue siendo válido `const authLoginV1('auth.login.v1')` en un enum con `final String name`.

Un flow puede declarar en su contrato que acepta solo `authLoginV2`, o bien aceptar ambas versiones y adaptar internamente:

```dart
@override
OmegaFlowContract? get contract => OmegaFlowContract.fromTyped(
  acceptedIntents: [AppIntent.authLoginV1, AppIntent.authLoginV2],
  // ...
);

@override
void onIntent(OmegaFlowContext ctx) {
  final intent = ctx.intent;
  if (intent == null) return;

  if (intent.name == AppIntent.authLoginV1.name) {
    final v1 = intent.payloadAs<LoginCredentialsV1>();
    final v2 = LoginCredentialsV2(email: v1?.email ?? '', password: v1?.password ?? '');
    // seguir usando v2 internamente...
  }

  if (intent.name == AppIntent.authLoginV2.name) {
    final v2 = intent.payloadAs<LoginCredentialsV2>();
    // lógica nueva...
  }
}
```

Así puedes introducir versiones nuevas sin romper flows/agents existentes y hacer una migración gradual.

---

### Offline-first (cola de intents)

Para soportar escenarios **offline-first**, Omega incluye tipos para una cola de intents pendientes:

- `OmegaQueuedIntent` — representa un intent que no se pudo ejecutar online (id estable, name, payload, createdAt).
- `OmegaOfflineQueue` — interfaz abstracta para una cola (enqueue/getAll/remove/clear).
- `OmegaMemoryOfflineQueue` — implementación en memoria, útil para tests y demos.

Patrón recomendado en un flow cuando falla una operación de red:

```dart
class OrdersFlow extends OmegaFlow {
  final OmegaOfflineQueue offlineQueue;

  OrdersFlow(OmegaChannel c, this.offlineQueue)
      : super(id: 'ordersFlow', channel: c);

  Future<void> _createOrder(OmegaFlowContext ctx) async {
    final intent = ctx.intent;
    if (intent == null) return;

    try {
      // Intento online (por ejemplo, llamada HTTP)
      emitExpression('creating');
      await api.createOrder(intent.payload); // tu lógica real
      emitExpression('created');
    } catch (_) {
      // Sin red o error de conectividad → encolar para reintentar luego
      final queued = OmegaQueuedIntent.fromIntent(intent);
      await offlineQueue.enqueue(queued);
      emitExpression('pendingOffline', payload: queued.id);
    }
  }
}
```

Luego, un agente o servicio de sincronización puede leer la cola y reemitir los intents cuando vuelva la conexión:

```dart
Future<void> replayOfflineIntents(
  OmegaOfflineQueue queue,
  OmegaChannel channel,
) async {
  final pending = await queue.getAll();
  for (final q in pending) {
    final intent = OmegaIntent(id: q.id, name: q.name, payload: q.payload);
    channel.emit(
      OmegaEvent(
        id: q.id,
        name: 'omega.offline.replay.intent',
        payload: intent,
      ),
    );
    await queue.remove(q.id);
  }
}
```

La implementación concreta de la cola (SharedPreferences, Hive, SQLite, etc.) queda a elección de la app host; solo debe implementar `OmegaOfflineQueue`.

---

### CLI y Creación de Proyectos (con y sin IA)

**Qué hace:** Omega incluye una potente CLI que no solo genera archivos, sino que orquesta la creación completa de proyectos Flutter pre-configurados.

#### 1. Instalación y Activación Global
Para usar el comando `omega` desde cualquier lugar (fuera de un proyecto), debes activarlo globalmente:

```bash
# Opción A: Desde Git (recomendado hasta que se publique en pub.dev)
dart pub global activate --source git https://github.com/yefersonSegura/omega_architecture.git

# Opción B: Desde el repositorio local (si estás desarrollando Omega)
dart pub global activate --source path .
```

#### Configuración del PATH
Para que el sistema reconozca el comando `omega` desde cualquier directorio, debes añadir la carpeta de binarios globales de Dart a tu sistema.

**Windows:**
1. Presiona la tecla **Windows** y escribe: `variables de entorno`.
2. Selecciona **"Editar las variables de entorno del sistema"**.
3. Haz clic en el botón **"Variables de entorno..."**.
4. En **"Variables de usuario"**, busca **`Path`** y haz clic en **"Editar"**.
5. Haz clic en **"Nuevo"** y pega: `%LOCALAPPDATA%\Pub\Cache\bin`
6. Acepta todo y **REINICIA EL TERMINAL**.

**macOS / iOS / Linux:**
1. Abre tu archivo de configuración de shell (ej: `~/.zshrc`, `~/.bashrc`).
2. Añade esta línea al final:
   ```bash
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   ```
3. Guarda el archivo y ejecuta `source ~/.zshrc` (o tu archivo correspondiente) o reinicia el terminal.

#### 2. Creación de una App (Sin IA)
Crea una estructura limpia con Omega ya configurado en `main.dart` y `omega_setup.dart`.
```bash
omega create app mi_gran_idea
```

#### 3. Creación de una App (Con IA Kickstart)
La IA analizará tu descripción y generará los agentes, flows y UI necesarios para que no empieces de cero. Requiere configuración previa:

**Configuración de Variables de Entorno:**
- `OMEGA_AI_ENABLED="true"`
- `OMEGA_AI_PROVIDER="openai"`
- `OMEGA_AI_API_KEY="tu-clave-sk-..."`

**Ejecución:**
```bash
omega create app cripto_dash --kickstart "un dashboard de criptomonedas con graficos y alertas" --provider-api
```

#### 4. Comandos de Asistencia en Proyectos Existentes
- `omega init` — Prepara un proyecto Flutter existente para usar Omega.
- `omega g ecosystem <Name>` — Crea agente, flow, behavior y UI y los registra automáticamente.
- `omega ai coach audit "auth"` — Analiza tu implementación de "auth" y detecta brechas (faltan contratos, tests, etc).
- `omega ai explain trace.json` — Explica qué pasó en una sesión grabada (ideal para depurar errores complejos).

**Referencia completa del CLI (tabla, `ai coach`, trazas, inspector):** [COMANDOS_CLI.md](COMANDOS_CLI.md). En inglés con más ejemplos de salida: [README principal](../README.md) (sección *Omega CLI*).

## Enlaces

- [COMANDOS_CLI.md](COMANDOS_CLI.md) — Todos los comandos `omega` para desarrolladores.
- [ARQUITECTURA.md](ARQUITECTURA.md) — Detalle técnico de cada componente.
- [CONTRACTS.md](CONTRACTS.md) — Contratos declarativos (flows y agentes); el **example** es la referencia.
- [TESTING.md](TESTING.md) — Cómo testear agentes y flows sin Flutter.
- [COMPARATIVA.md](COMPARATIVA.md) — Cuándo elegir Omega frente a BLoC/Riverpod.
- [README principal](../README.md) — Instalación, CLI y resumen.
