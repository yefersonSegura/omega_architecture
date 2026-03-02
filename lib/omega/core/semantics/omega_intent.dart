import '../types/omega_object.dart';

/// [OmegaIntent] representa una intención semántica o una petición de acción en el sistema.
class OmegaIntent extends OmegaObject {
  /// El nombre de la intención o acción solicitada.
  final String name;

  /// Información necesaria para procesar la intención.
  final dynamic payload;

  const OmegaIntent({required super.id, required this.name, this.payload});
}
