# Cómo testear flows y agentes sin Flutter

Puedes testear la lógica de **agentes** y **flows** con tests unitarios puros: no hace falta `runApp`, `WidgetTester` ni `pumpWidget`. Solo canal, intents, eventos y aserciones.

---

## Testear un agente

1. Crea un **motor de comportamiento** (subclase de [OmegaAgentBehaviorEngine] o reglas) que devuelva reacciones según el contexto.
2. Crea un **agente de prueba** que extienda [OmegaAgent], use ese behavior e implemente [onAction] y [onMessage] guardando el resultado en variables.
3. **Emite eventos** por el canal o llama a **agent.receiveIntent(OmegaIntent)**.
4. Tras un breve delay (para que el stream procese), **comprueba** que `onAction` fue llamado con la acción y payload esperados.

### Ejemplo (evento)

```dart
class FakeBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    if (ctx.event?.name == "hello") {
      return OmegaAgentReaction("sayHello", payload: "world");
    }
    return null;
  }
}

class FakeAgent extends OmegaAgent {
  FakeAgent(OmegaChannel channel)
      : super(id: "fake", channel: channel, behavior: FakeBehavior());
  String? lastAction;
  dynamic lastPayload;

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {
    lastAction = action;
    lastPayload = payload;
  }
}

test("Agent reacts to events", () async {
  final channel = OmegaChannel();
  final agent = FakeAgent(channel);
  channel.emit(OmegaEvent(id: "1", name: "hello"));
  await Future.delayed(Duration(milliseconds: 10));
  expect(agent.lastAction, "sayHello");
  expect(agent.lastPayload, "world");
});
```

### Ejemplo (intent)

Para probar la reacción a una **intención** en lugar de un evento, usa el mismo agente y llama a **receiveIntent**; el behavior debe tener en cuenta `ctx.intent` (además de `ctx.event`):

```dart
agent.receiveIntent(
  const OmegaIntent(id: "i1", name: "hello", payload: "from_intent"),
);
await Future.delayed(Duration(milliseconds: 10));
expect(agent.lastAction, "sayHello");
```

---

## Testear un flow

1. Crea un **flow de prueba** que extienda [OmegaFlow] e implemente [onEvent] y [onIntent] (p. ej. emitiendo expresiones según el intent).
2. Haz **flow.start()** para ponerlo en [OmegaFlowState.running] (solo así procesa intents y eventos).
3. **Escucha** `flow.expressions` y guarda la última expresión recibida.
4. Llama a **flow.receiveIntent(OmegaIntent)** (o emite eventos al canal si el flow reacciona a ellos).
5. Tras un breve delay, **comprueba** el tipo y payload de la expresión.

### Ejemplo

```dart
class TestFlow extends OmegaFlow {
  TestFlow(OmegaChannel channel) : super(id: "testFlow", channel: channel);

  @override
  void onIntent(OmegaFlowContext ctx) {
    if (ctx.intent?.name == "next") {
      emitExpression("received_intent", payload: "next_intent_processed");
    } else {
      emitExpression("received_intent", payload: ctx.intent?.name);
    }
  }

  @override
  void onEvent(OmegaFlowContext ctx) {}
}

test("Flow receiveIntent emits expression when running", () async {
  final channel = OmegaChannel();
  final flow = TestFlow(channel);
  flow.start();

  late OmegaFlowExpression expression;
  flow.expressions.listen((exp) => expression = exp);

  flow.receiveIntent(
    const OmegaIntent(id: "i2", name: "do.something", payload: null),
  );

  await Future.delayed(const Duration(milliseconds: 10));
  expect(expression.type, "received_intent");
  expect(expression.payload, "do.something");
});
```

**Importante:** Si el flow no está en `running`, **receiveIntent** no hace nada. Puedes comprobar que no se emiten expresiones cuando el flow está en `idle` o `paused`.

---

## Testear FlowManager y snapshots

- **FlowManager:** Registra flows, activa con `activate(id)` o `switchTo(id)`, envía intents con `handleIntent(OmegaIntent)` y comprueba que el flow activo reciba la intención (p. ej. mediante una variable en el flow de prueba).
- **Snapshots:** Tras activar un flow y emitir expresiones o escribir en `flow.memory`, llama a `manager.getFlowSnapshot(id)` o `manager.getAppSnapshot()` y comprueba `state`, `memory` y `lastExpression`.

Los tests en `test/omega_flow_manager_test.dart` y `test/omega_flow_test.dart` son referencia.

---

## Resumen

| Objetivo              | Qué usar                         | Sin Flutter |
|-----------------------|-----------------------------------|-------------|
| Agente reacciona a evento | `channel.emit(OmegaEvent)` + delay + assert `onAction` | Sí          |
| Agente reacciona a intent | `agent.receiveIntent(OmegaIntent)` + delay + assert | Sí          |
| Flow emite expresión  | `flow.start()`, `flow.receiveIntent(...)`, `expressions.listen` + assert | Sí          |
| FlowManager enruta   | `manager.registerFlow`, `activate`/`switchTo`, `handleIntent` + assert en el flow | Sí          |
| Snapshot              | `flow.getSnapshot()` o `manager.getAppSnapshot()` + assert campos | Sí          |

No necesitas `runApp` ni widgets para cubrir la lógica de negocio de agentes y flows.
