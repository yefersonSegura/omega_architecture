# Time travel & traces

[OmegaTimeTravelRecorder](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaTimeTravelRecorder-class.html) captures **channel events** plus an optional **initial app snapshot** from the [OmegaFlowManager](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager-class.html). [OmegaRecordedSession](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaRecordedSession-class.html) stores that data so you can **replay** up to a chosen event index — useful for reproducing bugs and demos.

---

## Record → stop → replay

```dart
final recorder = OmegaTimeTravelRecorder();
recorder.startRecording(channel, flowManager);
// ... user drives the app; events append ...
final session = recorder.stopRecording();
// Restore state + re-emit events 0..n (inclusive)
recorder.replay(session, channel, flowManager, upToIndex: 12);
```

During replay the recorder sets an internal flag so re-emitted events are **not** appended again to the session list.

---

## Export JSON (CI, sharing, `omega trace`)

Sessions can be serialized for files or backends. Typical shape includes:

- **`events`** — list of recorded channel events  
- **`initialSnapshot`** — optional [OmegaAppSnapshot](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaAppSnapshot-class.html) JSON  

Use the CLI to inspect files without opening the app:

```bash
dart run omega_architecture:omega trace view ./session.json
dart run omega_architecture:omega trace validate ./session.json
```

**`omega ai explain ./session.json`** adds heuristics (and optional **`--provider-api`**) on top of the same file — see [Omega CLI](./cli).

---

## Snapshots & persistence

[OmegaFlowManager.getAppSnapshot](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager/getAppSnapshot.html) / [restoreFromSnapshot](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaFlowManager/restoreFromSnapshot.html) support **save / restore** of flow memory and active flow id. Values you persist should be **JSON-serializable** if you use `toJson` / `fromJson` on snapshots.

[OmegaSnapshotStorage](https://pub.dev/documentation/omega_architecture/latest/omega_architecture/OmegaSnapshotStorage-class.html) is the hook interface your app implements (file, `shared_preferences`, API, …).

---

## Example app

The **`example/`** project includes a **time-travel panel** in debug (see `lib/main.dart` and auth flow UI) wired to record/replay. Run:

```bash
cd example && flutter run
```

---

## Related

- [Channel & events](./channel-events) — what gets recorded  
- [Total architecture](./total-architecture) — snapshot row in the stack table  
