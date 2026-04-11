// Wire ids mix lowerCamelCase (`authFlow`) y PascalCase (`Provider`, `Auth`) como en el example.
// ignore_for_file: constant_identifier_names

import 'package:omega_architecture/omega_architecture.dart';

/// Ids de flows del example (mismo valor que `super(id: ...)` en cada [OmegaFlow]).
enum AppFlowId with OmegaFlowIdEnumWire implements OmegaFlowId {
  authFlow,
  ordersFlow,
  /// Coincide con `ProviderFlow`: id `"Provider"`.
  Provider,
}

/// Ids de agentes (`super(id: ...)` en cada [OmegaAgent]).
enum AppAgentId with OmegaAgentIdEnumWire implements OmegaAgentId {
  Auth,
  Provider,
  orders,
}
