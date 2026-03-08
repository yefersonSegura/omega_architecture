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

- `lib/main.dart` — Punto de entrada, bootstrap, `OmegaScope`, activación del flow inicial y primera navegación.
- `lib/omega/omega_setup.dart` — Config: agentes (Provider, Auth), flows (Provider, Auth), rutas (login, home), `initialFlowId`.
- `lib/auth/` — AuthFlow, AuthAgent, AuthBehavior, pantalla de login.
- `lib/home/` — Pantalla Home.

Este ejemplo sirve como referencia para integrar Omega en una app real: config, flow inicial, navegación por intents y reacción a eventos entre flow y agente.
