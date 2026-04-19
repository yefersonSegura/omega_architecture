// lib/omega/ui/navigation/omega_navigator.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/semantics/omega_intent.dart';
import 'omega_route.dart';
import 'omega_navigation_entry.dart';

/// Navigation intent prefix. Channel events can be
/// [navigationIntentEvent] (payload = [OmegaIntent]) or "navigate.xxx" / "navigate.push.xxx".
const String navigationIntentEvent = 'navigation.intent';

const String _kNavigatePrefix = 'navigate.';
const String _kNavigatePushPrefix = 'navigate.push.';

/// **iOS:** [CupertinoPageRoute] (slide + swipe-back). **Android & others:** [MaterialPageRoute]
/// (Material transitions, predictive back on Android). Web/desktop use Material.
PageRoute<void> _omegaAdaptivePageRoute({
  required WidgetBuilder builder,
  required RouteSettings settings,
}) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<void>(
      builder: builder,
      settings: settings,
    );
  }
  return MaterialPageRoute<void>(
    builder: builder,
    settings: settings,
  );
}

/// Converts navigation intents ("navigate.xxx", "navigate.push.xxx") into Flutter push/pushReplacement.
///
/// **Why use it:** Flows navigate by emitting events; they don't have BuildContext. The channel emits
/// "navigation.intent" or "navigate.home"; the manager calls [handleIntent] and this shows the screen.
///
/// **Example:** In the flow: `channel.emit(OmegaEvent(..., name: "navigation.intent", payload: OmegaIntent.fromName(AppIntent.navigateHome, payload: user)));`
///
/// [navigatorKey] must be assigned to [MaterialApp.navigatorKey]. [intent.payload] is passed as [RouteSettings.arguments].
///
/// Page transitions are platform-adaptive (Cupertino on iOS, Material on Android and elsewhere).
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
    assert(() {
      debugPrint('OmegaNavigator: Processing intent -> ${intent.name}');
      return true;
    }());

    final name = intent.name;
    if (!name.startsWith(_kNavigatePrefix)) {
      assert(() {
        debugPrint(
          "OmegaNavigator: Ignoring intent (does not start with 'navigate.')",
        );
        return true;
      }());
      return;
    }

    final bool usePush = name.startsWith(_kNavigatePushPrefix);
    final String destination = usePush
        ? name.substring(_kNavigatePushPrefix.length)
        : name.substring(_kNavigatePrefix.length);

    if (destination.isEmpty) {
      assert(() {
        debugPrint("OmegaNavigator ERROR: Empty destination in '$name'.");
        return true;
      }());
      return;
    }

    assert(() {
      debugPrint(
        "OmegaNavigator: Looking up route for destination -> '$destination' (push=$usePush)",
      );
      return true;
    }());

    final entry = _routes[destination];
    if (entry == null) {
      assert(() {
        debugPrint(
          "OmegaNavigator ERROR: Route '$destination' not found.",
        );
        debugPrint('Currently registered routes: ${_routes.keys.toList()}');
        return true;
      }());
      return;
    }

    final nav = navigatorKey.currentState;
    if (nav == null) {
      assert(() {
        debugPrint(
          'OmegaNavigator ERROR: navigatorKey.currentState is NULL. Make sure to pass the key to MaterialApp.',
        );
        return true;
      }());
      return;
    }

    final route = _omegaAdaptivePageRoute(
      builder: entry.route.builder,
      settings: RouteSettings(
        name: destination,
        arguments: intent.payload,
      ),
    );

    assert(() {
      debugPrint(
        usePush
            ? "OmegaNavigator: Pushing to '$destination'..."
            : "OmegaNavigator: PushReplacement to '$destination'...",
      );
      return true;
    }());

    if (usePush) {
      nav.push(route);
    } else {
      nav.pushReplacement(route);
    }
  }

  /// Implementation for [MaterialApp.onGenerateRoute].
  /// This allows using standard Navigator API (Navigator.pushNamed) with Omega routes.
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null) return null;

    final entry = _routes[name];
    if (entry == null) {
      assert(() {
        debugPrint(
          "OmegaNavigator ERROR: Route '$name' not found in onGenerateRoute.",
        );
        return true;
      }());
      return null;
    }

    return _omegaAdaptivePageRoute(
      builder: entry.route.builder,
      settings: settings,
    );
  }
}
