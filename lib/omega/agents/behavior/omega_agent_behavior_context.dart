import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../../core/events/omega_event.dart';

/// Context passed to [OmegaAgentBehaviorEngine.evaluate].
///
/// Contains the [event] or [intent] that triggered the evaluation and a reference to the agent's
/// [state] map so rules can read or update it when deciding the reaction.
class OmegaAgentBehaviorContext {
  /// Global event that triggered the evaluation, if applicable.
  final OmegaEvent? event;

  /// Intent that triggered the evaluation, if applicable.
  final OmegaIntent? intent;

  /// Reference to the agent's internal state map at evaluation time. Rules may read or write it.
  final Map<String, dynamic> state;

  const OmegaAgentBehaviorContext({
    this.event,
    this.intent,
    this.state = const {},
  });
}
