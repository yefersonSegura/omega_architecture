// lib/omega/flows/omega_flow_manager.dart

import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

import '../core/channel/omega_channel.dart';

import 'omega_flow.dart';
import 'omega_flow_state.dart';

class OmegaFlowManager {
  final OmegaChannel channel;

  // Registro dinámico de flows del sistema
  final Map<String, OmegaFlow> _flows = {};

  OmegaFlowManager({required this.channel});

  // -----------------------------------------------------------
  // 1. Registrar un Flow en el sistema
  // -----------------------------------------------------------
  void registerFlow(OmegaFlow flow) {
    _flows[flow.id] = flow;
  }

  // -----------------------------------------------------------
  // 2. Obtener un flow por ID
  // -----------------------------------------------------------
  OmegaFlow? getFlow(String id) => _flows[id];

  // -----------------------------------------------------------
  // 3. Recibir intenciones desde la UI o sistema
  // -----------------------------------------------------------
  void handleIntent(OmegaIntent intent) {
    for (final flow in _flows.values) {
      if (flow.state == OmegaFlowState.running) {
        flow.receiveIntent(intent);
      }
    }
  }

  // -----------------------------------------------------------
  // 4. Activar un flow específico
  // -----------------------------------------------------------
  void activate(String id) {
    final flow = _flows[id];
    if (flow == null) return;

    flow.start();
  }

  // -----------------------------------------------------------
  // 5. Poner un flow en pausa
  // -----------------------------------------------------------
  void pause(String id) {
    final flow = _flows[id];
    flow?.pause();
  }

  // -----------------------------------------------------------
  // 6. Dormir un flow
  // -----------------------------------------------------------
  void sleep(String id) {
    final flow = _flows[id];
    flow?.sleep();
  }

  // -----------------------------------------------------------
  // 7. Detener un flow definitivamente
  // -----------------------------------------------------------
  void end(String id) {
    final flow = _flows[id];
    flow?.end();
  }

  // -----------------------------------------------------------
  // 8. Detener todos los flows (ej: logout)
  // -----------------------------------------------------------
  void endAll() {
    for (final flow in _flows.values) {
      flow.end();
    }
  }

  // -----------------------------------------------------------
  // 9. Activar un único flow y pausar los demás (Modo exclusivo)
  // -----------------------------------------------------------
  void activateExclusive(String id) {
    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
      } else {
        flow.pause();
      }
    }
  }

  void wireNavigator(OmegaNavigator nav) {
    channel.events.listen((event) {
      if (event.name == "navigation.intent") {
        final intent = event.payload as OmegaIntent;
        nav.handleIntent(intent);
      }
    });
  }
}
