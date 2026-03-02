// lib/omega/ui/navigation/omega_route.dart

import 'package:flutter/widgets.dart';

class OmegaRoute {
  final String id; // Ej: "login", "home", "products"
  final WidgetBuilder builder; // La pantalla a mostrar

  const OmegaRoute({required this.id, required this.builder});
}
