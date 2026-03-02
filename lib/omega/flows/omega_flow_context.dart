import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/events/omega_event.dart';

/// [OmegaFlowContext] encapsula la información disponible para un flujo durante su ejecución.
/// Contiene el [event] o [intent] que disparó la acción y el acceso a la [memory] del flujo.
class OmegaFlowContext {
  /// El evento que disparó el flujo, si lo hay.
  final OmegaEvent? event;

  /// La intención que disparó el flujo, si la hay.
  final OmegaIntent? intent;

  /// El mapa de memoria persistente del flujo.
  final Map<String, dynamic> memory;

  const OmegaFlowContext({this.event, this.intent, required this.memory});
}
