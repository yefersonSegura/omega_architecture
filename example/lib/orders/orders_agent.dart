import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';
import 'orders_behavior.dart';

class OrdersAgent extends OmegaAgent {
  static final _contract = OmegaAgentContract.fromTyped(
    agentId: AppAgentId.orders.id,
    listenedEvents: [],
    acceptedIntents: [],
  );

  @override
  OmegaAgentContract? get contract => _contract;

  OrdersAgent(OmegaEventBus channel)
      : super(
          id: AppAgentId.orders.id,
          channel: channel,
          behavior: OrdersBehavior(),
        );

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
