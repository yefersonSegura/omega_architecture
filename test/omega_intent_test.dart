import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _TestIntent implements OmegaIntentName {
  authLogin('auth.login'),
  goHome('navigate.home');

  const _TestIntent(this.name);
  @override
  final String name;
}

void main() {
  test("OmegaIntent stores name and payload", () {
    final intent = OmegaIntent(
      id: "123",
      name: "auth.login",
      payload: {"email": "a@b.com"},
    );

    expect(intent.name, "auth.login");
    expect(intent.payload["email"], "a@b.com");
  });

  test("OmegaIntent.fromName uses typed name and generates id", () {
    final intent = OmegaIntent.fromName(_TestIntent.authLogin, payload: {'x': 1});
    expect(intent.name, 'auth.login');
    expect(intent.payload, {'x': 1});
    expect(intent.id.startsWith('intent:'), isTrue);
  });
}
