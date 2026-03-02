// lib/omega/core/types/omega_failure.dart

class OmegaFailure {
  final String
  code; // Código interno del error (ej: "auth.invalid_credentials")
  final String message; // Mensaje legible
  final dynamic details; // Datos extra (opcional)

  const OmegaFailure({required this.code, required this.message, this.details});

  @override
  String toString() =>
      "OmegaFailure(code: $code, message: $message, details: $details)";
}
