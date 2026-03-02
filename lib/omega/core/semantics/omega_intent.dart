import '../types/omega_object.dart';

class OmegaIntent extends OmegaObject {
  final String action;
  final dynamic data;

  const OmegaIntent({required super.id, required this.action, this.data});
}
