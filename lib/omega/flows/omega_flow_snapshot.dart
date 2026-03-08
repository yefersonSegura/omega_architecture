import 'omega_flow_expression.dart';
import 'omega_flow_state.dart';

/// [OmegaFlowSnapshot] es una foto del estado actual de un [OmegaFlow].
///
/// Incluye [flowId], [state], una copia de [memory] y la última [lastExpression]
/// emitida (si hubo alguna). No modifica el flow; solo lee su estado.
///
/// **Para qué sirve:**
/// - **Depuración:** Ver en qué estado está un flow, qué hay en [memory] y cuál
///   fue la última expresión, sin poner prints por todo el código.
/// - **Persistencia:** Guardar el snapshot (p. ej. en disco) al cerrar la app
///   y luego restaurar el estado al reabrir.
/// - **Time-travel:** En herramientas de desarrollo, guardar un historial de
///   snapshots para "volver atrás" y ver cómo estaba la app en un momento dado.
///
/// Obtener snapshot de un flow: [OmegaFlow.getSnapshot].
/// Snapshot de todos los flows: [OmegaFlowManager.getSnapshots] o [OmegaFlowManager.getAppSnapshot].
class OmegaFlowSnapshot {
  /// Id del flow.
  final String flowId;

  /// Estado actual del flow (idle, running, paused, etc.).
  final OmegaFlowState state;

  /// Copia superficial de la memoria del flow en el momento del snapshot.
  final Map<String, dynamic> memory;

  /// Última expresión emitida por el flow, o null si no ha emitido ninguna.
  final OmegaFlowExpression? lastExpression;

  const OmegaFlowSnapshot({
    required this.flowId,
    required this.state,
    required this.memory,
    this.lastExpression,
  });

  @override
  String toString() =>
      'OmegaFlowSnapshot(flowId: $flowId, state: $state, memory: ${memory.length} keys, lastExpression: ${lastExpression?.type})';
}

/// [OmegaAppSnapshot] es una foto del estado de la app a nivel de flows.
///
/// Incluye [activeFlowId] (flow considerado principal) y [flows] (snapshots de todos
/// los flows registrados). Sirve para lo mismo que [OmegaFlowSnapshot] pero a nivel
/// global: depuración (ver el estado de toda la app), persistencia (guardar/restaurar)
/// o time-travel. Se obtiene con [OmegaFlowManager.getAppSnapshot].
class OmegaAppSnapshot {
  /// Id del flow principal (tras [OmegaFlowManager.switchTo] o [activateExclusive]).
  final String? activeFlowId;

  /// Snapshots de todos los flows registrados (orden no garantizado).
  final List<OmegaFlowSnapshot> flows;

  const OmegaAppSnapshot({
    this.activeFlowId,
    required this.flows,
  });

  @override
  String toString() =>
      'OmegaAppSnapshot(activeFlowId: $activeFlowId, flows: ${flows.length})';
}
