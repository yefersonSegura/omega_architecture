// lib/omega/flows/omega_flow_manager.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

import '../core/channel/omega_channel.dart';
import 'omega_flow.dart';
import 'omega_flow_snapshot.dart';
import 'omega_flow_state.dart';
import 'omega_intent_handler_context.dart';

/// Manages all flows: registers them, activates/pauses, and routes intents to those in running state.
///
/// **Why use it:** The UI and agents don't know which flow should receive an intent; the manager
/// sends it only to flows in [OmegaFlowState.running]. With [wireNavigator] you connect the channel to the navigator.
///
/// **Example:** `manager.registerFlow(AuthFlow(channel: ch, agent: authAgent)); manager.switchTo("authFlow"); manager.handleIntent(intent);`
class _RegisteredIntentHandler {
  const _RegisteredIntentHandler({
    required this.intentName,
    required this.handler,
    required this.consumeIntent,
  });

  final String intentName;
  final OmegaIntentHandler handler;
  final bool consumeIntent;
}

class OmegaFlowManager {
  final OmegaChannel channel;

  final Map<String, OmegaFlow> _flows = {};
  final List<_RegisteredIntentHandler> _intentHandlers = [];
  StreamSubscription? _navSubscription;

  /// Id of the main flow (the one last activated with [switchTo]). Useful for snapshot and restore.
  String? activeFlowId;

  OmegaFlowManager({required this.channel});

  // -----------------------------------------------------------
  // Register Flow
  // -----------------------------------------------------------

  /// Registers a flow so it can be activated and receive intents. Call at bootstrap (omega_setup).
  ///
  /// **Example:** `flowManager.registerFlow(AuthFlow(channel: ch, agent: authAgent));`
  void registerFlow(OmegaFlow flow) {
    _flows[flow.id] = flow;
  }

  /// Ids of all registered flows (same strings as [OmegaFlow.id]). Useful for debugging.
  Iterable<String> get registeredFlowIds => _flows.keys;

  // -----------------------------------------------------------
  // Get Flow
  // -----------------------------------------------------------

  /// Returns the flow registered with [id]. Use so the UI can listen to its [expressions] (e.g. flow.expressions.listen(...)).
  OmegaFlow? getFlow(String id) => _flows[id];

  /// Like [getFlow], but also finds a flow when [id] matches a registered key
  /// ignoring ASCII case (e.g. route `UserInterface` vs [OmegaFlowIdEnumWire] `userInterface`).
  ///
  /// Prefer using the **same** string for [OmegaFlow] `super(id: ...)`, [OmegaFlowExpressionBuilder]
  /// `flowId`, and `navigate.{id}`; this method avoids the common mismatch only.
  OmegaFlow? getFlowFlexible(String id) {
    final direct = _flows[id];
    if (direct != null) return direct;
    final lower = id.toLowerCase();
    for (final e in _flows.entries) {
      if (e.key.toLowerCase() == lower) {
        return e.value;
      }
    }
    return null;
  }

  // -----------------------------------------------------------
  // Snapshot (current state)
  // -----------------------------------------------------------

  /// Snapshot of a flow by id. For debugging or per-flow persistence.
  OmegaFlowSnapshot? getFlowSnapshot(String id) => _flows[id]?.getSnapshot();

  /// List of snapshots for all flows. For inspection or persistence.
  List<OmegaFlowSnapshot> getSnapshots() =>
      _flows.values.map((f) => f.getSnapshot()).toList();

  /// Snapshot of app state (active flow + all flows). For save/restore on close/open.
  ///
  /// **Example:** `final json = flowManager.getAppSnapshot().toJson(); await save(jsonEncode(json));`
  OmegaAppSnapshot getAppSnapshot() => OmegaAppSnapshot(
        activeFlowId: activeFlowId,
        flows: getSnapshots(),
      );

  /// Restores each flow's memory and activates the flow that was active. Call when opening the app after loading the snapshot.
  ///
  /// **Example:** `final snapshot = OmegaAppSnapshot.fromJson(jsonDecode(loaded)); flowManager.restoreFromSnapshot(snapshot);`
  void restoreFromSnapshot(OmegaAppSnapshot snapshot) {
    for (final flowSnapshot in snapshot.flows) {
      final flow = _flows[flowSnapshot.flowId];
      if (flow != null) {
        flow.restoreMemory(flowSnapshot.memory);
      }
    }
    activeFlowId = snapshot.activeFlowId;
    if (snapshot.activeFlowId != null) {
      switchTo(snapshot.activeFlowId!);
    }
  }

  // -----------------------------------------------------------
  // Handle Intent
  // -----------------------------------------------------------

  /// Registers a lightweight [handler] invoked when [handleIntent] receives an intent
  /// whose [OmegaIntent.name] equals [intentName].
  ///
  /// Handlers run **before** running flows. If any matching handler was registered with
  /// [consumeIntent] `true`, intents are **not** forwarded to flows (use for trivial cases
  /// that replace a whole [OmegaFlow] for one intent, or for side-effects only).
  ///
  /// For domain orchestration and UI expressions, prefer a real [OmegaFlow]; handlers are
  /// optional sugar to reduce boilerplate.
  void registerIntentHandler({
    required String intentName,
    required OmegaIntentHandler handler,
    bool consumeIntent = false,
  }) {
    _intentHandlers.add(
      _RegisteredIntentHandler(
        intentName: intentName,
        handler: handler,
        consumeIntent: consumeIntent,
      ),
    );
  }

