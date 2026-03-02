// lib/omega/ui/flutter/omega_scope.dart

import 'package:flutter/widgets.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';

/// [OmegaScope] es el contenedor principal de dependencias para la UI.
/// Proporciona acceso al [OmegaChannel] y al [OmegaFlowManager] a través del árbol de widgets.
class OmegaScope extends InheritedWidget {
  /// El canal de eventos global.
  final OmegaChannel channel;

  /// El gestor de flujos del sistema.
  final OmegaFlowManager flowManager;

  const OmegaScope({
    super.key,
    required this.channel,
    required this.flowManager,
    required super.child,
  });

  /// Permite obtener el [OmegaScope] más cercano en el árbol de widgets.
  static OmegaScope of(BuildContext context) {
    final OmegaScope? result = context
        .dependOnInheritedWidgetOfExactType<OmegaScope>();
    assert(result != null, 'No se encontró OmegaScope en el contexto');
    return result!;
  }

  @override
  bool updateShouldNotify(OmegaScope oldWidget) {
    return channel != oldWidget.channel || flowManager != oldWidget.flowManager;
  }
}
