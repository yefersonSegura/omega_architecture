// lib/omega/flows/omega_flow_state.dart

enum OmegaFlowState {
  idle, // esperando sin hacer nada
  running, // el flujo está activo
  sleeping, // temporalmente inactivo
  paused, // detenido manualmente
  ended, // finalizado
}
