import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _TestIntentV implements OmegaIntentName {
  authLoginV1('auth.login.v1'),
  authLoginV2('auth.login.v2');

  const _TestIntentV(this.name);
  @override
  final String name;
}

enum _WireFromEnum with OmegaIntentNameEnumWire implements OmegaIntentName {
  alphaBeta,
}

enum _Dotted with OmegaIntentNameDottedCamel implements OmegaIntentName {
  ordersCreate,
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

  test("OmegaIntent.fromName uses typed name and generates id, with versions", () {
    final intent = OmegaIntent.fromName(_TestIntentV.authLoginV2, payload: {'x': 1});
    expect(intent.name, 'auth.login.v2');
    expect(intent.payload, {'x': 1});
    expect(intent.id.startsWith('intent:'), isTrue);
  });

  test("OmegaIntentNameEnumWire uses Enum.name", () {
    final intent = OmegaIntent.fromName(_WireFromEnum.alphaBeta);
    expect(intent.name, 'alphaBeta');
  });

  test("OmegaIntentNameDottedCamel derives dotted wire", () {
    final intent = OmegaIntent.fromName(_Dotted.ordersCreate);
    expect(intent.name, 'orders.create');
  });
}
