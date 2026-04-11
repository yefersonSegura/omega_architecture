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
/// [getFlow] returns the instance.
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
    final flow = OmegaScope.of(context).flowManager.getFlow(flowId);
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
