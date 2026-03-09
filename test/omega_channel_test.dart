import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _TestEvent implements OmegaEventName {
  testEvent('test.event'),
  other('other');

  const _TestEvent(this.name);
  @override
  final String name;
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
}
