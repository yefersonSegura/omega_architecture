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
  });
}
