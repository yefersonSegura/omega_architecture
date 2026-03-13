// lib/omega/time_travel/omega_time_travel_recorder.dart

import 'dart:async';

import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';
import '../flows/omega_flow_manager.dart';
import '../flows/omega_flow_snapshot.dart';

import 'omega_recorded_session.dart';

/// Records channel events (and an optional initial snapshot) for replay and time-travel.
///
/// **Why use it:** Capture a session (events + initial state), then replay it to reproduce
/// bugs or "go back" to a previous moment: restore the initial snapshot and re-emit events
/// up to a given index. Useful for debugging and demos.
///
/// **Example:**
/// ```dart
/// final recorder = OmegaTimeTravelRecorder();
/// recorder.startRecording(channel, flowManager);
/// // ... user interacts, events are recorded ...
/// final session = recorder.stopRecording();
/// // Replay up to event index 5 (time-travel to that moment)
/// recorder.replay(session, channel, flowManager, upToIndex: 5);
/// ```
class OmegaTimeTravelRecorder {
  StreamSubscription<OmegaEvent>? _subscription;
  OmegaAppSnapshot? _initialSnapshot;
  final List<OmegaEvent> _events = [];
  bool _isReplaying = false;
  bool _isRecording = false;

  /// Whether the recorder is currently recording (subscribed to the channel).
  bool get isRecording => _isRecording;

  /// Starts recording: subscribes to [channel] and takes an initial snapshot from [flowManager].
  /// All events emitted on the channel from now on are stored until [stopRecording].
  ///
  /// If already recording, this does nothing (or you can call [stopRecording] first).
  void startRecording(OmegaChannel channel, OmegaFlowManager flowManager) {
    if (_isRecording) return;
    _initialSnapshot = flowManager.getAppSnapshot();
    _events.clear();
    _isRecording = true;
    _subscription = channel.events.listen((event) {
      if (!_isReplaying) {
        _events.add(event);
      }
    });
  }

  /// Stops recording, cancels the subscription and returns the recorded session.
  /// The recorder can be reused with [startRecording] after this.
  OmegaRecordedSession stopRecording() {
    _subscription?.cancel();
    _subscription = null;
    _isRecording = false;
    final session = OmegaRecordedSession(
      initialSnapshot: _initialSnapshot,
      events: List<OmegaEvent>.from(_events),
    );
    _initialSnapshot = null;
    _events.clear();
    return session;
  }

  /// Replays [session]: restores [session.initialSnapshot] (if present) via [flowManager],
  /// then re-emits [session.events] to [channel] from index 0 up to [upToIndex] (inclusive).
  /// If [upToIndex] is null, replays all events.
  ///
  /// While replaying, the recorder does not record (so the same [OmegaTimeTravelRecorder]
  /// that recorded the session can be used without double-recording). Use this to
  /// "time-travel" to the state after event [upToIndex]: restore initial state and
  /// replay events 0..upToIndex.
  ///
  /// **Example:** Replay up to step 5 to inspect app state at that moment:
  /// ```dart
  /// recorder.replay(session, channel, flowManager, upToIndex: 5);
  /// ```
  void replay(
    OmegaRecordedSession session,
    OmegaChannel channel,
    OmegaFlowManager flowManager, {
    int? upToIndex,
  }) {
    if (session.events.isEmpty) return;
    if (session.initialSnapshot != null) {
      flowManager.restoreFromSnapshot(session.initialSnapshot!);
    }
    final lastIndex = session.events.length - 1;
    final end = upToIndex != null
        ? upToIndex.clamp(0, lastIndex)
        : lastIndex;
    _isReplaying = true;
    try {
      for (var i = 0; i <= end && i < session.events.length; i++) {
        channel.emit(session.events[i]);
      }
    } finally {
      // Keep _isReplaying true until after stream delivery (async); otherwise
      // re-emitted events would be recorded.
      Future.microtask(() => _isReplaying = false);
    }
  }
}
