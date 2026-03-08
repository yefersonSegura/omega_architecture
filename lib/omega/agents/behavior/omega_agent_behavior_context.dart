import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../../core/events/omega_event.dart';

/// [OmegaAgentBehaviorContext] es el contexto que recibe [OmegaAgentBehaviorEngine.evaluate].
///
/// Incluye el [event] o [intent] que disparó la evaluación y una copia del [state] del agente
/// para que las reglas puedan decidir la reacción sin modificar el estado directamente.
class OmegaAgentBehaviorContext {
  /// Evento global que disparó la evaluación, si aplica.
  final OmegaEvent? event;

  /// Intención que disparó la evaluación, si aplica.
  final OmegaIntent? intent;

  /// Copia del estado interno del agente en el momento de la evaluación.
  final Map<String, dynamic> state;

  const OmegaAgentBehaviorContext({
    this.event,
    this.intent,
    this.state = const {},
  });
}
