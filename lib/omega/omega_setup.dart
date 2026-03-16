import 'package:omega_architecture/prueba1222/prueba1222_agent.dart';
import 'package:omega_architecture/prueba1222/prueba1222_flow.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(agents: <OmegaAgent>[
      PRUEBA1222Agent(channel),], flows: <OmegaFlow>[
      PRUEBA1222Flow(channel),], routes: []);
}
