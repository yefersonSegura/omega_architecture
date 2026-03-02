import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../../core/events/omega_event.dart';

class OmegaAgentBehaviorContext {
  final OmegaEvent? event;
  final OmegaIntent? intent;
  final Map<String, dynamic> state;

  const OmegaAgentBehaviorContext({
    this.event,
    this.intent,
    this.state = const {},
  });
}
