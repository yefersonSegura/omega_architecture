/// [OmegaAgentMessage] define la estructura de la comunicación directa entre dos agentes.
class OmegaAgentMessage {
  /// El ID del agente que envía el mensaje.
  final String from;

  /// El ID del agente que debe recibir el mensaje.
  final String to;

  /// La acción o comando solicitado en el mensaje.
  final String action;

  /// La carga útil de datos necesaria para la acción.
  final dynamic payload;

  const OmegaAgentMessage({
    required this.from,
    required this.to,
    required this.action,
    this.payload,
  });
}
