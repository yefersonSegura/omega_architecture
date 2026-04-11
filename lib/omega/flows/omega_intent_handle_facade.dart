import '../core/semantics/omega_intent_name.dart';
import 'omega_flow_manager.dart';
import 'omega_intent_handler_context.dart';

/// Shortcuts for registering lightweight intent handlers on [OmegaFlowManager].
///
/// Prefer full [OmegaFlow] + contracts for non-trivial journeys; use [Omega.handle]
/// when a single callback per intent is enough and you want less boilerplate.
final class Omega {
  Omega._();

  /// Registers [handler] for intents whose name matches [intentName.name].
  ///
  /// Equivalent to [OmegaFlowManager.registerIntentHandler]. See [consumeIntent]
  /// there: when `true`, running flows will not receive this intent.
  static void handle(
    OmegaFlowManager flowManager,
    OmegaIntentName intentName,
    OmegaIntentHandler handler, {
    bool consumeIntent = false,
  }) {
    flowManager.registerIntentHandler(
      intentName: intentName.name,
      handler: handler,
      consumeIntent: consumeIntent,
    );
  }
}
