// lib/omega/core/types/omega_failure.dart

import 'omega_object.dart';

/// [OmegaFailure] representa un error o fallo dentro del sistema.
///
/// Útil para emitir errores semánticos por el canal o devolverlos desde
/// agentes/flows. Extiende [OmegaObject] (tiene [id] y [meta]).
class OmegaFailure extends OmegaObject {
  /// Mensaje legible que describe el fallo.
  final String message;

  /// Detalles adicionales (stack trace, código, etc.), opcional.
  final dynamic details;

  const OmegaFailure({
    required super.id,
    required this.message,
    this.details,
    super.meta = const {},
  });

  @override
  String toString() =>
      "OmegaFailure(id: $id, message: $message, details: $details)";
}
