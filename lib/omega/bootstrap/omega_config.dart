import '../agents/omega_agent.dart';
import '../core/channel/omega_channel.dart';
import '../core/semantics/omega_intent.dart';
import '../flows/omega_flow.dart';
import '../flows/omega_flow_manager.dart';
import '../ui/navigation/omega_route.dart';

/// Runs after flows and routes are registered and [OmegaFlowManager.wireNavigator] completed.
///
/// Use for [OmegaFlowManager.registerIntentHandler] / [Omega.handle] so registration
/// lives next to [OmegaConfig.flows] instead of [main].
typedef OmegaIntentHandlerRegistrar = void Function(
  OmegaFlowManager flowManager,
  OmegaChannel channel,
);

/// Bootstrap configuration: list of agents, flows, routes and initial flow.
///
/// **Why use it:** Single object you pass to [OmegaRuntime.bootstrap]; the runtime registers everything and returns the [OmegaRuntime].
///
/// **Example:** `OmegaConfig(agents: [...], flows: [...], routes: [...], initialFlowId: "authFlow", initialNavigationIntent: OmegaIntent.fromName(AppIntent.navigateLogin), intentHandlerRegistrars: [MyDemo.attach]);`
class OmegaConfig {
  final List<OmegaAgent> agents;
  final List<OmegaFlow> flows;
  final List<OmegaRoute> routes;

  /// Id of the flow to activate when the app opens. The host calls flowManager.switchTo(initialFlowId) on the first frame.
  final String? initialFlowId;

  /// Optional first navigation intent (e.g. [OmegaIntent.fromName] with `AppIntent.navigateLogin`).
  ///
  /// [initialFlowId] only selects which flow is **running**; it does not push an [OmegaRoute].
  /// When set, pass the same value on [OmegaScope.initialNavigationIntent] and use
  /// [OmegaInitialRoute] as [MaterialApp.home]'s root so the first frame opens the matching `navigate.*` route.
  final OmegaIntent? initialNavigationIntent;

  /// Optional hooks; [OmegaRuntime.bootstrap] invokes each with the same
  /// [OmegaFlowManager] and [OmegaChannel] the runtime uses (after [wireNavigator]).
  final List<OmegaIntentHandlerRegistrar> intentHandlerRegistrars;

  const OmegaConfig({
    this.agents = const [],
    this.flows = const [],
    this.routes = const [],
    this.initialFlowId,
    this.initialNavigationIntent,
    this.intentHandlerRegistrars = const [],
  });
}
