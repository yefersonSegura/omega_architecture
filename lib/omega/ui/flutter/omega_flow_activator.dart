import 'package:flutter/widgets.dart';

import '../../core/semantics/omega_flow_id.dart';
import '../../flows/omega_flow_manager.dart';
import 'omega_scope.dart';

String _omegaFlowActivatorResolveId(Object flowId) {
  if (flowId is String) return flowId;
  if (flowId is OmegaFlowId) return flowId.id;
  throw ArgumentError.value(
    flowId,
    'flowId',
    'Expected String or OmegaFlowId (e.g. enum with OmegaFlowIdEnumWire)',
  );
}

/// Calls [OmegaFlowManager.activate] or [OmegaFlowManager.switchTo] once when this
/// widget's [Element] gets dependencies — so screens do not hand-roll
/// `OmegaScope.of(context).flowManager.activate(...)` in [didChangeDependencies].
///
/// [flowId] may be a **raw** [String] (legacy) or any [OmegaFlowId] (e.g. an enum
/// with [OmegaFlowIdEnumWire]) — same pattern as [OmegaIntent.fromName] with typed names.
///
/// Wrap the body of a route that **owns** a flow. Prefer [useSwitchTo] when this screen
/// should be the only running flow; use default [activate] when several flows may run together.
///
/// ```dart
/// return OmegaFlowActivator(
///   flowId: AppFlowId.authFlow,
///   child: Scaffold(...),
/// );
/// ```
class OmegaFlowActivator extends StatefulWidget {
  const OmegaFlowActivator({
    super.key,
    required this.flowId,
    required this.child,
    this.useSwitchTo = false,
  });

  /// Registered flow id: [String] or [OmegaFlowId] (e.g. `AppFlowId.authFlow`).
  final Object flowId;

  /// When `true`, calls [OmegaFlowManager.switchTo]; otherwise [OmegaFlowManager.activate].
  final bool useSwitchTo;

  final Widget child;

  @override
  State<OmegaFlowActivator> createState() => _OmegaFlowActivatorState();
}

class _OmegaFlowActivatorState extends State<OmegaFlowActivator> {
  bool _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_applied) return;
    _applied = true;
    final OmegaFlowManager fm = OmegaScope.of(context).flowManager;
    final id = _omegaFlowActivatorResolveId(widget.flowId);
    if (widget.useSwitchTo) {
      fm.switchTo(id);
    } else {
      fm.activate(id);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
