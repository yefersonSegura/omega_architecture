// lib/omega/flows/omega_flow_state.dart

/// Lifecycle states for an [OmegaFlow].
///
/// Only [running] flows process channel events and intents. The other states mean
/// the flow is not active or has finished (idle, paused, sleeping, ended).
enum OmegaFlowState {
  /// Created but not started yet.
  idle,

  /// Actively processing events and intents.
  running,

  /// Retaining memory but not processing events.
  sleeping,

  /// Temporarily paused.
  paused,

  /// Finished; resources released.
  ended,
}
