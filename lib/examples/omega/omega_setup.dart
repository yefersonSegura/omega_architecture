import 'package:omega_architecture/examples/auth/auth_agent.dart';
import 'package:omega_architecture/examples/auth/auth_flow.dart';
import 'package:omega_architecture/examples/auth/ui/auth_page.dart';
import 'package:omega_architecture/examples/home/home.dart';
import 'package:omega_architecture/examples/provider/provider_agent.dart';
import 'package:omega_architecture/examples/provider/provider_flow.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(
    agents: <OmegaAgent>[ProviderAgent(channel), AuthAgent(channel)],
    flows: <OmegaFlow>[ProviderFlow(channel), AuthFlow(channel)],
    routes: [
      OmegaRoute(id: "login", builder: (context) => const OmegaLoginPage()),
      OmegaRoute(id: "home", builder: (context) => const HomePage()),
    ],
  );
}
