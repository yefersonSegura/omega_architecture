// Ejemplo de configuración Omega para tests/ejemplos del repo.
// En tu app, ejecuta `omega init` y se creará tu propio omega_setup.dart
// en tu proyecto (app host), no dentro de la librería.
import 'package:omega_architecture/auth/auth_agent.dart';
import 'package:omega_architecture/auth/auth_flow.dart';
import 'package:omega_architecture/auth/ui/auth_page.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(
    agents: <OmegaAgent>[AuthAgent(channel)],
    flows: <OmegaFlow>[AuthFlow(channel)],
    routes: [
      OmegaRoute(id: "login", builder: (context) => const OmegaLoginPage()),
    ],
  );
}
