import 'package:omega_architecture/omega/agents/protocol/omega_agent_protocol.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

/// [OmegaRuntime] es el resultado del arranque: canal, flow manager, protocolo, navegador y flow inicial.
///
/// Se obtiene con [OmegaRuntime.bootstrap]. La app usa [channel], [flowManager], [navigator]
/// y opcionalmente [initialFlowId] para montar [OmegaScope] y [MaterialApp], y activar el flow inicial.
class OmegaRuntime {
  final OmegaChannel channel;
  final OmegaFlowManager flowManager;
  final OmegaAgentProtocol protocol;
  final OmegaNavigator navigator;

  /// Id del flow a activar al inicio, si se definió en [OmegaConfig.initialFlowId].
  /// Úsalo en tu widget raíz (ej. en addPostFrameCallback) para activar
  /// el flow inicial sin hardcodear su id.
  final String? initialFlowId;

  OmegaRuntime._(
    this.channel,
    this.flowManager,
    this.protocol,
    this.navigator,
    this.initialFlowId,
  );

  /// Inicializa el runtime de Omega a partir de una función que construye
  /// el [OmegaConfig] usando el [OmegaChannel] interno.
  ///
  /// De este modo, agentes y flows comparten SIEMPRE el mismo canal que
  /// utiliza el [OmegaFlowManager] y el [OmegaNavigator].
  factory OmegaRuntime.bootstrap(
    OmegaConfig Function(OmegaChannel) createConfig,
  ) {
    final channel = OmegaChannel();
    final config = createConfig(channel);
    final flowManager = OmegaFlowManager(channel: channel);
    final protocol = OmegaAgentProtocol(channel);
    final navigator = OmegaNavigator();

    // Agentes
    for (final agent in config.agents) {
      protocol.register(agent);
    }

    // Flows
    for (final flow in config.flows) {
      flowManager.registerFlow(flow);
    }

    // Rutas
    for (final route in config.routes) {
      navigator.registerRoute(route);
    }

    flowManager.wireNavigator(navigator);

    return OmegaRuntime._(
      channel,
      flowManager,
      protocol,
      navigator,
      config.initialFlowId,
    );
  }
}
