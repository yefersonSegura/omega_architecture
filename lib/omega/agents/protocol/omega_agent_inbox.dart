import 'omega_agent_message.dart';

/// [OmegaAgentInbox] es la cola de mensajes directos de un agente (FIFO).
///
/// Cuando llega un mensaje vía [OmegaAgentProtocol.send], se llama a [receive].
/// El agente puede consumir con [next] o comprobar [hasMessages].
class OmegaAgentInbox {
  final _queue = <OmegaAgentMessage>[];

  /// Añade un mensaje a la cola.
  void receive(OmegaAgentMessage message) {
    _queue.add(message);
  }

  /// Retorna el siguiente mensaje en la cola o null si está vacía.
  OmegaAgentMessage? next() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  /// Indica si hay mensajes pendientes por procesar.
  bool get hasMessages => _queue.isNotEmpty;
}
