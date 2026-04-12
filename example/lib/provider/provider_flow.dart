import 'package:omega_architecture/omega_architecture.dart';

import '../omega/app_runtime_ids.dart';
import 'provider_agent.dart';

class ProviderFlow extends OmegaFlow {
  static final _contract = OmegaFlowContract.fromTyped(
    flowId: AppFlowId.Provider.id,
    listenedEvents: [],
    acceptedIntents: [],
    emittedExpressionTypes: {'idle'},
  );

  @override
  OmegaFlowContract? get contract => _contract;

  ProviderFlow({required super.channel, required this.agent})
      : super(id: AppFlowId.Provider.id);

  final ProviderAgent agent;

  @override
  OmegaAgent? get uiScopeAgent => agent;

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {}

  @override
  void onEvent(OmegaFlowContext ctx) {}
}
