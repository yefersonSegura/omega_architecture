// lib/omega/ui/navigation/omega_route.dart

import 'package:flutter/widgets.dart';

/// [OmegaRoute] define una ruta de navegación en la aplicación.
class OmegaRoute {
  /// Identificador único de la ruta (ej: "login", "home").
  final String id;

  /// Función constructora que devuelve el Widget de la pantalla.
  final WidgetBuilder builder;

  const OmegaRoute({required this.id, required this.builder});
}
