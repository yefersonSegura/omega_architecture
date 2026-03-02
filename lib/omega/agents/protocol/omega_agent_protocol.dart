import 'omega_agent_message.dart';
import '../omega_agent.dart';
import '../../core/channel/omega_channel.dart';

class OmegaAgentProtocol {
  final OmegaChannel channel;
  final Map<String, OmegaAgent> agents = {};

  OmegaAgentProtocol(this.channel);

  // Registrar agente dentro del protocolo
  void register(OmegaAgent agent) {
    agents[agent.id] = agent;
  }

  // Enviar mensaje directo a otro agente
  void send(OmegaAgentMessage msg) {
    final receiver = agents[msg.to];
    receiver?.receiveMessage(msg);
  }

  // Broadcast general a todos los agentes
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
