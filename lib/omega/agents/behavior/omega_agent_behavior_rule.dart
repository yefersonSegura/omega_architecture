import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_context.dart';
import 'package:omega_architecture/omega/agents/behavior/omega_agent_reaction.dart';

/// [OmegaAgentBehaviorRule] define una condición y la reacción correspondiente.
class OmegaAgentBehaviorRule {
  /// Función que determina si la regla debe aplicarse en un contexto dado.
  final bool Function(OmegaAgentBehaviorContext context) condition;

  /// Función que genera la reacción si la condición se cumple.
  final OmegaAgentReaction Function(OmegaAgentBehaviorContext context) reaction;

  const OmegaAgentBehaviorRule({
    required this.condition,
    required this.reaction,
  });
}
