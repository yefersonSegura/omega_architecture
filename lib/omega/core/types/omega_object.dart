// lib/omega/core/types/omega_object.dart

/// Base class for Omega system objects.
///
/// Provides [id] (unique identifier) and [meta] (optional metadata map).
/// [OmegaEvent], [OmegaIntent] and [OmegaFailure] extend this class.
abstract class OmegaObject {
  /// Unique object identifier.
  final String id;

  /// Optional metadata (key-value).
  final Map<String, dynamic> meta;

  const OmegaObject({required this.id, this.meta = const {}});
}
