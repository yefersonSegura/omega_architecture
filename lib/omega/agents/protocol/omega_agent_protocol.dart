import 'omega_agent_message.dart';
import '../omega_agent.dart';
import '../../core/channel/omega_channel.dart';

/// [OmegaAgentProtocol] facilita la comunicación directa y coordinada entre múltiples agentes.
/// Permite el envío de mensajes punto a punto y la difusión (broadcast) a todos los agentes registrados.
class OmegaAgentProtocol {
  /// El canal de comunicación global.
  final OmegaChannel channel;

  /// Mapa de agentes registrados en este protocolo indexados por su ID.
  final Map<String, OmegaAgent> agents = {};

  OmegaAgentProtocol(this.channel);

  /// Registra un agente dentro del protocolo para permitir comunicación directa.
  void register(OmegaAgent agent) {
    agents[agent.id] = agent;
  }

  /// Envía un mensaje directo a un agente receptor específico.
  void send(OmegaAgentMessage msg) {
    final receiver = agents[msg.to];
    receiver?.receiveMessage(msg);
  }

  /// Difunde un mensaje (broadcast) a todos los agentes registrados en el protocolo.
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
