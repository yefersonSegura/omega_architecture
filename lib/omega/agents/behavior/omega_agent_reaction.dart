/// [OmegaAgentReaction] representa el resultado de una regla de comportamiento.
/// Define qué [action] debe realizar el agente y con qué [payload].
class OmegaAgentReaction {
  /// El nombre de la acción a ejecutar.
  final String action;

  /// Datos asociados a la acción.
  final dynamic payload;

  const OmegaAgentReaction(this.action, {this.payload});
}
