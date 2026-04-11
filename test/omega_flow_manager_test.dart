import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _TestIntent implements OmegaIntentName {
  testAction('test.action');

  const _TestIntent(this.name);
  @override
  final String name;
}

class DummyFlow extends OmegaFlow {
  DummyFlow(OmegaChannel channel) : super(id: "dummy", channel: channel);

  String? lastIntentAction;

  @override
  void onIntent(OmegaFlowContext intent) {
    lastIntentAction = intent.intent?.name;
  }

  @override
  void onEvent(OmegaFlowContext event) {}
}

void main() {
  test("FlowManager should route intents to active flow", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);

    final flow = DummyFlow(channel);
    manager.registerFlow(flow);
    manager.activate("dummy");

    manager.handleIntent(OmegaIntent.fromName(_TestIntent.testAction));

    expect(flow.lastIntentAction, "test.action");

    manager.dispose();
    channel.dispose();
  });

  test("FlowManager activate is idempotent (second call no-op)", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = DummyFlow(channel);
    manager.registerFlow(flow);

    expect(manager.activate("dummy"), isTrue);
    expect(flow.state, OmegaFlowState.running);

    expect(manager.activate("dummy"), isTrue);
    expect(flow.state, OmegaFlowState.running);

    expect(manager.activate("nonexistent"), isFalse);

    manager.dispose();
    channel.dispose();
  });

  test("FlowManager switchTo ignores unregistered flow id", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = DummyFlow(channel);
    manager.registerFlow(flow);
    manager.activate("dummy");

    manager.switchTo("nonexistent");

    expect(manager.activeFlowId, isNull);
    expect(manager.getFlow("dummy")?.state, OmegaFlowState.running);

    manager.dispose();
    channel.dispose();
  });

  test("FlowManager dispose does not throw", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    manager.dispose();
    manager.dispose();
    channel.dispose();
  });

  test(
    "FlowManager getFlowSnapshot and getAppSnapshot return correct state",
    () {
      final channel = OmegaChannel();
      final manager = OmegaFlowManager(channel: channel);
      final flow = DummyFlow(channel);
      manager.registerFlow(flow);

      expect(manager.getFlowSnapshot("dummy"), isNotNull);
      expect(manager.getFlowSnapshot("dummy")!.flowId, "dummy");
      expect(manager.getFlowSnapshot("dummy")!.state, OmegaFlowState.idle);
      expect(manager.getFlowSnapshot("dummy")!.memory, isEmpty);
      expect(manager.getFlowSnapshot("dummy")!.lastExpression, isNull);

      expect(manager.getFlowSnapshot("nonexistent"), isNull);

      manager.activate("dummy");
      flow.memory["key"] = "value";
      flow.emitExpression("loading");

      final snap = manager.getFlowSnapshot("dummy")!;
      expect(snap.state, OmegaFlowState.running);
      expect(snap.memory["key"], "value");
      expect(snap.lastExpression?.type, "loading");

      final appSnap = manager.getAppSnapshot();
      expect(appSnap.flows.length, 1);
      expect(appSnap.flows.first.flowId, "dummy");
      expect(appSnap.activeFlowId, isNull);

      manager.switchTo("dummy");
      expect(manager.getAppSnapshot().activeFlowId, "dummy");

      manager.dispose();
      channel.dispose();
    },
  );

  test("FlowManager restoreFromSnapshot restores memory and active flow", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = DummyFlow(channel);
    manager.registerFlow(flow);
    manager.switchTo("dummy"); // activa y marca como flow principal
    flow.memory["saved"] = "data";
    flow.memory["count"] = 42;

    final snapshot = manager.getAppSnapshot();
    final json = snapshot.toJson();
    final decoded = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    final restored = OmegaAppSnapshot.fromJson(decoded);

    manager.end("dummy");
    flow.memory.clear(); // simula app recién abierta sin estado
    expect(manager.activeFlowId, isNull);

    manager.restoreFromSnapshot(restored);
    expect(flow.memory["saved"], "data");
    expect(flow.memory["count"], 42);
    expect(manager.activeFlowId, "dummy");
    expect(flow.state, OmegaFlowState.running);

    manager.dispose();
    channel.dispose();
  });

  test("registerIntentHandler runs before flows; consumeIntent skips flow", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = DummyFlow(channel);
    manager.registerFlow(flow);
    manager.activate("dummy");

    var handlerCalls = 0;
    manager.registerIntentHandler(
      intentName: _TestIntent.testAction.name,
      consumeIntent: true,
      handler: (intent, ctx) {
        handlerCalls++;
        expect(ctx.intent.name, _TestIntent.testAction.name);
        expect(identical(ctx.channel, channel), isTrue);
      },
    );

    manager.handleIntent(OmegaIntent.fromName(_TestIntent.testAction));

    expect(handlerCalls, 1);
    expect(flow.lastIntentAction, isNull);

    manager.dispose();
    channel.dispose();
  });

  test("registerIntentHandler without consumeIntent still delivers to flow", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = DummyFlow(channel);
    manager.registerFlow(flow);
    manager.activate("dummy");

    manager.registerIntentHandler(
      intentName: _TestIntent.testAction.name,
      consumeIntent: false,
      handler: (intent, ctx) {},
    );

    manager.handleIntent(OmegaIntent.fromName(_TestIntent.testAction));

    expect(flow.lastIntentAction, _TestIntent.testAction.name);

    manager.dispose();
    channel.dispose();
  });

  test("Omega.handle registers same as registerIntentHandler", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = DummyFlow(channel);
    manager.registerFlow(flow);
    manager.activate("dummy");

    var n = 0;
    Omega.handle(manager, _TestIntent.testAction, (intent, ctx) {
      n++;
    }, consumeIntent: true);

    manager.handleIntent(OmegaIntent.fromName(_TestIntent.testAction));
    expect(n, 1);
    expect(flow.lastIntentAction, isNull);

    manager.dispose();
    channel.dispose();
  });

  test("OmegaIntentReducer updates state", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final reducer = OmegaIntentReducer<int>(0, manager);
    reducer.on(_TestIntent.testAction, (prev, intent) => prev + 1);

    manager.handleIntent(OmegaIntent.fromName(_TestIntent.testAction));
    expect(reducer.state, 1);

    manager.dispose();
    channel.dispose();
  });
}
