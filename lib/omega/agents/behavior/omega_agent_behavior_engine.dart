import 'omega_agent_behavior_rule.dart';
import 'omega_agent_behavior_context.dart';
import 'omega_agent_reaction.dart';

class OmegaAgentBehaviorEngine {
  final List<OmegaAgentBehaviorRule> _rules = [];

  void addRule(OmegaAgentBehaviorRule rule) {
    _rules.add(rule);
  }

  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext context) {
    for (final rule in _rules) {
      if (rule.condition(context)) {
        return rule.reaction(context);
      }
    }
    return null;
  }
}
