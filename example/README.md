# Omega Example

Ejemplo mínimo que recorre **flow inicial**, **login** y **navegación** a home.

## Flujo

1. **Arranque:** `main()` hace `OmegaRuntime.bootstrap(createOmegaConfig)`, monta `OmegaScope` y `MyApp`.
2. **Flow inicial:** `_RootHandler` envuelve la UI con **`OmegaFlowActivator`** (`useSwitchTo: true`, `flowId: initialFlowId`) para activar el flow de arranque sin llamar a `switchTo` a mano.
3. **Primera ruta:** En `omega_setup.dart`, **`initialNavigationIntent:`** … y en `main` el mismo valor en **`OmegaScope.initialNavigationIntent`**; el `home` del `MaterialApp` es **`OmegaInitialRoute(child: …)`**, que tras el primer frame emite la navegación (sin pasar el intent por `MyApp`).
4. **Pantalla de login:** `OmegaLoginPage` obtiene el `AuthFlow` y escucha `flow.expressions`. El usuario escribe y pulsa "Login"; la UI emite la intención `auth.login` con email/password. El flow la recibe en `onIntent`, emite "loading" y dispara el evento `auth.login.request` al canal.
5. **Agente de auth:** `AuthAgent` (u otro agente que escuche `auth.login.request`) procesa y emite `auth.login.success` o `auth.login.error` por el canal.
6. **Flow reacciona:** `AuthFlow.onEvent` recibe `auth.login.success` y emite en el canal `navigation.intent` con `OmegaIntent(name: "navigate.home")`, llevando al usuario a la pantalla Home.

## Cómo ejecutar

Desde la raíz del repo:

```bash
cd example && flutter run
```

## Estructura relevante

- `lib/main.dart` — Punto de entrada, bootstrap, `OmegaScope`, activación del flow inicial y primera navegación. En **debug**: (1) **Inspector:** botón en la AppBar (`OmegaInspectorLauncher`) abre el inspector en diálogo (desktop/móvil) o en ventana nueva (web); (2) **Inspector en navegador:** `OmegaInspectorServer.start(channel, flowManager)` arranca un servidor y en consola sale la URL (p. ej. `http://localhost:9292`) para abrir el inspector en el navegador (solo desktop/móvil); (3) **Time-travel:** botón (icono historia) abre un panel para grabar una sesión y reproducir hasta un paso; ver [doc/TIME_TRAVEL.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/TIME_TRAVEL.md) y [doc/GUIA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md) (sección Inspector).
- `lib/omega/omega_setup.dart` — Config: agentes, flows, rutas. **Namespaces:** cada dominio usa un namespace del canal (`channel.namespace('auth')`, `'provider'`, `'orders'`); los flows y agents reciben ese [OmegaEventBus] y así solo emiten/escuchan eventos de su dominio más los globales. **Ruta tipada:** `OmegaRoute.typed<LoginSuccessPayload>(id: "home", builder: ...)` para que la vista reciba el payload sin castear.
- `lib/omega/app_semantics.dart` — `AppEvent` / `AppIntent` con `OmegaEventNameDottedCamel` y `OmegaIntentNameDottedCamel`: solo identificadores camelCase (`navigateHome`, `authLoginSuccess`); el alambre con puntos se deriva (`navigate.home`, `auth.login.success`). Pedidos: `ordersCreate` → `orders.create`.
- `lib/omega/app_runtime_ids.dart` — `AppFlowId` / `AppAgentId` con `OmegaFlowIdEnumWire` / `OmegaAgentIdEnumWire` (mismo estilo que intents): `AppFlowId.authFlow`, `AppAgentId.Auth`, etc., para `OmegaFlowActivator`, `super(id: ...)`, contratos y `getFlow`.
- `lib/auth/models.dart` — **Payload tipado:** [LoginCredentials] (intent de login) y [LoginSuccessPayload] (evento de éxito). Se leen con la extensión `payloadAs<T>()` en el flow, agente y página.
- `lib/auth/` — AuthFlow, AuthAgent, AuthBehavior, pantalla de login. La pantalla envuelve el `Scaffold` con **`OmegaFlowActivator(flowId: AppFlowId.authFlow)`**. **Contratos:** AuthFlow y AuthAgent definen `contract` ([OmegaFlowContract]/[OmegaAgentContract]) con los eventos e intents que escuchan y los tipos de expresión que emiten; en debug, Omega avisa en consola si llega algo no declarado (ver [doc/CONTRACTS.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/CONTRACTS.md)).
- `lib/home/` — HomePage recibe `LoginSuccessPayload? userData`; el flow navega con `OmegaIntent.fromName(AppIntent.navigateHome, payload: userData)`. Botón **Demo: Omega.handle** abre el contador de `lib/demo/`.
- `lib/demo/` — `intentHandlerRegistrars` → **`Omega.handle`** (contador) + **`OmegaIntentHandlerPipeline`** (cuadrado async en `demoCounterSquare`); `DemoCounterIntent` con `OmegaIntentNameDottedCamel`; `IntentHandlerDemoPage` + `ValueNotifier`.

Este ejemplo sirve como referencia para integrar Omega en una app real: config, flow inicial, navegación por intents y reacción a eventos entre flow y agente.

**Más documentación:** En el repo del paquete, [doc/GUIA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md) explica cada función de Omega con ejemplos (canal, eventos, intents, agentes, flows, rutas tipadas, persistencia, inspector).
