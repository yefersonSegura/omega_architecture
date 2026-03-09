// lib/omega/ui/navigation/omega_route.dart

import 'package:flutter/widgets.dart';

/// Defines a screen the navigator shows when the intent is "navigate.[id]" or "navigate.push.[id]".
///
/// **Why use it:** Centralize routes in one place; the flow only emits an intent with [id] and [payload].
///
/// **Example:** Normal route: `OmegaRoute(id: "login", builder: (ctx) => LoginPage());` Typed: [OmegaRoute.typed].
class OmegaRoute {
  /// Route id. Matches the destination in "navigate.[id]".
  final String id;

  /// Builds the screen. Arguments in [RouteSettings.arguments]; use [routeArguments] or [typed].
  final WidgetBuilder builder;

  const OmegaRoute({required this.id, required this.builder});

  /// Typed route: the builder receives the intent payload as [T]. Avoids casts in the screen.
  ///
  /// **Example:** `OmegaRoute.typed<LoginSuccessPayload>(id: "home", builder: (ctx, userData) => HomePage(userData: userData));`
  static OmegaRoute typed<T>({
    required String id,
    required Widget Function(BuildContext context, T? arguments) builder,
  }) {
    return OmegaRoute(
      id: id,
      builder: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as T?;
        return builder(context, args);
      },
    );
  }
}

/// Gets the current route arguments as [T]. Use when the route is not [OmegaRoute.typed].
///
/// **Example:** `final product = routeArguments<Product>(context);`
T? routeArguments<T>(BuildContext context) {
  return ModalRoute.of(context)?.settings.arguments as T?;
}
