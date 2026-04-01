/// Omega Architecture: framework reactivo y basado en agentes para Flutter.
///
/// Componentes principales:
/// - [OmegaChannel] / [OmegaChannelNamespace] / [OmegaEventBus]: bus de eventos; use [OmegaChannel.namespace] para scope por módulo (auth, checkout, etc.). Flows y agents aceptan [OmegaEventBus] (canal o namespace).
/// - [OmegaAgent] / [OmegaAgentBehaviorEngine]: lógica en agentes.
/// - [OmegaFlow] / [OmegaFlowManager]: flujos de negocio y orquestación.
/// - [OmegaScope] / [OmegaBuilder] / [OmegaInspector] / [OmegaInspectorLauncher] / [OmegaInspectorReceiver] / [OmegaInspectorServer]: integración con la UI y Inspector en navegador.
/// - [OmegaNavigator] / [OmegaRoute]: navegación por intents.
///
/// Para arrancar la app usa [OmegaRuntime.bootstrap] (ver paquete omega/bootstrap).
/// Documentación detallada: doc/ARQUITECTURA.md.
library;

// CORE EXPORTS
export 'omega/core/channel/omega_channel.dart';
export 'omega/core/semantics/omega_intent.dart';
export 'omega/core/semantics/omega_intent_name.dart';
export 'omega/core/semantics/omega_event_name.dart';
export 'omega/core/semantics/omega_typed_event.dart';
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
export 'omega/ui/flutter/omega_builder.dart';
export 'omega/ui/flutter/omega_agent_builder.dart';
export 'omega/ui/flutter/omega_inspector.dart';
export 'omega/ui/flutter/omega_inspector_launcher.dart';
export 'omega/ui/flutter/omega_inspector_receiver.dart';
export 'omega/ui/flutter/omega_inspector_server.dart';
