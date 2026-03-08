import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_context.dart';
import 'package:omega_architecture/omega/agents/behavior/omega_agent_reaction.dart';

/// [OmegaAgentBehaviorRule] define una regla: cuándo aplica ([condition]) y qué reacción devolver ([reaction]).
class OmegaAgentBehaviorRule {
  /// Devuelve true si la regla aplica para este contexto.
  final bool Function(OmegaAgentBehaviorContext context) condition;

  /// Devuelve la reacción (acción + payload) si [condition] es true.
  final OmegaAgentReaction Function(OmegaAgentBehaviorContext context) reaction;

  const OmegaAgentBehaviorRule({
    required this.condition,
    required this.reaction,
  });
}
