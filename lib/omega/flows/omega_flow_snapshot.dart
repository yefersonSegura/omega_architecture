import 'omega_flow_expression.dart';
import 'omega_flow_state.dart';

// Serialization: for persistence, [memory] and [lastExpression.payload] must be
// JSON-serializable (primitives, List, Map). See [toJson] and [fromJson].

/// Snapshot of the current state of an [OmegaFlow].
///
/// Includes [flowId], [state], a copy of [memory] and the last [lastExpression]
/// emitted (if any). Does not modify the flow; only reads its state.
///
/// **Use cases:**
/// - **Debugging:** See flow state, [memory] contents and last expression without prints everywhere.
/// - **Persistence:** Save the snapshot (e.g. to disk) on app close and restore state on reopen.
/// - **Time-travel:** In dev tools, keep a history of snapshots to "go back" and see app state at a point in time.
///
/// Get snapshot of a flow: [OmegaFlow.getSnapshot].
/// Snapshot of all flows: [OmegaFlowManager.getSnapshots] or [OmegaFlowManager.getAppSnapshot].
class OmegaFlowSnapshot {
  /// Flow id.
  final String flowId;

  /// Current flow state (idle, running, paused, etc.).
  final OmegaFlowState state;

  /// Shallow copy of the flow's memory at snapshot time.
  final Map<String, dynamic> memory;

  /// Last expression emitted by the flow, or null if none.
  final OmegaFlowExpression? lastExpression;

  const OmegaFlowSnapshot({
    required this.flowId,
    required this.state,
    required this.memory,
    this.lastExpression,
  });

  /// Converts the snapshot to a map for saving (disk, SharedPreferences). memory and payload must be JSON-serializable.
  ///
  /// **Example:** `final json = flow.getSnapshot().toJson(); await storage.save(jsonEncode(json));`
  Map<String, dynamic> toJson() => <String, dynamic>{
        'flowId': flowId,
        'state': state.name,
        'memory': Map<String, dynamic>.from(memory),
        if (lastExpression != null)
          'lastExpression': <String, dynamic>{
            'type': lastExpression!.type,
            if (lastExpression!.payload != null) 'payload': lastExpression!.payload,
          },
      };

  /// Creates a snapshot from a map (e.g. jsonDecode of saved data). Used when restoring state.
  static OmegaFlowSnapshot fromJson(Map<String, dynamic> json) {
    final stateStr = json['state'] as String? ?? 'idle';
    final state = OmegaFlowState.values.firstWhere(
      (e) => e.name == stateStr,
      orElse: () => OmegaFlowState.idle,
    );
    final mem = json['memory'];
    final memory = mem is Map
        ? Map<String, dynamic>.from(mem)
        : <String, dynamic>{};
    OmegaFlowExpression? lastExpression;
    final le = json['lastExpression'];
    if (le is Map) {
      final m = Map<String, dynamic>.from(le);
      lastExpression = OmegaFlowExpression(
        m['type'] as String? ?? '',
        payload: m['payload'],
      );
    }
    return OmegaFlowSnapshot(
      flowId: json['flowId'] as String? ?? '',
      state: state,
      memory: memory,
      lastExpression: lastExpression,
    );
  }

  @override
  String toString() =>
      'OmegaFlowSnapshot(flowId: $flowId, state: $state, memory: ${memory.length} keys, lastExpression: ${lastExpression?.type})';
}

/// Snapshot of app state: active flow plus snapshots of all flows. For persistence or debugging.
///
/// **Example:** `final snap = flowManager.getAppSnapshot(); await storage.save(jsonEncode(snap.toJson()));`
class OmegaAppSnapshot {
  /// Id of the main flow.
  final String? activeFlowId;

  /// Snapshots of each registered flow.
  final List<OmegaFlowSnapshot> flows;

  const OmegaAppSnapshot({
    this.activeFlowId,
    required this.flows,
  });

  /// JSON map for saving. Restore with [fromJson] and [OmegaFlowManager.restoreFromSnapshot].
  Map<String, dynamic> toJson() => <String, dynamic>{
        'activeFlowId': activeFlowId,
        'flows': flows.map((f) => f.toJson()).toList(),
      };

  /// Creates snapshot from map (jsonDecode). Then flowManager.restoreFromSnapshot(snapshot).
  static OmegaAppSnapshot fromJson(Map<String, dynamic> json) {
    final activeFlowId = json['activeFlowId'] as String?;
    final flowsList = json['flows'];
    final flows = flowsList is List
        ? flowsList
            .map((e) => e is Map
                ? OmegaFlowSnapshot.fromJson(Map<String, dynamic>.from(e))
                : null)
            .whereType<OmegaFlowSnapshot>()
            .toList()
        : <OmegaFlowSnapshot>[];
    return OmegaAppSnapshot(activeFlowId: activeFlowId, flows: flows);
  }

  @override
  String toString() =>
      'OmegaAppSnapshot(activeFlowId: $activeFlowId, flows: ${flows.length})';
}
