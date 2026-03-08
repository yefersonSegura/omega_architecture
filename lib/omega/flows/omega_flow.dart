// lib/omega/flows/omega_flow.dart

import 'dart:async';

import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'omega_flow_state.dart';
import 'omega_flow_expression.dart';
import 'omega_flow_context.dart';
import 'omega_flow_snapshot.dart';

/// [OmegaFlow] representa un flujo de negocio (ej. login, checkout).
///
/// Se suscribe al [OmegaChannel]. Solo cuando [state] es [OmegaFlowState.running]
/// procesa eventos ([onEvent]) e intents ([onIntent]). La UI escucha [expressions]
/// para actualizarse. Se activa con [OmegaFlowManager.activate] o [OmegaFlowManager.switchTo].
abstract class OmegaFlow {
  /// Identificador único del flujo (ej. "auth", "cart").
  final String id;

  /// Canal global; el flow escucha eventos aquí.
  final OmegaChannel channel;

  /// Estado actual: solo en [OmegaFlowState.running] se procesan eventos e intents.
  OmegaFlowState state = OmegaFlowState.idle;

  final StreamController<OmegaFlowExpression> _expressions =
      StreamController.broadcast();

  /// Stream de expresiones que la UI puede escuchar para reconstruirse.
  Stream<OmegaFlowExpression> get expressions => _expressions.stream;

  /// Memoria interna del flujo (datos que persisten durante su ejecución).
  final Map<String, dynamic> memory = {};

  OmegaFlowExpression? _lastExpression;

  OmegaFlow({required this.id, required this.channel}) {
    channel.events.listen(_handleEvent);
  }

  // -----------------------------------------------------------
  // 1. Ciclo de vida
  // -----------------------------------------------------------

  /// Inicia la ejecución del flujo si no está ya en ejecución.
  void start() {
    if (state == OmegaFlowState.running) return;
    state = OmegaFlowState.running;
    onStart();
  }

  /// Pone el flujo en modo "dormido", reduciendo su actividad pero manteniendo el estado.
  void sleep() {
    state = OmegaFlowState.sleeping;
    onSleep();
  }

  /// Despierta un flujo que estaba en modo sleep.
  void wakeUp() {
    state = OmegaFlowState.running;
    onWakeUp();
  }

  /// Pausa el flujo temporalmente.
  void pause() {
    state = OmegaFlowState.paused;
    onPause();
  }

  /// Finaliza el flujo definitivamente y cierra sus flujos de datos.
  void end() {
    state = OmegaFlowState.ended;
    onEnd();
    _expressions.close();
  }

  // Hooks opcionales
  void onStart() {}
  void onSleep() {}
  void onWakeUp() {}
  void onPause() {}
  void onEnd() {}

  // -----------------------------------------------------------
  // 2. Manejo de eventos globales
  // -----------------------------------------------------------

  void _handleEvent(OmegaEvent event) {
    if (state != OmegaFlowState.running) return;

    final context = OmegaFlowContext(event: event, memory: memory);

    onEvent(context);
  }

  /// Método llamado cuando el flujo recibe un evento global al estar en ejecución.
  void onEvent(OmegaFlowContext ctx);

  // -----------------------------------------------------------
  // 3. Manejo de intenciones desde UI u otros agentes
  // -----------------------------------------------------------

  /// Recibe una [OmegaIntent] y la procesa si el flujo está activo.
  void receiveIntent(OmegaIntent intent) {
    if (state != OmegaFlowState.running) return;

    final context = OmegaFlowContext(intent: intent, memory: memory);

    onIntent(context);
  }

  /// Método abstracto que define cómo reacciona el flujo a una intención específica.
  void onIntent(OmegaFlowContext ctx);

  // -----------------------------------------------------------
  // 4. Emitir expresiones hacia la UI
  // -----------------------------------------------------------

  /// Emite una expresión (un mensaje o cambio de estado visual) que la UI debe procesar.
  void emitExpression(String type, {dynamic payload}) {
    if (!_expressions.isClosed) {
      final expr = OmegaFlowExpression(type, payload: payload);
      _lastExpression = expr;
      _expressions.add(expr);
    }
  }

  // -----------------------------------------------------------
  // 5. Snapshot (estado actual)
  // -----------------------------------------------------------

  /// Devuelve una foto del estado actual del flow (id, state, copia de memory, última expresión).
  /// Útil para depuración, persistencia o time-travel.
  OmegaFlowSnapshot getSnapshot() => OmegaFlowSnapshot(
        flowId: id,
        state: state,
        memory: Map<String, dynamic>.from(memory),
        lastExpression: _lastExpression,
      );
}
