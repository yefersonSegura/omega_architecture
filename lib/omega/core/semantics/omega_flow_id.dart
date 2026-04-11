/// Contract for typed flow ids (same string as [OmegaFlow] `super(id: ...)`).
///
/// Use an enum with [OmegaFlowIdEnumWire] so you avoid raw strings in
/// [OmegaFlowActivator], [OmegaFlowManager.getFlow], and contracts.
///
/// ```dart
/// enum AppFlowId with OmegaFlowIdEnumWire implements OmegaFlowId {
///   authFlow,
///   ordersFlow,
/// }
/// // super(id: AppFlowId.authFlow.id, channel: channel)
/// ```
abstract class OmegaFlowId {
  /// Registered flow id (e.g. `"authFlow"`).
  String get id;
}

/// [OmegaFlowId.id] is [Enum.name] — no duplicated string per case.
mixin OmegaFlowIdEnumWire on Enum implements OmegaFlowId {
  @override
  String get id => (this as Enum).name;
}
