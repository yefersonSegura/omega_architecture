// lib/omega/core/types/omega_object.dart

/// [OmegaObject] es la clase base para todos los objetos del sistema Omega.
/// Proporciona un identificador único [id] y un mapa de metadatos [meta].
abstract class OmegaObject {
  final String id;
  final Map<String, dynamic> meta;

  const OmegaObject({required this.id, this.meta = const {}});
}
