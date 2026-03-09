// lib/omega/ui/flutter/omega_scope.dart

import 'package:flutter/widgets.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';

/// Dependency container: exposes [channel] and [flowManager] to the whole UI via inheritance.
///
/// **Why use it:** Screens need the channel to emit events and the flowManager for
/// [handleIntent] and [getFlow]. By wrapping the app with OmegaScope, any child can use [OmegaScope.of].
///
/// **Example:** `OmegaScope(channel: r.channel, flowManager: r.flowManager, initialFlowId: r.initialFlowId, child: MaterialApp(...));`
class OmegaScope extends InheritedWidget {
  /// Event channel. For emitting or listening to events from the UI.
  final OmegaChannel channel;

  /// Flow manager. For handleIntent and getting the active flow (expressions).
  final OmegaFlowManager flowManager;

  /// Id of the flow to activate on startup. On first frame call flowManager.switchTo(initialFlowId).
  final String? initialFlowId;

  const OmegaScope({
    super.key,
    required this.channel,
    required this.flowManager,
    this.initialFlowId,
    required super.child,
  });

  /// Obtains the [OmegaScope] from the tree. Use in screens to access channel and flowManager.
  ///
  /// **Example:** `final scope = OmegaScope.of(context); scope.flowManager.handleIntent(intent);`
  static OmegaScope of(BuildContext context) {
    final OmegaScope? result = context
        .dependOnInheritedWidgetOfExactType<OmegaScope>();
    assert(result != null, 'OmegaScope not found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(OmegaScope oldWidget) {
    return channel != oldWidget.channel ||
        flowManager != oldWidget.flowManager ||
        initialFlowId != oldWidget.initialFlowId;
  }
}
