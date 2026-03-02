// lib/omega/ui/navigation/omega_navigation_entry.dart

import 'omega_route.dart';

/// [OmegaNavigationEntry] es una entrada en el registro del navegador que envuelve una [OmegaRoute].
class OmegaNavigationEntry {
  /// La ruta asociada a esta entrada.
  final OmegaRoute route;

  const OmegaNavigationEntry(this.route);
}
