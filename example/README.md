# Omega Example

Ejemplo mínimo que recorre **flow inicial**, **login** y **navegación** a home.

## Flujo

1. **Arranque:** `main()` hace `OmegaRuntime.bootstrap(createOmegaConfig)`, monta `OmegaScope` y `MyApp`.
2. **Flow inicial:** En el primer frame, `_RootHandler` activa el flow definido en `initialFlowId` (`authFlow`) con `flowManager.switchTo(scope.initialFlowId!)`.
3. **Navegación a login:** Se emite en el canal el evento `navigation.intent` con un `OmegaIntent(name: "navigate.login")`, así la primera pantalla que ve el usuario es la de login.
4. **Pantalla de login:** `OmegaLoginPage` obtiene el `AuthFlow` y escucha `flow.expressions`. El usuario escribe y pulsa "Login"; la UI emite la intención `auth.login` con email/password. El flow la recibe en `onIntent`, emite "loading" y dispara el evento `auth.login.request` al canal.
5. **Agente de auth:** `AuthAgent` (u otro agente que escuche `auth.login.request`) procesa y emite `auth.login.success` o `auth.login.error` por el canal.
6. **Flow reacciona:** `AuthFlow.onEvent` recibe `auth.login.success` y emite en el canal `navigation.intent` con `OmegaIntent(name: "navigate.home")`, llevando al usuario a la pantalla Home.

## Cómo ejecutar

Desde la raíz del repo:

```bash
cd example && flutter run
```

## Estructura relevante

- `lib/main.dart` — Punto de entrada, bootstrap, `OmegaScope`, activación del flow inicial y primera navegación. En **debug**: botón **Time-travel** (icono historia) en la AppBar abre un panel para grabar una sesión (eventos del canal + snapshot inicial) y reproducir hasta un paso; ver [docs/TIME_TRAVEL.md](https://github.com/yefersonSegura/omega_architecture/blob/main/docs/TIME_TRAVEL.md).
- `lib/omega/omega_setup.dart` — Config: agentes, flows, rutas. **Ruta tipada:** `OmegaRoute.typed<LoginSuccessPayload>(id: "home", builder: (context, userData) => HomePage(userData: userData))` para que la vista reciba el payload sin castear.
- `lib/omega/app_semantics.dart` — **Nombres tipados:** enums [AppEvent] y [AppIntent] que implementan [OmegaEventName]/[OmegaIntentName]. Se usan con `OmegaEvent.fromName` y `OmegaIntent.fromName` para evitar strings mágicos.
- `lib/auth/models.dart` — **Payload tipado:** [LoginCredentials] (intent de login) y [LoginSuccessPayload] (evento de éxito). Se leen con la extensión `payloadAs<T>()` en el flow, agente y página.
- `lib/auth/` — AuthFlow, AuthAgent, AuthBehavior, pantalla de login. **Contratos:** AuthFlow y AuthAgent definen `contract` ([OmegaFlowContract]/[OmegaAgentContract]) con los eventos e intents que escuchan y los tipos de expresión que emiten; en debug, Omega avisa en consola si llega algo no declarado (ver [docs/CONTRACTS.md](https://github.com/yefersonSegura/omega_architecture/blob/main/docs/CONTRACTS.md)).
- `lib/home/` — HomePage recibe `LoginSuccessPayload? userData`; el flow navega con `OmegaIntent.fromName(AppIntent.navigateHome, payload: userData)`.

Este ejemplo sirve como referencia para integrar Omega en una app real: config, flow inicial, navegación por intents y reacción a eventos entre flow y agente.

**Más documentación:** En el repo del paquete, [docs/GUIA.md](https://github.com/yefersonSegura/omega_architecture/blob/main/docs/GUIA.md) explica cada función de Omega con ejemplos (canal, eventos, intents, agentes, flows, rutas tipadas, persistencia, inspector).
