import '../types/omega_object.dart';

/// [OmegaIntent] representa una intención semántica o petición de acción en el sistema.
///
/// La UI no llama métodos directamente; emite intents. [OmegaFlowManager] los enruta
/// a los flows en ejecución. También se usan para navegación (ej. name "navigate.login").
/// Extiende [OmegaObject] (tiene [id] y [meta]).
class OmegaIntent extends OmegaObject {
  /// Nombre de la intención (ej. "auth.login", "navigate.login", "cart.add").
  final String name;

  /// Información necesaria para procesar la intención (credenciales, id de ruta, etc.).
  final dynamic payload;

  const OmegaIntent({required super.id, required this.name, this.payload});
}
