import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/events/omega_event.dart';

/// Context the flow receives in [OmegaFlow.onEvent] and [OmegaFlow.onIntent]: the triggering event or intent and [memory].
///
/// **Why use it:** In [onIntent] you read [intent] and [memory]; in [onEvent] you read [event] and [memory]. Memory persists across calls.
///
/// **Example:** `void onIntent(OmegaFlowContext ctx) { final creds = ctx.intent?.payloadAs<LoginCredentials>(); ctx.memory["pending"] = true; ... }`
class OmegaFlowContext {
  /// Event that triggered [onEvent]. Null in [onIntent].
  final OmegaEvent? event;

  /// Intent that triggered [onIntent]. Null in [onEvent].
  final OmegaIntent? intent;

  /// Flow memory. Shared between onEvent and onIntent; included in the snapshot.
  final Map<String, dynamic> memory;

  const OmegaFlowContext({this.event, this.intent, required this.memory});
}
