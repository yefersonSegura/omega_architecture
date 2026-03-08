import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega/flows/omega_flow_context.dart';
import 'package:omega_architecture/omega_architecture.dart';

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

    manager.handleIntent(OmegaIntent(id: "i1", name: "test.action"));

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
}
