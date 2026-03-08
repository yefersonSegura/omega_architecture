// lib/omega/flows/omega_flow_manager.dart

import 'dart:async';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/ui/navigation/omega_navigator.dart';

import '../core/channel/omega_channel.dart';
import 'omega_flow.dart';
import 'omega_flow_state.dart';

/// [OmegaFlowManager] registra y coordina todos los [OmegaFlow].
///
/// Responsabilidades: registrar flows, activar/pausar/cambiar de flow,
/// enrutar [OmegaIntent] a los flows en [OmegaFlowState.running], y conectar
/// el canal al [OmegaNavigator] con [wireNavigator]. Llamar a [dispose] al cerrar la app.
class OmegaFlowManager {
  final OmegaChannel channel;

  final Map<String, OmegaFlow> _flows = {};
  StreamSubscription? _navSubscription;

  /// Id del flow que se considera "principal" (tras [switchTo] o [activateExclusive]).
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
  ///
  /// Idempotente: si el flow ya está en [OmegaFlowState.running], no hace nada.
  /// Devuelve true si el flow se activó (o ya estaba activo), false si [id] no está registrado.
  bool activate(String id) {
    final flow = _flows[id];
    if (flow == null) return false;
    if (flow.state == OmegaFlowState.running) return true;

    flow.start();
    return true;
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
  ///
  /// Idempotente: si [id] ya es el único flow en ejecución, no hace nada.
  /// Devuelve true si se cambió al flow (o ya estaba activo), false si [id] no está registrado.
  bool switchTo(String id) {
    if (!_flows.containsKey(id)) return false;

    final target = _flows[id]!;
    final alreadyOnlyRunning =
        target.state == OmegaFlowState.running &&
        _flows.values.every((f) =>
            f.id == id || f.state != OmegaFlowState.running);
    if (alreadyOnlyRunning) {
      activeFlowId = id;
      return true;
    }

    for (final flow in _flows.values) {
      if (flow.id == id) {
        flow.start();
        activeFlowId = id;
      } else if (flow.state == OmegaFlowState.running) {
        flow.pause();
      }
    }
    return true;
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
  // Conexión del navegador
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
