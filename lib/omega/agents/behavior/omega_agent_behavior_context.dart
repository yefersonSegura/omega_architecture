import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../../core/events/omega_event.dart';

/// [OmegaAgentBehaviorContext] resume el estado y los estímulos (eventos/intenciones)
/// que el motor de comportamiento necesita para evaluar las reglas.
class OmegaAgentBehaviorContext {
  /// El evento que disparó la evaluación, si lo hay.
  final OmegaEvent? event;

  /// La intención que disparó la evaluación, si la hay.
  final OmegaIntent? intent;

  /// Una copia del estado interno del agente en el momento de la evaluación.
  final Map<String, dynamic> state;

  const OmegaAgentBehaviorContext({
    this.event,
    this.intent,
    this.state = const {},
  });
}
