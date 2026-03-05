import 'package:omega_architecture/omega/agents/protocol/omega_agent_protocol.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

class OmegaRuntime {
  final OmegaChannel channel;
  final OmegaFlowManager flowManager;
  final OmegaAgentProtocol protocol;
  final OmegaNavigator navigator;

  OmegaRuntime._(this.channel, this.flowManager, this.protocol, this.navigator);

  factory OmegaRuntime.bootstrap(OmegaConfig config) {
    final channel = OmegaChannel();
    final flowManager = OmegaFlowManager(channel: channel);
    final protocol = OmegaAgentProtocol(channel);
    final navigator = OmegaNavigator();

    /// Agents
    for (final agent in config.agents) {
      protocol.register(agent);
    }

    /// Flows
    for (final flow in config.flows) {
      flowManager.registerFlow(flow);
    }

    /// Routes
    for (final route in config.routes) {
      navigator.registerRoute(route);
    }

    flowManager.wireNavigator(navigator);

    /// Activar primer flow
    if (config.flows.isNotEmpty) {
      flowManager.activate(config.flows.first.id);
    }

    return OmegaRuntime._(channel, flowManager, protocol, navigator);
  }
}
