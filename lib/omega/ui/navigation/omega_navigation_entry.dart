// lib/omega/ui/navigation/omega_navigation_entry.dart

import 'omega_route.dart';

/// [OmegaNavigationEntry] es la entrada interna del [OmegaNavigator] por cada [OmegaRoute] registrada.
class OmegaNavigationEntry {
  /// Ruta asociada (id + builder).
  final OmegaRoute route;

  const OmegaNavigationEntry(this.route);
}
