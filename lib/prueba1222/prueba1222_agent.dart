import 'package:omega_architecture/omega_architecture.dart';
import 'prueba1222_behavior.dart';

class PRUEBA1222Agent extends OmegaAgent {
  PRUEBA1222Agent(OmegaChannel channel)
    : super(id: "PRUEBA1222", channel: channel, behavior: PRUEBA1222Behavior());

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
