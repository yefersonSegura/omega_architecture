// lib/omega/flows/omega_flow_manager.dart

import 'dart:async';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

import '../core/channel/omega_channel.dart';
import 'omega_flow.dart';
import 'omega_flow_state.dart';

class OmegaFlowManager {
  final OmegaChannel channel;

  final Map<String, OmegaFlow> _flows = {};
  StreamSubscription? _navSubscription;

  /// Flow actualmente activo (modo principal)
  String? activeFlowId;

  OmegaFlowManager({required this.channel});

  // -----------------------------------------------------------
  // Registrar Flow
  // -----------------------------------------------------------

  void registerFlow(OmegaFlow flow) {
    _flows[flow.id] = flow;
  }

  // -----------------------------------------------------------
  // Obtener Flow
  // -----------------------------------------------------------

  OmegaFlow? getFlow(String id) => _flows[id];

  // -----------------------------------------------------------
  // Manejar Intent
  // -----------------------------------------------------------

  void handleIntent(OmegaIntent intent) {
    for (final flow in _flows.values) {
      if (flow.state == OmegaFlowState.running) {
        flow.receiveIntent(intent);
      }
    }
  }

  // -----------------------------------------------------------
  // Activar Flow (sin afectar otros)
  // -----------------------------------------------------------

  /// Activa el flow [id] sin pausar los demás. Permite tener varios flows
  /// en [OmegaFlowState.running] a la vez; todos recibirán intents vía [handleIntent].
  /// Para un único flow activo (y pausar el resto), usar [switchTo] o [activateExclusive].
  void activate(String id) {
    final flow = _flows[id];
    if (flow == null) return;

    flow.start();
  }

  // -----------------------------------------------------------
  // Activar Flow exclusivo
  // -----------------------------------------------------------

  /// Activa el flow [id] y pausa los demás. No comprueba si [id] está registrado;
  /// si no existe, [activeFlowId] puede quedar asignado sin flow activo.
  /// Preferir [switchTo] cuando el id deba existir.
  void activateExclusive(String id) {
    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
        activeFlowId = id;
      } else if (flow.state == OmegaFlowState.running) {
        flow.pause();
      }
    }
  }

  // -----------------------------------------------------------
  // Cambiar Flow principal
  // -----------------------------------------------------------

  /// Cambia al flow [id] (debe estar registrado), lo activa y pausa el resto.
  /// Más seguro que [activateExclusive] porque ignora ids no registrados.
  void switchTo(String id) {
    if (!_flows.containsKey(id)) return;

    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
        activeFlowId = id;
      } else if (flow.state == OmegaFlowState.running) {
        flow.pause();
      }
    }
  }

  // -----------------------------------------------------------
  // Pausar Flow
  // -----------------------------------------------------------

  void pause(String id) {
    final flow = _flows[id];
    flow?.pause();
  }

  // -----------------------------------------------------------
  // Dormir Flow
  // -----------------------------------------------------------

  void sleep(String id) {
    final flow = _flows[id];
    flow?.sleep();
  }

  // -----------------------------------------------------------
  // Finalizar Flow
  // -----------------------------------------------------------

  void end(String id) {
    final flow = _flows[id];
    flow?.end();

    if (activeFlowId == id) {
      activeFlowId = null;
    }
  }

  void endAll() {
    for (final flow in _flows.values) {
      flow.end();
    }

    activeFlowId = null;
  }

  // -----------------------------------------------------------
  // Navigator wiring
  // -----------------------------------------------------------

  void wireNavigator(OmegaNavigator nav) {
    _navSubscription?.cancel();
    _navSubscription = channel.events.listen((event) {
      if (event.name == "navigation.intent") {
        if (event.payload is OmegaIntent) {
          nav.handleIntent(event.payload as OmegaIntent);
        }
      } else if (event.name.startsWith("navigate.")) {
        nav.handleIntent(
          OmegaIntent(id: event.id, name: event.name, payload: event.payload),
        );
      }
    });
  }

  /// Cancela suscripciones (p. ej. navegación). Llamar al cerrar la app.
  void dispose() {
    _navSubscription?.cancel();
    _navSubscription = null;
  }
}
