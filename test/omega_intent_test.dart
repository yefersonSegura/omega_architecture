import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  test("OmegaIntent stores action and data", () {
    final intent = OmegaIntent(
      id: "123",
      action: "auth.login",
      data: {"email": "a@b.com"},
    );

    expect(intent.action, "auth.login");
    expect(intent.data["email"], "a@b.com");
  });
}
