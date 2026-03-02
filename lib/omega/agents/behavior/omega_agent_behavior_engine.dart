import 'omega_agent_behavior_rule.dart';
import 'omega_agent_behavior_context.dart';
import 'omega_agent_reaction.dart';

/// [OmegaAgentBehaviorEngine] es el motor de reglas que determina cómo reacciona un agente.
/// Contiene una lista de reglas que se evalúan secuencialmente.
class OmegaAgentBehaviorEngine {
  final List<OmegaAgentBehaviorRule> _rules = [];

  /// Añade una nueva regla al motor de comportamiento.
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
