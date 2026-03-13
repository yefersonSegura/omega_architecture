import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

class _FakeAgent extends OmegaAgent {
  _FakeAgent(OmegaChannel channel, this.id_)
      : super(id: id_, channel: channel, behavior: _FakeBehavior());

  final String id_;
  OmegaAgentMessage? lastMessage;

  @override
  void onMessage(OmegaAgentMessage msg) {
    lastMessage = msg;
  }

  @override
  void onAction(String action, dynamic payload) {}
}

class _FakeBehavior extends OmegaAgentBehaviorEngine {
  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext context) => null;
}

void main() {
  test('OmegaAgentProtocol send delivers to agent by msg.to', () {
    final channel = OmegaChannel();
    final agent = _FakeAgent(channel, 'Auth');
    final protocol = OmegaAgentProtocol(channel);
    protocol.register(agent);

    protocol.send(const OmegaAgentMessage(
      from: 'Cart',
      to: 'Auth',
      action: 'invalidateToken',
      payload: null,
    ));

    expect(agent.lastMessage?.from, 'Cart');
    expect(agent.lastMessage?.to, 'Auth');
    expect(agent.lastMessage?.action, 'invalidateToken');

    agent.dispose();
    channel.dispose();
  });

  test('OmegaAgentProtocol send is no-op when to is not registered', () {
    final channel = OmegaChannel();
    final agent = _FakeAgent(channel, 'Auth');
    final protocol = OmegaAgentProtocol(channel);
    protocol.register(agent);

    protocol.send(const OmegaAgentMessage(
      from: 'X',
      to: 'NonExistent',
      action: 'ping',
    ));

    expect(agent.lastMessage, isNull);

    agent.dispose();
    channel.dispose();
  });

  test('OmegaAgentProtocol broadcast sends to all agents', () {
    final channel = OmegaChannel();
    final a1 = _FakeAgent(channel, 'A1');
    final a2 = _FakeAgent(channel, 'A2');
    final protocol = OmegaAgentProtocol(channel);
    protocol.register(a1);
    protocol.register(a2);

    protocol.broadcast('reset', payload: 42);

    expect(a1.lastMessage?.action, 'reset');
    expect(a1.lastMessage?.payload, 42);
    expect(a1.lastMessage?.from, 'system');
    expect(a2.lastMessage?.action, 'reset');
    expect(a2.lastMessage?.payload, 42);

    a1.dispose();
    a2.dispose();
    channel.dispose();
  });

  test('OmegaAgentInbox next removes and returns FIFO', () {
    final inbox = OmegaAgentInbox();
    inbox.receive(const OmegaAgentMessage(from: 'a', to: 'b', action: '1'));
    inbox.receive(const OmegaAgentMessage(from: 'a', to: 'b', action: '2'));

    expect(inbox.hasMessages, isTrue);
    expect(inbox.length, 2);
    expect(inbox.next()?.action, '1');
    expect(inbox.next()?.action, '2');
    expect(inbox.next(), isNull);
    expect(inbox.hasMessages, isFalse);
  });

  test('OmegaAgentInbox maxMessages drops oldest when full', () {
    final inbox = OmegaAgentInbox(maxMessages: 2);
    inbox.receive(const OmegaAgentMessage(from: 'x', to: 'y', action: 'first'));
    inbox.receive(const OmegaAgentMessage(from: 'x', to: 'y', action: 'second'));
    inbox.receive(const OmegaAgentMessage(from: 'x', to: 'y', action: 'third'));

    expect(inbox.length, 2);
    expect(inbox.next()?.action, 'second');
    expect(inbox.next()?.action, 'third');
    expect(inbox.next(), isNull);
  });
}
