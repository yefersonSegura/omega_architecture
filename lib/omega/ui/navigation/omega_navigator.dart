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
    if (!intent.name.startsWith("navigate.")) return;

    final destination = intent.name.replaceFirst("navigate.", "");

    final entry = _routes[destination];
    if (entry == null) return;

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: entry.route.builder),
    );
  }
}
