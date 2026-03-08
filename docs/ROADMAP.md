# Visión y roadmap: Omega como arquitectura referente

Ideas para hacer de Omega la opción más visionaria y única en Flutter. No son obligatorias; son direcciones estratégicas.

---

## 1. Omega DevTools (inspección en tiempo real)

- [x] **Inspector mínimo ([OmegaInspector]):** panel en la app que muestra últimos N eventos del canal (nombre, payload, timestamp) y snapshot de flows (id, estado, última expresión, memory). Colapsable; refresco cada 2 s. Ver [OmegaInspector] en la UI.
- [ ] **Time-travel:** reproducir desde un snapshot guardado (base ya existe con OmegaFlowSnapshot / OmegaAppSnapshot).
- [ ] **Replay:** “volver a emitir” un evento para reproducir un bug.
- [ ] **Agentes:** en el inspector, cuáles reaccionaron a qué evento (requiere instrumentación opcional).

**Objetivo:** Que Omega sea la arquitectura donde “ves todo lo que pasa”.

---

## 2. Contratos y convenciones (semántica)

- [x] **Eventos/intents tipados (nombres):** OmegaEventName, OmegaIntentName, fromName.
- [ ] **Registro/contratos por evento (opcional):** registro de “eventos conocidos” con payload opcional (autocompletado, refactors, menos strings mágicos).
- [ ] **Contratos por flow:** “este flow solo emite estas expresiones” y “solo reacciona a estos intents”, documentados o validables en tests.
- [ ] **Versionado de intents:** soporte para `auth.login.v2` y migraciones cuando cambie el payload.

**Objetivo:** Omega no es solo “eventos por strings”; es semántica clara y evolución controlada.

---

## 3. Persistencia y recuperación (app state)

- [x] **API para serializar/restaurar** OmegaAppSnapshot: toJson/fromJson, restoreMemory, restoreFromSnapshot, OmegaSnapshotStorage.
- [x] **Restore on launch:** “al abrir la app, restaurar el snapshot de la última sesión” (o del último estado conocido de un flow).
- [ ] **Offline-first:** flows que persisten su memory y se reconcilian al volver online.

**Objetivo:** La arquitectura que “no pierde estado” por defecto.

---

## 4. Composición y módulos

- [ ] **OmegaModule:** paquete que trae su flow, agentes, rutas y eventos; se registra en el host con una sola llamada (ej. `OmegaModuleAuth.register(channel, config)`).
- [ ] **Ecosistemas reutilizables:** auth, onboarding, checkout como módulos que distintas apps pueden reutilizar.
- [ ] **Eventos namespaced:** ej. `auth.*`, `checkout.*`, para que módulos no se pisen.

**Objetivo:** Omega como plataforma de módulos reutilizables entre apps.

---

## 5. IA y asistencia (futuro)

- [ ] **Generación desde descripción:** “crear flow de checkout con pasos X, Y, Z” → CLI o plugin genera flow, intents y expresiones.
- [ ] **Sugerencias de reglas:** a partir de eventos/intents observados, proponer reglas de behavior (“cuando ocurra X, ¿quieres hacer Y?”).
- [ ] **Documentación viva:** a partir del grafo eventos → flows → agentes, generar docs o diagramas.

**Objetivo:** Arquitectura pensada para tooling e IA.

---

## 6. Testing y confiabilidad

- [ ] **Record/Replay en tests:** grabar una sesión (eventos + intents) y repetirla en CI para regresiones.
- [ ] **Property-based testing:** “para cualquier secuencia de intents en el flow X, no hay expresión Z sin antes Y”.
- [ ] **Assertions de contrato:** “el flow Auth nunca emite navigate.home sin antes auth.login.success”.

**Objetivo:** Comportamiento verificable y auditable.

---

## 7. Diferenciación (mensaje)

- [x] **Un párrafo claro:** “En [COMPARATIVA.md](COMPARATIVA.md) y en la web (presentation): estado observable, persistible y reproducible; agentes, flows e intents en el centro; la UI solo refleja.”
- [x] **Comparativa honesta:** [docs/COMPARATIVA.md](COMPARATIVA.md) y sección en la web: "Omega vs BLoC vs Riverpod", tabla y **cuándo elegir Omega**. README enlaza la web como documentación completa.

**Objetivo:** Que la comunidad entienda por qué y cuándo elegir Omega.

---

## Orden sugerido de impacto

1. **DevTools (o Omega Inspector mínimo)** — lo que más impacta la percepción de “único”.
2. **Persistencia/restore de snapshot** — poco común en Flutter y alineado con el modelo actual.
3. **Módulos (OmegaModule)** — reutilización entre apps.
4. **Eventos/intents tipados o registrados** — menos magia, más refactor seguro.
5. **Mensaje y comparativa** — que la gente sepa cuándo elegir Omega.

---

## Feedback (referencia)

> Sigue faltando tipado fuerte en eventos/expresiones y algo tipo DevTools, pero para un POS como Kashira la base está sólida y el día a día con Omega es más claro que en la versión anterior.

— Refuerza prioridad de **§1 DevTools** y **§2 Contratos / eventos tipados**; valida que la base actual sirve en producción (POS) y que la claridad del modelo mejora la experiencia diaria.

---

## Notas

- Los ítems con `[ ]` son propuestas abiertas.
- Ver también [MEJORAS.md](MEJORAS.md) para el historial de pasos ya completados (1–7).
