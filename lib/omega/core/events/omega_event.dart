import '../types/omega_object.dart';
import '../semantics/omega_event_name.dart';

/// Represents "something that happened" in the system, transmitted via [OmegaChannel].
///
/// **Why use it:** Agents and flows react by [name]; [payload] carries optional data.
/// This avoids coupling emitter and receiver.
///
/// **Example:** Create with typed name and read payload with type:
/// ```dart
/// channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
/// // In a listener:
/// final u = event.payloadAs<User>();
/// ```
class OmegaEvent extends OmegaObject {
  /// Event name (e.g. "auth.login.success"). Listeners filter by this value.
  final String name;

  /// Optional data. Use [payloadAs] to read with type safety.
  final dynamic payload;

  const OmegaEvent({
    required super.id,
    required this.name,
    this.payload,
    super.meta = const {},
  });

  /// Creates an event with a typed name (enum implementing [OmegaEventName]). Generates [id] if not provided.
  ///
  /// **Why use it:** Autocomplete and safe refactors; avoids typos in strings.
  factory OmegaEvent.fromName(
    OmegaEventName eventName, {
    dynamic payload,
    String? id,
    Map<String, dynamic> meta = const {},
  }) =>
      OmegaEvent(
        id: id ?? 'ev:${DateTime.now().millisecondsSinceEpoch}',
        name: eventName.name,
        payload: payload,
        meta: meta,
      );
}

/// Extension to read the payload with type safety.
extension OmegaEventPayloadExtension on OmegaEvent {
  /// Returns [payload] as [T] if the runtime value is compatible; otherwise null.
  ///
  /// **Why use it:** Avoids `payload as User` which can throw; here you get null if it doesn't match.
  /// **Example:** `final user = event.payloadAs<User>(); if (user != null) show(user.name);`
  T? payloadAs<T>() =>
      payload != null && payload is T ? payload as T : null;
}
