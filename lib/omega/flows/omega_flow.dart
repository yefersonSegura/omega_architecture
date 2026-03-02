// lib/omega/flows/omega_flow.dart

import 'dart:async';

import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'omega_flow_state.dart';
import 'omega_flow_expression.dart';
import 'omega_flow_context.dart';

/// [OmegaFlow] representa un flujo de lógica o un proceso de negocio complejo.
/// Puede mantener estado, reaccionar a eventos y emitir expresiones para la UI.
abstract class OmegaFlow {
  /// Identificador único del flujo.
  final String id;

  /// El canal de comunicación global.
  final OmegaChannel channel;

  /// El estado actual del flujo (ej: running, paused, ended).
  OmegaFlowState state = OmegaFlowState.idle;

  // Stream dinámico para que la UI observe los cambios emitidos por el flujo.
  final StreamController<OmegaFlowExpression> _expressions =
      StreamController.broadcast();

  /// Un flujo de expresiones que la UI puede escuchar.
  Stream<OmegaFlowExpression> get expressions => _expressions.stream;

  /// Memoria interna del flujo para persistir datos durante su ejecución.
  final Map<String, dynamic> memory = {};

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
      _expressions.add(OmegaFlowExpression(type, payload: payload));
    }
  }
}
