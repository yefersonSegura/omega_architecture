// lib/omega/ui/navigation/omega_navigator.dart

import 'package:flutter/material.dart';

import '../../core/semantics/omega_intent.dart';
import 'omega_route.dart';
import 'omega_navigation_entry.dart';

class OmegaNavigator {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, OmegaNavigationEntry> _routes = {};

  // -----------------------------------------------------------
  // 1. Registrar rutas (pantallas)
  // -----------------------------------------------------------
  void registerRoute(OmegaRoute route) {
    _routes[route.id] = OmegaNavigationEntry(route);
  }

  // -----------------------------------------------------------
  // 2. Procesar intención de navegación
  // -----------------------------------------------------------
  void handleIntent(OmegaIntent intent) {
    if (!intent.action.startsWith("navigate.")) return;

    final destination = intent.action.replaceFirst("navigate.", "");

    final entry = _routes[destination];
    if (entry == null) return;

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: entry.route.builder),
    );
  }
}
