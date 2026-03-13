# Time-travel: record and replay

Omega lets you **record** a session (events + initial app snapshot) and **replay** it to reproduce behavior or "go back" to a previous moment. This is useful for debugging, demos, and auditing.

## Concepts

- **Record:** While recording, every event emitted on the channel is stored in order. When you start recording, an **initial snapshot** of the app (all flows’ state and memory) is taken so you can restore it before replay.
- **Replay:** Restore the initial snapshot (so flows and active flow are reset), then re-emit the recorded events up to a chosen index. The app behaves as if it had just processed those events—**time-travel** to that step.
- **Session:** A recorded session is an [OmegaRecordedSession]: it holds the initial snapshot and the list of events. You get it by calling [OmegaTimeTravelRecorder.stopRecording].

## Usage

### 1. Create a recorder and start recording

```dart
final recorder = OmegaTimeTravelRecorder();
recorder.startRecording(channel, flowManager);
```

From this moment, every event emitted on `channel` is stored. An initial snapshot is taken from `flowManager`.

### 2. Stop and get the session

```dart
final session = recorder.stopRecording();
// session.initialSnapshot  → snapshot at start
// session.events           → list of events in order
// session.length           → number of events
```

### 3. Replay (time-travel)

Replay the session so the app is in the state it was **after** a given event index:

```dart
// Replay all events (reproduce the whole session)
recorder.replay(session, channel, flowManager);

// Replay only up to event index 5 (time-travel to step 5)
recorder.replay(session, channel, flowManager, upToIndex: 5);
```

Replay does two things:

1. Restores `session.initialSnapshot` via `flowManager.restoreFromSnapshot(...)` so flows and active flow are reset.
2. Emits `session.events[0]`, `session.events[1]`, … up to `upToIndex` (or all if `upToIndex` is null) on `channel`.

While replaying, the recorder does **not** record again (so you can use the same recorder without double-recording).

## When to use

- **Debugging:** Record a session where a bug appears, then replay up to different steps to see when state goes wrong.
- **Demos:** Record a flow once and replay it in a demo or screenshot run.
- **Tests:** Record a real run and replay it in tests (same channel and flow manager, or a test copy) to assert on state at specific steps.

## Notes

- Events are kept in memory; payloads are not serialized. For long sessions or persistence to disk, you could extend [OmegaRecordedSession] to store serialized events (e.g. JSON) and rehydrate when replaying.
- Replay runs synchronously: each event is emitted in order. If your flows/agents do async work, that work will run during replay.
- The snapshot restores **flow memory and active flow** only; the navigator route stack is not saved. Replayed navigation events will run again and the navigator will push/replace as defined by your routes.
- The **Inspector** can show current flow state and recent events; combined with time-travel you can inspect state at any recorded step after replaying up to that index.
