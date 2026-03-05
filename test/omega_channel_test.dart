import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

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
}
