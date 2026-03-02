import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'behavior/omega_agent_behavior_engine.dart';
import 'behavior/omega_agent_behavior_context.dart';
import 'behavior/omega_agent_reaction.dart';

import 'protocol/omega_agent_inbox.dart';
import 'protocol/omega_agent_message.dart';

abstract class OmegaAgent {
  final String id;
  final OmegaChannel channel;
  final OmegaAgentBehaviorEngine behavior;

  late final OmegaAgentInbox inbox;

  /// Estado interno del agente
  final Map<String, dynamic> state = {};

  OmegaAgent({
    required this.id,
    required this.channel,
    required this.behavior,
  }) {
    inbox = OmegaAgentInbox();

    // Escuchar eventos del sistema
    channel.events.listen(_handleEvent);
  }

  // -----------------------------------------------------------
  // 1. Procesar mensajes DIRECTOS de otros agentes
  // -----------------------------------------------------------

  void receiveMessage(OmegaAgentMessage msg) {
    inbox.receive(msg);
    onMessage(msg); // Cada agente implementa su reacción
  }

  /// Cada agente define cómo responder mensajes
  void onMessage(OmegaAgentMessage msg);

  // -----------------------------------------------------------
  // 2. Procesar eventos globales (OmegaChannel)
  // -----------------------------------------------------------

  void _handleEvent(OmegaEvent event) {
    final context = OmegaAgentBehaviorContext(event: event, state: state);

    final reaction = behavior.evaluate(context);
    if (reaction != null) {
      _executeReaction(reaction);
    }
  }

  // -----------------------------------------------------------
  // 3. Procesar intenciones semánticas
  // -----------------------------------------------------------

  void receiveIntent(OmegaIntent intent) {
    final context = OmegaAgentBehaviorContext(intent: intent, state: state);

    final reaction = behavior.evaluate(context);
    if (reaction != null) {
      _executeReaction(reaction);
    }
  }

  // -----------------------------------------------------------
  // 4. Ejecutar reacciones producidas por el BehaviorEngine
  // -----------------------------------------------------------

  void _executeReaction(OmegaAgentReaction reaction) {
    onAction(reaction.action, reaction.payload);
  }

  // -----------------------------------------------------------
  // 5. Cada agente define sus acciones internas
  // -----------------------------------------------------------

  void onAction(String action, dynamic payload);

  // -----------------------------------------------------------
  // 6. Emitir eventos globales
  // -----------------------------------------------------------

  void emit(String name, {dynamic payload}) {
    channel.emit(
      OmegaEvent(
        id: "$id:${DateTime.now().millisecondsSinceEpoch}",
        name: name,
        payload: payload,
      ),
    );
  }
}
