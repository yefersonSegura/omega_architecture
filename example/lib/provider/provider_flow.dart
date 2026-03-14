import 'package:omega_architecture/omega_architecture.dart';

class ProviderFlow extends OmegaFlow {
  static final _contract = OmegaFlowContract.fromTyped(
    flowId: 'Provider',
    listenedEvents: [],
    acceptedIntents: [],
    emittedExpressionTypes: {'idle'},
  );

  @override
  OmegaFlowContract? get contract => _contract;

  ProviderFlow(OmegaChannel channel) : super(id: "Provider", channel: channel);

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {}

  @override
  void onEvent(OmegaFlowContext ctx) {}
}
