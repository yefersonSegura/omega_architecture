import '../agents/omega_agent.dart';
import '../flows/omega_flow.dart';
import '../ui/navigation/omega_route.dart';

/// [OmegaConfig] es la configuración de la app: agentes, flows, rutas y flow inicial.
///
/// Lo defines en tu app (p. ej. en omega_setup.dart) y lo pasas a [OmegaRuntime.bootstrap].
/// El runtime registra [agents] en el protocolo, [flows] en el [OmegaFlowManager],
/// [routes] en el [OmegaNavigator], y expone [initialFlowId] para activar ese flow al primer frame.
class OmegaConfig {
  final List<OmegaAgent> agents;
  final List<OmegaFlow> flows;
  final List<OmegaRoute> routes;

  /// Id opcional del flow a activar al arranque de la app (ej. "auth").
  /// La app host debe llamar a [OmegaFlowManager.switchTo] o [OmegaFlowManager.activate]
  /// con este id tras el primer frame (ej. en [WidgetsBinding.instance.addPostFrameCallback]).
  /// Si es null, la app decide qué flow activar.
  final String? initialFlowId;

  const OmegaConfig({
    this.agents = const [],
    this.flows = const [],
    this.routes = const [],
    this.initialFlowId,
  });
}
