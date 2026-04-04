import '../types/omega_object.dart';
import '../semantics/omega_event_name.dart';

/// Represents "something that happened" in the system, transmitted via [OmegaChannel].
///
/// **Why use it:** Agents and flows react by [name]; [payload] carries optional data.
/// Use optional [namespace] to scope events (e.g. "auth", "checkout") so modules do not collide.
///
/// **Example:** Create with typed name and read payload with type:
/// ```dart
/// channel.emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
/// // With namespace (e.g. from channel.namespace('auth')):
/// channel.namespace('auth').emit(OmegaEvent.fromName(AppEvent.authLoginSuccess, payload: user));
/// ```
class OmegaEvent extends OmegaObject {
  /// Event name (e.g. "auth.login.success"). Listeners filter by this value.
  final String name;

  /// Optional data. Use [payloadAs] to read with type safety.
  final dynamic payload;

  /// Optional namespace (e.g. "auth", "checkout"). When set, only listeners subscribed to
  /// that namespace (or the global stream) receive it. When null, event is global.
  final String? namespace;

  /// Prefer [OmegaEvent.fromName] when you have an [OmegaEventName] — it supplies [id] when omitted.
  const OmegaEvent({
    required super.id,
    required this.name,
    this.payload,
    super.meta = const {},
    this.namespace,
  });

  /// Creates an event with a typed name (enum implementing [OmegaEventName]). Generates [id] if not provided.
  ///
  /// **Why use it:** Autocomplete and safe refactors; avoids typos in strings.
  factory OmegaEvent.fromName(
    OmegaEventName eventName, {
    dynamic payload,
    String? id,
    String? namespace,
    Map<String, dynamic> meta = const {},
  }) =>
      OmegaEvent(
        id: id ?? 'ev:${DateTime.now().millisecondsSinceEpoch}',
        name: eventName.name,
        payload: payload,
        namespace: namespace,
        meta: meta,
      );

  /// Serializes this event to a JSON-friendly map (e.g. for [OmegaRecordedSession] trace files).
  /// [payload] and [meta] should be JSON-serializable when persisting.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (payload != null) 'payload': payload,
        if (namespace != null) 'namespace': namespace,
        if (meta.isNotEmpty) 'meta': Map<String, dynamic>.from(meta),
      };

  /// Creates an event from a map (e.g. from a trace file). [payload] and [meta] are read as-is.
  static OmegaEvent fromJson(Map<String, dynamic> json) => OmegaEvent(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        payload: json['payload'],
        namespace: json['namespace'] as String?,
        meta: json['meta'] is Map
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : const {},
      );
}

/// Extension to read the payload with type safety.
extension OmegaEventPayloadExtension on OmegaEvent {
  /// Returns [payload] as [T] if the runtime value is compatible; otherwise null.
  ///
  /// **Why use it:** Avoids `payload as User` which can throw; here you get null if it doesn't match.
  /// **Example:** `final user = event.payloadAs<User>(); if (user != null) show(user.name);`
  T? payloadAs<T>() => payload != null && payload is T ? payload as T : null;
}
