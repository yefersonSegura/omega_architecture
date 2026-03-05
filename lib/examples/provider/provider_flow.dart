import 'package:omega_architecture/omega_architecture.dart';

class ProviderFlow extends OmegaFlow {
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
