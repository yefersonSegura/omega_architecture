// lib/omega/ui/navigation/omega_navigator.dart

import 'package:flutter/material.dart';

import '../../core/semantics/omega_intent.dart';
import 'omega_route.dart';
import 'omega_navigation_entry.dart';

/// [OmegaNavigator] gestiona la navegación de la aplicación basada en intenciones.
/// Mantiene un registro de rutas y utiliza una [GlobalKey] para interactuar con el Navigator de Flutter.
class OmegaNavigator {
  /// Llave global para acceder al estado del Navigator de Flutter.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, OmegaNavigationEntry> _routes = {};

  // -----------------------------------------------------------
  // 1. Registrar rutas (pantallas)
  // -----------------------------------------------------------
  /// Registra una nueva ruta [route] en el navegador.
  void registerRoute(OmegaRoute route) {
    _routes[route.id] = OmegaNavigationEntry(route);
  }

  // -----------------------------------------------------------
  // 2. Procesar intención de navegación
  // -----------------------------------------------------------
  /// Procesa una [OmegaIntent] de navegación.
  /// Si la intención comienza con "navigate.", intenta cambiar a la ruta especificada.
  void handleIntent(OmegaIntent intent) {
    print("OmegaNavigator: Procesando intención -> ${intent.name}");

    if (!intent.name.startsWith("navigate.")) {
      print(
        "OmegaNavigator: Ignorando intención (no comienza con 'navigate.')",
      );
      return;
    }

    final destination = intent.name.replaceFirst("navigate.", "");
    print("OmegaNavigator: Buscando ruta para el destino -> '$destination'");

    final entry = _routes[destination];
    if (entry == null) {
      print(
        "OmegaNavigator ERROR: No se encontró la ruta '$destination' registrada.",
      );
      print("Rutas registradas actualmente: ${_routes.keys.toList()}");
      return;
    }

    if (navigatorKey.currentState == null) {
      print(
        "OmegaNavigator ERROR: navigatorKey.currentState es NULL. Asegúrate de pasar la llave al MaterialApp.",
      );
      return;
    }

    print("OmegaNavigator: Navegando a '$destination'...");
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: entry.route.builder),
    );
  }
}
