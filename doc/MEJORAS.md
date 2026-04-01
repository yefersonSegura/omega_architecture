# Recomendaciones de mejora (abiertas)

Lista de mejoras propuestas para Omega. No se cierran hasta que se implementen o se decida no hacerlas.

---

## Paso 1 – Activación de flows ✅ (hecho)

- [x] `initialFlowId` en OmegaConfig / OmegaRuntime / OmegaScope
- [x] Activar flow inicial en el primer frame (ej. en `main.dart` del example)
- [x] Idempotencia en `FlowManager.activate` y `FlowManager.switchTo` (retorno `bool`)

---

## Paso 2 – Estado actual (snapshot) ✅ (hecho)

- [x] Definir qué es el "estado actual" de un flow (memory + state + última expresión)
- [x] API para obtener snapshot (ej. para depuración, persistencia o time-travel)
- [x] Opcional: snapshot a nivel de app (flows activos + canal)

---

## Paso 3 – Logging y diagnóstico ✅ (hecho)

- [x] Sustituir `print` por un mecanismo de logging (ej. callback inyectable o `debugPrint`)
- [x] En `omega_bootstrap.dart` y `omega_navigator.dart` evitar `avoid_print` en producción

---

## Paso 4 – Navegación ✅ (hecho)

- [x] Revisar contrato de navegación (eventos "navigate.*" vs "navigation.intent")
- [x] Soporte para push vs pushReplacement según ruta o intent
- [x] Opcional: deep links / rutas con parámetros

---

## Paso 5 – Testing y ejemplos ✅ (hecho)

- [x] Más tests unitarios (agentes, flows, expresiones)
- [x] Ejemplo mínimo en `example/` que recorra login + navegación + flow inicial
- [x] Documentar cómo testear flows y agentes sin Flutter

---

## Paso 6 – DX y CLI ✅ (hecho)

- [x] Mejoras en mensajes del CLI (paths absolutos, prefijo "Error:", mensajes claros)
- [x] Opcional: `omega g` para más artefactos (solo agent, solo flow, etc.)
- [x] Validación de `omega_setup.dart` (omega validate: estructura, ids duplicados)

---

## Paso 7 – Documentación y pub ✅ (hecho)

- [x] Mantener README y ARQUITECTURA.md al día con cada cambio
- [x] Publicar en pub.dev cuando corresponda (versión 0.0.6 preparada en CHANGELOG y pubspec)
- [x] Changelog por versión

---

## Visión y roadmap (próximos horizontes)

Para que Omega sea la arquitectura más visionaria y única, ver **[doc/ROADMAP.md](ROADMAP.md)**. Resumen de bloques:

- [ ] **Omega DevTools** — Inspección en tiempo real (canal, flows, agentes), time-travel, replay.
- [ ] **Contratos y semántica** — Eventos/intents tipados o registrados, contratos por flow, versionado.
- [x] **Persistencia y recuperación** — toJson/fromJson, restoreMemory, restoreFromSnapshot, OmegaSnapshotStorage; restore on launch documentado (offline-first pendiente). Ver ROADMAP §3.
- [ ] **Módulos (OmegaModule)** — Ecosistemas reutilizables entre apps, eventos namespaced.
- [ ] **IA y asistencia** — Generación desde descripción, sugerencias de reglas, documentación viva.
- [ ] **Testing avanzado** — Record/replay, property-based, assertions de contrato.
- [x] **Diferenciación** — Mensaje claro y comparativa Omega vs BLoC vs Riverpod en [COMPARATIVA.md](COMPARATIVA.md) y sección en la web. Inspector: diseño moderno (tema azul, tarjetas); launcher web usa nombre de ventana único para poder cerrar y volver a abrir.

Orden sugerido de impacto: DevTools → Persistencia → Módulos → Eventos tipados → Mensaje.

---

## Notas

- Los ítems con `[ ]` siguen abiertos; cuando se implementen, marcar con `[x]`.
- Si alguna recomendación se descarta, se puede mover a una sección "Descartadas" con motivo breve.
