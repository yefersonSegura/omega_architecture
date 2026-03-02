import 'omega_agent_message.dart';

/// [OmegaAgentInbox] gestiona los mensajes directos recibidos por un agente.
/// Implementa una cola simple de tipo FIFO.
class OmegaAgentInbox {
  final _queue = <OmegaAgentMessage>[];

  /// Añade un mensaje a la cola de entrada.
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
