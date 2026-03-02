import '../types/omega_object.dart';

class OmegaEvent extends OmegaObject {
  final String name;
  final dynamic payload;

  const OmegaEvent({
    required super.id,
    required this.name,
    this.payload,
    super.meta = const {},
  });
}
