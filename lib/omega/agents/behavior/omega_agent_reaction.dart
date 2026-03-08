/// [OmegaAgentReaction] es el resultado de una regla: la [action] que el agente debe ejecutar y su [payload].
///
/// El agente recibe la reacción y la ejecuta en [OmegaAgent.onAction].
class OmegaAgentReaction {
  /// El nombre de la acción a ejecutar.
  final String action;

  /// Datos asociados a la acción.
  final dynamic payload;

  const OmegaAgentReaction(this.action, {this.payload});
}
