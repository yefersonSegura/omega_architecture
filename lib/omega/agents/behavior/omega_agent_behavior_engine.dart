import 'omega_agent_behavior_rule.dart';
import 'omega_agent_behavior_context.dart';
import 'omega_agent_reaction.dart';

/// Rule engine: given a context (event or intent), returns the first reaction whose rule matches.
///
/// **Why use it:** The agent doesn't need a big switch; you define rules "if event.name == X then action Y".
///
/// **Example:** `behavior.addRule(OmegaAgentBehaviorRule((ctx) => ctx.event?.name == "auth.login.request", (ctx) => OmegaAgentReaction("login", ctx.event?.payload)));`
class OmegaAgentBehaviorEngine {
  final List<OmegaAgentBehaviorRule> _rules = [];

  /// Registers a rule. Order matters: the first matching condition is evaluated.
  void addRule(OmegaAgentBehaviorRule rule) {
    _rules.add(rule);
  }

  /// Evaluates [context] against the rules. Returns the first matching [OmegaAgentReaction], or null.
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext context) {
    for (final rule in _rules) {
      if (rule.condition(context)) {
        return rule.reaction(context);
      }
    }
    return null;
  }
}
