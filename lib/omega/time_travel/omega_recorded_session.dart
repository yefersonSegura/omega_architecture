// lib/omega/time_travel/omega_recorded_session.dart

import '../core/events/omega_event.dart';
import '../flows/omega_flow_snapshot.dart';

/// A recorded session: initial app snapshot plus the list of events emitted during recording.
///
/// **Why use it:** Represents a "capture" of app behavior for replay or time-travel. Use
/// [OmegaTimeTravelRecorder] to create sessions, then [OmegaTimeTravelRecorder.replay] to
/// restore state and re-emit events up to a given index.
///
/// **Example:** After recording, replay up to step 5 to inspect state at that moment:
/// ```dart
/// final session = recorder.stopRecording();
/// recorder.replay(session, channel, flowManager, upToIndex: 5);
/// ```
class OmegaRecordedSession {
  /// Snapshot taken when recording started. Restored before replay so the app state is reset.
  final OmegaAppSnapshot? initialSnapshot;

  /// Events emitted on the channel during the recording (in order).
  final List<OmegaEvent> events;

  const OmegaRecordedSession({
    this.initialSnapshot,
    this.events = const [],
  });

  /// Number of recorded events.
  int get length => events.length;

  /// Serializes this session to a JSON-friendly map for saving trace files.
  /// Use with [OmegaTimeTravelRecorder] and save to disk for `omega trace view`.
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (initialSnapshot != null) 'initialSnapshot': initialSnapshot!.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
      };

  /// Creates a session from a map (e.g. from a trace file). Used when loading saved traces.
  static OmegaRecordedSession fromJson(Map<String, dynamic> json) {
    OmegaAppSnapshot? initialSnapshot;
    final snap = json['initialSnapshot'];
    if (snap is Map) {
      initialSnapshot =
          OmegaAppSnapshot.fromJson(Map<String, dynamic>.from(snap));
    }
    final eventsList = json['events'];
    final events = eventsList is List
        ? eventsList
            .map((e) => e is Map
                ? OmegaEvent.fromJson(Map<String, dynamic>.from(e))
                : null)
            .whereType<OmegaEvent>()
            .toList()
        : <OmegaEvent>[];
    return OmegaRecordedSession(
      initialSnapshot: initialSnapshot,
      events: events,
    );
  }
}
