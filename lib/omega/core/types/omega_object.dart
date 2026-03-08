// lib/omega/core/types/omega_object.dart

/// [OmegaObject] es la clase base de los objetos del sistema Omega.
///
/// Proporciona [id] (identificador único) y [meta] (mapa de metadatos opcional).
/// [OmegaEvent], [OmegaIntent] y [OmegaFailure] extienden de esta clase.
abstract class OmegaObject {
  /// Identificador único del objeto.
  final String id;

  /// Metadatos opcionales (clave-valor).
  final Map<String, dynamic> meta;

  const OmegaObject({required this.id, this.meta = const {}});
}
