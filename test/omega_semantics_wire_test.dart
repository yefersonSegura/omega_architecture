import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _DottedEvent with OmegaEventNameDottedCamel implements OmegaEventName {
  authLoginSuccess,
}

void main() {
  test('omegaWireNameFromCamelCaseEnumMember splits humps', () {
    expect(omegaWireNameFromCamelCaseEnumMember('ordersCreate'), 'orders.create');
    expect(omegaWireNameFromCamelCaseEnumMember('authLogin'), 'auth.login');
    expect(
      omegaWireNameFromCamelCaseEnumMember('demoCounterIncrement'),
      'demo.counter.increment',
    );
    expect(omegaWireNameFromCamelCaseEnumMember('navigationIntent'), 'navigation.intent');
  });

  test('omegaWireNameFromCamelCaseEnumMember edge cases', () {
    expect(omegaWireNameFromCamelCaseEnumMember(''), '');
    expect(omegaWireNameFromCamelCaseEnumMember('x'), 'x');
    expect(omegaWireNameFromCamelCaseEnumMember('alphaBeta'), 'alpha.beta');
  });

  test('OmegaEventNameDottedCamel on OmegaEvent.fromName', () {
    final e = OmegaEvent.fromName(_DottedEvent.authLoginSuccess);
    expect(e.name, 'auth.login.success');
  });
}
