// lib/omega/ui/navigation/omega_route.dart

import 'package:flutter/widgets.dart';

/// [OmegaRoute] define una pantalla que el [OmegaNavigator] puede mostrar.
///
/// El [id] se usa para enrutar: "navigate.login" o "navigate.push.login" llevan a la ruta con [id] "login".
/// [builder] construye el widget de la pantalla. Para recibir argumentos (p. ej. [intent.payload]),
/// usa `ModalRoute.of(context)?.settings.arguments` dentro del builder.
class OmegaRoute {
  /// Identificador de la ruta (ej. "login", "home"); destino en "navigate.{id}" o "navigate.push.{id}".
  final String id;

  /// Construye el widget de la pantalla. Argumentos disponibles en [RouteSettings.arguments].
  final WidgetBuilder builder;

  const OmegaRoute({required this.id, required this.builder});
}
