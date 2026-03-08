import 'omega_agent_message.dart';
import '../omega_agent.dart';
import '../../core/channel/omega_channel.dart';

/// [OmegaAgentProtocol] registra agentes y permite mensajes directos ([send]) o broadcast ([broadcast]).
///
/// El runtime registra aquí todos los agentes del config. No sustituye al canal global:
/// el canal es para eventos; el protocolo es para mensajes punto a punto o a todos.
class OmegaAgentProtocol {
  /// Canal global (compartido con flows y UI).
  final OmegaChannel channel;

  /// Agentes registrados por id; usado por [send] para entregar mensajes.
  final Map<String, OmegaAgent> agents = {};

  OmegaAgentProtocol(this.channel);

  /// Registra un agente para que pueda recibir mensajes vía [send] o [broadcast].
  void register(OmegaAgent agent) {
    agents[agent.id] = agent;
  }

  /// Envía [msg] al agente cuyo id es [OmegaAgentMessage.to].
  void send(OmegaAgentMessage msg) {
    final receiver = agents[msg.to];
    receiver?.receiveMessage(msg);
  }

  /// Envía un mensaje a todos los agentes registrados (acción [action], [payload] opcional).
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
