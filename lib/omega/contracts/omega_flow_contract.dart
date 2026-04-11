// lib/omega/contracts/omega_flow_contract.dart

import '../core/semantics/omega_event_name.dart';
import '../core/semantics/omega_intent_name.dart';

/// Declarative contract for an [OmegaFlow]: which events it listens to,
/// which intents it accepts, and which expression types it may emit.
///
/// **Why use it:** Documents and validates flow boundaries. In debug mode,
/// Omega can warn when a flow receives an event or intent not in its contract,
/// or emits an expression type not declared. Enables tooling (Inspector, docs)
/// and stricter conventions.
///
/// **Example:**
/// ```dart
/// class AuthFlow extends OmegaFlow {
///   AuthFlow({required OmegaEventBus channel, required this.agent})
///       : super(id: 'authFlow', channel: channel);
///   final AuthAgent agent;
///
///   @override
///   OmegaFlowContract? get contract => OmegaFlowContract(
///     listenedEventNames: {AppEvent.authLoginSuccess.name, AppEvent.authLoginError.name},
///     acceptedIntentNames: {AppIntent.authLogin.name, AppIntent.authLogout.name},
///     emittedExpressionTypes: {'loading', 'success', 'error'},
///   );
///
///   @override
///   void onEvent(OmegaFlowContext ctx) { ... }
///
///   @override
///   void onIntent(OmegaFlowContext ctx) { ... }
/// }
/// ```
///
/// With typed names:
/// ```dart
/// contract => OmegaFlowContract.fromTyped(
///   listenedEvents: [AppEvent.authLoginSuccess, AppEvent.authLoginError],
///   acceptedIntents: [AppIntent.authLogin, AppIntent.authLogout],
///   emittedExpressionTypes: {'loading', 'success', 'error'},
/// );
/// ```
class OmegaFlowContract {
  /// Optional flow id for documentation or tooling.
  final String? flowId;

  /// Event names this flow is declared to react to. Empty = no constraint (all allowed).
  final Set<String> listenedEventNames;

  /// Intent names this flow is declared to accept. Empty = no constraint (all allowed).
  final Set<String> acceptedIntentNames;

  /// Expression types this flow may emit to the UI. Empty = no constraint.
  final Set<String> emittedExpressionTypes;

  const OmegaFlowContract({
    this.flowId,
    this.listenedEventNames = const {},
    this.acceptedIntentNames = const {},
    this.emittedExpressionTypes = const {},
  });

  /// Builds a contract from typed event and intent names (e.g. enums).
  ///
  /// **Example:** `OmegaFlowContract.fromTyped(listenedEvents: AppEvent.values, acceptedIntents: [AppIntent.authLogin])`
  factory OmegaFlowContract.fromTyped({
    String? flowId,
    Iterable<OmegaEventName> listenedEvents = const [],
    Iterable<OmegaIntentName> acceptedIntents = const [],
    Iterable<String> emittedExpressionTypes = const [],
  }) {
    return OmegaFlowContract(
      flowId: flowId,
      listenedEventNames: listenedEvents.map((e) => e.name).toSet(),
      acceptedIntentNames: acceptedIntents.map((i) => i.name).toSet(),
      emittedExpressionTypes: emittedExpressionTypes.toSet(),
    );
  }

  /// Whether the flow is declared to listen to this event name.
  /// If [listenedEventNames] is empty, returns true (no constraint).
  bool acceptsEvent(String name) =>
      listenedEventNames.isEmpty || listenedEventNames.contains(name);

  /// Whether the flow is declared to accept this intent name.
  /// If [acceptedIntentNames] is empty, returns true (no constraint).
  bool acceptsIntent(String name) =>
      acceptedIntentNames.isEmpty || acceptedIntentNames.contains(name);

  /// Whether the flow is declared to emit this expression type.
  /// If [emittedExpressionTypes] is empty, returns true (no constraint).
  bool allowsExpression(String type) =>
      emittedExpressionTypes.isEmpty || emittedExpressionTypes.contains(type);
}

/// Declarative contract for an [OmegaAgent]: which events it reacts to
/// and which intents (when delegated by a flow) it accepts.
///
/// **Why use it:** Documents agent boundaries; in debug, Omega can warn
/// when an agent receives an event or intent not in its contract.
///
/// **Example:**
/// ```dart
/// class AuthAgent extends OmegaAgent {
///   AuthAgent(OmegaChannel c) : super(id: 'Auth', channel: c, behavior: AuthBehavior());
///   @override
///   OmegaAgentContract? get contract => OmegaAgentContract.fromTyped(
///     listenedEvents: [AppEvent.authLoginRequest],
///     acceptedIntents: [AppIntent.authLogin],
///   );
///   ...
/// }
/// ```
class OmegaAgentContract {
  final String? agentId;
  final Set<String> listenedEventNames;
  final Set<String> acceptedIntentNames;

  const OmegaAgentContract({
    this.agentId,
    this.listenedEventNames = const {},
    this.acceptedIntentNames = const {},
  });

  factory OmegaAgentContract.fromTyped({
    String? agentId,
    Iterable<OmegaEventName> listenedEvents = const [],
    Iterable<OmegaIntentName> acceptedIntents = const [],
  }) {
    return OmegaAgentContract(
      agentId: agentId,
      listenedEventNames: listenedEvents.map((e) => e.name).toSet(),
      acceptedIntentNames: acceptedIntents.map((i) => i.name).toSet(),
    );
  }

  bool acceptsEvent(String name) =>
      listenedEventNames.isEmpty || listenedEventNames.contains(name);

  bool acceptsIntent(String name) =>
      acceptedIntentNames.isEmpty || acceptedIntentNames.contains(name);
}
