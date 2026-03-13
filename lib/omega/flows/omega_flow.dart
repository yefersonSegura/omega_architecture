// lib/omega/flows/omega_flow.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../contracts/omega_flow_contract.dart';
import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'omega_flow_state.dart';
import 'omega_flow_expression.dart';
import 'omega_flow_context.dart';
import 'omega_flow_snapshot.dart';

/// Business flow (login, checkout, etc.): orchestrates events, intents and communication with the UI.
///
/// **Why use it:** Centralizes use-case logic. Listens to channel events and UI intents;
/// decides which expressions to emit and when to navigate. The UI only listens to [expressions].
///
/// **Example:** In [onIntent] you receive credentials, emit "loading", ask the agent to login;
/// in [onEvent] you receive "auth.login.success" and emit "success" + navigation intent.
///
/// Only processes when [state] is [OmegaFlowState.running]. Activated via [OmegaFlowManager.activate] or [switchTo].
abstract class OmegaFlow {
  /// Flow identifier (e.g. "authFlow"). Must match the one used in the manager.
  final String id;

  /// Global channel; the flow listens to [channel.events] and can emit events.
  final OmegaChannel channel;

  /// Current state. [onEvent] and [onIntent] are only called when [OmegaFlowState.running].
  OmegaFlowState state = OmegaFlowState.idle;

  final StreamController<OmegaFlowExpression> _expressions =
      StreamController.broadcast();

  /// Stream the UI listens to for updates (loading, success, error, etc.).
  ///
  /// **Example:** `flow.expressions.listen((e) => setState(() { uiState = e.type; }));`
  Stream<OmegaFlowExpression> get expressions => _expressions.stream;

  /// Flow memory (key/value). Persists while the flow is active; can be restored with [restoreMemory].
  final Map<String, dynamic> memory = {};

  OmegaFlowExpression? _lastExpression;

  OmegaFlow({required this.id, required this.channel}) {
    channel.events.listen(_handleEvent);
  }

  /// Optional declarative contract: events listened, intents accepted, expression types emitted.
  /// When set, in debug mode Omega warns if the flow receives or emits something not declared.
  /// Override in subclasses to declare contracts. Default is null (no validation).
  OmegaFlowContract? get contract => null;

  // -----------------------------------------------------------
  // 1. Lifecycle
  // -----------------------------------------------------------

  /// Puts the flow in [OmegaFlowState.running] and calls [onStart]. Invoked by the manager (activate/switchTo).
  void start() {
    if (state == OmegaFlowState.running) return;
    state = OmegaFlowState.running;
    onStart();
  }

  /// Puts the flow in "sleep" mode, reducing activity but keeping state.
  void sleep() {
    state = OmegaFlowState.sleeping;
    onSleep();
  }

  /// Wakes up a flow that was in sleep mode.
  void wakeUp() {
    state = OmegaFlowState.running;
    onWakeUp();
  }

  /// Pauses the flow temporarily.
  void pause() {
    state = OmegaFlowState.paused;
    onPause();
  }

  /// Ends the flow and closes its streams.
  void end() {
    state = OmegaFlowState.ended;
    onEnd();
    _expressions.close();
  }

  // Optional hooks
  void onStart() {}
  void onSleep() {}
  void onWakeUp() {}
  void onPause() {}
  void onEnd() {}

  // -----------------------------------------------------------
  // 2. Global event handling
  // -----------------------------------------------------------

  void _handleEvent(OmegaEvent event) {
    if (state != OmegaFlowState.running) return;

    if (kDebugMode) {
      final c = contract;
      if (c != null && !c.acceptsEvent(event.name)) {
        debugPrint(
          'OmegaFlow[$id]: received event "${event.name}" not in contract (listened: ${c.listenedEventNames}).',
        );
      }
    }

    final context = OmegaFlowContext(event: event, memory: memory);

    onEvent(context);
  }

  /// Implement the reaction to channel events (e.g. "auth.login.success"). Only called when the flow is running.
  void onEvent(OmegaFlowContext ctx);

  // -----------------------------------------------------------
  // 3. Intent handling from UI or other agents
  // -----------------------------------------------------------

  /// Sends the intent to this flow. Only processed if [state] is running; then [onIntent] is called.
  void receiveIntent(OmegaIntent intent) {
    if (state != OmegaFlowState.running) return;

    if (kDebugMode) {
      final c = contract;
      if (c != null && !c.acceptsIntent(intent.name)) {
        debugPrint(
          'OmegaFlow[$id]: received intent "${intent.name}" not in contract (accepted: ${c.acceptedIntentNames}).',
        );
      }
    }

    final context = OmegaFlowContext(intent: intent, memory: memory);

    onIntent(context);
  }

  /// Implement the reaction to intents (e.g. login, logout). Only called when the flow is running.
  void onIntent(OmegaFlowContext ctx);

  // -----------------------------------------------------------
  // 4. Emit expressions to the UI
  // -----------------------------------------------------------

  /// Notifies the UI of a state change (loading, success, error). The UI listens to [expressions].
  ///
  /// **Why use it:** The UI doesn't ask "are you loading?"; the flow announces state.
  /// **Example:** `emitExpression("loading");` then `emitExpression("success", payload: user);`
  void emitExpression(String type, {dynamic payload}) {
    if (kDebugMode) {
      final c = contract;
      if (c != null && !c.allowsExpression(type)) {
        debugPrint(
          'OmegaFlow[$id]: emitted expression type "$type" not in contract (allowed: ${c.emittedExpressionTypes}).',
        );
      }
    }
    if (!_expressions.isClosed) {
      final expr = OmegaFlowExpression(type, payload: payload);
      _lastExpression = expr;
      _expressions.add(expr);
    }
  }

  // -----------------------------------------------------------
  // 5. Snapshot (current state)
  // -----------------------------------------------------------

  /// Snapshot of current state (id, state, memory, last expression). For debugging, persistence or restore.
  ///
  /// **Example:** `final snap = flow.getSnapshot(); await save(snap.toJson());`
  OmegaFlowSnapshot getSnapshot() => OmegaFlowSnapshot(
        flowId: id,
        state: state,
        memory: Map<String, dynamic>.from(memory),
        lastExpression: _lastExpression,
      );

  /// Replaces [memory] with [data]. Use after loading a snapshot (restore on launch).
  ///
  /// **Example:** `flow.restoreMemory(snapshot.memory);`
  void restoreMemory(Map<String, dynamic> data) {
    memory.clear();
    memory.addAll(Map<String, dynamic>.from(data));
  }
}
