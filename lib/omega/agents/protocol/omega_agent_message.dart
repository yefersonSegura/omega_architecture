/// [OmegaAgentMessage] es un mensaje directo de un agente ([from]) a otro ([to]).
///
/// Se envía con [OmegaAgentProtocol.send]. El receptor lo procesa en [OmegaAgent.onMessage].
class OmegaAgentMessage {
  /// Id del agente emisor.
  final String from;

  /// Id del agente receptor.
  final String to;

  /// Acción o comando (ej. "login", "validate").
  final String action;

  /// Datos opcionales para la acción.
  final dynamic payload;

  const OmegaAgentMessage({
    required this.from,
    required this.to,
    required this.action,
    this.payload,
  });
}
