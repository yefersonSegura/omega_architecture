import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _TestEvent implements OmegaEventName {
  testEvent('test.event'),
  other('other');

  const _TestEvent(this.name);
  @override
  final String name;
}

class _TestTypedEvent implements OmegaTypedEvent {
  _TestTypedEvent(this.value);
  final int value;
  @override
  String get name => 'test.typed';
}

void main() {
  test("OmegaChannel should emit and listen events", () async {
    final channel = OmegaChannel();
    final event = OmegaEvent(id: "1", name: "test.event", payload: "hello");

    late OmegaEvent received;

    channel.events.listen((e) => received = e);

    channel.emit(event);

    await Future.delayed(Duration(milliseconds: 10));

    expect(received.name, "test.event");
    expect(received.payload, "hello");

    channel.dispose();
  });

  test("OmegaChannel emit after dispose does not throw and calls onEmitError", () {
    Object? capturedError;
    final channel = OmegaChannel(
      onEmitError: (e, _) => capturedError = e,
    );
    channel.dispose();

    channel.emit(OmegaEvent(id: "1", name: "late", payload: null));

    expect(capturedError, isNotNull);
  });

  test("OmegaChannel dispose is idempotent", () {
    final channel = OmegaChannel();
    channel.dispose();
    channel.dispose(); // no throw
  });

  test("OmegaEvent.fromName uses typed name and generates id", () {
    final event = OmegaEvent.fromName(_TestEvent.testEvent, payload: 'data');
    expect(event.name, 'test.event');
    expect(event.payload, 'data');
    expect(event.id.startsWith('ev:'), isTrue);
  });

  test("OmegaEvent.payloadAs returns typed payload when type matches", () {
    final event = OmegaEvent(id: '1', name: 'x', payload: 42);
    expect(event.payloadAs<int>(), 42);
    expect(event.payloadAs<String>(), isNull);
  });

  test("OmegaChannelNamespace emit tags event with namespace", () async {
    final channel = OmegaChannel();
    final authNs = channel.namespace('auth');
    OmegaEvent? received;
    authNs.events.listen((e) => received = e);

    authNs.emit(OmegaEvent(id: '1', name: 'auth.login', payload: null));

    await Future.delayed(Duration(milliseconds: 10));
    expect(received, isNotNull);
    expect(received!.namespace, 'auth');
    expect(received!.name, 'auth.login');
    channel.dispose();
  });

  test("OmegaChannel emitTyped wraps typed event and listener receives it", () async {
    final channel = OmegaChannel();
    OmegaEvent? received;
    channel.events.listen((e) => received = e);

    channel.emitTyped(_TestTypedEvent(42));

    await Future.delayed(Duration(milliseconds: 10));
    expect(received, isNotNull);
    expect(received!.name, 'test.typed');
    expect(received!.payload, isA<_TestTypedEvent>());
    expect((received!.payload as _TestTypedEvent).value, 42);
    expect(received!.payloadAs<_TestTypedEvent>()?.value, 42);
    channel.dispose();
  });

  test("OmegaChannelNamespace emitTyped tags typed event with namespace", () async {
    final channel = OmegaChannel();
    final authNs = channel.namespace('auth');
    OmegaEvent? received;
    authNs.events.listen((e) => received = e);

    authNs.emitTyped(_TestTypedEvent(1));

    await Future.delayed(Duration(milliseconds: 10));
    expect(received, isNotNull);
    expect(received!.name, 'test.typed');
    expect(received!.namespace, 'auth');
    expect(received!.payloadAs<_TestTypedEvent>()?.value, 1);
    channel.dispose();
  });

  test("OmegaChannelNamespace events only receives global and same-namespace events", () async {
    final channel = OmegaChannel();
    final authNs = channel.namespace('auth');
    final checkoutNs = channel.namespace('checkout');
    final authReceived = <OmegaEvent>[];
    final checkoutReceived = <OmegaEvent>[];
    authNs.events.listen(authReceived.add);
    checkoutNs.events.listen(checkoutReceived.add);

    channel.emit(OmegaEvent(id: '1', name: 'global', payload: null));
    authNs.emit(OmegaEvent(id: '2', name: 'auth.login', payload: null));
    checkoutNs.emit(OmegaEvent(id: '3', name: 'checkout.step', payload: null));

    await Future.delayed(Duration(milliseconds: 50));

    expect(authReceived.length, 2);
    expect(authReceived.any((e) => e.name == 'global' && e.namespace == null), isTrue);
    expect(authReceived.any((e) => e.name == 'auth.login' && e.namespace == 'auth'), isTrue);
    expect(authReceived.any((e) => e.name == 'checkout.step'), isFalse);

    expect(checkoutReceived.length, 2);
    expect(checkoutReceived.any((e) => e.name == 'global' && e.namespace == null), isTrue);
    expect(checkoutReceived.any((e) => e.name == 'checkout.step' && e.namespace == 'checkout'), isTrue);
    expect(checkoutReceived.any((e) => e.name == 'auth.login'), isFalse);

    channel.dispose();
  });
}
