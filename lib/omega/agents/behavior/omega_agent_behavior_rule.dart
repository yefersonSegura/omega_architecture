import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_context.dart';
import 'package:omega_architecture/omega/agents/behavior/omega_agent_reaction.dart';

/// Behavior engine rule: [condition] indicates if it applies; [reaction] returns the action to run.
///
/// **Example:** `OmegaAgentBehaviorRule(condition: (ctx) => ctx.event?.name == "auth.login.request", reaction: (ctx) => OmegaAgentReaction("login", ctx.event?.payload));`
class OmegaAgentBehaviorRule {
  /// True if this rule applies for the context (current event or intent).
  final bool Function(OmegaAgentBehaviorContext context) condition;

  /// Reaction to run in [OmegaAgent.onAction] when [condition] is true.
  final OmegaAgentReaction Function(OmegaAgentBehaviorContext context) reaction;

  const OmegaAgentBehaviorRule({
    required this.condition,
    required this.reaction,
  });
}
