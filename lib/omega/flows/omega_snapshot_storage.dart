import 'omega_flow_snapshot.dart';

/// Optional contract to save and load [OmegaAppSnapshot] (disk, backend, etc.).
///
/// The app can implement this with `shared_preferences`, `path_provider` + File,
/// or a backend. On startup, load with [load] and call [OmegaFlowManager.restoreFromSnapshot].
/// On close or at key points, get [OmegaFlowManager.getAppSnapshot] and call [save].
///
/// Example with file (requires `path_provider` in the project):
/// ```dart
/// class FileSnapshotStorage implements OmegaSnapshotStorage {
///   FileSnapshotStorage(this.path);
///   final String path;
///   @override
///   Future<void> save(OmegaAppSnapshot snapshot) async {
///     final f = File(path);
///     await f.writeAsString(jsonEncode(snapshot.toJson()));
///   }
///   @override
///   Future<OmegaAppSnapshot?> load() async {
///     final f = File(path);
///     if (!await f.exists()) return null;
///     final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
///     return OmegaAppSnapshot.fromJson(map);
///   }
/// }
/// ```
abstract class OmegaSnapshotStorage {
  /// Saves the snapshot (e.g. to disk or cloud).
  Future<void> save(OmegaAppSnapshot snapshot);

  /// Loads the last saved snapshot, or null if none.
  Future<OmegaAppSnapshot?> load();
}
