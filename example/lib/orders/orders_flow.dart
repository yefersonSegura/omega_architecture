import 'dart:math';

import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';
import '../omega/app_semantics.dart';

/// Demo flow that simulates an "orders.create" operation which may fail due to
/// connectivity. On failure it enqueues the intent in [OmegaOfflineQueue] and
/// emits a "pendingOffline" expression.
class OrdersFlow extends OmegaFlow {
  final OmegaOfflineQueue offlineQueue;

  static final _contract = OmegaFlowContract.fromTyped(
    flowId: AppFlowId.ordersFlow.id,
    listenedEvents: [],
    acceptedIntents: [AppIntent.ordersCreate],
    emittedExpressionTypes: {'idle', 'creating', 'created', 'pendingOffline'},
  );

  @override
  OmegaFlowContract? get contract => _contract;

  OrdersFlow(OmegaEventBus channel, this.offlineQueue)
      : super(id: AppFlowId.ordersFlow.id, channel: channel);

  @override
  void onStart() {
    emitExpression('idle');
  }

  @override
  void onEvent(OmegaFlowContext ctx) {
    // This demo flow does not react to global events.
  }

  @override
  void onIntent(OmegaFlowContext ctx) {
    final intent = ctx.intent;
    if (intent == null) return;

    if (intent.name == AppIntent.ordersCreate.name) {
      _handleCreateOrder(intent);
    }
  }

  Future<void> _handleCreateOrder(OmegaIntent intent) async {
    emitExpression('creating');

    // Simulate network: 50% chance of failure.
    final hasNetwork = Random().nextBool();

    if (hasNetwork) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      emitExpression('created');
      return;
    }

    final queued = OmegaQueuedIntent.fromIntent(intent);
    await offlineQueue.enqueue(queued);
    emitExpression('pendingOffline', payload: queued.id);
  }
}

