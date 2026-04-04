import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../agents/omega_stateful_agent.dart';

/// Builder signature that receives the state of a stateful agent.
///
/// Only [context] and [state] — there is no third `agent` parameter. Use the
/// same [OmegaAgentBuilder.agent] you passed to [OmegaAgentBuilder] (e.g. hold
/// it on the [State] or [StatefulWidget] as a field: `widget.agent`).
typedef OmegaAgentWidgetBuilder<TState> = Widget Function(
  BuildContext context,
  TState state,
);

/// Helper widget to listen to [OmegaStatefulAgent.viewState] from the UI.
///
/// It wraps the subscription to [OmegaStatefulAgent.stateStream] (alias
/// [OmegaStatefulAgent.viewStateStream]) and rebuilds
/// the subtree every time the state changes. It does **not** manage the agent
/// lifecycle; it only observes it.
class OmegaAgentBuilder<TAgent extends OmegaStatefulAgent<TState>, TState>
    extends StatefulWidget {
  const OmegaAgentBuilder({
    super.key,
    required this.agent,
    required this.builder,
  });

  final TAgent agent;
  final OmegaAgentWidgetBuilder<TState> builder;

  @override
  State<OmegaAgentBuilder<TAgent, TState>> createState() =>
      _OmegaAgentBuilderState<TAgent, TState>();
}

class _OmegaAgentBuilderState<TAgent extends OmegaStatefulAgent<TState>, TState>
    extends State<OmegaAgentBuilder<TAgent, TState>> {
  late TState _state;
  StreamSubscription<TState>? _sub;

  @override
  void initState() {
    super.initState();
    _state = widget.agent.viewState;
    _sub = widget.agent.stateStream.listen((value) {
      if (mounted) {
        setState(() => _state = value);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}