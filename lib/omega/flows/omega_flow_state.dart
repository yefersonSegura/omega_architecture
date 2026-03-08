// lib/omega/flows/omega_flow_state.dart

/// [OmegaFlowState] define los estados del ciclo de vida de un [OmegaFlow].
///
/// Solo en [running] el flow procesa eventos e intents. Los demás estados
/// (idle, paused, sleeping, ended) indican que no está activo o ya terminó.
enum OmegaFlowState {
  /// El flujo está creado pero aún no ha comenzado.
  idle,

  /// El flujo está procesando activamente eventos e intenciones.
  running,

  /// El flujo está en reposo, manteniendo su memoria pero sin procesar eventos.
  sleeping,

  /// El flujo ha sido detenido temporalmente.
  paused,

  /// El flujo ha finalizado su ciclo de vida y liberado recursos.
  ended,
}
