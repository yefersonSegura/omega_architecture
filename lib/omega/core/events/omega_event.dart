import '../types/omega_object.dart';
import '../semantics/omega_event_name.dart';

/// [OmegaEvent] representa un evento que ocurre en el sistema y se transmite por [OmegaChannel].
///
/// Los agentes y flows se suscriben al canal y reaccionan según [name] (ej. "auth.login.success").
/// Los datos opcionales van en [payload]. Extiende [OmegaObject] (tiene [id] y [meta]).
///
/// Para evitar strings mágicos, usa [OmegaEventName] y [fromName]:
/// `channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: data));`
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

  /// Crea un evento a partir de un nombre tipado ([OmegaEventName]). Si [id] es null, se genera uno.
  factory OmegaEvent.fromName(
    OmegaEventName eventName, {
    dynamic payload,
    String? id,
    Map<String, dynamic> meta = const {},
  }) =>
      OmegaEvent(
        id: id ?? 'ev:${DateTime.now().millisecondsSinceEpoch}',
        name: eventName.name,
        payload: payload,
        meta: meta,
      );
}
