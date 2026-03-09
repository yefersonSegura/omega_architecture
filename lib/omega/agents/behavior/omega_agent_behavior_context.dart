import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../../core/events/omega_event.dart';

/// Context passed to [OmegaAgentBehaviorEngine.evaluate].
///
/// Contains the [event] or [intent] that triggered the evaluation and a copy of the agent's [state]
/// so rules can decide the reaction without modifying state directly.
class OmegaAgentBehaviorContext {
  /// Global event that triggered the evaluation, if applicable.
  final OmegaEvent? event;

  /// Intent that triggered the evaluation, if applicable.
  final OmegaIntent? intent;

  /// Copy of the agent's internal state at evaluation time.
  final Map<String, dynamic> state;

  const OmegaAgentBehaviorContext({
    this.event,
    this.intent,
    this.state = const {},
  });
}
