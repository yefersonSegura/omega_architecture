# Data flow

End-to-end path (same mental model as Omega Angular):

1. **UI** → emits an **intent** (e.g. login) to the flow manager or channel.  
2. **Flow** (when running) receives it in `onIntent`; may emit **events** on the channel (e.g. `auth.login.request`).  
3. **Agent** listens; **behavior** picks a reaction (e.g. `doLogin`); agent emits success/error **events**.  
4. **Flow** handles events in `onEvent`; emits **expressions** to the UI and/or **navigation intents**.  
5. **UI** rebuilds from expressions; **OmegaNavigator** resolves navigation intents to routes.

Details and code snippets: [GUIA.md — Flujo de datos resumido](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md#flujo-de-datos-resumido).
