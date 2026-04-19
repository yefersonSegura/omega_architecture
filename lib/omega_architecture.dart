/// Omega Architecture: a reactive, agent-oriented framework for Flutter.
///
/// Main pieces:
/// - [OmegaFlowId] / [OmegaAgentId]: typed ids for flows and agents (enums + wire mixins).
/// - [OmegaChannel] / [OmegaChannelNamespace] / [OmegaEventBus]: event bus; use
///   [OmegaChannel.namespace] to scope by module (auth, checkout, etc.). Flows and
///   agents take an [OmegaEventBus] (channel or namespace view).
/// - [OmegaAgent] / [OmegaAgentBehaviorEngine]: agent-side rules and reactions.
/// - [OmegaFlow] / [OmegaFlowManager]: business flows and orchestration; optional
///   lightweight [OmegaFlowManager.registerIntentHandler] / [Omega.handle] /
///   [OmegaIntentReducer] / [OmegaIntentHandlerPipeline] for minimal intent-only reactions.
/// - [OmegaScope] / [OmegaAgentScope] / [OmegaScopedAgentBuilder] /
///   [OmegaFlowActivator] / [OmegaInitialRoute] / [OmegaInitialNavigationEmitter] / [OmegaFlowExpressionBuilder] / [OmegaBuilder] / [OmegaInspector] /
///   [OmegaInspectorLauncher] / [OmegaInspectorReceiver] / [OmegaInspectorServer]:
///   Flutter UI and in-browser Inspector.
/// - [OmegaNavigator] / [OmegaRoute]: intent-driven navigation.
///
/// Bootstrap with [OmegaRuntime.bootstrap] (see `omega/bootstrap`).
///
/// Reference app (clone of this package): `example/lib/omega/omega_setup.dart`,
/// `example/lib/auth/auth_flow.dart`, `example/lib/auth/auth_agent.dart`,
/// `example/lib/auth/ui/auth_page.dart`.
///
/// Further reading: documentation site (see repository `docs/`).
library;

// CORE EXPORTS
export 'omega/core/channel/omega_channel.dart';
export 'omega/core/semantics/omega_intent.dart';
export 'omega/core/semantics/omega_intent_name.dart';
export 'omega/core/semantics/omega_event_name.dart';
export 'omega/core/semantics/omega_flow_id.dart';
export 'omega/core/semantics/omega_agent_id.dart';
export 'omega/core/semantics/omega_semantics_wire_from_camel.dart';
export 'omega/core/semantics/omega_typed_event.dart';
export 'omega/core/semantics/omega_typed_intent.dart';
export 'omega/core/events/omega_event.dart';
export 'omega/core/types/omega_failure.dart';
export 'omega/core/types/omega_object.dart';

// AGENTS
export 'omega/agents/omega_agent.dart';
export 'omega/agents/omega_stateful_agent.dart';
export 'omega/agents/behavior/omega_agent_behavior_context.dart';
export 'omega/agents/behavior/omega_agent_behavior_engine.dart';
export 'omega/agents/behavior/omega_agent_behavior_rule.dart';
export 'omega/agents/behavior/omega_agent_reaction.dart';

// PROTOCOLS
export 'omega/agents/protocol/omega_agent_inbox.dart';
export 'omega/agents/protocol/omega_agent_message.dart';
export 'omega/agents/protocol/omega_agent_protocol.dart';

// CONTRACTS
export 'omega/contracts/omega_flow_contract.dart';

// TIME-TRAVEL (record & replay)
export 'omega/time_travel/omega_recorded_session.dart';
export 'omega/time_travel/omega_time_travel_recorder.dart';

// OFFLINE-FIRST (queued intents)
export 'omega/offline/omega_offline_queue.dart';

// FLOWS
export 'omega/flows/omega_flow.dart';
export 'omega/flows/omega_flow_manager.dart';
export 'omega/flows/omega_intent_handler_context.dart';
export 'omega/flows/omega_intent_handle_facade.dart';
export 'omega/flows/omega_intent_reducer.dart';
export 'omega/flows/omega_intent_handler_pipeline.dart';
export 'omega/flows/omega_flow_state.dart';
export 'omega/flows/omega_flow_expression.dart';
export 'omega/flows/omega_flow_context.dart';
export 'omega/flows/omega_flow_snapshot.dart';
export 'omega/flows/omega_snapshot_storage.dart';
export 'omega/flows/omega_workflow_flow.dart';

// UI NAVIGATION
export 'omega/ui/navigation/omega_navigator.dart';
export 'omega/ui/navigation/omega_route.dart';
export 'omega/ui/navigation/omega_navigation_entry.dart';

// UI INTEGRATION (FLUTTER)
export 'omega/ui/flutter/omega_scope.dart';
export 'omega/ui/flutter/omega_initial_navigation_emitter.dart';
export 'omega/ui/flutter/omega_flow_activator.dart';
export 'omega/ui/flutter/omega_agent_scope.dart';
export 'omega/ui/flutter/omega_builder.dart';
export 'omega/ui/flutter/omega_agent_builder.dart';
export 'omega/ui/flutter/omega_scoped_agent_builder.dart';
export 'omega/ui/flutter/omega_flow_expression_builder.dart';
export 'omega/ui/flutter/omega_inspector.dart';
export 'omega/ui/flutter/omega_inspector_launcher.dart';
export 'omega/ui/flutter/omega_inspector_receiver.dart';
export 'omega/ui/flutter/omega_inspector_server.dart';
export 'omega/ui/flutter/root_heandler_app.dart';

// BOOTSTRAP
export 'omega/bootstrap/omega_runtime.dart';
export 'omega/bootstrap/omega_config.dart';
