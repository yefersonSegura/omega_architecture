import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

class FakeBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    final name = ctx.event?.name ?? ctx.intent?.name;
    if (name == "hello") {
      return OmegaAgentReaction("sayHello", payload: "world");
    }
    return null;
  }
}

class FakeAgent extends OmegaAgent {
  String? lastAction;
  dynamic lastPayload;

  FakeAgent(OmegaChannel channel)
    : super(id: "fake", channel: channel, behavior: FakeBehavior());

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, payload) {
    lastAction = action;
    lastPayload = payload;
  }
}

void main() {
  test("Agent reacts to events using behavior engine", () async {
    final channel = OmegaChannel();
    final agent = FakeAgent(channel);

    channel.emit(OmegaEvent(id: "1", name: "hello"));

    await Future.delayed(Duration(milliseconds: 10));

    expect(agent.lastAction, "sayHello");
    expect(agent.lastPayload, "world");
  });

  test(
    "Agent reacts to receiveIntent when behavior returns reaction",
    () async {
      final channel = OmegaChannel();
      final agent = FakeAgent(channel);

      agent.receiveIntent(
        const OmegaIntent(id: "i1", name: "hello", payload: "from_intent"),
      );

      await Future.delayed(Duration(milliseconds: 10));

      expect(agent.lastAction, "sayHello");
      expect(agent.lastPayload, "world");
    },
  );
}
