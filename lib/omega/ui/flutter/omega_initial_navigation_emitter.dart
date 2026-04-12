import 'package:flutter/widgets.dart';

import '../../core/events/omega_event.dart';
import '../../core/semantics/omega_intent.dart';
import '../navigation/omega_navigator.dart';
import 'omega_scope.dart';

/// After the first frame, emits [navigationIntentEvent] once with [intent] on
/// [OmegaScope]'s channel so [OmegaNavigator] can push/replace the matching route.
///
/// Prefer **[OmegaInitialRoute]** when the intent is already on [OmegaScope.initialNavigationIntent]
/// (typical: set in [OmegaConfig] / pass through [OmegaScope] — no extra constructor args).
///
/// Place this **under** [MaterialApp] (e.g. as [MaterialApp.home]'s parent or root
/// of `home`) so [MaterialApp.navigatorKey] is attached when the callback runs.
class OmegaInitialNavigationEmitter extends StatefulWidget {
  const OmegaInitialNavigationEmitter({
    super.key,
    required this.intent,
    required this.child,
  });

  /// Must be a navigation intent (`navigate.*` / `navigate.push.*` wire).
  final OmegaIntent intent;

  final Widget child;

  @override
  State<OmegaInitialNavigationEmitter> createState() =>
      _OmegaInitialNavigationEmitterState();
}

class _OmegaInitialNavigationEmitterState
    extends State<OmegaInitialNavigationEmitter> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_emitOnce);
  }

  void _emitOnce(_) {
    if (!mounted || _done) return;
    _done = true;
    OmegaScope.of(context).channel.emit(
      OmegaEvent(
        id: 'omega:initialNavigation',
        name: navigationIntentEvent,
        payload: widget.intent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Wraps [MaterialApp.home] (or the route subtree root) so the first Omega screen opens
/// without threading the intent through your root widget.
///
/// Resolves the navigation intent as **`intent` argument** if non-null, otherwise
/// [OmegaScope.initialNavigationIntent] (set [OmegaScope] with
/// `initialNavigationIntent: runtime.initialNavigationIntent` next to `initialFlowId`).
/// If both are null, this widget only builds [child] (no emit).
///
/// ```dart
/// OmegaScope(
///   channel: runtime.channel,
///   flowManager: runtime.flowManager,
///   initialFlowId: runtime.initialFlowId,
///   initialNavigationIntent: runtime.initialNavigationIntent,
///   child: MaterialApp(
///     navigatorKey: runtime.navigator.navigatorKey,
///     home: OmegaInitialRoute(child: const _Root()),
///   ),
/// );
/// ```
class OmegaInitialRoute extends StatefulWidget {
  const OmegaInitialRoute({super.key, required this.child, this.intent});

  /// If null, uses [OmegaScope.initialNavigationIntent].
  final OmegaIntent? intent;

  final Widget child;

  @override
  State<OmegaInitialRoute> createState() => _OmegaInitialRouteState();
}

class _OmegaInitialRouteState extends State<OmegaInitialRoute> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_emitOnce);
  }

  void _emitOnce(_) {
    if (!mounted || _done) return;
    _done = true;
    final resolved = widget.intent ?? OmegaScope.of(context).initialNavigationIntent;
    if (resolved == null) return;
    OmegaScope.of(context).channel.emit(
      OmegaEvent(
        id: 'omega:initialNavigation',
        name: navigationIntentEvent,
        payload: resolved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
