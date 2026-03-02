import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

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
}
