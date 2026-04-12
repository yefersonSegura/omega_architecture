import '../types/omega_object.dart';
import 'omega_intent_name.dart';

/// Represents a request for action (login, navigate, etc.) without coupling who asks and who executes.
///
/// **Why use it:** The UI emits intents instead of calling methods; [OmegaFlowManager]
/// routes them to flows that are running. Optional [namespace] scopes intents (e.g. for modules).
///
/// **Example:** Emit from UI and read payload in the flow:
/// ```dart
/// flowManager.handleIntent(OmegaIntent.fromName(AppIntent.authLogin, payload: creds));
/// // In flow onIntent: final c = ctx.intent!.payloadAs<LoginCredentials>();
/// ```
class OmegaIntent extends OmegaObject {
  /// Intent name (e.g. "auth.login", "navigate.home"). Defines the action.
  final String name;

  /// Data to execute the action. Use [payloadAs] to read with type.
  final dynamic payload;

  /// Optional namespace (e.g. "auth", "checkout"). Can be used by the host to route to the right module.
  final String? namespace;

  /// Prefer [OmegaIntent.fromName] when you have an [OmegaIntentName] — it supplies [id] when omitted.
  const OmegaIntent({
    required super.id,
    required this.name,
    this.payload,
    this.namespace,
  });

  /// Creates an intent with a typed name ([OmegaIntentName]). Generates [id] if not provided.
  ///
  /// **Why use it:** Avoids magic strings; safe refactors and autocomplete.
  ///
  /// **First argument [intentName]:** the **enum value** (e.g. `AppIntent.navigateLogin`),
  /// not a string and not `AppIntent.navigateLogin.name`. Optional **[payload]:** any
  /// object; use [OmegaIntentPayloadExtension.payloadAs] in flows. Pairs with
  /// [OmegaEvent.fromName] when the same DTO is re-emitted on the channel.
  factory OmegaIntent.fromName(
    OmegaIntentName intentName, {
    dynamic payload,
    String? id,
    String? namespace,
  }) =>
      OmegaIntent(
        id: id ?? 'intent:${DateTime.now().millisecondsSinceEpoch}',
        name: intentName.name,
        payload: payload,
        namespace: namespace,
      );
}

/// Extension to read the payload with type safety.
extension OmegaIntentPayloadExtension on OmegaIntent {
  /// Returns [payload] as [T] if compatible at runtime; otherwise null.
  ///
  /// **Example:** `final creds = intent.payloadAs<LoginCredentials>(); if (creds != null) ...`
  T? payloadAs<T>() =>
      payload != null && payload is T ? payload as T : null;
}
