/// Contract for typed agent ids (same string as [OmegaAgent] `super(id: ...)`).
///
/// Use an enum with [OmegaAgentIdEnumWire] like [OmegaIntentName] for intents.
///
/// ```dart
/// enum AppAgentId with OmegaAgentIdEnumWire implements OmegaAgentId {
///   Auth,
///   Provider,
/// }
/// ```
abstract class OmegaAgentId {
  /// Registered agent id (e.g. `"Auth"`).
  String get id;
}

/// [OmegaAgentId.id] is [Enum.name].
mixin OmegaAgentIdEnumWire on Enum implements OmegaAgentId {
  @override
  String get id => (this as Enum).name;
}
