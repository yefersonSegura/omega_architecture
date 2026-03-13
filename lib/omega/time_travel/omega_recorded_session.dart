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
}
