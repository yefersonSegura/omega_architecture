// lib/omega/ui/navigation/omega_navigation_entry.dart

import 'omega_route.dart';

/// Internal entry used by [OmegaNavigator] for each registered [OmegaRoute].
class OmegaNavigationEntry {
  /// Registered route (id + builder).
  final OmegaRoute route;

  const OmegaNavigationEntry(this.route);
}
