// lib/omega/flows/omega_flow.dart

import 'dart:async';

import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'omega_flow_state.dart';
import 'omega_flow_expression.dart';
import 'omega_flow_context.dart';

abstract class OmegaFlow {
  final String id;
  final OmegaChannel channel;

  OmegaFlowState state = OmegaFlowState.idle;

  // Stream dinámico para que la UI observe
  final StreamController<OmegaFlowExpression> _expressions =
      StreamController.broadcast();

  Stream<OmegaFlowExpression> get expressions => _expressions.stream;

  // Memoria interna del Flow
  final Map<String, dynamic> memory = {};

  OmegaFlow({required this.id, required this.channel}) {
    channel.events.listen(_handleEvent);
  }

  // -----------------------------------------------------------
  // 1. Ciclo de vida
  // -----------------------------------------------------------

  void start() {
    if (state == OmegaFlowState.running) return;
    state = OmegaFlowState.running;
    onStart();
  }

  void sleep() {
    state = OmegaFlowState.sleeping;
    onSleep();
  }

  void wakeUp() {
    state = OmegaFlowState.running;
    onWakeUp();
  }

  void pause() {
    state = OmegaFlowState.paused;
    onPause();
  }

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

  void onEvent(OmegaFlowContext ctx);

  // -----------------------------------------------------------
  // 3. Manejo de intenciones desde UI u otros agentes
  // -----------------------------------------------------------

  void receiveIntent(OmegaIntent intent) {
    if (state != OmegaFlowState.running) return;

    final context = OmegaFlowContext(intent: intent, memory: memory);

    onIntent(context);
  }

  void onIntent(OmegaFlowContext ctx);

  // -----------------------------------------------------------
  // 4. Emitir expresiones hacia la UI
  // -----------------------------------------------------------

  void emitExpression(String type, {dynamic payload}) {
    if (!_expressions.isClosed) {
      _expressions.add(OmegaFlowExpression(type, payload: payload));
    }
  }
}
