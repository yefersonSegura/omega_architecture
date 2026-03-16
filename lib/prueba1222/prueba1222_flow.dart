import 'package:omega_architecture/omega_architecture.dart';

class PRUEBA1222Flow extends OmegaFlow {
  PRUEBA1222Flow(OmegaChannel channel)
    : super(id: "PRUEBA1222", channel: channel);

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {}

  @override
  void onEvent(OmegaFlowContext ctx) {}
}
