// lib/omega/core/types/omega_object.dart

abstract class OmegaObject {
  final String id;
  final Map<String, dynamic> meta;

  const OmegaObject({required this.id, this.meta = const {}});
}
