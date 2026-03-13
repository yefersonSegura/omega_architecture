import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _TestEvent implements OmegaEventName {
  a('ev.a'),
  b('ev.b');

  const _TestEvent(this.name);
  @override
  final String name;
}

enum _TestIntent implements OmegaIntentName {
  x('intent.x'),
  y('intent.y');

  const _TestIntent(this.name);
  @override
  final String name;
}

void main() {
  group('OmegaFlowContract', () {
    test('empty sets accept everything', () {
      const c = OmegaFlowContract();
      expect(c.acceptsEvent('any'), isTrue);
      expect(c.acceptsIntent('any'), isTrue);
      expect(c.allowsExpression('any'), isTrue);
    });

    test('fromTyped builds correct sets', () {
      final c = OmegaFlowContract.fromTyped(
        flowId: 'f1',
        listenedEvents: [_TestEvent.a, _TestEvent.b],
        acceptedIntents: [_TestIntent.x],
        emittedExpressionTypes: ['loading', 'done'],
      );
      expect(c.flowId, 'f1');
      expect(c.listenedEventNames, {'ev.a', 'ev.b'});
      expect(c.acceptedIntentNames, {'intent.x'});
      expect(c.emittedExpressionTypes, {'loading', 'done'});
    });

    test('acceptsEvent accepts only declared names', () {
      final c = OmegaFlowContract(
        listenedEventNames: {'ev.a', 'ev.b'},
      );
      expect(c.acceptsEvent('ev.a'), isTrue);
      expect(c.acceptsEvent('ev.b'), isTrue);
      expect(c.acceptsEvent('ev.c'), isFalse);
    });

    test('acceptsIntent accepts only declared names', () {
      final c = OmegaFlowContract(acceptedIntentNames: {'intent.x'});
      expect(c.acceptsIntent('intent.x'), isTrue);
      expect(c.acceptsIntent('intent.y'), isFalse);
    });

    test('allowsExpression allows only declared types', () {
      final c = OmegaFlowContract(emittedExpressionTypes: {'loading'});
      expect(c.allowsExpression('loading'), isTrue);
      expect(c.allowsExpression('success'), isFalse);
    });
  });

  group('OmegaAgentContract', () {
    test('empty sets accept everything', () {
      const c = OmegaAgentContract();
      expect(c.acceptsEvent('any'), isTrue);
      expect(c.acceptsIntent('any'), isTrue);
    });

    test('fromTyped builds correct sets', () {
      final c = OmegaAgentContract.fromTyped(
        agentId: 'ag1',
        listenedEvents: [_TestEvent.a],
        acceptedIntents: [_TestIntent.x, _TestIntent.y],
      );
      expect(c.agentId, 'ag1');
      expect(c.listenedEventNames, {'ev.a'});
      expect(c.acceptedIntentNames, {'intent.x', 'intent.y'});
    });

    test('acceptsEvent and acceptsIntent filter correctly', () {
      final c = OmegaAgentContract(
        listenedEventNames: {'ev.a'},
        acceptedIntentNames: {'intent.x'},
      );
      expect(c.acceptsEvent('ev.a'), isTrue);
      expect(c.acceptsEvent('ev.b'), isFalse);
      expect(c.acceptsIntent('intent.x'), isTrue);
      expect(c.acceptsIntent('intent.y'), isFalse);
    });
  });

  test('flow with contract still processes event and intent', () async {
    final channel = OmegaChannel();
    var eventReceived = false;
    var intentReceived = false;

    final flow = _FlowWithContract(channel, () => eventReceived = true, () => intentReceived = true);
    final manager = OmegaFlowManager(channel: channel);
    manager.registerFlow(flow);
    manager.activate('f');

    channel.emit(OmegaEvent(id: 'e1', name: 'ev.a'));
    await Future<void>.delayed(Duration.zero);
    expect(eventReceived, isTrue);

    manager.handleIntent(OmegaIntent(id: 'i1', name: 'intent.x'));
    await Future<void>.delayed(Duration.zero);
    expect(intentReceived, isTrue);

    manager.dispose();
    channel.dispose();
  });

  test('flow contract is cached (single evaluation)', () async {
    final channel = OmegaChannel();
    final flow = _FlowContractCounter(channel);
    final manager = OmegaFlowManager(channel: channel);
    manager.registerFlow(flow);
    manager.activate('f');

    for (var i = 0; i < 5; i++) {
      channel.emit(OmegaEvent(id: 'e$i', name: 'ev.a'));
      manager.handleIntent(OmegaIntent(id: 'i$i', name: 'intent.x'));
      flow.emitExpression('loading');
      await Future<void>.delayed(Duration.zero);
    }

    expect(flow.contractGetterCalls, 1);

    manager.dispose();
    channel.dispose();
  });
}

class _FlowWithContract extends OmegaFlow {
  _FlowWithContract(OmegaChannel c, this._onEvent, this._onIntent) : super(id: 'f', channel: c);

  final void Function() _onEvent;
  final void Function() _onIntent;

  static final _contract = OmegaFlowContract.fromTyped(
    listenedEvents: [_TestEvent.a],
    acceptedIntents: [_TestIntent.x],
    emittedExpressionTypes: ['loading'],
  );

  @override
  OmegaFlowContract? get contract => _contract;

  @override
  void onEvent(OmegaFlowContext ctx) => _onEvent();

  @override
  void onIntent(OmegaFlowContext ctx) => _onIntent();
}

class _FlowContractCounter extends OmegaFlow {
  _FlowContractCounter(OmegaChannel c) : super(id: 'f', channel: c);

  int contractGetterCalls = 0;

  @override
  OmegaFlowContract? get contract {
    contractGetterCalls++;
    return OmegaFlowContract.fromTyped(
      listenedEvents: [_TestEvent.a],
      acceptedIntents: [_TestIntent.x],
      emittedExpressionTypes: ['loading'],
    );
  }

  @override
  void onEvent(OmegaFlowContext ctx) {}

  @override
  void onIntent(OmegaFlowContext ctx) {}
}
