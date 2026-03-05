import 'package:omega_architecture/auth/auth_flow.dart';
import 'package:omega_architecture/auth/auth_agent.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

import '../auth/ui/auth_page.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(
    agents: <OmegaAgent>[AuthAgent(channel)],
    flows: <OmegaFlow>[AuthFlow(channel)],
    routes: [
      OmegaRoute(id: "login", builder: (context) => const OmegaLoginPage()),
    ],
  );
}
