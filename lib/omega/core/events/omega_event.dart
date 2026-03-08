import '../types/omega_object.dart';

/// [OmegaEvent] representa un evento que ocurre en el sistema y se transmite por [OmegaChannel].
///
/// Los agentes y flows se suscriben al canal y reaccionan según [name] (ej. "auth.login.success").
/// Los datos opcionales van en [payload]. Extiende [OmegaObject] (tiene [id] y [meta]).
class OmegaEvent extends OmegaObject {
  /// Nombre descriptivo del evento (ej. "auth.login.success", "user.updated").
  final String name;

  /// Datos adicionales asociados al evento (objeto, mapa, etc.).
  final dynamic payload;

  const OmegaEvent({
    required super.id,
    required this.name,
    this.payload,
    super.meta = const {},
  });
}
