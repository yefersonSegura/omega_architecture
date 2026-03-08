import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/events/omega_event.dart';

/// [OmegaFlowContext] es el contexto que recibe un [OmegaFlow] en [OmegaFlow.onEvent] y [OmegaFlow.onIntent].
///
/// Incluye el [event] o [intent] que disparó la ejecución y la [memory] del flujo
/// para leer/escribir estado entre llamadas.
class OmegaFlowContext {
  /// Evento global que disparó [onEvent], si aplica.
  final OmegaEvent? event;

  /// Intención que disparó [onIntent], si aplica.
  final OmegaIntent? intent;

  /// Memoria del flujo (compartida entre onEvent/onIntent).
  final Map<String, dynamic> memory;

  const OmegaFlowContext({this.event, this.intent, required this.memory});
}
