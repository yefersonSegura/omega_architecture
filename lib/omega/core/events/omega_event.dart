import '../types/omega_object.dart';

/// [OmegaEvent] representa un evento que ocurre en el sistema y se transmite por el canal.
class OmegaEvent extends OmegaObject {
  /// El nombre descriptivo del evento.
  final String name;

  /// Datos adicionales asociados al evento.
  final dynamic payload;

  const OmegaEvent({
    required super.id,
    required this.name,
    this.payload,
    super.meta = const {},
  });
}
