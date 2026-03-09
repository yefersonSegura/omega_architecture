import 'omega_agent_message.dart';
import '../omega_agent.dart';
import '../../core/channel/omega_channel.dart';

/// Agent registry: direct messages ([send]) or to all ([broadcast]). The channel remains for global events.
///
/// **Why use it:** When a flow must ask a specific agent (e.g. AuthAgent) without emitting a global event.
///
/// **Example:** The runtime calls protocol.register(agent). A flow gets the agent and calls agent.receiveIntent(intent).
class OmegaAgentProtocol {
  final OmegaChannel channel;
  final Map<String, OmegaAgent> agents = {};

  OmegaAgentProtocol(this.channel);

  /// Registers an agent. The runtime calls this at bootstrap for each agent in the config.
  void register(OmegaAgent agent) {
    agents[agent.id] = agent;
  }

  /// Sends a message to a single agent (msg.to). For agent-to-agent communication.
  void send(OmegaAgentMessage msg) {
    final receiver = agents[msg.to];
    receiver?.receiveMessage(msg);
  }

  /// Sends the same message to all agents. Useful for "system shutdown" or "reset".
  void broadcast(String action, {dynamic payload}) {
    for (final agent in agents.values) {
      agent.receiveMessage(
        OmegaAgentMessage(
          from: "system",
          to: agent.id,
          action: action,
          payload: payload,
        ),
      );
    }
  }
}
