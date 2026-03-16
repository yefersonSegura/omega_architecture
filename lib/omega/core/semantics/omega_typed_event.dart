import 'omega_event_name.dart';

/// A strongly-typed event: the class itself carries both the event name and the payload.
///
/// Implement this interface with a class that has the data you need (e.g. [LoginRequestedEvent]
/// with `email` and `password`). You can then emit it directly:
///
/// ```dart
/// channel.emit(LoginRequestedEvent(email, password));
/// ```
///
/// The channel wraps it in an [OmegaEvent] with [name] and the instance as payload.
/// Listeners use [OmegaEvent.payloadAs] to read the same typed object:
///
/// ```dart
/// final ev = event.payloadAs<LoginRequestedEvent>();
/// if (ev != null) { ... ev.email ... ev.password ... }
/// ```
///
/// **Benefits:** autocomplete, type safety at compile time, easier refactoring, fewer bugs.
abstract interface class OmegaTypedEvent implements OmegaEventName {
  // name is provided by OmegaEventName
}
