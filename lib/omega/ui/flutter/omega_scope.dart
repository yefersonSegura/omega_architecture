// lib/omega/ui/flutter/omega_scope.dart

import 'package:flutter/widgets.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';

/// [OmegaScope] es el contenedor principal de dependencias para la UI.
/// Proporciona acceso al [OmegaChannel] y al [OmegaFlowManager] a través del árbol de widgets.
///
/// **Ciclo de vida:** Este widget no hace [OmegaChannel.dispose] ni [OmegaFlowManager.dispose].
/// Quien cree el [channel] y el [flowManager] debe llamar a sus `dispose()` al cerrar la app
/// (p. ej. en el [State.dispose] del widget que los instancia).
class OmegaScope extends InheritedWidget {
  /// El canal de eventos global.
  final OmegaChannel channel;

  /// El gestor de flujos del sistema.
  final OmegaFlowManager flowManager;

  /// Id del flow a activar al inicio, si se definió en [OmegaConfig.initialFlowId].
  /// Usar en addPostFrameCallback para llamar a [OmegaFlowManager.switchTo].
  final String? initialFlowId;

  const OmegaScope({
    super.key,
    required this.channel,
    required this.flowManager,
    this.initialFlowId,
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
    return channel != oldWidget.channel ||
        flowManager != oldWidget.flowManager ||
        initialFlowId != oldWidget.initialFlowId;
  }
}
