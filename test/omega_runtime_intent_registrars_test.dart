import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  test('OmegaRuntime.bootstrap invokes intentHandlerRegistrars after wireNavigator', () {
    var calls = 0;
    OmegaChannel? passedChannel;

    final runtime = OmegaRuntime.bootstrap(
      (channel) => OmegaConfig(
        intentHandlerRegistrars: [
          (flowManager, ch) {
            calls++;
            passedChannel = ch;
            expect(flowManager, isNotNull);
            expect(identical(ch, channel), isTrue);
          },
        ],
      ),
    );

    expect(calls, 1);
    expect(identical(passedChannel, runtime.channel), isTrue);

    runtime.channel.dispose();
  });
}
