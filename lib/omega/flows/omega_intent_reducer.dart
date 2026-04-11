import '../core/semantics/omega_intent.dart';
import '../core/semantics/omega_intent_name.dart';
import 'omega_flow_manager.dart';

/// Holds a single value [state] updated by one or more [OmegaFlowManager] intent handlers.
///
/// Mimics a tiny reducer (`state -> intent -> newState`) without defining a full
/// [OmegaFlow]. Use [on] per intent name; typically set [consumeIntent] so flows
/// do not also see the same intent.
///
/// ```dart
/// final counter = OmegaIntentReducer<int>(0, flowManager);
/// counter.on(AppIntent.increment, (n, intent) => n + (intent.payloadAs<int>() ?? 1));
/// print(counter.state);
/// ```
final class OmegaIntentReducer<T> {
  OmegaIntentReducer(T initial, this._flowManager) : _state = initial;

  final OmegaFlowManager _flowManager;
  T _state;

  T get state => _state;

  void on(
    OmegaIntentName name,
    T Function(T previous, OmegaIntent intent) reducer, {
    bool consumeIntent = true,
  }) {
    _flowManager.registerIntentHandler(
      intentName: name.name,
      consumeIntent: consumeIntent,
      handler: (intent, ctx) {
        _state = reducer(_state, intent);
      },
    );
  }
}
