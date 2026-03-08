import 'omega_flow_snapshot.dart';

/// Contrato opcional para guardar y cargar [OmegaAppSnapshot] (disco, backend, etc.).
///
/// La app puede implementar esta interfaz con `shared_preferences`, `path_provider` + File,
/// o un backend. Al iniciar, cargar con [load] y llamar a [OmegaFlowManager.restoreFromSnapshot].
/// Al cerrar o en puntos clave, obtener [OmegaFlowManager.getAppSnapshot] y llamar a [save].
///
/// Ejemplo con archivo (requiere `path_provider` en el proyecto):
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
  /// Guarda el snapshot (p. ej. en disco o en la nube).
  Future<void> save(OmegaAppSnapshot snapshot);

  /// Carga el último snapshot guardado, o null si no hay ninguno.
  Future<OmegaAppSnapshot?> load();
}
