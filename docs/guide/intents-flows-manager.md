# Intents, flows & manager

- **OmegaIntent** — UI-facing request (`OmegaIntent.fromName`, typed helpers).  
- **OmegaFlow** — `onIntent` / `onEvent`, emits expressions and navigation.  
- **Flow manager** — tracks **running** flow(s) and routes intents from the UI.

The UI does **not** call repositories or routers directly for feature work; it emits intents and listens to **expressions** and route arguments.

See the package **`example/`** app (`AuthFlow`, login screen) and [GUIA.md — OmegaIntent / flows](https://github.com/yefersonSegura/omega_architecture/blob/main/doc/GUIA.md#omegaintent-intención).
