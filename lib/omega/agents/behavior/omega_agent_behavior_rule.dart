import 'package:omega_architecture/omega/agents/behavior/omega_agent_behavior_context.dart';
import 'package:omega_architecture/omega/agents/behavior/omega_agent_reaction.dart';

class OmegaAgentBehaviorRule {
  final bool Function(OmegaAgentBehaviorContext context) condition;
  final OmegaAgentReaction Function(OmegaAgentBehaviorContext context) reaction;

  const OmegaAgentBehaviorRule({
    required this.condition,
    required this.reaction,
  });
}
