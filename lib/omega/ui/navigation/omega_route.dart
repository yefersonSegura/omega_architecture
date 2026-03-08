// lib/omega/ui/navigation/omega_route.dart

import 'package:flutter/widgets.dart';

/// [OmegaRoute] define una pantalla que el [OmegaNavigator] puede mostrar.
///
/// El [id] se usa para enrutar: un intent "navigate.login" lleva a la ruta con [id] "login".
/// [builder] construye el widget de la pantalla (p. ej. LoginPage).
class OmegaRoute {
  /// Identificador de la ruta (ej. "login", "home"); debe coincidir con el destino en "navigate.{id}".
  final String id;

  /// Construye el widget de la pantalla.
  final WidgetBuilder builder;

  const OmegaRoute({required this.id, required this.builder});
}
