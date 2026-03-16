import 'dart:async';
import '../events/omega_event.dart';
import '../semantics/omega_typed_event.dart';

/// Abstraction for emitting and listening to events. Implemented by [OmegaChannel]
/// and [OmegaChannelNamespace], so flows and agents can use either the global channel
/// or a namespaced view.
abstract class OmegaEventBus {
  /// Publishes [event]. On a namespace view, the event is tagged with that namespace.
  void emit(OmegaEvent event);

  /// Publishes a typed event. The instance is used as payload and [event.name] as the event name.
  /// Use this for type-safe events: `channel.emitTyped(LoginRequestedEvent(email, password));`
  void emitTyped(OmegaTypedEvent event);

  /// Event stream. On a namespace view, only global and that namespace's events are emitted.
  Stream<OmegaEvent> get events;
}

/// Central event bus: all communication between agents, flows and UI goes through it.
///
/// **Why use it:** Decouples who emits from who listens. The UI does not call
/// agent methods; it emits events. Flows and agents react without knowing the UI.
///
/// **Namespaces:** Use [namespace] to scope events (e.g. "auth", "checkout") so modules
/// do not collide. [events] receives all events; [namespace](id).events receives only
/// global events and events in that namespace.
///
/// **Example:** Emit and listen (global), or use a typed event class:
/// ```dart
/// channel.emit(OmegaEvent(id: "1", name: "auth.login.request", payload: creds));
/// // Or use a typed event (recommended): channel.emit(LoginRequestedEvent(email, password));
/// channel.events.listen((e) => print(e.name));
/// channel.namespace('auth').emit(OmegaEvent(...));
/// channel.namespace('auth').events.listen((e) => ...);
/// ```
///
/// **Lifecycle:** Whoever creates the channel must call [dispose] when the app closes.
class OmegaChannel implements OmegaEventBus {
  final _controller = StreamController<OmegaEvent>.broadcast();

  /// Optional callback when emit fails (e.g. channel already closed).
  final void Function(Object error, StackTrace? stackTrace)? onEmitError;

  OmegaChannel({this.onEmitError});

  /// Event stream. Subscribe to react to what happens in the system.
  /// Receives all events (global and namespaced). For scoped listening use [namespace].
  ///
  /// **Example:** `channel.events.listen((e) { if (e.name == "user.updated") refresh(); });`
  Stream<OmegaEvent> get events => _controller.stream;

  /// Returns a view of the channel scoped to [name]. Events emitted via this view
  /// get [name] as [OmegaEvent.namespace]. [events] on the view only emits global
  /// events (namespace == null) and events in this namespace.
  ///
  /// **Why use it:** In large apps or with [OmegaModule], namespaces avoid name
  /// collisions (e.g. "auth.loading" vs "checkout.loading") and keep module boundaries clear.
  OmegaChannelNamespace namespace(String name) => OmegaChannelNamespace(this, name);

  /// Publishes [event] on the channel. All [events] subscribers receive it.
  /// If [event.namespace] is set, only subscribers to that namespace (or the global stream) receive it.
  ///
  /// **Why use it:** To notify that "something happened" (login, error, navigation) without
  /// coupling emitter and receiver. If the channel is closed, [onEmitError] is called.
  @override
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

  @override
  void emitTyped(OmegaTypedEvent event) {
    emit(OmegaEvent(
      id: 'ev:${DateTime.now().millisecondsSinceEpoch}',
      name: event.name,
      payload: event,
    ));
  }

  /// Closes the channel and releases resources. Call when closing the app to avoid leaks.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}

/// View of [OmegaChannel] scoped to a namespace. Use [OmegaChannel.namespace] to obtain.
///
/// **Emit:** Events emitted via [emit] are published with [namespace] set, so only
/// listeners to this namespace (or the global [OmegaChannel.events] stream) receive them.
///
/// **Listen:** [events] returns a stream that emits only global events (no namespace)
/// and events whose namespace equals this one.
class OmegaChannelNamespace implements OmegaEventBus {
  /// The underlying channel.
  final OmegaChannel channel;

  /// The namespace name (e.g. "auth", "checkout").
  final String namespace;

  OmegaChannelNamespace(this.channel, this.namespace);

  @override
  void emit(OmegaEvent event) {
    final tagged = OmegaEvent(
      id: event.id,
      name: event.name,
      payload: event.payload,
      meta: event.meta,
      namespace: namespace,
    );
    channel.emit(tagged);
  }

  @override
  void emitTyped(OmegaTypedEvent event) {
    final inner = OmegaEvent(
      id: 'ev:${DateTime.now().millisecondsSinceEpoch}',
      name: event.name,
      payload: event,
    );
    emit(inner);
  }

  /// Event stream filtered to global events and events in this namespace.
  /// Use this so a module only reacts to its own and global events.
  Stream<OmegaEvent> get events => channel.events.where((e) {
        final ns = e.namespace;
        return ns == null || ns == namespace;
      });
}
