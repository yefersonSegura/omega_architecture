# Cuándo elegir Omega · Comparativa con BLoC y Riverpod

Esta es la documentación de posicionamiento: en qué se diferencia Omega y **cuándo tiene sentido elegirlo** frente a BLoC o Riverpod.

---

## Párrafo de posicionamiento

**Omega** es una arquitectura en Flutter donde el estado es **observable, persistible y reproducible**: eventos, flows y agentes en el centro; la UI solo refleja. Con snapshot, DevTools (inspector en app y en ventana separada en web), persistencia/restore y nombres tipados para eventos e intents, puedes inspeccionar, recuperar y reutilizar flujos como en ningún otro stack. No es solo “state management”: es un **modelo de agentes + canal + flows + intents** con navegación desacoplada del `BuildContext`.

---

## Omega vs BLoC vs Riverpod

| Aspecto | Omega | BLoC | Riverpod |
|--------|--------|------|----------|
| **Modelo** | Agentes + flows + canal de eventos + intents | Blocs + Streams + eventos | Providers + ref + estado derivado |
| **Dónde vive la lógica** | En agentes y flows (independientes de la UI) | En Blocs atados a Streams y widgets | En providers y notifiers |
| **Comunicación** | Canal global (eventos con nombre), intents semánticos | Eventos → estados → UI | Lectura/escritura de providers |
| **Navegación** | Por intents (sin depender de `BuildContext`) | Suele usar `BuildContext` / Navigator directo | Suele usar `context` / go_router etc. |
| **Observabilidad** | Inspector (eventos + snapshots), ventana separada en web | Debug manual / logs | DevTools de Riverpod |
| **Persistencia de estado** | API de snapshot (toJson/fromJson, restore on launch) | Manual (persistir estado del Bloc) | Manual o paquetes |
| **Testing sin UI** | Agentes y flows testeables sin Flutter | Blocs testeables; integración con UI más acoplada | Providers testeables |
| **Curva de aprendizaje** | Conceptos nuevos (agentes, flows, intents) | Streams y Bloc pattern | Providers, ref, override |
| **Comunidad / adopción** | Emergente | Muy adoptado | Muy adoptado |

En resumen: **Omega** fija un modelo (agentes + flows + canal) y ofrece trazabilidad y desacoplamiento explícitos. **BLoC** y **Riverpod** son más conocidos y flexibles en distintos aspectos; Omega se diferencia por arquitectura clara, inspección y persistencia de flujos.

---

## Cuándo elegir Omega

- **Varios flujos de negocio** (login, checkout, onboarding) que orquestas por intents y quieres inspeccionar (eventos + snapshots).
- **Equipos** que necesitan una estructura clara: agentes para lógica, flows para orquestar, intents para comunicar, sin depender del `BuildContext` para navegar.
- **Apps complejas** donde quieres poder guardar/restaurar estado (snapshot) o depurar con un inspector integrado (y en web, en ventana separada).
- **Testing** de lógica de negocio sin montar la UI: agentes y flows se testean con el canal y el FlowManager.

## Cuándo usar BLoC o Riverpod

- **BLoC:** Te basta con eventos → estados → UI y te gusta el patrón Bloc + Stream; no necesitas el modelo de agentes ni la capa de intents.
- **Riverpod:** Prefieres máxima flexibilidad (providers, ref, override) y una comunidad muy grande con ejemplos y documentación; no necesitas el modelo fijo de Omega (agentes + flows + canal).

---

## Enlaces

- **Documentación técnica:** [ARQUITECTURA.md](ARQUITECTURA.md)  
- **Roadmap y visión:** [ROADMAP.md](ROADMAP.md)  
- **Web de Omega (documentación):** sitio VitePress en [docs/](https://github.com/yefersonSegura/omega_architecture/tree/main/docs) — publicado en GitHub Pages (`omega doc`). Profundidad adicional en `doc/*.md` del repositorio.