  /// Removes all intent handlers (e.g. in tests or hot-restart scenarios).
  void clearIntentHandlers() {
    _intentHandlers.clear();
  }

  /// Sends the [intent] to registered handlers (if any), then to all flows that are running.
  ///
  /// **Why use it:** The screen doesn't know the flow; it just calls handleIntent(OmegaIntent.fromName(AppIntent.authLogin, payload: creds)).
  /// **Example:** `flowManager.handleIntent(OmegaIntent.fromName(AppIntent.authLogin, payload: creds));`
  void handleIntent(OmegaIntent intent) {
    var consume = false;
    final ctx = OmegaIntentHandlerContext(channel: channel, intent: intent);
    for (final h in _intentHandlers) {
      if (h.intentName != intent.name) continue;
      try {
        h.handler(intent, ctx);
      } catch (e, st) {
        developer.log(
          'Intent handler failed; other handlers and flows still run.',
          name: 'omega_flow_manager',
          error: e,
          stackTrace: st,
        );
        continue;
      }
      if (h.consumeIntent) consume = true;
    }
    if (consume) return;

    for (final flow in _flows.values) {
      if (flow.state == OmegaFlowState.running) {
        flow.receiveIntent(intent);
      }
    }
  }

  // -----------------------------------------------------------
  // Activate Flow (without affecting others)
  // -----------------------------------------------------------

  /// Activates the flow [id] without pausing others. Multiple flows can be running and all receive intents.
  ///
  /// **Why use it:** When you want more than one flow to react (e.g. auth + cart). For a single active flow, use [switchTo].
  /// **Example:** `flowManager.activate("authFlow"); flowManager.activate("cartFlow");`
  bool activate(String id) {
    final flow = _flows[id];
    if (flow == null) return false;
    if (flow.state == OmegaFlowState.running) return true;

    flow.start();
    return true;
  }

  // -----------------------------------------------------------
  // Activate Flow exclusively
  // -----------------------------------------------------------

  void activateExclusive(String id) {
    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
        activeFlowId = id;
      } else if (flow.state == OmegaFlowState.running) {
        flow.pause();
      }
    }
  }

  // -----------------------------------------------------------
  // Switch main Flow
  // -----------------------------------------------------------

  /// Activates the flow [id] and pauses the rest. Only one "main" flow receives intents.
  ///
  /// **Why use it:** After login you want only AuthFlow (or HomeFlow) to be active.
  /// **Example:** `flowManager.switchTo("authFlow");` on startup. Idempotent.
  bool switchTo(String id) {
    final target = _flows[id];
    if (target == null) return false;

    final alreadyOnlyRunning =
        target.state == OmegaFlowState.running &&
        _flows.values.every((f) =>
            f.id == id || f.state != OmegaFlowState.running);
    if (alreadyOnlyRunning) {
      activeFlowId = id;
      return true;
    }

    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
        activeFlowId = id;
      } else if (flow.state == OmegaFlowState.running) {
        flow.pause();
      }
    }
    return true;
  }

  // -----------------------------------------------------------
  // Pause Flow
  // -----------------------------------------------------------

  void pause(String id) {
    final flow = _flows[id];
    flow?.pause();
  }

  // -----------------------------------------------------------
  // Sleep Flow
  // -----------------------------------------------------------

  void sleep(String id) {
    final flow = _flows[id];
    flow?.sleep();
  }

  // -----------------------------------------------------------
  // End Flow
  // -----------------------------------------------------------

  void end(String id) {
    final flow = _flows[id];
    flow?.end();

    if (activeFlowId == id) {
      activeFlowId = null;
    }
  }

  void endAll() {
    for (final flow in _flows.values) {
      flow.end();
    }

    activeFlowId = null;
  }

  // -----------------------------------------------------------
  // Navigator connection
  // -----------------------------------------------------------

  /// Connects the channel to the navigator: when "navigation.intent" or "navigate.xxx" is emitted, the navigator does push/pushReplacement.
  ///
  /// **Why use it:** Flows navigate by emitting events; they don't use BuildContext. Call once at bootstrap.
  /// **Example:** `flowManager.wireNavigator(runtime.navigator);`
  void wireNavigator(OmegaNavigator nav) {
    _navSubscription?.cancel();
    _navSubscription = channel.events.listen((event) {
      try {
        if (event.name == navigationIntentEvent) {
          if (event.payload is OmegaIntent) {
            nav.handleIntent(event.payload as OmegaIntent);
          }
        } else if (event.name.startsWith("navigate.")) {
          nav.handleIntent(
            OmegaIntent(id: event.id, name: event.name, payload: event.payload),
          );
        }
      } catch (e, st) {
        developer.log(
          'Navigator handling failed for event "${event.name}".',
          name: 'omega_flow_manager',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  /// Cancels subscriptions (e.g. navigation). Call when closing the app.
  void dispose() {
    _navSubscription?.cancel();
    _navSubscription = null;
    _intentHandlers.clear();
  }
}
