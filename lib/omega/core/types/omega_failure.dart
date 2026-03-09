// lib/omega/core/types/omega_failure.dart

import 'omega_object.dart';

/// Represents an error or failure within the system.
///
/// Useful to emit semantic errors on the channel or return them from
/// agents/flows. Extends [OmegaObject] (has [id] and [meta]).
class OmegaFailure extends OmegaObject {
  /// Human-readable message describing the failure.
  final String message;

  /// Optional additional details (stack trace, code, etc.).
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
