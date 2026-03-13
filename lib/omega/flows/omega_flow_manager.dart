// lib/omega/flows/omega_flow_manager.dart

import 'dart:async';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

import '../core/channel/omega_channel.dart';
import 'omega_flow.dart';
import 'omega_flow_snapshot.dart';
import 'omega_flow_state.dart';

/// Manages all flows: registers them, activates/pauses, and routes intents to those in running state.
///
/// **Why use it:** The UI and agents don't know which flow should receive an intent; the manager
/// sends it only to flows in [OmegaFlowState.running]. With [wireNavigator] you connect the channel to the navigator.
///
/// **Example:** `manager.registerFlow(AuthFlow(channel)); manager.switchTo("authFlow"); manager.handleIntent(intent);`
class OmegaFlowManager {
  final OmegaChannel channel;

  final Map<String, OmegaFlow> _flows = {};
  StreamSubscription? _navSubscription;

  /// Id of the main flow (the one last activated with [switchTo]). Useful for snapshot and restore.
  String? activeFlowId;

  OmegaFlowManager({required this.channel});

  // -----------------------------------------------------------
  // Register Flow
  // -----------------------------------------------------------

  /// Registers a flow so it can be activated and receive intents. Call at bootstrap (omega_setup).
  ///
  /// **Example:** `flowManager.registerFlow(AuthFlow(channel));`
  void registerFlow(OmegaFlow flow) {
    _flows[flow.id] = flow;
  }

  // -----------------------------------------------------------
  // Get Flow
  // -----------------------------------------------------------

  /// Returns the flow registered with [id]. Use so the UI can listen to its [expressions] (e.g. flow.expressions.listen(...)).
  OmegaFlow? getFlow(String id) => _flows[id];

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

  /// Sends the [intent] to all flows that are running. The UI calls this when emitting an action.
  ///
  /// **Why use it:** The screen doesn't know the flow; it just calls handleIntent(OmegaIntent.fromName(AppIntent.authLogin, payload: creds)).
  /// **Example:** `flowManager.handleIntent(OmegaIntent.fromName(AppIntent.authLogin, payload: creds));`
  void handleIntent(OmegaIntent intent) {
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
      if (event.name == navigationIntentEvent) {
        if (event.payload is OmegaIntent) {
          nav.handleIntent(event.payload as OmegaIntent);
        }
      } else if (event.name.startsWith("navigate.")) {
        nav.handleIntent(
          OmegaIntent(id: event.id, name: event.name, payload: event.payload),
        );
      }
    });
  }

  /// Cancels subscriptions (e.g. navigation). Call when closing the app.
  void dispose() {
    _navSubscription?.cancel();
    _navSubscription = null;
  }
}
