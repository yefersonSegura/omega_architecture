// lib/omega/core/types/omega_failure.dart

import 'omega_object.dart';

/// [OmegaFailure] representa un error o fallo dentro del sistema.
/// Extiende de [OmegaObject] para mantener consistencia en la jerarquía.
class OmegaFailure extends OmegaObject {
  /// Un mensaje legible que describe el fallo.
  final String message;

  /// Detalles adicionales sobre el error, opcional.
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
