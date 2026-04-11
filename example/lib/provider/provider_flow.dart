import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';

class ProviderFlow extends OmegaFlow {
  static final _contract = OmegaFlowContract.fromTyped(
    flowId: AppFlowId.Provider.id,
    listenedEvents: [],
    acceptedIntents: [],
    emittedExpressionTypes: {'idle'},
  );

  @override
  OmegaFlowContract? get contract => _contract;

  ProviderFlow(OmegaEventBus channel)
      : super(id: AppFlowId.Provider.id, channel: channel);

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {}

  @override
  void onEvent(OmegaFlowContext ctx) {}
}
