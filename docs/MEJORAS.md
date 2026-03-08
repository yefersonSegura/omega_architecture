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

## Paso 6 – DX y CLI

- [ ] Mejoras en mensajes del CLI (paths, errores claros)
- [ ] Opcional: `omega g` para más artefactos (solo agent, solo flow, etc.)
- [ ] Validación de `omega_setup.dart` (imports, ids únicos)

---

## Paso 7 – Documentación y pub

- [ ] Mantener README y ARQUITECTURA.md al día con cada cambio
- [ ] Publicar en pub.dev cuando corresponda (ej. 0.0.5 con la doc nueva)
- [ ] Changelog por versión

---

## Notas

- Los ítems con `[ ]` siguen abiertos; cuando se implementen, marcar con `[x]`.
- Si alguna recomendación se descarta, se puede mover a una sección "Descartadas" con motivo breve.
