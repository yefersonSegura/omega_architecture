import 'omega_agent_behavior_rule.dart';
import 'omega_agent_behavior_context.dart';
import 'omega_agent_reaction.dart';

/// [OmegaAgentBehaviorEngine] determina cómo reacciona un agente a eventos e intents.
///
/// Evalúa [OmegaAgentBehaviorContext] frente a las reglas añadidas con [addRule].
/// Devuelve la primera [OmegaAgentReaction] cuya condición se cumpla, o null.
class OmegaAgentBehaviorEngine {
  final List<OmegaAgentBehaviorRule> _rules = [];

  /// Añade una regla (condición + reacción) al motor.
  void addRule(OmegaAgentBehaviorRule rule) {
    _rules.add(rule);
  }

  /// Evalúa el contexto actual [context] frente a las reglas registradas.
  /// Retorna la primera reacción exitosa o null si ninguna regla coincide.
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext context) {
    for (final rule in _rules) {
      if (rule.condition(context)) {
        return rule.reaction(context);
      }
    }
    return null;
  }
}
