import '../agents/omega_agent.dart';
import '../flows/omega_flow.dart';
import '../ui/navigation/omega_route.dart';

/// Bootstrap configuration: list of agents, flows, routes and initial flow.
///
/// **Why use it:** Single object you pass to [OmegaRuntime.bootstrap]; the runtime registers everything and returns the [OmegaRuntime].
///
/// **Example:** `OmegaConfig(agents: [AuthAgent(...)], flows: [AuthFlow(channel)], routes: [OmegaRoute(...)], initialFlowId: "authFlow");`
class OmegaConfig {
  final List<OmegaAgent> agents;
  final List<OmegaFlow> flows;
  final List<OmegaRoute> routes;

  /// Id of the flow to activate when the app opens. The host calls flowManager.switchTo(initialFlowId) on the first frame.
  final String? initialFlowId;

  const OmegaConfig({
    this.agents = const [],
    this.flows = const [],
    this.routes = const [],
    this.initialFlowId,
  });
}
