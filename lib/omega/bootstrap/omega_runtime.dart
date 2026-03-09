import 'package:omega_architecture/omega/agents/protocol/omega_agent_protocol.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

/// Result of bootstrap: channel, flowManager, protocol, navigator and optionally [initialFlowId].
///
/// **Why use it:** Single creation point; agents, flows and navigator share the same channel.
///
/// **Example:** `final r = OmegaRuntime.bootstrap((c) => OmegaConfig(channel: c, agents: [...], flows: [...], routes: [...], initialFlowId: "authFlow"));` Then wrap the app with OmegaScope and assign r.navigator.navigatorKey to MaterialApp.
class OmegaRuntime {
  final OmegaChannel channel;
  final OmegaFlowManager flowManager;
  final OmegaAgentProtocol protocol;
  final OmegaNavigator navigator;

  /// Id of the flow to activate on startup. On first frame: flowManager.switchTo(initialFlowId).
  final String? initialFlowId;

  OmegaRuntime._(
    this.channel,
    this.flowManager,
    this.protocol,
    this.navigator,
    this.initialFlowId,
  );

  /// Creates channel, config (with your createConfig), flowManager, protocol, navigator; registers agents, flows and routes; connects navigator to the channel.
  ///
  /// **Example:** `OmegaRuntime.bootstrap((channel) => OmegaConfig(channel: channel, agents: [AuthAgent(...)], flows: [AuthFlow(channel)], routes: [...], initialFlowId: "authFlow"));`
  factory OmegaRuntime.bootstrap(
    OmegaConfig Function(OmegaChannel) createConfig,
  ) {
    final channel = OmegaChannel();
    final config = createConfig(channel);
    final flowManager = OmegaFlowManager(channel: channel);
    final protocol = OmegaAgentProtocol(channel);
    final navigator = OmegaNavigator();

    // Agents
    for (final agent in config.agents) {
      protocol.register(agent);
    }

    // Flows
    for (final flow in config.flows) {
      flowManager.registerFlow(flow);
    }

    // Routes
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
