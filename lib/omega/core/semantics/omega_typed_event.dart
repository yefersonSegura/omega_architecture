import 'omega_event_name.dart';

/// A strongly-typed event: the class itself carries both the event name and the payload.
///
/// Implement this interface with a class that carries your payload fields.
/// Emit with [OmegaEventBus.emitTyped] (not raw `emit` unless you wrap an [OmegaEvent] yourself):
///
/// ```dart
/// channel.emitTyped(LoginRequestedEvent(email: e, password: p));
/// ```
///
/// The channel wraps it in an [OmegaEvent] with [name] and the instance as payload.
/// Listeners use [OmegaEventTypedPayloadExtension.typedPayloadAs] or [OmegaEventPayloadExtension.payloadAs]
/// to read the same typed object:
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
