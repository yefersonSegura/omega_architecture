import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../flows/omega_flow.dart';
import '../../flows/omega_flow_expression.dart';
import 'omega_agent_scope.dart';
import 'omega_scope.dart';

/// Listens to [OmegaFlow.expressions] for [flowId] and rebuilds when a new
/// [OmegaFlowExpression] is emitted (e.g. after [OmegaFlowManager.handleIntent]).
///
/// Requires [OmegaScope] above this context. The flow must be registered and
/// usually [OmegaFlowManager.activate] / [switchTo] should have been called so
/// [OmegaFlowManager.getFlowFlexible] finds the instance.
///
/// [flowId] should match the flow’s registered id; if you use `navigate.UserInterface`
/// but the flow uses [OmegaFlowIdEnumWire] `userInterface`, ids still resolve via
/// [OmegaFlowManager.getFlowFlexible].
///
/// Uses [OmegaFlow.lastExpression] as [StreamBuilder.initialData] because the
/// expressions stream is broadcast and does not replay the last value.
///
/// When the flow overrides [OmegaFlow.uiScopeAgent], the [builder] result is wrapped in
/// [OmegaAgentScope] so [OmegaScopedAgentBuilder] works inside without wrapping the route.
class OmegaFlowExpressionBuilder extends StatelessWidget {
  const OmegaFlowExpressionBuilder({
    super.key,
    required this.flowId,
    required this.builder,
  });

  /// Same id passed to [OmegaFlow] `super(id: ...)`.
  final String flowId;

  /// Receives the latest expression from the stream (or null if flow missing).
  final Widget Function(
    BuildContext context,
    OmegaFlowExpression? expression,
  ) builder;

  Widget _maybeScope(OmegaFlow? flow, Widget child) {
    final a = flow?.uiScopeAgent;
    if (a == null) return child;
    return OmegaAgentScope(agent: a, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final fm = OmegaScope.of(context).flowManager;
    final flow = fm.getFlowFlexible(flowId);
    if (kDebugMode && flow == null) {
      debugPrint(
        'OmegaFlowExpressionBuilder: no flow for flowId="$flowId". '
        'Registered: ${fm.registeredFlowIds.toList()}. '
        'Align [flowId] with [OmegaFlow.id] (or override [OmegaFlow.uiScopeAgent] on the flow).',
      );
    }
    if (kDebugMode && flow != null && flow.uiScopeAgent == null) {
      debugPrint(
        'OmegaFlowExpressionBuilder: flow "${flow.id}" has null [OmegaFlow.uiScopeAgent]. '
        '[OmegaScopedAgentBuilder] below needs that override (or wrap with [OmegaAgentScope]).',
      );
    }
    if (flow == null) {
      return _maybeScope(null, builder(context, null));
    }
    return StreamBuilder<OmegaFlowExpression>(
      stream: flow.expressions,
      initialData: flow.lastExpression,
      builder: (context, snapshot) {
        return _maybeScope(flow, builder(context, snapshot.data));
      },
    );
  }
}
