import 'omega_agent_message.dart';
import '../omega_agent.dart';
import '../../core/channel/omega_channel.dart';

/// Registry of agents for direct messaging: [send] to one agent by id, or [broadcast] to all.
/// The channel is used for global events; the protocol is for agent-to-agent or system-to-agent messages.
///
/// **Why use it:** Send a message to a specific agent (e.g. "invalidateToken" to Auth) without
/// emitting a global event. The runtime registers agents at bootstrap; flows or other agents
/// get the protocol and call [send] or [broadcast].
///
/// **Example:** `protocol.send(OmegaAgentMessage(from: "Cart", to: "Auth", action: "invalidateToken"));`
class OmegaAgentProtocol {
  final OmegaChannel channel;

  /// Registered agents by id. Register at bootstrap; [send] looks up by [OmegaAgentMessage.to].
  final Map<String, OmegaAgent> agents = {};

  OmegaAgentProtocol(this.channel);

  /// Registers an agent. Called at bootstrap for each agent in the config. If an agent with the same [agent.id] exists, it is replaced.
  void register(OmegaAgent agent) {
    agents[agent.id] = agent;
  }

  /// Sends [msg] to the agent whose id equals [msg.to]. No-op if no agent is registered for that id.
  void send(OmegaAgentMessage msg) {
    final receiver = agents[msg.to];
    receiver?.receiveMessage(msg);
  }

  /// Sends a message with [action] and optional [payload] to every registered agent. Use for system-wide commands (e.g. "reset", "shutdown").
  void broadcast(String action, {dynamic payload}) {
    for (final agent in agents.values) {
      agent.receiveMessage(
        OmegaAgentMessage(
          from: 'system',
          to: agent.id,
          action: action,
          payload: payload,
        ),
      );
    }
  }
}
