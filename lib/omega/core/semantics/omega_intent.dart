import '../types/omega_object.dart';
import 'omega_intent_name.dart';

/// Represents a request for action (login, navigate, etc.) without coupling who asks and who executes.
///
/// **Why use it:** The UI emits intents instead of calling methods; [OmegaFlowManager]
/// routes them to flows that are running. Also used for navigation (name "navigate.xxx").
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

  const OmegaIntent({required super.id, required this.name, this.payload});

  /// Creates an intent with a typed name ([OmegaIntentName]). Generates [id] if not provided.
  ///
  /// **Why use it:** Avoids magic strings; safe refactors and autocomplete.
  factory OmegaIntent.fromName(
    OmegaIntentName intentName, {
    dynamic payload,
    String? id,
  }) =>
      OmegaIntent(
        id: id ?? 'intent:${DateTime.now().millisecondsSinceEpoch}',
        name: intentName.name,
        payload: payload,
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
