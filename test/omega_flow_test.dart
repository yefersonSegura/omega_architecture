import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega/flows/omega_flow_context.dart';
import 'package:omega_architecture/omega_architecture.dart';

class TestFlow extends OmegaFlow {
  TestFlow(OmegaChannel channel) : super(id: "testFlow", channel: channel);

  @override
  void onIntent(OmegaFlowContext intent) {
    emitExpression("received_intent", payload: intent.intent?.action);
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

    flow.onIntent(
      OmegaFlowContext(
        intent: OmegaIntent(id: "i1", action: "do.something"),
      ),
    );

    await Future.delayed(Duration(milliseconds: 10));

    expect(expression.type, "received_intent");
    expect(expression.payload, "do.something");
  });
}
