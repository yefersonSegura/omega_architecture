import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

class TestFlow extends OmegaFlow {
  TestFlow(OmegaChannel channel) : super(id: "testFlow", channel: channel);

  @override
  void onIntent(OmegaFlowContext intent) {
    if (intent.intent?.name == "next") {
      emitExpression("received_intent", payload: "next_intent_processed");
    } else {
      emitExpression("received_intent", payload: intent.intent?.name);
    }
  }

  @override
  void onEvent(OmegaFlowContext event) {}
}

void main() {
  test("OmegaFlow should emit expressions", () async {
    final channel = OmegaChannel();
    final flow = TestFlow(channel);
    flow.start();

    late OmegaFlowExpression expression;

    flow.expressions.listen((exp) => expression = exp);

    // Test case for "next" intent
    flow.onIntent(
      OmegaFlowContext(
        intent: const OmegaIntent(id: "i", name: "next"),
        memory: const {},
      ),
    );
    await Future.delayed(const Duration(milliseconds: 10));
    expect(expression.type, "received_intent");
    expect(expression.payload, "next_intent_processed");

    // Original test case for "do.something" action
    flow.onIntent(
      OmegaFlowContext(
        intent: const OmegaIntent(id: "i1", name: "do.something"),
        memory: const {},
      ),
    );

    await Future.delayed(const Duration(milliseconds: 10));

    expect(expression.type, "received_intent");
    expect(expression.payload, "do.something");
  });

  test("OmegaFlow receiveIntent emits expression when running", () async {
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

  test("OmegaFlow receiveIntent does nothing when not running", () async {
    final channel = OmegaChannel();
    final flow = TestFlow(channel);
    assert(flow.state != OmegaFlowState.running);

    var received = 0;
    flow.expressions.listen((_) => received++);

    flow.receiveIntent(
      const OmegaIntent(id: "i3", name: "do.something"),
    );

    await Future.delayed(const Duration(milliseconds: 20));
    expect(received, 0);
  });
}
