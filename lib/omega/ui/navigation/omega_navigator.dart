// lib/omega/ui/navigation/omega_navigator.dart

import 'package:flutter/material.dart';

import '../../core/semantics/omega_intent.dart';
import 'omega_route.dart';
import 'omega_navigation_entry.dart';

/// Navigation intent prefix. Channel events can be
/// [navigationIntentEvent] (payload = [OmegaIntent]) or "navigate.xxx" / "navigate.push.xxx".
const String navigationIntentEvent = 'navigation.intent';

/// Converts navigation intents ("navigate.xxx", "navigate.push.xxx") into Flutter push/pushReplacement.
///
/// **Why use it:** Flows navigate by emitting events; they don't have BuildContext. The channel emits
/// "navigation.intent" or "navigate.home"; the manager calls [handleIntent] and this shows the screen.
///
/// **Example:** In the flow: `channel.emit(OmegaEvent(..., name: "navigation.intent", payload: OmegaIntent.fromName(AppIntent.navigateHome, payload: user)));`
///
/// [navigatorKey] must be assigned to [MaterialApp.navigatorKey]. [intent.payload] is passed as [RouteSettings.arguments].
class OmegaNavigator {
  /// Navigator key. Assign to [MaterialApp.navigatorKey].
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, OmegaNavigationEntry> _routes = {};

  // -----------------------------------------------------------
  // 1. Register routes (screens)
  // -----------------------------------------------------------
  /// Registers a screen. [route.id] is the destination in "navigate.{id}" or "navigate.push.{id}".
  ///
  /// **Example:** `navigator.registerRoute(OmegaRoute.typed<User>(id: "home", builder: (ctx, user) => HomePage(user)));`
  void registerRoute(OmegaRoute route) {
    _routes[route.id] = OmegaNavigationEntry(route);
  }

  // -----------------------------------------------------------
  // 2. Process navigation intent
  // -----------------------------------------------------------
  /// Performs navigation: "navigate.id" → pushReplacement; "navigate.push.id" → push. [intent.payload] → arguments.
  void handleIntent(OmegaIntent intent) {
    debugPrint("OmegaNavigator: Processing intent -> ${intent.name}");

    if (!intent.name.startsWith("navigate.")) {
      debugPrint(
        "OmegaNavigator: Ignoring intent (does not start with 'navigate.')",
      );
      return;
    }

    final bool usePush = intent.name.startsWith("navigate.push.");
    final String destination = usePush
        ? intent.name.replaceFirst("navigate.push.", "")
        : intent.name.replaceFirst("navigate.", "");

    if (destination.isEmpty) {
      debugPrint("OmegaNavigator ERROR: Empty destination in '${intent.name}'.");
      return;
    }

    debugPrint("OmegaNavigator: Looking up route for destination -> '$destination' (push=$usePush)");

    final entry = _routes[destination];
    if (entry == null) {
      debugPrint(
        "OmegaNavigator ERROR: Route '$destination' not found.",
      );
      debugPrint("Currently registered routes: ${_routes.keys.toList()}");
      return;
    }

    if (navigatorKey.currentState == null) {
      debugPrint(
        "OmegaNavigator ERROR: navigatorKey.currentState is NULL. Make sure to pass the key to MaterialApp.",
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
      debugPrint("OmegaNavigator: Pushing to '$destination'...");
      navigatorKey.currentState?.push(route);
    } else {
      debugPrint("OmegaNavigator: PushReplacement to '$destination'...");
      navigatorKey.currentState?.pushReplacement(route);
    }
  }
}
