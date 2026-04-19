import 'package:flutter/widgets.dart';

import '../../agents/omega_agent.dart';

/// Provides an [OmegaAgent] to descendants without passing it through every
/// constructor. Wrap a route (or subtree) in [omega_setup.dart]:
///
/// ```dart
/// OmegaRoute(
///   id: 'shop',
///   builder: (context) => OmegaAgentScope(
///     agent: cartAgent,
///     child: const ShopDemoPage(),
///   ),
/// )
/// ```
///
/// Children that need the agent use [omegaAgentAs] / [maybeOmegaAgentAs].
/// For [OmegaStatefulAgent] view state, prefer [OmegaScopedAgentBuilder].
class OmegaAgentScope extends InheritedWidget {
  /// Agent instance shared by this subtree (typically one per scope).
  final OmegaAgent agent;

  const OmegaAgentScope({
    super.key,
    required this.agent,
    required super.child,
  });

  /// Nearest [OmegaAgentScope]'s agent (must not be null).
  static OmegaAgent omegaAgentOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OmegaAgentScope>();
    assert(
      scope != null,
      'OmegaAgentScope not found above this context. '
      'If you use OmegaScopedAgentBuilder under OmegaFlowExpressionBuilder, override '
      'OmegaFlow.uiScopeAgent on your flow (same agent instance), or wrap the route with '
      'OmegaAgentScope in omega_setup. See web docs: OmegaFlowExpressionBuilder.',
    );
    return scope!.agent;
  }

  /// Cast the scoped agent to [T]. Throws if the agent is not a [T].
  static T omegaAgentAs<T extends OmegaAgent>(BuildContext context) {
    final a = omegaAgentOf(context);
    if (a is! T) {
      throw FlutterError(
        'OmegaAgentScope: expected agent of type $T, got ${a.runtimeType}.',
      );
    }
    return a;
  }

  /// Like [omegaAgentAs] but returns null if missing or wrong type.
  ///
  /// Does not register a dependency (uses [findAncestorWidgetOfExactType]).
  static T? maybeOmegaAgentAs<T extends OmegaAgent>(BuildContext context) {
    final scope = context.findAncestorWidgetOfExactType<OmegaAgentScope>();
    if (scope == null) return null;
    final a = scope.agent;
    return a is T ? a : null;
  }

  @override
  bool updateShouldNotify(OmegaAgentScope oldWidget) {
    return agent != oldWidget.agent;
  }
}
