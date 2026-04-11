import '../core/channel/omega_channel.dart';
import '../core/semantics/omega_intent.dart';

/// Context passed to lightweight [OmegaFlowManager.registerIntentHandler] callbacks.
///
/// Use [intent.payloadAs] to read typed payloads. Use [channel] to emit follow-up
/// events (`emit` / `emitTyped`) or delegate to agents indirectly.
class OmegaIntentHandlerContext {
  const OmegaIntentHandlerContext({
    required this.channel,
    required this.intent,
  });

  /// Same bus the [OmegaFlowManager] was constructed with (often [OmegaChannel]).
  final OmegaEventBus channel;

  /// The intent currently being handled.
  final OmegaIntent intent;
}

/// Lightweight handler invoked before intents are delivered to running [OmegaFlow]s.
typedef OmegaIntentHandler =
    void Function(OmegaIntent intent, OmegaIntentHandlerContext context);
