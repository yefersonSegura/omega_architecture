// lib/omega/ui/navigation/omega_navigator.dart

import 'package:flutter/material.dart';

import '../../core/semantics/omega_intent.dart';
import 'omega_route.dart';
import 'omega_navigation_entry.dart';

/// Prefijo de intents de navegación. Los eventos del canal pueden ser
/// [navigationIntentEvent] (payload = [OmegaIntent]) o "navigate.xxx" / "navigate.push.xxx".
const String navigationIntentEvent = 'navigation.intent';

/// [OmegaNavigator] traduce intents de navegación a rutas de Flutter.
///
/// **Contrato de navegación (canal):**
/// - Evento [navigationIntentEvent] con [OmegaIntent] en el payload → [handleIntent](payload).
/// - Evento "navigate.xxx" o "navigate.push.xxx" → se construye un intent y se llama [handleIntent].
///
/// **Formato del intent ([handleIntent]):**
/// - "navigate.&lt;id&gt;" → reemplaza la pantalla actual (pushReplacement). Ej: "navigate.login".
/// - "navigate.push.&lt;id&gt;" → apila la pantalla (push). Ej: "navigate.push.detail".
/// El [intent.payload] se pasa como argumentos de la ruta ([RouteSettings.arguments]).
///
/// Debes pasar [navigatorKey] al [MaterialApp.navigatorKey].
class OmegaNavigator {
  /// Llave global para el [Navigator] de Flutter; asignar a [MaterialApp.navigatorKey].
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
  ///
  /// - "navigate.&lt;id&gt;" → pushReplacement a la ruta [id].
  /// - "navigate.push.&lt;id&gt;" → push a la ruta [id].
  /// [intent.payload] se pasa a la pantalla vía [RouteSettings.arguments].
  void handleIntent(OmegaIntent intent) {
    debugPrint("OmegaNavigator: Procesando intención -> ${intent.name}");

    if (!intent.name.startsWith("navigate.")) {
      debugPrint(
        "OmegaNavigator: Ignorando intención (no comienza con 'navigate.')",
      );
      return;
    }

    final bool usePush = intent.name.startsWith("navigate.push.");
    final String destination = usePush
        ? intent.name.replaceFirst("navigate.push.", "")
        : intent.name.replaceFirst("navigate.", "");

    if (destination.isEmpty) {
      debugPrint("OmegaNavigator ERROR: Destino vacío en '${intent.name}'.");
      return;
    }

    debugPrint("OmegaNavigator: Buscando ruta para el destino -> '$destination' (push=$usePush)");

    final entry = _routes[destination];
    if (entry == null) {
      debugPrint(
        "OmegaNavigator ERROR: No se encontró la ruta '$destination' registrada.",
      );
      debugPrint("Rutas registradas actualmente: ${_routes.keys.toList()}");
      return;
    }

    if (navigatorKey.currentState == null) {
      debugPrint(
        "OmegaNavigator ERROR: navigatorKey.currentState es NULL. Asegúrate de pasar la llave al MaterialApp.",
      );
      return;
    }

    final route = MaterialPageRoute<void>(
      builder: entry.route.builder,
      settings: RouteSettings(
        name: destination,
        arguments: intent.payload,
      ),
    );

    if (usePush) {
      debugPrint("OmegaNavigator: Push a '$destination'...");
      navigatorKey.currentState?.push(route);
    } else {
      debugPrint("OmegaNavigator: PushReplacement a '$destination'...");
      navigatorKey.currentState?.pushReplacement(route);
    }
  }
}
