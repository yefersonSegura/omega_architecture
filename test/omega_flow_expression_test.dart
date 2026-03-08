import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  test("OmegaFlowExpression stores type and payload", () {
    const exp = OmegaFlowExpression("success", payload: {"id": 1});
    expect(exp.type, "success");
    expect(exp.payload, {"id": 1});
  });

  test("OmegaFlowExpression payload is optional", () {
    const exp = OmegaFlowExpression("idle");
    expect(exp.type, "idle");
    expect(exp.payload, isNull);
  });
}
