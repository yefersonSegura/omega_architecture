import 'dart:async';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'behavior/omega_agent_behavior_engine.dart';
import 'behavior/omega_agent_behavior_context.dart';
import 'behavior/omega_agent_reaction.dart';

import 'protocol/omega_agent_inbox.dart';
import 'protocol/omega_agent_message.dart';

/// [OmegaAgent] es la unidad básica de procesamiento y lógica en la arquitectura.
/// Cada agente tiene su propio identificador [id], acceso al [channel] global,
/// y un motor de comportamiento [behavior].
abstract class OmegaAgent {
  /// Identificador único del agente.
  final String id;

  /// El canal de comunicación global.
  final OmegaChannel channel;

  /// El motor que define cómo reacciona el agente a eventos e intenciones.
  final OmegaAgentBehaviorEngine behavior;

  StreamSubscription? _eventSubscription;

  /// Bandeja de entrada para mensajes directos entre agentes.
  late final OmegaAgentInbox inbox;

  /// Estado interno mutable del agente.
  final Map<String, dynamic> state = {};

  OmegaAgent({
    required this.id,
    required this.channel,
    required this.behavior,
  }) {
    inbox = OmegaAgentInbox();

    // Escuchar eventos del sistema y guardar la suscripción
    _eventSubscription = channel.events.listen(_handleEvent);
  }

  /// Limpiar recursos y cancelar suscripciones
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  // -----------------------------------------------------------
  // 1. Procesar mensajes DIRECTOS de otros agentes
  // -----------------------------------------------------------

  /// Recibe un mensaje directo de otro agente y lo añade a la bandeja de entrada.
  void receiveMessage(OmegaAgentMessage msg) {
    inbox.receive(msg);
    onMessage(msg); // Cada agente implementa su reacción
  }

  /// Método abstracto que cada agente debe implementar para responder a mensajes.
  void onMessage(OmegaAgentMessage msg);

  // -----------------------------------------------------------
  // 2. Procesar eventos globales (OmegaChannel)
  // -----------------------------------------------------------

  void _handleEvent(OmegaEvent event) {
    _evaluateBehavior(OmegaAgentBehaviorContext(event: event, state: state));
  }

  // -----------------------------------------------------------
  // 3. Procesar intenciones semánticas
  // -----------------------------------------------------------

  /// Recibe una [OmegaIntent] y la evalúa a través del motor de comportamiento.
  void receiveIntent(OmegaIntent intent) {
    _evaluateBehavior(OmegaAgentBehaviorContext(intent: intent, state: state));
  }

  void _evaluateBehavior(OmegaAgentBehaviorContext context) {
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

  /// Método abstracto donde el agente ejecuta la lógica ligada a una acción específica.
  void onAction(String action, dynamic payload);

  // -----------------------------------------------------------
  // 6. Emitir eventos globales
  // -----------------------------------------------------------

  /// Emite un evento al canal global con un nombre y carga útil opcional.
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
