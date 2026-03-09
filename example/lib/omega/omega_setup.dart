import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

import '../auth/auth_agent.dart';
import '../auth/auth_flow.dart';
import '../auth/models.dart';
import '../auth/ui/auth_page.dart';
import '../home/home.dart';
import '../provider/provider_agent.dart';
import '../provider/provider_flow.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(
    agents: <OmegaAgent>[ProviderAgent(channel), AuthAgent(channel)],
    flows: <OmegaFlow>[ProviderFlow(channel), AuthFlow(channel)],
    routes: [
      OmegaRoute(id: "login", builder: (context) => const OmegaLoginPage()),
      // Ruta tipada: la vista recibe LoginSuccessPayload? (ej. tras login desde el flow)
      OmegaRoute.typed<LoginSuccessPayload>(
        id: "home",
        builder: (context, userData) => HomePage(userData: userData),
      ),
    ],
    initialFlowId: "authFlow",
  );
}
