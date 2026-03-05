import '../agents/omega_agent.dart';
import '../flows/omega_flow.dart';
import '../ui/navigation/omega_route.dart';

class OmegaConfig {
  final List<OmegaAgent> agents;
  final List<OmegaFlow> flows;
  final List<OmegaRoute> routes;

  const OmegaConfig({
    this.agents = const [],
    this.flows = const [],
    this.routes = const [],
  });
}
