import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _F with OmegaFlowIdEnumWire implements OmegaFlowId {
  alphaBeta,
}

void main() {
  test('OmegaFlowIdEnumWire uses Enum.name', () {
    expect(_F.alphaBeta.id, 'alphaBeta');
  });
}
