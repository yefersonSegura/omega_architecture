import 'package:flutter/widgets.dart';

import '../../agents/omega_stateful_agent.dart';
import 'omega_agent_builder.dart';
import 'omega_agent_scope.dart';

/// [OmegaAgentBuilder] that resolves the agent from [OmegaAgentScope] instead of
/// taking it as a constructor argument.
///
/// Use when the page is wrapped with [OmegaAgentScope] at the route so the screen
/// widget does not need `required this.someAgent`.
class OmegaScopedAgentBuilder<TAgent extends OmegaStatefulAgent<TState>, TState>
    extends StatelessWidget {
  const OmegaScopedAgentBuilder({super.key, required this.builder});

  final OmegaAgentWidgetBuilder<TState> builder;

  @override
  Widget build(BuildContext context) {
    final agent = OmegaAgentScope.omegaAgentAs<TAgent>(context);
    return OmegaAgentBuilder<TAgent, TState>(
      agent: agent,
      builder: builder,
    );
  }
}
