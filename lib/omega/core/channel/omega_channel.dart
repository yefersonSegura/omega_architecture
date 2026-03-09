import 'dart:async';
import '../events/omega_event.dart';

/// Central event bus: all communication between agents, flows and UI goes through it.
///
/// **Why use it:** Decouples who emits from who listens. The UI does not call
/// agent methods; it emits events. Flows and agents react without knowing the UI.
///
/// **Example:** Emit an event and listen:
/// ```dart
/// channel.emit(OmegaEvent(id: "1", name: "auth.login.request", payload: creds));
/// channel.events.listen((e) => print(e.name));
/// ```
///
/// **Lifecycle:** Whoever creates the channel must call [dispose] when the app closes.
class OmegaChannel {
  final _controller = StreamController<OmegaEvent>.broadcast();

  /// Optional callback when emit fails (e.g. channel already closed).
  final void Function(Object error, StackTrace? stackTrace)? onEmitError;

  OmegaChannel({this.onEmitError});

  /// Event stream. Subscribe to react to what happens in the system.
  ///
  /// **Example:** `channel.events.listen((e) { if (e.name == "user.updated") refresh(); });`
  Stream<OmegaEvent> get events => _controller.stream;

  /// Publishes [event] on the channel. All [events] subscribers receive it.
  ///
  /// **Why use it:** To notify that "something happened" (login, error, navigation) without
  /// coupling emitter and receiver. If the channel is closed, [onEmitError] is called.
  void emit(OmegaEvent event) {
    if (_controller.isClosed) {
      onEmitError?.call(
        StateError('OmegaChannel is disposed, cannot emit'),
        StackTrace.current,
      );
      return;
    }
    try {
      _controller.add(event);
    } catch (e, st) {
      if (!_controller.isClosed) {
        _controller.addError(e, st);
      }
      onEmitError?.call(e, st);
    }
  }

  /// Closes the channel and releases resources. Call when closing the app to avoid leaks.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
