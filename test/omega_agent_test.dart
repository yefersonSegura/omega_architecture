import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega/agents/protocol/omega_agent_message.dart'
    show OmegaAgentMessage;
import 'package:omega_architecture/omega_architecture.dart';

class FakeBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    if (ctx.event?.name == "hello") {
      return OmegaAgentReaction("sayHello", "world");
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
}
